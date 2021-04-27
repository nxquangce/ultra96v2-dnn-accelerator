`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 04/27/2021 11:29:14 PM
// Design Name: 
// Module Name: accelerator_core_tb_data_gen
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: accelerator core test bench data generator
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module accelerator_core_tb_data_gen(
    clk,
    rst,
    o_data_req,
    i_data,
    i_data_val,
    i_weight,
    i_weight_val
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter BIT_WIDTH     = 8;
parameter NUM_CHANNEL   = 3;
parameter NUM_KERNEL    = 4;
parameter NUM_KCPE      = 3;    // Number of kernel-channel PE
parameter REG_WIDTH     = 32;

parameter NUM_RDATA     = 3;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input  wire                                                  clk;
input  wire                                                  rst;
input  wire                                                  o_data_req;
output wire [(BIT_WIDTH * NUM_CHANNEL             ) - 1 : 0] i_data;
output wire [(BIT_WIDTH * NUM_CHANNEL * NUM_KERNEL) - 1 : 0] i_weight;
output wire                                                  i_data_val;
output wire                                                  i_weight_val;

reg [(BIT_WIDTH * NUM_CHANNEL             ) - 1 : 0] i_data_reg;
reg                                                  i_data_val_reg;
reg [(BIT_WIDTH * NUM_CHANNEL * NUM_KERNEL) - 1 : 0] i_weight_reg;
reg                                                  i_weight_val_reg;

assign i_data = i_data_reg;
assign i_data_val = i_data_val_reg;
assign i_weight = i_weight_reg;
assign i_weight_val = i_weight_val_reg;

always @(posedge clk) begin
    if (rst) begin
        i_data_reg <= 24'h20_10_00;
        i_data_val_reg <= 0;
    end
    else if (o_data_req) begin
        i_data_reg[ 7: 0] <= i_data_reg[ 7: 0] + 1'b1;
        i_data_reg[15: 8] <= i_data_reg[15: 8] + 1'b1;
        i_data_reg[23:16] <= i_data_reg[23:16] + 1'b1;
        i_data_val_reg <= 1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        i_weight_reg <= 0;
        i_weight_val_reg <= 0;
    end
    else if (o_data_req) begin
        i_weight_reg <= i_weight_reg + 1'b1;
        i_weight_val_reg <= 1;
    end
end

endmodule
