using Test

@testset "All tests" begin
    include("nanoseconddatetime.jl")
    include("io.jl")
    include("channel_codes.jl")
end
