`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 07/05/2021 02:59:31 PM
// Design Name: Status registers PS interface
// Module Name: statusx_psif
// Project Name: lib
// Target Devices: any
// Tool Versions: any
// Description: allow PS access registers via 1 interface
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module statusx_psif(
    idat,
    ps_addr,
    ps_rden,
    ps_rdat,
    ps_rvld
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter DATA_WIDTH        = 32;
parameter ADDR_WIDTH        = 32;
parameter BASE_ADDR         = 32'h00000000;
parameter ADDR_RANGE_WIDTH  = 4;
parameter NUM_REGS          = 1;
parameter NO_REG_CODE       = 32'hcafecafe;

localparam IDAT_WIDTH       = DATA_WIDTH * NUM_REGS;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input  [IDAT_WIDTH - 1 : 0] idat;
input  [ADDR_WIDTH - 1 : 0] ps_addr;
input                       ps_rden;
output [DATA_WIDTH - 1 : 0] ps_rdat;
output                      ps_rvld;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg  [DATA_WIDTH - 1 : 0] odat;
wire [ADDR_WIDTH - 1 : 0] local_addr;
wire                      addr_valid;
wire                      addr_noreg;
wire                      rden;
wire [DATA_WIDTH - 1 : 0] data [NUM_REGS - 1 : 0];

genvar i;
generate
    for (i = 0; i < NUM_REGS; i = i + 1) begin
        assign data[i] = idat[DATA_WIDTH * (i + 1) - 1 : DATA_WIDTH * i];
    end
endgenerate

assign local_addr = ps_addr - BASE_ADDR;
assign addr_valid = (ps_addr[ADDR_WIDTH - 1 : ADDR_RANGE_WIDTH] == BASE_ADDR[ADDR_WIDTH - 1 : ADDR_RANGE_WIDTH]);
assign addr_noreg = (local_addr < NUM_REGS);
assign rden       = ps_rden & addr_valid;

always @(*) begin
    odat = (addr_noreg) ? data[local_addr] : NO_REG_CODE;
end

assign ps_rdat = (rden) ? odat : 0;
assign ps_rvld = rden;

endmodule
