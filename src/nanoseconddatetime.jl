# Types and methods for nanosecond-precision dates

"""
    NanosecondDateTime

Type representing an instance in time to nanosecond precision.
It is made up of a standard `DateTime` plus a number of nanoseconds in addition
to the millisecond resolution that `DateTime` offers.

# Accessor functions
- [`datetime`](@ref): Return a `Dates.DateTime`
  giving the date and time of a `NanosecondDateTime` to millisecond precision.
- [`nanoseconds`](@ref): Return a `Dates.Nanosecond`
  giving the additional number of nanoseconds beyond the millsecond precision
  of the `Date.DateTime` part.

# Other functions
- [`nearest_datetime`](@ref): Return the `Dates.DateTime` nearest to the
  `NanosecondDateTime`.
"""
struct NanosecondDateTime
    "`DateTime`, to millisecond resolution"
    datetime::DateTime
    "Positive number of nanoseconds.  Never more than 999999."
    nanosecond::Nanosecond
end

NanosecondDateTime(dt::NanosecondDateTime) = dt

Base.typemin(::Type{NanosecondDateTime}) = NanosecondDateTime(typemin(nstime_t))
Base.typemax(::Type{NanosecondDateTime}) = NanosecondDateTime(typemax(nstime_t))

# Comparison between NanosecondDateTimes
Base.:(==)(t1::NanosecondDateTime, t2::NanosecondDateTime) =
    datetime(t1) == datetime(t2) && nanoseconds(t1) == nanoseconds(t2)

Base.:(<)(t1::NanosecondDateTime, t2::NanosecondDateTime) =
    datetime(t1) < datetime(t2) || (datetime(t1) == datetime(t2) && nanoseconds(t1) < nanoseconds(t2))

function Base.print(io::IO, dt::NanosecondDateTime)
    date_str = Dates.format(datetime(dt), dateformat"yyyy-mm-ddTHH:MM:SS.sss")
    ns_str = lpad(Dates.value(nanoseconds(dt)), 6, '0')
    print(io, date_str, ns_str)
end

# Human-readable format
Base.show(io::IO, ::MIME"text/plain", dt::NanosecondDateTime) = print(io, dt)

# Parsable format
Base.show(io::IO, dt::NanosecondDateTime) = print(io, "NanosecondDateTime(\"", dt, "\")")

# Comparisons between DateTimes and NanosecondDateTimes
Base.:(==)(dt::DateTime, ndt::NanosecondDateTime) =
    iszero(nanoseconds(ndt)) && dt == datetime(ndt)
Base.:(==)(ndt::NanosecondDateTime, dt::DateTime) = dt == ndt

Base.:(<)(dt::DateTime, ndt::NanosecondDateTime) =
    dt < datetime(ndt) || (dt == datetime(ndt) && !iszero(nanoseconds(ndt)))
Base.:(<)(ndt::NanosecondDateTime, dt::DateTime) = datetime(ndt) < dt

"""
    EPOCH ($(EPOCH))

Epoch of the `NanosecondDateTime` type.  This is the `DateTime` corresponding
to the zeroth nanosecond of the type.
"""
const EPOCH = DateTime(1970)

"""
    NanosecondDateTime(nstime)

Construct a `NanosecondDateTime` from an `$(nstime_t)`.  This represents
the integer number of nanoseconds since the epoch of `1970-01-01T00:00:00.000000000`.
Hence the range of dates which can be represented is
`$(typemin(NanosecondDateTime)) - $(typemax(NanosecondDateTime))`.

# Example
```
julia> NanosecondDateTime(100)
NanosecondDateTime("1970-01-01T00:00:00.000000100")
```
"""
function NanosecondDateTime(nstime::nstime_t)
    epoch_ms = nstime ÷ 1_000_000
    dt = EPOCH + Millisecond(epoch_ms)
    ns = Nanosecond(nstime % 1_000_000)
    if ns < Nanosecond(0)
        dt = dt - Millisecond(1)
        ns = Nanosecond(1_000_000) + ns
    end
    NanosecondDateTime(dt, ns)
end

"""
    NanosecondDateTime(dt::DateTime)

Create a `NanosecondDateTime` from a `DateTime`, `dt`.

# Example
```
julia> using Dates

julia> dt = now()
2021-04-18T22:03:52.145

julia> ndt = NanosecondDateTime(dt)
NanosecondDateTime("2021-04-18T22:03:52.145000000")

julia> datetime(ndt) == dt
true
```
"""
NanosecondDateTime(dt::DateTime) = NanosecondDateTime(dt, Nanosecond(0))

"""
    NanosecondDateTime(str)

Create a `NanosecondDateTime` from a string.  It must be in the standard
format `"yyyy-mm-ddTHH:MM:SS.s"`.  (See [`Dates.DateFormat`](@ref)
for a description of the fields.)  Note that nanosecond precision can
be given, but need not be.

# Examples
```
julia> NanosecondDateTime("1990-01-02T03:04:05.123456789")
NanosecondDateTime("1990-01-02T03:04:05.123456789")

julia> NanosecondDateTime("2000-01-01")
NanosecondDateTime("2000-01-01T00:00:00.000000000")
```
"""
function NanosecondDateTime(str::AbstractString)
    isempty(str) && throw(ArgumentError("string cannot be empty"))
    # After this we are safe to treat bytes and characters the same
    isascii(str) ||
        throw(ArgumentError("date string must be in the format yyyy-mm-ddTHH:MM:SS.sssssssss"))
    # Parse the first bit up to milliseconds
    # FIXME: Can do this without the strip and allocations
    str = strip(str)
    dt = DateTime(first(str, 23))
    # Parse the remainder as micro- and nanoseconds
    if length(str) > 23
        ns_str = str[24:end]
        length(ns_str) > 6 &&
            throw(ArgumentError("too many decimal places in the seconds"))
        # FIXME: Can do this without allocating another string
        ns = parse(Int, rpad(ns_str, 6, '0'))
        return NanosecondDateTime(dt, Nanosecond(ns))
    else
        return NanosecondDateTime(dt)
    end
end

Base.convert(::Type{nstime_t}, dt::NanosecondDateTime) =
    Dates.value(datetime(dt) - EPOCH)*1_000_000 + Dates.value(nanoseconds(dt))

"""
    datetime(dt::NanosecondDateTime) -> ::Dates.DateTime

Return the date and time of `dt`, rounded down to the nearest millisecond.
Add on the number of [`nanoseconds`](@ref LibMseed.nanoseconds) to obtain
the full-precision time.

# Example
```
julia> ndt = NanosecondDateTime("2000-01-01T01:23:45.999999999")
NanosecondDateTime("2000-01-01T01:23:45.999999999")

julia> datetime(ndt)
2000-01-01T01:23:45.999
```

See also: [`NanosecondDateTime`](@ref),
[`nearest_datetime`](@ref).
"""
datetime(dt::NanosecondDateTime) = dt.datetime

"""
    nanoseconds(dt::NanosecondDateTime) -> ::Dates.Nanosecond(n)

Return the number of additional nanoseconds of the date and time represented
by `dt`, beyond the millisecond resolution of [`datetime`](@ref LibMseed.datetime).
This value is always positive.

# Example
```
julia> ndt = NanosecondDateTime("1990-01-02T00:11:22.123456789")
NanosecondDateTime("1990-01-02T00:11:22.123456789")

julia> nanoseconds(ndt)
456789 nanoseconds
```

See also: [`NanosecondDateTime`](@ref).
"""
nanoseconds(dt::NanosecondDateTime) = dt.nanosecond

"""
    nearest_datetime(dt::NanosecondDateTime) -> ::Dates.DateTime

Round `dt` to the nearest millisecond and return a `DateTime`.

# Example
```
julia> ndt = NanosecondDateTime("1999-12-31T23:59:59.9996")
NanosecondDateTime("1999-12-31T23:59:59.999600000")

julia> nearest_datetime(ndt)
2000-01-01T00:00:00
```

See also: [`datetime`](@ref).
"""
nearest_datetime(dt::NanosecondDateTime) = datetime(dt) +
    Millisecond(round(Int, Dates.value(nanoseconds(dt))/1_000_000))

Dates.Date(dt::NanosecondDateTime) = Dates.Date(datetime(dt))
Dates.Time(dt::NanosecondDateTime) = Dates.Time(datetime(dt)) + nanoseconds(dt)

Base.convert(::Type{DateTime}, ndt::NanosecondDateTime) =
    iszero(nanoseconds(ndt)) ? datetime(ndt) :
        throw(InexactError(:convert, DateTime, ndt))
