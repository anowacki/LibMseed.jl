# Reading and writing, including of raw data vectors

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
    read_buffer(buffer::Vector{UInt8}; channels::AbstractString, startdate::DateTime, enddate::DateTime, headers_only=false, time_tolerance=nothing, verbose_level=0) -> tracelist

Parse data in `buffer` (a series of bytes) as miniSEED data and return
`tracelist` (a `MseedTraceList`) containing the data.

If `buffer` is not valid miniSEED data, then an error is thrown.

`channels` can contain a globbing pattern which matches the 'id' string of
chennls in the file, which will be of the form
`"FDSN:NET_STA_CHA_BAND_SOURCE_POSITION"`.  By default all channels are read.

To limit data approximately to the date range `startdate` to `enddate`,
pass these as keyword arguments.  If only one of `startdate` or `enddate`
are set, respectively, then the `enddate` and `startdate` is left open.
The default is to read data from all time periods.

!!! Some data from before `startdate` or after `enddate` may be included
    as only whole blocks are returned.  You will need to cut the data
    after reading to ensure no samples outside the desired time window
    are present.

If no records match `channels`, or all data for selected channels lie
outside `startdate` to `enddate`, then an empty tracelist is returned.

By default, trace segments with gaps of less than half the nominal sampling
interval are joined together to form a single segment.  This behaviour
can be adjusted by passing a value in seconds to `time_tolerance`, in which
case segments with gaps of less than `time_tolerance` s are joined.  Pass
`time_tolerance = 0` to not merge segments with gaps.

!!! note
    `time_tolerance` can only be used on x86 and x64 platforms.  It is not
    possible to use it on PowerPC or ARM processors such as Apple Silicon ones.
    Users of these platforms will need to accept the default behaviour
    and manually join segments separated with gaps larger than the default
    tolerance.  See the note at
    https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/#Closure-cfunctions .

`verbose_level` is passed to the `libmseed` routine `mstl3_readbuffer`
to control the verbosity level, with `0` (the default) only writing
error messages to stderr, and higher numbers causing more information
to be printed.
"""
function read_buffer(buffer::Vector{UInt8};
    headers_only=false,
    channels=nothing,
    startdate=nothing,
    enddate=nothing,
    time_tolerance=nothing,
    verbose_level=0
)
    version, len = detect_buffer(buffer)
    if version === nothing
        throw(ArgumentError("data does not seem to be miniSEED"))
    end
    if len === nothing
        error("buffer length cannot be determined")
    end

    mstl = Ref(init_tracelist())
    flags = headers_only ? 0x0000 : (MSF_VALIDATECRC | MSF_UNPACKDATA)
    buffer_length = length(buffer)*sizeof(eltype(buffer))

    time_tol_func_ptr, tolerance = _get_time_tolerance_func_ptr(time_tolerance)

    selections, selecttime = if all(isnothing, (channels, startdate, enddate))
        C_NULL, C_NULL
    else
        _get_selections(channels, startdate, enddate)
    end

    GC.@preserve mstl time_tol_func_ptr selections selecttime begin
        err = @ccall libmseed.mstl3_readbuffer_selection(
            mstl[]::Ref{Ptr{MS3TraceList}},
            buffer::Ref{UInt8},
            buffer_length::UInt64,
            0::Int8,
            flags::UInt32,
            tolerance::Ptr{Cvoid},
            selections::Ptr{MS3Selections},
            verbose_level::Int8
        )::Int64

        # libmseed returns a 'not SEED data' error if no selections match
        if err == MS_NOTSEED && selections != C_NULL
            free!(mstl)
            return MseedTraceList([])
        elseif err < 0
            free!(mstl)
            check_error_value_and_throw(err)
        end

        tracelist = MseedTraceList(mstl; headers_only)
        free!(mstl)
    end

    tracelist
end

"""
    read_file(file; channels::AbstractString, startdate::DateTime, enddate::DateTime, headers_only=false, time_tolerance=nothing, verbose_level=0) -> tracelist

Read miniSEED data from `file` on disk and return `tracelist`, (a
`MseedTraceList`) containing the data.  If `headers_only` is `true`, then
only headers are read the the data are not unpacked.  In this case, the element
type of the data cannot be calculated and instead is marked as `Missing`.

If `file` does not contain valid data then an error is thrown.

`channels` can contain a globbing pattern which matches the 'id' string of
chennls in the file, which will be of the form
`"FDSN:NET_STA_CHA_BAND_SOURCE_POSITION"`.  By default all channels are read.

To limit data approximately to the date range `startdate` to `enddate`,
pass these as keyword arguments.  If only one of `startdate` or `enddate`
are set, respectively, then the `enddate` and `startdate` is left open.
The default is to read data from all time periods.

!!! Some data from before `startdate` or after `enddate` may be included
    as only whole blocks are returned.  You will need to cut the data
    after reading to ensure no samples outside the desired time window
    are present.

If no records match `channels`, or all data for selected channels lie
outside `startdate` to `enddate`, then an empty tracelist is returned.

By default, trace segments with gaps of less than half the nominal sampling
interval are joined together to form a single segment.  This behaviour
can be adjusted by passing a value in seconds to `time_tolerance`, in which
case segments with gaps of less than `time_tolerance` s are joined.  Pass
`time_tolerance = 0` to not merge segments with gaps.

!!! note
    `time_tolerance` can only be used on x86 and x64 platforms.  It is not
    possible to use it on PowerPC or ARM processors such as Apple Silicon ones.
    Users of these platforms will need to accept the default behaviour
    and manually join segments separated with gaps larger than the default
    tolerance.  See the note at
    https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/#Closure-cfunctions .

`verbose_level` is passed to the `libmseed` routine `mstl3_readtracelist_selection`
to control the verbosity level, with `0` (the default) only writing
error messages to stderr, and higher numbers causing more information
to be printed.
"""
function read_file(file;
    headers_only=false,
    channels=nothing,
    startdate=nothing,
    enddate=nothing,
    time_tolerance=nothing,
    verbose_level=0
)
    flags = headers_only ? 0x0000 : (MSF_VALIDATECRC | MSF_UNPACKDATA)
    mstl = Ref(init_tracelist())

    time_tol_func_ptr, tolerance = _get_time_tolerance_func_ptr(time_tolerance)

    selections, selecttime = if all(isnothing, (channels, startdate, enddate))
        C_NULL, C_NULL
    else
        _get_selections(channels, startdate, enddate)
    end

    GC.@preserve mstl time_tol_func_ptr selecttime selections begin
        err = @ccall libmseed.ms3_readtracelist_selection(
            mstl[]::Ref{Ptr{MS3TraceList}},
            file::Cstring,
            tolerance::Ptr{MS3Tolerance},
            selections::Ptr{MS3Selections},
            0::Int8,
            flags::UInt32,
            verbose_level::Int8
        )::Cint

        # libmseed returns a 'not SEED data' error if no selections match
        if err == MS_NOTSEED && selections != C_NULL
            free!(mstl)
            return MseedTraceList([])
        elseif err != MS_NOERROR
            free!(mstl)
            check_error_value_and_throw(err, file)
        end

        tracelist = MseedTraceList(mstl; headers_only)
        free!(mstl)
    end

    tracelist
end

"""
    write_file(file, data, sample_rate, starttime, id; append=false, verbose_level=0, compress=:steim2, pubversion=1, record_length=nothing) -> n

Write `data` in miniSEED format to `file`, returning the number of records
written `n`.  The number of samples per second  is given by `sample_rate`.

`starttime` is the date of the first sample, which must be a `Dates.DateTime`,
or an integer number of nanoseconds since $(EPOCH).

`id` is an ASCII string giving the ID of the trace.  If it is longer than
$LM_SIDLEN characters, it is truncated with a warning.

!!! note
    The libmseed library requires `id` to be in the form
    `FDSN[:AGENCY]:NET_STA_LOC_BAND_SOURCE_POSITION`, where `NET` is the network,
    `STA` is the station, `LOC` is the instrumation location code,
    `BAND` is the frequency band of recording, `SOURCE` is the code for
    the kind of instrument, and `POSITION` gives the code for the
    component orientation.  `AGENCY` gives information about the source
    of the information, but this is not standard and other tools may not
    be able to read these IDs correctly.  The Federation of Digital
    Seismograph Networks (FDSN) describes the format at
    http://docs.fdsn.org/projects/source-identifiers/en/v1.0/ .

    For version 2 files (the default to write), the following character limits
    are in place:
    - `NET`: 2
    - `STA`: 5
    - `LOC`: 2
    - `BAND`, `SOURCE` and `POSITION`: 1

    For version 3 files, the total identifier must be less than 255 characters
    long.

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

# miniSEED file version
The standard in-use version for miniSEED files is version 2, which is the
default to write.  However the libmseed library supports the newer version 3.
Note that version 2 only supports microsecond precision for times; if you
pass a `starttime` which is not representable by a whole number of
microseconds, the underlying libmseed library will truncate the time to
the whole microsecond below the time given.

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
  to disk.  By default the libmseed library determines the record length.
- `version = 2`: miniSEED file version to write (can be `2` or `3`).
  Note that little other software supports the current version `3`, so the
  default is to write version `2`.

# Example
```
julia> using Dates: DateTime

julia> data = rand(Float32, 1000);

julia> sampling_rate = 100;

julia> starttime = DateTime("2000-01-01");

julia> id = "FDSN:GB_JSA__B_H_Z";

julia> LibMseed.write_file("data.mseed", data, sampling_rate, starttime, id)
1

julia> LibMseed.read_file("data.mseed")
MseedTraceList:
 1 trace:
  "FDSN:GB_JSA__B_H_Z": 2000-01-01T00:00:00.000000000 2000-01-01T00:00:09.990000000, 1 segments
```
"""
function write_file(file, data, sample_rate, starttime, id;
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
        throw(ArgumentError("only miniSEED format versions 2 and 3 are supported"))
    typemin(NanosecondDateTime) <= starttime <= typemax(NanosecondDateTime) ||
        throw(ArgumentError("date is not representable in miniSEED"))

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

    err = @ccall libmseed.msr3_writemseed(
        msr::Ptr{MS3Record},
        file::Cstring,
        overwrite::Int8,
        flags::UInt32,
        verbose_level::Int8
    )::Int64

    if err == -1
        error("error writing records")
    end

    # If not an error, this is the number of records written
    err
end

"Determine the necessary encoding given the data type"
_encoding(::AbstractVector{<:Int32}) = DE_INT32
_encoding(::AbstractVector{<:Float32}) = DE_FLOAT32
_encoding(::AbstractVector{<:Float64}) = DE_FLOAT64
_encoding(_) = -1

"Return the sample type character code given the data type"
sample_code(::Type{Int32}) = 'i'
sample_code(::Type{Float32}) = 'f'
sample_code(::Type{Float64}) = 'd'
sample_code(::AbstractVector{<:T}) where T = sample_code(T)
sample_code(::Type{T}) where T = error("unsupported data type $T for writing")

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
    err = @ccall libmseed.ms3_detect(
        data::Ptr{Cchar}, length(data)::UInt64, version::Ref{UInt8}
    )::Cint

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
    MS_UNKNOWNFORMAT => "Unknown data encoding format",
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

"""
    _get_time_tolerance_func_ptr(time_tolerance) -> func_pointer, tolerance::MS3Tolerance

If `time_tolerance` is not `nothing`, create a closure over
`time_tolerance` and return a `Base.CFunction` and an `MS3Tolerance`
containing a reference to the function.

`func_pointer` should be guarded in a `Base.@GC_preserve` block when
`tolerance` is used to avoid the former being garbage collected.

We have to use a Julia closure to create a `CFunction`, but this is unsupported
on PowerPC and ARM, so this function throws an error if `time_tolerance`
is not `nothing` on these and other non-x86 and -x86_64 platforms.  (See
https://github.com/JuliaLang/julia/issues/27174 and
https://github.com/JuliaLang/julia/issues/32154 .
)
"""
function _get_time_tolerance_func_ptr(time_tolerance)
    time_tol_func_ptr = if time_tolerance !== nothing
        # Error out on unsupported platforms
        if !(Sys.ARCH === :i686 || Sys.ARCH === :x86_64)
            error("use of the time_tolerance option is not supported on ARM or PowerPC")
        end
        # Create a closure to pass to libmseed to set the time tolerance by
        # which traces are joined up.
        time_tolerance_func(::Ptr{MS3Record})::Cdouble = time_tolerance
        # Pointer to put in MS3Tolerance struct
        @cfunction($time_tolerance_func, Cdouble, (Ptr{MS3Record},))
    else
        # Otherwise use default
        C_NULL
    end

    tolerance = Ref(MS3Tolerance(
        Base.unsafe_convert(Ptr{Cvoid}, time_tol_func_ptr),
        C_NULL)
    )

    time_tol_func_ptr, tolerance
end

"""
    _get_selections(channels, startdate, enddate) -> selections, selecttime

Create `MS3Selections` and `MS3SelectTime` objects containing the
globbing pattern in `channels` and the date range specified by `startdate`
and `enddate`.
"""
function _get_selections(channels, startdate, enddate)
    if isnothing(channels)
        channels = "*"
    elseif !isascii(channels)
        throw(ArgumentError("channel ID matching patterns must be ASCII text"))
    end

    sidtype = fieldtype(MS3Selections, :sidpattern)

    starttime = if isnothing(startdate)
        NSTUNSET
    else
        convert(nstime_t, NanosecondDateTime(startdate))
    end
    endtime = if isnothing(enddate)
        NSTUNSET
    else
        convert(nstime_t, NanosecondDateTime(enddate))
    end

    selecttime = Ref(MS3SelectTime(starttime, endtime, C_NULL))

    selections = Ref(MS3Selections(
        _to_c_string(sidtype, isnothing(channels) ? "*" : channels),
        pointer_from_objref(selecttime),
        C_NULL,
        0
    ))

    # Pass both back to ensure nothing gets unduly garbage collected
    selections, selecttime
end

"""
    _to_c_string(::Type{NTuple{N,T}}, s::AbstractString) where {N,T} -> c_string

Convert a string `s` into an `NTuple{N,T}` of `T`s, throwing an error
if `s` is longer than `N` ASCII characters, and if `s` is not ASCII.
Extra space in `c_string` is filled with 0 values.
"""
function _to_c_string(::Type{NTuple{N,T}}, s::AbstractString) where {N,T}
    isascii(s) || throw(ArgumentError("string must be ASCII"))
    n = length(s)
    length(s) > N && throw(ArgumentError("string is too long"))
    let n = n, s = s
        ntuple(i -> i <= n ? T(s[i]) : T(0x0), N)
    end
end
