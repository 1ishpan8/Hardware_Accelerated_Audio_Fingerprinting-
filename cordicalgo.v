`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.06.2026 10:24:49
// Design Name: 
// Module Name: cordicalgo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cordicalgo #(
    parameter DATA_WIDTH = 16
)(
    input  wire                  clk,
    input  wire [DATA_WIDTH-1:0] X_in,      // Real from FFT
    input  wire [DATA_WIDTH-1:0] Y_in,      // Imaginary from FFT
    output wire [DATA_WIDTH:0]   magnitude  // Output Magnitude
);

    localparam BIT_WIDTH = DATA_WIDTH;

    reg signed [DATA_WIDTH:0] X [0:BIT_WIDTH-1];
    reg signed [DATA_WIDTH:0] Y [0:BIT_WIDTH-1];

    always @(posedge clk) begin
        X[0] <= (X_in[DATA_WIDTH-1]) ? -X_in : X_in;
        Y[0] <= (Y_in[DATA_WIDTH-1]) ? -Y_in : Y_in;
    end
    
    genvar i;
    generate
        for (i = 0; i < BIT_WIDTH - 1; i = i + 1) begin: cordic_pipeline
            
            wire signed [DATA_WIDTH:0] X_shr;
            wire signed [DATA_WIDTH:0] Y_shr;
            wire                       Y_sign;

            assign X_shr  = X[i] >>> i;
            assign Y_shr  = Y[i] >>> i;
            
            assign Y_sign = Y[i][DATA_WIDTH];

            always @(posedge clk) begin
                if (Y_sign) begin 
                    X[i+1] <= X[i] - Y_shr;
                    Y[i+1] <= Y[i] + X_shr;
                end else begin    
                   
                    X[i+1] <= X[i] + Y_shr;
                    Y[i+1] <= Y[i] - X_shr;
                end
            end
        end
    endgenerate

    assign magnitude = X[BIT_WIDTH-1];

endmodule