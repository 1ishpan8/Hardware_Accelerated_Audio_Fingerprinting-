`timescale 1ns / 1ps
// relu_maxpool_layer2 (16ch, 50->25) - reset added AND the missing
// default arm added (this was one of the two X-frozen FSMs in your sim).
module relu_maxpool_layer2 (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          valid_in,
    input  wire [12799:0] conv_in,   // 16ch x 50 x 16b
    output reg  [6399:0] pool_out,   // 16ch x 25 x 16b
    output reg           valid_out
);
    reg [1:0] state;
    reg [4:0] i_reg;
    integer c;
    reg signed [15:0] val1, val2, relu1, relu2;

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= 2'd0; valid_out <= 1'b0; i_reg <= 5'd0;
        end else begin
            case (state)
                2'd0: begin
                    valid_out <= 1'b0;
                    if (valid_in) begin state <= 2'd1; i_reg <= 5'd0; end
                end
                2'd1: begin
                    for (c = 0; c < 16; c = c + 1) begin
                        val1 = conv_in[(((c*50)+(i_reg*2))  *16) +: 16];
                        val2 = conv_in[(((c*50)+(i_reg*2+1))*16) +: 16];
                        relu1 = (val1 > 0) ? val1 : 16'sd0;
                        relu2 = (val2 > 0) ? val2 : 16'sd0;
                        pool_out[(((c*25)+i_reg)*16) +: 16] <= (relu1 > relu2) ? relu1 : relu2;
                    end
                    if (i_reg == 5'd24) state <= 2'd2;
                    else                i_reg <= i_reg + 1'b1;
                end
                2'd2: begin valid_out <= 1'b1; state <= 2'd0; end
                default: state <= 2'd0;
            endcase
        end
    end
endmodule      