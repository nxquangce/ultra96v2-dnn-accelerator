`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 04/22/2021 12:20:48 AM
// Design Name: Pixel concat
// Module Name: pixel_concat
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: Concat pixel data..
//   data from bram is 32 bit, but a pixel is 24 bit, there are 1 byte
//   belongs to next pixel, and in next data, there are 2 bytes...
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pixel_concat(
    clk,
    rst,
    idat,
    ival,
    odat,
    oval,
    ostall
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter DAT_WIDTH = 32;
parameter PIX_WIDTH = 24;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input                      clk;
input                      rst;
input  [DAT_WIDTH - 1 : 0] idat;
input                      ival;
output [PIX_WIDTH - 1 : 0] odat;
output                     oval;
output                     ostall;

reg  [PIX_WIDTH - 1 : 0] odata_reg_p0;
reg  [DAT_WIDTH - 1 : 0] cache_reg_p1;
reg  [1:0]               state;
reg                      oval_stall_reg;
wire [DAT_WIDTH * 2 - 1 : 0] dat_concat;

always @(posedge clk) begin
    if (rst) begin
        cache_reg_p1 <= 0;
    end
    else if (ival) begin
        cache_reg_p1 <= idat;
    end
end

always @(posedge clk) begin
    if (rst) begin
        state <= 2'b00;
    end
    else if (oval) begin
        state <= state + 1'b1;
    end
end

assign ostall = (state == 2'b10) & ival;

// Cal out data
assign dat_concat = {idat, cache_reg_p1};

always @(*) begin
    case (state)
        2'b00: odata_reg_p0 = dat_concat[8 * 7 - 1 : 8 * 4];
        2'b01: odata_reg_p0 = dat_concat[8 * 6 - 1 : 8 * 3];
        2'b10: odata_reg_p0 = dat_concat[8 * 5 - 1 : 8 * 2];
        2'b11: odata_reg_p0 = dat_concat[8 * 8 - 1 : 8 * 5];    // due to stall
        default: begin
            odata_reg_p0 = 0;
        end
    endcase
end

assign odat = odata_reg_p0;

// Cal out valid for state 3
always @(posedge clk) begin
    if (rst) begin
        oval_stall_reg <= 0;
    end
    else begin
        oval_stall_reg <= ostall;
    end
end

assign oval = (state == 2'b11) ? oval_stall_reg : ival;

endmodule

