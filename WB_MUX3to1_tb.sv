`timescale 1ns/1ps

module WB_MUX3to1_tb;

    logic [31:0] mem, ALU, pc_plus_4;
    logic [1:0] sel;
    logic [31:0] result;
    int errors = 0;

    WB_MUX3to1 dut(
        .mem(mem),
        .ALU(ALU),
        .pc_plus_4(pc_plus_4),
        .sel(sel),
        .result(result)
    );
    
    task check(input string name, 
                input logic [31:0] exp_result);
        #1;
        if(result !== exp_result) begin
            $display("[FAIL] %s", name);
            $display("  Expected{result=0x%08h}", exp_result);
            $display("  Got{result=0x%08h}", result);
            errors++;
        end else begin  
            $display("[PASS] %s : result=0x%08h", name, result);
        end
    endtask

    initial begin
        $display("=== WRITEBACK MUX TESTBENCH ===\n");

        // ---------------- SELECT MEM ----------------
        mem = 32'hDEADBEEF; ALU = 32'hCAFEBABE; pc_plus_4 = 32'hBEEFDEAD;
        sel = 2'b00;
        check("Select mem", 32'hDEADBEEF);

        // ---------------- SELECT ALU ----------------
        sel = 2'b01;
        check("Select ALU", 32'hCAFEBABE);

        // ---------------- SELECT PC_PLUS_4 ----------------
        sel = 2'b10;
        check("Select pc_plus_4", 32'hBEEFDEAD);

        // ---------------- SELECT FOREIGN INPUT ----------------
        sel = 2'b11;
        check("Select foreign input", 32'h00000000);

        // ---------------- SUMMARY ----------------
        $display("\n=== Summary ===");
        if(errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("FAILED: %0d test(s)", errors);
    
        $finish;
    end

endmodule