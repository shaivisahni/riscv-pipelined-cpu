`timescale 1ns/1ps

import phantom_pkg::*;

module IF_ID_reg_tb;

    logic        clk, rst, stall, flush;
    logic [31:0] pc_in, pc_plus_4_in, inst_in;
    if_id_t      if_id_out;
    int          errors = 0;

    localparam logic [31:0] NOP = 32'h00000013;

    // DUT
    IF_ID_reg dut (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .pc_in(pc_in),
        .pc_plus_4_in(pc_plus_4_in),
        .inst_in(inst_in),
        .if_id_out(if_id_out)
    );

    // Clock: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    task check(input string name,
               input logic [31:0] exp_pc,
               input logic [31:0] exp_p4,
               input logic [31:0] exp_inst);
        if (if_id_out.pc !== exp_pc || if_id_out.pc_plus_4 !== exp_p4 || if_id_out.inst !== exp_inst) begin
            $display("[FAIL] %s", name);
            $display("        expected{pc=0x%08h, +4=0x%08h, inst=0x%08h}", exp_pc, exp_p4, exp_inst);
            $display("        got     {pc=0x%08h, +4=0x%08h, inst=0x%08h}",
                     if_id_out.pc, if_id_out.pc_plus_4, if_id_out.inst);
            errors++;
        end else begin
            $display("[PASS] %s: pc=0x%08h +4=0x%08h inst=0x%08h",
                     name, if_id_out.pc, if_id_out.pc_plus_4, if_id_out.inst);
        end
    endtask

    initial begin
        $display("=== IF_ID_reg Testbench ===\n");

        // ---------------- RESET ----------------
        rst = 1; stall = 0; flush = 0;
        pc_in = 32'hDEADBEEF; pc_plus_4_in = 32'hCAFEBABE; inst_in = 32'h12345678;
        @(posedge clk); #1;
        // reset → pc/p4 cleared, inst = NOP (regardless of inputs)
        check("reset: NOP out, cleared", 32'h0, 32'h0, NOP);

        // ---------------- NORMAL LATCH ----------------
        rst = 0; stall = 0; flush = 0;
        pc_in = 32'h00000000; pc_plus_4_in = 32'h00000004; inst_in = 32'h00500093;
        @(posedge clk); #1;
        check("latch instr 0", 32'h00000000, 32'h00000004, 32'h00500093);

        pc_in = 32'h00000004; pc_plus_4_in = 32'h00000008; inst_in = 32'h00a00113;
        @(posedge clk); #1;
        check("latch instr 1", 32'h00000004, 32'h00000008, 32'h00a00113);

        pc_in = 32'h00000008; pc_plus_4_in = 32'h0000000C; inst_in = 32'h002081b3;
        @(posedge clk); #1;
        check("latch instr 2", 32'h00000008, 32'h0000000C, 32'h002081b3);

        // ---------------- STALL (hold) ----------------
        // Freeze — contents must stay at instr 2 even as inputs change
        stall = 1;
        pc_in = 32'hAAAAAAAA; pc_plus_4_in = 32'hBBBBBBBB; inst_in = 32'hCCCCCCCC;
        @(posedge clk); #1;
        check("stall holds instr 2", 32'h00000008, 32'h0000000C, 32'h002081b3);

        @(posedge clk); #1;
        check("stall still holds (2nd cyc)", 32'h00000008, 32'h0000000C, 32'h002081b3);

        // ---------------- RESUME after stall ----------------
        stall = 0;
        pc_in = 32'h0000000C; pc_plus_4_in = 32'h00000010; inst_in = 32'h40110233;
        @(posedge clk); #1;
        check("resume: latch instr 3", 32'h0000000C, 32'h00000010, 32'h40110233);

        // ---------------- FLUSH (inject NOP) ----------------
        flush = 1;
        pc_in = 32'h11111111; pc_plus_4_in = 32'h22222222; inst_in = 32'h33333333;
        @(posedge clk); #1;
        check("flush injects NOP", 32'h0, 32'h0, NOP);

        // ---------------- FLUSH BEATS STALL ----------------
        // Both asserted → flush wins (NOP, not hold)
        flush = 1; stall = 1;
        pc_in = 32'h44444444; pc_plus_4_in = 32'h55555555; inst_in = 32'h66666666;
        @(posedge clk); #1;
        check("flush beats stall", 32'h0, 32'h0, NOP);

        // ---------------- RESUME after flush ----------------
        flush = 0; stall = 0;
        pc_in = 32'h00000010; pc_plus_4_in = 32'h00000014; inst_in = 32'h0020a023;
        @(posedge clk); #1;
        check("resume after flush", 32'h00000010, 32'h00000014, 32'h0020a023);

        // ---------------- RESET BEATS EVERYTHING ----------------
        rst = 1; flush = 1; stall = 1;
        pc_in = 32'h77777777; pc_plus_4_in = 32'h88888888; inst_in = 32'h99999999;
        @(posedge clk); #1;
        check("reset beats flush+stall", 32'h0, 32'h0, NOP);

        // ---------------- BACK TO NORMAL ----------------
        rst = 0; flush = 0; stall = 0;
        pc_in = 32'h00001000; pc_plus_4_in = 32'h00001004; inst_in = 32'hfe1ff06f;
        @(posedge clk); #1;
        check("normal after reset", 32'h00001000, 32'h00001004, 32'hfe1ff06f);

        // ---------------- SUMMARY ----------------
        $display("\n=== Summary ===");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("FAILED: %0d test(s)", errors);

        $finish;
    end

endmodule