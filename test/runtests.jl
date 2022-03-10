using LibMseed

data = read("/Users/nowacki/Work/Projects/Seis.jl/test/test_data/io/miniseed_GB.CWF.single_sample_gaps.mseed")

println(LibMseed.read_buffer(data))