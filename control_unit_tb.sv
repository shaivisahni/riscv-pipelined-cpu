`timescale 1ns/1ps

import phantom_pkg::*;

module control_unit_tb;

    logic [31:0] inst;
    ctrl_t       ctrl;
    int          errors = 0;

    control_unit dut (
        .inst(inst),
        .ctrl(ctrl)
    );

    task check(input string name, 
                input logic exp_RegWEn, 
                input logic exp_ASel, 
                input logic exp_BSel, 
                input logic [3:0] exp_ALUSel, 
                input logic exp_MemRW,
                input logic [1:0] exp_WBSel,
                input logic exp_BrUn,
                input logic exp_is_branch,
                input logic exp_is_jump,
                input logic [2:0] exp_funct3);
    #1;
    if(ctrl.RegWEn      !== exp_RegWEn      ||
       ctrl.ASel        !== exp_ASel        ||
       ctrl.BSel        !== exp_BSel        ||
       ctrl.ALUSel      !== exp_ALUSel      ||
       ctrl.MemRW       !== exp_MemRW       ||
       ctrl.WBSel       !== exp_WBSel       ||
       ctrl.BrUn        !== exp_BrUn        ||
       ctrl.is_branch   !== exp_is_branch   ||
       ctrl.is_jump     !== exp_is_jump     ||
       ctrl.funct3      !== exp_funct3) begin
       $display("[FAIL] %s (inst=0x%08h)", name, inst);
       $display("   RegWEn %b/%b ASel %b/%b BSel %b/%b  ALUSel %b/%b", 
                     ctrl.RegWEn, exp_RegWEn, ctrl.ASel, exp_ASel,
                     ctrl.BSel, exp_BSel, ctrl.ALUSel, exp_ALUSel);
       $display("   MemRW %b/%b  WBSel %b/%b  BrUn %b/%b  is_br %b/%b  is_jmp %b/%b funct3 %b/%b",
                     ctrl.MemRW, exp_MemRW, ctrl.WBSel, 
                     exp_WBSel, ctrl.BrUn, exp_BrUn,
                     ctrl.is_branch, exp_is_branch, ctrl.is_jump, exp_is_jump, ctrl.funct3, exp_funct3);
       $display("   (got/expected)");
       errors++;
    end else begin
        $display("[PASS] %s", name);
    end
endtask

initial begin
    $display("=== control_unit TB ===\n");

    // R-TYPE
    // add x3, x1, x2   funct7=0000000 funct3=000
    inst = 32'h002081b3;
    //          RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
    check("add",    1,  0,   0,  4'b0000,   0,  2'b01, 0,   0,     0,    3'b000);

    // sub x4, x2, x1   funct7=0100000 funct3=000 → ALUSel=1000
    inst = 32'h40110233;
    //          RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
    check("sub",    1,  0,   0,  4'b1000,   0,  2'b01, 0,   0,     0,    3'b000);

    // and x5, x1, x2   funct3=111 → ALUSel=0111
    inst = 32'h0020f2b3;
    //          RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
    check("and",    1,  0,   0,  4'b0111,   0,  2'b01, 0,   0,     0,    3'b111);

    // sll x5, x1, x2   funct3=001 → ALUSel=0001
    inst = 32'h002092b3;
    //          RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
    check("sll",    1,  0,   0,  4'b0001,   0,  2'b01, 0,   0,     0,    3'b001);

    // sra x5, x1, x2   funct7=0100000 funct3=101 → ALUSel=1101
    inst = 32'h4020d2b3;
    //          RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
    check("sra",    1,  0,   0,  4'b1101,   0,  2'b01, 0,   0,     0,    3'b101);

    // I-TYPE

    // addi x1, x0, 5   funct3=000 → ALUSel=0000 (Option A: non-shift, top bit 0)
        inst = 32'h00500093;
    //             RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
        check("addi",  1,   0,   1,  4'b0000,  0,  2'b01,  0,   0,    0,    3'b000);

    // andi x1, x1, 15  funct3=111 → ALUSel=0111
        inst = 32'h00f0f093;
    //             RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
        check("andi",  1,   0,   1,  4'b0111,  0,  2'b01,  0,   0,    0,    3'b111);

    // slli x1, x1, 2   funct3=001 (shift) → ALUSel={inst[30],001}=0001
        inst = 32'h00209093;
    //             RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
        check("slli",  1,   0,   1,  4'b0001,  0,  2'b01,  0,   0,    0,    3'b001);

        // srli x1, x1, 2   funct3=101 funct7=0000000 → ALUSel=0101
        inst = 32'h0020d093;
    //             RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
        check("srli",  1,   0,   1,  4'b0101,  0,  2'b01,  0,   0,    0,    3'b101);

        // srai x1, x1, 2   funct3=101 funct7=0100000 → ALUSel=1101 (Option A grabs inst[30])
        inst = 32'h4020d093;
    //             RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
        check("srai",  1,   0,   1,  4'b1101,  0,  2'b01,  0,   0,    0,    3'b101);

    // LOAD
        // lw x1, 0(x2)   funct3=010
        inst = 32'h00012083;
    //             RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
        check("lw",    1,   0,   1,  4'b0000,  0,  2'b00,  0,   0,    0,    3'b010);

        // ============ STORE ============
        // sw x1, 0(x2)
        inst = 32'h00112023;
    //             RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
        check("sw",    0,   0,   1,  4'b0000,  1,  2'b01,  0,   0,    0,    3'b010);
        // WBSel is don't-care (RegWEn=0); expecting the default 01

        // ============ BRANCH ============
        // beq x1, x2, offset   funct3=000 → signed, BrUn=0
        inst = 32'h00208463;
    //             RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
        check("beq",   0,   1,   1,  4'b0000,  0,  2'b01,  0,   1,    0,    3'b000);

        // bltu x1, x2, offset  funct3=110 → unsigned, BrUn=1
        inst = 32'h0020e463;
    //             RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
        check("bltu",  0,   1,   1,  4'b0000,  0,  2'b01,  1,   1,    0,    3'b110);

        // bgeu x1, x2, offset  funct3=111 → unsigned, BrUn=1
        inst = 32'h0020f463;
    //             RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
        check("bgeu",  0,   1,   1,  4'b0000,  0,  2'b01,  1,   1,    0,    3'b111);

        // blt x1, x2, offset   funct3=100 → signed, BrUn=0
        inst = 32'h0020c463;
    //             RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
        check("blt",   0,   1,   1,  4'b0000,  0,  2'b01,  0,   1,    0,    3'b100);

        // FUNCT3 FOR REMAINING INSTRUCTIONS FOLLOWING DEFAULT
        // JAL 
        // jal x1, offset
        inst = 32'h008000ef;
    //             RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
        check("jal",   1,   1,   1,  4'b0000,  0,  2'b10,  0,   0,    1,    inst[14:12]); 

        // JALR
        // jalr x1, x2, 0   → ASel=0 (rs1)
        inst = 32'h000100e7;
    //             RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
        check("jalr",  1,   0,   1,  4'b0000,  0,  2'b10,  0,   0,    1,    inst[14:12]); 

        // LUI
        // lui x1, 0x12345  → ALUSel=pass-B (1111), ASel don't-care (expect default 0)
        inst = 32'h123450b7;
    //             RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
        check("lui",   1,   0,   1,  4'b1111,  0,  2'b01,  0,   0,    0,    inst[14:12]); 

        // AUIPC 
        // auipc x1, 0x1
        inst = 32'h00001097;
    //             RegWEn ASel BSel ALUSel   MemRW WBSel BrUn is_br is_jmp funct3
        check("auipc", 1,   1,   1,  4'b0000,  0,  2'b01,  0,   0,    0,    inst[14:12]); 

        // UNKNOWN OPCODE
        // garbage → all safe defaults, RegWEn=0
        inst = 32'hFFFFFFFF;
        check("unknown->safe", 0, 0, 0, 4'b0000, 0, 2'b01, 0, 0, 0, inst[14:12]);

        // SUMMARY
        $display("\n=== Summary ===");
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("FAILED: %0d test(s)", errors);
        $finish;
    end

endmodule