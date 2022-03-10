# This file is generated manually.

@cenum LMIO_type::UInt32 begin
    LMIO_NULL = 0
    LMIO_FILE = 1
    LMIO_URL = 2
end

struct LMIO
    type::LMIO_type
    handle::Ptr{Cvoid}
    handle2::Ptr{Cvoid}
    still_running::Cint
end
