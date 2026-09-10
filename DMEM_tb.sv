`timescale 1ns/1ps

module DMEM_tb;

    logic [31:0] addr, DataW, DataR;
    logic clk, MemRW;
    int errors = 0;

    // Random addresses
    localparam logic [31:0] addrA = 32'h0000008E; // 142
    localparam logic [31:0] addrB = 32'h00000039; // 57
    localparam logic [31:0] addrC = 32'h0000000C; // 12
    localparam logic [31:0] addrD = 32'h0000000D; // 13

    // DUT
    DMEM dut(
        .addr(addr),
        .DataW(DataW),
        .clk(clk),
        .MemRW(MemRW),
        .DataR(DataR)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check(input string name,
                input logic [31:0] exp_DataR);
        #1;
        if(DataR !== exp_DataR) begin
            $display("[FAIL] %s", name);
            $display("  expected{DataR=0x%08h}", exp_DataR);
            $display("  got{DataR=0x%08h}", DataR);
            errors++;
        end else begin
            $display("[PASS] %s : DataR=0x%08h", name, DataR);
        end
    endtask

    initial begin
        $display("=== DMEM Testbench ===\n");

        // ---------- write with MEMRW = 1, read back ----------
        addr = addrA; DataW = 32'hDEADBEEF; MemRW = 1'b1; 
        @(posedge clk); #1;
        MemRW = 1'b0;
        check("Write then read back", 32'hDEADBEEF);

        // ---------- MEMRW = 0 (GATING) ----------
        addr = addrA; DataW = 32'hFFFFFFFF; MemRW = 1'b0; 
        @(posedge clk); #1;
        check("MemRW GATING (write blocked)", 32'hDEADBEEF);

        // ---------- ASYNC READ ACROSS TWO ADDRESSES ----------
        addr = addrB; DataW = 32'hCAFEBABE; MemRW = 1'b1;
        @(posedge clk); #1;
        MemRW = 1'b0;
        addr = addrA; check("Async read addrA", 32'hDEADBEEF);
        addr = addrB; check("Async read addrB", 32'hCAFEBABE);

        // ---------- BYTE-OFFSET ----------
        addr = addrC; DataW = 32'hFFFFFFFF; MemRW = 1'b1;
        @(posedge clk); #1;
        addr = addrD; MemRW = 1'b0;
        check("Byte-offset write addrC (12), read addrD (13)", 32'hFFFFFFFF);

        // ---------- SUMMARY ----------
        $display("\n=== Summary ===");
        if(errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("FAILED: %0d test(s)", errors);
        $finish;
    end
endmodule