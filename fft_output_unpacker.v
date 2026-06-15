`timescale 1ns / 1ps

module fft_output_unpacker #( 
    parameter DATA_WIDTH = 32
)(
    input  wire                  aclk,
    input  wire                  aresetn,
    
    input  wire                  s_axis_data_tvalid,
    input  wire                  s_axis_data_tlast,
    input  wire [DATA_WIDTH-1:0] s_axis_data_tdata,
    output reg                   s_axis_data_tready 
);
 
    reg [DATA_WIDTH-1:0] capture_reg;
    reg                  packet_done;
 
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axis_data_tready <= 1'b0; 
            capture_reg        <= {DATA_WIDTH{1'b0}};
            packet_done        <= 1'b0;
        end else begin
            if (!packet_done) begin
                s_axis_data_tready <= 1'b1;
            end

            if (s_axis_data_tvalid && s_axis_data_tready) begin
                capture_reg <= s_axis_data_tdata;
                
                if (s_axis_data_tlast) begin
                    packet_done        <= 1'b1;
                    s_axis_data_tready <= 1'b0; 
                end
            end
            
            if (packet_done) begin
                packet_done        <= 1'b0; 
                s_axis_data_tready <= 1'b1;
            end
        end
    end
endmodule
