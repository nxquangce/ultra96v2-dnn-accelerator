`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/26/2021 11:29:45 AM
// Design Name: 
// Module Name: pixel_concat_tb_data_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pixel_concat_tb_data_gen(
    clk,
    rst,
    idat,
    ival,
    ostall
    );

parameter DAT_WIDTH = 32;
parameter MODE = 0;

input                      clk;
input                      rst;
output [DAT_WIDTH - 1 : 0] idat;
output                     ival;
input                      ostall;

reg [DAT_WIDTH - 1 : 0] idat_reg;
reg                     ival_reg;

wire pause;
reg [DAT_WIDTH - 1 : 0] pause_cnt;

always @(posedge clk) begin
    if (rst) begin
        pause_cnt <= 0;
    end
    else begin
        pause_cnt <= pause_cnt + 1'b1;
    end
end

assign pause = (MODE == 1) ? (pause_cnt[1] | pause_cnt[5] | pause_cnt[11]) : 1'b1;

always @(posedge clk) begin
    if (rst) begin
        idat_reg <= 0;
    end
    else if (!ostall & !pause) begin
        idat_reg <= idat_reg + 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        ival_reg <= 0;
    end
    else begin
        ival_reg <= (ostall | pause) ? 1'b0 : 1'b1;
    end
end

assign idat = idat_reg;
assign ival = ival_reg;

endmodule
