`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/26/2021 11:23:01 AM
// Design Name: 
// Module Name: pixel_concat_tb
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


module pixel_concat_tb;

parameter DAT_WIDTH = 32;
parameter PIX_WIDTH = 24;

reg                      clk;
reg                      rst;

wire                     ival;
wire [DAT_WIDTH - 1 : 0] idat;
wire [PIX_WIDTH - 1 : 0] odat;
wire                     oval;
wire                     ostall;

pixel_concat uut(
    .clk    (clk),
    .rst    (rst),
    .idat   (idat),
    .ival   (ival),
    .odat   (odat),
    .oval   (oval),
    .ostall (ostall)
    );

pixel_concat_tb_data_gen 
    #(
        .MODE(1)
    )
stimulus(
    .clk     (clk),
    .rst     (rst),
    .idat    (idat),
    .ival    (ival),
    .ostall  (ostall)
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

endmodule
