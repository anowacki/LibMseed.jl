# Automatically generated using Clang.jl


const LIBMSEED_H = 1
const LIBMSEED_VERSION = "3.0.8"
const LIBMSEED_RELEASE = "2020.156"
const PRIsize_t = "zu"
const MINRECLEN = 40
const MAXRECLEN = 131172
const LM_SIDLEN = 64

# Skipping MacroDefinition: MS_ISRATETOLERABLE ( A , B ) ( ms_dabs ( 1.0 - ( ( A ) / ( B ) ) ) < 0.0001 )
# Skipping MacroDefinition: MS2_ISDATAINDICATOR ( X ) ( ( X ) == 'D' || ( X ) == 'R' || ( X ) == 'Q' || ( X ) == 'M' )
# Skipping MacroDefinition: MS3_ISVALIDHEADER ( X ) ( * ( X ) == 'M' && * ( ( X ) + 1 ) == 'S' && * ( ( X ) + 2 ) == 3 && ( uint8_t ) ( * ( ( X ) + 12 ) ) >= 0 && ( uint8_t ) ( * ( ( X ) + 12 ) ) <= 23 && ( uint8_t ) ( * ( ( X ) + 13 ) ) >= 0 && ( uint8_t ) ( * ( ( X ) + 13 ) ) <= 59 && ( uint8_t ) ( * ( ( X ) + 14 ) ) >= 0 && ( uint8_t ) ( * ( ( X ) + 14 ) ) <= 60 )
# Skipping MacroDefinition: MS2_ISVALIDHEADER ( X ) ( ( isdigit ( ( uint8_t ) * ( X ) ) || * ( X ) == ' ' || ! * ( X ) ) && ( isdigit ( ( uint8_t ) * ( ( X ) + 1 ) ) || * ( ( X ) + 1 ) == ' ' || ! * ( ( X ) + 1 ) ) && ( isdigit ( ( uint8_t ) * ( ( X ) + 2 ) ) || * ( ( X ) + 2 ) == ' ' || ! * ( ( X ) + 2 ) ) && ( isdigit ( ( uint8_t ) * ( ( X ) + 3 ) ) || * ( ( X ) + 3 ) == ' ' || ! * ( ( X ) + 3 ) ) && ( isdigit ( ( uint8_t ) * ( ( X ) + 4 ) ) || * ( ( X ) + 4 ) == ' ' || ! * ( ( X ) + 4 ) ) && ( isdigit ( ( uint8_t ) * ( ( X ) + 5 ) ) || * ( ( X ) + 5 ) == ' ' || ! * ( ( X ) + 5 ) ) && MS2_ISDATAINDICATOR ( * ( ( X ) + 6 ) ) && ( * ( ( X ) + 7 ) == ' ' || * ( ( X ) + 7 ) == '\0' ) && ( uint8_t ) ( * ( ( X ) + 24 ) ) >= 0 && ( uint8_t ) ( * ( ( X ) + 24 ) ) <= 23 && ( uint8_t ) ( * ( ( X ) + 25 ) ) >= 0 && ( uint8_t ) ( * ( ( X ) + 25 ) ) <= 59 && ( uint8_t ) ( * ( ( X ) + 26 ) ) >= 0 && ( uint8_t ) ( * ( ( X ) + 26 ) ) <= 60 )
# Skipping MacroDefinition: bit ( x , y ) ( ( x ) & ( y ) ) ? 1 : 0

const NSTMODULUS = 1000000000
const NSTERROR = -(Int64(2145916800000000000))

# Skipping MacroDefinition: MS_EPOCH2NSTIME ( X ) ( X ) * ( nstime_t ) NSTMODULUS
# Skipping MacroDefinition: MS_NSTIME2EPOCH ( X ) ( X ) / NSTMODULUS
# Skipping MacroDefinition: mstl3_addmsr ( mstl , msr , splitversion , autoheal , flags , tolerance ) mstl3_addmsr_recordptr ( mstl , msr , NULL , splitversion , autoheal , flags , tolerance )
# Skipping MacroDefinition: LMIO_INITIALIZER { . type = LMIO_NULL , . handle = NULL , . handle2 = NULL , . still_running = 0 }
# Skipping MacroDefinition: MS3FileParam_INITIALIZER { . path = "" , . startoffset = 0 , . endoffset = 0 , . streampos = 0 , . recordcount = 0 , . readbuffer = NULL , . readlength = 0 , . readoffset = 0 , . flags = 0 , . input = LMIO_INITIALIZER }
# Skipping MacroDefinition: mseh_get ( msr , path , valueptr , type , maxlength ) mseh_get_path ( msr , path , valueptr , type , maxlength )
# Skipping MacroDefinition: mseh_get_number ( msr , path , valueptr ) mseh_get_path ( msr , path , valueptr , 'n' , 0 )
# Skipping MacroDefinition: mseh_get_string ( msr , path , buffer , maxlength ) mseh_get_path ( msr , path , buffer , 's' , maxlength )
# Skipping MacroDefinition: mseh_get_boolean ( msr , path , valueptr ) mseh_get_path ( msr , path , valueptr , 'b' , 0 )
# Skipping MacroDefinition: mseh_exists ( msr , path ) ( ! mseh_get_path ( msr , path , NULL , 0 , 0 ) )
# Skipping MacroDefinition: mseh_set ( msr , path , valueptr , type ) mseh_set_path ( msr , path , valueptr , type )
# Skipping MacroDefinition: mseh_set_number ( msr , path , valueptr ) mseh_set_path ( msr , path , valueptr , 'n' )
# Skipping MacroDefinition: mseh_set_string ( msr , path , valueptr ) mseh_set_path ( msr , path , valueptr , 's' )
# Skipping MacroDefinition: mseh_set_boolean ( msr , path , valueptr ) mseh_set_path ( msr , path , valueptr , 'b' )

const MAX_LOG_MSG_LENGTH = 200

# Skipping MacroDefinition: MSLogRegistry_INITIALIZER { . maxmessages = 0 , . messagecnt = 0 , . messages = NULL }
# Skipping MacroDefinition: MSLogParam_INITIALIZER { . log_print = NULL , . logprefix = NULL , . diag_print = NULL , . errprefix = NULL , . registry = MSLogRegistry_INITIALIZER }
# Skipping MacroDefinition: ms_log ( level , ... ) ms_rlog ( __func__ , level , __VA_ARGS__ )
# Skipping MacroDefinition: ms_log_l ( logp , level , ... ) ms_rlog_l ( logp , __func__ , level , __VA_ARGS__ )
# Skipping MacroDefinition: ms_loginit ( log_print , logprefix , diag_print , errprefix ) ms_rloginit ( log_print , logprefix , diag_print , errprefix , 0 )
# Skipping MacroDefinition: ms_loginit_l ( logp , log_print , logprefix , diag_print , errprefix ) ms_rloginit_l ( logp , log_print , logprefix , diag_print , errprefix , 0 )

const DE_ASCII = 0
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
const nstime_t = Int64

@cenum ms_timeformat_t::UInt32 begin
    ISOMONTHDAY = 0
    ISOMONTHDAY_SPACE = 1
    SEEDORDINAL = 2
    UNIXEPOCH = 3
    NANOSECONDEPOCH = 4
end

@cenum ms_subseconds_t::UInt32 begin
    NONE = 0
    MICRO = 1
    NANO = 2
    MICRO_NONE = 3
    NANO_NONE = 4
    NANO_MICRO = 5
    NANO_MICRO_NONE = 6
end


struct MS3Record
    record::Cstring
    reclen::Int32
    swapflag::UInt8
    sid::NTuple{64, UInt8}
    formatversion::UInt8
    flags::UInt8
    starttime::nstime_t
    samprate::Cdouble
    encoding::Int8
    pubversion::UInt8
    samplecnt::Int64
    crc::UInt32
    extralength::UInt16
    datalength::UInt16
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

struct MS3TraceID
    sid::NTuple{64, UInt8}
    pubversion::UInt8
    earliest::nstime_t
    latest::nstime_t
    prvtptr::Ptr{Cvoid}
    numsegments::UInt32
    first::Ptr{MS3TraceSeg}
    last::Ptr{MS3TraceSeg}
    next::Ptr{MS3TraceID}
end

struct MS3TraceList
    numtraces::UInt32
    traces::Ptr{MS3TraceID}
    last::Ptr{MS3TraceID}
end

struct MS3Tolerance
    time::Ptr{Cvoid}
    samprate::Ptr{Cvoid}
end

struct MS3FileParam
    path::NTuple{512, UInt8}
    startoffset::Int64
    endoffset::Int64
    streampos::Int64
    recordcount::Int64
    readbuffer::Cstring
    readlength::Cint
    readoffset::Cint
    flags::UInt32
    input::LMIO
end

struct MSEHEventDetection
    type::NTuple{30, UInt8}
    detector::NTuple{30, UInt8}
    signalamplitude::Cdouble
    signalperiod::Cdouble
    backgroundestimate::Cdouble
    wave::NTuple{30, UInt8}
    units::NTuple{30, UInt8}
    onsettime::nstime_t
    medsnr::NTuple{6, UInt8}
    medlookback::Cint
    medpickalgorithm::Cint
    next::Ptr{MSEHEventDetection}
end

struct MSEHCalibration
    type::NTuple{30, UInt8}
    begintime::nstime_t
    endtime::nstime_t
    steps::Cint
    firstpulsepositive::Cint
    alternatesign::Cint
    trigger::NTuple{30, UInt8}
    continued::Cint
    amplitude::Cdouble
    inputunits::NTuple{30, UInt8}
    amplituderange::NTuple{30, UInt8}
    duration::Cdouble
    sineperiod::Cdouble
    stepbetween::Cdouble
    inputchannel::NTuple{30, UInt8}
    refamplitude::Cdouble
    coupling::NTuple{30, UInt8}
    rolloff::NTuple{30, UInt8}
    noise::NTuple{30, UInt8}
    next::Ptr{MSEHCalibration}
end

struct MSEHTimingException
    vcocorrection::Cfloat
    time::nstime_t
    usec::Cint
    receptionquality::Cint
    count::UInt32
    type::NTuple{16, UInt8}
    clockstatus::NTuple{128, UInt8}
end

struct MSEHRecenter
    type::NTuple{30, UInt8}
    begintime::nstime_t
    endtime::nstime_t
    trigger::NTuple{30, UInt8}
end

struct MSLogEntry
    level::Cint
    _function::NTuple{30, UInt8}
    message::NTuple{200, UInt8}
    next::Ptr{MSLogEntry}
end

struct MSLogRegistry
    maxmessages::Cint
    messagecnt::Cint
    messages::Ptr{MSLogEntry}
end

struct MSLogParam
    log_print::Ptr{Cvoid}
    logprefix::Cstring
    diag_print::Ptr{Cvoid}
    errprefix::Cstring
    registry::MSLogRegistry
end

struct LeapSecond
    leapsecond::nstime_t
    TAIdelta::Int32
    next::Ptr{LeapSecond}
end

const flag = Int8

struct LIBMSEED_MEMORY
    malloc::Ptr{Cvoid}
    realloc::Ptr{Cvoid}
    free::Ptr{Cvoid}
end
