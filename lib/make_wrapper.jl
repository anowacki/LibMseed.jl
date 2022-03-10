using Clang

const LIBMSEED_INCLUDE = joinpath(@__DIR__, "libmseed") |> normpath
const LIBMSEED_HEADERS = [joinpath(LIBMSEED_INCLUDE, "libmseed.h")]

wc = init(; headers = LIBMSEED_HEADERS,
            output_file = joinpath(@__DIR__, "..", "src", "libmseed_api.jl"),
            common_file = joinpath(@__DIR__, "..", "src", "libmseed_common.jl"),
            clang_includes = vcat(LIBMSEED_INCLUDE, CLANG_INCLUDE),
            clang_args = ["-I", joinpath(LIBMSEED_INCLUDE, "..")],
            header_wrapped = (root, current)->root == current,
            header_library = x->"libmseed",
            clang_diagnostics = true,
            )

run(wc)

