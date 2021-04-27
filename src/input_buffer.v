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
    i_data_ch0,
    i_data_ch0_val,
    i_data_ch1,
    i_data_ch1_val,
    i_data_ch2,
    i_data_ch2_val,
    i_data_req,
    o_data_ch0,
    o_data_ch0_val,
    o_data_ch1,
    o_data_ch1_val,
    o_data_ch2,
    o_data_ch2_val,
    data_counter_ch0,
    data_counter_ch1,
    data_counter_ch2,
    o_empty,
    o_full
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter DAT_WIDTH     = 8;
parameter NUM_CHANNEL   = 3;
parameter NUM_RDATA     = 3;
parameter FF_DEPTH      = 8;
parameter FF_ADDR_WIDTH = 3;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input  wire                                 clk;
input  wire                                 rst;
input  wire [DAT_WIDTH - 1 : 0]             i_data_ch0;
input  wire                                 i_data_ch0_val;
input  wire [DAT_WIDTH - 1 : 0]             i_data_ch1;
input  wire                                 i_data_ch1_val;
input  wire [DAT_WIDTH - 1 : 0]             i_data_ch2;
input  wire                                 i_data_ch2_val;
input  wire                                 i_data_req;
output wire [DAT_WIDTH * NUM_RDATA - 1 : 0] o_data_ch0;
output wire                                 o_data_ch0_val;
output wire [DAT_WIDTH * NUM_RDATA - 1 : 0] o_data_ch1;
output wire                                 o_data_ch1_val;
output wire [DAT_WIDTH * NUM_RDATA - 1 : 0] o_data_ch2;
output wire                                 o_data_ch2_val;
output wire [FF_ADDR_WIDTH - 1 : 0]         data_counter_ch0;
output wire [FF_ADDR_WIDTH - 1 : 0]         data_counter_ch1;
output wire [FF_ADDR_WIDTH - 1 : 0]         data_counter_ch2;
output wire                                 o_empty;
output wire                                 o_full;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire [NUM_CHANNEL - 1 : 0] full;
wire [NUM_CHANNEL - 1 : 0] empty;

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
    .wr_req       (i_data_ch0_val),
    .wr_data      (i_data_ch0),
    .rd_req       (i_data_req),
    .rd_data      (o_data_ch0),
    .rd_data_val  (o_data_ch0_val),
    .data_counter (data_counter_ch0),
    .full         (full[0]),
    .empty        (empty[0])
    );

// Channel 1
fifo_p1o3 
    #(
    .NUM_RDATA     (NUM_RDATA),
    .DAT_WIDTH     (DAT_WIDTH),
    .FF_DEPTH      (FF_DEPTH),
    .FF_ADDR_WIDTH (FF_ADDR_WIDTH)
    )
fifo_ch1
    (
    .clk          (clk),
    .rst          (rst),
    .wr_req       (i_data_ch1_val),
    .wr_data      (i_data_ch1),
    .rd_req       (i_data_req),
    .rd_data      (o_data_ch1),
    .rd_data_val  (o_data_ch1_val),
    .data_counter (data_counter_ch1),
    .full         (full[1]),
    .empty        (empty[1])
    );

// Channel 2
fifo_p1o3 
    #(
    .NUM_RDATA     (NUM_RDATA),
    .DAT_WIDTH     (DAT_WIDTH),
    .FF_DEPTH      (FF_DEPTH),
    .FF_ADDR_WIDTH (FF_ADDR_WIDTH)
    )
fifo_ch2
    (
    .clk          (clk),
    .rst          (rst),
    .wr_req       (i_data_ch2_val),
    .wr_data      (i_data_ch2),
    .rd_req       (i_data_req),
    .rd_data      (o_data_ch2),
    .rd_data_val  (o_data_ch2_val),
    .data_counter (data_counter_ch2),
    .full         (full[2]),
    .empty        (empty[2])
    );

assign o_full = |full;
assign o_empty = &o_empty;

endmodule
