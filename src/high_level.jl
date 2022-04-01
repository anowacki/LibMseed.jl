# High-level wrappers around bare functions

#=
    Julia types for the public API
=#

"""
    NanosecondDateTime

Type representing an instance in time to nanosecond precision.
It is made up of a standard `DateTime` plus a number of nanoseconds in addition
to the millisecond resolution that `DateTime` offers.

# Accessor functions
- [`datetime`](@ref): Return a `Dates.DateTime`
  giving the date and time of a `NanosecondDateTime` to millisecond precision.
- [`nanoseconds`](@ref): Return a `Dates.Nanosecond`
  giving the additional number of nanoseconds beyond the millsecond precision
  of the `Date.DateTime` part.

# Other functions
- [`nearest_datetime`](@ref): Return the `Dates.DateTime` nearest to the
  `NanosecondDateTime`.
"""
struct NanosecondDateTime
    "`DateTime`, to millisecond resolution"
    datetime::DateTime
    "Positive number of nanoseconds.  Never more than 999999."
    nanosecond::Nanosecond
end

Base.typemin(::Type{NanosecondDateTime}) = NanosecondDateTime(typemin(nstime_t))
Base.typemax(::Type{NanosecondDateTime}) = NanosecondDateTime(typemax(nstime_t))

Base.:(==)(t1::NanosecondDateTime, t2::NanosecondDateTime) =
    datetime(t1) == datetime(t2) && nanoseconds(t1) == nanoseconds(t2)

function Base.print(io::IO, dt::NanosecondDateTime)
    date_str = Dates.format(datetime(dt), dateformat"yyyy-mm-ddTHH:MM:SS.sss")
    ns_str = lpad(Dates.value(nanoseconds(dt)), 6, '0')
    print(io, date_str, ns_str)
end

"""
    EPOCH ($(EPOCH))

Epoch of the `NanosecondDateTime` type.  This is the `DateTime` corresponding
to the zeroth nanosecond of the type.
"""
const EPOCH = DateTime(1970)

"""
    NanosecondDateTime(nstime)

Construct a `NanosecondDateTime` from an `$(nstime_t)`.  This represents
the integer number of nanoseconds since the epoch of `1970-01-01T00:00:00.000000000`.
Hence the range of dates which can be represented is
`$(typemin(NanosecondDateTime)) - $(typemax(NanosecondDateTime))`.
"""
function NanosecondDateTime(nstime::nstime_t)
    epoch_ms = nstime ÷ 1_000_000
    dt = EPOCH + Millisecond(epoch_ms)
    ns = Nanosecond(nstime % 1_000_000)
    if ns < Nanosecond(0)
        dt = dt - Millisecond(1)
        ns = Nanosecond(1_000_000) + ns
    end
    NanosecondDateTime(dt, ns)
end

"""
    NanosecondDateTime(dt::DateTime)

Create a `NanosecondDateTime` from a `DateTime`, `dt`.
"""
NanosecondDateTime(dt::DateTime) = NanosecondDateTime(dt, Nanosecond(0))

Base.convert(::Type{nstime_t}, dt::NanosecondDateTime) =
    Dates.value(datetime(dt) - EPOCH)*1_000_000 + Dates.value(nanoseconds(dt))

"""
    datetime(dt::NanosecondDateTime) -> ::Date.DateTime

Return the date and time of `dt`, rounded down to the nearest millisecond.
Add on the number of [`nanoseconds`](@ref) to obtain the full-precision time.

See also: [`NanosecondDateTime`](@ref).
"""
datetime(dt::NanosecondDateTime) = dt.datetime

"""
    nanoseconds(dt::NanosecondDateTime) -> ::Date.Nanosecond(n)

Return the number of additional nanoseconds of the date and time represented
by `dt`, beyond the millisecond resolution of [`datetime`](@ref).  This value
is always positive.

See also: [`NanosecondDateTime`](@ref).
"""
nanoseconds(dt::NanosecondDateTime) = dt.nanosecond

"""
    nearest_datetime(dt::NanosecondDateTime) -> ::Dates.DateTime

Round `dt` to the nearest millisecond and return a `DateTime`.
"""
nearest_datetime(dt::NanosecondDateTime) = datetime(dt) +
    Millisecond(round(Int, Dates.value(nanoseconds(dt))/1_000_000))

"""
    MseedTraceSegment{T}

Segment of continuous data of element type `T`.

# Fields
- `starttime::NanosecondDateTime`: Date and time of first sample.
- `endtime::NanosecondDateTime`: Date and time of last sample.
- `sample_rate::Float64`: Nominal sampling rate in samples per second.
- `sample_count::Int64`: Number of samples in trace coverage.
- `data::Vector{T}`: Data values of trace.
"""
struct MseedTraceSegment{T}
    starttime::NanosecondDateTime
    endtime::NanosecondDateTime
    sample_rate::Float64
    sample_count::Int64
    data::Vector{T}
end

function Base.show(io::IO, mime::MIME"text/plain", segment::MseedTraceSegment{T}) where T
    print(io, """
        MseedTraceSegment{$T}:
         starttime:    $(segment.starttime)
         endtime:      $(segment.endtime)
         sample_rate:  $(segment.sample_rate)
         sample_count: $(segment.sample_count)""")
    if !isempty(segment.data)
        print(io, """\n data:         [values between $(extrema(segment.data))]""")
    end
end

function Base.:(==)(seg1::MseedTraceSegment, seg2::MseedTraceSegment)
    seg1.starttime == seg2.starttime &&
        seg1.endtime == seg2.endtime &&
        seg1.sample_rate == seg2.sample_rate &&
        seg2.sample_count == seg2.sample_count &&
        seg1.data == seg2.data
end

"""
    MseedTraceID

Container for several segments of continuous data for a single channel.

# Fields
- `id`: `String` describing the source channel ID as a 'URN'.
- `earliest::NanosecondDateTime`: Time of earliest sample in all segments.
- `latest::NanosecondDateTime`: Time of latest sample in all segments.
- `segments::Vector{MseedTraceSegment}`: Set of data segments.  Each must have
  the same data type.
"""
struct MseedTraceID{T}
    id::String
    earliest::NanosecondDateTime
    latest::NanosecondDateTime
    segments::Vector{MseedTraceSegment{T}}
end

function Base.:(==)(t1::MseedTraceID, t2::MseedTraceID)
    t1.id == t2.id &&
        t1.earliest == t2.earliest &&
        t1.latest == t2.latest &&
        length(t1.segments) == length(t2.segments) &&
        all(x -> x[1] == x[2], zip(t1.segments, t2.segments))
end

Base.show(io::IO, mime::MIME"text/plain", traceid::MseedTraceID{T}) where T =
    print(io, """
        MseedTraceID{$T}:
         id:       $(traceid.id)
         earliest: $(traceid.earliest)
         latest:   $(traceid.latest)
         segments: $(length(traceid.segments))
        """)

"""
    MseedTraceList

Container for several different channels.

# Fields
- `traces::Vector{MseedTraceID}`: Set of trace channels, each of which may contain
  several segments of continuous data.
"""
struct MseedTraceList
    traces::Vector{MseedTraceID}
end

Base.:(==)(list1::MseedTraceList, list2::MseedTraceList) = list1.traces == list2.traces

function Base.show(io::IO, ::MIME"text/plain", tracelist::MseedTraceList)
    ntraces = length(tracelist.traces)
    s = ntraces == 1 ? "" : "s"
    print(io, """
        MseedTraceList:
         $(ntraces) trace$(s):""")
    for trace in tracelist.traces
        print(io, "\n  \"", trace.id, "\": $(trace.earliest) $(trace.latest), $(length(trace.segments)) segments")
    end
end

"""
    channel_code_parts(s) (net, sta, loc, cha)

Convert a single `String` `s` into its component SEED channel code parts.
Returns a named tuple of network `net`, station `sta`, location `loc` and
channel `cha`.  Empty components are given as empty `String`s.

This function assumes that `s` is an ASCII string, as per the SEED convention
for channel IDs.

See https://iris-edu.github.io/xseed-specification/docs/xFDSNSourceIdentifiers-DRAFT20190520.pdf
for the transitional SEED URN specification.
"""
function channel_code_parts(s::String)
    parts = split(s, '_')
    nparts = length(parts)
    # Maybe an XFDSN URN
    if startswith(s, "XFDSN:") || startswith(s, "FDSN:")
        # Seems like an XFDSN URN
        if length(s) > 6
            length(parts[1]) > 6 || error("unexpectedly short network name")
            # URN convention: XFDSN:NET_STA_LOC_BAND_SOURCE_POSITION
            if nparts == 6
                net = parts[1][1] == 'X' ? parts[1][7:end] : parts[1][6:end]
                sta = parts[2]
                loc = parts[3]
                cha = join(parts[4:end])
            # Traditional SEED convention: NET_STA_LOC_CHA
            elseif nparts == 4
                length(parts[1]) > 6 || error("unexpectedly short network name")
                net = parts[1][7:end]
                sta = parts[2]
                loc = parts[3]
                cha = parts[4]
            else
                error("unexpected apparent XFDSN URN")
            end
        # Not really an XFDSN URN
        else
            error("unexpectedly short channel id")
        end

    # Not an XFDSN URN but might have the same structure
    else
        # NET_STA_LOC_CHA: one might be blank
        if nparts == 4
            net = parts[1]
            sta = parts[2]
            loc = parts[3]
            cha = parts[4]
        # NET_STA_LOC_BAND_SOURCE_POSITION: all but one might be blank
        elseif nparts == 6
            net = parts[1]
            sta = parts[2]
            loc = parts[3]
            cha = join(parts[4:end])
        # Something else entirely: just put it all in sta
        else
            net = nothing
            sta = s
            loc = nothing
            cha = nothing
        end
    end
    (net=net, sta=sta, loc=loc, cha=cha)
end

"""
    channel_code_parts(traceid::MseedTraceID) -> (net, sta, loc, cha)

Return the channel code parts for the trace ID for `traceid`.
"""
channel_code_parts(traceid::MseedTraceID) = channel_code_parts(traceid.id)

#=
    libmseed structs
=#
mutable struct _MS3TraceSeg
    starttime::nstime_t
    endtime::nstime_t
    samprate::Cdouble
    samplecnt::Int64
    datasamples::Ptr{Cvoid}
    datasize::Csize_t
    numsamples::Int64
    sampletype::UInt8
    prvtptr::Ptr{Cvoid}
    recordlist::Ptr{MS3RecordList}
    prev::Ptr{_MS3TraceSeg}
    next::Ptr{_MS3TraceSeg}
end

mutable struct _MS3TraceID
    sid::NTuple{64, UInt8}
    pubversion::UInt8
    earliest::nstime_t
    latest::nstime_t
    prvtptr::Ptr{Cvoid}
    numsegments::UInt32
    first::Ptr{_MS3TraceSeg}
    last::Ptr{_MS3TraceSeg}
    next::Ptr{_MS3TraceID}
end

mutable struct _MS3TraceList
    numtraces::UInt32
    traces::Ptr{_MS3TraceID}
    last::Ptr{_MS3TraceID}
end

"""
    MseedTraceList(mstl::Ref{Ptr{_MS3TraceList}})

Construct a `MseedTraceList` from a reference to a `_MS3TraceList` struct
obtained from a call to one of `libmseed`'s functions.

This function builds a full `MseedTraceList` and copies the data from
`mstl`.
"""
function MseedTraceList(mstl::Ref{Ptr{_MS3TraceList}})
    this_tracelist = unsafe_load(mstl[])
    numtraces = Int32(this_tracelist.numtraces)
    tracelist = MseedTraceList(Vector{MseedTraceID}(undef, numtraces))

    # Follow linked list through MS3TraceIDs
    this_traceid = unsafe_load(this_tracelist.traces) # First
    for itraceid in 1:numtraces
        tracelist.traces[itraceid] = MseedTraceID(this_traceid)

        # Move to the next trace id
        if itraceid != numtraces && this_traceid.next == C_NULL
            error("unexpectedly reached end of trace id list")
        elseif itraceid == numtraces && this_traceid.next != C_NULL
            @warn("unexpected extra trace ids in list")
            break
        end
        if itraceid != numtraces
            this_traceid = unsafe_load(this_traceid.next)
        end
    end

    tracelist
end

"""
    MseedTraceID(this_traceid::_MS3TraceID)

Construct a `MseedTraceID` from a `_MS3TraceID` object, obtained from
a call to one of `libmseed`'s functions.
"""
function MseedTraceID(this_traceid::_MS3TraceID)
    id = bytes2string(this_traceid.sid)
    earliest = NanosecondDateTime(this_traceid.earliest)
    latest = NanosecondDateTime(this_traceid.latest)
    numsegments = Int(this_traceid.numsegments)

    # Get reference to the first segment here so we know the element type
    this_traceseg = unsafe_load(this_traceid.first)
    T = sample_type(Char(this_traceseg.sampletype))

    traceid = MseedTraceID{T}(id, earliest, latest,
        Vector{MseedTraceSegment{T}}(undef, numsegments))

    # Follow linked list through trace MS3TraceSegs
    for itraceseg in 1:numsegments
        traceid.segments[itraceseg] = MseedTraceSegment(T, this_traceseg)

        # Move to the next trace segment
        if itraceseg != numsegments && this_traceseg.next == C_NULL
            error("unexpectedly reached end of trace segment list")
        elseif itraceseg == numsegments && this_traceseg.next != C_NULL
            @warn("unexpected extra trace segment in list")
            break
        end
        if itraceseg != numsegments
            this_traceseg = unsafe_load(this_traceseg.next)
        end
    end

    traceid
end

"""
    MseedTraceSegment(T, this_traceseg::_MS3TraceSeg) -> segment

Construct a `MseedTraceSegment{T}` from `_MS3TraceSeg` object obtained
from a call to one of `libmseed`'s functions.
"""
function MseedTraceSegment(T, this_traceseg::_MS3TraceSeg)
    starttime = NanosecondDateTime(this_traceseg.starttime)
    endtime = NanosecondDateTime(this_traceseg.endtime)
    sample_rate = this_traceseg.samprate
    sample_count = this_traceseg.samplecnt
    numsamples = Int(this_traceseg.numsamples)
    samples_ptr = convert(Ptr{T}, this_traceseg.datasamples)
    data = unsafe_wrap(Vector{T}, samples_ptr, numsamples)
    MseedTraceSegment{T}(starttime, endtime, sample_rate, sample_count, copy(data))
end

"""
    sample_type(t::UInt8) -> ::DataType

Determine the element type of a `MseedTraceSegment` from the
character (as a `UInt8`) `t`.

If `t` corresponds to an unsupported or unknown element type,
then an error is thrown.
"""
function sample_type(t)
    if t === 'f'
        return Float32
    elseif t === 'd'
        return Float64
    elseif t === 'i'
        return Int32
    elseif t === 'a'
        error("ASCII-format miniSEED data are not currently supported")
    else
        error("unsupported miniSEED sample type `$t`")
    end
end

"""
    bytes2string(bytes::Ntuple{N,UInt8})

Convert a null-terminated tuple of `UInt8`s into a `String`.

This function takes the first null character ('`\\0`') as the end marker
and ignores all subsequent characters in `bytes`.

See also: [`Cstring`](@ref), [`unsafe_string`](@ref)
"""
function bytes2string(bytes::NTuple{N,UInt8}) where N
    index = findfirst(x -> x == 0, bytes)
    len = index === nothing ? N : index - 1
    String(UInt8[@inbounds(bytes[i]) for i in 1:len])
end

"""
    string2bytes(::Type{NTuple{N,T}}, str) -> bytes

Convert a `String` to a null-terminated tuple of `T`s of length `N`.
If `str` is longer than `N`, the string is truncated without warning.
"""
function string2bytes(::Type{NTuple{N,T}}, str::AbstractString) where {N,T}
    isascii(str) || throw(ArgumentError("input string must be ASCII"))
    n = length(str)
    ntuple(i -> i <= n ? T(str[i]) : T('\0'), Val(N))
end


"""
    read_buffer(buffer::Vector{UInt8}, verbose_level=0) -> tracelist

Parse data in `buffer` (a series of bytes) as miniSEED data and return
`tracelist` (a `MseedTraceList`) containing the data.

If `buffer` is not valid miniSEED data, then an error is thrown.

`verbose_level` is passed to the `libmseed` routine `mstl3_readbuffer`
to control the verbosity level, with `0` (the default) only writing
error messages to stderr, and higher numbers causing more information
to be printed.
"""
function read_buffer(buffer::Vector{UInt8}, verbose_level=0)
    version, len = detect_buffer(buffer)
    if version === nothing
        throw(ArgumentError("data does not seem to be miniSEED"))
    end
    if len === nothing
        error("buffer length cannot be determined")
    end
    mstl = Ref(init_tracelist())
    flags = MSF_VALIDATECRC | MSF_UNPACKDATA
    buffer_length = length(buffer)*sizeof(eltype(buffer))
    err = ccall(
        (:mstl3_readbuffer, libmseed),
        Int64,
        (Ref{Ptr{_MS3TraceList}}, Ref{UInt8}, UInt64, Int8, UInt32, Ptr{Cvoid}, Int8),
        mstl[], buffer, buffer_length, '\0', flags,
        C_NULL, verbose_level
    )
    # Positive values of `err` give the number of traces, so we
    # only need to check for negative errors here.
    if err < 0
        free!(mstl)
        check_error_value_and_throw(err)
    end

    tracelist = MseedTraceList(mstl)
    free!(mstl)

    tracelist
end

"""
    read_file(file; verbose_level=0) -> tracelist

Read miniSEED data from `file` on disk and return `tracelist`, (a
`MseedTraceList`) containing the data.

If `file` does not contain valid data then an error is thrown.

`verbose_level` is passed to the `libmseed` routine `mstl3_readtracelist`
to control the verbosity level, with `0` (the default) only writing
error messages to stderr, and higher numbers causing more information
to be printed.
"""
function read_file(file; verbose_level=0)
    mstl = Ref(init_tracelist())
    flags = MSF_VALIDATECRC | MSF_UNPACKDATA
    err = ccall(
        (:ms3_readtracelist, libmseed),
        Cint,
        (Ref{Ptr{_MS3TraceList}}, Cstring, Ptr{Cvoid}, Int8, UInt32, Int8),
        mstl[], file, C_NULL, -1, flags, verbose_level
    )
    if err != MS_NOERROR
        free!(mstl)
        check_error_value_and_throw(err, file)
    elseif err > 0
        check_error_value_and_warn(err, file)
    end

    tracelist = MseedTraceList(mstl)
    free!(mstl)

    tracelist
end

"""
    write_data(file, data, sample_rate, starttime, id; append=false, verbose_level=0, compress=:steim2, pubversion=1, record_length=nothing) -> n

Write `data` in miniSEED format to `file`.  The number of samples per second
is given by `sample_rate`, and `starttime` is the date of the first sample.

`id` is an ASCII string giving the ID of the trace.  If it is longer than
$LM_SIDLEN characters, it is truncated with a warning.

Use `append=true` to add new records on to `file`; otherwise any existing
file is overwritten.  `file` is created if it does not already exist in
either case.

`verbose_level` is passed to the `libmseed` routine `mstl3_readtracelist`
to control the verbosity level, with `0` (the default) only writing
error messages to stderr, and higher numbers causing more information
to be printed.

# Allowable `data` element types
miniSEED files can only contain data for `Int32`, `Float32` or `Float64`
element types.  Therefore, this function will only write vectors with
one of these element types and throw an error if a different type is
passed in.  You should convert data to one of these types before calling
this function.

# Compression options
`compress` can take the values `:steim1` or `:steim2`, causing the file
to be written respectively with Steim-1 or Steim-2 compression.  Note that
this is only possible for `Int32` data.

# All keyword arguments
- `append = false`: If `true`, append this data to an existing file if it exists.
- `verbose_level = 0`: Control verbosity of the libmseed library, with
  values greater than 0 increasing verbosity.
- `compress = :steim2`: If input data are integers, use Steim compression
  when writing the data.  Options are: `:steim1` (Steim-1 compression)
  and `:steim2` (Steim-2) compression.
- `pubversion = 1`: Set the publication version for the record.  In
  SEED, later versions correspond to revised data and are read from
  files in preference to earlier versions.
- `record_length = nothing`: Control the record length of records written
  to disk.  The default value (`-1`) allows the libmseed library to
  determine the record length.
- `version = 2`: miniSEED file version to write.  Note that little other
  software supports the current version `3`, so the default is to write
  version `2`.
"""
function write_data(file, data, sample_rate, starttime, id;
        append::Bool=false, verbose_level::Integer=0,
        compress::Union{Nothing,Symbol}=nothing,
        pubversion::Integer=1, record_length::Union{Nothing,Integer}=nothing,
        version::Integer=2)

    # TODO: Investigate and fix issue where Steim compression produces
    #       files with an incorrect checksum and sometimes corrupt data
    #       when read by obspy, SeisIO and SAC (but not by libmseed!).
    #       For now, disallow Steim encoding entirely.
    compress !== nothing &&
        throw(ArgumentError(
            "Steim compression is not currently supported due to a bug"))

    # Check arguments
    compress in (nothing, :steim1, :steim2) ||
        throw(ArgumentError("unrecognised option for `compress`"))
    record_length !== nothing && (record_length < -1 || record_length == 0) &&
        throw(ArgumentError("unknown value for `record_length` (must be -1 or > 0)"))
    2 <= version <= 3 ||
        @warn("miniSEED format versions other than 2 and 3 may not work")

    record = C_NULL
    reclen = record_length === nothing ? -1 : record_length
    swapflag = 0
    if length(id) > LM_SIDLEN
        @warn("station id truncated to first $LM_SIDLEN characters")
    end
    sid = string2bytes(NTuple{LM_SIDLEN,UInt8}, id)
    formatversion = version
    flags = MSF_FLUSHDATA
    starttime = NanosecondDateTime(starttime)
    samprate = sample_rate
    samplecnt = -1
    crc = 0
    extralength = 0
    datalength = 0
    extra = C_NULL
    datasamples = pointer(data)
    datasize = sizeof(eltype(data))*length(data)
    numsamples = length(data)
    sampletype = sample_code(data)
    
    # Determine default encoding
    encoding = _encoding(data)

    # Allow compression if requested and using `Int32`s
    if eltype(data) == Int32 && compress !== nothing
        encoding = if compress === :steim1
            DE_STEIM1
        elseif compress === :steim2
            DE_STEIM2
        end
    end

    msr = Ref(MS3Record(record, reclen, swapflag, sid, formatversion, flags,
        starttime, samprate, encoding, pubversion, samplecnt, crc,
        extralength, datalength, extra, datasamples, datasize, numsamples,
        sampletype))

    overwrite = append ? 0 : 1

    err = ccall(
        (:msr3_writemseed, libmseed),
        Int64,
        (Ptr{MS3Record}, Cstring, Int8, UInt32, Int8),
        msr, file, overwrite, flags, verbose_level
    )

    if err == -1
        error("error writing records")
    end

    # If not an error, this is the number of records written
    err
end

_encoding(::AbstractVector{<:Int32}) = DE_INT32
_encoding(::AbstractVector{<:Float32}) = DE_FLOAT32
_encoding(::AbstractVector{<:Float64}) = DE_FLOAT64
_encoding(_) = -1

"Return the sample type character code given the data type"
sample_code(::Type{Int32}) = 'i'
sample_code(::Type{Float32}) = 'f'
sample_code(::Type{Float64}) = 'd'
sample_code(::AbstractVector{<:T}) where T = sample_code(T)
sample_code() = error("unsupported data type $T for writing")

"""
    init_tracelist(; verbose=false) -> mstl::Ptr{libmseed._MS3TraceList}

Create a new `_MS3TraceList`, and return a pointer to it.

`mstl` can then be passed to other `libmseed` functions by wrapping it
in a `Ref` like `Ref(mstl)`.

# Example
```
# Create a new trace list for miniSEED data and allocate some memory
mstl = Ref(init_tracelist())
# Free the memory just allocated and destroy the trace list
free!(mstl)
```
"""
function init_tracelist(; verbose=false)
    mstl = ccall((:mstl3_init, libmseed), Ptr{_MS3TraceList}, (Ptr{Cvoid},), C_NULL)
    if mstl == C_NULL
        error("error allocating trace structure")
    end
    mstl
end

"""
    free!(mstl)

Free the memory associated with a trace list.

The memory is managed by the `libmseed` library, and `mstl` is a
reference to a pointer to a `MS3TraceList` struct.
"""
function free!(mstl::Ref{Ptr{_MS3TraceList}})
    @debug("Freeing trace memory at $(mstl[])")
    ccall(
        (:mstl3_free, libmseed),
        Cvoid,
        (Ref{Ptr{_MS3TraceList}}, Int8),
        mstl, 0)
    @debug("Pointer now set to $(mstl[])")
    nothing
end

"""
    detect_buffer(data) -> (version, length)

Check whether `data` is miniSEED data.  `data` should be a set of raw bytes.

If the data appear to be miniSEED, return the major `version` number of the
format, and the `length` in bytes of the data.  If the length cannot be determined,
then `length` is `nothing`.

If the data do not seem to be miniSEED, return `nothing` for both `version`
and `length`.
"""
function detect_buffer(data::Vector{UInt8})
    version = Ref{UInt8}()
    err = ccall(
        (:ms3_detect, libmseed),
        Cint,
        (Ptr{Cchar}, UInt64, Ref{UInt8}),
        data, length(data), version)
    # Data not miniSEED condition
    if err < 0
        return nothing, nothing
    # Condition where we cannot determine the data length
    elseif err == 0
        return Int(version[]), nothing
    # `err` is actually the data length
    else
        return Int(version[]), Int(err)
    end
end

"English error messages which correspond to libmseed error codes"
const _MS_ERROR_MESSAGES = Dict{Cint,String}(
    MS_ENDOFFILE => "End of file reached",
    MS_NOERROR => "No error",
    MS_GENERROR => "Generic unspecified error",
    MS_NOTSEED => "Data are not SEED",
    MS_WRONGLENGTH => "Length of SEED data was not correct",
    MS_OUTOFRANGE => "SEED record length out of range",
    MS_UNKNOWNFORMAT => "Unkonwn data encoding format",
    MS_STBADCOMPFLAG => "Invalid Steim compression flag(s)",
    MS_INVALIDCRC => "Invalid CRC checksum for data"
)

"""
    check_error_value_and_throw(err, file=nothing)

Check `err`, a value returned by a libmseed function, and if
it represents an error conditions, throw an error and report the
nature of the error if possible.
"""
function check_error_value_and_throw(err, file=nothing)
    file_message = _file_message(file)
    error_message = get(_MS_ERROR_MESSAGES, err, "(unknown error code $err)")
    error(error_message * file_message)
end

"""
    check_error_value_and_warn(err, file=nothing)

Check `err`, a value returned by a libmseed function, and if
it represents a warning condition, warn the user with an informative
message if possible.
"""
function check_error_value_and_warn(err, file=nothing)
    file_message = _file_message(file)
    warning_message = get(_MS_ERROR_MESSAGES, err, "(unknown warning code $err)")
    @warn(warning_message * file_message)
    nothing
end

_file_message(file) = file !== nothing ? " in file '$file'" : ""
