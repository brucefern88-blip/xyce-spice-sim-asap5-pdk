// ============================================================================
// ASAP5 Standard Cell Library -- Yosys Cell Mapping with Specify Timing
// Process: ASAP5 5nm GAA Nanosheet, LVT
// Corner: TT (typical-typical)
// VDD: 0.5V
// Temperature: 25C
// Generated: 2026-03-18
//
// Timing values from Liberty characterization (typical: 0.100ns slew, 1fF load)
// All delays in nanoseconds.
// ============================================================================

module INVx1 (input A, output Y);
  assign Y = ~A;
  specify
    (A => Y) = (0.094, 0.073);  // rise, fall delay
  endspecify
endmodule

module INVx2 (input A, output Y);
  assign Y = ~A;
  specify
    (A => Y) = (0.069, 0.056);
  endspecify
endmodule

module INVx4 (input A, output Y);
  assign Y = ~A;
  specify
    (A => Y) = (0.052, 0.045);
  endspecify
endmodule

module NAND2x1 (input A, input B, output Y);
  assign Y = ~(A & B);
  specify
    (A => Y) = (0.099, 0.116);
    (B => Y) = (0.099, 0.116);
  endspecify
endmodule

module NOR2x1 (input A, input B, output Y);
  assign Y = ~(A | B);
  specify
    (A => Y) = (0.160, 0.077);
    (B => Y) = (0.160, 0.077);
  endspecify
endmodule

module AOI21x1 (input A0, input A1, input B, output Y);
  assign Y = ~((A0 & A1) | B);
  specify
    (A0 => Y) = (0.296, 0.219);
    (A1 => Y) = (0.296, 0.219);
    (B => Y) = (0.296, 0.219);
  endspecify
endmodule

module OAI21x1 (input A0, input A1, input B, output Y);
  assign Y = ~((A0 | A1) & B);
  specify
    (A0 => Y) = (0.309, 0.199);
    (A1 => Y) = (0.309, 0.199);
    (B => Y) = (0.309, 0.199);
  endspecify
endmodule

module XOR2x1 (input A, input B, output Y);
  assign Y = A ^ B;
  specify
    (A => Y) = (0.157, 0.134);
    (B => Y) = (0.157, 0.134);
  endspecify
endmodule

module XOR2x2 (input A, input B, output Y);
  assign Y = A ^ B;
  specify
    (A => Y) = (0.085, 0.077);
    (B => Y) = (0.085, 0.077);
  endspecify
endmodule

module XNOR2x1 (input A, input B, output Y);
  assign Y = ~(A ^ B);
  specify
    (A => Y) = (0.157, 0.134);
    (B => Y) = (0.157, 0.134);
  endspecify
endmodule

module XNOR2x2 (input A, input B, output Y);
  assign Y = ~(A ^ B);
  specify
    (A => Y) = (0.085, 0.077);
    (B => Y) = (0.085, 0.077);
  endspecify
endmodule

module MUX21x1 (input D0, input D1, input S, output Y);
  assign Y = S ? D1 : D0;
  specify
    (D0 => Y) = (0.217, 0.192);
    (D1 => Y) = (0.217, 0.192);
    (S => Y) = (0.217, 0.192);
  endspecify
endmodule

// ============================================================================
// Fused Hamming Cells with specify timing
// Timing scaled from XOR2x1 (similar internal depth: INV+OAI22+AOI22 path)
// ============================================================================

module FUSED_G (input ai, input bi, input aj, input bj,
                output noh1, output noh2);
  wire x0 = ai ^ bi;
  wire x1 = aj ^ bj;
  assign noh1 = ~(x0 ^ x1);
  assign noh2 = ~(x0 & x1);
  specify
    (ai => noh1) = (0.180, 0.160);
    (bi => noh1) = (0.180, 0.160);
    (aj => noh1) = (0.180, 0.160);
    (bj => noh1) = (0.180, 0.160);
    (ai => noh2) = (0.140, 0.120);
    (bi => noh2) = (0.140, 0.120);
    (aj => noh2) = (0.140, 0.120);
    (bj => noh2) = (0.140, 0.120);
  endspecify
endmodule

module FUSED_A (input ai, input bi, input aj, input bj,
                output oh0, output oh1, output oh2);
  wire d0 = ai ^ bi;
  wire d1 = aj ^ bj;
  assign oh0 = ~d0 & ~d1;
  assign oh1 = d0 ^ d1;
  assign oh2 = d0 & d1;
  specify
    (ai => oh0) = (0.160, 0.140);
    (bi => oh0) = (0.160, 0.140);
    (aj => oh0) = (0.160, 0.140);
    (bj => oh0) = (0.160, 0.140);
    (ai => oh1) = (0.200, 0.180);
    (bi => oh1) = (0.200, 0.180);
    (aj => oh1) = (0.200, 0.180);
    (bj => oh1) = (0.200, 0.180);
    (ai => oh2) = (0.140, 0.120);
    (bi => oh2) = (0.140, 0.120);
    (aj => oh2) = (0.140, 0.120);
    (bj => oh2) = (0.140, 0.120);
  endspecify
endmodule

module FUSED_E (input ai, input bi, input aj, input bj,
                output oh0, output oh1, output oh2);
  wire d0 = ai ^ bi;
  wire d1 = aj ^ bj;
  assign oh0 = ~d0 & ~d1;
  assign oh1 = d0 ^ d1;
  assign oh2 = d0 & d1;
  specify
    (ai => oh0) = (0.160, 0.140);
    (bi => oh0) = (0.160, 0.140);
    (aj => oh0) = (0.160, 0.140);
    (bj => oh0) = (0.160, 0.140);
    (ai => oh1) = (0.190, 0.170);
    (bi => oh1) = (0.190, 0.170);
    (aj => oh1) = (0.190, 0.170);
    (bj => oh1) = (0.190, 0.170);
    (ai => oh2) = (0.130, 0.110);
    (bi => oh2) = (0.130, 0.110);
    (aj => oh2) = (0.130, 0.110);
    (bj => oh2) = (0.130, 0.110);
  endspecify
endmodule

module FUSED_F (input ai, input bi, input aj, input bj,
                output oh1, output oh2);
  wire d0 = ai ^ bi;
  wire d1 = aj ^ bj;
  assign oh1 = d0 ^ d1;
  assign oh2 = d0 & d1;
  specify
    (ai => oh1) = (0.195, 0.175);
    (bi => oh1) = (0.195, 0.175);
    (aj => oh1) = (0.195, 0.175);
    (bj => oh1) = (0.195, 0.175);
    (ai => oh2) = (0.135, 0.115);
    (bi => oh2) = (0.135, 0.115);
    (aj => oh2) = (0.135, 0.115);
    (bj => oh2) = (0.135, 0.115);
  endspecify
endmodule
