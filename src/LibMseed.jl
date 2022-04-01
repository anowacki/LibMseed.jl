module LibMseed

using CEnum
using Dates: Dates, DateTime, Millisecond, Nanosecond, @dateformat_str
using libmseed_jll: libmseed

# Bare wrappers around library functions and types
include("manual_types.jl")
include("libmseed_common.jl")

# Utility code for interfacing with C
include("c_strings.jl")

# Higher-level wrappers around libmseed functions with checking and type conversion
include("nanoseconddatetime.jl")
include("julia_types.jl")

# Reading/writing/parsing
include("io.jl")

# Helper functions
include("channel_codes.jl")

end # module
