`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 05/08/2021 11:17:10 PM
// Design Name: psum bram controller bus multiplexer
// Module Name: psum_bramctrl_bus_mux
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: Select ps axi bram ctrl or pl user bram ctrl to read/write psum bram
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module psum_bramctrl_bus_mux(
    clk,
    i_conf_ctrl,
    bram_addr_a,
    bram_clk_a,
    bram_wrdata_a,
    bram_rddata_a,
    bram_en_a,
    bram_rst_a,
    bram_we_a,
    mem_addr,
    mem_idat,
    mem_odat,
    mem_wren,
    mem_enb,
    mem_rst,
    addra,
    clka,
    dina,
    douta,
    ena,
    rsta,
    wea,
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter DATA_WIDTH    = 32;
parameter ADDR_WIDTH    = 32;

parameter NUM_BYTE      = 4;

parameter REG_WIDTH     = 32;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                       clk;
input   [REG_WIDTH - 1 : 0] i_conf_ctrl;

input  [ADDR_WIDTH - 1 : 0] bram_addr_a;
input                       bram_clk_a;
input  [DATA_WIDTH - 1 : 0] bram_wrdata_a;
output [DATA_WIDTH - 1 : 0] bram_rddata_a;
input                       bram_en_a;
input                       bram_rst_a;
input    [NUM_BYTE - 1 : 0] bram_we_a;

input  [ADDR_WIDTH - 1 : 0] mem_addr;
input  [DATA_WIDTH - 1 : 0] mem_idat;
output [DATA_WIDTH - 1 : 0] mem_odat;
input    [NUM_BYTE - 1 : 0] mem_wren;
input                       mem_enb;
input                       mem_rst;

output [ADDR_WIDTH - 1 : 0] addra;
output                      clka;
output [DATA_WIDTH - 1 : 0] dina;
input  [DATA_WIDTH - 1 : 0] douta;
output                      ena;
output                      rsta;
output   [NUM_BYTE - 1 : 0] wea;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire psenb;

reg [ADDR_WIDTH - 1 : 0] addra_reg;
reg                      clka_reg;
reg [DATA_WIDTH - 1 : 0] dina_reg;
reg                      ena_reg;
reg                      rsta_reg;
reg   [NUM_BYTE - 1 : 0] wea_reg;

reg [DATA_WIDTH - 1 : 0] bram_rddata_a_reg;
reg [DATA_WIDTH - 1 : 0] mem_odat_reg;

always @(*) begin
    if (psenb) begin
        addra_reg = bram_addr_a;
        clka_reg  = bram_clk_a;
        dina_reg  = bram_wrdata_a;
        ena_reg   = bram_en_a;
        rsta_reg  = bram_rst_a;
        wea_reg   = bram_we_a;

        bram_rddata_a_reg = douta;
        mem_odat_reg = 0;
    end
    else begin
        addra_reg = mem_addr;
        clka_reg  = clk;
        dina_reg  = mem_idat;
        ena_reg   = mem_wren;
        rsta_reg  = mem_enb;
        wea_reg   = mem_rst;

        bram_rddata_a_reg = 0;
        mem_odat_reg  = douta;
    end
end

assign addra         = addra_reg;
assign clka          = clka_reg;
assign dina          = dina_reg;
assign ena           = ena_reg;
assign rsta          = rsta_reg;
assign wea           = wea_reg;
assign bram_rddata_a = bram_rddata_a_reg;
assign mem_odat      = mem_odat_reg;

endmodule
