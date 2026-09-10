module EX_before_PRs(
    input logic [31:0] PC, DataA, DataB, inst,
    input logic BrUn, Asel, Bsel, 
    input logic [3:0] ALUSel,
    output logic[31:0] result, DataB_out,
    output logic BrEq, BrLT
);

logic [31:0] IG_out;
Branch_Comp EX_BC(
    .DataA(DataA),
    .DataB(DataB),
    .BrUn(BrUn),
    .BrEq(BrEq),
    .BrLT(BrLT)
);

Imm_Gen EX_IG(
    .inst(inst),
    .imm(IG_out)
);

ALU_with_MUXes EX_ALU1(
    .PC(PC),
    .rs1(DataA),
    .rs2(DataB),
    .imm(IG_out),
    .Asel(Asel),
    .Bsel(Bsel),
    .ALUSel(ALUSel),
    .result(result)
);

assign DataB_out = DataB;

endmodule