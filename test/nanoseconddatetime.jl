using Dates
using LibMseed
using Test

@testset "NanosecondDateTime" begin
    @testset "Epoch" begin
        @test LibMseed.NanosecondDateTime(LibMseed.nstime_t(0)) == LibMseed.EPOCH
        @test LibMseed.NanosecondDateTime(
            DateTime("1970-01-01T00:00:00.000"), Nanosecond(0)) == LibMseed.EPOCH
    end

    @testset "Constructors" begin
        @testset "Integer" begin
            @test LibMseed.NanosecondDateTime(Int64(1)) ==
                LibMseed.NanosecondDateTime(LibMseed.EPOCH, Nanosecond(1))
        end

        @testset "DateTime" begin
            @test LibMseed.NanosecondDateTime(DateTime(1990)) ==
                LibMseed.NanosecondDateTime(DateTime(1990), Nanosecond(0))
        end

        @testset "NanosecondDateTime" begin
            dt = LibMseed.NanosecondDateTime(now(), Nanosecond(123456))
            @test dt == LibMseed.NanosecondDateTime(dt)
        end

        @testset "String" begin
            @test_throws ArgumentError NanosecondDateTime("")
            @test_throws ArgumentError NanosecondDateTime("2000")
            @test_throws ArgumentError NanosecondDateTime("2000-20-01T")
            # The 'Τ' below is actually 'T': ASCII/Unicode U+0054 (capital tau)
            @test_throws ArgumentError Nanosecond("2000-01-01Τ01:02")
            @test_throws ArgumentError Nanosecond("2000-01-01T00:00:00.1234567890")
            @test NanosecondDateTime("1990-01-02T03:04:05.123456789") ==
                NanosecondDateTime(DateTime(1990, 1, 2, 3, 4, 5, 123), Nanosecond(456789))
            @test NanosecondDateTime("1990-01-02T03:04:05.123456") ==
                NanosecondDateTime(DateTime(1990, 1, 2, 3, 4, 5, 123), Nanosecond(456000))
            @test NanosecondDateTime("1990-01-02T03:04:05.1234") ==
                NanosecondDateTime(DateTime(1990, 1, 2, 3, 4, 5, 123), Nanosecond(400000))
            @test NanosecondDateTime("1990-01-02T03:04:05.123") ==
                NanosecondDateTime(DateTime(1990, 1, 2, 3, 4, 5, 123), Nanosecond(0))
            @test NanosecondDateTime("1990-01-02T03:04:05") ==
                NanosecondDateTime(DateTime(1990, 1, 2, 3, 4, 5), Nanosecond(0))
            # Whitespace
            @test NanosecondDateTime("  1990-01-02T03:04:05.123456789  ") ==
                NanosecondDateTime(DateTime(1990, 1, 2, 3, 4, 5, 123), Nanosecond(456789))
        end
    end

    @testset "Accessors" begin
        dt = now()
        ns = Nanosecond(rand(0:999999))
        ndt = LibMseed.NanosecondDateTime(dt, ns)
        @test LibMseed.datetime(ndt) == dt
        @test LibMseed.nanoseconds(ndt) == ns
    end

    @testset "Conversion" begin
        @testset "Conversion to $(LibMseed.nstime_t)" begin
            i = rand(LibMseed.nstime_t)
            ndt = LibMseed.NanosecondDateTime(i)
            i′ = convert(Int64, ndt)
            @test i == i′
        end

        @testset "Conversion to DateTime" begin
            @test convert(DateTime, NanosecondDateTime("1700-01-01T12:34:56.123000000")) ==
                DateTime(1700, 1, 1, 12, 34, 56, 123)
            @test_throws InexactError convert(DateTime,
                NanosecondDateTime("2000-01-01T00:00:00.000000001"))
        end        
    end

    @testset "nearest_datetime" begin
        dt = now()
        ns = Nanosecond(500001)
        ndt = LibMseed.NanosecondDateTime(dt, ns)
        @test LibMseed.nearest_datetime(ndt) == dt + Millisecond(1)
    end

    @testset "Date" begin
        dt = now()
        ns = Nanosecond(rand(0:999999))
        ndt = LibMseed.NanosecondDateTime(dt, ns)
        @test Date(ndt) == Date(dt)
    end

    @testset "Time" begin
        dt = now()
        ns = Nanosecond(rand(0:999999))
        ndt = LibMseed.NanosecondDateTime(dt, ns)
        @test Time(ndt) == Time(dt) + ns
    end

    @testset "Printing" begin
        str = let io = IOBuffer()
            print(io, LibMseed.NanosecondDateTime(
                DateTime(2000, 1, 2, 3, 4, 5, 678), Nanosecond(12345)))
            String(take!(seekstart(io)))
        end
        @test str == "2000-01-02T03:04:05.678012345"
    end

    @testset "NanosecondDateTime comparisons" begin
        ndt = LibMseed.NanosecondDateTime(now(), Nanosecond(500000))
        @testset "==" begin
            ndt′ = LibMseed.NanosecondDateTime(
                LibMseed.datetime(ndt), LibMseed.nanoseconds(ndt))
            @test ndt == ndt′
            @test isequal(ndt, ndt′)
            @test !(ndt > ndt′)
            @test !(ndt < ndt′)
            @test ndt <= ndt′
            @test ndt >= ndt′
        end

        @testset "<" begin
            ndt′ = LibMseed.NanosecondDateTime(
                LibMseed.datetime(ndt), Nanosecond(500001))
            @test ndt != ndt′
            @test !isequal(ndt, ndt′)
            @test ndt < ndt′
            @test ndt <= ndt′
            @test !(ndt > ndt′)
            @test ndt′ > ndt
            @test !(ndt′ < ndt)
        end
    end

    @testset "DateTime comparisons" begin
        dt = now()
        @testset "==" begin
            ndt = LibMseed.NanosecondDateTime(dt)
            @test ndt == dt
            @test isequal(ndt, dt)
            @test !(ndt > dt)
            @test !(ndt < dt)
        end

        @testset "NanosecondDateTime > DateTime" begin
            ndt = LibMseed.NanosecondDateTime(dt, Nanosecond(1))
            @test ndt != dt
            @test !isequal(ndt, dt)
            @test dt < ndt
            @test !(dt > ndt)
            @test ndt > dt
            @test !(ndt < dt)
        end

        @testset "NanosecondDateTime < DateTime" begin
            ndt = LibMseed.NanosecondDateTime(dt - Millisecond(1), Nanosecond(999999))
            @test ndt != dt
            @test !isequal(ndt, dt)
            @test ndt < dt
            @test !(ndt > dt)
            @test dt > ndt
            @test !(dt < ndt)
        end
    end

    @testset "Base.show" begin
        # Helper function to get the output of `show`
        get_string(args...; kwargs...) = let io = IOBuffer()
            show(io, args...; kwargs...)
            String(take!(seekstart(io)))
        end

        @testset "Single" begin
            @test get_string(NanosecondDateTime("1999-12-31T23:59:59.999999999")) ==
                "NanosecondDateTime(\"1999-12-31T23:59:59.999999999\")"
            @test get_string(MIME("text/plain"), NanosecondDateTime("2000-01-02T")) == "2000-01-02T00:00:00.000000000"
        end

        @testset "Vector" begin
            str = "2122-02-03T04:05:06.001002003"
            ndt = NanosecondDateTime(str)
            @test get_string(MIME("text/plain"), [ndt, ndt]) == 
                 """
                 2-element Vector{NanosecondDateTime}:
                  $str
                  $str"""
        end
    end
end