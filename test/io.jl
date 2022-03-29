using Test
using LibMseed

testfile(path...) = joinpath(@__DIR__, "..", "lib", "libmseed", "test", "data", path...)

error_files = (
    "corrupt-blockettes-wrongnext.mseed",
    "detection.record.mseed",
    "text-encoded.mseed",
)

@testset "File/buffer reading" begin
    @testset "Errors" begin
        @testset "$file" for file in error_files
            @test_throws ErrorException LibMseed.read_file(testfile(file))
            @test_throws ErrorException LibMseed.read_buffer(read(testfile(file)))
        end
    end

    @testset "File v buffer" begin
        @testset "$filename" for filename in collect(f for f in readdir(testfile()) if !(f in error_files))
            file = testfile(filename)
            mf = LibMseed.read_file(file)
            mb = LibMseed.read_buffer(read(file))
            @test mf == mb
        end
    end
end
