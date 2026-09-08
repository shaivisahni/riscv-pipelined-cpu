`timescale 1ns/1ps

import phantom_pkg::*;

module EX_MEM_reg_tb;

    logic clk, rst;
    ex_mem_t ex_mem_next;
    ex_mem_t ex_mem_out;
    int errors = 0;

    EX_MEM_reg DUT(
        .clk(clk),
        .rst(rst),
        .ex_mem_next(ex_mem_next),
        .ex_mem_out(ex_mem_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check(input string name, input ex_mem_t exp_ex_mem_out);
        @(posedge clk); #1;
        if(ex_mem_out !== exp_ex_mem_out) begin
            $display("[FAIL] %s", name);
            $display("  expected = %p", exp_ex_mem_out);
            $display("  got      = %p", ex_mem_out);
            errors++;
        end else begin
            $display("[PASS] %s", name);
        end
    endtask

    initial begin

        $display("=== EX/MEM Pipeline Register Testbench ===\n");

        ex_mem_next = '{
            ALU:        32'hDEADBEEF,
            rs2_data:   32'hAAAAAAAA,
            rd_addr:    5'b00011,
            pc_plus_4:  32'hCAFEBABE,
            RegWEn:     1'b1,
            MemRW:      1'b1,
            WBSel:      2'b01
        };

        // ---------------- STANDARD ----------------
        rst = 0;
        check("Standard", ex_mem_next);

        // ---------------- RESET ----------------
        rst = 1'b1;
        check("Reset", '0);

        // ---------------- SUMMARY ---------------- 
        $display("\n=== Summary ===");
        if(errors == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("FAILED %0d test(s)", errors);
        end
        $finish;
    end

endmodule