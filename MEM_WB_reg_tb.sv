`timescale 1ns/1ps

import phantom_pkg::*;

module MEM_WB_reg_tb;

    logic       clk, rst;
    mem_wb_t    mem_wb_next, mem_wb_out;
    int errors = 0;

    MEM_WB_reg DUT(
        .clk(clk),
        .rst(rst),
        .mem_wb_next(mem_wb_next),
        .mem_wb_out(mem_wb_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check(input string name, input mem_wb_t expected);
        @(posedge clk); #1;
        if(mem_wb_out !== expected) begin
            $display("[FAIL] %s", name);
            $display("  expected = %p", expected);
            $display("  got = %p", mem_wb_out);
            errors++;
        end else begin
            $display("[PASS] %s", name);
        end
    endtask

    initial begin
        $display("=== MEM/WB Pipeline Register Testbench ===\n");

        mem_wb_next = '{
            DataR:          32'hDEADBEEF,
            ALU:            32'hAAAAAAAA,
            pc_plus_4:      32'hCAFEBABE,
            rd_addr:        5'b00011,
            RegWEn:     1'b1,
            WBSel:      2'b01
        };

        // ---------------- STANDARD ----------------
        rst = 0;
        check("Standard", mem_wb_next);

        // ---------------- RESET ----------------
        rst = 1;
        check("Reset", '0);

        // ---------------- SUMMARY ----------------
        $display("\n=== Summary ===");
        if(errors == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("FAILED: %0d test(s)", errors);
        end
        $finish;
    end
endmodule