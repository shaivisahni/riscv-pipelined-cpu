import phantom_pkg::*;

module EX_MEM_reg(
    input  logic clk, rst,
    input  ex_mem_t ex_mem_next,
    output ex_mem_t ex_mem_out
);
    always_ff @(posedge clk) begin
        if (rst) 
            ex_mem_out <= '0;
        else     
            ex_mem_out <= ex_mem_next;
    end
endmodule