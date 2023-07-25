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
