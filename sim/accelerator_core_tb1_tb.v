`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 04/30/2021 10:59:07 PM
// Design Name: 
// Module Name: accelerator_core_tb1_tb
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: accelerator core test bench with data req, bram sim
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module accelerator_core_tb1_tb;

parameter BIT_WIDTH     = 8;
parameter NUM_CHANNEL   = 3;
parameter NUM_KERNEL    = 4;
parameter NUM_KCPE      = 3;    // Number of kernel-channel PE
parameter REG_WIDTH     = 32;

parameter NUM_RDATA     = 3;

parameter ADDR_WIDTH    = 32;
parameter DATA_WIDTH    = 32;

reg clk;
reg rst;
wire                                                  o_data_req;
wire                                                  o_data_end;
wire                                                  o_weight_req;
wire [(BIT_WIDTH * NUM_CHANNEL             ) - 1 : 0] i_data;
wire [(BIT_WIDTH * NUM_CHANNEL * NUM_KERNEL) - 1 : 0] i_weight;
wire                                                  i_data_val;
wire                                                  i_weight_val;
// wire [BIT_WIDTH - 1 : 0]                              o_psum_kn0;
// wire [BIT_WIDTH - 1 : 0]                              o_psum_kn1;
// wire [BIT_WIDTH - 1 : 0]                              o_psum_kn2;
// wire [BIT_WIDTH - 1 : 0]                              o_psum_kn3;
// wire                                                  o_psum_kn0_val;
// wire                                                  o_psum_kn1_val;
// wire                                                  o_psum_kn2_val;
// wire                                                  o_psum_kn3_val;

wire                             [ADDR_WIDTH - 1 : 0] memctrl0_wadd;
wire                                                  memctrl0_wren;
wire                             [DATA_WIDTH - 1 : 0] memctrl0_idat;
wire                             [ADDR_WIDTH - 1 : 0] memctrl0_radd;
wire                                                  memctrl0_rden;
wire                             [DATA_WIDTH - 1 : 0] memctrl0_odat;
wire                                                  memctrl0_oval;

reg [REG_WIDTH - 1 : 0]                               i_conf_ctrl;
reg [REG_WIDTH - 1 : 0]                               i_conf_cnt;
reg [REG_WIDTH - 1 : 0]                               i_conf_knx;
reg [REG_WIDTH - 1 : 0]                               i_conf_weightinterval;
reg [REG_WIDTH - 1 : 0]                               i_conf_kernelshape;
reg [REG_WIDTH - 1 : 0]                               i_conf_inputshape;
reg [REG_WIDTH - 1 : 0]                               i_conf_inputrstcnt;


accelerator_core uut(
    .clk                    (clk),
    .rst                    (rst),
    .o_data_req             (o_data_req),
    .o_data_end             (o_data_end),
    .i_data                 (i_data),
    .i_data_val             (i_data_val),
    .o_weight_req           (o_weight_req),
    .i_weight               (i_weight),
    .i_weight_val           (i_weight_val),
    // .o_psum_kn0             (o_psum_kn0),
    // .o_psum_kn0_val         (o_psum_kn0_val),
    // .o_psum_kn1             (o_psum_kn1),
    // .o_psum_kn1_val         (o_psum_kn1_val),
    // .o_psum_kn2             (o_psum_kn2),
    // .o_psum_kn2_val         (o_psum_kn2_val),
    // .o_psum_kn3             (o_psum_kn3),
    // .o_psum_kn3_val         (o_psum_kn3_val),
    .memctrl0_wadd          (memctrl0_wadd),
    .memctrl0_wren          (memctrl0_wren),
    .memctrl0_idat          (memctrl0_idat),
    .memctrl0_radd          (memctrl0_radd),
    .memctrl0_rden          (memctrl0_rden),
    .memctrl0_odat          (memctrl0_odat),
    .memctrl0_oval          (memctrl0_oval),
    .i_conf_ctrl            (i_conf_ctrl),
    .i_conf_cnt             (i_conf_cnt),
    .i_conf_knx             (i_conf_knx),
    .i_conf_weightinterval  (i_conf_weightinterval),
    .i_conf_kernelshape     (i_conf_kernelshape),
    .i_conf_inputshape      (i_conf_inputshape),
    .i_conf_inputrstcnt     (i_conf_inputrstcnt)
    );

wire                      stall;
wire [ADDR_WIDTH - 1 : 0] addr;
wire                      rden;
wire [DATA_WIDTH - 1 : 0] raw_rd_data;
wire [DATA_WIDTH - 1 : 0] mem_rd_data;
wire                      raw_rd_vld;
wire [ADDR_WIDTH - 1 : 0] mem_rd_addr;

data_req data_req0(
    .clk        (clk),
    .rst        (rst),
    .i_req      (o_data_req),
    .i_stall    (stall),
    .i_end      (o_data_end),
    .o_addr     (addr),
    .o_rden     (rden)
    );

bram_ctrl bram_ctrl0(
    .clk        (clk),
    .rst        (rst),
    .addr       (addr),
    .wren       (0),
    .idat       (0),
    .rden       (rden),
    .odat       (raw_rd_data),
    .oval       (raw_rd_vld),
    .mem_addr   (mem_rd_addr),
    .mem_idat   (),
    .mem_odat   (mem_rd_data),
    .mem_enb    (),
    .mem_rst    (),
    .mem_wren   ()
    );

data_bram_tb_sim bram0(
    .clk        (clk),
    .rst        (rst),
    .irdaddr    (mem_rd_addr),
    .odat       (mem_rd_data)
    );

pixel_concat concat(
    .clk        (clk),
    .rst        (rst),
    .idat       (raw_rd_data),
    .ival       (raw_rd_vld),
    .odat       (i_data),
    .oval       (i_data_val),
    .ostall     (stall)
    );

wire [ADDR_WIDTH - 1 : 0] memx_weight_addr;
wire                      memx_weight_rden;

wire [DATA_WIDTH - 1 : 0] memctrl0_weight_odat;
wire [DATA_WIDTH - 1 : 0] memctrl1_weight_odat;
wire [DATA_WIDTH - 1 : 0] memctrl2_weight_odat;
wire [DATA_WIDTH - 1 : 0] memctrl3_weight_odat;

wire                      memctrl0_weight_oval;
wire                      memctrl1_weight_oval;
wire                      memctrl2_weight_oval;
wire                      memctrl3_weight_oval;

wire [ADDR_WIDTH - 1 : 0] mem0_weight_addr;
wire [ADDR_WIDTH - 1 : 0] mem1_weight_addr;
wire [ADDR_WIDTH - 1 : 0] mem2_weight_addr;
wire [ADDR_WIDTH - 1 : 0] mem3_weight_addr;

wire [DATA_WIDTH - 1 : 0] mem0_weight_odat;
wire [DATA_WIDTH - 1 : 0] mem1_weight_odat;
wire [DATA_WIDTH - 1 : 0] mem2_weight_odat;
wire [DATA_WIDTH - 1 : 0] mem3_weight_odat;

weight_req weight_req_eng(
    .clk        (clk),
    .rst        (rst),
    .i_req      (o_weight_req),
    .o_dat      (i_weight),
    .o_vld      (i_weight_val),
    .memx_addr  (memx_weight_addr),
    .memx_rden  (memx_weight_rden),
    .mem0_odat  (memctrl0_weight_odat),
    .mem0_oval  (memctrl0_weight_oval),
    .mem1_odat  (memctrl1_weight_odat),
    .mem1_oval  (memctrl1_weight_oval),
    .mem2_odat  (memctrl2_weight_odat),
    .mem2_oval  (memctrl2_weight_oval),
    .mem3_odat  (memctrl3_weight_odat),
    .mem3_oval  (memctrl3_weight_oval)
    );

bram_ctrl bram_ctrl_weight0(
    .clk        (clk),
    .rst        (rst),
    .addr       (memx_weight_addr),
    .rden       (memx_weight_rden),
    .wren       (0),
    .idat       (0),
    .odat       (memctrl0_weight_odat),
    .oval       (memctrl0_weight_oval),
    .mem_addr   (mem0_weight_addr),
    .mem_odat   (mem0_weight_odat),
    .mem_idat   (),
    .mem_enb    (),
    .mem_rst    (),
    .mem_wren   ()
    );

data_bram_tb_sim bram_weight0(
    .clk        (clk),
    .rst        (rst),
    .irdaddr    (mem0_weight_addr),
    .odat       (mem0_weight_odat)
    );

bram_ctrl bram_ctrl_weight1(
    .clk        (clk),
    .rst        (rst),
    .addr       (memx_weight_addr),
    .rden       (memx_weight_rden),
    .wren       (0),
    .idat       (0),
    .odat       (memctrl1_weight_odat),
    .oval       (memctrl1_weight_oval),
    .mem_addr   (mem1_weight_addr),
    .mem_odat   (mem1_weight_odat),
    .mem_idat   (),
    .mem_enb    (),
    .mem_rst    (),
    .mem_wren   ()
    );

data_bram_tb_sim bram_weight1(
    .clk        (clk),
    .rst        (rst),
    .irdaddr    (mem1_weight_addr),
    .odat       (mem1_weight_odat)
    );

bram_ctrl bram_ctrl_weight2(
    .clk        (clk),
    .rst        (rst),
    .addr       (memx_weight_addr),
    .rden       (memx_weight_rden),
    .wren       (0),
    .idat       (0),
    .odat       (memctrl2_weight_odat),
    .oval       (memctrl2_weight_oval),
    .mem_addr   (mem2_weight_addr),
    .mem_odat   (mem2_weight_odat),
    .mem_idat   (),
    .mem_enb    (),
    .mem_rst    (),
    .mem_wren   ()
    );

data_bram_tb_sim bram_weight2(
    .clk        (clk),
    .rst        (rst),
    .irdaddr    (mem2_weight_addr),
    .odat       (mem2_weight_odat)
    );

bram_ctrl bram_ctrl_weight3(
    .clk        (clk),
    .rst        (rst),
    .addr       (memx_weight_addr),
    .rden       (memx_weight_rden),
    .wren       (0),
    .idat       (0),
    .odat       (memctrl3_weight_odat),
    .oval       (memctrl3_weight_oval),
    .mem_addr   (mem3_weight_addr),
    .mem_odat   (mem3_weight_odat),
    .mem_idat   (),
    .mem_enb    (),
    .mem_rst    (),
    .mem_wren   ()
    );

data_bram_tb_sim bram_weight3(
    .clk        (clk),
    .rst        (rst),
    .irdaddr    (mem3_weight_addr),
    .odat       (mem3_weight_odat)
    );


// Psum BRAM
wire [ADDR_WIDTH - 1 : 0] mem_psum_raddr;
wire [ADDR_WIDTH - 1 : 0] mem_psum_waddr;
wire [DATA_WIDTH - 1 : 0] mem_psum_rdata;
wire [DATA_WIDTH - 1 : 0] mem_psum_wdata;
wire                      mem_psum_wrenb;

bram_ctrl psum_bram_ctrl_0(
    .clk        (clk),
    .rst        (rst),
    .addr       (memctrl0_radd),
    .wren       (0),
    .idat       (0),
    .rden       (memctrl0_rden),
    .odat       (memctrl0_odat),
    .oval       (memctrl0_oval),
    .mem_addr   (mem_psum_raddr),
    .mem_idat   (),
    .mem_odat   (mem_psum_rdata),
    .mem_enb    (),
    .mem_rst    (),
    .mem_wren   ()
    );

bram_ctrl psum_bram_ctrl_1(
    .clk        (clk),
    .rst        (rst),
    .addr       (memctrl0_wadd),
    .wren       (memctrl0_wren),
    .idat       (memctrl0_idat),
    .rden       (0),
    .odat       (),
    .oval       (),
    .mem_addr   (mem_psum_waddr),
    .mem_idat   (mem_psum_wdata),
    .mem_odat   (),
    .mem_enb    (),
    .mem_rst    (),
    .mem_wren   (mem_psum_wrenb)
    );

psum_bram_tb_sim psum_bram(
    .clk        (clk),
    .rst        (rst),
    .waddr      (mem_psum_waddr),
    .idat       (mem_psum_wdata),
    .wren       (mem_psum_wrenb),
    .raddr      (mem_psum_raddr),
    .odat       (mem_psum_rdata)
    );

accelerator_core_tb_data_gen weigth_stimulus(
    .clk            (clk),
    .rst            (rst),
    .o_data_req     (o_data_req),
    .i_data         (),
    .i_data_val     (),
    .o_weight_req   (),
    .i_weight       (),
    .i_weight_val   ()
    );

initial begin
    clk <= 0;
    forever begin
        #5 clk <= ~clk;
    end
end

initial begin
    rst <= 1;
    #20 rst <= 0;
end

localparam WEIGHT_INTERVAL = 50176 - 2 * 222;
initial begin
    i_conf_ctrl <= 0;
    i_conf_cnt <= 0;
    i_conf_knx <= 0;
    i_conf_weightinterval <= 0;
    i_conf_kernelshape <= 0;
    i_conf_inputshape <= 0;
    i_conf_inputrstcnt <= 0;

    #50 
    i_conf_ctrl <= 32'b1;
    i_conf_cnt <= 32'd50176;
    i_conf_knx <= 32'hffffffff;
    i_conf_weightinterval <= WEIGHT_INTERVAL;
    i_conf_kernelshape <= 32'h0020_0333;
    i_conf_inputshape <= 32'h0001_03e0;
    i_conf_inputrstcnt <= 32'd49283; // 222 * 222 - 1
end

endmodule