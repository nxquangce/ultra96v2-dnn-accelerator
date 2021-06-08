`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 05/05/2021 02:52:26 PM
// Design Name: Psum BRAM for simulation
// Module Name: psum_bram_tb_sim
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: Psum BRAM for simulation
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module psum_bram_tb_sim(
    clk,
    rst,
    waddr,
    idat,
    wren,
    raddr,
    odat
    );

parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 32;

parameter MEM_DEPTH  = 400000;

input                       clk;
input                       rst;
input  [ADDR_WIDTH - 1 : 0] waddr;
input  [DATA_WIDTH - 1 : 0] idat;
input                       wren;
input  [ADDR_WIDTH - 1 : 0] raddr;
output [DATA_WIDTH - 1 : 0] odat;

reg [DATA_WIDTH - 1 : 0] data_reg [MEM_DEPTH - 1 : 0];
reg [DATA_WIDTH - 1 : 0] rdat_reg;

integer i;

always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i <= MEM_DEPTH; i = i + 1) begin
            data_reg[i] <= 0;
        end
    end
    else if (wren) begin
        data_reg[waddr] <= idat;
    end
end

always @(posedge clk) begin
    if (rst) begin
        rdat_reg <= 0;
    end
    else begin
        rdat_reg <= data_reg[raddr];
    end
end

assign odat = rdat_reg;

endmodule
