# Julia wrapper for header: libmseed.h
# Automatically generated using Clang.jl


function ms_nstime2time(nstime, year, yday, hour, min, sec, nsec)
    ccall((:ms_nstime2time, libmseed), Cint, (nstime_t, Ptr{UInt16}, Ptr{UInt16}, Ptr{UInt8}, Ptr{UInt8}, Ptr{UInt8}, Ptr{UInt32}), nstime, year, yday, hour, min, sec, nsec)
end

function ms_nstime2timestr(nstime, timestr, timeformat, subsecond)
    ccall((:ms_nstime2timestr, libmseed), Cstring, (nstime_t, Cstring, ms_timeformat_t, ms_subseconds_t), nstime, timestr, timeformat, subsecond)
end

function ms_nstime2timestrz(nstime, timestr, timeformat, subsecond)
    ccall((:ms_nstime2timestrz, libmseed), Cstring, (nstime_t, Cstring, ms_timeformat_t, ms_subseconds_t), nstime, timestr, timeformat, subsecond)
end

function ms_time2nstime(year, yday, hour, min, sec, nsec)
    ccall((:ms_time2nstime, libmseed), nstime_t, (Cint, Cint, Cint, Cint, Cint, UInt32), year, yday, hour, min, sec, nsec)
end

function ms_timestr2nstime(timestr)
    ccall((:ms_timestr2nstime, libmseed), nstime_t, (Cstring,), timestr)
end

function ms_mdtimestr2nstime(timestr)
    ccall((:ms_mdtimestr2nstime, libmseed), nstime_t, (Cstring,), timestr)
end

function ms_seedtimestr2nstime(seedtimestr)
    ccall((:ms_seedtimestr2nstime, libmseed), nstime_t, (Cstring,), seedtimestr)
end

function ms_doy2md(year, yday, month, mday)
    ccall((:ms_doy2md, libmseed), Cint, (Cint, Cint, Ptr{Cint}, Ptr{Cint}), year, yday, month, mday)
end

function ms_md2doy(year, month, mday, yday)
    ccall((:ms_md2doy, libmseed), Cint, (Cint, Cint, Cint, Ptr{Cint}), year, month, mday, yday)
end

function msr3_parse(record, recbuflen, ppmsr, flags, verbose)
    ccall((:msr3_parse, libmseed), Cint, (Cstring, UInt64, Ptr{Ptr{MS3Record}}, UInt32, Int8), record, recbuflen, ppmsr, flags, verbose)
end

function msr3_pack(msr, record_handler, handlerdata, packedsamples, flags, verbose)
    ccall((:msr3_pack, libmseed), Cint, (Ptr{MS3Record}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Int64}, UInt32, Int8), msr, record_handler, handlerdata, packedsamples, flags, verbose)
end

function msr3_repack_mseed3(msr, record, recbuflen, verbose)
    ccall((:msr3_repack_mseed3, libmseed), Cint, (Ptr{MS3Record}, Cstring, UInt32, Int8), msr, record, recbuflen, verbose)
end

function msr3_pack_header3(msr, record, recbuflen, verbose)
    ccall((:msr3_pack_header3, libmseed), Cint, (Ptr{MS3Record}, Cstring, UInt32, Int8), msr, record, recbuflen, verbose)
end

function msr3_pack_header2(msr, record, recbuflen, verbose)
    ccall((:msr3_pack_header2, libmseed), Cint, (Ptr{MS3Record}, Cstring, UInt32, Int8), msr, record, recbuflen, verbose)
end

function msr3_unpack_data(msr, verbose)
    ccall((:msr3_unpack_data, libmseed), Int64, (Ptr{MS3Record}, Int8), msr, verbose)
end

function msr3_data_bounds(msr, dataoffset, datasize)
    ccall((:msr3_data_bounds, libmseed), Cint, (Ptr{MS3Record}, Ptr{UInt32}, Ptr{UInt32}), msr, dataoffset, datasize)
end

function ms_decode_data(input, inputsize, encoding, samplecount, output, outputsize, sampletype, swapflag, sid, verbose)
    ccall((:ms_decode_data, libmseed), Int64, (Ptr{Cvoid}, Csize_t, UInt8, Int64, Ptr{Cvoid}, Csize_t, Cstring, Int8, Cstring, Int8), input, inputsize, encoding, samplecount, output, outputsize, sampletype, swapflag, sid, verbose)
end

function msr3_init(msr)
    ccall((:msr3_init, libmseed), Ptr{MS3Record}, (Ptr{MS3Record},), msr)
end

function msr3_free(ppmsr)
    ccall((:msr3_free, libmseed), Cvoid, (Ptr{Ptr{MS3Record}},), ppmsr)
end

function msr3_duplicate(msr, datadup)
    ccall((:msr3_duplicate, libmseed), Ptr{MS3Record}, (Ptr{MS3Record}, Int8), msr, datadup)
end

function msr3_endtime(msr)
    ccall((:msr3_endtime, libmseed), nstime_t, (Ptr{MS3Record},), msr)
end

function msr3_print(msr, details)
    ccall((:msr3_print, libmseed), Cvoid, (Ptr{MS3Record}, Int8), msr, details)
end

function msr3_resize_buffer(msr)
    ccall((:msr3_resize_buffer, libmseed), Cint, (Ptr{MS3Record},), msr)
end

function msr3_sampratehz(msr)
    ccall((:msr3_sampratehz, libmseed), Cdouble, (Ptr{MS3Record},), msr)
end

function msr3_host_latency(msr)
    ccall((:msr3_host_latency, libmseed), Cdouble, (Ptr{MS3Record},), msr)
end

function ms3_detect(record, recbuflen, formatversion)
    ccall((:ms3_detect, libmseed), Cint, (Cstring, UInt64, Ptr{UInt8}), record, recbuflen, formatversion)
end

function ms_parse_raw3(record, maxreclen, details)
    ccall((:ms_parse_raw3, libmseed), Cint, (Cstring, Cint, Int8), record, maxreclen, details)
end

function ms_parse_raw2(record, maxreclen, details, swapflag)
    ccall((:ms_parse_raw2, libmseed), Cint, (Cstring, Cint, Int8, Int8), record, maxreclen, details, swapflag)
end

function ms3_matchselect(selections, sid, starttime, endtime, pubversion, ppselecttime)
    ccall((:ms3_matchselect, libmseed), Ptr{MS3Selections}, (Ptr{MS3Selections}, Cstring, nstime_t, nstime_t, Cint, Ptr{Ptr{MS3SelectTime}}), selections, sid, starttime, endtime, pubversion, ppselecttime)
end

function msr3_matchselect(selections, msr, ppselecttime)
    ccall((:msr3_matchselect, libmseed), Ptr{MS3Selections}, (Ptr{MS3Selections}, Ptr{MS3Record}, Ptr{Ptr{MS3SelectTime}}), selections, msr, ppselecttime)
end

function ms3_addselect(ppselections, sidpattern, starttime, endtime, pubversion)
    ccall((:ms3_addselect, libmseed), Cint, (Ptr{Ptr{MS3Selections}}, Cstring, nstime_t, nstime_t, UInt8), ppselections, sidpattern, starttime, endtime, pubversion)
end

function ms3_addselect_comp(ppselections, network, station, location, channel, starttime, endtime, pubversion)
    ccall((:ms3_addselect_comp, libmseed), Cint, (Ptr{Ptr{MS3Selections}}, Cstring, Cstring, Cstring, Cstring, nstime_t, nstime_t, UInt8), ppselections, network, station, location, channel, starttime, endtime, pubversion)
end

function ms3_readselectionsfile(ppselections, filename)
    ccall((:ms3_readselectionsfile, libmseed), Cint, (Ptr{Ptr{MS3Selections}}, Cstring), ppselections, filename)
end

function ms3_freeselections(selections)
    ccall((:ms3_freeselections, libmseed), Cvoid, (Ptr{MS3Selections},), selections)
end

function ms3_printselections(selections)
    ccall((:ms3_printselections, libmseed), Cvoid, (Ptr{MS3Selections},), selections)
end

function mstl3_init(mstl)
    ccall((:mstl3_init, libmseed), Ptr{MS3TraceList}, (Ptr{MS3TraceList},), mstl)
end

function mstl3_free(ppmstl, freeprvtptr)
    ccall((:mstl3_free, libmseed), Cvoid, (Ptr{Ptr{MS3TraceList}}, Int8), ppmstl, freeprvtptr)
end

function mstl3_addmsr_recordptr(mstl, msr, pprecptr, splitversion, autoheal, flags, tolerance)
    ccall((:mstl3_addmsr_recordptr, libmseed), Ptr{MS3TraceSeg}, (Ptr{MS3TraceList}, Ptr{MS3Record}, Ptr{Ptr{MS3RecordPtr}}, Int8, Int8, UInt32, Ptr{MS3Tolerance}), mstl, msr, pprecptr, splitversion, autoheal, flags, tolerance)
end

function mstl3_readbuffer(ppmstl, buffer, bufferlength, splitversion, flags, tolerance, verbose)
    ccall((:mstl3_readbuffer, libmseed), Int64, (Ptr{Ptr{MS3TraceList}}, Cstring, UInt64, Int8, UInt32, Ptr{MS3Tolerance}, Int8), ppmstl, buffer, bufferlength, splitversion, flags, tolerance, verbose)
end

function mstl3_readbuffer_selection(ppmstl, buffer, bufferlength, splitversion, flags, tolerance, selections, verbose)
    ccall((:mstl3_readbuffer_selection, libmseed), Int64, (Ptr{Ptr{MS3TraceList}}, Cstring, UInt64, Int8, UInt32, Ptr{MS3Tolerance}, Ptr{MS3Selections}, Int8), ppmstl, buffer, bufferlength, splitversion, flags, tolerance, selections, verbose)
end

function mstl3_unpack_recordlist(id, seg, output, outputsize, verbose)
    ccall((:mstl3_unpack_recordlist, libmseed), Int64, (Ptr{MS3TraceID}, Ptr{MS3TraceSeg}, Ptr{Cvoid}, Csize_t, Int8), id, seg, output, outputsize, verbose)
end

function mstl3_convertsamples(seg, type, truncate)
    ccall((:mstl3_convertsamples, libmseed), Cint, (Ptr{MS3TraceSeg}, UInt8, Int8), seg, type, truncate)
end

function mstl3_resize_buffers(mstl)
    ccall((:mstl3_resize_buffers, libmseed), Cint, (Ptr{MS3TraceList},), mstl)
end

function mstl3_pack(mstl, record_handler, handlerdata, reclen, encoding, packedsamples, flags, verbose, extra)
    ccall((:mstl3_pack, libmseed), Int64, (Ptr{MS3TraceList}, Ptr{Cvoid}, Ptr{Cvoid}, Cint, Int8, Ptr{Int64}, UInt32, Int8, Cstring), mstl, record_handler, handlerdata, reclen, encoding, packedsamples, flags, verbose, extra)
end

function mstl3_printtracelist(mstl, timeformat, details, gaps)
    ccall((:mstl3_printtracelist, libmseed), Cvoid, (Ptr{MS3TraceList}, ms_timeformat_t, Int8, Int8), mstl, timeformat, details, gaps)
end

function mstl3_printsynclist(mstl, dccid, subseconds)
    ccall((:mstl3_printsynclist, libmseed), Cvoid, (Ptr{MS3TraceList}, Cstring, ms_subseconds_t), mstl, dccid, subseconds)
end

function mstl3_printgaplist(mstl, timeformat, mingap, maxgap)
    ccall((:mstl3_printgaplist, libmseed), Cvoid, (Ptr{MS3TraceList}, ms_timeformat_t, Ptr{Cdouble}, Ptr{Cdouble}), mstl, timeformat, mingap, maxgap)
end

function ms3_readmsr(ppmsr, mspath, fpos, last, flags, verbose)
    ccall((:ms3_readmsr, libmseed), Cint, (Ptr{Ptr{MS3Record}}, Cstring, Ptr{Int64}, Ptr{Int8}, UInt32, Int8), ppmsr, mspath, fpos, last, flags, verbose)
end

function ms3_readmsr_r(ppmsfp, ppmsr, mspath, fpos, last, flags, verbose)
    ccall((:ms3_readmsr_r, libmseed), Cint, (Ptr{Ptr{MS3FileParam}}, Ptr{Ptr{MS3Record}}, Cstring, Ptr{Int64}, Ptr{Int8}, UInt32, Int8), ppmsfp, ppmsr, mspath, fpos, last, flags, verbose)
end

function ms3_readmsr_selection(ppmsfp, ppmsr, mspath, fpos, last, flags, selections, verbose)
    ccall((:ms3_readmsr_selection, libmseed), Cint, (Ptr{Ptr{MS3FileParam}}, Ptr{Ptr{MS3Record}}, Cstring, Ptr{Int64}, Ptr{Int8}, UInt32, Ptr{MS3Selections}, Int8), ppmsfp, ppmsr, mspath, fpos, last, flags, selections, verbose)
end

function ms3_readtracelist(ppmstl, mspath, tolerance, splitversion, flags, verbose)
    ccall((:ms3_readtracelist, libmseed), Cint, (Ptr{Ptr{MS3TraceList}}, Cstring, Ptr{MS3Tolerance}, Int8, UInt32, Int8), ppmstl, mspath, tolerance, splitversion, flags, verbose)
end

function ms3_readtracelist_timewin(ppmstl, mspath, tolerance, starttime, endtime, splitversion, flags, verbose)
    ccall((:ms3_readtracelist_timewin, libmseed), Cint, (Ptr{Ptr{MS3TraceList}}, Cstring, Ptr{MS3Tolerance}, nstime_t, nstime_t, Int8, UInt32, Int8), ppmstl, mspath, tolerance, starttime, endtime, splitversion, flags, verbose)
end

function ms3_readtracelist_selection(ppmstl, mspath, tolerance, selections, splitversion, flags, verbose)
    ccall((:ms3_readtracelist_selection, libmseed), Cint, (Ptr{Ptr{MS3TraceList}}, Cstring, Ptr{MS3Tolerance}, Ptr{MS3Selections}, Int8, UInt32, Int8), ppmstl, mspath, tolerance, selections, splitversion, flags, verbose)
end

function ms3_url_useragent(program, version)
    ccall((:ms3_url_useragent, libmseed), Cint, (Cstring, Cstring), program, version)
end

function ms3_url_userpassword(userpassword)
    ccall((:ms3_url_userpassword, libmseed), Cint, (Cstring,), userpassword)
end

function ms3_url_addheader(header)
    ccall((:ms3_url_addheader, libmseed), Cint, (Cstring,), header)
end

function ms3_url_freeheaders()
    ccall((:ms3_url_freeheaders, libmseed), Cvoid, ())
end

function msr3_writemseed(msr, mspath, overwrite, flags, verbose)
    ccall((:msr3_writemseed, libmseed), Int64, (Ptr{MS3Record}, Cstring, Int8, UInt32, Int8), msr, mspath, overwrite, flags, verbose)
end

function mstl3_writemseed(mst, mspath, overwrite, maxreclen, encoding, flags, verbose)
    ccall((:mstl3_writemseed, libmseed), Int64, (Ptr{MS3TraceList}, Cstring, Int8, Cint, Int8, UInt32, Int8), mst, mspath, overwrite, maxreclen, encoding, flags, verbose)
end

function libmseed_url_support()
    ccall((:libmseed_url_support, libmseed), Cint, ())
end

function ms_sid2nslc(sid, net, sta, loc, chan)
    ccall((:ms_sid2nslc, libmseed), Cint, (Cstring, Cstring, Cstring, Cstring, Cstring), sid, net, sta, loc, chan)
end

function ms_nslc2sid(sid, sidlen, flags, net, sta, loc, chan)
    ccall((:ms_nslc2sid, libmseed), Cint, (Cstring, Cint, UInt16, Cstring, Cstring, Cstring, Cstring), sid, sidlen, flags, net, sta, loc, chan)
end

function ms_seedchan2xchan(xchan, seedchan)
    ccall((:ms_seedchan2xchan, libmseed), Cint, (Cstring, Cstring), xchan, seedchan)
end

function ms_xchan2seedchan(seedchan, xchan)
    ccall((:ms_xchan2seedchan, libmseed), Cint, (Cstring, Cstring), seedchan, xchan)
end

function ms_strncpclean(dest, source, length)
    ccall((:ms_strncpclean, libmseed), Cint, (Cstring, Cstring, Cint), dest, source, length)
end

function ms_strncpcleantail(dest, source, length)
    ccall((:ms_strncpcleantail, libmseed), Cint, (Cstring, Cstring, Cint), dest, source, length)
end

function ms_strncpopen(dest, source, length)
    ccall((:ms_strncpopen, libmseed), Cint, (Cstring, Cstring, Cint), dest, source, length)
end

function mseh_get_path(msr, path, value, type, maxlength)
    ccall((:mseh_get_path, libmseed), Cint, (Ptr{MS3Record}, Cstring, Ptr{Cvoid}, UInt8, Csize_t), msr, path, value, type, maxlength)
end

function mseh_set_path(msr, path, value, type)
    ccall((:mseh_set_path, libmseed), Cint, (Ptr{MS3Record}, Cstring, Ptr{Cvoid}, UInt8), msr, path, value, type)
end

function mseh_add_event_detection(msr, path, eventdetection)
    ccall((:mseh_add_event_detection, libmseed), Cint, (Ptr{MS3Record}, Cstring, Ptr{MSEHEventDetection}), msr, path, eventdetection)
end

function mseh_add_calibration(msr, path, calibration)
    ccall((:mseh_add_calibration, libmseed), Cint, (Ptr{MS3Record}, Cstring, Ptr{MSEHCalibration}), msr, path, calibration)
end

function mseh_add_timing_exception(msr, path, exception)
    ccall((:mseh_add_timing_exception, libmseed), Cint, (Ptr{MS3Record}, Cstring, Ptr{MSEHTimingException}), msr, path, exception)
end

function mseh_add_recenter(msr, path, recenter)
    ccall((:mseh_add_recenter, libmseed), Cint, (Ptr{MS3Record}, Cstring, Ptr{MSEHRecenter}), msr, path, recenter)
end

function mseh_print(msr, indent)
    ccall((:mseh_print, libmseed), Cint, (Ptr{MS3Record}, Cint), msr, indent)
end

function ms_rloginit(log_print, logprefix, diag_print, errprefix, maxmessages)
    ccall((:ms_rloginit, libmseed), Cvoid, (Ptr{Cvoid}, Cstring, Ptr{Cvoid}, Cstring, Cint), log_print, logprefix, diag_print, errprefix, maxmessages)
end

function ms_rloginit_l(logp, log_print, logprefix, diag_print, errprefix, maxmessages)
    ccall((:ms_rloginit_l, libmseed), Ptr{MSLogParam}, (Ptr{MSLogParam}, Ptr{Cvoid}, Cstring, Ptr{Cvoid}, Cstring, Cint), logp, log_print, logprefix, diag_print, errprefix, maxmessages)
end

function ms_rlog_emit(logp, count, context)
    ccall((:ms_rlog_emit, libmseed), Cint, (Ptr{MSLogParam}, Cint, Cint), logp, count, context)
end

function ms_rlog_free(logp)
    ccall((:ms_rlog_free, libmseed), Cint, (Ptr{MSLogParam},), logp)
end

function ms_readleapseconds(envvarname)
    ccall((:ms_readleapseconds, libmseed), Cint, (Cstring,), envvarname)
end

function ms_readleapsecondfile(filename)
    ccall((:ms_readleapsecondfile, libmseed), Cint, (Cstring,), filename)
end

function ms_samplesize(sampletype)
    ccall((:ms_samplesize, libmseed), UInt8, (UInt8,), sampletype)
end

function ms_encoding_sizetype(encoding, samplesize, sampletype)
    ccall((:ms_encoding_sizetype, libmseed), Cint, (UInt8, Ptr{UInt8}, Cstring), encoding, samplesize, sampletype)
end

function ms_encodingstr(encoding)
    ccall((:ms_encodingstr, libmseed), Cstring, (UInt8,), encoding)
end

function ms_errorstr(errorcode)
    ccall((:ms_errorstr, libmseed), Cstring, (Cint,), errorcode)
end

function ms_sampletime(time, offset, samprate)
    ccall((:ms_sampletime, libmseed), nstime_t, (nstime_t, Int64, Cdouble), time, offset, samprate)
end

function ms_dabs(val)
    ccall((:ms_dabs, libmseed), Cdouble, (Cdouble,), val)
end

function ms_bigendianhost()
    ccall((:ms_bigendianhost, libmseed), Cint, ())
end

function lmp_ftell64(stream)
    ccall((:lmp_ftell64, libmseed), Int64, (Ptr{FILE},), stream)
end

function lmp_fseek64(stream, offset, whence)
    ccall((:lmp_fseek64, libmseed), Cint, (Ptr{FILE}, Int64, Cint), stream, offset, whence)
end

function lmp_nanosleep(nanoseconds)
    ccall((:lmp_nanosleep, libmseed), UInt64, (UInt64,), nanoseconds)
end

function ms_crc32c(input, length, previousCRC32C)
    ccall((:ms_crc32c, libmseed), UInt32, (Ptr{UInt8}, Cint, UInt32), input, length, previousCRC32C)
end

function ms_gswap2(data2)
    ccall((:ms_gswap2, libmseed), Cvoid, (Ptr{Cvoid},), data2)
end

function ms_gswap4(data4)
    ccall((:ms_gswap4, libmseed), Cvoid, (Ptr{Cvoid},), data4)
end

function ms_gswap8(data8)
    ccall((:ms_gswap8, libmseed), Cvoid, (Ptr{Cvoid},), data8)
end

function ms_gswap2a(data2)
    ccall((:ms_gswap2a, libmseed), Cvoid, (Ptr{Cvoid},), data2)
end

function ms_gswap4a(data4)
    ccall((:ms_gswap4a, libmseed), Cvoid, (Ptr{Cvoid},), data4)
end

function ms_gswap8a(data8)
    ccall((:ms_gswap8a, libmseed), Cvoid, (Ptr{Cvoid},), data8)
end

function libmseed_memory_prealloc(ptr, size, currentsize)
    ccall((:libmseed_memory_prealloc, libmseed), Ptr{Cvoid}, (Ptr{Cvoid}, Csize_t, Ptr{Csize_t}), ptr, size, currentsize)
end
