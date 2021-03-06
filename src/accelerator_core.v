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
    i_conf_outputshape,
    o_conf_status,
    ps_addr,
    ps_wren,
    ps_wdat,
    ps_rden,
    ps_rdat,
    ps_rvld,
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

parameter STRIDE_WIDTH      = 4;
parameter PADDING_WIDTH     = 4;

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
input  wire           [REG_WIDTH - 1 : 0] i_conf_outputshape;
output wire           [REG_WIDTH - 1 : 0] o_conf_status;

input                 [REG_WIDTH - 1 : 0] ps_addr;
input                                     ps_wren;
input                 [REG_WIDTH - 1 : 0] ps_wdat;
input                                     ps_rden;
output                [REG_WIDTH - 1 : 0] ps_rdat;
output                                    ps_rvld;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire  [BIT_WIDTH * 2 - 1 : 0] accum_i_psum [NUM_KERNEL - 1 : 0];
wire     [NUM_KERNEL - 1 : 0] accum_i_psum_vld;
wire                          accum_i_psum_end;

// wire                          rst_soft;
// wire                          rst_p;
wire                          i_cnfx_enable;
wire                          kcpe_done;
wire                          psum_done;

wire   [STRIDE_WIDTH - 1 : 0] i_cnfx_stride;
wire  [PADDING_WIDTH - 1 : 0] i_cnfx_padding;

wire      [REG_WIDTH - 1 : 0] linekcpe_valid_knx_cnt;
wire      [REG_WIDTH - 1 : 0] linekcpe_psum_line_vld_cnt;
wire      [REG_WIDTH - 1 : 0] linekcpe_idata_req_cnt;
wire      [REG_WIDTH - 1 : 0] linekcpe_odata_req_cnt;
wire      [REG_WIDTH - 1 : 0] linekcpe_weight_line_req_cnt;
wire      [REG_WIDTH - 1 : 0] linekcpe_weight_done_cnt;
wire      [REG_WIDTH - 1 : 0] linekcpe_kernel_done_cnt;
wire      [REG_WIDTH - 1 : 0] psumacc_base_addr;
wire      [REG_WIDTH - 1 : 0] psumacc_psum_out_cnt;
wire      [REG_WIDTH - 1 : 0] psumacc_wr_addr;
wire      [REG_WIDTH - 1 : 0] psumacc_rd_addr;
wire      [REG_WIDTH - 1 : 0] datareq_knlinex_cnt;
wire      [REG_WIDTH - 1 : 0] datareq_addr_reg;

assign i_cnfx_enable  = i_conf_ctrl[0];
assign i_cnfx_stride  = i_conf_kernelsize[19:16];
assign i_cnfx_padding = i_conf_kernelsize[27:24];

wire [7 : 0] valid_input_shape;
assign valid_input_shape = (i_conf_inputshape[7:0] + i_cnfx_padding - i_conf_kernelshape[3:0]);

// assign rst_soft = i_conf_ctrl[1];
// assign rst_p = rst | rst_soft;

line_kcpe_conv2d_engine line_kcpe_conv2d_engine_0(
    .clk                                (clk),
    .rst                                (rst),
    .o_data_req                         (o_data_req),
    .o_data_end                         (o_data_end),
    .i_data                             (i_data),
    .i_data_vld                         (i_data_vld),
    .o_weight_req                       (o_weight_req),
    .i_weight                           (i_weight),
    .i_weight_vld                       (i_weight_vld),
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
    .i_conf_outputshape                 (i_conf_outputshape),
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
    .rst                        (rst),
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
    .i_conf_ctrl                (i_conf_ctrl),
    .i_conf_weightinterval      (i_conf_weightinterval),
    .i_conf_outputsize          (i_conf_outputsize),
    .i_conf_inputshape          (i_conf_inputshape),
    .i_conf_kernelshape         (i_conf_kernelshape),
    .i_conf_outputshape         (i_conf_outputshape),
    .i_cnfx_stride              (i_cnfx_stride),
    .i_cnfx_padding             (i_cnfx_padding),
    .o_done                     (psum_done),
    .dbg_psumacc_base_addr      (dbg_psumacc_base_addr),
    .dbg_psumacc_psum_out_cnt   (dbg_psumacc_psum_out_cnt),
    .dbg_psumacc_rd_addr        (dbg_psumacc_rd_addr),
    .dbg_psumacc_wr_addr        (dbg_psumacc_wr_addr)
    );


// Control logic
reg [REG_WIDTH - 1 : 0] conf_status;
reg [REG_WIDTH - 1 : 0] time_cnt;

always @(posedge clk) begin
    if (rst) begin
        conf_status <= 0;
    end
    else begin
        conf_status <= {30'b0, kcpe_done, psum_done};
    end
end

assign o_conf_status = conf_status;

// Execution timer
reg [2 : 0] psum_done_pp;
wire time_cnt_enb;

always @(posedge clk) begin
    psum_done_pp[0] <= psum_done;
    psum_done_pp[1] <= psum_done_pp[0];
    psum_done_pp[2] <= psum_done_pp[1];
end

assign time_cnt_enb = i_cnfx_enable & (~psum_done_pp[2]);

always @(posedge clk) begin
    if (rst) begin
        time_cnt <= 0;
    end
    else if (time_cnt_enb) begin
        time_cnt <= time_cnt + 1'b1;
    end
end

statusx_psif #(
    .BASE_ADDR          (32'hF0000010),
    .ADDR_RANGE_WIDTH   (4),
    .NUM_REGS           (1)
    )
status_register(
    .idat               (time_cnt),
    .ps_addr            (ps_addr),
    .ps_rden            (ps_rden),
    .ps_rdat            (ps_rdat),
    .ps_rvld            (ps_rvld)
    );

statusx_psif #(
    .BASE_ADDR         (32'hF0000000),
    .ADDR_RANGE_WIDTH  (4),
    .NUM_REGS          (13)
    )
dbg_cnt_register(
    .idat       ({
                dbg_linekcpe_valid_knx_cnt,
                dbg_linekcpe_psum_line_vld_cnt,
                dbg_linekcpe_idata_req_cnt,
                dbg_linekcpe_odata_req_cnt,
                dbg_linekcpe_weight_line_req_cnt,
                dbg_linekcpe_weight_done_cnt,
                dbg_linekcpe_kernel_done_cnt,
                dbg_psumacc_base_addr,
                dbg_psumacc_psum_out_cnt,
                dbg_psumacc_wr_addr,
                dbg_psumacc_rd_addr,
                dbg_datareq_knlinex_cnt,
                dbg_datareq_addr_reg
                }),
    .ps_addr    (ps_addr),
    .ps_rden    (ps_rden),
    .ps_rdat    (dbg_cnt_register_rdat),
    .ps_rvld    (dbg_cnt_register_rvld)
    );

endmodule
