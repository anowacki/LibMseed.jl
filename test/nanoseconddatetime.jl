using Dates
using LibMseed
using Test

@testset "NanosecondDateTime" begin
    @testset "Epoch" begin
        @test LibMseed.NanosecondDateTime(0) == LibMseed.EPOCH
        @test LibMseed.NanosecondDateTime(
            DateTime("1970-01-01T00:00:00.000"), Nanosecond(0)) == LibMseed.EPOCH
    end

    @testset "Constructors" begin
        @testset "Integer" begin
            @test LibMseed.NanosecondDateTime(1) ==
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
    end

    @testset "Accessors" begin
        dt = now()
        ns = Nanosecond(rand(0:999999))
        ndt = LibMseed.NanosecondDateTime(dt, ns)
        @test LibMseed.datetime(ndt) == dt
        @test LibMseed.nanoseconds(ndt) == ns
    end

    @testset "Conversion to $(LibMseed.nstime_t)" begin
        i = rand(LibMseed.nstime_t)
        ndt = LibMseed.NanosecondDateTime(i)
        i′ = convert(Int64, ndt)
        @test i == i′
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
end