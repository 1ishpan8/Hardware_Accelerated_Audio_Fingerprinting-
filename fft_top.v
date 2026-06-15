`timescale 1ns / 1ps

module fft_top (
    input  wire        clk,
    input  wire        rst_n,
    
    // Testbench Audio Input 
    input  wire [31:0] audio_in_tdata,  
    input  wire        audio_in_tvalid,
    output wire        audio_in_tready,
    input  wire        audio_in_tlast
);

    // --- 1. INTERNAL WIRES ---
    // FFT to Delay Lines
    wire [31:0] fft_out_tdata;
    wire        fft_out_tvalid;
    wire        fft_out_tlast;
    
    // CORDIC to Peak Detector
    wire        cordic_valid;
    wire        frame_done_pulse; 
    wire [16:0] cordic_magnitude;
    
    // Peak Detector to BRAM
    wire [9:0]  peak_0, peak_1, peak_2, peak_3, peak_4;
    wire [49:0] packed_fingerprint;
    
    // BRAM Pointer
    reg  [6:0]  write_ptr;

    // --- 2. THE FFT FRONT-END ---
    wire config_tready;
    reg  config_done;

    always @(posedge clk) begin
        if (!rst_n) 
            config_done <= 1'b0;
        else if (config_tready && !config_done) 
            config_done <= 1'b1; 
    end

    xfft_0 fft_inst (
        .aclk(clk),
        .aresetn(rst_n),
        .s_axis_config_tdata(8'b0000_0001), 
        .s_axis_config_tvalid(~config_done),
        .s_axis_config_tready(config_tready),
        
        .s_axis_data_tdata(audio_in_tdata),
        .s_axis_data_tvalid(audio_in_tvalid),
        .s_axis_data_tready(audio_in_tready), 
        .s_axis_data_tlast(audio_in_tlast),
        
        .m_axis_data_tdata(fft_out_tdata),
        .m_axis_data_tvalid(fft_out_tvalid),
        .m_axis_data_tready(1'b1), // Always ready to receive
        .m_axis_data_tlast(fft_out_tlast)
    );

    // --- 3. THE 16-CYCLE SHIFT REGISTERS ---
    // This perfectly synchronizes the FFT's valid and last signals with 
    // the 16-cycle mathematical delay of your custom CORDIC pipeline.
    reg [15:0] valid_delay_line;
    reg [15:0] tlast_delay_line;

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_delay_line <= 16'd0;
            tlast_delay_line <= 16'd0;
        end else begin
            valid_delay_line <= {valid_delay_line[14:0], fft_out_tvalid};
            tlast_delay_line <= {tlast_delay_line[14:0], fft_out_tlast};
        end
    end

assign cordic_valid = valid_delay_line[15];


    // --- 4. THE CORDIC ---
    cordicalgo #(
        .DATA_WIDTH(16)
    ) my_cordic (
        .clk(clk),
        .X_in(fft_out_tdata[15:0]),  
        .Y_in(fft_out_tdata[31:16]), 
        .magnitude(cordic_magnitude)
    );

    // --- 5. THE PEAK DETECTOR ---
    peak_detector my_sorter (
        .clk(clk),
        .rst_n(~rst_n),
        .data_in(cordic_magnitude),
        .data_en(cordic_valid),
        .fingerprint_0(peak_0),
        .fingerprint_1(peak_1),
        .fingerprint_2(peak_2),
        .fingerprint_3(peak_3),
        .fingerprint_4(peak_4),
        .fingerprint_valid(frame_done_pulse) 
    );

    // --- 6. THE CIRCULAR BUFFER (RAM) ---
    assign packed_fingerprint = {peak_4, peak_3, peak_2, peak_1, peak_0};

    // Safely increment write pointer only at the end of a valid 1024-point frame
    always @(posedge clk) begin
        if (!rst_n) 
            write_ptr <= 7'd0;
        else if (frame_done_pulse) 
            write_ptr <= write_ptr + 1'b1;
    end

    dual_buffer_ram #(
        .DATA_WIDTH(50),
        .DATA_DEPTH(128)
    ) audio_history_buffer (
        .clk(clk),
        .write_enable(frame_done_pulse), 
        .wr_addr(write_ptr),
        .data_in_a(packed_fingerprint),
        .read_enable(1'b0), 
        .rd_addr(7'd0),
        .data_out_b()
    );

endmodule