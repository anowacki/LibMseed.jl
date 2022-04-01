# Utilities for dealing with channel codes/trace IDs

"""
    channel_code_parts(s) (net, sta, loc, cha)

Convert a single `String` `s` into its component SEED channel code parts.
Returns a named tuple of network `net`, station `sta`, location `loc` and
channel `cha`.  Empty components are given as empty `String`s.

This function assumes that `s` is an ASCII string, as per the SEED convention
for channel IDs.

See https://iris-edu.github.io/xseed-specification/docs/xFDSNSourceIdentifiers-DRAFT20190520.pdf
for the transitional SEED URN specification.
"""
function channel_code_parts(s::String)
    parts = split(s, '_')
    nparts = length(parts)
    # Maybe an XFDSN URN
    if startswith(s, "XFDSN:") || startswith(s, "FDSN:")
        # Seems like an XFDSN URN
        if length(s) > 6
            length(parts[1]) > 6 || error("unexpectedly short network name")
            # URN convention: XFDSN:NET_STA_LOC_BAND_SOURCE_POSITION
            if nparts == 6
                net = parts[1][1] == 'X' ? parts[1][7:end] : parts[1][6:end]
                sta = parts[2]
                loc = parts[3]
                cha = join(parts[4:end])
            # Traditional SEED convention: NET_STA_LOC_CHA
            elseif nparts == 4
                length(parts[1]) > 6 || error("unexpectedly short network name")
                net = parts[1][7:end]
                sta = parts[2]
                loc = parts[3]
                cha = parts[4]
            else
                error("unexpected apparent XFDSN URN")
            end
        # Not really an XFDSN URN
        else
            error("unexpectedly short channel id")
        end

    # Not an XFDSN URN but might have the same structure
    else
        # NET_STA_LOC_CHA: one might be blank
        if nparts == 4
            net = parts[1]
            sta = parts[2]
            loc = parts[3]
            cha = parts[4]
        # NET_STA_LOC_BAND_SOURCE_POSITION: all but one might be blank
        elseif nparts == 6
            net = parts[1]
            sta = parts[2]
            loc = parts[3]
            cha = join(parts[4:end])
        # Something else entirely: just put it all in sta
        else
            net = nothing
            sta = s
            loc = nothing
            cha = nothing
        end
    end
    (net=net, sta=sta, loc=loc, cha=cha)
end

"""
    channel_code_parts(traceid::MseedTraceID) -> (net, sta, loc, cha)

Return the channel code parts for the trace ID for `traceid`.
"""
channel_code_parts(traceid::MseedTraceID) = channel_code_parts(traceid.id)

