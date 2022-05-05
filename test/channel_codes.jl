using Dates: DateTime
using LibMseed
using Test

@testset "Channel codes" begin
    @testset "channel_code_parts" begin
        @testset "FDSN format" begin
            # New format: separate channel code elements
            @test LibMseed.channel_code_parts("XFDSN:AA_BB_CC_D_E_F") ==
                (net="AA", sta="BB", loc="CC", cha="DEF")
            @test LibMseed.channel_code_parts("FDSN:AA_BB_CC_D_E_F") ==
                (net="AA", sta="BB", loc="CC", cha="DEF")
            # Old format: single channel code
            @test LibMseed.channel_code_parts("XFDSN:AA_BB_CC_DEF") ==
                (net="AA", sta="BB", loc="CC", cha="DEF")
            @test LibMseed.channel_code_parts("FDSN:AA_BB_CC_DEF") ==
                (net="AA", sta="BB", loc="CC", cha="DEF")
            # No _s
            @test_throws ErrorException LibMseed.channel_code_parts("XFDSN:ldfjaldjjlfjk")
            @test_throws ErrorException LibMseed.channel_code_parts("FDSN:ldfjaldjjlfjk")
            # Too many parts
            @test_throws ErrorException LibMseed.channel_code_parts("XFDSN:A_B_C_D_E_F_G")
            @test_throws ErrorException LibMseed.channel_code_parts("FDSN:A_B_C_D_E_F_G")
            # Not enough parts
            @test_throws ErrorException LibMseed.channel_code_parts("XFDSN:A_B_C_D_E")
            @test_throws ErrorException LibMseed.channel_code_parts("FDSN:A_B_C_D_E")
            # Empty network code
            @test LibMseed.channel_code_parts("FDSN:_BB_CC_D_E_F") ==
                (net="", sta="BB", loc="CC", cha="DEF")
            @test LibMseed.channel_code_parts("XFDSN:_BB_CC_D_E_F") ==
                (net="", sta="BB", loc="CC", cha="DEF")
            # 'Empty' everything
            @test LibMseed.channel_code_parts("XFDSN:___ _ _ ") ==
                (net="", sta="", loc="", cha="   ")
        end

        @testset "_ separated" begin
            # New format: separate channel code elements
            @test LibMseed.channel_code_parts("AA_BB_CC_D_E_F") ==
                (net="AA", sta="BB", loc="CC", cha="DEF")
            # Old format: single channel code
            @test LibMseed.channel_code_parts("AA_BB_CC_DEF") ==
                (net="AA", sta="BB", loc="CC", cha="DEF")
        end

        @testset "Other format" begin
            @test LibMseed.channel_code_parts("AABBCCDEF") ==
                (net=nothing, sta="AABBCCDEF", loc=nothing, cha=nothing)
        end

        @testset "MseedTraceID" begin
            id = "FDSN:AA_BB_CC_D_E_F"
            earliest = latest = LibMseed.NanosecondDateTime(DateTime(1999))
            traceid = LibMseed.MseedTraceID(id, earliest, latest,
                LibMseed.MseedTraceSegment{Int32}[])
            @test LibMseed.channel_code_parts(traceid) ==
                LibMseed.channel_code_parts(id)
        end
    end
end