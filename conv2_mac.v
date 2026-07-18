`timescale 1ns / 1ps
// conv2_mac - reset added; rescale fixed: shift the FULL 40-bit
// accumulator, THEN saturate. (mac_accumulator[15:0] >>> F sliced the
// low bits first - an unsigned part-select - destroying the value.)
// sat16 lower bound corrected to -32768.
module conv2_mac #(
    parameter FRAC_BITS = 8
)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire          valid_in,
    input  wire [6399:0] pool_in,     // 16 ch x 25 x 16b
    output reg  [12799:0] conv2_out,  // 32 ch x 25 x 16b
    output reg           valid_out
);
    reg signed [15:0] weights [0:1535];
    reg signed [15:0] biases  [0:31];
    initial begin
        $readmemh("conv2_weights.mem", weights);
        $readmemh("conv2_bias.mem",    biases);
    end

    localparam IDLE = 2'd0, COMPUTE = 2'd1, DONE = 2'd2;

    function signed [15:0] sat16(input signed [39:0] v);
        sat16 = (v >  40'sd32767) ?  16'sd32767 :
                (v < -40'sd32768) ? -16'sd32768 : v[15:0];
    endfunction

    reg [1:0] state;
    reg [4:0] oc_reg, i_reg;
    integer ic;
    reg signed [39:0] mac_accumulator;
    reg signed [15:0] val_left, val_mid, val_right;

    always @(posedge clk) begin
        if (!rst_n) begin
            state     <= IDLE;
            valid_out <= 1'b0;
            oc_reg    <= 5'd0;
            i_reg     <= 5'd0;
        end else begin
            case (state)
                IDLE: begin
                    valid_out <= 1'b0;
                    if (valid_in) begin
                        state  <= COMPUTE;
                        oc_reg <= 5'd0;
                        i_reg  <= 5'd0;
                    end
                end
                COMPUTE: begin
                    mac_accumulator = $signed(biases[oc_reg]) <<< FRAC_BITS;
                    for (ic = 0; ic < 16; ic = ic + 1) begin
                        val_left  = (i_reg == 0)  ? 16'sd0 : pool_in[(((ic*25)+(i_reg-1))*16) +: 16];
                        val_mid   =                          pool_in[(((ic*25)+ i_reg   )*16) +: 16];
                        val_right = (i_reg == 24) ? 16'sd0 : pool_in[(((ic*25)+(i_reg+1))*16) +: 16];
                        mac_accumulator = mac_accumulator
                            + (val_left  * weights[(oc_reg*48)+(ic*3)+0])
                            + (val_mid   * weights[(oc_reg*48)+(ic*3)+1])
                            + (val_right * weights[(oc_reg*48)+(ic*3)+2]);
                    end

                    conv2_out[(((oc_reg*25)+i_reg)*16) +: 16]
                        <= sat16(mac_accumulator >>> FRAC_BITS);   // full-width shift

                    if (i_reg == 5'd24) begin
                        i_reg <= 5'd0;
                        if (oc_reg == 5'd31) state <= DONE;
                        else                 oc_reg <= oc_reg + 1'b1;
                    end else begin
                        i_reg <= i_reg + 1'b1;
                    end
                end
                DONE: begin
                    valid_out <= 1'b1;
                    state     <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule

