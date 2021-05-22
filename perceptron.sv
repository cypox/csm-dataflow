`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2021 09:18:14 PM
// Design Name: 
// Module Name: perceptron
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


module perceptron #(parameter
    N = 8, DATA_WIDTH = 33, RESULT_WIDTH = ((N-1) < 2**$clog2(N)) ? DATA_WIDTH + $clog2(N) : DATA_WIDTH + $clog2(N) + 1
    )(
    input clk,
    input signed [DATA_WIDTH-1:0] data_in[N-1:0],
    output signed [RESULT_WIDTH-1:0] data_out
    );
    
    reg signed [DATA_WIDTH-1:0] multiplication_output[N - 1:0];
    
    genvar i;
    for (i = 0 ; i < N-1 ; i ++)
    begin
        constant_multiplier#(.DATA_WIDTH(DATA_WIDTH), .CONSTANT(3))
            cm_input_inst(.clk(clk), .data_in(data_in[i]), .data_out(multiplication_output[i]));
    end
    constant_multiplier#(.DATA_WIDTH(DATA_WIDTH), .CONSTANT(1))
                cm_bias_inst(.clk(clk), .data_in(data_in[N-1]), .data_out(multiplication_output[N-1]));
    
    adder_tree#(.N(N), .DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH))
        adder_tree_inst(.clk(clk), .data_in(multiplication_output), .result(data_out));

endmodule
