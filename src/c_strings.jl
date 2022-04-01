# Convert between C strings and Julia ones

"""
    bytes2string(bytes::Ntuple{N,UInt8})

Convert a null-terminated tuple of `UInt8`s into a `String`.

This function takes the first null character ('`\\0`') as the end marker
and ignores all subsequent characters in `bytes`.

See also: [`Cstring`](@ref), [`unsafe_string`](@ref)
"""
function bytes2string(bytes::NTuple{N,UInt8}) where N
    index = findfirst(x -> x == 0, bytes)
    len = index === nothing ? N : index - 1
    String(UInt8[@inbounds(bytes[i]) for i in 1:len])
end

"""
    string2bytes(::Type{NTuple{N,T}}, str) -> bytes

Convert a `String` to a null-terminated tuple of `T`s of length `N`.
If `str` is longer than `N`, the string is truncated without warning.
"""
function string2bytes(::Type{NTuple{N,T}}, str::AbstractString) where {N,T}
    isascii(str) || throw(ArgumentError("input string must be ASCII"))
    n = length(str)
    ntuple(i -> i <= n ? T(str[i]) : T('\0'), Val(N))
end
