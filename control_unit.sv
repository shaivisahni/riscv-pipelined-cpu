import phantom_pkg::*;

module control_unit(
    input  logic [31:0] inst,
    output ctrl_t       ctrl
);

    // Instruction field extraction
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7_5;   // inst[30], distinguishes ADD/SUB, SRL/SRA

    assign opcode   = inst[6:0];
    assign funct3   = inst[14:12];
    assign funct7_5 = inst[30];

    // Opcode constants (RV32I)
    localparam logic [6:0] OP_R      = 7'b0110011;  // R-type
    localparam logic [6:0] OP_I      = 7'b0010011;  // I-type ALU
    localparam logic [6:0] OP_LOAD   = 7'b0000011;
    localparam logic [6:0] OP_STORE  = 7'b0100011;
    localparam logic [6:0] OP_BRANCH = 7'b1100011;
    localparam logic [6:0] OP_JAL    = 7'b1101111;
    localparam logic [6:0] OP_JALR   = 7'b1100111;
    localparam logic [6:0] OP_LUI    = 7'b0110111;
    localparam logic [6:0] OP_AUIPC  = 7'b0010111;

    // ALU op constants
    localparam logic [3:0] ALU_ADD    = 4'b0000;
    localparam logic [3:0] ALU_PASS_B = 4'b1111;

    always_comb begin
        // ---- Safe defaults (a NOP-ish do-nothing) ----
        ctrl.RegWEn    = 1'b0;
        ctrl.ASel      = 1'b0;
        ctrl.BSel      = 1'b0;
        ctrl.ALUSel    = ALU_ADD;
        ctrl.MemRW     = 1'b0;      // read
        ctrl.WBSel     = 2'b01;     // ALU (harmless default)
        ctrl.BrUn      = 1'b0;
        ctrl.is_branch = 1'b0;
        ctrl.is_jump   = 1'b0;
        ctrl.funct3    = funct3;

        case (opcode)

            OP_R: begin
                ctrl.RegWEn = 1'b1;
                ctrl.ASel   = 1'b0;               // rs1
                ctrl.BSel   = 1'b0;               // rs2
                ctrl.ALUSel = {funct7_5, funct3}; // native R-type encoding
                ctrl.WBSel  = 2'b01;              // ALU
            end

            OP_I: begin
                ctrl.RegWEn = 1'b1;
                ctrl.ASel   = 1'b0;               // rs1
                ctrl.BSel   = 1'b1;               // imm
                ctrl.WBSel  = 2'b01;              // ALU
                // Option A: shifts use funct7_5, others force top bit 0
                if (funct3 == 3'b001 || funct3 == 3'b101)
                    ctrl.ALUSel = {funct7_5, funct3};  // SLLI/SRLI/SRAI
                else
                    ctrl.ALUSel = {1'b0, funct3};      // ADDI/SLTI/etc.
            end

            OP_LOAD: begin
                ctrl.RegWEn = 1'b1;
                ctrl.ASel   = 1'b0;      // rs1
                ctrl.BSel   = 1'b1;      // imm
                ctrl.ALUSel = ALU_ADD;   // address = rs1 + imm
                ctrl.MemRW  = 1'b0;      // read
                ctrl.WBSel  = 2'b00;     // mem data
            end

            OP_STORE: begin
                ctrl.RegWEn = 1'b0;      // no writeback
                ctrl.ASel   = 1'b0;      // rs1
                ctrl.BSel   = 1'b1;      // imm
                ctrl.ALUSel = ALU_ADD;   // address = rs1 + imm
                ctrl.MemRW  = 1'b1;      // write
            end

            OP_BRANCH: begin
                ctrl.RegWEn    = 1'b0;
                ctrl.ASel      = 1'b1;      // PC
                ctrl.BSel      = 1'b1;      // imm  → ALU computes PC+imm (target)
                ctrl.ALUSel    = ALU_ADD;
                ctrl.is_branch = 1'b1;
                // BrUn: unsigned for BLTU(110)/BGEU(111)
                ctrl.BrUn      = (funct3 == 3'b110 || funct3 == 3'b111);
            end

            OP_JAL: begin
                ctrl.RegWEn  = 1'b1;
                ctrl.ASel    = 1'b1;      // PC
                ctrl.BSel    = 1'b1;      // imm  → target = PC+imm
                ctrl.ALUSel  = ALU_ADD;
                ctrl.WBSel   = 2'b10;     // PC+4 (return address)
                ctrl.is_jump = 1'b1;
            end

            OP_JALR: begin
                ctrl.RegWEn  = 1'b1;
                ctrl.ASel    = 1'b0;      // rs1  → target = rs1+imm
                ctrl.BSel    = 1'b1;      // imm
                ctrl.ALUSel  = ALU_ADD;
                ctrl.WBSel   = 2'b10;     // PC+4
                ctrl.is_jump = 1'b1;
            end

            OP_LUI: begin
                ctrl.RegWEn = 1'b1;
                ctrl.BSel   = 1'b1;         // imm
                ctrl.ALUSel = ALU_PASS_B;   // pass immediate through
                ctrl.WBSel  = 2'b01;        // ALU
            end

            OP_AUIPC: begin
                ctrl.RegWEn = 1'b1;
                ctrl.ASel   = 1'b1;      // PC
                ctrl.BSel   = 1'b1;      // imm  → PC + imm
                ctrl.ALUSel = ALU_ADD;
                ctrl.WBSel  = 2'b01;     // ALU
            end

            default: begin
                // Unknown opcode → do nothing (all defaults, RegWEn=0)
            end

        endcase
    end

endmodule