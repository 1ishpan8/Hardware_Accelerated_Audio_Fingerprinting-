`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.06.2026 14:46:30
// Design Name: 
// Module Name: tb_system_top
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

`timescale 1ns / 1ps

module tb_fft_top();

    // System Signals
    reg clk;
    reg rst_n;

    // ROM Setup (3 seconds of 44.1kHz audio)
    reg [15:0] rom_memory [0:132299];
    integer i;

    // AXI-Stream Master Signals
    reg [31:0] s_axis_tdata;
    reg        s_axis_tvalid;
    wire       s_axis_tready; 
    reg        s_axis_tlast;

    // Instantiate Top Module
    fft_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .audio_in_tdata(s_axis_tdata),
        .audio_in_tvalid(s_axis_tvalid),
        .audio_in_tready(s_axis_tready),
        .audio_in_tlast(s_axis_tlast)
    );

    // 100 MHz Clock Generation
    always #5 clk = ~clk;

    initial begin
        // Load the Python-generated hex file
        $readmemh("song_data.mem", rom_memory);
        $display("ROM successfully loaded with audio data.");

        // Initialize 
        clk = 0;
        rst_n = 0;
        s_axis_tvalid = 0;
        s_axis_tdata = 0;
        s_axis_tlast = 0;

        // Reset Sequence
        #100;
        rst_n = 1;
        #100;

        $display("Streaming 3 seconds of audio...");

        // Stream audio into the hardware pipeline
        for (i = 0; i < 132300; i = i + 1) begin
            
            // Pad 16-bit audio with 16 bits of imaginary zero
            s_axis_tdata = {16'd0, rom_memory[i]};
            s_axis_tvalid = 1'b1;
            
            // Assert tlast every 1024th sample
            if ((i + 1) % 1024 == 0) begin
                s_axis_tlast = 1'b1;
            end else begin
                s_axis_tlast = 1'b0;
            end

            // AXI Handshake: Wait if pipeline is choked
            wait(s_axis_tready == 1'b1);
            @(posedge clk); 
        end

        // End of stream
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        
        // Wait 2000 cycles for the final FFT frame and CORDIC math to clear
        #20000; 

        // Export the True Dual-Port BRAM contents to a physical file
        $writememh("extracted_features.mem", uut.audio_history_buffer.ram_memory);

        $display("SIMULATION COMPLETE. Features written to extracted_features.mem");
        $finish;
    end

endmodule