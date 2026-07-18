`timescale 1ns / 1ps
//
// fft_top - CNN integration FIXED
//  * Signals renamed to the ones that actually exist: valid trigger is
//    frame_done_pulse, data is packed_fingerprint (the uploaded version
//    referenced two nonexistent nets, creating undriven implicit wires).
//  * SINGLE driver on m_axis_feat_*: the class prediction is latched into
//    the same AXI-Stream holding register (tvalid held until tready) -
//    the direct assign from cnn_final_valid was both a double-drive and a
//    re-introduction of the one-cycle-pulse protocol violation.
//  * rst_n wired into every CNN layer (required for X-free simulation).
//  Payload: {8'd0, class[5:0], fingerprint[49:0]}
//  C side:  class_id = (u64_word >> 50) & 0x3F;
//
module fft_top (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [31:0] s_axis_aud_tdata,
    input  wire        s_axis_aud_tvalid,
    output wire        s_axis_aud_tready,
    input  wire        s_axis_aud_tlast,

    output wire [63:0] m_axis_feat_tdata,
    output wire [7:0]  m_axis_feat_tkeep,
    output wire        m_axis_feat_tvalid,
    input  wire        m_axis_feat_tready,
    output wire        m_axis_feat_tlast
);
    // NOTE: if on-board magnitudes ever look overflowed, revisit this per
    // PG109 for your xfft configuration (scaling schedule lives here).
    localparam [15:0] FFT_CONFIG = 16'h0001;

    wire [31:0] fft_out_tdata;
    wire        fft_out_tvalid, fft_out_tlast;
    wire [16:0] cordic_magnitude;
    wire        frame_done_pulse;
    wire [9:0]  peak_0, peak_1, peak_2, peak_3, peak_4;
    wire [49:0] packed_fingerprint;
    wire        config_tready;
    reg         config_done;

    always @(posedge clk) begin
        if (!rst_n)                             config_done <= 1'b0;
        else if (config_tready && !config_done) config_done <= 1'b1;
    end

    xfft_0 fft_inst (
        .aclk(clk), .aresetn(rst_n),
        .s_axis_config_tdata(FFT_CONFIG),
        .s_axis_config_tvalid(~config_done),
        .s_axis_config_tready(config_tready),
        .s_axis_data_tdata(s_axis_aud_tdata),
        .s_axis_data_tvalid(s_axis_aud_tvalid),
        .s_axis_data_tready(s_axis_aud_tready),
        .s_axis_data_tlast(s_axis_aud_tlast),
        .m_axis_data_tdata(fft_out_tdata),
        .m_axis_data_tvalid(fft_out_tvalid),
        .m_axis_data_tready(1'b1),
        .m_axis_data_tlast(fft_out_tlast)
    );

    reg [15:0] valid_delay_line;
    always @(posedge clk) begin
        if (!rst_n) valid_delay_line <= 16'd0;
        else        valid_delay_line <= {valid_delay_line[14:0], fft_out_tvalid};
    end

    cordicalgo #(.DATA_WIDTH(16)) my_cordic (
        .clk(clk), .rst_n(rst_n),
        .X_in(fft_out_tdata[15:0]),
        .Y_in(fft_out_tdata[31:16]),
        .magnitude(cordic_magnitude)
    );

    peak_detector my_sorter (
        .clk(clk), .rst_n(rst_n),
        .data_in(cordic_magnitude),
        .data_en(valid_delay_line[15]),
        .fingerprint_0(peak_0), .fingerprint_1(peak_1),
        .fingerprint_2(peak_2), .fingerprint_3(peak_3),
        .fingerprint_4(peak_4),
        .fingerprint_valid(frame_done_pulse)
    );

    assign packed_fingerprint = {peak_4, peak_3, peak_2, peak_1, peak_0};

    // Hold the fingerprint stable for the whole CNN latency
    reg [49:0] fp_hold;
    always @(posedge clk) begin
        if (!rst_n)                fp_hold <= 50'd0;
        else if (frame_done_pulse) fp_hold <= packed_fingerprint;
    end

    // ---------------- CNN pipeline (3 classes) ----------------
    wire [12799:0] conv1_to_pool1;
    wire [6399:0]  pool1_to_conv2;
    wire [12799:0] conv2_to_pool2;
    wire [6143:0]  pool2_to_fc1;
    wire [1023:0]  fc1_to_fc2;
    wire conv1_v, pool1_v, conv2_v, pool2_v, fc1_v, cnn_final_valid;
    wire [5:0] predicted_class;

    conv1_mac conv1_inst (
        .clk(clk), .rst_n(rst_n),
        .valid_in(frame_done_pulse),
        .fingerprint_in(fp_hold),
        .conv_out(conv1_to_pool1),
        .valid_out(conv1_v)
    );

    // 16ch, 50 -> 25   (module lives in maxpool_relu2.v)
    relu_maxpool_layer2 pool1_inst (
        .clk(clk), .rst_n(rst_n),
        .valid_in(conv1_v),
        .conv_in(conv1_to_pool1),
        .pool_out(pool1_to_conv2),
        .valid_out(pool1_v)
    );

    conv2_mac #(.FRAC_BITS(8)) conv2_inst (
        .clk(clk), .rst_n(rst_n),
        .valid_in(pool1_v),
        .pool_in(pool1_to_conv2),
        .conv2_out(conv2_to_pool2),
        .valid_out(conv2_v)
    );

    // 32ch, 25 -> 12   (module lives in maxpool_relu1.v)
    relu_maxpool2_layer pool2_inst (
        .clk(clk), .rst_n(rst_n),
        .valid_in(conv2_v),
        .conv_in(conv2_to_pool2),
        .pool_out(pool2_to_fc1),
        .valid_out(pool2_v)
    );

    fc_layer1 #(.FRAC_BITS(8)) fc1_inst (
        .clk(clk), .rst_n(rst_n),
        .valid_in(pool2_v),
        .flat_in(pool2_to_fc1),
        .fc1_out(fc1_to_fc2),
        .valid_out(fc1_v)
    );

    fc_layer2 #(.NUM_CLASSES(3), .FRAC_BITS(8)) fc2_inst (
        .clk(clk), .rst_n(rst_n),
        .valid_in(fc1_v),
        .fc1_in(fc1_to_fc2),
        .class_out(predicted_class),
        .valid_out(cnn_final_valid)
    );

    // ------------- SINGLE AXI-Stream output stage -------------
    reg [63:0] feat_data_r;
    reg        feat_valid_r;
    always @(posedge clk) begin
        if (!rst_n) begin
            feat_data_r  <= 64'd0;
            feat_valid_r <= 1'b0;
        end else begin
            if (cnn_final_valid) begin
                feat_data_r  <= {8'd0, predicted_class, fp_hold};
                feat_valid_r <= 1'b1;
            end else if (feat_valid_r && m_axis_feat_tready) begin
                feat_valid_r <= 1'b0;
            end
        end
    end

    assign m_axis_feat_tdata  = feat_data_r;
    assign m_axis_feat_tvalid = feat_valid_r;
    assign m_axis_feat_tlast  = feat_valid_r;
    assign m_axis_feat_tkeep  = 8'hFF;

endmodule