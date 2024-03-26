import Dates
using Dates: DateTime, Second, Millisecond
using LibMseed
using Test

"Return the path to a test data file, given just its name"
testfile(path...) = joinpath(@__DIR__, "data", path...)

"List of files which should throw an error in the libmseed library when read"
error_files = (
    "corrupt-blockettes-wrongnext.mseed",
    "detection.record.mseed",
    "text-encoded.mseed",
)

"Set of files which should be read successfully"
good_files = collect(f for f in readdir(testfile())
                     if !(f in (error_files..., "no-blockette1000-steim1.mseed")))

"""
    _capture(redirect_func, f) -> (output, return)

Redirect either stdout or stderr and return a named tuple of the
string written to stdout/stderr `output`, and whatever the zero-argument
function `f` returns in `return`.

To capture stdout, pass `redirect_stdout` to `redirect_func`; for
sterr, pass `redirect_stderr`.  Whatever `redirect_func` is, it should
take two arguments: a zero-argument function and an `IOStream` or file
name.

!!! note
    This function works around an issue in `Base.redirect_std{out,err}`
    where std{out,err} from ccall does not get captured
    properly; a call to `Base.Libc.flush_cstdio` is needed.  See
        https://discourse.julialang.org/t/redirect-stdout-and-stderr/13424/5
    and
        https://github.com/JuliaLang/julia/issues/31236
"""
function _capture(redirect_func, f)
    mktempdir() do dir
        path = joinpath(dir, "test_file")
        var"return" = open(path, "w") do io
            redirect_func(io) do
                val = f()
                Base.Libc.flush_cstdio()
                val
            end
        end
        output = String(read(path))
        (output=output, var"return"=var"return")
    end
end

capture_stdout(f) = _capture(redirect_stdout, f)
capture_stderr(f) = _capture(redirect_stderr, f)

@testset "IO" begin
    @testset "sample_type" begin
        @test LibMseed.sample_type('f') == Float32
        @test LibMseed.sample_type('d') == Float64
        @test LibMseed.sample_type('i') == Int32
        @test_throws ErrorException LibMseed.sample_type('a')
        for c in "bceghjklmnopqrstuvwxyz"
            @test_throws ErrorException LibMseed.sample_type(c)
        end
    end

    @testset "sample_code" begin
        @test LibMseed.sample_code(Float32) == 'f'
        @test LibMseed.sample_code(Float64) == 'd'
        @test LibMseed.sample_code(Int32) == 'i'
        @test LibMseed.sample_code(rand(Float32, 3)) == 'f'
        @test LibMseed.sample_code(rand(Float64, 3)) == 'd'
        @test LibMseed.sample_code(rand(Int32, 3)) == 'i'
        @testset "Vector{$t}" for t in (Float16, Int64, Int128, BigFloat, BigInt, Complex{Float32})
            @test_throws ErrorException LibMseed.sample_code(t)
            if t != BigInt
                @test_throws ErrorException LibMseed.sample_code(rand(t, 3))
            end
        end
    end

    @testset "File/buffer reading" begin
        @testset "Errors" begin
            @testset "$file" for file in error_files
                capture_stdout() do
                    capture_stderr() do
                        @test_throws ErrorException LibMseed.read_file(testfile(file))
                        @test_throws ErrorException LibMseed.read_buffer(read(testfile(file)))
                    end
                end
            end
        end

        @testset "File v buffer" begin
            @testset "$filename" for filename in good_files
                file = testfile(filename)
                mf = LibMseed.read_file(file)
                mb = LibMseed.read_buffer(read(file))
                @test mf == mb
            end
        end

        @testset "detect_buffer" begin
            @test LibMseed.detect_buffer(UInt8[1,2,3]) == (nothing, nothing)
        end

        @testset "read_buffer" begin
            @testset "Not SEED" begin
                @test_throws ArgumentError LibMseed.read_buffer(UInt8[1,2,3])
            end

            @testset "time_tolerance" begin
                @testset "Join segments" begin
                    mktempdir() do dir
                        file = joinpath(dir, "test.mseed")
                        startdatetime = DateTime(2000)
                        for i in 1:3
                            data = rand(Float32, 3)
                            write_file(file, data, 1, startdatetime, "FDSN:NT_STA_LO_C_H_A";
                                append=true)
                            startdatetime += Second(3) + (isodd(i) ? 1 : -1)*Millisecond(1)
                        end
                        ms = read_buffer(read(file); time_tolerance=0.001)
                        @test length(ms.traces[1].segments) == 1
                        seg = ms.traces[1].segments[1]
                        @test seg.starttime == NanosecondDateTime("2000-01-01T")
                        @test seg.endtime == NanosecondDateTime("2000-01-01T00:00:08")
                    end
                end

                @testset "Keep segments separate" begin
                    mktempdir() do dir
                        file = joinpath(dir, "test.mseed")
                        startdatetime = DateTime(2000)
                        for i in 1:3
                            data = rand(Float32, 3)
                            write_file(file, data, 1, startdatetime, "FDSN:NT_STA_LO_C_H_A";
                                append=true)
                            startdatetime += Second(3) + (isodd(i) ? 1 : -1)*Millisecond(1)
                        end
                        ms = read_buffer(read(file); time_tolerance=0.0005)
                        @test length(ms.traces[1].segments) == 3
                        segs = ms.traces[1].segments
                        @test segs[1].starttime == NanosecondDateTime("2000-01-01T")
                        @test segs[2].starttime == NanosecondDateTime("2000-01-01T00:00:03.001")
                        @test segs[2].endtime == NanosecondDateTime("2000-01-01T00:00:05.001")
                        @test segs[3].starttime == NanosecondDateTime("2000-01-01T00:00:06")
                        @test segs[3].endtime == NanosecondDateTime("2000-01-01T00:00:08")
                    end
                end
            end
        end

        @testset "read_file" begin
            @testset "time_tolerance" begin
                @testset "Join segments" begin
                    mktempdir() do dir
                        file = joinpath(dir, "test.mseed")
                        startdatetime = DateTime(2000)
                        for i in 1:3
                            data = rand(Float32, 3)
                            write_file(file, data, 1, startdatetime, "FDSN:NT_STA_LO_C_H_A";
                                append=true)
                            startdatetime += Second(3) + (isodd(i) ? 1 : -1)*Millisecond(1)
                        end
                        ms = read_file(file; time_tolerance=0.001)
                        @test length(ms.traces[1].segments) == 1
                        seg = ms.traces[1].segments[1]
                        @test seg.starttime == NanosecondDateTime("2000-01-01T")
                        @test seg.endtime == NanosecondDateTime("2000-01-01T00:00:08")
                    end
                end

                @testset "Keep segments separate" begin
                    mktempdir() do dir
                        file = joinpath(dir, "test.mseed")
                        startdatetime = DateTime(2000)
                        for i in 1:3
                            data = rand(Float32, 3)
                            write_file(file, data, 1, startdatetime, "FDSN:NT_STA_LO_C_H_A";
                                append=true)
                            startdatetime += Second(3) + (isodd(i) ? 1 : -1)*Millisecond(1)
                        end
                        ms = read_file(file; time_tolerance=0.0005)
                        @test length(ms.traces[1].segments) == 3
                        segs = ms.traces[1].segments
                        @test segs[1].starttime == NanosecondDateTime("2000-01-01T")
                        @test segs[2].starttime == NanosecondDateTime("2000-01-01T00:00:03.001")
                        @test segs[2].endtime == NanosecondDateTime("2000-01-01T00:00:05.001")
                        @test segs[3].starttime == NanosecondDateTime("2000-01-01T00:00:06")
                        @test segs[3].endtime == NanosecondDateTime("2000-01-01T00:00:08")
                    end
                end
            end
        end

        @testset "Headers only" begin
            capture_stdout() do
                capture_stderr() do
                    @testset "File" begin
                        @testset "$file" for file in good_files
                            ms = read_file(testfile(file); headers_only=true)
                            ms_with_data = read_file(testfile(file))
                            for (trace, trace_with_data) in zip(ms.traces, ms_with_data.traces)
                                for (seg, seg_with_data) in zip(trace.segments, trace_with_data.segments)
                                    @test seg.starttime == seg_with_data.starttime
                                    @test seg.endtime == seg_with_data.endtime
                                    @test seg.sample_rate == seg_with_data.sample_rate
                                    @test seg.sample_rate == seg_with_data.sample_rate
                                    @test seg.sample_count == seg_with_data.sample_count
                                    @test eltype(seg.data) == Missing
                                    @test isempty(seg.data)
                                end
                            end
                        end
                    end

                    @testset "Buffer" begin
                        @testset "$file" for file in good_files
                            buf = read(testfile(file))
                            ms = read_buffer(buf; headers_only=true)
                            ms_with_data = read_buffer(buf)

                            for (trace, trace_with_data) in zip(ms.traces, ms_with_data.traces)
                                for (seg, seg_with_data) in zip(trace.segments, trace_with_data.segments)
                                    @test seg.starttime == seg_with_data.starttime
                                    @test seg.endtime == seg_with_data.endtime
                                    @test seg.sample_rate == seg_with_data.sample_rate
                                    @test seg.sample_rate == seg_with_data.sample_rate
                                    @test seg.sample_count == seg_with_data.sample_count
                                    @test eltype(seg.data) == Missing
                                    @test isempty(seg.data)
                                end
                            end                    
                        end
                    end
                end
            end
        end
    end

    @testset "Writing" begin
        mktempdir() do dir
            file = joinpath(dir, "data.mseed")
            samprate = 100
            starttime = LibMseed.NanosecondDateTime(
                Dates.DateTime("2000-01-01"), Dates.Nanosecond(1))
            id = "FDSN:AA_BB_CC_D_E_F"

            @testset "Data eltype $datatype" for datatype in (Int32, Float32, Float64)
                data = rand(datatype, 10)
                valid_args = (file, data, samprate, starttime, id)

                @testset "Errors" begin
                    # This test doesn't depend on the data type
                    if datatype == Int32
                        @testset "Vector{$T} not supported" for T in (Int8, Int16, Int64, Float16)
                            @test_throws ErrorException LibMseed.write_file(
                                file, rand(T, 10), 100, Dates.now(), "FDSN:AA_BB_CC_D_E_F")
                        end
                    end

                    @testset "$comp not supported" for comp in (:steim1, :steim2)
                        @test_throws ArgumentError LibMseed.write_file(valid_args...;
                            compress=comp)
                    end

                    @testset "Record length $len" for len in (-2, 0)
                        @test_throws ArgumentError LibMseed.write_file(valid_args...;
                            record_length=len)
                    end

                    @testset "Invalid version $version" for version in (1, 4)
                        @test_throws ArgumentError LibMseed.write_file(valid_args...;
                            version=version)
                    end

                    @testset "Date outside range" begin
                        @test_throws ArgumentError LibMseed.write_file(
                            file, data, samprate, Dates.DateTime("1200-01-01"), id)
                        @test_throws ArgumentError LibMseed.write_file(
                            file, data, samprate, Dates.DateTime("3000-01-01"), id)
                    end
                end

                @testset "Round-trip" begin
                    # Account for the fact that miniSEED version 2 has only
                    # microsecond precision
                    version_3_ns = LibMseed.nanoseconds(starttime)
                    version_2_ns = Dates.Nanosecond(1000*(Dates.value(version_3_ns)÷1000))
                    version_2_starttime = LibMseed.NanosecondDateTime(
                        LibMseed.datetime(starttime), version_2_ns)

                    @testset "Version $version" for version in (2, 3)
                        let starttime = version == 2 ? version_2_starttime : starttime
                            LibMseed.write_file(valid_args...; version=version)
                            ms = LibMseed.read_file(file)
                            @test ms isa LibMseed.MseedTraceList
                            @test length(ms.traces) == 1
                            trace = only(ms.traces)
                            @test trace isa LibMseed.MseedTraceID{datatype}
                            @test trace.id == id
                            @test trace.earliest == starttime
                            @test length(trace.segments) == 1
                            segment = only(trace.segments)
                            @test segment isa LibMseed.MseedTraceSegment{datatype}
                            @test segment.starttime == starttime
                            @test segment.sample_rate == samprate
                            @test segment.sample_count == length(data)
                            @test segment.data == data
                        end
                    end
                end

                @testset "Appending" begin
                    @testset "Appending to new file" begin
                        mktempdir() do dir
                            path = joinpath(dir, "test.mseed")
                            LibMseed.write_file(path, data, samprate, starttime, id)
                            ms = LibMseed.read_file(path)
                            path2 = joinpath(dir, "test2.mseed")
                            LibMseed.write_file(path2, data, samprate, starttime, id;
                                append=true)
                            ms′ = LibMseed.read_file(path2)
                            @test ms == ms′
                        end
                    end

                    @testset "Appending segments" begin
                        starttime1 = DateTime(2000, 1, 1)
                        LibMseed.write_file(file, data, samprate, starttime1, id)
                        starttime2 = DateTime(2000, 1, 1, 1)
                        data2 = rand(datatype, 20)
                        LibMseed.write_file(file, data2, samprate, starttime2, id;
                            append=true)
                        ms = LibMseed.read_file(file)
                        segments = only(ms.traces).segments
                        @test length(segments) == 2
                        @test segments[1].starttime == starttime1
                        @test segments[1].data == data
                        @test segments[2].starttime == starttime2
                        @test segments[2].data == data2
                    end

                    @testset "Appending traces" begin
                        id2 = replace(id, "AA"=>"XX")
                        LibMseed.write_file(file, data, samprate, starttime, id)
                        LibMseed.write_file(file, data, samprate, starttime, id2;
                            append=true)
                        ms = LibMseed.read_file(file)
                        @test length(ms.traces) == 2
                        @test ms.traces[1].id == id
                        @test ms.traces[2].id == id2
                        @test ms.traces[1].segments[1].data ==
                            ms.traces[2].segments[1].data
                    end
                end
            end
        end

        @testset "Bad identifier" begin
            mktemp() do path, io
                redirect_stderr(devnull) do
                    @test_throws ErrorException LibMseed.write_file(
                        path, Float32[1,2,3], 1, DateTime(2000),
                        "NOT AN ALLOWED NAME")
                end
            end
        end
    end

    @testset "Verbose level" begin
        @testset "read_file" begin
            file = testfile(first(good_files))
            f1 = () -> LibMseed.read_file(file)
            output1 = capture_stdout(f1).output
            f2 = () -> LibMseed.read_file(file; verbose_level=100)
            output2 = capture_stdout(f2).output
            @test length(output1) < length(output2)
        end

        @testset "read_buffer" begin
            buffer = read(testfile(first(good_files)))
            f1 = () -> LibMseed.read_buffer(buffer)
            output1 = capture_stdout(f1).output
            f2 = () -> LibMseed.read_buffer(buffer; verbose_level=100)
            output2 = capture_stdout(f2).output
            @test length(output1) < length(output2)
        end

        @testset "write_file" begin
            mktemp() do path, io
                args = (path, Float32[1,2,3], 1, DateTime(2000),
                    "FDSN:XX_YY_ZZ_A_B_C")
                output1 = capture_stdout(() -> LibMseed.write_file(
                    args...)).output
                output2 = capture_stdout(() -> LibMseed.write_file(
                    args...; verbose_level=100)).output
                @test length(output1) < length(output2)
            end
        end
    end

    @testset "Threaded IO$(Threads.nthreads() == 0 ? " (single thread)" : "")" begin
        Threads.nthreads() == 1 &&
            @info "Running threaded IO tests on a single thread. " *
                "Set the environment variable `JULIA_NUM_THREADS` to > 1 " *
                "to run multithreaded tests"
        n = 100
        mktempdir() do dir
            # Write in parallel
            tasks = map(1:n) do i
                Threads.@spawn begin
                    file = joinpath(dir, "data$(i).mseed")
                    data = rand(Float32, 1000)
                    samprate = rand(1:100)
                    starttime = DateTime(2000, rand(1:12), rand(1:28))
                    id = "FDSN:XX_$(i)__B_H_Z"
                    LibMseed.write_file(file, data, samprate, starttime, id)
                    (; file, data, samprate, starttime, id)
                end
            end
            write_outputs = fetch.(tasks)
            # Read in parallel
            tasks = map(write_outputs) do out
                Threads.@spawn LibMseed.read_file(out.file; time_tolerance=0)
            end
            read_data = fetch.(tasks)

            @test all(
                map(zip(write_outputs, read_data)) do (out, ms)
                    file, data, samprate, starttime, id = out
                    ms.traces[1].id == id &&
                        ms.traces[1].segments[1].sample_rate == samprate &&
                        ms.traces[1].segments[1].starttime == starttime &&
                        ms.traces[1].segments[1].data == data
                end
            )
        end
    end
end
