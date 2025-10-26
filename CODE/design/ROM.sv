`timescale 1ns / 1ps

module ROM (
    input  logic [31:0] addr,
    output logic [31:0] data
);
    logic [31:0] rom[0:2**15-1];

    initial begin
        $readmemh("code.mem", rom); 
        /*
        // R-Type Instructions (opcode = 0110011)
        rom[0] = 32'b0000000_00001_00010_000_00100_0110011;  // add x4, x2, x1
        rom[1] = 32'b0100000_00001_00010_000_00101_0110011;  // sub x5, x2, x1
        rom[2] = 32'b0000000_00000_00011_111_00110_0110011;  // and x6, x3, x0
        rom[3] = 32'b0000000_00000_00011_110_00111_0110011;  // or  x7, x3, x0

        // I-Type (ALU Immediate) Instructions (opcode = 0010011)
        rom[4] = 32'b000000000001_00001_000_01001_0010011;  // addi x9, x1, 1
        rom[5] = 32'b000000000100_00010_111_01010_0010011;  // andi x10, x2, 4
        rom[6] = 32'b000000000011_00001_001_01011_0010011;  // slli x11, x1, 3
        rom[7] = 32'b00000001001_00001_001_01100_0010011;  // slli x12, x1, 9
        rom[8] = 32'b000000011110_00001_001_01101_0010011;  // slli x13, x1, 30

        // B-Type (Branch) Instruction (opcode = 1100011)
        rom[9] = 32'b0000000_00010_00001_000_01000_1100011;  // beq x1, x2, 8

        // S-Type (Store) Instructions (opcode = 0100011)
        rom[10] = 32'b0000000_01011_00000_000_00100_0100011;  // sb x11, 4(x0)
        rom[11] = 32'b0000000_01100_00000_001_01000_0100011;  // sh x12, 8(x0)
        rom[12] = 32'b0000000_01101_00000_010_01100_0100011;  // sw x13, 12(x0)

        // I-Type (Load) Instructions (opcode = 0000011)
        rom[13] = 32'b000000000100_00000_000_01110_0000011;  // lb x14, 4(x0)
        rom[14] = 32'b000000001000_00000_001_01111_0000011;  // lh x15, 8(x0)
        rom[15] = 32'b000000001100_00000_010_10000_0000011;  // lw x16, 12(x0)

        // U-Type (Load Upper Immediate) Instruction (opcode = 0110111)
        rom[16] = 32'b00010000000000000000_10001_0110111;  // lui x17, 0x10000

        // --- 수정된 명령어 ---
        // UJ-Type (Jump and Link) Instruction (opcode = 1101111)
        rom[17] = 32'b00000000110000000000100101101111; // jal x18, 12      (rd=x18, imm=12 -> target=PC+12, x18=PC+4)

        // I-Type (Jump and Link Register) Instruction (opcode = 1100111)
        rom[20] = 32'b00000000111000001000101011100111; // jalr x19, x17, 0 (rd=x19, rs1=x17, funct3=000, imm=0 -> target=x17+0, x19=PC+4)
        */
    end

    assign data = rom[addr[31:2]];
endmodule
