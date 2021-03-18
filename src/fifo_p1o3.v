`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 03/18/2021 01:42:34 PM
// Design Name: FIFO pop 1 out 3
// Module Name: fifo_p1o3
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: A FIFO which can read 3 data at a time then remove the first data.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo_p1o3(
    clk,
    rst,
    wr_req,
    wr_data,
    rd_req,
    rd_data,
    rd_data_val,
    data_counter,
    full,
    empty
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter NUM_RDATA     = 3;
parameter DAT_WIDTH     = 8;
parameter FF_DEPTH      = 8;
parameter FF_ADDR_WIDTH = 3;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input  wire                                 clk;
input  wire                                 rst;
input  wire                                 wr_req;
input  wire [DAT_WIDTH - 1 : 0]             wr_data;
input  wire                                 rd_req;
output wire [DAT_WIDTH * NUM_RDATA - 1 : 0] rd_data;
output wire                                 rd_data_val;
output wire [FF_ADDR_WIDTH - 1 : 0]         data_counter;
output wire                                 full;
output wire                                 empty;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [DAT_WIDTH - 1 : 0] ff_mem [FF_DEPTH - 1 : 0];
reg [FF_ADDR_WIDTH : 0] wr_ptr;
reg [FF_ADDR_WIDTH : 0] rd_ptr;
reg [DAT_WIDTH - 1 : 0] rd_data_reg [NUM_RDATA - 1 : 0];

wire [FF_ADDR_WIDTH - 1 : 0] wr_addr;
wire [FF_ADDR_WIDTH - 1 : 0] rd_addr;
wire wr_enb;
wire rd_enb;

// Read/write address
assign rd_addr = rd_ptr[FF_ADDR_WIDTH - 1 : 0];
assign wr_addr = wr_ptr[FF_ADDR_WIDTH - 1 : 0];

// FIFO full, empty
assign full  = (wr_ptr[FF_ADDR_WIDTH] != rd_ptr[FF_ADDR_WIDTH]) && (wr_addr == rd_addr);
assign empty = (wr_ptr == rd_ptr);

// Enable to prevent write when full, read when empty
assign wr_enb = ~full  & wr_req;
assign rd_enb = ~empty & rd_req;

// FIFO Data counter
reg [FF_ADDR_WIDTH - 1 : 0] data_counter_reg;
always @(posedge clk) begin
    if (rst) begin
        data_counter_reg <= 0;
    end
    else if (wr_enb & rd_enb) begin
        data_counter_reg <= data_counter_reg;
    end
    else if (wr_enb) begin
        data_counter_reg <= data_counter_reg + 1'b1;
    end
    else if (rd_enb) begin
        data_counter_reg <= data_counter_reg - 1'b1;
    end
end

assign data_counter = data_counter_reg;

// Write data
always @(posedge clk) begin
    if (rst) begin
        ff_mem[0] <= 0;
        ff_mem[1] <= 0;
        ff_mem[2] <= 0;
        ff_mem[3] <= 0;
        ff_mem[4] <= 0;
        ff_mem[5] <= 0;
        ff_mem[6] <= 0;
        ff_mem[7] <= 0;
    end
    else if (wr_enb) begin
        ff_mem[wr_addr] <= wr_data;
        wr_ptr          <= wr_ptr + 1'b1;
    end
end

// Read 3 data
always @(posedge clk) begin
    if (rd_enb) begin
        rd_data_reg[0]  <= ff_mem[rd_addr];
        rd_data_reg[1]  <= ff_mem[rd_addr + 1'b1];
        rd_data_reg[2]  <= ff_mem[rd_addr + 'd2];
        rd_ptr          <= rd_ptr + 1'b1;
    end
    else begin
        rd_data_reg[0]  <= 0;
        rd_data_reg[1]  <= 0;
        rd_data_reg[2]  <= 0;
    end
end

// Read data out
assign rd_data = {rd_data_reg[2], rd_data_reg[1], rd_data_reg[0]};

endmodule
