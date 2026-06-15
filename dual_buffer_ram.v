`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.06.2026 10:42:17
// Design Name: 
// Module Name: dual_buffer_ram
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


module dual_buffer_ram  #( DATA_WIDTH = 50 , DATA_DEPTH = 128 )
(input wire clk , 
input wire  write_enable ,
input wire [$clog2(DATA_DEPTH)-1:0] wr_addr ,
input wire [DATA_WIDTH-1:0] data_in_a ,

input wire  read_enable ,
input wire [$clog2(DATA_DEPTH)-1:0] rd_addr ,
output reg [DATA_WIDTH-1:0]  data_out_b
);

reg [DATA_WIDTH-1:0] ram_memory [0:DATA_DEPTH-1];

always @ (posedge clk) 
                      begin
                            if (write_enable)
                                            begin 
                                                 ram_memory [wr_addr] <= data_in_a;
                                            end  
                                if (read_enable)
                                               begin 
                                                    data_out_b <= ram_memory [rd_addr];
                                               end 
                                           end     
endmodule