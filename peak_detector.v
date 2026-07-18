`timescale 1ns / 1ps
//
// peak_detector - FIXED VERSION
//
// Changes vs original:
//  1. OFF-BY-ONE FIX: the original latched the fingerprints in the same
//     clock in which sample 1023 was being compared, so the last sample
//     of every frame could never appear in the results (non-blocking
//     assignment means the latch read the OLD max_idx values). Now a
//     one-cycle "flush" state latches the outputs on the clock AFTER the
//     final sample has been folded in.
//  2. BIN MASKING (important for audio fingerprints): bin 0 is DC and for
//     a real-valued input bins 512..1023 are mirror images of bins
//     1..511. Without masking, DC usually wins peak #0 and the remaining
//     peaks come in mirror pairs (k and 1024-k), wasting your 5 slots.
//     Set ONLY_FIRST_HALF = 0 to restore the original behavior.
//  3. max_idx width corrected to 10 bits (was declared 17 bits).
//
module peak_detector #(
    parameter ONLY_FIRST_HALF = 1   // 1: keep bins 1..511 only
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [16:0] data_in,
    input  wire        data_en,
    output reg  [9:0]  fingerprint_0,
    output reg  [9:0]  fingerprint_1,
    output reg  [9:0]  fingerprint_2,
    output reg  [9:0]  fingerprint_3,
    output reg  [9:0]  fingerprint_4,
    output reg         fingerprint_valid
);

    reg [16:0] max_mag [0:4];
    reg [9:0]  max_idx [0:4];
    reg [9:0]  count;
    reg        flush;

    // A bin participates in the search if it is not DC and (optionally)
    // in the non-mirrored half of the spectrum.
    wire in_band = (count != 10'd0) &&
                   (ONLY_FIRST_HALF ? (count < 10'd512) : 1'b1);

    always @(posedge clk) begin
        if (!rst_n) begin
            count             <= 10'd0;
            flush             <= 1'b0;
            fingerprint_valid <= 1'b0;

            max_mag[0] <= 17'd0; max_idx[0] <= 10'd0;
            max_mag[1] <= 17'd0; max_idx[1] <= 10'd0;
            max_mag[2] <= 17'd0; max_idx[2] <= 10'd0;
            max_mag[3] <= 17'd0; max_idx[3] <= 10'd0;
            max_mag[4] <= 17'd0; max_idx[4] <= 10'd0;

            fingerprint_0 <= 10'd0;
            fingerprint_1 <= 10'd0;
            fingerprint_2 <= 10'd0;
            fingerprint_3 <= 10'd0;
            fingerprint_4 <= 10'd0;
        end
        else begin
            fingerprint_valid <= 1'b0;

            // Latch results one clock AFTER the last sample was compared,
            // so sample 1023 is included in the search.
            if (flush) begin
                fingerprint_0     <= max_idx[0];
                fingerprint_1     <= max_idx[1];
                fingerprint_2     <= max_idx[2];
                fingerprint_3     <= max_idx[3];
                fingerprint_4     <= max_idx[4];
                fingerprint_valid <= 1'b1;
                flush             <= 1'b0;
            end

            if (data_en) begin
                if (count == 10'd0) begin
                    // Start of a new frame: clear the leaderboard.
                    // (Bin 0 = DC is intentionally not entered.)
                    max_mag[0] <= 17'd0; max_idx[0] <= 10'd0;
                    max_mag[1] <= 17'd0; max_idx[1] <= 10'd0;
                    max_mag[2] <= 17'd0; max_idx[2] <= 10'd0;
                    max_mag[3] <= 17'd0; max_idx[3] <= 10'd0;
                    max_mag[4] <= 17'd0; max_idx[4] <= 10'd0;
                end
                else if (in_band) begin
                    if (data_in > max_mag[0]) begin
                        max_mag[4] <= max_mag[3]; max_idx[4] <= max_idx[3];
                        max_mag[3] <= max_mag[2]; max_idx[3] <= max_idx[2];
                        max_mag[2] <= max_mag[1]; max_idx[2] <= max_idx[1];
                        max_mag[1] <= max_mag[0]; max_idx[1] <= max_idx[0];
                        max_mag[0] <= data_in;    max_idx[0] <= count;
                    end
                    else if (data_in > max_mag[1]) begin
                        max_mag[4] <= max_mag[3]; max_idx[4] <= max_idx[3];
                        max_mag[3] <= max_mag[2]; max_idx[3] <= max_idx[2];
                        max_mag[2] <= max_mag[1]; max_idx[2] <= max_idx[1];
                        max_mag[1] <= data_in;    max_idx[1] <= count;
                    end
                    else if (data_in > max_mag[2]) begin
                        max_mag[4] <= max_mag[3]; max_idx[4] <= max_idx[3];
                        max_mag[3] <= max_mag[2]; max_idx[3] <= max_idx[2];
                        max_mag[2] <= data_in;    max_idx[2] <= count;
                    end
                    else if (data_in > max_mag[3]) begin
                        max_mag[4] <= max_mag[3]; max_idx[4] <= max_idx[3];
                        max_mag[3] <= data_in;    max_idx[3] <= count;
                    end
                    else if (data_in > max_mag[4]) begin
                        max_mag[4] <= data_in;    max_idx[4] <= count;
                    end
                end

                count <= count + 1'b1;   // 10-bit counter wraps 1023 -> 0

                if (count == 10'd1023)
                    flush <= 1'b1;       // results latched next clock
            end
        end
    end

endmodule