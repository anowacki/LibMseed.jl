using Dates: DateTime
using LibMseed
using Test

@testset "Channel codes" begin
    @testset "channel_code_parts" begin
        @testset "FDSN format" begin
            @testset "New format: separate channel code elements" begin
                @test LibMseed.channel_code_parts("XFDSN:AA_BB_CC_D_E_F") ==
                    (net="AA", sta="BB", loc="CC", cha="DEF")
                @test LibMseed.channel_code_parts("FDSN:AA_BB_CC_D_E_F") ==
                    (net="AA", sta="BB", loc="CC", cha="DEF")
                # Old format: single channel code
                @test LibMseed.channel_code_parts("XFDSN:AA_BB_CC_DEF") ==
                    (net="AA", sta="BB", loc="CC", cha="DEF")
                @test LibMseed.channel_code_parts("FDSN:AA_BB_CC_DEF") ==
                    (net="AA", sta="BB", loc="CC", cha="DEF")
            end

            @testset "No _s" begin
                @test (
                    @test_logs (
                        :warn, "unexpected apparent XFDSN URN"
                    ) LibMseed.channel_code_parts("XFDSN:ldfjaldjjlfjk")
                ) == (net="", sta="XFDSN:ldfjaldjjlfjk", loc="", cha="")
                @test (
                    @test_logs (
                        :warn, "unexpected apparent XFDSN URN"
                    ) LibMseed.channel_code_parts("FDSN:ldfjaldjjlfjk")
                ) == (net="", sta="FDSN:ldfjaldjjlfjk", loc="", cha="")
            end
            
            @testset "Too many parts" begin
                @test (
                    @test_logs (
                        :warn, "unexpected apparent XFDSN URN"
                    ) LibMseed.channel_code_parts("XFDSN:A_B_C_D_E_F_G")
                ) == (net="", sta="XFDSN:A_B_C_D_E_F_G", loc="", cha="")
                @test (
                    @test_logs (
                        :warn, "unexpected apparent XFDSN URN"
                    ) LibMseed.channel_code_parts("FDSN:A_B_C_D_E_F_G")
                ) == (net="", sta="FDSN:A_B_C_D_E_F_G", loc="", cha="")
            end

            @testset "Not enough parts" begin
                @test (
                    @test_logs (
                        :warn, "unexpected apparent XFDSN URN"
                    ) LibMseed.channel_code_parts("XFDSN:A_B_C_D_E")
                ) == (net="", sta="XFDSN:A_B_C_D_E", loc="", cha="")
                @test (
                    @test_logs (
                        :warn, "unexpected apparent XFDSN URN"
                    ) LibMseed.channel_code_parts("FDSN:A_B_C_D_E")
                ) == (net="", sta="FDSN:A_B_C_D_E", loc="", cha="")
            end

            @testset "Empty network code" begin
                @test LibMseed.channel_code_parts("FDSN:_BB_CC_D_E_F") ==
                    (net="", sta="BB", loc="CC", cha="DEF")
                @test LibMseed.channel_code_parts("XFDSN:_BB_CC_D_E_F") ==
                    (net="", sta="BB", loc="CC", cha="DEF")
            end

            @testset "'Empty' everything" begin
                @test LibMseed.channel_code_parts("XFDSN:___ _ _ ") ==
                    (net="", sta="", loc="", cha="   ")
            end
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
                (net="", sta="AABBCCDEF", loc="", cha="")
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