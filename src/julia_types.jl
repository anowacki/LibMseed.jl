# Julia types which expose functionality to the user

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
    MseedTraceList(mstl::Ref{Ptr{MS3TraceList}})

Construct a `MseedTraceList` from a reference to a `MS3TraceList` struct
obtained from a call to one of `libmseed`'s functions.

This function builds a full `MseedTraceList` and copies the data from
`mstl`.
"""
function MseedTraceList(mstl::Ref{Ptr{MS3TraceList}})
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
    MseedTraceID(this_traceid::MS3TraceID)

Construct a `MseedTraceID` from a `MS3TraceID` object, obtained from
a call to one of `libmseed`'s functions.
"""
function MseedTraceID(this_traceid::MS3TraceID)
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
    MseedTraceSegment(T, this_traceseg::MS3TraceSeg) -> segment

Construct a `MseedTraceSegment{T}` from `MS3TraceSeg` object obtained
from a call to one of `libmseed`'s functions.
"""
function MseedTraceSegment(T, this_traceseg::MS3TraceSeg)
    starttime = NanosecondDateTime(this_traceseg.starttime)
    endtime = NanosecondDateTime(this_traceseg.endtime)
    sample_rate = this_traceseg.samprate
    sample_count = this_traceseg.samplecnt
    numsamples = Int(this_traceseg.numsamples)
    samples_ptr = convert(Ptr{T}, this_traceseg.datasamples)
    data = unsafe_wrap(Vector{T}, samples_ptr, numsamples)
    MseedTraceSegment{T}(starttime, endtime, sample_rate, sample_count, copy(data))
end
