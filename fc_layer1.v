`timescale 1ns / 1ps
// fc_layer1 - sequential MAC (BRAM-friendly), reset added.
module fc_layer1 #(
    parameter FRAC_BITS = 8
)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire          valid_in,
    input  wire [6143:0] flat_in,   // 384 x 16b
    output reg  [1023:0] fc1_out,   // 64 x 16b
    output reg           valid_out
);
    reg signed [15:0] weights [0:24575];
    reg signed [15:0] biases  [0:63];
    initial begin
        $readmemh("fc1_weights.mem", weights);
        $readmemh("fc1_bias.mem",    biases);
    end

    localparam IDLE = 3'd0, LOAD = 3'd1, MAC = 3'd2, WRITE = 3'd3, DONE = 3'd4;

    function signed [15:0] sat16(input signed [39:0] v);
        sat16 = (v >  40'sd32767) ?  16'sd32767 :
                (v < -40'sd32768) ? -16'sd32768 : v[15:0];
    endfunction

    reg [2:0] state;
    reg [5:0] n_reg;
    reg [8:0] i_reg;
    reg signed [39:0] acc;
    wire signed [15:0] val_in = flat_in[(i_reg * 16) +: 16];

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE; valid_out <= 1'b0;
            n_reg <= 6'd0; i_reg <= 9'd0;
        end else begin
            case (state)
                IDLE: begin
                    valid_out <= 1'b0;
                    if (valid_in) begin n_reg <= 6'd0; state <= LOAD; end
                end
                LOAD: begin
                    acc   <= $signed(biases[n_reg]) <<< FRAC_BITS;
                    i_reg <= 9'd0;
                    state <= MAC;
                end
                MAC: begin
                    acc <= acc + (val_in * weights[(n_reg * 384) + i_reg]);
                    if (i_reg == 9'd383) state <= WRITE;
                    else                 i_reg <= i_reg + 1'b1;
                end
                WRITE: begin
                    fc1_out[(n_reg * 16) +: 16]
                        <= (acc > 0) ? sat16(acc >>> FRAC_BITS) : 16'sd0;
                    if (n_reg == 6'd63) state <= DONE;
                    else begin n_reg <= n_reg + 1'b1; state <= LOAD; end
                end
                DONE: begin valid_out <= 1'b1; state <= IDLE; end
                default: state <= IDLE;
            endcase
        end
    end
endmodule                                            

