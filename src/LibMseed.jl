module LibMseed

using CEnum
using Dates: Dates, DateTime, Millisecond, Nanosecond, @dateformat_str
using libmseed_jll: libmseed

# Bare wrappers around library functions and types
include("manual_types.jl")
include("libmseed_common.jl")

# Higher-level wrappers around functions with checking and type conversion
include("high_level.jl")

end # module
