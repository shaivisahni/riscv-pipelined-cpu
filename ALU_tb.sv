`timescale 1ns/1ps

module ALU_tb;

  logic [31:0] A, B, result;
  logic [3:0]  ALUSel;

  ALU dut (.A(A), .B(B), .ALUSel(ALUSel), .result(result));

  int errors = 0;

  task check(input logic [31:0] exp, input string name);
    if (result !== exp) begin
      $error("%s: A=%h B=%h ALUSel=%b -> got %h, expected %h",
             name, A, B, ALUSel, result, exp);
      errors++;
    end
  endtask

  initial begin
    A = 32'd5; B = 32'd3; ALUSel = 4'b0000; #1; check(32'd8, "ADD");
    A = 32'd10; B = 32'd11; ALUSel = 4'b1000; #1; check(-32'sd1, "SUB");                  //   SUB   (4'b1000)
    A = 32'b0110; B = 32'b1111; ALUSel = 4'b0100; #1; check(32'b1001, "XOR");              //   XOR   (4'b0100)
    A = 32'b01001000; B = 32'b10110111; ALUSel = 4'b0110; #1; check(32'b11111111, "OR");  //   OR    (4'b0110)
    A = 32'b0101; B = 32'b1111; ALUSel = 4'b0111; #1; check(32'b0101, "AND");             //   AND   (4'b0111)
    A = 32'b11111111; B = 32'd5; ALUSel = 4'b0001; #1; check(32'b1111111100000, "SLL");    //   SLL   (4'b0001)
    A = 32'hFFFF_FFFF; B = 32'd1; ALUSel = 4'b0101; #1; check(32'h7FFF_FFFF, "SRL");      //   SRL   (4'b0101)
    A = 32'hFFFF_FFFF; B = 32'd1; ALUSel = 4'b1101; #1; check(32'hFFFF_FFFF, "SRA");      //   SRA   (4'b1101)
    A = -32'sd1; B = 32'sd1; ALUSel = 4'b0010; #1; check({31'b0,1'b1}, "SLT");            //   SLT   (4'b0010)  
    A = -32'sd1; B = 32'sd1; ALUSel = 4'b0011; #1; check(32'd0, "SLTU");                  //   SLTU  (4'b0011) 

    if (errors == 0) $display("ALU_tb PASSED");
    else             $error("ALU_tb FAILED: %0d errors", errors);
    $finish;
  end
endmodule