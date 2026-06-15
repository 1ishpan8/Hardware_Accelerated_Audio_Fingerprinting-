`timescale 1ns / 1ps

module fft_input_packager #(
    parameter DATA_WIDTH = 32,
    parameter PACKET_LEN = 1024 
)(
    input  wire                  aclk,
    input  wire                  aresetn,
    input  wire                  start_trigger, 
    
    output reg  [9:0]            rom_addr,
    input  wire [DATA_WIDTH-1:0] rom_data,
    
    input  wire                  m_axis_data_tready,
    output reg                   m_axis_data_tvalid,
    output reg  [DATA_WIDTH-1:0] m_axis_data_tdata,
    output wire                  m_axis_data_tlast 
);

    reg [10:0] count; 
    reg [1:0]  state;
    
    localparam IDLE = 2'd0;
    localparam SEND = 2'd1;
    localparam DONE = 2'd2;

    assign m_axis_data_tlast = (state == SEND) && (count == PACKET_LEN - 1);

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axis_data_tvalid <= 1'b0;
            m_axis_data_tdata  <= {DATA_WIDTH{1'b0}};
            count              <= 11'd0;
            rom_addr           <= 10'd0; 
            state              <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (start_trigger) begin
                        m_axis_data_tvalid <= 1'b1;
                        m_axis_data_tdata  <= rom_data;
                        count              <= 11'd0;
                        rom_addr           <= 10'd0;
                        state              <= SEND;
                    end
                end
                
                SEND: begin
                    if (m_axis_data_tvalid && m_axis_data_tready) begin
                        if (count == PACKET_LEN - 1) begin
                            m_axis_data_tvalid <= 1'b0;
                            state              <= DONE;
                        end else begin
                            count             <= count + 1'b1;
                            rom_addr          <= rom_addr + 1'b1;
                            m_axis_data_tdata <= rom_data; 
                        end
                    end
                end
                
                DONE: begin
                    state <= IDLE; // Return to allow back-to-back testing
                end
            endcase
        end
    end
endmodule