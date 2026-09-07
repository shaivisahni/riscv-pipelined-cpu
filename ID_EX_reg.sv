import phantom_pkg::*;

module ID_EX_reg(
    input logic clk, rst, stall, flush,
    input id_ex_t id_ex_next,
    output id_ex_t id_ex_out
);

    always_ff @(posedge clk) begin
        if(rst | flush | stall) begin
            id_ex_out <= '0;
        end 
        else begin
            id_ex_out <= id_ex_next;
        end
    end

endmodule