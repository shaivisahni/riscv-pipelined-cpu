import phantom_pkg::*;

module MEM_WB_reg(
    input  logic clk, rst,
    input  mem_wb_t mem_wb_next,
    output mem_wb_t mem_wb_out
);
    always_ff @(posedge clk) begin
        if (rst) 
            mem_wb_out <= '0;
        else     
            mem_wb_out <= mem_wb_next;
    end
endmodule