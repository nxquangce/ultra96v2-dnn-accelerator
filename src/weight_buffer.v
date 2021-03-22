`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 03/22/2021 03:15:48 PM
// Design Name: Weight Buffer
// Module Name: weight_buffer
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: Buffer for weights. 3 positions, 3 channels, 4 kernel.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module weight_buffer(
    clk,
    rst,
    i_data_kn0,
    i_data_kn0_val,
    i_data_kn1,
    i_data_kn1_val,
    i_data_kn2,
    i_data_kn2_val,
    i_data_kn3,
    i_data_kn3_val,
    o_data_req,
    o_data_3ch_kn0,
    o_data_3ch_kn0_val,
    o_data_3ch_kn1,
    o_data_3ch_kn1_val,
    o_data_3ch_kn2,
    o_data_3ch_kn2_val,
    o_data_3ch_kn3,
    o_data_3ch_kn3_val
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter DAT_WIDTH     = 8;
parameter NUM_KERNEL    = 4;
parameter NUM_CHANNEL   = 3;
parameter NUM_RDATA     = 3;
parameter FF_DEPTH      = NUM_RDATA;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input  wire                                               clk;
input  wire                                               rst;
input  wire [DAT_WIDTH * NUM_CHANNEL - 1 : 0]             i_data_kn0;
input  wire                                               i_data_kn0_val;
input  wire [DAT_WIDTH * NUM_CHANNEL - 1 : 0]             i_data_kn1;
input  wire                                               i_data_kn1_val;
input  wire [DAT_WIDTH * NUM_CHANNEL - 1 : 0]             i_data_kn2;
input  wire                                               i_data_kn2_val;
input  wire [DAT_WIDTH * NUM_CHANNEL - 1 : 0]             i_data_kn3;
input  wire                                               i_data_kn3_val;
input  wire                                               o_data_req;
output wire [DAT_WIDTH * NUM_CHANNEL * NUM_RDATA - 1 : 0] o_data_3ch_kn0;
output wire                                               o_data_3ch_kn0_val;
output wire [DAT_WIDTH * NUM_CHANNEL * NUM_RDATA - 1 : 0] o_data_3ch_kn1;
output wire                                               o_data_3ch_kn1_val;
output wire [DAT_WIDTH * NUM_CHANNEL * NUM_RDATA - 1 : 0] o_data_3ch_kn2;
output wire                                               o_data_3ch_kn2_val;
output wire [DAT_WIDTH * NUM_CHANNEL * NUM_RDATA - 1 : 0] o_data_3ch_kn3;
output wire                                               o_data_3ch_kn3_val;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [DAT_WIDTH * NUM_CHANNEL - 1 : 0] weight_kn0_reg [NUM_RDATA - 1 : 0];
reg [DAT_WIDTH * NUM_CHANNEL - 1 : 0] weight_kn1_reg [NUM_RDATA - 1 : 0];
reg [DAT_WIDTH * NUM_CHANNEL - 1 : 0] weight_kn2_reg [NUM_RDATA - 1 : 0];
reg [DAT_WIDTH * NUM_CHANNEL - 1 : 0] weight_kn3_reg [NUM_RDATA - 1 : 0];
reg [NUM_RDATA - 1 : 0] weight_val_reg [NUM_KERNEL - 1 : 0];

// Cache weight data
always @(posedge clk) begin
    if (rst) begin
        weight_kn0_reg[0] = 0;
        weight_kn1_reg[0] = 0;
        weight_kn2_reg[0] = 0;
        weight_kn3_reg[0] = 0;
        weight_kn0_reg[1] = 0;
        weight_kn1_reg[1] = 0;
        weight_kn2_reg[1] = 0;
        weight_kn3_reg[1] = 0;
        weight_kn0_reg[2] = 0;
        weight_kn1_reg[2] = 0;
        weight_kn2_reg[2] = 0;
        weight_kn3_reg[2] = 0;
        // weight_kn0_reg[3] = 0;
        // weight_kn1_reg[3] = 0;
        // weight_kn2_reg[3] = 0;
        // weight_kn3_reg[3] = 0;
    end
    else begin
        if (i_data_kn0_val) begin
            weight_kn0_reg[0] <= i_data_kn0;
            weight_kn0_reg[1] <= weight_kn0_reg[0];
            weight_kn0_reg[2] <= weight_kn0_reg[1];
            // weight_kn0_reg[3] <= weight_kn0_reg[2];
        end
        if (i_data_kn1_val) begin
            weight_kn1_reg[0] = i_data_kn1;
            weight_kn1_reg[1] = weight_kn1_reg[0];
            weight_kn1_reg[2] = weight_kn1_reg[1];
            // weight_kn1_reg[3] = weight_kn1_reg[2];
        end
        if (i_data_kn2_val) begin
            weight_kn2_reg[0] = i_data_kn2;
            weight_kn2_reg[1] = weight_kn2_reg[0];
            weight_kn2_reg[2] = weight_kn2_reg[1];
            // weight_kn2_reg[3] = weight_kn2_reg[2];
        end
        if (i_data_kn3_val) begin
            weight_kn3_reg[0] = i_data_kn3;
            weight_kn3_reg[1] = weight_kn3_reg[0];
            weight_kn3_reg[2] = weight_kn3_reg[1];
            // weight_kn3_reg[3] = weight_kn3_reg[2];
        end
    end
end

// Cache valid register
always @(posedge clk) begin
    if (rst | o_data_req) begin
        weight_val_reg[0] <= 0;
        weight_val_reg[1] <= 0;
        weight_val_reg[2] <= 0;
        weight_val_reg[3] <= 0;
    end
    else begin
        if (i_data_kn0_val) begin
            weight_val_reg[0][0] <= 1'b1;
            weight_val_reg[0][1] <= weight_val_reg[0][0];
            weight_val_reg[0][2] <= weight_val_reg[0][1];
        end
        if (i_data_kn1_val) begin
            weight_val_reg[1][0] <= 1'b1;
            weight_val_reg[1][1] <= weight_val_reg[1][0];
            weight_val_reg[1][2] <= weight_val_reg[1][1];
        end
        if (i_data_kn2_val) begin
            weight_val_reg[2][0] <= 1'b1;
            weight_val_reg[2][1] <= weight_val_reg[2][0];
            weight_val_reg[2][2] <= weight_val_reg[2][1];
        end
        if (i_data_kn3_val) begin
            weight_val_reg[3][0] <= 1'b1;
            weight_val_reg[3][1] <= weight_val_reg[3][0];
            weight_val_reg[3][2] <= weight_val_reg[3][1];
        end
    end
end

// Output data valid
assign o_data_3ch_kn0_val = &weight_val_reg[0] & o_data_req;
assign o_data_3ch_kn1_val = &weight_val_reg[1] & o_data_req;
assign o_data_3ch_kn2_val = &weight_val_reg[2] & o_data_req;
assign o_data_3ch_kn3_val = &weight_val_reg[3] & o_data_req;

// Output data
assign o_data_3ch_kn0 = {weight_kn0_reg[0], weight_kn0_reg[1], weight_kn0_reg[2]}; //, weight_kn0_reg[3]};
assign o_data_3ch_kn1 = {weight_kn1_reg[0], weight_kn1_reg[1], weight_kn1_reg[2]}; //, weight_kn1_reg[3]};
assign o_data_3ch_kn2 = {weight_kn2_reg[0], weight_kn2_reg[1], weight_kn2_reg[2]}; //, weight_kn2_reg[3]};
assign o_data_3ch_kn3 = {weight_kn3_reg[0], weight_kn3_reg[1], weight_kn3_reg[2]}; //, weight_kn3_reg[3]};

endmodule
