using Test
using LibMseed

testfile(path...) = joinpath(@__DIR__, "..", "lib", "libmseed", "test", "data", path...)

error_files = (
    "corrupt-blockettes-wrongnext.mseed",
    "detection.record.mseed",
    "text-encoded.mseed",
)

good_files = collect(f for f in readdir(testfile())
                     if !(f in (error_files..., "no-blockette1000-steim1.mseed")))

@testset "File/buffer reading" begin
    @testset "Errors" begin
        @testset "$file" for file in error_files
            @test_throws ErrorException LibMseed.read_file(testfile(file))
            @test_throws ErrorException LibMseed.read_buffer(read(testfile(file)))
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
        @test_throws ArgumentError LibMseed.read_buffer(UInt8[1,2,3])
    end
end
