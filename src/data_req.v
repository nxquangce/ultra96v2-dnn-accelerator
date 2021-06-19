`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 04/30/2021 10:40:59 PM
// Design Name: Data request
// Module Name: data_req
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: Generate read request signals to data block ram
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module data_req(
    clk,
    rst,
    i_req,
    i_stall,
    i_end,
    o_addr,
    o_rden,
    i_cnfx_stride,
    i_conf_inputshape,
    i_conf_kernelshape,
    dbg_datareq_knlinex_cnt,
    dbg_datareq_addr_reg,
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter ADDR_WIDTH        = 32;
parameter KERNEL_SIZE_WIDTH = 2;
parameter REG_WIDTH         = 32;

parameter STRIDE_WIDTH      = 4;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                          clk;
input                          rst;
input                          i_req;
input                          i_stall;
input                          i_end;
output    [ADDR_WIDTH - 1 : 0] o_addr;
output                         o_rden;
input   [STRIDE_WIDTH - 1 : 0] i_cnfx_stride;
input      [REG_WIDTH - 1 : 0] i_conf_inputshape;
input      [REG_WIDTH - 1 : 0] i_conf_kernelshape;
output     [REG_WIDTH - 1 : 0] dbg_datareq_knlinex_cnt;
output     [REG_WIDTH - 1 : 0] dbg_datareq_addr_reg;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg        [ADDR_WIDTH - 1 : 0] addr_reg;
reg [KERNEL_SIZE_WIDTH - 1 : 0] knlinex_cnt;
wire                            knlinex_cnt_max_vld;
reg        [ADDR_WIDTH - 1 : 0] base_addr_1;
reg        [ADDR_WIDTH - 1 : 0] base_addr_2;

reg                             i_stall_cache;
wire                            stall_cache_vld;

reg        [ADDR_WIDTH - 1 : 0] stride_range;
wire       [ADDR_WIDTH - 1 : 0] stride_base_addr;
wire                            row_end_vld;
reg         [REG_WIDTH - 1 : 0] row_req_cnt;

assign row_end_vld = row_req_cnt == i_conf_inputshape[7:0];

always @(posedge clk) begin
    if (rst) begin
        row_req_cnt <= 0;
    end
    else if (i_req) begin
        row_req_cnt <= (row_end_vld) ? 0 : row_req_cnt + 1'b1;
    end
end

always @(posedge clk) begin
    case (i_cnfx_stride)
        4'd1: stride_range <= i_conf_inputshape[7:0];
        4'd2: stride_range <= i_conf_inputshape[7:0] << 1;
        4'd3: stride_range <= i_conf_inputshape[7:0] << 1 + i_conf_inputshape[7:0];
        4'd4: stride_range <= i_conf_inputshape[7:0] << 2;
        default: stride_range <= 0;
    endcase
end

assign stride_base_addr = (stride_range << 1 + stride_range) >> 2;

assign stall_cache_vld = i_stall & (~i_req);

always @(posedge clk) begin
    if (rst | i_req) begin
        i_stall_cache <= 0;
    end
    else if (stall_cache_vld) begin
        i_stall_cache <= 1'b1;
    end
end

assign knlinex_cnt_max_vld = (knlinex_cnt == (i_conf_kernelshape[KERNEL_SIZE_WIDTH - 1 : 0] - 1'b1));

always @(posedge clk) begin
    if (rst) begin
        knlinex_cnt <= 0;
    end
    else if (i_end) begin
        knlinex_cnt <= (knlinex_cnt_max_vld) ? 0 : knlinex_cnt + 1'b1;
    end
end

always @(posedge clk) begin
    base_addr_1 <= (((i_conf_inputshape[7:0] << 1) + i_conf_inputshape[7:0]) >> 2);
    base_addr_2 <= ((((i_conf_inputshape[7:0] << 1) << 1) + (i_conf_inputshape[7:0] << 1)) >> 2);
end

always @(posedge clk) begin
    if (rst) begin
        addr_reg <= 0;
    end
    else if (i_end) begin
        case (knlinex_cnt)
            2'b00: addr_reg <= base_addr_1;
            2'b01: addr_reg <= base_addr_2;
            default: addr_reg <= 0;
        endcase
    end
    else if (o_rden) begin
        addr_reg <= (row_end_vld) ? addr_reg + stride_base_addr + 1'b1 : addr_reg + 1'b1;
    end
end

assign o_rden = i_req & ~i_stall & ~i_stall_cache;
assign o_addr = addr_reg;

// Debug
assign dbg_datareq_knlinex_cnt = knlinex_cnt;
assign dbg_datareq_addr_reg = addr_reg;

endmodule
