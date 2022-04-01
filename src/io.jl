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
sample_code() = error("unsupported data type $T for writing")

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
