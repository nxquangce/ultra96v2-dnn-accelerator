`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 04/21/2021 05:34:36 PM
// Design Name: BRAM controller
// Module Name: bram_ctrl
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: BRAM controller
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module bram_ctrl(
    clk,
    rst,
    addr,
    wren,
    idat,
    rden,
    odat,
    oval,
    mem_addr,
    mem_idat,
    mem_odat,
    mem_enb,
    mem_rst,
    mem_wen
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter DAT_WIDTH     = 32;
parameter ADDR_WIDTH    = 32;

localparam NUM_BYTE     = 4;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
// User side
input                      clk;
input                      rst;
input [ADDR_WIDTH - 1 : 0] addr;
input                      wren;
input [DAT_WIDTH - 1 : 0]  idat;
input                      rden;
output [DAT_WIDTH - 1 : 0] odat;
output                     oval;
// BRAM side
output [ADDR_WIDTH - 1 : 0] mem_addr;
output [DAT_WIDTH - 1 : 0]  mem_idat;
input  [DAT_WIDTH - 1 : 0]  mem_odat;
output                      mem_enb;
output                      mem_rst;
output [NUM_BYTE - 1 : 0]   mem_wen;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [DAT_WIDTH - 1 : 0] odat_reg; 
reg                     odat_val_reg;

assign mem_enb = 1'b1;
assign mem_rst = 1'b0;
assign mem_addr = addr;
assign mem_wen = {4{wren}};
assign oval = odat_val_reg;
assign odat = (oval) ? mem_odat : odat_reg;

always @(posedge clk) begin
    if (rst) begin
        odat_reg <= 0;
    end
    if (oval) begin
        odat_reg <= mem_odat;
    end
end

always @(posedge clk) begin
    odat_val_reg <= rden;
end

endmodule
