`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 03/23/2021 03:21:33 PM
// Design Name: Result Router of Psum
// Module Name: result_router
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: Determine operations that a psum belongs to,
// then calculate the sum of psum in each operation.
// Forward the results to the right acummulator address.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module result_router(
    clk,
    rst,
    i_psum_kcpe0,
    i_psum_kcpe0_vld,
    i_psum_kcpe1,
    i_psum_kcpe1_vld,
    i_psum_kcpe2,
    i_psum_kcpe2_vld,
    o_psum_kn0,
    o_psum_kn0_vld,
    o_psum_kn1,
    o_psum_kn1_vld,
    o_psum_kn2,
    o_psum_kn2_vld,
    o_psum_kn3,
    o_psum_kn3_vld
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter BIT_WIDTH     = 8;
parameter NUM_KCPE      = 3;
parameter NUM_KERNEL    = 4;
parameter NUM_CHANNEL   = 3;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input  wire                                      clk;
input  wire                                      rst;
input  wire [BIT_WIDTH * 2 * NUM_KERNEL - 1 : 0] i_psum_kcpe0;
input  wire [BIT_WIDTH * 2 * NUM_KERNEL - 1 : 0] i_psum_kcpe1;
input  wire [BIT_WIDTH * 2 * NUM_KERNEL - 1 : 0] i_psum_kcpe2;
input  wire                                      i_psum_kcpe0_vld;
input  wire                                      i_psum_kcpe1_vld;
input  wire                                      i_psum_kcpe2_vld;
output wire [BIT_WIDTH * 2 - 1 : 0]              o_psum_kn0;
output wire [BIT_WIDTH * 2 - 1 : 0]              o_psum_kn1;
output wire [BIT_WIDTH * 2 - 1 : 0]              o_psum_kn2;
output wire [BIT_WIDTH * 2 - 1 : 0]              o_psum_kn3;
output wire                                      o_psum_kn0_vld;
output wire                                      o_psum_kn1_vld;
output wire                                      o_psum_kn2_vld;
output wire                                      o_psum_kn3_vld;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire [BIT_WIDTH * 2 - 1 : 0] i_psum_kcpe [NUM_KCPE - 1 : 0][NUM_KERNEL - 1 : 0];

reg [BIT_WIDTH * 2 - 1 : 0] psum_kn0_reg;
reg [BIT_WIDTH * 2 - 1 : 0] psum_kn1_reg;
reg [BIT_WIDTH * 2 - 1 : 0] psum_kn2_reg;
reg [BIT_WIDTH * 2 - 1 : 0] psum_kn3_reg;

reg                     psum_kcpe0_vld_reg;
reg                     psum_kcpe1_vld_reg;
reg                     psum_kcpe2_vld_reg;

genvar idxKn;
generate
    for (idxKn = 0; idxKn < NUM_KERNEL; idxKn = idxKn + 1) begin
        assign i_psum_kcpe[0][idxKn] = i_psum_kcpe0[BIT_WIDTH * 2 * (idxKn + 1) - 1 : BIT_WIDTH * 2 * idxKn];
        assign i_psum_kcpe[1][idxKn] = i_psum_kcpe1[BIT_WIDTH * 2 * (idxKn + 1) - 1 : BIT_WIDTH * 2 * idxKn];
        assign i_psum_kcpe[2][idxKn] = i_psum_kcpe2[BIT_WIDTH * 2 * (idxKn + 1) - 1 : BIT_WIDTH * 2 * idxKn];
    end
endgenerate

always @(posedge clk) begin
    if (rst) begin
        psum_kn0_reg <= 0;
        psum_kn1_reg <= 0;
        psum_kn2_reg <= 0;
        psum_kn3_reg <= 0;
    end
    else begin
        psum_kn0_reg <= i_psum_kcpe[0][0] + i_psum_kcpe[1][0] + i_psum_kcpe[2][0];
        psum_kn1_reg <= i_psum_kcpe[0][1] + i_psum_kcpe[1][1] + i_psum_kcpe[2][1];
        psum_kn2_reg <= i_psum_kcpe[0][2] + i_psum_kcpe[1][2] + i_psum_kcpe[2][2];
        psum_kn3_reg <= i_psum_kcpe[0][3] + i_psum_kcpe[1][3] + i_psum_kcpe[2][3];
    end
end

always @(posedge clk) begin
    if (rst) begin
        psum_kcpe0_vld_reg <= 0;
        psum_kcpe1_vld_reg <= 0;
        psum_kcpe2_vld_reg <= 0;
    end
    else begin
        psum_kcpe0_vld_reg <= i_psum_kcpe0_vld;
        psum_kcpe1_vld_reg <= i_psum_kcpe1_vld;
        psum_kcpe2_vld_reg <= i_psum_kcpe2_vld;
    end
end

// Output psum data
assign o_psum_kn0 = psum_kn0_reg;
assign o_psum_kn1 = psum_kn1_reg;
assign o_psum_kn2 = psum_kn2_reg;
assign o_psum_kn3 = psum_kn3_reg;

// Output psum valid
wire o_psum_kn_vld;
assign o_psum_kn_vld  = psum_kcpe0_vld_reg & psum_kcpe1_vld_reg & psum_kcpe2_vld_reg;
assign o_psum_kn0_vld = o_psum_kn_vld;
assign o_psum_kn1_vld = o_psum_kn_vld;
assign o_psum_kn2_vld = o_psum_kn_vld;
assign o_psum_kn3_vld = o_psum_kn_vld;


endmodule
