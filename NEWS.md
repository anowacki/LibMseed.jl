# LibMseed.jl v0.2.0 release notes

## Breaking changes
- `read_buffer`: The `verbose_level` positional argument has been replaced
  with a keyword argument of the same name for consistency with other
  functions.

## New features
- `read_file`, `read_buffer`: The new `time_tolerance` keyword argument can
  be used to control whether and how adjacent trace segments with gaps are
  joined into a single segment.  (**N.B.** This feature can only be used
  on x86 and x86_64 platforms due to JuliaLang/julia#27174 and
  JuliaLang/julia#32154.)

## Notable bug fixes
