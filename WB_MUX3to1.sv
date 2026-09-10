module WB_MUX3to1(
    input logic [31:0] mem, ALU, pc_plus_4,
    input logic [1:0] sel,
    output logic [31:0] result
);
    always_comb begin
        case(sel)
            2'b00: result = mem;
            2'b01: result = ALU;
            2'b10: result = pc_plus_4;
            default: result = 0;
        endcase
    end
endmodule