module DMEM(
    input logic [31:0] addr, DataW,
    input logic clk, MemRW,
    output logic [31:0] DataR
);

logic [31:0] DMEM_mem [255:0];

always_ff @(posedge clk) begin
    if(MemRW) begin
      DMEM_mem[addr[9:2]] <= DataW;
    end
end

assign DataR = DMEM_mem[addr[9:2]];

endmodule