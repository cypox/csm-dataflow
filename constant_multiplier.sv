`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2021 08:56:34 PM
// Design Name: 
// Module Name: constant_multiplier
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


module constant_multiplier # (parameter integer DATA_WIDTH = 8, parameter integer CONSTANT = 0)
    (
    input clk,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
    );

    always_ff @(posedge clk)
        data_out <= data_in * CONSTANT;

endmodule
