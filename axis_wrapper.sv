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
    parameter integer DATA_WIDTH = 32,
    parameter integer INP_DEPTH=8,
    parameter integer OUT_DEPTH=8
    )(
        input wire axi_clk,
        input wire axi_reset_n,
        // axis slave interface
        input wire s_axis_valid,
        input wire [DATA_WIDTH-1:0] s_axis_data,
        output wire s_axis_ready,
        // axis master interface
        output wire m_axis_valid,
        output wire [DATA_WIDTH-1:0] m_axis_data,
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
    
    reg [DATA_WIDTH-1:0] input_ram [INP_DEPTH-1:0];
    wire [DATA_WIDTH-1:0] output_ram [OUT_DEPTH-1:0];
    
    reg [DATA_WIDTH-1:0] m_axis_data_reg;
    reg [DATA_WIDTH-1:0] s_axis_data_reg;
    
    reg [WR_ADDR_WIDTH:0] current_write_address = {WR_ADDR_WIDTH{1'b0}};
    reg [RD_ADDR_WIDTH:0] current_read_address = {RD_ADDR_WIDTH{1'b0}};
    
    wire memory_full = current_write_address >= INP_DEPTH;
    wire last = current_read_address+1 == OUT_DEPTH;
    wire finished = current_read_address >= OUT_DEPTH; // all data has been sent to slave, we can start receiving again
    
    assign s_axis_ready = !memory_full | finished;
    assign m_axis_valid = !s_axis_ready; // WARNING: we start sending when we finish computation not as soon as we finish reading
    
    assign m_axis_data = m_axis_data_reg;
    assign s_axis_data_reg = s_axis_data;

    // processing logic
    genvar index;
    for(index = 0; index < INP_DEPTH; index = index + 1)
    begin
        assign output_ram[index] = input_ram[index] - 1;
    end
    
    // write logic
    always @(posedge axi_clk)
    begin
        if (s_axis_valid & s_axis_ready)
        begin
            for(i = 0 ; i < DATA_WIDTH/8 ; i = i + 1)
            begin
                input_ram[current_write_address][i*8+:8] <= s_axis_data_reg[i*8+:8];
            end
            current_write_address <= current_write_address + 1;
        end
        
        // restart if finished with all data
        if (last)
        begin
            current_write_address <= {WR_ADDR_WIDTH+1{1'b0}};
        end
        
        // reset logic
        if (!axi_reset_n) begin
            current_write_address = {WR_ADDR_WIDTH+1{1'b0}};
        end
    end
    
    // read logic
    always @(posedge axi_clk)
    begin
        if (m_axis_valid & m_axis_ready)
        begin
            for(i = 0 ; i < DATA_WIDTH/8 ; i = i + 1)
            begin
                m_axis_data_reg[i*8+:8] <= output_ram[current_read_address][i*8+:8];
            end
            current_read_address <= current_read_address + 1;
        end
        
        if (finished)
        begin
            current_read_address = {RD_ADDR_WIDTH+1{1'b0}};
        end
        
        // reset logic
        if (!axi_reset_n) begin
            current_read_address = {RD_ADDR_WIDTH+1{1'b0}};
        end
    end

endmodule
