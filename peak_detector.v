`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.06.2026 10:44:13
// Design Name: 
// Module Name: peak_detector
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


module peak_detector (clk , rst_n , data_in , data_en , fingerprint_0 , fingerprint_1 , fingerprint_2 , fingerprint_3 , fingerprint_4 , fingerprint_valid);

input clk;
input rst_n;
input wire  [16:0] data_in;
input data_en;
output reg [9:0] fingerprint_0;
output reg [9:0] fingerprint_1;
output reg [9:0] fingerprint_2;
output reg [9:0] fingerprint_3;
output reg [9:0] fingerprint_4;
output reg fingerprint_valid; 

reg [16:0] max_mag [0:4];
reg [16:0] max_idx [0:4];


    reg [9:0] count;
    integer i; 
    
    always @ (posedge clk) begin
        if (rst_n) begin
            count <= 10'd0;
            for (i = 0; i < 5; i = i + 1) 
                                        begin
                                            max_mag[i] <= 17'd0;
                                            max_idx[i] <= 10'd0;
                                        end
        end 
        else if (data_en) begin

            count <= count + 1'b1;

            if (data_in > max_mag[0]) 
                                    begin
                                        max_mag[4] <= max_mag[3]; max_idx[4] <= max_idx[3];
                                        max_mag[3] <= max_mag[2]; max_idx[3] <= max_idx[2];
                                        max_mag[2] <= max_mag[1]; max_idx[2] <= max_idx[1];
                                        max_mag[1] <= max_mag[0]; max_idx[1] <= max_idx[0];
               
                                        max_mag[0] <= data_in;    
                                        max_idx[0] <= count;
            end
             
            else if (data_in > max_mag[1]) 
                                         begin
                                              max_mag[4] <= max_mag[3]; max_idx[4] <= max_idx[3];
                                              max_mag[3] <= max_mag[2]; max_idx[3] <= max_idx[2];
                                              max_mag[2] <= max_mag[1]; max_idx[2] <= max_idx[1];
               
                                              max_mag[1] <= data_in;    
                                              max_idx[1] <= count;
            end 
            
            else if (data_in > max_mag[2]) 
                                         begin
                                             max_mag[4] <= max_mag[3]; max_idx[4] <= max_idx[3];
                                             max_mag[3] <= max_mag[2]; max_idx[3] <= max_idx[2];
                                             max_mag[2] <= data_in;    max_idx[2] <= count;
            end 
            
            else if (data_in > max_mag[3])
                                         begin
                                              max_mag[4] <= max_mag[3]; max_idx[4] <= max_idx[3];
                                              max_mag[3] <= data_in;    max_idx[3] <= count;
            end 

            else if (data_in > max_mag[4]) 
                                         begin
                                              max_mag[4] <= data_in;    
                                              max_idx[4] <= count;
                
            if (count <= 1023) 
                             begin
                                  fingerprint_0 <= max_idx[0];
                                  fingerprint_1 <= max_idx[1];
                                  fingerprint_2 <= max_idx[2];
                                  fingerprint_3 <= max_idx[3];
                                  fingerprint_4 <= max_idx[4];
                                  fingerprint_valid <= 1'b1;
                                   
               end   
            else 
                begin 
                     fingerprint_valid <= 1'b0;
                end                 
            end
               else 
                   begin 
                        fingerprint_valid <= 1'b0;
                   end 
        end
    end
endmodule
