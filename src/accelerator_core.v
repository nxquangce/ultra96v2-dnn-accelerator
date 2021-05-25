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
    i_data_vld,
    o_weight_req,
    i_weight,
    i_weight_vld,
    // o_psum_kn0,
    // o_psum_kn0_vld,
    // o_psum_kn1,
    // o_psum_kn1_vld,
    // o_psum_kn2,
    // o_psum_kn2_vld,
    // o_psum_kn3,
    // o_psum_kn3_vld,
    memctrl0_wadd,
    memctrl0_wren,
    memctrl0_idat,
    memctrl0_radd,
    memctrl0_rden,
    memctrl0_odat,
    memctrl0_ovld,
    i_conf_ctrl,
    i_conf_outputsize,
    i_conf_kernelsize,
    i_conf_weightinterval,
    i_conf_kernelshape,
    i_conf_inputshape,
    i_conf_inputrstcnt,
    o_conf_status,
    dbg_linekcpe_valid_knx_cnt,
    dbg_linekcpe_psum_line_vld_cnt,
    dbg_linekcpe_idata_req_cnt,
    dbg_linekcpe_odata_req_cnt,
    dbg_linekcpe_weight_line_req_cnt,
    dbg_linekcpe_weight_done_cnt,
    dbg_linekcpe_kernel_done_cnt,
    dbg_psumacc_base_addr,
    dbg_psumacc_psum_out_cnt,
    dbg_psumacc_rd_addr,
    dbg_psumacc_wr_addr,

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

parameter OUTPUT_MEM_DELAY = 1;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input  wire                               clk;
input  wire                               rst;
output wire                               o_data_req;
output wire                               o_data_end;
output wire                               o_weight_req;
input  wire [IN_INPUT_DAT_WIDTH  - 1 : 0] i_data;
input  wire [IN_WEIGHT_DAT_WIDTH - 1 : 0] i_weight;
input  wire                               i_data_vld;
input  wire                               i_weight_vld;
// output wire           [BIT_WIDTH - 1 : 0] o_psum_kn0;
// output wire           [BIT_WIDTH - 1 : 0] o_psum_kn1;
// output wire           [BIT_WIDTH - 1 : 0] o_psum_kn2;
// output wire           [BIT_WIDTH - 1 : 0] o_psum_kn3;
// output wire                               o_psum_kn0_vld;
// output wire                               o_psum_kn1_vld;
// output wire                               o_psum_kn2_vld;
// output wire                               o_psum_kn3_vld;
output wire          [ADDR_WIDTH - 1 : 0] memctrl0_wadd;
output wire                               memctrl0_wren;
output wire          [DATA_WIDTH - 1 : 0] memctrl0_idat;
output wire          [ADDR_WIDTH - 1 : 0] memctrl0_radd;
output wire                               memctrl0_rden;
input  wire          [DATA_WIDTH - 1 : 0] memctrl0_odat;
input  wire                               memctrl0_ovld;
input  wire           [REG_WIDTH - 1 : 0] i_conf_ctrl;
input  wire           [REG_WIDTH - 1 : 0] i_conf_outputsize;
input  wire           [REG_WIDTH - 1 : 0] i_conf_kernelsize;
input  wire           [REG_WIDTH - 1 : 0] i_conf_weightinterval;
input  wire           [REG_WIDTH - 1 : 0] i_conf_kernelshape;
input  wire           [REG_WIDTH - 1 : 0] i_conf_inputshape;
input  wire           [REG_WIDTH - 1 : 0] i_conf_inputrstcnt;
output wire           [REG_WIDTH - 1 : 0] o_conf_status;

output wire           [REG_WIDTH - 1 : 0] dbg_linekcpe_valid_knx_cnt;
output wire           [REG_WIDTH - 1 : 0] dbg_linekcpe_psum_line_vld_cnt;
output wire           [REG_WIDTH - 1 : 0] dbg_linekcpe_idata_req_cnt;
output wire           [REG_WIDTH - 1 : 0] dbg_linekcpe_odata_req_cnt;
output wire           [REG_WIDTH - 1 : 0] dbg_linekcpe_weight_line_req_cnt;
output wire           [REG_WIDTH - 1 : 0] dbg_linekcpe_weight_done_cnt;
output wire           [REG_WIDTH - 1 : 0] dbg_linekcpe_kernel_done_cnt;

output wire           [REG_WIDTH - 1 : 0] dbg_psumacc_base_addr;
output wire           [REG_WIDTH - 1 : 0] dbg_psumacc_psum_out_cnt;
output wire           [REG_WIDTH - 1 : 0] dbg_psumacc_rd_addr;
output wire           [REG_WIDTH - 1 : 0] dbg_psumacc_wr_addr;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire  [BIT_WIDTH * 2 - 1 : 0] accum_i_psum [NUM_KERNEL - 1 : 0];
wire     [NUM_KERNEL - 1 : 0] accum_i_psum_vld;
wire                          accum_i_psum_end;
// wire [BIT_WIDTH - 1 : 0]                accum_o_psum [NUM_KERNEL - 1 : 0];
// wire [NUM_KERNEL - 1 : 0]               accum_o_psum_vld;

// wire [(BIT_WIDTH * NUM_KERNEL) - 1 : 0] engine_i_psum;
// wire                                    engine_i_psum_vld;

wire                      rst_soft;
wire                      rst_p;
wire                      kcpe_done;
wire                      psum_done;

assign rst_soft = i_conf_ctrl[1];
assign rst_p = rst | rst_soft;

line_kcpe_conv2d_engine line_kcpe_conv2d_engine_0(
    .clk                                (clk),
    .rst                                (rst_p),
    .o_data_req                         (o_data_req),
    .o_data_end                         (o_data_end),
    .i_data                             (i_data),
    .i_data_vld                         (i_data_vld),
    .o_weight_req                       (o_weight_req),
    .i_weight                           (i_weight),
    .i_weight_vld                       (i_weight_vld),
    // .i_psum                             (engine_i_psum),
    // .i_psum_vld                         (engine_i_psum_vld),
    .o_psum_kn0                         (accum_i_psum[0]),
    .o_psum_kn0_vld                     (accum_i_psum_vld[0]),
    .o_psum_kn1                         (accum_i_psum[1]),
    .o_psum_kn1_vld                     (accum_i_psum_vld[1]),
    .o_psum_kn2                         (accum_i_psum[2]),
    .o_psum_kn2_vld                     (accum_i_psum_vld[2]),
    .o_psum_kn3                         (accum_i_psum[3]),
    .o_psum_kn3_vld                     (accum_i_psum_vld[3]),
    .o_psum_end                         (accum_i_psum_end),
    .i_conf_ctrl                        (i_conf_ctrl),
    .i_conf_kernelshape                 (i_conf_kernelshape),
    .i_conf_inputshape                  (i_conf_inputshape),
    .i_conf_inputrstcnt                 (i_conf_inputrstcnt),
    .i_conf_outputsize                  (i_conf_outputsize),
    .i_conf_kernelsize                  (i_conf_kernelsize),
    .o_done                             (kcpe_done),
    .dbg_linekcpe_valid_knx_cnt         (dbg_linekcpe_valid_knx_cnt),
    .dbg_linekcpe_psum_line_vld_cnt     (dbg_linekcpe_psum_line_vld_cnt),
    .dbg_linekcpe_idata_req_cnt         (dbg_linekcpe_idata_req_cnt),
    .dbg_linekcpe_odata_req_cnt         (dbg_linekcpe_odata_req_cnt),
    .dbg_linekcpe_weight_line_req_cnt   (dbg_linekcpe_weight_line_req_cnt),
    .dbg_linekcpe_weight_done_cnt       (dbg_linekcpe_weight_done_cnt),
    .dbg_linekcpe_kernel_done_cnt       (dbg_linekcpe_kernel_done_cnt)
    );

psum_accum_ctrl
    #(
    .MEM_DELAY                  (OUTPUT_MEM_DELAY)
    )
psum_accum_ctrl_0(
    .clk                        (clk),
    .rst                        (rst_p),
    .psum_kn0_dat               (accum_i_psum[0]),
    .psum_kn0_vld               (accum_i_psum_vld[0]),
    .psum_kn1_dat               (accum_i_psum[1]),
    .psum_kn1_vld               (accum_i_psum_vld[1]),
    .psum_kn2_dat               (accum_i_psum[2]),
    .psum_kn2_vld               (accum_i_psum_vld[2]),
    .psum_kn3_dat               (accum_i_psum[3]),
    .psum_kn3_vld               (accum_i_psum_vld[3]),
    .psum_knx_end               (accum_i_psum_end),
    .memctrl0_wadd              (memctrl0_wadd),
    .memctrl0_wren              (memctrl0_wren),
    .memctrl0_idat              (memctrl0_idat),
    .memctrl0_radd              (memctrl0_radd),
    .memctrl0_rden              (memctrl0_rden),
    .memctrl0_odat              (memctrl0_odat),
    .memctrl0_ovld              (memctrl0_ovld),
    .i_conf_weightinterval      (i_conf_weightinterval),
    .i_conf_outputsize          (i_conf_outputsize),
    .i_conf_kernelshape         (i_conf_kernelshape),
    .o_done                     (psum_done),
    .dbg_psumacc_base_addr      (dbg_psumacc_base_addr),
    .dbg_psumacc_psum_out_cnt   (dbg_psumacc_psum_out_cnt),
    .dbg_psumacc_rd_addr        (dbg_psumacc_rd_addr),
    .dbg_psumacc_wr_addr        (dbg_psumacc_wr_addr)
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
