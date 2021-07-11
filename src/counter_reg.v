`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 07/05/2021 12:44:48 AM
// Design Name: Counter status register
// Module Name: counter_reg
// Project Name: lib
// Target Devices: any
// Tool Versions: any
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module counter_reg(
    clk,
    rst,
    ienb,
    imax,
    ostatus,
    ps_addr,
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
input                       ienb;
input  [DATA_WIDTH - 1 : 0] imax;
output [DATA_WIDTH - 1 : 0] ostatus;
input  [ADDR_WIDTH - 1 : 0] ps_addr;
input                       ps_rden;
output [DATA_WIDTH - 1 : 0] ps_rdat;
output                      ps_rvld;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [DATA_WIDTH - 1 : 0] counter;
wire                     rden;
wire                     max_vld;

assign max_vld = (counter == imax);

always @(posedge clk) begin
    if (rst) begin
        counter <= 0;
    end
    else if (ienb) begin
        counter <= (max_vld) ? 0 : counter + 1'b1;
    end
end

assign rden = ps_rden & (ps_addr == REG_ADDR);

assign ostatus = counter;

assign ps_rdat = (rden) ? counter : 0;
assign ps_rvld = rden;


endmodule
