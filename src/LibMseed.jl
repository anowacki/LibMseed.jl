module LibMseed

using libmseed_jll: libmseed
using Dates: Dates, DateTime, Millisecond, Nanosecond, @dateformat_str
using CEnum

const FILE = Cvoid

# Bare wrappers around library functions and types
include("ctypes.jl")
include("manual_types.jl")
include("libmseed_common.jl")
include("libmseed_api.jl")

# Higher-level wrappers around functions with checking and type conversion
include("high_level.jl")

end # module
