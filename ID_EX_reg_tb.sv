`timescale 1ns/1ps

import phantom_pkg::*;

module ID_EX_reg_tb;

    logic clk, rst, stall, flush;
    id_ex_t id_ex_next, id_ex_out;
    int errors = 0;

    ID_EX_reg DUT(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .id_ex_next(id_ex_next),
        .id_ex_out(id_ex_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check(input string name, input id_ex_t expected);
        @(posedge clk); #1;
        if(id_ex_out !== expected) begin
            $display("[FAIL] %s", name);
            $display("  expected = %p", expected);
            $display("  got      = %p", id_ex_out);
            errors++;
        end else begin
            $display("[PASS] %s", name);
        end
    endtask

    initial begin
        $display("=== ID/EX Pipeline Register Testbench ===\n");

        // ---------------- STANDARD ----------------
        id_ex_next = '{
            pc:         32'h00000001,
            pc_plus_4:  32'h00000002,
            rs1_data:   32'hAAAAAAAA,
            rs2_data:   32'hBBBBBBBB,
            inst:       32'h00000013,
            rs1_addr:   5'd1,
            rs2_addr:   5'd2,
            rd_addr:    5'd3,
            ctrl:       '{                       
                RegWEn:    1'b1,
                ASel:      1'b0,
                BSel:      1'b1,
                ALUSel:    4'b0101,
                MemRW:     1'b1,
                WBSel:     2'b10,
                BrUn:      1'b1,
                is_branch: 1'b0,
                is_jump:   1'b0,
                funct3:    3'b011
            }
        };
        rst = 1'b0; stall = 1'b0; flush = 1'b0;
        check("STANDARD", id_ex_next);

        // ---------------- STALL ----------------
        stall = 1'b1;
        check("STALL", '0);

        // ---------------- FLUSH ----------------
        stall = 1'b0; flush = 1'b1; 
        check("FLUSH", '0);

        // ---------------- RESET ----------------
        flush = 1'b0; rst = 1'b1;
        check("RESET", '0);

        // ---------------- SUMMARY ----------------
        $display("\n=== Summary ===");
        if(errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("FAILED: %0d test(s)", errors);
        $finish;
    end

endmodule