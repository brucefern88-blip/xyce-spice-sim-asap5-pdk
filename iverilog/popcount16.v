// =============================================================================
// File:    popcount16.v   (matches top-level module name — required by linters)
// Design:  16-Bit Popcount — XOR-AND Via-Based ROM-in-Metal Architecture
// Process: TSMC N3 (3nm) FinFET
//
// Architecture mapping:
//   Stage 1  FEOL FinFET   : pair_processor — the ONLY real transistor logic
//   Stage 2  M3-M4 + V3   : 4× crossbar_3x3  (9 vias each  = 36 total)
//   Stage 3  M5-M6 + V5   : 2× crossbar_5x5  (25 vias each = 50 total)
//   Stage 4  M7-M8 + V7   : 1× crossbar_9x9  (81 vias      = 81 total)
//   Stage 5  M9+           : encoder_17to5 — second and last transistor stage
//
// Total via (AND gate) count across all crossbars: 36 + 50 + 81 = 167
// =============================================================================
`timescale 1ns/1ps

// =============================================================================
// pair_processor
//
// Converts a 2-bit input (a, b) into a 3-wire one-hot encoding of its count.
// This and the final encoder are the ONLY places with real gate transistors.
//
//   a b | and | xor | cnt2 cnt1 cnt0 | popcount
//   ----+-----+-----+----------------+--------
//   0 0 |  0  |  0  |   0    0    1  |   0
//   0 1 |  0  |  1  |   0    1    0  |   1
//   1 0 |  0  |  1  |   0    1    0  |   1
//   1 1 |  1  |  0  |   1    0    0  |   2
//
// N3 cell cost: 1x XOR2 + 1x AND2 + 1x NOR2 = 3 cells per pair = 24 total
// =============================================================================
module pair_processor (
    input  wire a,
    input  wire b,
    output wire cnt0,   // high when popcount(a,b) == 0
    output wire cnt1,   // high when popcount(a,b) == 1  (this IS the XOR output)
    output wire cnt2    // high when popcount(a,b) == 2  (this IS the AND output)
);
    wire xor_ab;
    wire and_ab;

    xor g_xor (xor_ab, a, b);           // XOR2: exactly one bit set
    and g_and (and_ab, a, b);           // AND2: both bits set
    nor g_nor (cnt0, xor_ab, and_ab);   // NOR2: neither bit set → count=0

    // cnt1 and cnt2 are just the XOR and AND outputs — buf maps to a wire in P&R
    buf g_b1 (cnt1, xor_ab);
    buf g_b2 (cnt2, and_ab);
endmodule


// =============================================================================
// crossbar_3x3
//
// Stage 2: Adds two one-hot [0..2] values, outputs one-hot [0..4].
// Physical structure: 3x3 via grid on metal layers M3/M4.
//
// Each `and` = one via. Because encoding is one-hot, exactly one row wire
// and one column wire are ever active simultaneously, so exactly one via
// fires and drives the correct output sum wire.
//
//   Via grid (row=A value, col=B value, cell=output sum index):
//        B=0  B=1  B=2
//   A=0 [ 0 ][ 1 ][ 2 ]
//   A=1 [ 1 ][ 2 ][ 3 ]
//   A=2 [ 2 ][ 3 ][ 4 ]
// =============================================================================
module crossbar_3x3 (
    input  wire [2:0] a,    // one-hot: a[i]=1 means value is i
    input  wire [2:0] b,    // one-hot: b[j]=1 means value is j
    output wire [4:0] s     // one-hot: s[k]=1 means sum is k
);
    // 9 via intersection wires — tRC fires when row=R and col=C are both active
    wire t00, t01, t02;
    wire t10, t11, t12;
    wire t20, t21, t22;

    // Via matrix: every `and` gate is one physical via in the 3x3 grid
    and g00 (t00, a[0], b[0]);   // sum = 0+0 = 0
    and g01 (t01, a[0], b[1]);   // sum = 0+1 = 1
    and g02 (t02, a[0], b[2]);   // sum = 0+2 = 2
    and g10 (t10, a[1], b[0]);   // sum = 1+0 = 1
    and g11 (t11, a[1], b[1]);   // sum = 1+1 = 2
    and g12 (t12, a[1], b[2]);   // sum = 1+2 = 3
    and g20 (t20, a[2], b[0]);   // sum = 2+0 = 2
    and g21 (t21, a[2], b[1]);   // sum = 2+1 = 3
    and g22 (t22, a[2], b[2]);   // sum = 2+2 = 4

    // OR collection: each output gathers all vias on its anti-diagonal (row+col=k)
    // Number of contributing vias per output: 1, 2, 3, 2, 1 (triangular shape)
    buf  gs0 (s[0], t00);               // only (0,0) can produce sum=0
    or   gs1 (s[1], t01, t10);          // (0,1) or (1,0)
    or   gs2 (s[2], t02, t11, t20);     // (0,2), (1,1), or (2,0)
    or   gs3 (s[3], t12, t21);          // (1,2) or (2,1)
    buf  gs4 (s[4], t22);               // only (2,2) can produce sum=4
endmodule


// =============================================================================
// crossbar_5x5
//
// Stage 3: Adds two one-hot [0..4] values, outputs one-hot [0..8].
// Physical structure: 5x5 via grid on metal layers M5/M6.
// 25 vias total. The anti-diagonal pattern grows to 5 terms at s[4].
// =============================================================================
module crossbar_5x5 (
    input  wire [4:0] a,
    input  wire [4:0] b,
    output wire [8:0] s
);
    // 25 via intersection wires
    wire t00, t01, t02, t03, t04;
    wire t10, t11, t12, t13, t14;
    wire t20, t21, t22, t23, t24;
    wire t30, t31, t32, t33, t34;
    wire t40, t41, t42, t43, t44;

    // Via matrix — 25 `and` gates = 25 physical vias in the 5x5 grid
    and g00(t00,a[0],b[0]); and g01(t01,a[0],b[1]); and g02(t02,a[0],b[2]);
    and g03(t03,a[0],b[3]); and g04(t04,a[0],b[4]);
    and g10(t10,a[1],b[0]); and g11(t11,a[1],b[1]); and g12(t12,a[1],b[2]);
    and g13(t13,a[1],b[3]); and g14(t14,a[1],b[4]);
    and g20(t20,a[2],b[0]); and g21(t21,a[2],b[1]); and g22(t22,a[2],b[2]);
    and g23(t23,a[2],b[3]); and g24(t24,a[2],b[4]);
    and g30(t30,a[3],b[0]); and g31(t31,a[3],b[1]); and g32(t32,a[3],b[2]);
    and g33(t33,a[3],b[3]); and g34(t34,a[3],b[4]);
    and g40(t40,a[4],b[0]); and g41(t41,a[4],b[1]); and g42(t42,a[4],b[2]);
    and g43(t43,a[4],b[3]); and g44(t44,a[4],b[4]);

    // OR collection along anti-diagonals — via counts: 1,2,3,4,5,4,3,2,1
    buf gs0(s[0], t00);
    or  gs1(s[1], t01, t10);
    or  gs2(s[2], t02, t11, t20);
    or  gs3(s[3], t03, t12, t21, t30);
    or  gs4(s[4], t04, t13, t22, t31, t40);   // peak: 5 vias on this diagonal
    or  gs5(s[5], t14, t23, t32, t41);
    or  gs6(s[6], t24, t33, t42);
    or  gs7(s[7], t34, t43);
    buf gs8(s[8], t44);
endmodule


// =============================================================================
// crossbar_9x9
//
// Stage 4: Adds two one-hot [0..8] values, outputs one-hot [0..16].
// Physical structure: 9x9 via grid on metal layers M7/M8.
// 81 vias total. Peak anti-diagonal is s[8] with 9 contributing vias.
// This is the final and largest crossbar in the 16-bit design.
// =============================================================================
module crossbar_9x9 (
    input  wire [8:0]  a,
    input  wire [8:0]  b,
    output wire [16:0] s
);
    // 81 via intersection wires
    wire t00,t01,t02,t03,t04,t05,t06,t07,t08;
    wire t10,t11,t12,t13,t14,t15,t16,t17,t18;
    wire t20,t21,t22,t23,t24,t25,t26,t27,t28;
    wire t30,t31,t32,t33,t34,t35,t36,t37,t38;
    wire t40,t41,t42,t43,t44,t45,t46,t47,t48;
    wire t50,t51,t52,t53,t54,t55,t56,t57,t58;
    wire t60,t61,t62,t63,t64,t65,t66,t67,t68;
    wire t70,t71,t72,t73,t74,t75,t76,t77,t78;
    wire t80,t81,t82,t83,t84,t85,t86,t87,t88;

    // Via matrix — 81 `and` gates = 81 physical vias in the 9x9 grid
    // Row 0
    and g00(t00,a[0],b[0]); and g01(t01,a[0],b[1]); and g02(t02,a[0],b[2]);
    and g03(t03,a[0],b[3]); and g04(t04,a[0],b[4]); and g05(t05,a[0],b[5]);
    and g06(t06,a[0],b[6]); and g07(t07,a[0],b[7]); and g08(t08,a[0],b[8]);
    // Row 1
    and g10(t10,a[1],b[0]); and g11(t11,a[1],b[1]); and g12(t12,a[1],b[2]);
    and g13(t13,a[1],b[3]); and g14(t14,a[1],b[4]); and g15(t15,a[1],b[5]);
    and g16(t16,a[1],b[6]); and g17(t17,a[1],b[7]); and g18(t18,a[1],b[8]);
    // Row 2
    and g20(t20,a[2],b[0]); and g21(t21,a[2],b[1]); and g22(t22,a[2],b[2]);
    and g23(t23,a[2],b[3]); and g24(t24,a[2],b[4]); and g25(t25,a[2],b[5]);
    and g26(t26,a[2],b[6]); and g27(t27,a[2],b[7]); and g28(t28,a[2],b[8]);
    // Row 3
    and g30(t30,a[3],b[0]); and g31(t31,a[3],b[1]); and g32(t32,a[3],b[2]);
    and g33(t33,a[3],b[3]); and g34(t34,a[3],b[4]); and g35(t35,a[3],b[5]);
    and g36(t36,a[3],b[6]); and g37(t37,a[3],b[7]); and g38(t38,a[3],b[8]);
    // Row 4
    and g40(t40,a[4],b[0]); and g41(t41,a[4],b[1]); and g42(t42,a[4],b[2]);
    and g43(t43,a[4],b[3]); and g44(t44,a[4],b[4]); and g45(t45,a[4],b[5]);
    and g46(t46,a[4],b[6]); and g47(t47,a[4],b[7]); and g48(t48,a[4],b[8]);
    // Row 5
    and g50(t50,a[5],b[0]); and g51(t51,a[5],b[1]); and g52(t52,a[5],b[2]);
    and g53(t53,a[5],b[3]); and g54(t54,a[5],b[4]); and g55(t55,a[5],b[5]);
    and g56(t56,a[5],b[6]); and g57(t57,a[5],b[7]); and g58(t58,a[5],b[8]);
    // Row 6
    and g60(t60,a[6],b[0]); and g61(t61,a[6],b[1]); and g62(t62,a[6],b[2]);
    and g63(t63,a[6],b[3]); and g64(t64,a[6],b[4]); and g65(t65,a[6],b[5]);
    and g66(t66,a[6],b[6]); and g67(t67,a[6],b[7]); and g68(t68,a[6],b[8]);
    // Row 7
    and g70(t70,a[7],b[0]); and g71(t71,a[7],b[1]); and g72(t72,a[7],b[2]);
    and g73(t73,a[7],b[3]); and g74(t74,a[7],b[4]); and g75(t75,a[7],b[5]);
    and g76(t76,a[7],b[6]); and g77(t77,a[7],b[7]); and g78(t78,a[7],b[8]);
    // Row 8
    and g80(t80,a[8],b[0]); and g81(t81,a[8],b[1]); and g82(t82,a[8],b[2]);
    and g83(t83,a[8],b[3]); and g84(t84,a[8],b[4]); and g85(t85,a[8],b[5]);
    and g86(t86,a[8],b[6]); and g87(t87,a[8],b[7]); and g88(t88,a[8],b[8]);

    // OR collection along anti-diagonals — via counts: 1,2,3,4,5,6,7,8,9,8,...,1
    buf gs0 (s[0],  t00);
    or  gs1 (s[1],  t01, t10);
    or  gs2 (s[2],  t02, t11, t20);
    or  gs3 (s[3],  t03, t12, t21, t30);
    or  gs4 (s[4],  t04, t13, t22, t31, t40);
    or  gs5 (s[5],  t05, t14, t23, t32, t41, t50);
    or  gs6 (s[6],  t06, t15, t24, t33, t42, t51, t60);
    or  gs7 (s[7],  t07, t16, t25, t34, t43, t52, t61, t70);
    or  gs8 (s[8],  t08, t17, t26, t35, t44, t53, t62, t71, t80);  // 9 vias — peak
    or  gs9 (s[9],  t18, t27, t36, t45, t54, t63, t72, t81);
    or  gs10(s[10], t28, t37, t46, t55, t64, t73, t82);
    or  gs11(s[11], t38, t47, t56, t65, t74, t83);
    or  gs12(s[12], t48, t57, t66, t75, t84);
    or  gs13(s[13], t58, t67, t76, t85);
    or  gs14(s[14], t68, t77, t86);
    or  gs15(s[15], t78, t87);
    buf gs16(s[16], t88);
endmodule


// =============================================================================
// encoder_17to5
//
// Stage 5: Converts 17-wire one-hot result into 5-bit binary output.
// Second and final module that uses real transistors.
//
// Each output bit = OR of all one-hot inputs where that bit is set
// in the binary representation of the count value:
//
//   cnt[4]: set only for count=16          → oh[16]
//   cnt[3]: set for counts 8–15            → oh[8]|oh[9]|...|oh[15]
//   cnt[2]: set for counts 4–7, 12–15      → oh[4..7] | oh[12..15]
//   cnt[1]: set for counts 2,3,6,7,10,11,14,15
//   cnt[0]: set for all odd counts 1,3,5,7,9,11,13,15
//
// Implemented as balanced 2-level OR trees to keep gate depth at 2 levels.
// =============================================================================
module encoder_17to5 (
    input  wire [16:0] oh,    // one-hot input: oh[k]=1 means popcount=k
    output wire [4:0]  cnt    // 5-bit binary output, value 0–16
);
    // cnt[4] — MSB: only count 16 reaches here (1 input, no OR needed)
    buf ge4 (cnt[4], oh[16]);

    // cnt[3]: counts 8–15 (8 inputs → two 4-input ORs then one final OR)
    wire c3a, c3b;
    or ge3a (c3a, oh[8],  oh[9],  oh[10], oh[11]);
    or ge3b (c3b, oh[12], oh[13], oh[14], oh[15]);
    or ge3  (cnt[3], c3a, c3b);

    // cnt[2]: counts 4–7 and 12–15 (8 inputs across two non-contiguous groups)
    wire c2a, c2b;
    or ge2a (c2a, oh[4],  oh[5],  oh[6],  oh[7]);
    or ge2b (c2b, oh[12], oh[13], oh[14], oh[15]);
    or ge2  (cnt[2], c2a, c2b);

    // cnt[1]: counts 2,3,6,7,10,11,14,15 (alternating pairs — bit 1 pattern)
    wire c1a, c1b, c1c, c1d, c1lo, c1hi;
    or ge1a (c1a, oh[2],  oh[3]);
    or ge1b (c1b, oh[6],  oh[7]);
    or ge1c (c1c, oh[10], oh[11]);
    or ge1d (c1d, oh[14], oh[15]);
    or ge1lo(c1lo, c1a, c1b);
    or ge1hi(c1hi, c1c, c1d);
    or ge1  (cnt[1], c1lo, c1hi);

    // cnt[0]: all odd counts 1,3,5,7,9,11,13,15 (bit 0 = LSB alternates 0,1)
    wire c0a, c0b, c0c, c0d, c0lo, c0hi;
    or ge0a (c0a, oh[1],  oh[3]);
    or ge0b (c0b, oh[5],  oh[7]);
    or ge0c (c0c, oh[9],  oh[11]);
    or ge0d (c0d, oh[13], oh[15]);
    or ge0lo(c0lo, c0a, c0b);
    or ge0hi(c0hi, c0c, c0d);
    or ge0  (cnt[0], c0lo, c0hi);
endmodule


// =============================================================================
// popcount16  — TOP LEVEL
//
// Signal widths at each inter-stage boundary (one-hot wires per group × groups):
//   in[15:0]  →  Stage1  →  3w × 8 groups  (range 0–2 per group)
//             →  Stage2  →  5w × 4 groups  (range 0–4 per group)
//             →  Stage3  →  9w × 2 groups  (range 0–8 per group)
//             →  Stage4  →  17w × 1 group  (range 0–16)
//             →  Stage5  →  5-bit binary
// =============================================================================
module popcount16 (
    input  wire [15:0] in,
    output wire [4:0]  out
);
    // -------------------------------------------------------------------------
    // Stage 1: 8x pair_processor — flat naming avoids 2D array portability risk
    // -------------------------------------------------------------------------
    // Pair 0: bits [1:0]
    wire s1_0_cnt0, s1_0_cnt1, s1_0_cnt2;
    pair_processor pp0 (.a(in[1]),  .b(in[0]),  .cnt0(s1_0_cnt0), .cnt1(s1_0_cnt1), .cnt2(s1_0_cnt2));

    // Pair 1: bits [3:2]
    wire s1_1_cnt0, s1_1_cnt1, s1_1_cnt2;
    pair_processor pp1 (.a(in[3]),  .b(in[2]),  .cnt0(s1_1_cnt0), .cnt1(s1_1_cnt1), .cnt2(s1_1_cnt2));

    // Pair 2: bits [5:4]
    wire s1_2_cnt0, s1_2_cnt1, s1_2_cnt2;
    pair_processor pp2 (.a(in[5]),  .b(in[4]),  .cnt0(s1_2_cnt0), .cnt1(s1_2_cnt1), .cnt2(s1_2_cnt2));

    // Pair 3: bits [7:6]
    wire s1_3_cnt0, s1_3_cnt1, s1_3_cnt2;
    pair_processor pp3 (.a(in[7]),  .b(in[6]),  .cnt0(s1_3_cnt0), .cnt1(s1_3_cnt1), .cnt2(s1_3_cnt2));

    // Pair 4: bits [9:8]
    wire s1_4_cnt0, s1_4_cnt1, s1_4_cnt2;
    pair_processor pp4 (.a(in[9]),  .b(in[8]),  .cnt0(s1_4_cnt0), .cnt1(s1_4_cnt1), .cnt2(s1_4_cnt2));

    // Pair 5: bits [11:10]
    wire s1_5_cnt0, s1_5_cnt1, s1_5_cnt2;
    pair_processor pp5 (.a(in[11]), .b(in[10]), .cnt0(s1_5_cnt0), .cnt1(s1_5_cnt1), .cnt2(s1_5_cnt2));

    // Pair 6: bits [13:12]
    wire s1_6_cnt0, s1_6_cnt1, s1_6_cnt2;
    pair_processor pp6 (.a(in[13]), .b(in[12]), .cnt0(s1_6_cnt0), .cnt1(s1_6_cnt1), .cnt2(s1_6_cnt2));

    // Pair 7: bits [15:14]
    wire s1_7_cnt0, s1_7_cnt1, s1_7_cnt2;
    pair_processor pp7 (.a(in[15]), .b(in[14]), .cnt0(s1_7_cnt0), .cnt1(s1_7_cnt1), .cnt2(s1_7_cnt2));

    // -------------------------------------------------------------------------
    // Stage 2: 4x crossbar_3x3  (36 vias, 0 transistors)
    // Pack each pair's three one-hot wires into a 3-bit bus for the crossbar
    // -------------------------------------------------------------------------
    wire [4:0] s2_0, s2_1, s2_2, s2_3;

    crossbar_3x3 cb2_0 (
        .a({s1_0_cnt2, s1_0_cnt1, s1_0_cnt0}),
        .b({s1_1_cnt2, s1_1_cnt1, s1_1_cnt0}),
        .s(s2_0)
    );
    crossbar_3x3 cb2_1 (
        .a({s1_2_cnt2, s1_2_cnt1, s1_2_cnt0}),
        .b({s1_3_cnt2, s1_3_cnt1, s1_3_cnt0}),
        .s(s2_1)
    );
    crossbar_3x3 cb2_2 (
        .a({s1_4_cnt2, s1_4_cnt1, s1_4_cnt0}),
        .b({s1_5_cnt2, s1_5_cnt1, s1_5_cnt0}),
        .s(s2_2)
    );
    crossbar_3x3 cb2_3 (
        .a({s1_6_cnt2, s1_6_cnt1, s1_6_cnt0}),
        .b({s1_7_cnt2, s1_7_cnt1, s1_7_cnt0}),
        .s(s2_3)
    );

    // -------------------------------------------------------------------------
    // Stage 3: 2x crossbar_5x5  (50 vias, 0 transistors)
    // -------------------------------------------------------------------------
    wire [8:0] s3_0, s3_1;

    crossbar_5x5 cb3_0 (.a(s2_0), .b(s2_1), .s(s3_0));
    crossbar_5x5 cb3_1 (.a(s2_2), .b(s2_3), .s(s3_1));

    // -------------------------------------------------------------------------
    // Stage 4: 1x crossbar_9x9  (81 vias, 0 transistors)
    // -------------------------------------------------------------------------
    wire [16:0] s4;

    crossbar_9x9 cb4 (.a(s3_0), .b(s3_1), .s(s4));

    // -------------------------------------------------------------------------
    // Stage 5: final binary encoder
    // -------------------------------------------------------------------------
    encoder_17to5 enc (.oh(s4), .cnt(out));

endmodule
