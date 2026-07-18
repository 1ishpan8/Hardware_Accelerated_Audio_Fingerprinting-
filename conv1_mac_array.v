`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.06.2026 15:15:49
// Design Name: 
// Module Name: conv1_mac_array
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


module conv1_mac_array (
input wire clk , 
input wire rst , 
input wire valid_in , 
input wire [49:0] fingerprint_in ,
output reg valid_out


    );
    
    wire [51:0] padded_in = {1'b0 , fingerprint_in , 1'b0};
    
    wire [2:0] window_in_0 = padded_in [2:0];
    wire [2:0] window_in_1 = padded_in [3:1];
    wire [2:0] window_in_2 = padded_in [4:2];
    wire [2:0] window_in_3 = padded_in [5:3];
    wire [2:0] window_in_4 = padded_in [6:4];
    wire [2:0] window_in_5 = padded_in [7:5];
    wire [2:0] window_in_6 = padded_in [8:6];
    wire [2:0] window_in_7 = padded_in [9:7];
    wire [2:0] window_in_8 = padded_in [10:8];
    wire [2:0] window_in_9 = padded_in [11:9];
    wire [2:0] window_in_10 = padded_in [12:10];
    wire [2:0] window_in_11 = padded_in [13:11];
    wire [2:0] window_in_12 = padded_in [14:12];
    wire [2:0] window_in_13 = padded_in [15:13];
    wire [2:0] window_in_14 = padded_in [16:14];
    wire [2:0] window_in_15 = padded_in [17:15];
    wire [2:0] window_in_16 = padded_in [18:16];
    wire [2:0] window_in_17 = padded_in [19:17];
    wire [2:0] window_in_18 = padded_in [20:18];
    wire [2:0] window_in_19 = padded_in [21:19];
    wire [2:0] window_in_20 = padded_in [22:20];
    wire [2:0] window_in_21 = padded_in [23:21];
    wire [2:0] window_in_22 = padded_in [24:22];
    wire [2:0] window_in_23 = padded_in [25:23];
    wire [2:0] window_in_24 = padded_in [26:24];
    wire [2:0] window_in_25 = padded_in [27:25];
    wire [2:0] window_in_26 = padded_in [28:26];
    wire [2:0] window_in_27 = padded_in [29:27];
    wire [2:0] window_in_28 = padded_in [30:28];
    wire [2:0] window_in_29 = padded_in [31:29];
    wire [2:0] window_in_30 = padded_in [32:30];
    wire [2:0] window_in_31 = padded_in [33:31];
    wire [2:0] window_in_32 = padded_in [34:32];
    wire [2:0] window_in_33 = padded_in [35:33];
    wire [2:0] window_in_34 = padded_in [36:34];
    wire [2:0] window_in_35 = padded_in [37:35];
    wire [2:0] window_in_36 = padded_in [38:36];
    wire [2:0] window_in_37 = padded_in [39:37];
    wire [2:0] window_in_38 = padded_in [40:38];
    wire [2:0] window_in_39 = padded_in [41:39];
    wire [2:0] window_in_40 = padded_in [42:40];
    wire [2:0] window_in_41 = padded_in [43:41];
    wire [2:0] window_in_42 = padded_in [44:42];
    wire [2:0] window_in_43 = padded_in [45:43];
    wire [2:0] window_in_44 = padded_in [46:44];
    wire [2:0] window_in_45 = padded_in [47:45];
    wire [2:0] window_in_46 = padded_in [48:46];
    wire [2:0] window_in_47 = padded_in [49:47];
    wire [2:0] window_in_48 = padded_in [50:48];
    wire [2:0] window_in_49 = padded_in [51:49];
    
    
    
endmodule
