`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 03/24/2021 10:29:39 AM
// Design Name: Psum Accumulator
// Module Name: psum_accumulator
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: Temporal memory to store psums and accumulate them
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module psum_accumulator(
    clk,
    rst,
    i_conf_knx,
    i_conf_cnt,
    i_psum_kn0,
    i_psum_kn0_val,
    i_psum_kn1,
    i_psum_kn1_val,
    i_psum_kn2,
    i_psum_kn2_val,
    i_psum_kn3,
    i_psum_kn3_val,
    o_psum_kn0,
    o_psum_kn0_val,
    o_psum_kn1,
    o_psum_kn1_val,
    o_psum_kn2,
    o_psum_kn2_val,
    o_psum_kn3,
    o_psum_kn3_val
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter BIT_WIDTH     = 8;
parameter NUM_CHANNEL   = 3;
parameter NUM_KERNEL    = 4;
parameter REG_WIDTH     = 32;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input  wire                     clk;
input  wire                     rst;
input  wire [REG_WIDTH - 1 : 0] i_conf_knx;
input  wire [REG_WIDTH - 1 : 0] i_conf_cnt;
input  wire [BIT_WIDTH - 1 : 0] i_psum_kn0;
input  wire [BIT_WIDTH - 1 : 0] i_psum_kn1;
input  wire [BIT_WIDTH - 1 : 0] i_psum_kn2;
input  wire [BIT_WIDTH - 1 : 0] i_psum_kn3;
input  wire                     i_psum_kn0_val;
input  wire                     i_psum_kn1_val;
input  wire                     i_psum_kn2_val;
input  wire                     i_psum_kn3_val;
output wire [BIT_WIDTH - 1 : 0] o_psum_kn0;
output wire [BIT_WIDTH - 1 : 0] o_psum_kn1;
output wire [BIT_WIDTH - 1 : 0] o_psum_kn2;
output wire [BIT_WIDTH - 1 : 0] o_psum_kn3;
output wire                     o_psum_kn0_val;
output wire                     o_psum_kn1_val;
output wire                     o_psum_kn2_val;
output wire                     o_psum_kn3_val;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [BIT_WIDTH - 1 : 0] accum_reg [NUM_KERNEL - 1 : 0];
reg [BIT_WIDTH - 1 : 0] accum_cnt_reg [NUM_KERNEL - 1 : 0];

wire [BIT_WIDTH - 1 : 0] accum_perkn_conf_cnt [NUM_KERNEL - 1 : 0];

wire [NUM_KERNEL - 1 : 0] accum_perkn_conf_knx [NUM_KERNEL - 1 : 0];
wire [NUM_KERNEL - 1 : 0] accum_perkn_enb [NUM_KERNEL - 1 : 0];
wire [2 : 0] accum_perkn_cnt [NUM_KERNEL - 1 : 0];

assign accum_perkn_conf_knx[0] = i_conf_knx[7 : 0];
assign accum_perkn_conf_knx[1] = i_conf_knx[15 : 8];
assign accum_perkn_conf_knx[2] = i_conf_knx[23 : 16];
assign accum_perkn_conf_knx[3] = i_conf_knx[31 : 24];

assign accum_perkn_conf_cnt[0] = i_conf_cnt[7 : 0];
assign accum_perkn_conf_cnt[1] = i_conf_cnt[15 : 8];
assign accum_perkn_conf_cnt[2] = i_conf_cnt[23 : 16];
assign accum_perkn_conf_cnt[3] = i_conf_cnt[31 : 24];

genvar idxK;
generate
    for (idxK = 0; idxK < NUM_KERNEL; idxK = idxK + 1) begin
        assign accum_perkn_enb[0][idxK] = accum_perkn_conf_knx[0][idxK] & i_psum_kn0_val;
        assign accum_perkn_enb[1][idxK] = accum_perkn_conf_knx[1][idxK] & i_psum_kn1_val;
        assign accum_perkn_enb[2][idxK] = accum_perkn_conf_knx[2][idxK] & i_psum_kn2_val;
        assign accum_perkn_enb[3][idxK] = accum_perkn_conf_knx[3][idxK] & i_psum_kn3_val;

        assign accum_perkn_cnt[idxK] = accum_perkn_enb[idxK][0] + accum_perkn_enb[idxK][1] + accum_perkn_enb[idxK][2] + accum_perkn_enb[idxK][3];
    end
endgenerate

always @(posedge clk) begin
    if (rst) begin
        accum_cnt_reg[0] <= 0;
        accum_cnt_reg[1] <= 0;
        accum_cnt_reg[2] <= 0;
        accum_cnt_reg[3] <= 0;
    end
    else begin
        accum_cnt_reg[0] <= (o_psum_kn0_val) ? accum_cnt_reg[0] + accum_perkn_cnt[0] : 0;   // WARNING: is 0 correct?
        accum_cnt_reg[1] <= (o_psum_kn1_val) ? accum_cnt_reg[1] + accum_perkn_cnt[1] : 0;
        accum_cnt_reg[2] <= (o_psum_kn2_val) ? accum_cnt_reg[2] + accum_perkn_cnt[2] : 0;
        accum_cnt_reg[3] <= (o_psum_kn3_val) ? accum_cnt_reg[3] + accum_perkn_cnt[3] : 0;
    end
end

always @(posedge clk) begin
    if (rst) begin
        accum_reg[0] <= 0;
        accum_reg[1] <= 0;
        accum_reg[2] <= 0;
        accum_reg[3] <= 0;
    end
    else begin
        accum_reg[0] <= accum_reg[0] + (i_psum_kn0 & {BIT_WIDTH{accum_perkn_enb[0][0]}}) 
                                     + (i_psum_kn1 & {BIT_WIDTH{accum_perkn_enb[1][0]}})
                                     + (i_psum_kn2 & {BIT_WIDTH{accum_perkn_enb[2][0]}})
                                     + (i_psum_kn3 & {BIT_WIDTH{accum_perkn_enb[3][0]}});

        accum_reg[1] <= accum_reg[1] + (i_psum_kn0 & {BIT_WIDTH{accum_perkn_enb[0][1]}}) 
                                     + (i_psum_kn1 & {BIT_WIDTH{accum_perkn_enb[1][1]}})
                                     + (i_psum_kn2 & {BIT_WIDTH{accum_perkn_enb[2][1]}})
                                     + (i_psum_kn3 & {BIT_WIDTH{accum_perkn_enb[3][1]}});

        accum_reg[2] <= accum_reg[2] + (i_psum_kn0 & {BIT_WIDTH{accum_perkn_enb[0][2]}}) 
                                     + (i_psum_kn1 & {BIT_WIDTH{accum_perkn_enb[1][2]}})
                                     + (i_psum_kn2 & {BIT_WIDTH{accum_perkn_enb[2][2]}})
                                     + (i_psum_kn3 & {BIT_WIDTH{accum_perkn_enb[3][2]}});

        accum_reg[3] <= accum_reg[3] + (i_psum_kn0 & {BIT_WIDTH{accum_perkn_enb[0][3]}}) 
                                     + (i_psum_kn1 & {BIT_WIDTH{accum_perkn_enb[1][3]}})
                                     + (i_psum_kn2 & {BIT_WIDTH{accum_perkn_enb[2][3]}})
                                     + (i_psum_kn3 & {BIT_WIDTH{accum_perkn_enb[3][3]}});   
    end
end

// Output
assign o_psum_kn0 = accum_reg[0];
assign o_psum_kn1 = accum_reg[1];
assign o_psum_kn2 = accum_reg[2];
assign o_psum_kn3 = accum_reg[3];

// Output valid
assign o_psum_kn0_val = (accum_cnt_reg[0] != accum_perkn_conf_cnt[0]);
assign o_psum_kn1_val = (accum_cnt_reg[1] != accum_perkn_conf_cnt[1]);
assign o_psum_kn2_val = (accum_cnt_reg[2] != accum_perkn_conf_cnt[2]);
assign o_psum_kn3_val = (accum_cnt_reg[3] != accum_perkn_conf_cnt[3]);

endmodule
