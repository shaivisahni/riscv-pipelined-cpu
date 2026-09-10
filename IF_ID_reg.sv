import phantom_pkg::*;

module IF_ID_reg(
    input logic clk, rst, stall, flush,
    input logic [31:0] pc_in, pc_plus_4_in, inst_in,
    output if_id_t if_id_out
);

localparam logic [31:0] NOP = 32'h00000013;

always_ff @(posedge clk) begin
    if(rst) begin
        if_id_out.pc    <= 32'b0;
        if_id_out.pc_plus_4 <= 32'b0;
        if_id_out.inst <= NOP;
    end
    else if(flush) begin
        if_id_out.pc <= 32'b0;
        if_id_out.pc_plus_4 <= 32'b0;
        if_id_out.inst <= NOP;
    end
    else if(stall) begin
        if_id_out <= if_id_out;
    end
    else begin
        if_id_out.pc <= pc_in;
        if_id_out.pc_plus_4 <= pc_plus_4_in;
        if_id_out.inst <= inst_in;
    end
end

endmodule