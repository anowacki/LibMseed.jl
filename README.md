# LibMseed.jl

[![Build Status](https://github.com/anowacki/LibMseed.jl/workflows/CI/badge.svg)](https://github.com/anowacki/LibMseed.jl/actions)
[![Code coverage](https://codecov.io/gh/anowacki/LibMseed.jl/branch/main/graph/badge.svg?token=zZLUNA3tJk)](https://codecov.io/gh/anowacki/LibMseed.jl)

LibMseed.jl is a Julia wrapper around the
[libmseed](https://github.com/EarthScope/libmseed) library for reading
and writing data in the miniSEED format.

## Installation
### Dependencies
- Julia v1.6 or later.

### Installation instructions
You can install LibMseed.jl from Julia's package manager like so:

```julia
julia> using Pkg; Pkg.add("LibMseed")
```

You do not need to separately install the `libmseed` library.  Instead,
LibMseed.jl installs its own version automatically.

## Using the package

`LibMseed` exports several functions with common names, such as `read_file`
and `write_file`.  It is recommended to either explicitly import the functions
you need, or always prepend names with `LibMseed`.

### Reading data from disk
Use `read_file` function to read miniSEED data
from disk.  Here we assume you have a file called `example.mseed` in the
current directory.

```julia
julia> import LibMseed

julia> ms = LibMseed.read_file("example.mseed")
MseedTraceList:
 2 traces:
  "FDSN:GB_CWF__B_H_Z": 2008-02-27T00:56:45.404999000 2008-02-27T00:57:45.384999000, 1 segments
  "FDSN:GB_CWF__H_H_Z": 2008-02-27T00:56:45.409999000 2008-02-27T00:57:45.399999000, 1 segments
```

### Reading data from memory
Use the `LibMseed.read_buffer` function to read miniSEED data
from memory.  This data should be a `Vector` of `UInt8`s.

```julia
julia> data = read("example.mseed") # This may have been downloaded from the internet, for example
26624-element Vector{UInt8}
0x00
⋮
0x00

julia> ms = LibMseed.read_buffer(data)
MseedTraceList:
 2 traces:
  "FDSN:GB_CWF__B_H_Z": 2008-02-27T00:56:45.404999000 2008-02-27T00:57:45.384999000, 1 segments
  "FDSN:GB_CWF__H_H_Z": 2008-02-27T00:56:45.409999000 2008-02-27T00:57:45.399999000, 1 segments
```

### Reading specific channels or time ranges
`read_file` and `read_buffer` support the `startdate`, `enddate` and
`channels` keyword arguments.

`startdate` and `enddate` limit the time window read, but the underlying
libmseed library does not ensure that the first sample of the traces
returned is at the start date requested, so you may need to further trim
traces:

```julia
julia> using Dates: DateTime

julia> file = joinpath(dirname(pathof(LibMseed)), "..", "test", "data", "Int32-oneseries-mixedlengths-mixedorder.mseed");

julia> ms = LibMseed.read_file(file)
MseedTraceList:
 1 trace:
  "FDSN:XX_TEST_00_L_H_Z": 2010-02-27T06:50:00.069539000 2010-02-27T07:55:51.069539000, 1 segments

julia> LibMseed.read_file(file; startdate=DateTime(2010, 2, 27, 7, 45))
MseedTraceList:
 1 trace:
  "FDSN:XX_TEST_00_L_H_Z": 2010-02-27T07:22:00.069539000 2010-02-27T07:55:51.069539000, 1 segments
```

`channels` is a string which is matched against the
[FDSN source ID](http://docs.fdsn.org/projects/source-identifiers/en/v1.0/)
of each channel to determine whether to read it.  `*` indicates any number
of any character (including zero), while `?` indicates exactly one character
of any kind.  E.g., `FDSN:GB_*Z` matches all vertical channels in the
GB network.


### Accessing data
`LibMseed.read_file` returns a `LibMseed.MseedTraceList`, which is a structure
holding an arbitrary number of traces (corresonding to individual channels),
each of which may hold an arbitrary number of segments.

Access the traces within the `MseedTraceList` object via its `traces`
property:

```julia
julia> ms.traces
2-element Vector{LibMseed.MseedTraceID}:
 LibMseed.MseedTraceID{Int32}("FDSN:GB_CWF__B_H_Z", NanosecondDateTime("2008-02-27T00:56:45.404999000"), NanosecondDateTime("2008-02-27T00:57:45.384999000"), LibMseed.MseedTraceSegment{Int32}[LibMseed.MseedTraceSegment{Int32}(NanosecondDateTime("2008-02-27T00:56:45.404999000"), NanosecondDateTime("2008-02-27T00:57:45.384999000"), 50.0, 3000, Int32[1466, 1466, 1453, 1449, 1449, 1443, 1441, 1443, 1444, 1439  …  -12421, -15146, 6993, 32994, 34813, 29718, 17484, 4468, 13498, 21614])])
 LibMseed.MseedTraceID{Int32}("FDSN:GB_CWF__H_H_Z", NanosecondDateTime("2008-02-27T00:56:45.409999000"), NanosecondDateTime("2008-02-27T00:57:45.399999000"), LibMseed.MseedTraceSegment{Int32}[LibMseed.MseedTraceSegment{Int32}(NanosecondDateTime("2008-02-27T00:56:45.409999000"), NanosecondDateTime("2008-02-27T00:57:45.399999000"), 100.0, 6000, Int32[1469, 1469, 1463, 1465, 1447, 1449, 1457, 1450, 1447, 1446  …  28750, 19408, 13748, 9836, -1323, 11130, 21097, 20900, 14103, 10817])])
```

Each trace is a `LibMseed.MseedTraceID` which has a single channel code.
It may be divided up into several non-contiguous segments, which can be
accessed by the `MseedTraceID`'s `segments` property:

```julia
julia> ms.traces[1].segments
1-element Vector{LibMseed.MseedTraceSegment{Int32}}:
 LibMseed.MseedTraceSegment{Int32}(NanosecondDateTime("2008-02-27T00:56:45.404999000"), NanosecondDateTime("2008-02-27T00:57:45.384999000"), 50.0, 3000, Int32[1466, 1466, 1453, 1449, 1449, 1443, 1441, 1443, 1444, 1439  …  -12421, -15146, 6993, 32994, 34813, 29718, 17484, 4468, 13498, 21614])
```

Here, the channel GB.CWF..BHZ has only one segment.  The raw data can
be obtained by accessing that segment's `data` property:

```julia
julia> ms.traces[1].segments[1].data
3000-element Vector{Int32}:
   1466
   1466
      ⋮
  13498
  21614
```

Note that the data element type is a parameter of the channel's `MseedTraceID`
object and each segment of a trace must have the same element type.

### Channel naming of input data
Channel names are simply read from the miniSEED file or data and may
or may not be in a standard SEED format.  However, you can use the
unexported `LibMseed.channel_code_parts` on a `MseedTraceID` or a string
to try and split the channel's ID into network, station, location and
channel as in traditional SEED conventions:

```julia
julia> LibMseed.channel_code_parts(ms.traces[1])
(net = "GB", sta = "CWF", loc = "", cha = "BHZ")
```

`LibMseed.channel_code_parts` returns a named tuple with the component
parts.  If a trace ID doesn't seem to correspond to the
network-station-location-channel format, then the whole ID string is
returned in the `sta` field of the named tuple and all other fields are
set to `""` (the empty string).

### Writing data
To write a continuous set of evenly-spaced samples to disk in miniSEED
format, use the `LibMseed.write_file` function.

Here we create some random data, set the necessary parameters (including
the date of the first sample) and write it to a new file, `"example2.mseed"`.

```julia
julia> using Dates: DateTime

julia> data = randn(1000);

julia> sampling_rate = 100; # Hz

julia> id = "FDSN:XX_STA_00_H_H_Z";

julia> starttime = DateTime(2000);

julia> LibMseed.write_file("example2.mseed", data, sampling_rate, starttime, id)
2
```

If we wanted to add a separate segment of data for this channel, or a
different channel entirely, then we can call `write_file` again but
use the `append=true` keyword argument:

```julia
julia> data2 = randn(100)

julia> starttime2 = DateTime(2000, 1, 1, 12);

julia> LibMseed.write_file("example2.mseed", data2, sampling_rate, starttime2, id; append=true)
1

julia> ms2 = LibMseed.read_file("example2.mseed")
MseedTraceList:
 1 trace:
  "FDSN:XX_STA_00_H_H_Z": 2000-01-01T00:00:00.000000000 2000-01-01T12:00:00.990000000, 2 segments

julia> segs = only(ms2.traces).segments;

julia> getproperty.(segs, [:starttime :endtime]) # One row per segment, start and end time
2×2 Matrix{LibMseed.NanosecondDateTime}:
 2000-01-01T00:00:00.000000000  …  2000-01-01T00:00:09.990000000
 2000-01-01T12:00:00.000000000     2000-01-01T12:00:00.990000000
```

#### Note on channel naming
Note that the libmseed library requires that the trace ID has the form
shown above, i.e. `"FDSN:NET_STA_LOC_BAND_SOURCE_POSITION"`, otherwise
an error is thrown.

### Time resolution
The time of the first sample (the `starttime` in the example above,
or the property `starttime` of a segment) is stored to nanosecond
precision in the miniSEED file.  The standard library `Dates` module
cannot handle nanosecond resolution `Dates.DateTime`s, and so time is
implemented in LibMseed.jl via the `LibMseed.NanosecondDateTime` type.

You can convert a `NanosecondDateTime` to the nearest `Dates.DateTime`
(precise to the millisecond) with `LibMseed.nearest_datetime`.  Use
`Dates.Time` to obtain the time of day to full nanosecond resolution.

```julia
julia> t = ms.traces[1].segments[1].starttime
2008-02-27T00:56:45.404999000

julia> LibMseed.nearest_datetime(t)
2008-02-27T00:56:45.405

julia> using Dates: Time

julia> Time(t)
00:56:45.404999
```

## More help
Each of the functions described above is further documented via its
docstring.

## Contributing
Pull requests to add functionality and fix bugs are welcome.  To report
a bug or feature request in the software, please
[open an issue](https://github.com/anowacki/LibMseed.jl/issues/new).


