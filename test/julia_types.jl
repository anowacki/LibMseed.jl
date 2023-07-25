using Test
using LibMseed

@testset "MseedTraceList" begin
    @testset "Construction" begin
        @testset "Errors" begin
            @test_throws ArgumentError MseedTraceList(
                Ref(Ptr{LibMseed.MS3TraceList}(C_NULL))
            )
        end
    end
end
