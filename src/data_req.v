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

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                       clk;
input                       rst;
input                       i_req;
input                       i_stall;
input                       i_end;
output [ADDR_WIDTH - 1 : 0] o_addr;
output                      o_rden;
input   [REG_WIDTH - 1 : 0] i_conf_inputshape;
input   [REG_WIDTH - 1 : 0] i_conf_kernelshape;
output  [REG_WIDTH - 1 : 0] dbg_datareq_knlinex_cnt;
output  [REG_WIDTH - 1 : 0] dbg_datareq_addr_reg;
////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg        [ADDR_WIDTH - 1 : 0] addr_reg;
reg [KERNEL_SIZE_WIDTH - 1 : 0] knlinex_cnt;
wire                            knlinex_cnt_max_vld;
reg        [ADDR_WIDTH - 1 : 0] base_addr_1;
reg        [ADDR_WIDTH - 1 : 0] base_addr_2;

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
    base_addr_1 <= (((i_conf_inputshape[7:0] << 1) + i_conf_inputshape[7:0]) >> 2) - 1'b1;
    base_addr_2 <= ((((i_conf_inputshape[7:0] << 1) << 1) + (i_conf_inputshape[7:0] << 1)) >> 2) - 1'b1;
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
        addr_reg <= addr_reg + 1'b1;
    end
end

assign o_rden = i_req & ~i_stall;
assign o_addr = addr_reg;

// Debug
assign dbg_datareq_knlinex_cnt = knlinex_cnt;
assign dbg_datareq_addr_reg = addr_reg;

endmodule
