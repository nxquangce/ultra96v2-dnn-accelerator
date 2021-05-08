`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 05/04/2021 07:25:30 PM
// Design Name: Weight request
// Module Name: weight_req
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: Generate read signal to weight brams and return aligned data
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module weight_req(
    clk,
    rst,
    i_req,
    o_dat,
    o_vld,
    memx_addr,
    memx_rden,
    mem0_odat,
    mem0_oval,
    mem1_odat,
    mem1_oval,
    mem2_odat,
    mem2_oval,
    mem3_odat,
    mem3_oval
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter MEM_DATA_WIDTH    = 32;
parameter MEM_ADDR_WIDTH    = 32;

parameter BIT_WIDTH         = 8;
parameter NUM_CHANNEL       = 3;
parameter NUM_KERNEL        = 4;
parameter NUM_KCPE          = 3;    // Number of kernel-channel PE
parameter DAT_WIDTH         = BIT_WIDTH * NUM_CHANNEL;

parameter REG_WIDTH         = 32;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                                                   clk;
input                                                   rst;
input                                                   i_req;
output [(BIT_WIDTH * NUM_CHANNEL * NUM_KERNEL) - 1 : 0] o_dat;
output                                                  o_vld;
output                         [MEM_ADDR_WIDTH - 1 : 0] memx_addr;
output                                                  memx_rden;
input                          [MEM_DATA_WIDTH - 1 : 0] mem0_odat;
input                          [MEM_DATA_WIDTH - 1 : 0] mem1_odat;
input                          [MEM_DATA_WIDTH - 1 : 0] mem2_odat;
input                          [MEM_DATA_WIDTH - 1 : 0] mem3_odat;
input                                                   mem0_oval;
input                                                   mem1_oval;
input                                                   mem2_oval;
input                                                   mem3_oval;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg      [MEM_ADDR_WIDTH - 1 : 0] addr;
reg           [DAT_WIDTH - 1 : 0] odata_reg_p0 [NUM_KERNEL - 1 : 0];
reg      [MEM_DATA_WIDTH - 1 : 0] cache_reg_p1 [NUM_KERNEL - 1 : 0];
reg                       [1 : 0] state;
reg                       [1 : 0] next_state;
reg                               req_reg;
wire [MEM_DATA_WIDTH * 2 - 1 : 0] memx_dat_concat [NUM_KERNEL - 1 : 0];
wire                              vld_stall;
wire                              req_stall;

always @(posedge clk) begin
    if (rst) begin
        addr <= 0;
    end
    else if (memx_rden) begin
        addr <= addr + 1'b1;
    end
end

assign memx_rden = i_req & ~req_stall;
assign memx_addr = addr;

always @(posedge clk) begin
    if (rst) begin
        cache_reg_p1[0] <= 0;
        cache_reg_p1[1] <= 0;
        cache_reg_p1[2] <= 0;
        cache_reg_p1[3] <= 0;
    end
    else begin
        if (mem0_oval) begin
            cache_reg_p1[0] <= mem0_odat;
        end
        if (mem1_oval) begin
            cache_reg_p1[1] <= mem1_odat;
        end
        if (mem2_oval) begin
            cache_reg_p1[2] <= mem2_odat;
        end
        if (mem3_oval) begin
            cache_reg_p1[3] <= mem3_odat;
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        req_reg <= 0;
    end
    else begin
        req_reg <= i_req;
    end
end

always @(posedge clk) begin
    if (rst) begin
        state <= 2'b00;
    end
    else if (o_vld) begin
        state <= state + 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        next_state <= 2'b00;
    end
    else if (i_req) begin
        next_state <= next_state + 1'b1;
    end
end

assign vld_stall = (state == 2'b11);
assign req_stall = (next_state == 2'b11);

assign memx_dat_concat[0] = {mem0_odat, cache_reg_p1[0]};
assign memx_dat_concat[1] = {mem1_odat, cache_reg_p1[1]};
assign memx_dat_concat[2] = {mem2_odat, cache_reg_p1[2]};
assign memx_dat_concat[3] = {mem3_odat, cache_reg_p1[3]};

always @(*) begin
    case (state)
        2'b00: begin
            odata_reg_p0[0] = memx_dat_concat[0][8 * 7 - 1 : 8 * 4];
            odata_reg_p0[1] = memx_dat_concat[1][8 * 7 - 1 : 8 * 4];
            odata_reg_p0[2] = memx_dat_concat[2][8 * 7 - 1 : 8 * 4];
            odata_reg_p0[3] = memx_dat_concat[3][8 * 7 - 1 : 8 * 4];
        end
        2'b01: begin
            odata_reg_p0[0] = memx_dat_concat[0][8 * 6 - 1 : 8 * 3];
            odata_reg_p0[1] = memx_dat_concat[1][8 * 6 - 1 : 8 * 3];
            odata_reg_p0[2] = memx_dat_concat[2][8 * 6 - 1 : 8 * 3];
            odata_reg_p0[3] = memx_dat_concat[3][8 * 6 - 1 : 8 * 3];
        end
        2'b10: begin
            odata_reg_p0[0] = memx_dat_concat[0][8 * 5 - 1 : 8 * 2];
            odata_reg_p0[1] = memx_dat_concat[1][8 * 5 - 1 : 8 * 2];
            odata_reg_p0[2] = memx_dat_concat[2][8 * 5 - 1 : 8 * 2];
            odata_reg_p0[3] = memx_dat_concat[3][8 * 5 - 1 : 8 * 2];
        end
        2'b11: begin
            odata_reg_p0[0] = memx_dat_concat[0][8 * 8 - 1 : 8 * 5];    // due to stall
            odata_reg_p0[1] = memx_dat_concat[1][8 * 8 - 1 : 8 * 5];    // due to stall
            odata_reg_p0[2] = memx_dat_concat[2][8 * 8 - 1 : 8 * 5];    // due to stall
            odata_reg_p0[3] = memx_dat_concat[3][8 * 8 - 1 : 8 * 5];    // due to stall
        end
        default: begin
            odata_reg_p0[0] = 0;
            odata_reg_p0[1] = 0;
            odata_reg_p0[2] = 0;
            odata_reg_p0[3] = 0;
        end
    endcase
end

assign o_dat = {odata_reg_p0[3], odata_reg_p0[2], odata_reg_p0[1], odata_reg_p0[0]};
assign o_vld = mem0_oval | (req_reg & vld_stall);

endmodule
