`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 05/04/2021 04:43:40 PM
// Design Name: Partial sum accumulator controller
// Module Name: psum_accum_ctrl
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: A FIFO controller that can read/write/update mem in sequence
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module psum_accum_ctrl(
    clk,
    rst,
    psum_kn0_dat,
    psum_kn0_vld,
    psum_kn1_dat,
    psum_kn1_vld,
    psum_kn2_dat,
    psum_kn2_vld,
    psum_kn3_dat,
    psum_kn3_vld,
    psum_knx_end,
    
    memctrl0_wadd,
    memctrl0_wren,
    memctrl0_idat,
    memctrl0_radd,
    memctrl0_rden,
    memctrl0_odat,
    memctrl0_oval,

    // memctrl1_wadd,
    // memctrl1_wren,
    // memctrl1_idat,
    // memctrl1_radd,
    // memctrl1_rden,
    // memctrl1_odat,
    // memctrl1_oval,

    // memctrl2_wadd,
    // memctrl2_wren,
    // memctrl2_idat,
    // memctrl2_radd,
    // memctrl2_rden,
    // memctrl2_odat,
    // memctrl2_oval,

    // memctrl3_wadd,
    // memctrl3_wren,
    // memctrl3_idat,
    // memctrl3_radd,
    // memctrl3_rden,
    // memctrl3_odat,
    // memctrl3_oval
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter BIT_WIDTH     = 8;
parameter REG_WIDTH     = 32;

parameter DATA_WIDTH    = 32;
parameter ADDR_WIDTH    = 32;
parameter MEM_DELAY     = 1;

parameter NUM_KERNEL    = 4;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                       clk;
input                       rst;
input   [BIT_WIDTH - 1 : 0] psum_kn0_dat;
input   [BIT_WIDTH - 1 : 0] psum_kn1_dat;
input   [BIT_WIDTH - 1 : 0] psum_kn2_dat;
input   [BIT_WIDTH - 1 : 0] psum_kn3_dat;
input                       psum_kn0_vld;
input                       psum_kn1_vld;
input                       psum_kn2_vld;
input                       psum_kn3_vld;
input                       psum_knx_end;

output [ADDR_WIDTH - 1 : 0] memctrl0_wadd;
output                      memctrl0_wren;
output [DATA_WIDTH - 1 : 0] memctrl0_idat;
output [ADDR_WIDTH - 1 : 0] memctrl0_radd;
output                      memctrl0_rden;
input  [DATA_WIDTH - 1 : 0] memctrl0_odat;
input                       memctrl0_oval;

// output [ADDR_WIDTH - 1 : 0] memctrl1_wadd;
// output                      memctrl1_wren;
// output [DATA_WIDTH - 1 : 0] memctrl1_idat;
// output [ADDR_WIDTH - 1 : 0] memctrl1_radd;
// output                      memctrl1_rden;
// input  [DATA_WIDTH - 1 : 0] memctrl1_odat;
// input                       memctrl1_oval;

// output [ADDR_WIDTH - 1 : 0] memctrl2_wadd;
// output                      memctrl2_wren;
// output [DATA_WIDTH - 1 : 0] memctrl2_idat;
// output [ADDR_WIDTH - 1 : 0] memctrl2_radd;
// output                      memctrl2_rden;
// input  [DATA_WIDTH - 1 : 0] memctrl2_odat;
// input                       memctrl2_oval;

// output [ADDR_WIDTH - 1 : 0] memctrl3_wadd;
// output                      memctrl3_wren;
// output [DATA_WIDTH - 1 : 0] memctrl3_idat;
// output [ADDR_WIDTH - 1 : 0] memctrl3_radd;
// output                      memctrl3_rden;
// input  [DATA_WIDTH - 1 : 0] memctrl3_odat;
// input                       memctrl3_oval;


////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [ADDR_WIDTH - 1 : 0] rd_addr;
reg [ADDR_WIDTH - 1 : 0] wr_addr;
reg                      wr_enab;
reg [ADDR_WIDTH - 1 : 0] addr_cache;
reg  [BIT_WIDTH - 1 : 0] psum_cache [NUM_KERNEL - 1 : 0];
reg  [BIT_WIDTH - 1 : 0] wdat_cache [NUM_KERNEL - 1 : 0];

always @(posedge clk) begin
    if (rst | psum_knx_end) begin
        rd_addr <= 0;
    end
    else if (psum_kn0_vld) begin
        rd_addr <= rd_addr + 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        wr_addr <= 0;
        addr_cache <= 0;
    end
    else begin
        addr_cache <= rd_addr;
        wr_addr <= addr_cache;
    end
end

assign memctrl0_rden = psum_kn0_vld;

assign memctrl0_radd = rd_addr;
// assign memctrl1_radd = rd_addr;
// assign memctrl2_radd = rd_addr;
// assign memctrl3_radd = rd_addr;

assign memctrl0_wadd = wr_addr;
// assign memctrl1_radd = wr_addr;
// assign memctrl2_radd = wr_addr;
// assign memctrl3_radd = wr_addr;

always @(posedge clk) begin
    if (rst) begin
        psum_cache[0] <= 0;
        psum_cache[1] <= 0;
        psum_cache[2] <= 0;
        psum_cache[3] <= 0;
    end
    else if (memctrl0_oval) begin
        psum_cache[0] <= psum_kn0_dat;
        psum_cache[1] <= psum_kn1_dat;
        psum_cache[2] <= psum_kn2_dat;
        psum_cache[3] <= psum_kn3_dat;
    end
end

always @(posedge clk) begin
    if (rst) begin
        wdat_cache[0] <= 0;
        wdat_cache[1] <= 0;
        wdat_cache[2] <= 0;
        wdat_cache[3] <= 0;
    end
    else if (memctrl0_oval) begin
        wdat_cache[0] <= memctrl0_odat[BIT_WIDTH * 1 - 1 : 0] + psum_cache[0];
        wdat_cache[1] <= memctrl0_odat[BIT_WIDTH * 2 - 1 : BIT_WIDTH * 1] + psum_cache[1];
        wdat_cache[2] <= memctrl0_odat[BIT_WIDTH * 3 - 1 : BIT_WIDTH * 2] + psum_cache[2];
        wdat_cache[3] <= memctrl0_odat[BIT_WIDTH * 4 - 1 : BIT_WIDTH * 3] + psum_cache[3];
    end
end

always @(posedge clk) begin
    wr_enab <= memctrl0_oval;
end

assign memctrl0_idat = {wdat_cache[3], wdat_cache[2], wdat_cache[1], wdat_cache[0]};
// assign memctrl1_idat = wdat_cache[1];
// assign memctrl2_idat = wdat_cache[2];
// assign memctrl3_idat = wdat_cache[3];

assign memctrl0_wren = wr_enab;
// assign memctrl1_wren = wr_enab;
// assign memctrl2_wren = wr_enab;
// assign memctrl3_wren = wr_enab;

endmodule
