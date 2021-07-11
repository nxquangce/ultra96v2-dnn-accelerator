`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 07/04/2021 10:56:03 PM
// Design Name: Sticky register
// Module Name: sticky_reg
// Project Name: lib
// Target Devices: any
// Tool Versions: any
// Description: register to catch a status, error, ...
//      write 1 to clear
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sticky_reg(
    clk,
    rst,
    idat,
    ienb,
    ps_addr,
    ps_wren,
    ps_wdat,
    ps_rden,
    ps_rdat,
    ps_rvld
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter DATA_WIDTH    = 32;
parameter ADDR_WIDTH    = 32;

parameter RST_MODE      = 1'b1;
parameter REG_ADDR      = 32'h00000000;
parameter CLR_CODE      = 32'h00000001;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                       clk;
input                       rst;
input  [DATA_WIDTH - 1 : 0] idat;
input                       ienb;
input  [ADDR_WIDTH - 1 : 0] ps_addr;
input                       ps_wren;
input  [DATA_WIDTH - 1 : 0] ps_wdat;
input                       ps_rden;
output [DATA_WIDTH - 1 : 0] ps_rdat;
output                      ps_rvld;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [DATA_WIDTH - 1 : 0] sticky;
reg                      block;

wire wren;
wire rden;
wire clear;

assign wren = ienb & ~block;
assign rden = ps_rden & (ps_addr == REG_ADDR);
assign clear = ~(rst ^ RST_MODE) | (ps_wren & (ps_wdat == CLR_CODE));

always @(posedge clk) begin
    if (clear) begin
        sticky <= 0;
    end
    else if (wren) begin
        sticky <= idat;
    end
end

always @(posedge clk) begin
    if (clear) begin
        block <= 1'b0;
    end
    else if (wren) begin
        block <= 1'b1;
    end
end

assign ps_rdat = (rden) ? sticky : 0;
assign ps_rvld = rden;

endmodule
