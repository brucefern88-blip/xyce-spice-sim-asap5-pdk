// ============================================================================
// ASAP5 Standard Cell Library -- Behavioral Verilog for Yosys
// Process: ASAP5 5nm GAA Nanosheet, LVT
// Corner: TT (typical-typical)
// VDD: 0.5V
// Temperature: 25C
// Generated: 2026-03-18
// ============================================================================

module INVx1 (input A, output Y);
  assign Y = ~A;
endmodule

module INVx2 (input A, output Y);
  assign Y = ~A;
endmodule

module INVx4 (input A, output Y);
  assign Y = ~A;
endmodule

module NAND2x1 (input A, input B, output Y);
  assign Y = ~(A & B);
endmodule

module NOR2x1 (input A, input B, output Y);
  assign Y = ~(A | B);
endmodule

module AOI21x1 (input A0, input A1, input B, output Y);
  assign Y = ~((A0 & A1) | B);
endmodule

module OAI21x1 (input A0, input A1, input B, output Y);
  assign Y = ~((A0 | A1) & B);
endmodule

module XOR2x1 (input A, input B, output Y);
  assign Y = A ^ B;
endmodule

module XOR2x2 (input A, input B, output Y);
  assign Y = A ^ B;
endmodule

module XNOR2x1 (input A, input B, output Y);
  assign Y = ~(A ^ B);
endmodule

module XNOR2x2 (input A, input B, output Y);
  assign Y = ~(A ^ B);
endmodule

module MUX21x1 (input D0, input D1, input S, output Y);
  assign Y = S ? D1 : D0;
endmodule

// ============================================================================
// Fused Hamming Cells
// ============================================================================

module FUSED_G (input ai, input bi, input aj, input bj,
                output noh1, output noh2);
  wire x0 = ai ^ bi;
  wire x1 = aj ^ bj;
  assign noh1 = ~(x0 ^ x1);   // active-low hd=1
  assign noh2 = ~(x0 & x1);   // active-low hd=2
endmodule

module FUSED_A (input ai, input bi, input aj, input bj,
                output oh0, output oh1, output oh2);
  wire d0 = ai ^ bi;
  wire d1 = aj ^ bj;
  assign oh0 = ~d0 & ~d1;     // hd=0: both match
  assign oh1 = d0 ^ d1;       // hd=1: exactly one differs
  assign oh2 = d0 & d1;       // hd=2: both differ
endmodule

module FUSED_E (input ai, input bi, input aj, input bj,
                output oh0, output oh1, output oh2);
  wire d0 = ai ^ bi;
  wire d1 = aj ^ bj;
  assign oh0 = ~d0 & ~d1;
  assign oh1 = d0 ^ d1;
  assign oh2 = d0 & d1;
endmodule

module FUSED_F (input ai, input bi, input aj, input bj,
                output oh1, output oh2);
  wire d0 = ai ^ bi;
  wire d1 = aj ^ bj;
  assign oh1 = d0 ^ d1;
  assign oh2 = d0 & d1;
endmodule

module BUFx1 (input A, output Y);
  assign Y = A;
endmodule

// Zero-transistor crosspoint via cells (passive wire connections)
module AND2via (input A, input B, output Y);
  assign Y = A & B;  // Physical: via at crosspoint intersection
endmodule

module OR2via (input A, input B, output Y);
  assign Y = A | B;  // Physical: shared metal wire collecting via taps
endmodule
