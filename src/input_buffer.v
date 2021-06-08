`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 03/18/2021 02:52:36 PM
// Design Name: Activation Input Buffer
// Module Name: input_buffer
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: Buffer for activation input. 3 positions, 3 channel, max 8 positions
// 
// Dependencies:
//  fifo_p1o3
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module input_buffer(
    clk,
    rst,
    i_data,
    i_data_vld,
    i_data_req,
    o_data,
    o_data_vld,
    data_counter,
    o_empty,
    o_full,
    o_half
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter BIT_WIDTH     = 8;
parameter NUM_CHANNEL   = 3;
parameter NUM_RDATA     = 3;
parameter FF_DEPTH      = 16;
parameter FF_ADDR_WIDTH = 4;

parameter DAT_WIDTH     = BIT_WIDTH * NUM_CHANNEL;
////////////////////////////////////////////////////////////////////////////////
// Port declarations
input  wire                                 clk;
input  wire                                 rst;
input  wire [DAT_WIDTH - 1 : 0]             i_data;
input  wire                                 i_data_vld;
input  wire                                 i_data_req;
output wire [DAT_WIDTH * NUM_RDATA - 1 : 0] o_data;
output wire                                 o_data_vld;
output wire [FF_ADDR_WIDTH : 0]             data_counter;
output wire                                 o_empty;
output wire                                 o_full;
output wire                                 o_half;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire full;
wire empty;

// Channel 0
fifo_p1o3
    #(
    .NUM_RDATA     (NUM_RDATA),
    .DAT_WIDTH     (DAT_WIDTH),
    .FF_DEPTH      (FF_DEPTH),
    .FF_ADDR_WIDTH (FF_ADDR_WIDTH)
    )
fifo_ch0
    (
    .clk          (clk),
    .rst          (rst),
    .wr_req       (i_data_vld),
    .wr_data      (i_data),
    .rd_req       (i_data_req),
    .rd_data      (o_data),
    .rd_data_vld  (o_data_vld),
    .data_counter (data_counter),
    .full         (full),
    .empty        (empty)
    );

assign o_half = (data_counter > FF_DEPTH * 3 / 4);
assign o_full = |full;
assign o_empty = &empty;

endmodule
