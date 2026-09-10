import phantom_pkg::*;

module forwarding_unit (
    input logic [4:0] idex_rs1_addr,
    input logic [4:0] idex_rs2_addr,

    input logic [4:0] exmem_rd_addr,
    input logic       exmem_RegWEn,

    input logic [4:0] memwb_rd_addr,
    input logic       memwb_RegWEn,

    input logic [4:0] exmem_rs2_addr,

    output fwd_sel_e  fwd_a,
    output fwd_sel_e  fwd_b,
    output logic      fwd_wm
);

    always_comb begin
        fwd_a = FWD_REG;
        if(exmem_RegWEn && (exmem_rd_addr != 0) && (exmem_rd_addr == idex_rs1_addr))
            fwd_a = FWD_MX;
        else if(memwb_RegWEn && (memwb_rd_addr != 0) && (memwb_rd_addr == idex_rs1_addr))
            fwd_a = FWD_WX;
    end

    always_comb begin
        fwd_b = FWD_REG;
        if(exmem_RegWEn && (exmem_rd_addr != 0) && (exmem_rd_addr == idex_rs2_addr))
            fwd_b = FWD_MX;
        else if(memwb_RegWEn && (memwb_rd_addr != 0) && (memwb_rd_addr == idex_rs2_addr))
            fwd_b = FWD_WX;
    end
    always_comb begin
        fwd_wm = 1'b0;
        if(memwb_RegWEn && (memwb_rd_addr != 0) && (memwb_rd_addr == exmem_rs2_addr))
            fwd_wm = 1'b1;
    end

endmodule