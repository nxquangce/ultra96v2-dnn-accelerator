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
    memctrl0_ovld,

    i_conf_ctrl,
    i_conf_weightinterval,
    i_conf_outputsize,
    i_conf_inputshape,
    i_conf_kernelshape,
    i_conf_outputshape,
    i_cnfx_stride,
    i_cnfx_padding,
    o_done,

    dbg_psumacc_base_addr,
    dbg_psumacc_psum_out_cnt,
    dbg_psumacc_rd_addr,
    dbg_psumacc_wr_addr,
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter BIT_WIDTH     = 8;
parameter REG_WIDTH     = 32;

parameter DATA_WIDTH    = 32;
parameter ADDR_WIDTH    = 32;
parameter MEM_DELAY     = 1;

parameter NUM_KERNEL    = 4;

parameter STRIDE_WIDTH          = 4;
parameter PADDING_WIDTH         = 4;
parameter OUTPUT_SHAPE_WIDTH    = 16;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                          clk;
input                          rst;
input      [BIT_WIDTH - 1 : 0] psum_kn0_dat;
input      [BIT_WIDTH - 1 : 0] psum_kn1_dat;
input      [BIT_WIDTH - 1 : 0] psum_kn2_dat;
input      [BIT_WIDTH - 1 : 0] psum_kn3_dat;
input                          psum_kn0_vld;
input                          psum_kn1_vld;
input                          psum_kn2_vld;
input                          psum_kn3_vld;
input                          psum_knx_end;

output    [ADDR_WIDTH - 1 : 0] memctrl0_wadd;
output                         memctrl0_wren;
output    [DATA_WIDTH - 1 : 0] memctrl0_idat;
output    [ADDR_WIDTH - 1 : 0] memctrl0_radd;
output                         memctrl0_rden;
input     [DATA_WIDTH - 1 : 0] memctrl0_odat;
input                          memctrl0_ovld;

input      [REG_WIDTH - 1 : 0] i_conf_ctrl;
input      [REG_WIDTH - 1 : 0] i_conf_weightinterval;
input      [REG_WIDTH - 1 : 0] i_conf_outputsize;
input      [REG_WIDTH - 1 : 0] i_conf_inputshape;
input      [REG_WIDTH - 1 : 0] i_conf_kernelshape;
input      [REG_WIDTH - 1 : 0] i_conf_outputshape;
input   [STRIDE_WIDTH - 1 : 0] i_cnfx_stride;
input  [PADDING_WIDTH - 1 : 0] i_cnfx_padding;
output                         o_done;

output     [REG_WIDTH - 1 : 0] dbg_psumacc_base_addr;
output     [REG_WIDTH - 1 : 0] dbg_psumacc_psum_out_cnt;
output     [REG_WIDTH - 1 : 0] dbg_psumacc_rd_addr;
output     [REG_WIDTH - 1 : 0] dbg_psumacc_wr_addr;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [ADDR_WIDTH - 1 : 0] base_addr;
reg [ADDR_WIDTH - 1 : 0] rd_addr;
reg [ADDR_WIDTH - 1 : 0] wr_addr;
reg                      wr_enab;
reg [ADDR_WIDTH - 1 : 0] addr_cache [MEM_DELAY - 1 : 0];
reg  [BIT_WIDTH - 1 : 0] psum_cache [NUM_KERNEL - 1 : 0][MEM_DELAY - 1 : 0];
reg  [BIT_WIDTH - 1 : 0] wdat_cache [NUM_KERNEL - 1 : 0];

reg  [REG_WIDTH - 1 : 0] psum_out_cnt;
wire                     psum_out_cnt_max_vld;
wire                     psum_out_cnt_premax_vld;

reg  [MEM_DELAY     : 0] psum_out_cnt_max_vld_pp;

reg                      con_enb;
reg                      con_enb_cache;
reg                      con_enb_vld;
reg                      con_enb_vld_pp;
reg                      psum_zero_enb;

reg [PADDING_WIDTH - 1 : 0] pad_sta;
reg [PADDING_WIDTH - 1 : 0] pad_end;

wire [7:0]                output_width;
wire [ADDR_WIDTH - 1 : 0] pad_sta_addr;

// Status
reg                     init;
reg                     done;
reg [REG_WIDTH - 1 : 0] kernel_done_cnt;
reg [REG_WIDTH - 1 : 0] kernel_done_cnt_max_reg;
wire                    kernel_done_cnt_max_vld;
wire                    done_vld;

reg [MEM_DELAY - 1 : 0] psum_knx_end_pp;
wire                    psum_knx_end_pp_vld;


// Detect rising edge of continue enable conf
always @(posedge clk) begin
    con_enb_vld <= ~con_enb_cache & con_enb;
    con_enb_vld_pp <= con_enb_vld;
end

always @(posedge clk) begin
    pad_sta = i_cnfx_padding >> 1;
    pad_end = i_cnfx_padding - (i_cnfx_padding >> 1);
end

wire [3 : 0] pad_sta_row;
wire [3 : 0] pad_row;
assign output_width = i_conf_outputshape[7:0];
assign pad_sta_row  = pad_sta - i_cnfx_stride + 1'b1;
assign pad_sta_addr = (pad_sta_row == 4'd0) ? 0:
                      (pad_sta_row == 4'd1) ? output_width :
                      (pad_sta_row == 4'd2) ? output_width << 1 : 0;

wire [REG_WIDTH - 1 : 0] psum_out_cnt_max;
reg  [REG_WIDTH - 1 : 0] num_skip_interval;

// fix timing
always @(posedge clk) begin
    num_skip_interval <= (i_cnfx_padding == 4'd0) ? 0 :
                         (i_cnfx_padding == 4'd1) ? output_width :
                         (i_cnfx_padding == 4'd2) ? output_width << 1:
                         (i_cnfx_padding == 4'd3) ? output_width << 1 + output_width :
                         (i_cnfx_padding == 4'd4) ? output_width << 2 : 0;
end

assign psum_out_cnt_max = i_conf_weightinterval - num_skip_interval;
assign psum_out_cnt_max_vld = (psum_out_cnt == psum_out_cnt_max);
assign psum_out_cnt_premax_vld = (psum_out_cnt == (psum_out_cnt_max - 1'b1)) & psum_kn0_vld;

always @(posedge clk) begin
    if (rst) begin
        psum_out_cnt <= 0;
    end
    else if (psum_kn0_vld) begin
        psum_out_cnt <= (psum_out_cnt_max_vld) ? 0 : psum_out_cnt + 1'b1;
    end
end

always @(posedge clk) begin
    if (rst | con_enb_vld) begin
        base_addr <= 0;
    end
    else if (psum_out_cnt_premax_vld) begin
        base_addr <= base_addr + i_conf_outputsize + 1'b1;
    end
end

wire output_end_vld;
assign output_end_vld = psum_out_cnt_max_vld & psum_kn0_vld;

always @(posedge clk) begin
    if (rst | output_end_vld) begin
        rd_addr <= base_addr + pad_sta_addr;
    end
    else if(psum_knx_end | con_enb_vld_pp) begin
        rd_addr <= base_addr;
    end
    else if (psum_kn0_vld) begin
        rd_addr <= rd_addr + 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        wr_addr <= 0;
        addr_cache[0] <= 0;
        addr_cache[1] <= 0;
    end
    else begin
        addr_cache[0] <= rd_addr;
        addr_cache[1] <= addr_cache[0];
        wr_addr <= addr_cache[MEM_DELAY - 1];
    end
end

assign memctrl0_rden = psum_kn0_vld;
assign memctrl0_radd = rd_addr;
assign memctrl0_wadd = wr_addr;

always @(posedge clk) begin
    if (rst) begin
        psum_cache[0][0] <= 0;
        psum_cache[1][0] <= 0;
        psum_cache[2][0] <= 0;
        psum_cache[3][0] <= 0;
    end
    else begin
        psum_cache[0][0] <= psum_kn0_dat;
        psum_cache[1][0] <= psum_kn1_dat;
        psum_cache[2][0] <= psum_kn2_dat;
        psum_cache[3][0] <= psum_kn3_dat;
    end
end

always @(posedge clk) begin
    if (rst) begin
        psum_cache[0][1] <= 0;
        psum_cache[1][1] <= 0;
        psum_cache[2][1] <= 0;
        psum_cache[3][1] <= 0;
    end
    else begin
        psum_cache[0][1] <= psum_cache[0][0];
        psum_cache[1][1] <= psum_cache[1][0];
        psum_cache[2][1] <= psum_cache[2][0];
        psum_cache[3][1] <= psum_cache[3][0];
    end
end

always @(posedge clk) begin
    if (rst) begin
        wdat_cache[0] <= 0;
        wdat_cache[1] <= 0;
        wdat_cache[2] <= 0;
        wdat_cache[3] <= 0;
    end
    else if (psum_zero_enb) begin
        wdat_cache[0] <= psum_cache[0][MEM_DELAY - 1];
        wdat_cache[1] <= psum_cache[1][MEM_DELAY - 1];
        wdat_cache[2] <= psum_cache[2][MEM_DELAY - 1];
        wdat_cache[3] <= psum_cache[3][MEM_DELAY - 1];
    end
    else if (memctrl0_ovld) begin
        wdat_cache[0] <= memctrl0_odat[BIT_WIDTH * 1 - 1 :             0] + psum_cache[0][MEM_DELAY - 1];
        wdat_cache[1] <= memctrl0_odat[BIT_WIDTH * 2 - 1 : BIT_WIDTH * 1] + psum_cache[1][MEM_DELAY - 1];
        wdat_cache[2] <= memctrl0_odat[BIT_WIDTH * 3 - 1 : BIT_WIDTH * 2] + psum_cache[2][MEM_DELAY - 1];
        wdat_cache[3] <= memctrl0_odat[BIT_WIDTH * 4 - 1 : BIT_WIDTH * 3] + psum_cache[3][MEM_DELAY - 1];
    end
end

always @(posedge clk) begin
    wr_enab <= memctrl0_ovld;
end

assign memctrl0_idat = {wdat_cache[3], wdat_cache[2], wdat_cache[1], wdat_cache[0]};
assign memctrl0_wren = wr_enab;

// Status
always @(posedge clk) begin
    con_enb <= i_conf_ctrl[4];
    con_enb_cache <= con_enb;
end

always @(posedge clk) begin
    psum_knx_end_pp[0] <= psum_knx_end;
    psum_knx_end_pp[1] <= psum_knx_end_pp[0];
end

assign psum_knx_end_pp_vld = psum_knx_end_pp[MEM_DELAY - 1];

always @(posedge clk) begin
    psum_out_cnt_max_vld_pp[0] <= kernel_done_vld; // psum_out_cnt_max_vld;
    psum_out_cnt_max_vld_pp[1] <= psum_out_cnt_max_vld_pp[0];
    psum_out_cnt_max_vld_pp[2] <= psum_out_cnt_max_vld_pp[1];
end

// zero vld signal to force read data zeros at first psum values
wire psum_zero_enb_vld;
wire pad_skip_end;
wire pad_skip_vld;
reg psum_zero_enb_vld_pp;
reg pad_skip_reg;
reg [ADDR_WIDTH - 1 : 0] pad_skip_addr;

assign pad_skip_vld = psum_zero_enb & (addr_cache[MEM_DELAY - 1] != base_addr) & psum_zero_enb_vld_pp;

always @(posedge clk) begin
    if (rst | pad_skip_end) begin
        pad_skip_reg <= 0;
    end
    else if (~pad_skip_reg) begin
        pad_skip_reg <= pad_skip_vld;
    end
end

always @(posedge clk) begin
    if (rst) begin
        pad_skip_addr <= 0;
    end
    else if ((~pad_skip_reg) & pad_skip_vld) begin
        pad_skip_addr <= addr_cache[MEM_DELAY - 1];
    end
end

assign psum_zero_enb_vld = (psum_out_cnt_max_vld_pp[MEM_DELAY]) | con_enb_vld | init;
assign pad_skip_end      = pad_skip_reg & (addr_cache[MEM_DELAY - 1] == (pad_skip_addr - 1'b1));

always @(posedge clk) begin
    psum_zero_enb_vld_pp <= psum_zero_enb_vld;
end

always @(posedge clk) begin
    if (rst | (psum_knx_end_pp_vld & (~pad_skip_reg)) | pad_skip_end) begin
        psum_zero_enb <= 0;
    end
    else if (psum_zero_enb_vld) begin
        psum_zero_enb <= 1'b1;
    end
end

// fix timming
always @(posedge clk) begin
    kernel_done_cnt_max_reg <= i_conf_kernelshape[31 : 16] - 3'd4;
end

wire kernel_done_vld;
assign kernel_done_vld = psum_out_cnt_max_vld & psum_kn0_vld;

assign kernel_done_cnt_max_vld = (kernel_done_cnt == kernel_done_cnt_max_reg);
assign done_vld = kernel_done_cnt_max_vld & kernel_done_vld;

always @(posedge clk) begin
    if (rst | init) begin
        kernel_done_cnt <= 0;
    end
    else if (kernel_done_vld) begin
        kernel_done_cnt <= (kernel_done_cnt_max_vld) ? 0 : kernel_done_cnt + 3'd4;
    end
end

always @(posedge clk) begin
    if (rst) begin
        init <= 1;
    end
    else if (psum_kn0_vld) begin
        init <= 0;
    end
end

always @(posedge clk) begin
    if (rst | init | con_enb) begin
        done <= 0;
    end
    else if (done_vld) begin
        done <= 1'b1;
    end
end

assign o_done = done;

// Debug
assign dbg_psumacc_base_addr = base_addr;
assign dbg_psumacc_psum_out_cnt = psum_out_cnt;
assign dbg_psumacc_rd_addr = rd_addr;
assign dbg_psumacc_wr_addr = wr_addr;

endmodule
