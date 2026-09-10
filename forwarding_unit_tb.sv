`timescale 1ns/1ps

import phantom_pkg::*;

module forwarding_unit_tb;

    logic [4:0] idex_rs1_addr, idex_rs2_addr, exmem_rd_addr,
                memwb_rd_addr, exmem_rs2_addr;
    logic       exmem_RegWEn, memwb_RegWEn, fwd_wm;
    fwd_sel_e   fwd_a, fwd_b;
    int         errors = 0;
    int         tests  = 0;

    forwarding_unit DUT(
        .idex_rs1_addr(idex_rs1_addr),
        .idex_rs2_addr(idex_rs2_addr),
        .exmem_rd_addr(exmem_rd_addr),
        .exmem_RegWEn(exmem_RegWEn),
        .memwb_rd_addr(memwb_rd_addr),
        .memwb_RegWEn(memwb_RegWEn),
        .exmem_rs2_addr(exmem_rs2_addr),
        .fwd_a(fwd_a),
        .fwd_b(fwd_b),
        .fwd_wm(fwd_wm)
    );

    task reset_inputs();
        idex_rs1_addr   = 5'b11111;
        idex_rs2_addr   = 5'b10101;
        exmem_rd_addr   = 5'b01010;
        exmem_RegWEn    = 1'b1;
        memwb_rd_addr   = 5'b00100;
        memwb_RegWEn    = 1'b1;
        exmem_rs2_addr  = 5'b01000;
    endtask

    task check(input string name, input fwd_sel_e exp_a, input fwd_sel_e exp_b, input logic exp_wm);
        #1;
        tests++;
        if(fwd_a !== exp_a || fwd_b !== exp_b || fwd_wm !== exp_wm) begin
            $display("[FAIL] %s", name);
            $display("  expected:{fwd_a=%s, fwd_b=%s, fwd_wm=%b}", exp_a.name(), exp_b.name(), exp_wm);
            $display("  got:{fwd_a=%s, fwd_b=%s, fwd_wm=%b}", fwd_a.name(), fwd_b.name(), fwd_wm);
            errors++;
        end else begin  
            $display("[PASS] %s", name);
            $display("  got:{fwd_a=%s, fwd_b=%s, fwd_wm=%b}", fwd_a.name(), fwd_b.name(), fwd_wm);
        end
    endtask

    initial begin
        $display("=== Forwarding Unit Testbench ===\n");

        // ---------------- NO MATCHES (STANDARD) ----------------
        reset_inputs();
        check("No matches (standard)", FWD_REG, FWD_REG, 1'b0);

        // ---------------- exmem_rd == idex_rs1, WEn=1 ----------------
        reset_inputs();
        exmem_rd_addr = idex_rs1_addr;
        check("exmem_rd == idex_rs1, WEn=1", FWD_MX, FWD_REG, 1'b0);

        // ---------------- memwb_rd == idex_rs1, WEn=1 ----------------
        reset_inputs();
        memwb_rd_addr = idex_rs1_addr;
        check("memwb_rd == idex_rs1, WEn=1", FWD_WX, FWD_REG, 1'b0);

        // ---------------- BOTH MATCH RS1 ----------------
        reset_inputs();
        exmem_rd_addr = idex_rs1_addr; memwb_rd_addr = idex_rs1_addr;
        check("both match rs1", FWD_MX, FWD_REG, 1'b0);

        // ---------------- exmem_rd == idex_rs2, WEn=1 ----------------
        reset_inputs();
        exmem_rd_addr = idex_rs2_addr;
        check("exmem_rd == idex_rs2, WEn=1", FWD_REG, FWD_MX, 1'b0);

        // ---------------- memwb_rd == idex_rs2, WEn=1 ----------------
        reset_inputs();
        memwb_rd_addr = idex_rs2_addr;
        check("memwb_rd == idex_rs2, WEn=1", FWD_REG, FWD_WX, 1'b0);

        // ---------------- BOTH MATCH rs2 ----------------
        reset_inputs();
        exmem_rd_addr = idex_rs2_addr; memwb_rd_addr = idex_rs2_addr;
        check("both match rs2", FWD_REG, FWD_MX, 1'b0);

        // ---------------- exmem_rd = 0 matching rs1=0 ----------------
        reset_inputs();
        exmem_rd_addr = '0; idex_rs1_addr = '0;
        check("exmem_rd = 0 matching rs1=0", FWD_REG, FWD_REG, 1'b0);

        // ---------------- memwb_rd = 0 matching rs1=0 ----------------
        reset_inputs();
        memwb_rd_addr = '0; idex_rs1_addr = '0;
        check("memwb_rd = 0 matching rs1=0", FWD_REG, FWD_REG, 1'b0);

        // ---------------- exmem_RegWEn = 0, addrs match ----------------
        reset_inputs();
        exmem_rd_addr = idex_rs1_addr; exmem_RegWEn = 1'b0;
        check("exmem_RegWEn = 0, addrs match", FWD_REG, FWD_REG, 1'b0);

        // ---------------- memwb_RegWEn = 0, addrs match ----------------
        reset_inputs();
        memwb_rd_addr = idex_rs1_addr; memwb_RegWEn = 1'b0;
        check("memwb_RegWEn = 0, addrs match", FWD_REG, FWD_REG, 1'b0);

        // ---------------- memwb_rd == exmem_rs2, WEn=1 (WM) ----------------
        reset_inputs();
        memwb_rd_addr = exmem_rs2_addr;
        check("memwb_rd == exmem_rs2, WEn=1 (WM)", FWD_REG, FWD_REG, 1'b1);

        // ---------------- memwb_rd = 0 matching exmem_rs2 = 0 ----------------
        reset_inputs();
        memwb_rd_addr = '0; exmem_rs2_addr = '0;
        check("memwb_rd = 0 matching exmem_rs2 = 0", FWD_REG, FWD_REG, 1'b0);

        // ---------------- memwb_RegWEn = 0, WM addrs match ----------------
        reset_inputs();
        memwb_rd_addr = exmem_rs2_addr; memwb_RegWEn = 1'b0;
        check("memwb_RegWEn = 0, WM addrs match", FWD_REG, FWD_REG, 1'b0);

        // ---------------- SIMULTANEOUS MX ON A, WX ON B ----------------
        // Catches the copy-paste bug where the fwd_b block compares rs1.
        reset_inputs();
        exmem_rd_addr = idex_rs1_addr; memwb_rd_addr = idex_rs2_addr;
        check("simultaneous MX on A, WX on B", FWD_MX, FWD_WX, 1'b0);

        $display("\n=========== SUMMARY ===========");
        $display("=== %0d/%0d passed, %0d errors ===", tests - errors, tests, errors);
        if(errors == 0) 
            $display("ALL TESTS PASSED");
        else            
            $display("Failed: %0d test(s)", errors);
        $finish;
    end

endmodule