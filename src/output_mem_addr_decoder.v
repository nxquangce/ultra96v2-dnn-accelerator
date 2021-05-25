`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 05/25/2021 05:15:42 PM
// Design Name: Output memory address decoder
// Module Name: output_mem_addr_decoder
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module output_mem_addr_decoder(
    clk,

    psumctrl_wadd,
    psumctrl_wren,
    psumctrl_radd,
    psumctrl_rden,
    psumctrl_odat,
    psumctrl_ovld,

    bramctrl_addr_rd_0,
    bramctrl_rden_rd_0,
    bramctrl_odat_rd_0,
    bramctrl_oval_rd_0,
    bramctrl_addr_wr_0,
    bramctrl_wren_wr_0,

    bramctrl_addr_rd_1,
    bramctrl_rden_rd_1,
    bramctrl_odat_rd_1,
    bramctrl_oval_rd_1,
    bramctrl_addr_wr_1,
    bramctrl_wren_wr_1,

    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter ADDR_WIDTH        = 32;
parameter DATA_WIDTH        = 32;
parameter NUM_BYTE          = 4;

parameter NUM_MEM           = 2;
parameter MEM_DEPTH         = 32768;
parameter MEM_ADDR_WIDTH    = 16;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                       clk;

input  [ADDR_WIDTH - 1 : 0] psumctrl_wadd;
input                       psumctrl_wren;
input  [ADDR_WIDTH - 1 : 0] psumctrl_radd;
input                       psumctrl_rden;
output [DATA_WIDTH - 1 : 0] psumctrl_odat;
output                      psumctrl_ovld;

output [ADDR_WIDTH - 1 : 0] bramctrl_addr_rd_0;
output                      bramctrl_rden_rd_0;
input  [DATA_WIDTH - 1 : 0] bramctrl_odat_rd_0;
input                       bramctrl_oval_rd_0;
output [ADDR_WIDTH - 1 : 0] bramctrl_addr_wr_0;
output                      bramctrl_wren_wr_0;

output [ADDR_WIDTH - 1 : 0] bramctrl_addr_rd_1;
output                      bramctrl_rden_rd_1;
input  [DATA_WIDTH - 1 : 0] bramctrl_odat_rd_1;
input                       bramctrl_oval_rd_1;
output [ADDR_WIDTH - 1 : 0] bramctrl_addr_wr_1;
output                      bramctrl_wren_wr_1;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [DATA_WIDTH - 1 : 0] psumctrl_odat;
reg                      psumctrl_ovld;
reg [ADDR_WIDTH - 1 : 0] bramctrl_addr_rd_0;
reg                      bramctrl_rden_rd_0;
reg [ADDR_WIDTH - 1 : 0] bramctrl_addr_wr_0;
reg                      bramctrl_wren_wr_0;
reg [ADDR_WIDTH - 1 : 0] bramctrl_addr_rd_1;
reg                      bramctrl_rden_rd_1;
reg [ADDR_WIDTH - 1 : 0] bramctrl_addr_wr_1;
reg                      bramctrl_wren_wr_1;

reg                      cache_sel;

always @(posedge clk) begin
    cache_sel <= psumctrl_radd[MEM_ADDR_WIDTH - 1];
end

always @(*) begin
    if (psumctrl_radd[MEM_ADDR_WIDTH - 1]) begin
        bramctrl_addr_rd_0 = 0;
        bramctrl_rden_rd_0 = 0;
        bramctrl_addr_rd_1 = {{(ADDR_WIDTH - MEM_ADDR_WIDTH + 1){1'b0}}, psumctrl_radd[MEM_ADDR_WIDTH - 2 : 0]};
        bramctrl_rden_rd_1 = psumctrl_rden;
    end
    else begin
        bramctrl_addr_rd_0 = {{(ADDR_WIDTH - MEM_ADDR_WIDTH + 1){1'b0}}, psumctrl_radd[MEM_ADDR_WIDTH - 2 : 0]};
        bramctrl_rden_rd_0 = psumctrl_rden;
        bramctrl_addr_rd_1 = 0;
        bramctrl_rden_rd_1 = 0;
    end
end

always @(*) begin
    psumctrl_odat = (cache_sel) ? bramctrl_odat_rd_1 : bramctrl_odat_rd_0;
    psumctrl_ovld = bramctrl_oval_rd_0 | bramctrl_oval_rd_1;
end

always @(*) begin
    if (psumctrl_wadd[MEM_ADDR_WIDTH - 1]) begin
        bramctrl_addr_wr_0 = 0;
        bramctrl_wren_wr_0 = 0;
        bramctrl_addr_wr_1 = {{(ADDR_WIDTH - MEM_ADDR_WIDTH + 1){1'b0}}, psumctrl_wadd[MEM_ADDR_WIDTH - 2 : 0]};
        bramctrl_wren_wr_1 = psumctrl_wren;
    end
    else begin
        bramctrl_addr_wr_0 = {{(ADDR_WIDTH - MEM_ADDR_WIDTH + 1){1'b0}}, psumctrl_wadd[MEM_ADDR_WIDTH - 2 : 0]};
        bramctrl_wren_wr_0 = psumctrl_wren;
        bramctrl_addr_wr_1 = 0;
        bramctrl_wren_wr_1 = 0;
    end
end

endmodule
