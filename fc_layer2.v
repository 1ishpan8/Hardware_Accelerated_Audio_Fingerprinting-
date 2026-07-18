`timescale 1ns / 1ps
// fc_layer2 - parameterized classes, running argmax, reset added.
module fc_layer2 #(
    parameter NUM_CLASSES = 3,
    parameter FRAC_BITS   = 8
)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire          valid_in,
    input  wire [1023:0] fc1_in,
    output reg  [5:0]    class_out,
    output reg           valid_out
);
    reg signed [15:0] weights [0:NUM_CLASSES*64-1];
    reg signed [15:0] biases  [0:NUM_CLASSES-1];
    initial begin
        $readmemh("fc2_weights.mem", weights);
        $readmemh("fc2_bias.mem",  biases);
    end

    localparam IDLE = 3'd0, LOAD = 3'd1, MAC = 3'd2, CMP = 3'd3, DONE = 3'd4;

    reg [2:0] state;
    reg [5:0] n_reg, i_reg;
    reg signed [39:0] acc, best;
    reg [5:0] best_idx;
    wire signed [15:0] val_in = fc1_in[(i_reg * 16) +: 16];

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE; valid_out <= 1'b0;
            n_reg <= 6'd0; i_reg <= 6'd0;
            class_out <= 6'd0; best_idx <= 6'd0;
        end else begin
            case (state)
                IDLE: begin
                    valid_out <= 1'b0;
                    if (valid_in) begin n_reg <= 6'd0; state <= LOAD; end
                end
                LOAD: begin
                    acc   <= $signed(biases[n_reg]) <<< FRAC_BITS;
                    i_reg <= 6'd0;
                    state <= MAC;
                end
                MAC: begin
                    acc <= acc + (val_in * weights[(n_reg * 64) + i_reg]);
                    if (i_reg == 6'd63) state <= CMP;
                    else                i_reg <= i_reg + 1'b1;
                end
                CMP: begin
                    if (n_reg == 6'd0 || acc > best) begin
                        best     <= acc;
                        best_idx <= n_reg;
                    end
                    if (n_reg == NUM_CLASSES - 1) state <= DONE;
                    else begin n_reg <= n_reg + 1'b1; state <= LOAD; end
                end
                DONE: begin
                    class_out <= best_idx;
                    valid_out <= 1'b1;
                    state     <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
