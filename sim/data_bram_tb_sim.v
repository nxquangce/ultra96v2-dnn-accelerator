`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 04/30/2021 11:02:48 PM
// Design Name: 
// Module Name: data_bram_tb_sim
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


module data_bram_tb_sim(
    clk,
    rst,
    irdaddr,
    odat
    );

parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 32;

input                       clk;
input                       rst;
input  [ADDR_WIDTH - 1 : 0] irdaddr;
output [DATA_WIDTH - 1 : 0] odat;

reg [DATA_WIDTH - 1 : 0] data_reg;

always @(posedge clk) begin
    if (rst) begin
        data_reg <= 32'h30_20_10_00;
    end
    else begin
        data_reg[ 3: 0] <= irdaddr[3:0];
        data_reg[11: 8] <= irdaddr[3:0];
        data_reg[19:16] <= irdaddr[3:0];
        data_reg[27:24] <= irdaddr[3:0];

        if (irdaddr % 3 == 0) begin
            data_reg[31:28] <= 4'd0;
            data_reg[23:20] <= 4'd2;
            data_reg[15:12] <= 4'd1;
            data_reg[ 7: 4] <= 4'd0;
        end
        else if (irdaddr % 3 == 1) begin
            data_reg[31:28] <= 4'd1;
            data_reg[23:20] <= 4'd0;
            data_reg[15:12] <= 4'd2;
            data_reg[ 7: 4] <= 4'd1;
        end
        else if (irdaddr % 3 == 2) begin
            data_reg[31:28] <= 4'd2;
            data_reg[23:20] <= 4'd1;
            data_reg[15:12] <= 4'd0;
            data_reg[ 7: 4] <= 4'd2;
        end
    end
end

assign odat = data_reg;

endmodule
