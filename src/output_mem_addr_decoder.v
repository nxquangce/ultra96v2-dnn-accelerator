`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 05/25/2021 05:15:42 PM
// Design Name: Output memory address decoder
// Module Name: output_mem_addr_decoder
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


module output_mem_addr_decoder(
    clk,

    psumctrl_wadd,
    psumctrl_wren,
    psumctrl_radd,
    psumctrl_rden,
    psumctrl_odat,
    psumctrl_ovld,

    bramctrl_addr_rd_0,
    bramctrl_rden_rd_0,
    bramctrl_odat_rd_0,
    bramctrl_oval_rd_0,
    bramctrl_addr_wr_0,
    bramctrl_wren_wr_0,

    bramctrl_addr_rd_1,
    bramctrl_rden_rd_1,
    bramctrl_odat_rd_1,
    bramctrl_oval_rd_1,
    bramctrl_addr_wr_1,
    bramctrl_wren_wr_1,

    bramctrl_addr_rd_2,
    bramctrl_rden_rd_2,
    bramctrl_odat_rd_2,
    bramctrl_oval_rd_2,
    bramctrl_addr_wr_2,
    bramctrl_wren_wr_2,

    bramctrl_addr_rd_3,
    bramctrl_rden_rd_3,
    bramctrl_odat_rd_3,
    bramctrl_oval_rd_3,
    bramctrl_addr_wr_3,
    bramctrl_wren_wr_3,

    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter ADDR_WIDTH        = 32;
parameter DATA_WIDTH        = 32;
parameter NUM_BYTE          = 4;

parameter MEM_DEPTH         = 32768;
parameter MEM_ADDR_WIDTH    = 15;
parameter NUM_MEM_WIDTH     = 2;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                       clk;

input  [ADDR_WIDTH - 1 : 0] psumctrl_wadd;
input                       psumctrl_wren;
input  [ADDR_WIDTH - 1 : 0] psumctrl_radd;
input                       psumctrl_rden;
output [DATA_WIDTH - 1 : 0] psumctrl_odat;
output                      psumctrl_ovld;

output [ADDR_WIDTH - 1 : 0] bramctrl_addr_rd_0;
output                      bramctrl_rden_rd_0;
input  [DATA_WIDTH - 1 : 0] bramctrl_odat_rd_0;
input                       bramctrl_oval_rd_0;
output [ADDR_WIDTH - 1 : 0] bramctrl_addr_wr_0;
output                      bramctrl_wren_wr_0;

output [ADDR_WIDTH - 1 : 0] bramctrl_addr_rd_1;
output                      bramctrl_rden_rd_1;
input  [DATA_WIDTH - 1 : 0] bramctrl_odat_rd_1;
input                       bramctrl_oval_rd_1;
output [ADDR_WIDTH - 1 : 0] bramctrl_addr_wr_1;
output                      bramctrl_wren_wr_1;

output [ADDR_WIDTH - 1 : 0] bramctrl_addr_rd_2;
output                      bramctrl_rden_rd_2;
input  [DATA_WIDTH - 1 : 0] bramctrl_odat_rd_2;
input                       bramctrl_oval_rd_2;
output [ADDR_WIDTH - 1 : 0] bramctrl_addr_wr_2;
output                      bramctrl_wren_wr_2;

output [ADDR_WIDTH - 1 : 0] bramctrl_addr_rd_3;
output                      bramctrl_rden_rd_3;
input  [DATA_WIDTH - 1 : 0] bramctrl_odat_rd_3;
input                       bramctrl_oval_rd_3;
output [ADDR_WIDTH - 1 : 0] bramctrl_addr_wr_3;
output                      bramctrl_wren_wr_3;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg  [DATA_WIDTH - 1 : 0] psumctrl_odat;
reg                       psumctrl_ovld;
reg  [ADDR_WIDTH - 1 : 0] bramctrl_addr_rd_0;
reg                       bramctrl_rden_rd_0;
reg  [ADDR_WIDTH - 1 : 0] bramctrl_addr_wr_0;
reg                       bramctrl_wren_wr_0;
reg  [ADDR_WIDTH - 1 : 0] bramctrl_addr_rd_1;
reg                       bramctrl_rden_rd_1;
reg  [ADDR_WIDTH - 1 : 0] bramctrl_addr_wr_1;
reg                       bramctrl_wren_wr_1;
reg  [ADDR_WIDTH - 1 : 0] bramctrl_addr_rd_2;
reg                       bramctrl_rden_rd_2;
reg  [ADDR_WIDTH - 1 : 0] bramctrl_addr_wr_2;
reg                       bramctrl_wren_wr_2;
reg  [ADDR_WIDTH - 1 : 0] bramctrl_addr_rd_3;
reg                       bramctrl_rden_rd_3;
reg  [ADDR_WIDTH - 1 : 0] bramctrl_addr_wr_3;
reg                       bramctrl_wren_wr_3;


wire [NUM_MEM_WIDTH - 1 : 0] bramctrl_rd_sel;
wire [NUM_MEM_WIDTH - 1 : 0] bramctrl_wr_sel;
wire    [ADDR_WIDTH - 1 : 0] bramctrl_rdaddr;
wire    [ADDR_WIDTH - 1 : 0] bramctrl_wraddr;

reg  [NUM_MEM_WIDTH - 1 : 0] bramctrl_rd_sel_cache;

assign bramctrl_rd_sel = psumctrl_radd[MEM_ADDR_WIDTH + NUM_MEM_WIDTH - 1 : MEM_ADDR_WIDTH];
assign bramctrl_rdaddr = {{(ADDR_WIDTH - MEM_ADDR_WIDTH){1'b0}}, psumctrl_radd[MEM_ADDR_WIDTH - 1 : 0]};

assign bramctrl_wr_sel = psumctrl_wadd[MEM_ADDR_WIDTH + NUM_MEM_WIDTH - 1 : MEM_ADDR_WIDTH];
assign bramctrl_wraddr = {{(ADDR_WIDTH - MEM_ADDR_WIDTH){1'b0}}, psumctrl_wadd[MEM_ADDR_WIDTH - 1 : 0]};

always @(posedge clk) begin
    if (psumctrl_rden) begin
        bramctrl_rd_sel_cache <= bramctrl_rd_sel;
    end
end

always @(*) begin
    bramctrl_addr_rd_0 = 0;
    bramctrl_rden_rd_0 = 0;
    bramctrl_addr_rd_1 = 0;
    bramctrl_rden_rd_1 = 0;
    bramctrl_addr_rd_2 = 0;
    bramctrl_rden_rd_2 = 0;
    bramctrl_addr_rd_3 = 0;
    bramctrl_rden_rd_3 = 0;

    case (bramctrl_rd_sel)
        2'b00: begin
            bramctrl_addr_rd_0 = bramctrl_rdaddr;
            bramctrl_rden_rd_0 = psumctrl_rden;
        end
        2'b01: begin
            bramctrl_addr_rd_1 = bramctrl_rdaddr;
            bramctrl_rden_rd_1 = psumctrl_rden;
        end
        2'b10: begin
            bramctrl_addr_rd_2 = bramctrl_rdaddr;
            bramctrl_rden_rd_2 = psumctrl_rden;
        end
        2'b11: begin
            bramctrl_addr_rd_3 = bramctrl_rdaddr;
            bramctrl_rden_rd_3 = psumctrl_rden;
        end
        default: begin
            bramctrl_addr_rd_0 = 0;
            bramctrl_rden_rd_0 = 0;
            bramctrl_addr_rd_1 = 0;
            bramctrl_rden_rd_1 = 0;
            bramctrl_addr_rd_2 = 0;
            bramctrl_rden_rd_2 = 0;
            bramctrl_addr_rd_3 = 0;
            bramctrl_rden_rd_3 = 0;
        end
    endcase
end

always @(posedge clk) begin
    case (bramctrl_rd_sel_cache)
        2'b00: psumctrl_odat <= bramctrl_odat_rd_0;
        2'b01: psumctrl_odat <= bramctrl_odat_rd_1;
        2'b10: psumctrl_odat <= bramctrl_odat_rd_2;
        2'b11: psumctrl_odat <= bramctrl_odat_rd_3;
        default: psumctrl_odat <= 0;
    endcase
    psumctrl_ovld <= bramctrl_oval_rd_0 | bramctrl_oval_rd_1 | bramctrl_oval_rd_2 | bramctrl_oval_rd_3;
end

always @(*) begin
    bramctrl_addr_wr_0 = 0;
    bramctrl_wren_wr_0 = 0;
    bramctrl_addr_wr_1 = 0;
    bramctrl_wren_wr_1 = 0;
    bramctrl_addr_wr_2 = 0;
    bramctrl_wren_wr_2 = 0;
    bramctrl_addr_wr_3 = 0;
    bramctrl_wren_wr_3 = 0;

    case (bramctrl_wr_sel) 
        2'b00: begin
            bramctrl_addr_wr_0 = bramctrl_wraddr;
            bramctrl_wren_wr_0 = psumctrl_wren;
        end
        2'b01: begin
            bramctrl_addr_wr_1 = bramctrl_wraddr;
            bramctrl_wren_wr_1 = psumctrl_wren;    
        end
        2'b10: begin
            bramctrl_addr_wr_2 = bramctrl_wraddr;
            bramctrl_wren_wr_2 = psumctrl_wren;    
        end
        2'b11: begin
            bramctrl_addr_wr_3 = bramctrl_wraddr;
            bramctrl_wren_wr_3 = psumctrl_wren;    
        end
        default: begin
            bramctrl_addr_wr_0 = 0;
            bramctrl_wren_wr_0 = 0;
            bramctrl_addr_wr_1 = 0;
            bramctrl_wren_wr_1 = 0;
            bramctrl_addr_wr_2 = 0;
            bramctrl_wren_wr_2 = 0;
            bramctrl_addr_wr_3 = 0;
            bramctrl_wren_wr_3 = 0;
        end
    endcase
end

endmodule
