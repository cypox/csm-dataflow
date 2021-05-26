`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2021 10:18:27 PM
// Design Name: 
// Module Name: axi_wrapper
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


module axis_wrapper #(
    parameter integer INP_DEPTH=8,
    parameter integer OUT_DEPTH=2,
    parameter integer INPUT_DATA_WIDTH = 32, 
    parameter integer OUTPUT_DATA_WIDTH = ((INP_DEPTH-1) < 2**$clog2(INP_DEPTH)) ? INPUT_DATA_WIDTH + $clog2(INP_DEPTH) : INPUT_DATA_WIDTH + $clog2(INP_DEPTH) + 1
    )(
        input wire axi_clk,
        input wire axi_reset_n,
        // axis slave interface
        input wire s_axis_valid,
        input wire [INPUT_DATA_WIDTH-1:0] s_axis_data,
        output wire s_axis_ready,
        // axis master interface
        output wire m_axis_valid,
        output wire [OUTPUT_DATA_WIDTH-1:0] m_axis_data,
        input wire m_axis_ready
    );
    // function called clogb2 that returns an integer which has the value of the ceiling of the log base 2.
    function integer clogb2 (input integer bit_depth);
      begin
        for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
          bit_depth = bit_depth >> 1;
      end
    endfunction
 
    localparam WR_ADDR_WIDTH  = clogb2(INP_DEPTH)-1;
    localparam RD_ADDR_WIDTH  = clogb2(OUT_DEPTH)-1;
    
    integer i;
    
    reg signed [INPUT_DATA_WIDTH-1:0] input_ram [INP_DEPTH-1:0];
    wire signed [OUTPUT_DATA_WIDTH-1:0] output_ram [OUT_DEPTH-1:0];
    
    reg [INPUT_DATA_WIDTH-1:0] m_axis_data_reg;
    reg [OUTPUT_DATA_WIDTH-1:0] s_axis_data_reg;

    reg s_axis_ready_reg;
    reg m_axis_valid_reg;
    
    reg [WR_ADDR_WIDTH:0] current_write_address = {WR_ADDR_WIDTH{1'b0}};
    reg [RD_ADDR_WIDTH:0] current_read_address = {RD_ADDR_WIDTH{1'b0}};
    
    //wire memory_full = current_write_address >= INP_DEPTH;
    //wire last = current_read_address+1 == OUT_DEPTH;
    //wire finished = current_read_address >= OUT_DEPTH; // all data has been sent to slave, we can start receiving again
    
    //assign s_axis_ready = !memory_full | finished;
    //assign m_axis_valid = !s_axis_ready; // WARNING: we start sending when we finish computation not as soon as we finish reading
    
    assign m_axis_data = m_axis_data_reg;
    assign s_axis_data_reg = s_axis_data;
    assign s_axis_ready = s_axis_ready_reg;
    assign m_axis_valid = m_axis_valid_reg;

    reg [2:0] delay = 3'b111; // time to wait for processing

    localparam [1:0] // 3 states
        reading_input = 2'b00,
        processing = 2'b01,
        writing_output = 2'b10;
    reg[1:0] state_reg = reading_input;

    always @ (state_reg)
    begin
        case (state_reg)
            reading_input:
            begin
                s_axis_ready_reg = 1'b1;
                m_axis_valid_reg = 1'b0;
            end
            processing:
            begin
                s_axis_ready_reg = 1'b0;
                m_axis_valid_reg = 1'b0;
            end
            writing_output:
            begin
                s_axis_ready_reg = 1'b0;
                m_axis_valid_reg = 1'b1;
            end
            default:
            begin
                s_axis_ready_reg = 1'b0;
                m_axis_valid_reg = 1'b0;
            end
        endcase
    end

    always @ (posedge axi_clk or negedge axi_reset_n) begin
    if (!axi_reset_n)
    begin
        state_reg <= reading_input;
        delay <= 3'b111;
        current_write_address <= {WR_ADDR_WIDTH+1{1'b0}};
        current_read_address <= {RD_ADDR_WIDTH+1{1'b0}};
    end
    else
        case (state_reg)
            reading_input:
            begin
                if (s_axis_valid)
                    current_write_address <= current_write_address + 1;
                if (current_write_address+1 == INP_DEPTH)
                begin
                    current_write_address <= {WR_ADDR_WIDTH+1{1'b0}};
                    state_reg <= processing;
                end
            end
            processing:
            begin
                delay <= delay - 1;
                if (delay == 0)
                begin
                    state_reg <= writing_output;
                    delay <= 3'b111;
                end
            end
            writing_output:
            begin
                if (m_axis_ready)
                    current_read_address <= current_read_address + 1;
                if (current_read_address+1 == OUT_DEPTH)
                begin
                    current_read_address <= {RD_ADDR_WIDTH+1{1'b0}};
                    state_reg <= reading_input;
                end
            end
        endcase
    end

    // processing logic
    genvar g;
    for (g = 0 ; g < OUT_DEPTH ; g++)
    begin
        perceptron#(.N(8), .DATA_WIDTH(INPUT_DATA_WIDTH), .RESULT_WIDTH(OUTPUT_DATA_WIDTH))
            dut(.clk(axi_clk), .data_in(input_ram), .data_out(output_ram[g]));
    end

    // read from slave and write to memory logic
    always @(*)
    begin
        for(i = 0 ; i < INPUT_DATA_WIDTH/8 ; i = i + 1)
        begin
            input_ram[current_write_address][i*8+:8] <= s_axis_data_reg[i*8+:8];
        end
    end
    
    // read from memory and write to master logic
    always @(*)
    begin
        for(i = 0 ; i < OUTPUT_DATA_WIDTH/8 ; i = i + 1)
        begin
            m_axis_data_reg[i*8+:8] <= output_ram[current_read_address][i*8+:8];
        end
    end

endmodule
