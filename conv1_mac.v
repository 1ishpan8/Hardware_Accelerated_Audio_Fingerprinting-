`timescale 1ns / 1ps
// conv1_mac - reset added (X-free in sim), default arm added,
// and the temp_sum scalar bug fixed for real this time:
// temp_sum is computed with a BLOCKING assignment to the whole variable,
// then saturated into conv_out in the same clock.
module conv1_mac (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          valid_in,
    input  wire [49:0]   fingerprint_in,
    output reg  [12799:0] conv_out,   // 16 ch x 50 x 16b
    output reg           valid_out
);
    reg signed [15:0] weights [0:47];
    reg signed [15:0] biases  [0:15];
    initial begin
        $readmemh("conv1_weights.mem", weights);
        $readmemh("conv1_bias.mem",    biases);
    end

    wire [51:0] padded_in = {1'b0, fingerprint_in, 1'b0};

    function signed [15:0] sat16(input signed [17:0] v);
        sat16 = (v >  18'sd32767) ?  16'sd32767 :
                (v < -18'sd32768) ? -16'sd32768 : v[15:0];
    endfunction

    reg [1:0] state;
    reg [5:0] i_reg;
    integer c;
    reg signed [17:0] temp_sum;

    always @(posedge clk) begin
        if (!rst_n) begin
            state     <= 2'd0;
            valid_out <= 1'b0;
            i_reg     <= 6'd0;
        end else begin
            case (state)
                2'd0: begin
                    valid_out <= 1'b0;
                    if (valid_in) begin
                        state <= 2'd1;
                        i_reg <= 6'd0;
                    end
                end
                2'd1: begin
                    for (c = 0; c < 16; c = c + 1) begin
                        temp_sum = biases[c]
                                 + (padded_in[i_reg]   ? weights[c*3]   : 16'sd0)
                                 + (padded_in[i_reg+1] ? weights[c*3+1] : 16'sd0)
                                 + (padded_in[i_reg+2] ? weights[c*3+2] : 16'sd0);
                        conv_out[(((c*50) + i_reg) * 16) +: 16] <= sat16(temp_sum);
                    end
                    if (i_reg == 6'd49) state <= 2'd2;
                    else                i_reg <= i_reg + 1'b1;
                end
                2'd2: begin
                    valid_out <= 1'b1;
                    state     <= 2'd0;
                end
                default: state <= 2'd0;
            endcase
        end
    end
endmodule
