`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 17/03/2021 15:40:00 PM
// Design Name: Kernel-Channel Processing element
// Module Name: kernel_channel_pe
// Project Name: ultra96v2-dnn-accelerator
// Target Devices: ultra96v2
// Tool Versions: 2018.2
// Description: Perform MAC on 3 channel/4 kernel at a time
// 
// Dependencies: 
//  pe : prcocessing element - mac
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module kernel_channel_pe(
    clk,
    rst,
    i_data,
    i_data_val,
    i_weight,
    i_weight_val,
    i_psum,
    // i_psum_val,
    o_psum,
    o_psum_val,
    err_psum_val
    );

////////////////////////////////////////////////////////////////////////////////
// Parameter declarations
parameter BIT_WIDTH     = 8;
parameter NUM_CHANNEL   = 3;
parameter NUM_KERNEL    = 4;
parameter REG_WIDTH     = 32;

////////////////////////////////////////////////////////////////////////////////
// Port declarations
input  wire                                                  clk;
input  wire                                                  rst;
input  wire [(BIT_WIDTH * NUM_CHANNEL             ) - 1 : 0] i_data;
input  wire [(BIT_WIDTH * NUM_KERNEL * NUM_CHANNEL) - 1 : 0] i_weight;
input  wire [(BIT_WIDTH * NUM_KERNEL              ) - 1 : 0] i_psum;
input  wire                                                  i_data_val;
input  wire                                                  i_weight_val;
// input  wire                                     i_psum_val;
output wire [(BIT_WIDTH * NUM_KERNEL              ) - 1 : 0] o_psum;
output wire [NUM_KERNEL - 1 : 0]                             o_psum_val;
output reg  [REG_WIDTH - 1 : 0]                              err_psum_val;

////////////////////////////////////////////////////////////////////////////////
// Local logic and instantiation
wire [BIT_WIDTH - 1 : 0] i_weight_kn [NUM_KERNEL  - 1 : 0][NUM_CHANNEL - 1 : 0];
wire [BIT_WIDTH - 1 : 0] i_data_ch   [NUM_CHANNEL - 1 : 0];
wire [BIT_WIDTH - 1 : 0] i_psum_kn   [NUM_KERNEL  - 1 : 0];
wire [BIT_WIDTH - 1 : 0] o_psum_kn   [NUM_KERNEL  - 1 : 0][NUM_CHANNEL - 1 : 0];

wire [NUM_CHANNEL - 1 : 0] o_psum_val_kc [NUM_KERNEL - 1 : 0];

// Split data into channels
assign i_data_ch[0]   = i_data[BIT_WIDTH     - 1 : 0];
assign i_data_ch[1]   = i_data[BIT_WIDTH * 2 - 1 : BIT_WIDTH];
assign i_data_ch[2]   = i_data[BIT_WIDTH * 3 - 1 : BIT_WIDTH * 2];

// Split weight into kernels and channel
genvar idxIwC, idxIwK;
generate
    for (idxIwK = 0; idxIwK < NUM_KERNEL; idxIwK = idxIwK + 1) begin
        for (idxIwC = 0; idxIwC < NUM_CHANNEL; idxIwC = idxIwC + 1) begin
            assign i_weight_kn[idxIwK][idxIwC] = i_weight[BIT_WIDTH * (idxIwK * NUM_CHANNEL + idxIwC + 1) - 1 : BIT_WIDTH * (idxIwK * NUM_CHANNEL + idxIwC)];
            // assign i_weight_kn[0] = i_weight[BIT_WIDTH      - 1 : 0];
            // assign i_weight_kn[1] = i_weight[BIT_WIDTH * 2  - 1 : BIT_WIDTH];
            // assign i_weight_kn[2] = i_weight[BIT_WIDTH * 3  - 1 : BIT_WIDTH * 2];
            // assign i_weight_kn[3] = i_weight[BIT_WIDTH * 4  - 1 : BIT_WIDTH * 3];
        end
    end
endgenerate

// Split psum into kernels
assign i_psum_kn[0]   = i_psum[BIT_WIDTH      - 1 : 0];
assign i_psum_kn[1]   = i_psum[BIT_WIDTH * 2  - 1 : BIT_WIDTH];
assign i_psum_kn[2]   = i_psum[BIT_WIDTH * 3  - 1 : BIT_WIDTH * 2];
assign i_psum_kn[3]   = i_psum[BIT_WIDTH * 4  - 1 : BIT_WIDTH * 3];

// Generate PEs
genvar idxC, idxK;
generate
    // PE for kernel idxC, channel 0
    for (idxK = 0; idxK < NUM_KERNEL; idxK = idxK + 1) begin
        pe i_pe_0(
            .clk            (clk),
            .rst            (rst),
            .i_data         (i_data_ch[0]),
            .i_data_val     (i_data_val),
            .i_weight       (i_weight_kn[idxK][0]),
            .i_weight_val   (i_weight_val),
            .i_psum         (i_psum_kn[idxK]),
            // .i_psum_val     (i_psum_val),
            .o_psum         (o_psum_kn[idxK][0]),
            .o_psum_val     (o_psum_val_kc[idxK][0])
            );
    end    

    // PE for kernel idxC, channel idxK
    for (idxK = 0; idxK < NUM_KERNEL; idxK = idxK + 1) begin
        for (idxC = 1; idxC < NUM_CHANNEL; idxC = idxC + 1) begin
            pe i_pe(
                .clk            (clk),
                .rst            (rst),
                .i_data         (i_data_ch[idxC]),
                .i_data_val     (i_data_val),
                .i_weight       (i_weight_kn[idxK][idxC]),
                .i_weight_val   (i_weight_val),
                .i_psum         (o_psum_kn[idxK][idxC - 1]),
                // .i_psum_val     (i_psum_val),
                .o_psum         (o_psum_kn[idxK][idxC]),
                .o_psum_val     (o_psum_val_kc[idxK])
                );
        end
    end
endgenerate

// Output valid
assign o_psum_val[0] = o_psum_val_kc[0][NUM_CHANNEL-1];
assign o_psum_val[1] = o_psum_val_kc[1][NUM_CHANNEL-1];
assign o_psum_val[2] = o_psum_val_kc[2][NUM_CHANNEL-1];
assign o_psum_val[3] = o_psum_val_kc[3][NUM_CHANNEL-1];

//////////////////////////////////////////////////////////////////////////////////
// Error monitor
wire [NUM_KERNEL - 1 : 0] err_psum_val_kn;

assign err_psum_val_kn[0] = o_psum_val_kc[0][0]^o_psum_val_kc[0][1] ^ o_psum_val_kc[0][2];
assign err_psum_val_kn[1] = o_psum_val_kc[1][0]^o_psum_val_kc[1][1] ^ o_psum_val_kc[1][2];
assign err_psum_val_kn[2] = o_psum_val_kc[2][0]^o_psum_val_kc[2][1] ^ o_psum_val_kc[2][2];
assign err_psum_val_kn[3] = o_psum_val_kc[3][0]^o_psum_val_kc[3][1] ^ o_psum_val_kc[3][2];

always @(posedge clk) begin
    if (rst) begin
        err_psum_val <= 0;
    end
    else begin
        if (err_psum_val_kn[0]) err_psum_val[0] <= 1'b1;
        if (err_psum_val_kn[1]) err_psum_val[1] <= 1'b1;
        if (err_psum_val_kn[2]) err_psum_val[2] <= 1'b1;
        if (err_psum_val_kn[3]) err_psum_val[3] <= 1'b1;
    end
end


endmodule