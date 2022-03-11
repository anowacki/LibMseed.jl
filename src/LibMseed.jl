module LibMseed

import Libdl
using Dates: Dates, DateTime, Millisecond, Nanosecond, @dateformat_str
using CEnum

function __init__()
    push!(Libdl.DL_LOAD_PATH, joinpath(@__DIR__, "..", "lib", "libmseed"))
end

const libmseed = :libmseed

const FILE = Cvoid

# Bare wrappers around library functions and types
include("ctypes.jl")
include("manual_types.jl")
include("libmseed_common.jl")
include("libmseed_api.jl")

# Higher-level wrappers around functions with checking and type conversion
include("high_level.jl")

end # module
