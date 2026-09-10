package phantom_pkg;

    typedef enum logic [1:0] {
        FWD_REG = 2'b00,
        FWD_MX  = 2'b01,
        FWD_WX  = 2'b10
    } fwd_sel_e;

    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] pc_plus_4;
        logic [31:0] inst;
    } if_id_t;

// ---- Control signal bundle (decoded in ID, rides the pipeline) ----
    typedef struct packed {
        logic        RegWEn;     // 1 = write rd
        logic        ASel;       // 0 = rs1, 1 = PC
        logic        BSel;       // 0 = rs2, 1 = imm
        logic [3:0]  ALUSel;     // ALU operation (1111 = pass-B for LUI)
        logic        MemRW;      // 0 = read, 1 = write (DMEM)
        logic [1:0]  WBSel;      // 0 = mem, 1 = ALU, 2 = PC+4
        logic        BrUn;       // 1 = unsigned branch compare
        logic        is_branch;  // 1 = branch instruction (PCSel resolved in EX)
        logic        is_jump;    // 1 = JAL/JALR (unconditional PCSel=1)
        logic [2:0]  funct3;     // for EX-stage branch condition select
    } ctrl_t;

    typedef struct packed {
        logic [31:0]    pc;         // for branch target and AUIPC
        logic [31:0]    pc_plus_4;  // for JAL/JALR writeback (WB)
        logic [31:0]    rs1_data;   // ALU/BranchComp operand (EX)
        logic [31:0]    rs2_data;   // ALU/BranchComp operand + store data (EX/MEM)
        logic [31:0]    inst;       // for ImmGen in EX
        logic [4:0]     rs1_addr;   // inst[19:15] — for forwarding unit
        logic [4:0]     rs2_addr;   // inst[24:20] — for forwarding unit
        logic [4:0]     rd_addr;    // inst[11:7]  — destination, rides to WB
        ctrl_t          ctrl;       // all control signals
    } id_ex_t;

    typedef struct packed {
        logic [31:0]    ALU;
        logic [31:0]    rs2_data;   // DataW
        logic [4:0]     rs2_addr;
        logic [4:0]     rd_addr;    
        logic [31:0]    pc_plus_4;
        logic           RegWEn;
        logic           MemRW;
        logic [1:0]     WBSel;
    } ex_mem_t;

    typedef struct packed {
        logic [31:0]    DataR;
        logic [31:0]    ALU;    
        logic [31:0]    pc_plus_4;
        logic [4:0]     rd_addr;
        logic           RegWEn;
        logic [1:0]     WBSel;
    } mem_wb_t;

endpackage