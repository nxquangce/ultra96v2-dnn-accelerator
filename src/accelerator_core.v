`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 03/24/2021 02:46:28 PM
// Design Name: DNN Accelerator core wrapper
// Module Name: accelerator_core
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


module accelerator_core(
    clk,
    rst,
    o_data_req,
    o_data_end,
    i_data,
    i_data_val,
    o_weight_req,
    i_weight,
    i_weight_val,
    // o_psum_kn0,
    // o_psum_kn0_val,
    // o_psum_kn1,
    // o_psum_kn1_val,
    // o_psum_kn2,
    // o_psum_kn2_val,
    // o_psum_kn3,
    // o_psum_kn3_val,
    memctrl0_wadd,
    memctrl0_wren,
    memctrl0_idat,
    memctrl0_radd,
    memctrl0_rden,
    memctrl0_odat,
    memctrl0_oval,
    i_conf_ctrl,
    i_conf_outputsize,
    i_conf_kernelsize,
    i_conf_weightinterval,
    i_conf_kernelshape,
    i_conf_inputshape,
    i_conf_inputrstcnt,
    o_conf_status
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter BIT_WIDTH     = 8;
parameter NUM_CHANNEL   = 3;
parameter NUM_KERNEL    = 4;
parameter NUM_KCPE      = 3;    // Number of kernel-channel PE
parameter REG_WIDTH     = 32;

parameter NUM_RDATA     = 3;

parameter ADDR_WIDTH    = 32;
parameter DATA_WIDTH    = 32;

parameter IN_INPUT_DAT_WIDTH  = BIT_WIDTH * NUM_CHANNEL;
parameter IN_WEIGHT_DAT_WIDTH = BIT_WIDTH * NUM_CHANNEL * NUM_KERNEL;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input  wire                               clk;
input  wire                               rst;
output wire                               o_data_req;
output wire                               o_data_end;
output wire                               o_weight_req;
input  wire [IN_INPUT_DAT_WIDTH  - 1 : 0] i_data;
input  wire [IN_WEIGHT_DAT_WIDTH - 1 : 0] i_weight;
input  wire                               i_data_val;
input  wire                               i_weight_val;
// output wire           [BIT_WIDTH - 1 : 0] o_psum_kn0;
// output wire           [BIT_WIDTH - 1 : 0] o_psum_kn1;
// output wire           [BIT_WIDTH - 1 : 0] o_psum_kn2;
// output wire           [BIT_WIDTH - 1 : 0] o_psum_kn3;
// output wire                               o_psum_kn0_val;
// output wire                               o_psum_kn1_val;
// output wire                               o_psum_kn2_val;
// output wire                               o_psum_kn3_val;
output wire          [ADDR_WIDTH - 1 : 0] memctrl0_wadd;
output wire                               memctrl0_wren;
output wire          [DATA_WIDTH - 1 : 0] memctrl0_idat;
output wire          [ADDR_WIDTH - 1 : 0] memctrl0_radd;
output wire                               memctrl0_rden;
input  wire          [DATA_WIDTH - 1 : 0] memctrl0_odat;
input  wire                               memctrl0_oval;
input  wire           [REG_WIDTH - 1 : 0] i_conf_ctrl;
input  wire           [REG_WIDTH - 1 : 0] i_conf_outputsize;
input  wire           [REG_WIDTH - 1 : 0] i_conf_kernelsize;
input  wire           [REG_WIDTH - 1 : 0] i_conf_weightinterval;
input  wire           [REG_WIDTH - 1 : 0] i_conf_kernelshape;
input  wire           [REG_WIDTH - 1 : 0] i_conf_inputshape;
input  wire           [REG_WIDTH - 1 : 0] i_conf_inputrstcnt;
output wire           [REG_WIDTH - 1 : 0] o_conf_status;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire  [BIT_WIDTH - 1 : 0] accum_i_psum [NUM_KERNEL - 1 : 0];
wire [NUM_KERNEL - 1 : 0] accum_i_psum_val;
wire [NUM_KERNEL - 1 : 0] accum_i_psum_end;
// wire [BIT_WIDTH - 1 : 0]                accum_o_psum [NUM_KERNEL - 1 : 0];
// wire [NUM_KERNEL - 1 : 0]               accum_o_psum_val;

// wire [(BIT_WIDTH * NUM_KERNEL) - 1 : 0] engine_i_psum;
// wire                                    engine_i_psum_val;

wire                      rst_soft;
wire                      rst_p;
wire                      kcpe_done;
wire                      psum_done;

assign rst_soft = i_conf_ctrl[1];
assign rst_p = rst | rst_soft;

line_kcpe_conv2d_engine line_kcpe_conv2d_engine_0(
    .clk                    (clk),
    .rst                    (rst_p),
    .o_data_req             (o_data_req),
    .o_data_end             (o_data_end),
    .i_data                 (i_data),
    .i_data_val             (i_data_val),
    .o_weight_req           (o_weight_req),
    .i_weight               (i_weight),
    .i_weight_val           (i_weight_val),
    // .i_psum                 (engine_i_psum),
    // .i_psum_val             (engine_i_psum_val),
    .o_psum_kn0             (accum_i_psum[0]),
    .o_psum_kn0_val         (accum_i_psum_val[0]),
    .o_psum_kn1             (accum_i_psum[1]),
    .o_psum_kn1_val         (accum_i_psum_val[1]),
    .o_psum_kn2             (accum_i_psum[2]),
    .o_psum_kn2_val         (accum_i_psum_val[2]),
    .o_psum_kn3             (accum_i_psum[3]),
    .o_psum_kn3_val         (accum_i_psum_val[3]),
    .o_psum_end             (accum_i_psum_end),
    .i_conf_ctrl            (i_conf_ctrl),
    .i_conf_kernelshape     (i_conf_kernelshape),
    .i_conf_inputshape      (i_conf_inputshape),
    .i_conf_inputrstcnt     (i_conf_inputrstcnt),
    .i_conf_outputsize      (i_conf_outputsize),
    .i_conf_kernelsize      (i_conf_kernelsize),
    .o_done                 (kcpe_done)
    );

psum_accum_ctrl psum_accum_ctrl_0(
    .clk                    (clk),
    .rst                    (rst_p),
    .psum_kn0_dat           (accum_i_psum[0]),
    .psum_kn0_vld           (accum_i_psum_val[0]),
    .psum_kn1_dat           (accum_i_psum[1]),
    .psum_kn1_vld           (accum_i_psum_val[1]),
    .psum_kn2_dat           (accum_i_psum[2]),
    .psum_kn2_vld           (accum_i_psum_val[2]),
    .psum_kn3_dat           (accum_i_psum[3]),
    .psum_kn3_vld           (accum_i_psum_val[3]),
    .psum_knx_end           (accum_i_psum_end),
    .memctrl0_wadd          (memctrl0_wadd),
    .memctrl0_wren          (memctrl0_wren),
    .memctrl0_idat          (memctrl0_idat),
    .memctrl0_radd          (memctrl0_radd),
    .memctrl0_rden          (memctrl0_rden),
    .memctrl0_odat          (memctrl0_odat),
    .memctrl0_oval          (memctrl0_oval),
    .i_conf_weightinterval  (i_conf_weightinterval),
    .i_conf_outputsize      (i_conf_outputsize),
    .i_conf_kernelshape     (i_conf_kernelshape),
    .o_done                 (psum_done)
    );


// Control logic
reg [REG_WIDTH - 1 : 0] conf_status;

always @(posedge clk) begin
    if (rst) begin
        conf_status <= 0;
    end
    else begin
        conf_status <= {30'b0, kcpe_done, psum_done};
    end
end

assign o_conf_status = conf_status;

endmodule
