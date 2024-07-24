# LibMseed.jl v0.3.3 release notes

- `read_file` and `read_buffer`: Add ability to limit reading of
 data to a specified time window with the `startdate` and `enddate`
 keyword arguments, and limit reading to certain channels with the
 `channels` keyword argument.  The latter takes a globbing string
 which can be used to match channels, such as `"FDSN:GB_*_*_B_?_Z"`
 to get all location of all stations in the GB network, and only the
 vertical components of broadband instruments, regardless of the
 sampling rate.


# LibMseed.jl v0.3.1 release notes

- Update required version of libmseed to v3.0.18


# LibMseed.jl v0.3.0 release notes

## libmseed library version

- libmseed version v3.0.16 is required.  This is the first stable
  version of libmseed v3.


# LibMseed.jl v0.2.2 release notes

v0.2.2 is a final patch release before v0.3.  The release fixes
compatibility with only v3.0.10 of the libmseed library.

Users are encouraged to upgrade to v0.3 of LibMseed.jl, which
contains no changes to the public API.


# LibMseed.jl v0.2.1 release notes

## Notable bug fixes
- Fix bug when using the (internal) `channel_code_parts` function
  to split a channel ID into its component network, station, location
  and channel codes.
