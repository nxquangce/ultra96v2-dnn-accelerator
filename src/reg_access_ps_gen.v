`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 07/04/2021 11:45:02 PM
// Design Name: Register access PS signals generator
// Module Name: reg_access_ps_gen
// Project Name: lib
// Target Devices: any
// Tool Versions: any
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module reg_access_ps_gen(
    clk,
    rst,
    host_addr,
    host_idat,
    host_odat,
    user_addr,
    user_wren,
    user_wdat,
    user_rden,
    user_rdat,
    user_rvld
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter DATA_WIDTH    = 32;
parameter ADDR_WIDTH    = 32;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                       clk;
input                       rst;
input  [ADDR_WIDTH - 1 : 0] host_addr;
input  [DATA_WIDTH - 1 : 0] host_idat;
output [DATA_WIDTH - 1 : 0] host_odat;
output [ADDR_WIDTH - 1 : 0] user_addr;
output                      user_wren;
output [DATA_WIDTH - 1 : 0] user_wdat;
output                      user_rden;
input  [DATA_WIDTH - 1 : 0] user_rdat;
input                       user_rvld;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
reg [ADDR_WIDTH - 1 : 0] host_addr_cache;
reg [DATA_WIDTH - 1 : 0] host_idat_cache;
reg [DATA_WIDTH - 1 : 0] user_rdat_cache;
wire                     addr_change;
wire                     data_change;

always @(posedge clk) begin
    if (rst) begin
        host_addr_cache <= 0;
        host_idat_cache <= 0;
    end
    else begin
        host_addr_cache <= host_addr;
        host_idat_cache <= host_idat;
    end
end

assign addr_change = (host_addr_cache != host_addr);
assign data_change = (host_idat_cache != host_idat);

always @(posedge clk) begin
    if (rst) begin
        user_rdat_cache <= 0;
    end
    else if (user_rvld) begin
        user_rdat_cache <= user_rdat;
    end
end

assign host_odat = user_rdat_cache;

assign user_addr = host_addr;
assign user_wdat = host_idat;
assign user_wren = addr_change | data_change;
assign user_rden = addr_change;

endmodule
