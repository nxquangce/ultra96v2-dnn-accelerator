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
    o_rden
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter ADDR_WIDTH = 32;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                       clk;
input                       rst;
input                       i_req;
input                       i_stall;
input                       i_end;
output [ADDR_WIDTH - 1 : 0] o_addr;
output                      o_rden;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [ADDR_WIDTH - 1 : 0] addr_reg;

always @(posedge clk) begin
    if (rst | i_end) begin
        addr_reg <= 0;
    end
    else if (o_rden) begin
        addr_reg <= addr_reg + 1'b1;
    end
end

assign o_rden = i_req & ~i_stall;
assign o_addr = addr_reg;

endmodule
