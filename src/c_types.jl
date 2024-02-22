# Constants and types defined in libmseed.h, originally built with
# Clang.jl but edited by hand.  Must be updated when libmseed.h
# changes.

"C file handle not used in the module"
const FILE = Cvoid

"Maximum length of a station ID string"
const LM_SIDLEN = 64

# Encodings
const DE_TEXT = 0
const DE_INT16 = 1
const DE_INT32 = 3
const DE_FLOAT32 = 4
const DE_FLOAT64 = 5
const DE_STEIM1 = 10
const DE_STEIM2 = 11
const DE_GEOSCOPE24 = 12
const DE_GEOSCOPE163 = 13
const DE_GEOSCOPE164 = 14
const DE_CDSN = 16
const DE_SRO = 30
const DE_DWWSSN = 32
const MSSWAP_HEADER = 0x01
const MSSWAP_PAYLOAD = 0x02
const MS_ENDOFFILE = 1
const MS_NOERROR = 0
const MS_GENERROR = -1
const MS_NOTSEED = -2
const MS_WRONGLENGTH = -3
const MS_OUTOFRANGE = -4
const MS_UNKNOWNFORMAT = -5
const MS_STBADCOMPFLAG = -6
const MS_INVALIDCRC = -7
const MSF_UNPACKDATA = 0x0001
const MSF_SKIPNOTDATA = 0x0002
const MSF_VALIDATECRC = 0x0004
const MSF_PNAMERANGE = 0x0008
const MSF_ATENDOFFILE = 0x0010
const MSF_SEQUENCE = 0x0020
const MSF_FLUSHDATA = 0x0040
const MSF_PACKVER2 = 0x0080
const MSF_RECORDLIST = 0x0100
const MSF_MAINTAINMSTL = 0x0200

"Integer type used for times in the C library"
const nstime_t = Int64

# C structs used for libmseed
@eval struct MS3Record
    record::Cstring
    reclen::Int32
    swapflag::UInt8
    sid::NTuple{$LM_SIDLEN, UInt8}
    formatversion::UInt8
    flags::UInt8
    starttime::nstime_t
    samprate::Cdouble
    encoding::Int8
    pubversion::UInt8
    samplecnt::Int64
    crc::UInt32
    extralength::UInt16
    datalength::UInt32
    extra::Cstring
    datasamples::Ptr{Cvoid}
    datasize::Csize_t
    numsamples::Int64
    sampletype::UInt8
end

struct MS3SelectTime
    starttime::nstime_t
    endtime::nstime_t
    next::Ptr{MS3SelectTime}
end

struct MS3Selections
    sidpattern::NTuple{100, UInt8}
    timewindows::Ptr{MS3SelectTime}
    next::Ptr{MS3Selections}
    pubversion::UInt8
end

struct MS3RecordPtr
    bufferptr::Cstring
    fileptr::Ptr{FILE}
    filename::Cstring
    fileoffset::Int64
    msr::Ptr{MS3Record}
    endtime::nstime_t
    dataoffset::UInt32
    prvtptr::Ptr{Cvoid}
    next::Ptr{MS3RecordPtr}
end

struct MS3RecordList
    recordcnt::UInt64
    first::Ptr{MS3RecordPtr}
    last::Ptr{MS3RecordPtr}
end

struct MS3TraceSeg
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
    prev::Ptr{MS3TraceSeg}
    next::Ptr{MS3TraceSeg}
end

const MSTRACEID_SKIPLIST_HEIGHT = 8

@eval struct MS3TraceID
    sid::NTuple{$LM_SIDLEN, UInt8}
    pubversion::UInt8
    earliest::nstime_t
    latest::nstime_t
    prvtptr::Ptr{Cvoid}
    numsegments::UInt32
    first::Ptr{MS3TraceSeg}
    last::Ptr{MS3TraceSeg}
    next::NTuple{$MSTRACEID_SKIPLIST_HEIGHT, Ptr{MS3TraceID}}
    height::UInt8
end

struct MS3TraceList
    numtraceids::UInt32
    traces::MS3TraceID
    prngstate::UInt64
end

struct MS3Tolerance
    time::Ptr{Cvoid}
    samprate::Ptr{Cvoid}
end

"""
    init_tracelist(; verbose=false) -> mstl::Ptr{MS3TraceList}

Create a new `MS3TraceList`, and return a pointer to it.

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
    mstl = @ccall libmseed.mstl3_init(C_NULL::Ptr{Cvoid})::Ptr{MS3TraceList}
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
function free!(mstl::Ref{Ptr{MS3TraceList}})
    @debug("Freeing trace memory at $(mstl[])")
    @ccall libmseed.mstl3_free(mstl::Ref{Ptr{MS3TraceList}}, 0::Int8)::Cvoid
    @debug("Pointer now set to $(mstl[])")
    nothing
end

