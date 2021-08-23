`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 03/17/2021 10:39:10 PM
// Design Name: Line kernel-channel-PE-based Convolution 2D Engine
// Module Name: line_kcpe_conv2d_engine
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: An array of 3 kernel-channel processing elements
//              to calculate MAC on 3 positions of 3 channel/4 kernel
//              in parallel
// 
// Dependencies: 
//  kernel_channel_pe
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module line_kcpe_conv2d_engine(
    clk,
    rst,
    o_data_req,
    o_data_end,
    i_data,
    i_data_vld,
    o_weight_req,
    i_weight,
    i_weight_vld,
    o_psum_kn0,
    o_psum_kn0_vld,
    o_psum_kn1,
    o_psum_kn1_vld,
    o_psum_kn2,
    o_psum_kn2_vld,
    o_psum_kn3,
    o_psum_kn3_vld,
    o_psum_end,
    i_conf_ctrl,
    i_conf_kernelshape,
    i_conf_inputshape,
    i_conf_inputrstcnt,
    i_conf_outputsize,
    i_conf_kernelsize,
    i_conf_outputshape,
    o_done,
    dbg_linekcpe_valid_knx_cnt,
    dbg_linekcpe_psum_line_vld_cnt,
    dbg_linekcpe_idata_req_cnt,
    dbg_linekcpe_odata_req_cnt,
    dbg_linekcpe_weight_line_req_cnt,
    dbg_linekcpe_weight_done_cnt,
    dbg_linekcpe_kernel_done_cnt,
    // ps_addr,
    // ps_wren,
    // ps_wdat,
    // ps_rden,
    // ps_rdat,
    // ps_rvld,
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter BIT_WIDTH             = 8;
parameter NUM_CHANNEL           = 3;
parameter NUM_KERNEL            = 4;
parameter NUM_KCPE              = 3;    // Number of kernel-channel PE
parameter REG_WIDTH             = 32;

parameter NUM_RDATA             = NUM_KCPE;

parameter KERNEL_SIZE_WIDTH     = 4;
parameter INPUT_SIZE_WIDTH      = 8;
parameter NUM_KCPE_WIDTH        = 2;

localparam IN_INPUT_DAT_WIDTH   = BIT_WIDTH * NUM_CHANNEL;
localparam IN_WEIGHT_DAT_WIDTH  = BIT_WIDTH * NUM_CHANNEL * NUM_KERNEL;

parameter INPUT_FF_ADDR_WIDTH   = 4;

parameter PADDING_WIDTH         = 4;
parameter STRIDE_WIDTH          = 4;
parameter OUTPUT_SHAPE_WIDTH    = 16;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input  wire                               clk;
input  wire                               rst;
output wire                               o_data_req;
output wire                               o_data_end;
output wire                               o_weight_req;
input  wire  [IN_INPUT_DAT_WIDTH - 1 : 0] i_data;
input  wire [IN_WEIGHT_DAT_WIDTH - 1 : 0] i_weight;
// input  wire [(BIT_WIDTH * NUM_KERNEL              ) - 1 : 0] i_psum;
input  wire                               i_data_vld;
input  wire                               i_weight_vld;
// input  wire                                                  i_psum_vld;
// output wire [(BIT_WIDTH * NUM_KERNEL              ) - 1 : 0] o_psum;
// output wire [NUM_KERNEL - 1 : 0]                             o_psum_vld;
output wire       [BIT_WIDTH * 2 - 1 : 0] o_psum_kn0;
output wire       [BIT_WIDTH * 2 - 1 : 0] o_psum_kn1;
output wire       [BIT_WIDTH * 2 - 1 : 0] o_psum_kn2;
output wire       [BIT_WIDTH * 2 - 1 : 0] o_psum_kn3;
output wire                               o_psum_kn0_vld;
output wire                               o_psum_kn1_vld;
output wire                               o_psum_kn2_vld;
output wire                               o_psum_kn3_vld;
output wire                               o_psum_end;

input  wire           [REG_WIDTH - 1 : 0] i_conf_ctrl;
input  wire           [REG_WIDTH - 1 : 0] i_conf_kernelshape;
input  wire           [REG_WIDTH - 1 : 0] i_conf_inputshape;
input  wire           [REG_WIDTH - 1 : 0] i_conf_inputrstcnt;
input  wire           [REG_WIDTH - 1 : 0] i_conf_outputsize;
input  wire           [REG_WIDTH - 1 : 0] i_conf_kernelsize;
input  wire           [REG_WIDTH - 1 : 0] i_conf_outputshape;
output wire                               o_done;

// Debug
output wire           [REG_WIDTH - 1 : 0] dbg_linekcpe_valid_knx_cnt;
output wire           [REG_WIDTH - 1 : 0] dbg_linekcpe_psum_line_vld_cnt;
output wire           [REG_WIDTH - 1 : 0] dbg_linekcpe_idata_req_cnt;
output wire           [REG_WIDTH - 1 : 0] dbg_linekcpe_odata_req_cnt;
output wire           [REG_WIDTH - 1 : 0] dbg_linekcpe_weight_line_req_cnt;
output wire           [REG_WIDTH - 1 : 0] dbg_linekcpe_weight_done_cnt;
output wire           [REG_WIDTH - 1 : 0] dbg_linekcpe_kernel_done_cnt;

// input  wire                               ps_wren;
// input  wire           [REG_WIDTH - 1 : 0] ps_addr;
// input  wire           [REG_WIDTH - 1 : 0] ps_wdat;
// input  wire                               ps_rden;
// output wire           [REG_WIDTH - 1 : 0] ps_rdat;
// output wire                               ps_rvld;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
// Input signals
localparam BUFFER_O_DATA_WIDTH = IN_INPUT_DAT_WIDTH * NUM_RDATA;

wire                                   i_data_req;
wire [BUFFER_O_DATA_WIDTH - 1 : 0]     buffer_o_data;
wire                                   buffer_o_data_vld;
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0] engine_i_data_pos0;
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0] engine_i_data_pos1;
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0] engine_i_data_pos2;
wire                                   buffer_o_data_full;
wire                                   buffer_o_data_half;
wire                                   buffer_o_data_empty;

// Weight signals
wire                                                i_weight_req;
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0]              i_weight_kn0;
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0]              i_weight_kn1;
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0]              i_weight_kn2;
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0]              i_weight_kn3;

wire [BIT_WIDTH * NUM_CHANNEL * NUM_RDATA - 1 : 0]  buffer_o_weight_3ch3pos_kn0;
wire [BIT_WIDTH * NUM_CHANNEL * NUM_RDATA - 1 : 0]  buffer_o_weight_3ch3pos_kn1;
wire [BIT_WIDTH * NUM_CHANNEL * NUM_RDATA - 1 : 0]  buffer_o_weight_3ch3pos_kn2;
wire [BIT_WIDTH * NUM_CHANNEL * NUM_RDATA - 1 : 0]  buffer_o_weight_3ch3pos_kn3;
wire                                                buffer_o_weight_3ch3pos_kn0_vld;
wire                                                buffer_o_weight_3ch3pos_kn1_vld;
wire                                                buffer_o_weight_3ch3pos_kn2_vld;
wire                                                buffer_o_weight_3ch3pos_kn3_vld;
wire                                                buffer_o_weight_full;

wire [BIT_WIDTH * NUM_CHANNEL * NUM_KERNEL - 1 : 0] engine_i_weight_3ch4kn_pos0;
wire [BIT_WIDTH * NUM_CHANNEL * NUM_KERNEL - 1 : 0] engine_i_weight_3ch4kn_pos1;
wire [BIT_WIDTH * NUM_CHANNEL * NUM_KERNEL - 1 : 0] engine_i_weight_3ch4kn_pos2;

// Psum out signals
wire [BIT_WIDTH *2 * NUM_KERNEL - 1 : 0] engine_o_psum_kcpe0;
wire [BIT_WIDTH *2 * NUM_KERNEL - 1 : 0] engine_o_psum_kcpe1;
wire [BIT_WIDTH *2 * NUM_KERNEL - 1 : 0] engine_o_psum_kcpe2;
wire                                     engine_o_psum_kcpe0_vld;
wire                                     engine_o_psum_kcpe1_vld;
wire                                     engine_o_psum_kcpe2_vld;

reg                     neg_enb;
reg                     con_enb;
reg                     con_enb_cache;
reg                     con_enb_vld;
reg                     con_enb_vld_pp;

// Detect rising edge of continue enable conf
always @(posedge clk) begin
    con_enb_cache <= con_enb;
    con_enb_vld <= ~con_enb_cache & con_enb;
    con_enb_vld_pp <= con_enb_vld;
end


// Activation input buffer
wire [3:0]                         i_cnfx_stride;
wire [3:0]                         i_cnfx_numinvalidrow;
wire [3:0]                         i_cnfx_padding;
wire [KERNEL_SIZE_WIDTH - 1 : 0]   i_cnfx_kernelwidth;
wire [INPUT_SIZE_WIDTH - 1 : 0]    i_cnfx_inputwidth;
wire [7:0]                         outputwidth;
wire [3:0]                         buffer_i_data_step;
wire [INPUT_FF_ADDR_WIDTH - 1 : 0] buffer_o_data_counter;
wire                               buffer_o_data_preempty;

reg [REG_WIDTH - 1 : 0] idata_req_per_row_cnt;
wire                    idata_req_per_row_cnt_max_vld;
wire                    idata_req_per_row_cnt_sta_vld;

reg [PADDING_WIDTH - 1 : 0] pad_sta;
reg [PADDING_WIDTH - 1 : 0] pad_end;

assign i_cnfx_stride        = i_conf_kernelsize[19:16];
assign i_cnfx_numinvalidrow = i_conf_kernelsize[23:20];
assign i_cnfx_padding       = i_conf_kernelsize[27:24];
assign i_cnfx_kernelwidth   = i_conf_kernelshape[KERNEL_SIZE_WIDTH - 1 : 0];
assign i_cnfx_inputwidth    = i_conf_inputshape[INPUT_SIZE_WIDTH - 1 : 0];
assign outputwidth          = i_conf_outputshape[7:0];

always @(posedge clk) begin
    pad_sta <= i_cnfx_padding >> 1;
    pad_end <= i_cnfx_padding - (i_cnfx_padding >> 1);
end

reg idata_req_per_row_cnt_sta_vld_cache;
always @(posedge clk) begin
    if (rst) begin
        idata_req_per_row_cnt_sta_vld_cache <= 0;
    end
    else if (i_data_req) begin
        idata_req_per_row_cnt_sta_vld_cache <= idata_req_per_row_cnt_sta_vld;
    end
end

assign idata_req_per_row_cnt_sta_vld = (idata_req_per_row_cnt == 0) & ~idata_req_per_row_cnt_sta_vld_cache;
assign idata_req_per_row_cnt_max_vld = idata_req_per_row_cnt == (i_cnfx_inputwidth - i_cnfx_numinvalidrow - 1'b1);

always @(posedge clk) begin
    if (rst) begin
        idata_req_per_row_cnt <= 0;
    end
    else if (i_data_req) begin
        idata_req_per_row_cnt <= (idata_req_per_row_cnt_max_vld) ? 0 : idata_req_per_row_cnt + buffer_i_data_step;
    end
end

assign buffer_i_data_step = (idata_req_per_row_cnt_sta_vld) ? i_cnfx_stride - pad_sta :
                            (idata_req_per_row_cnt_max_vld) ? (i_cnfx_numinvalidrow + 1'b1) : i_cnfx_stride;

reg idata_req_per_row_cnt_sta_vld_pp;
reg idata_req_per_row_cnt_end_vld_pp;
always @(posedge clk) begin
    idata_req_per_row_cnt_sta_vld_pp <= idata_req_per_row_cnt_sta_vld;
    idata_req_per_row_cnt_end_vld_pp <= idata_req_per_row_cnt_max_vld;
end

input_buffer 
    #(
    .BIT_WIDTH          (BIT_WIDTH),
    .NUM_CHANNEL        (NUM_CHANNEL),
    .NUM_RDATA          (NUM_RDATA),
    .FF_ADDR_WIDTH      (INPUT_FF_ADDR_WIDTH)
    )
input_buffer_0(
    .clk                (clk),
    .rst                (rst),
    .i_data             (i_data),
    .i_data_vld         (i_data_vld),
    .i_data_req         (i_data_req),
    .i_step             (buffer_i_data_step),
    .o_data             (buffer_o_data),
    .o_data_vld         (buffer_o_data_vld),
    .data_counter       (buffer_o_data_counter),
    .o_full             (buffer_o_data_full),
    .o_empty            (buffer_o_data_empty),
    .o_half             (buffer_o_data_half)
    );

assign buffer_o_data_preempty = (buffer_o_data_counter <  i_cnfx_kernelwidth);

// Data in position
wire [IN_INPUT_DAT_WIDTH - 1 : 0] buffer_o_data_pos [NUM_RDATA - 1 : 0];
assign buffer_o_data_pos[0] = buffer_o_data[IN_INPUT_DAT_WIDTH - 1 : 0];
assign buffer_o_data_pos[1] = buffer_o_data[IN_INPUT_DAT_WIDTH * 2 - 1 : IN_INPUT_DAT_WIDTH];
assign buffer_o_data_pos[2] = buffer_o_data[IN_INPUT_DAT_WIDTH * 3 - 1 : IN_INPUT_DAT_WIDTH * 2];

wire sta_with_pad_vld;
wire end_with_pad_vld;

assign sta_with_pad_vld = idata_req_per_row_cnt_sta_vld_pp & (pad_sta != 0);
assign end_with_pad_vld = idata_req_per_row_cnt_end_vld_pp & (pad_end != 0);

assign engine_i_data_pos0 = (sta_with_pad_vld) ?                    0 : buffer_o_data_pos[0];
assign engine_i_data_pos1 = (sta_with_pad_vld) ? buffer_o_data_pos[0] : buffer_o_data_pos[1];
assign engine_i_data_pos2 = (sta_with_pad_vld) ? buffer_o_data_pos[1] : 
                            (end_with_pad_vld) ?                    0 : buffer_o_data_pos[2];

// Weight Buffer
assign i_weight_kn0 = i_weight[BIT_WIDTH * NUM_CHANNEL - 1 : 0];
assign i_weight_kn1 = i_weight[BIT_WIDTH * NUM_CHANNEL * 2 - 1 : BIT_WIDTH * NUM_CHANNEL];
assign i_weight_kn2 = i_weight[BIT_WIDTH * NUM_CHANNEL * 3 - 1 : BIT_WIDTH * NUM_CHANNEL * 2];
assign i_weight_kn3 = i_weight[BIT_WIDTH * NUM_CHANNEL * 4 - 1 : BIT_WIDTH * NUM_CHANNEL * 3];

weight_buffer weight_buffer_0(
    .clk                (clk),
    .rst                (rst),
    .i_data_kn0         (i_weight_kn0),
    .i_data_kn0_val     (i_weight_vld),
    .i_data_kn1         (i_weight_kn1),
    .i_data_kn1_val     (i_weight_vld),
    .i_data_kn2         (i_weight_kn2),
    .i_data_kn2_val     (i_weight_vld),
    .i_data_kn3         (i_weight_kn3),
    .i_data_kn3_val     (i_weight_vld),
    .i_data_req         (i_weight_req),
    .o_data_3ch_kn0     (buffer_o_weight_3ch3pos_kn0),
    .o_data_3ch_kn0_val (buffer_o_weight_3ch3pos_kn0_vld),
    .o_data_3ch_kn1     (buffer_o_weight_3ch3pos_kn1),
    .o_data_3ch_kn1_val (buffer_o_weight_3ch3pos_kn1_vld),
    .o_data_3ch_kn2     (buffer_o_weight_3ch3pos_kn2),
    .o_data_3ch_kn2_val (buffer_o_weight_3ch3pos_kn2_vld),
    .o_data_3ch_kn3     (buffer_o_weight_3ch3pos_kn3),
    .o_data_3ch_kn3_val (buffer_o_weight_3ch3pos_kn3_vld),
    .o_full             (buffer_o_weight_full)
    );

// Convert weight from kernel to position
wire [BIT_WIDTH * NUM_CHANNEL - 1 : 0] buffer_o_weight [NUM_KERNEL - 1 : 0][NUM_RDATA - 1 : 0];

genvar idxIwPos;
generate
    for (idxIwPos = 0; idxIwPos < NUM_KCPE; idxIwPos = idxIwPos + 1) begin
        assign buffer_o_weight[0][idxIwPos] = buffer_o_weight_3ch3pos_kn0[BIT_WIDTH * ((idxIwPos + 1) * NUM_CHANNEL) - 1: BIT_WIDTH * idxIwPos * NUM_CHANNEL];
        assign buffer_o_weight[1][idxIwPos] = buffer_o_weight_3ch3pos_kn1[BIT_WIDTH * ((idxIwPos + 1) * NUM_CHANNEL) - 1: BIT_WIDTH * idxIwPos * NUM_CHANNEL];
        assign buffer_o_weight[2][idxIwPos] = buffer_o_weight_3ch3pos_kn2[BIT_WIDTH * ((idxIwPos + 1) * NUM_CHANNEL) - 1: BIT_WIDTH * idxIwPos * NUM_CHANNEL];
        assign buffer_o_weight[3][idxIwPos] = buffer_o_weight_3ch3pos_kn3[BIT_WIDTH * ((idxIwPos + 1) * NUM_CHANNEL) - 1: BIT_WIDTH * idxIwPos * NUM_CHANNEL];
    end
endgenerate

assign engine_i_weight_3ch4kn_pos0 = {buffer_o_weight[3][0], buffer_o_weight[2][0], buffer_o_weight[1][0], buffer_o_weight[0][0]};
assign engine_i_weight_3ch4kn_pos1 = {buffer_o_weight[3][1], buffer_o_weight[2][1], buffer_o_weight[1][1], buffer_o_weight[0][1]};
assign engine_i_weight_3ch4kn_pos2 = {buffer_o_weight[3][2], buffer_o_weight[2][2], buffer_o_weight[1][2], buffer_o_weight[0][2]};

// KC PE 0
kernel_channel_pe 
    #(
    .NUM_CHANNEL    (NUM_CHANNEL),
    .BIT_WIDTH      (BIT_WIDTH),
    .NUM_KERNEL     (NUM_KERNEL),
    .REG_WIDTH      (REG_WIDTH)
    )
kernel_channel_pe_0
    (
    .clk            (clk),
    .rst            (rst),
    .i_data         (engine_i_data_pos0),
    .i_data_vld     (buffer_o_data_vld),
    .i_weight       (engine_i_weight_3ch4kn_pos0),
    .i_weight_vld   (buffer_o_weight_3ch3pos_kn0_vld),
    .i_psum         (0),
    // .i_psum_vld     (),
    .o_psum         (engine_o_psum_kcpe0),
    .o_psum_vld     (engine_o_psum_kcpe0_vld),
    .i_conf_neg_enb (neg_enb),
    .err_psum_vld   ()
    );

// KC PE 1
kernel_channel_pe 
    #(
    .NUM_CHANNEL    (NUM_CHANNEL),
    .BIT_WIDTH      (BIT_WIDTH),
    .NUM_KERNEL     (NUM_KERNEL),
    .REG_WIDTH      (REG_WIDTH)
    )
kernel_channel_pe_1
    (
    .clk            (clk),
    .rst            (rst),
    .i_data         (engine_i_data_pos1),
    .i_data_vld     (buffer_o_data_vld),
    .i_weight       (engine_i_weight_3ch4kn_pos1),
    .i_weight_vld   (buffer_o_weight_3ch3pos_kn0_vld),
    .i_psum         (0),
    // .i_psum_vld     (),
    .o_psum         (engine_o_psum_kcpe1),
    .o_psum_vld     (engine_o_psum_kcpe1_vld),
    .i_conf_neg_enb (neg_enb),
    .err_psum_vld   ()
    );

// KC PE 2
kernel_channel_pe 
    #(
    .NUM_CHANNEL    (NUM_CHANNEL),
    .BIT_WIDTH      (BIT_WIDTH),
    .NUM_KERNEL     (NUM_KERNEL),
    .REG_WIDTH      (REG_WIDTH)
    )
kernel_channel_pe_2
    (
    .clk            (clk),
    .rst            (rst),
    .i_data         (engine_i_data_pos2),
    .i_data_vld     (buffer_o_data_vld),
    .i_weight       (engine_i_weight_3ch4kn_pos2),
    .i_weight_vld   (buffer_o_weight_3ch3pos_kn0_vld),
    .i_psum         (0),
    // .i_psum_vld     (),
    .o_psum         (engine_o_psum_kcpe2),
    .o_psum_vld     (engine_o_psum_kcpe2_vld),
    .i_conf_neg_enb (neg_enb),
    .err_psum_vld   ()
    );

// Psum output
wire [BIT_WIDTH * 2 - 1 : 0] router_kn0;
wire [BIT_WIDTH * 2 - 1 : 0] router_kn1;
wire [BIT_WIDTH * 2 - 1 : 0] router_kn2;
wire [BIT_WIDTH * 2 - 1 : 0] router_kn3;
wire                         router_kn0_vld;
wire                         router_kn1_vld;
wire                         router_kn2_vld;
wire                         router_kn3_vld;
wire                         invalid_knx_vld;
wire                         valid_knx_cnt_max_vld;
reg                    [7:0] valid_knx_cnt;
reg      [REG_WIDTH - 1 : 0] psum_line_vld_cnt;
wire                         psum_line_vld_cnt_max_vld;

result_router result_router_0(
    .clk                (clk),
    .rst                (rst),
    .i_psum_kcpe0       (engine_o_psum_kcpe0),
    .i_psum_kcpe0_vld   (engine_o_psum_kcpe0_vld),
    .i_psum_kcpe1       (engine_o_psum_kcpe1),
    .i_psum_kcpe1_vld   (engine_o_psum_kcpe1_vld),
    .i_psum_kcpe2       (engine_o_psum_kcpe2),
    .i_psum_kcpe2_vld   (engine_o_psum_kcpe2_vld),
    .o_psum_kn0         (router_kn0),
    .o_psum_kn0_vld     (router_kn0_vld),
    .o_psum_kn1         (router_kn1),
    .o_psum_kn1_vld     (router_kn1_vld),
    .o_psum_kn2         (router_kn2),
    .o_psum_kn2_vld     (router_kn2_vld),
    .o_psum_kn3         (router_kn3),
    .o_psum_kn3_vld     (router_kn3_vld)
    );

wire [3 : 0] valid_row_by_padding;
assign valid_row_by_padding = (pad_end == 0) ? 0 : (i_cnfx_stride << (pad_end - 1'b1)); // support pad 0, 1, 2 only

assign valid_knx_cnt_max_vld = valid_knx_cnt == (i_cnfx_inputwidth - i_cnfx_numinvalidrow - 1'b1);
//(i_cnfx_inputwidth + pad_sta - i_cnfx_numinvalidrow - 1'b1);
assign invalid_knx_vld = valid_knx_cnt > (i_cnfx_inputwidth + pad_end - i_cnfx_kernelwidth);
// (outputwidth - 1'b1);
//(i_cnfx_inputwidth - i_cnfx_kernelwidth + valid_row_by_padding);

always @(posedge clk) begin
    if (rst) begin
        valid_knx_cnt <= 0;
    end
    else if (router_kn0_vld) begin
        valid_knx_cnt <= (valid_knx_cnt_max_vld) ? 0 : valid_knx_cnt + i_cnfx_stride;
    end
end

assign o_psum_kn0 = router_kn0;
assign o_psum_kn1 = router_kn1;
assign o_psum_kn2 = router_kn2;
assign o_psum_kn3 = router_kn3;
assign o_psum_kn0_vld = router_kn0_vld & ~invalid_knx_vld;
assign o_psum_kn1_vld = router_kn1_vld & ~invalid_knx_vld;
assign o_psum_kn2_vld = router_kn2_vld & ~invalid_knx_vld;
assign o_psum_kn3_vld = router_kn3_vld & ~invalid_knx_vld;

//// Control logic
reg                     enb;
reg                     init;
reg                     odata_req_reg;
reg                     idata_req_reg;
reg [REG_WIDTH - 1 : 0] idata_req_cnt;
wire                    idata_req_cnt_max_vld;
wire                    idata_end;
reg [REG_WIDTH - 1 : 0] odata_req_cnt;
wire                    odata_req_cnt_max_vld;
wire                    odata_req_cnt_premax_vld;
reg                     done;

reg             [7 : 0] weight_line_done_cnt;
wire                    weight_line_done_cnt_max_vld;
reg             [7 : 0] weight_done_cnt;
wire                    weight_done_cnt_max_vld;
reg [REG_WIDTH - 1 : 0] kernel_done_cnt;
wire                    kernel_done_cnt_max_vld;
wire                    kernel_end;

always @(posedge clk) begin
    enb <= i_conf_ctrl[0];
    neg_enb <= i_conf_ctrl[3];
    con_enb <= i_conf_ctrl[4];
end

// Psum control
reg [3 : 0]             sub_line_psum_vld_num;
reg [REG_WIDTH - 1 : 0] sub_psum_vld_num;
reg [REG_WIDTH - 1 : 0] psum_line_vld_cnt_max;
reg [3 : 0]             psum_weight_row_cnt;
reg                     psum_init;

always @(posedge clk) begin
    if (rst) begin
        psum_init <= 1'b1;
    end
    else if (o_psum_kn0_vld) begin
        psum_init <= 1'b0;
    end
end

always @(posedge clk) begin
    if (rst) begin
        psum_weight_row_cnt <= 0;
    end
    else if (psum_line_vld_cnt_max_vld & o_psum_kn0_vld) begin
        psum_weight_row_cnt <= (psum_weight_row_cnt == (i_cnfx_kernelwidth - 1'b1)) ? 0 : psum_weight_row_cnt + 1'b1;
    end
end

reg [3 : 0] psum_padend_cnd_num;
reg [REG_WIDTH - 1 : 0] outputwidthx2;
reg [REG_WIDTH - 1 : 0] outputwidthx3;

// fox timing
always @(posedge clk) begin
    outputwidthx2 <= outputwidth << 1;
    outputwidthx3 <= (outputwidth << 1) + outputwidth;
end

// fix timing
always @(posedge clk) begin
    psum_padend_cnd_num   <= i_cnfx_kernelwidth - psum_weight_row_cnt - 1'b1;
    sub_line_psum_vld_num <= (psum_weight_row_cnt < pad_sta) ? pad_sta - psum_weight_row_cnt :
                             (psum_padend_cnd_num < pad_end) ? pad_end - psum_padend_cnd_num : 0;
end

// fix timing
always @(posedge clk) begin
    sub_psum_vld_num <= (sub_line_psum_vld_num == 4'd1) ? outputwidth :
                        (sub_line_psum_vld_num == 4'd2) ? outputwidthx2 :
                        (sub_line_psum_vld_num == 4'd3) ? outputwidthx3 : 0;
end

always @(posedge clk) begin
    if (rst) begin
        psum_line_vld_cnt_max <= 0;
    end
    if (o_psum_kn0_vld) begin
        psum_line_vld_cnt_max <= i_conf_outputsize - sub_psum_vld_num;
    end
end

assign psum_line_vld_cnt_max_vld = (psum_line_vld_cnt == psum_line_vld_cnt_max) & ~psum_init;

always @(posedge clk) begin
    if (rst) begin
        psum_line_vld_cnt <= 0;
    end
    else if (o_psum_kn0_vld) begin
        psum_line_vld_cnt <= (psum_line_vld_cnt_max_vld) ? 0 : psum_line_vld_cnt + 1'b1;
    end
end

assign o_psum_end = psum_line_vld_cnt_max_vld & o_psum_kn0_vld;

// Out data req control
always @(posedge clk) begin
    if (rst | done) begin
        odata_req_reg <= 0;
    end
    else if (enb) begin
        odata_req_reg <= ~buffer_o_data_half;
    end
end

reg [REG_WIDTH - 1 : 0] add_data_req_num;
reg [REG_WIDTH - 1 : 0] data_req_max;

// fix timing
always @(posedge clk) begin
    if (rst) begin
        add_data_req_num <= 0;
    end
    else begin
        add_data_req_num <= (i_cnfx_padding == 0) ? 0 :
                            ((weight_line_done_cnt <= pad_sta) |
                            ((i_cnfx_kernelwidth - weight_line_done_cnt) < pad_end)) ? 
                            0 : i_cnfx_inputwidth;
    end
end

// fix timing
always @(posedge clk) begin
    data_req_max <= i_conf_inputrstcnt + add_data_req_num;
end

assign odata_req_cnt_max_vld = (odata_req_cnt == data_req_max);
assign odata_req_cnt_premax_vld = (odata_req_cnt == (data_req_max - i_cnfx_kernelwidth));

always @(posedge clk) begin
    if (rst) begin
        odata_req_cnt <= 0;
    end
    else if (o_data_req) begin
        odata_req_cnt <= (odata_req_cnt_max_vld) ? 0 : odata_req_cnt + 1'b1;
    end
end

assign o_data_req = odata_req_reg & ~done;
assign o_data_end = odata_req_cnt_max_vld & ~init;

always @(posedge clk) begin
    if (rst) begin
        init <= 1'b1;
    end
    else if (buffer_o_weight_full) begin
        init <= 1'b0;
    end
end

// In data req control
wire idata_end_req_vld;
assign idata_end_req_vld = idata_end & ~buffer_o_data_preempty;

always @(posedge clk) begin
    if (rst | idata_end_req_vld | done) begin
        idata_req_reg <= 1'b0;
    end
    else if (i_weight_req | con_enb_vld_pp) begin
        idata_req_reg <= 1'b1;
    end
end

// fix timing
reg [REG_WIDTH - 1 : 0] idata_req_cnt_max;
always @(posedge clk) begin
    if (rst) begin
        idata_req_cnt_max <= 0;
    end
    else begin
        idata_req_cnt_max <= i_conf_inputrstcnt + add_data_req_num - i_cnfx_numinvalidrow;
    end
end

assign idata_req_cnt_max_vld = (idata_req_cnt == idata_req_cnt_max);
assign idata_end = idata_req_cnt_max_vld;

always @(posedge clk) begin
    if (rst) begin
        idata_req_cnt <= 0;
    end
    else if (i_data_req) begin
        idata_req_cnt <= (idata_req_cnt_max_vld) ? 0 : idata_req_cnt + buffer_i_data_step;
    end
end

assign i_data_req = (init & buffer_o_data_full) | (idata_req_reg & ~buffer_o_data_preempty);

// Weight control
reg                             weight_init;
reg                             oweight_req_per_row_reg;
reg [KERNEL_SIZE_WIDTH - 1 : 0] oweight_req_per_row_cnt;
wire                            oweight_req_per_row_cnt_max_vld;

always @(posedge clk) begin
    if (rst) begin
        weight_init <= 1'b0;
    end
    else if (oweight_req_per_row_cnt_max_vld) begin
        weight_init <= 1'b1;
    end
end

assign oweight_req_per_row_cnt_max_vld = oweight_req_per_row_cnt == (i_cnfx_kernelwidth - 1'b1);

always @(posedge clk) begin
    if (rst) begin
        oweight_req_per_row_cnt <= 0;
    end
    else if (oweight_req_per_row_reg) begin
        oweight_req_per_row_cnt <= (oweight_req_per_row_cnt_max_vld) ? 0 : oweight_req_per_row_cnt + 1'b1;
    end
end

always @(posedge clk) begin
    if (rst | oweight_req_per_row_cnt_max_vld) begin
        oweight_req_per_row_reg <= 1'b0;
    end
    else if (enb & (!weight_init | odata_req_cnt_premax_vld)) begin
        oweight_req_per_row_reg <= 1'b1;
    end
end

assign o_weight_req = oweight_req_per_row_reg & ~done;

reg idata_end_req_vld_pp;
always @(posedge clk) begin
    idata_end_req_vld_pp <= idata_end_req_vld;
end

assign i_weight_req = (init) ? buffer_o_weight_full : idata_end_req_vld_pp & buffer_o_weight_full;

assign weight_line_done_cnt_max_vld = weight_line_done_cnt == i_cnfx_kernelwidth;

always @(posedge clk) begin
    if (rst) begin
        weight_line_done_cnt <= 0;
    end
    else if (i_weight_req) begin
        weight_line_done_cnt <= (weight_line_done_cnt_max_vld) ? 1'b1 : weight_line_done_cnt + 1'b1;
    end
end

// Done control
assign weight_done_cnt_max_vld = (weight_done_cnt == i_conf_kernelsize[7 : 0]);

always @(posedge clk) begin
    if (rst) begin
        weight_done_cnt <= 0;
    end
    else if (i_weight_req) begin
        weight_done_cnt <= (weight_done_cnt_max_vld) ? 8'd3 : weight_done_cnt + 2'd3;
    end
end


assign kernel_done_cnt_max_vld = (kernel_done_cnt == (i_conf_kernelshape[31 : 16] - 3'd4));
assign kernel_end = weight_done_cnt_max_vld & idata_end_req_vld;

always @(posedge clk) begin
    if (rst | init) begin
        kernel_done_cnt <= 0;
    end if (kernel_end) begin
        kernel_done_cnt <= (kernel_done_cnt_max_vld) ? 0 : kernel_done_cnt + 3'd4;
    end
end

always @(posedge clk) begin
    if (rst | init | con_enb_vld) begin
        done <= 0;
    end
    else if (kernel_done_cnt_max_vld & kernel_end) begin
        done <= 1'b1;
    end
end

assign o_done = done;

//////////////////////////////////////////////////////////////////////////////////
// Error monitor

assign dbg_linekcpe_valid_knx_cnt = {24'b0, valid_knx_cnt};
assign dbg_linekcpe_psum_line_vld_cnt = psum_line_vld_cnt;
assign dbg_linekcpe_idata_req_cnt = idata_req_cnt;
assign dbg_linekcpe_odata_req_cnt = odata_req_cnt;
assign dbg_linekcpe_weight_line_req_cnt = {29'b0, oweight_req_per_row_cnt};
assign dbg_linekcpe_weight_done_cnt = {24'b0, weight_done_cnt};
assign dbg_linekcpe_kernel_done_cnt = kernel_done_cnt;

endmodule
