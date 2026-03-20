// ============================================================================
// 64-BIT HAMMING DISTANCE — CUBOID RADIX-4 WITH PRESERVED CROSSPOINTS
// ============================================================================
// Restructured RTL: parameterized crosspoint_sum modules with keep_hierarchy
// Each crosspoint stage is a named module instance that Yosys will NOT flatten.
// Wired-AND (via) and wired-OR (collection) operations preserved per crosspoint.
//
// Architecture: 5 stages, 46 crosspoint structures, ~1,605 grid points
//   Stage 1:  64 XOR/XNOR + 32 fused cells (transistor + M1)
//   Stage 2:  16×(3×3) + 8×(5×5) byte-level crosspoints (M2/M3)
//   Stage 3:  Radix-4 digit split (M5 routing, no crosspoints)
//   Stage 4:  Low-digit tree + High-digit tree + carry addition
//   Stage 5:  Binary conversion (wired-OR grid)
//
// Target: TSMC N5 / ASAP5 (13-layer metal stack)
// ============================================================================

`timescale 1ps / 1fs

module hamming_64b_cuboid_r4_xp (
    input  wire [63:0] A,
    input  wire [63:0] B,
    output wire [6:0]  hd
);

    // ========================================================================
    // STAGE 1A: Per-Bit XOR and XNOR
    // ========================================================================
    wire [63:0] d;
    wire [63:0] dn;

    genvar gi;
    generate
        for (gi = 0; gi < 64; gi = gi + 1) begin : xor_stage
            assign d[gi]  = A[gi] ^ B[gi];
            assign dn[gi] = ~d[gi];
        end
    endgenerate

    // ========================================================================
    // STAGE 1B: 32 Fused Hamming Cells
    // ========================================================================
    // Use flat wires for port compatibility
    wire [95:0] cell_oh_flat;  // 32 cells × 3 bits = 96 wires

    generate
        for (gi = 0; gi < 32; gi = gi + 1) begin : fused_cell
            assign cell_oh_flat[3*gi+0] = dn[2*gi] & dn[2*gi+1];  // OH0: count=0
            assign cell_oh_flat[3*gi+1] = d[2*gi]  ^ d[2*gi+1];   // OH1: count=1
            assign cell_oh_flat[3*gi+2] = d[2*gi]  & d[2*gi+1];   // OH2: count=2
        end
    endgenerate

    // ========================================================================
    // STAGE 2, LEVEL 1: 16× 3×3 Crosspoints (M2/M3)
    // ========================================================================
    wire [79:0] ps_flat;  // 16 pair-sums × 5 bits = 80 wires

    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : xp3_s2l1
            crosspoint_sum #(.M(3), .N(3)) u_xp3 (
                .v(cell_oh_flat[6*gi+2 : 6*gi]),
                .h(cell_oh_flat[6*gi+5 : 6*gi+3]),
                .s(ps_flat[5*gi+4 : 5*gi])
            );
        end
    endgenerate

    // ========================================================================
    // STAGE 2, LEVEL 2: 8× 5×5 Crosspoints (M2/M3)
    // ========================================================================
    wire [71:0] byte_oh_flat;  // 8 byte sums × 9 bits = 72 wires

    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : xp5_s2l2
            crosspoint_sum #(.M(5), .N(5)) u_xp5 (
                .v(ps_flat[10*gi+4 : 10*gi]),
                .h(ps_flat[10*gi+9 : 10*gi+5]),
                .s(byte_oh_flat[9*gi+8 : 9*gi])
            );
        end
    endgenerate

    // ========================================================================
    // STAGE 3: Radix-4 Digit Split (M5 routing)
    // ========================================================================
    wire [31:0] lo_flat;  // 8 low digits × 4 bits = 32 wires
    wire [23:0] hi_flat;  // 8 high digits × 3 bits = 24 wires

    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : r4_split
            wire [8:0] boh = byte_oh_flat[9*gi+8 : 9*gi];

            assign lo_flat[4*gi+0] = boh[0] | boh[4] | boh[8];
            assign lo_flat[4*gi+1] = boh[1] | boh[5];
            assign lo_flat[4*gi+2] = boh[2] | boh[6];
            assign lo_flat[4*gi+3] = boh[3] | boh[7];

            assign hi_flat[3*gi+0] = boh[0] | boh[1] | boh[2] | boh[3];
            assign hi_flat[3*gi+1] = boh[4] | boh[5] | boh[6] | boh[7];
            assign hi_flat[3*gi+2] = boh[8];
        end
    endgenerate

    // ========================================================================
    // STAGE 4 LOW-DIGIT TREE
    // ========================================================================

    // Level 1: 4× 4×4 Crosspoints (M6)
    wire [27:0] ll1_flat;  // 4 × 7 bits = 28 wires

    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : xp4_lo_l1
            crosspoint_sum #(.M(4), .N(4)) u_xp4 (
                .v(lo_flat[8*gi+3 : 8*gi]),
                .h(lo_flat[8*gi+7 : 8*gi+4]),
                .s(ll1_flat[7*gi+6 : 7*gi])
            );
        end
    endgenerate

    // Level 2: 2× 7×7 Crosspoints (M7)
    wire [25:0] ll2_flat;  // 2 × 13 bits = 26 wires

    generate
        for (gi = 0; gi < 2; gi = gi + 1) begin : xp7_lo_l2
            crosspoint_sum #(.M(7), .N(7)) u_xp7 (
                .v(ll1_flat[14*gi+6 : 14*gi]),
                .h(ll1_flat[14*gi+13 : 14*gi+7]),
                .s(ll2_flat[13*gi+12 : 13*gi])
            );
        end
    endgenerate

    // Level 3: 1× 13×13 Crosspoint (M8)
    wire [24:0] low_sum;

    crosspoint_sum #(.M(13), .N(13)) u_xp13_lo_l3 (
        .v(ll2_flat[12:0]),
        .h(ll2_flat[25:13]),
        .s(low_sum)
    );

    // ========================================================================
    // STAGE 4 HIGH-DIGIT TREE
    // ========================================================================

    // Level 1: 4× 3×3 Crosspoints (M6)
    wire [19:0] hl1_flat;  // 4 × 5 bits = 20 wires

    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : xp3_hi_l1
            crosspoint_sum #(.M(3), .N(3)) u_xp3 (
                .v(hi_flat[6*gi+2 : 6*gi]),
                .h(hi_flat[6*gi+5 : 6*gi+3]),
                .s(hl1_flat[5*gi+4 : 5*gi])
            );
        end
    endgenerate

    // Level 2: 2× 5×5 Crosspoints (M7)
    wire [17:0] hl2_flat;  // 2 × 9 bits = 18 wires

    generate
        for (gi = 0; gi < 2; gi = gi + 1) begin : xp5_hi_l2
            crosspoint_sum #(.M(5), .N(5)) u_xp5 (
                .v(hl1_flat[10*gi+4 : 10*gi]),
                .h(hl1_flat[10*gi+9 : 10*gi+5]),
                .s(hl2_flat[9*gi+8 : 9*gi])
            );
        end
    endgenerate

    // Level 3: 1× 9×9 Crosspoint (M8)
    wire [16:0] high_sum;

    crosspoint_sum #(.M(9), .N(9)) u_xp9_hi_l3 (
        .v(hl2_flat[8:0]),
        .h(hl2_flat[17:9]),
        .s(high_sum)
    );

    // ========================================================================
    // STAGE 4C: Radix-4 Carry Split (M8 routing)
    // ========================================================================
    wire [3:0] final_lo;
    wire [6:0] carry;

    assign final_lo[0] = low_sum[0] | low_sum[4] | low_sum[8]  | low_sum[12] | low_sum[16] | low_sum[20] | low_sum[24];
    assign final_lo[1] = low_sum[1] | low_sum[5] | low_sum[9]  | low_sum[13] | low_sum[17] | low_sum[21];
    assign final_lo[2] = low_sum[2] | low_sum[6] | low_sum[10] | low_sum[14] | low_sum[18] | low_sum[22];
    assign final_lo[3] = low_sum[3] | low_sum[7] | low_sum[11] | low_sum[15] | low_sum[19] | low_sum[23];

    assign carry[0] = low_sum[0]  | low_sum[1]  | low_sum[2]  | low_sum[3];
    assign carry[1] = low_sum[4]  | low_sum[5]  | low_sum[6]  | low_sum[7];
    assign carry[2] = low_sum[8]  | low_sum[9]  | low_sum[10] | low_sum[11];
    assign carry[3] = low_sum[12] | low_sum[13] | low_sum[14] | low_sum[15];
    assign carry[4] = low_sum[16] | low_sum[17] | low_sum[18] | low_sum[19];
    assign carry[5] = low_sum[20] | low_sum[21] | low_sum[22] | low_sum[23];
    assign carry[6] = low_sum[24];

    // ========================================================================
    // STAGE 4D: Carry Addition — 1× 17×7 Crosspoint (M8)
    // ========================================================================
    wire [22:0] upper;

    crosspoint_sum #(.M(17), .N(7)) u_xp17x7_carry (
        .v(high_sum),
        .h(carry),
        .s(upper)
    );

    // ========================================================================
    // STAGE 5: Binary Conversion (M9 wired-OR grids)
    // ========================================================================
    assign hd[0] = final_lo[1] | final_lo[3];
    assign hd[1] = final_lo[2] | final_lo[3];

    assign hd[2] = upper[1]  | upper[3]  | upper[5]  | upper[7]
                 | upper[9]  | upper[11] | upper[13] | upper[15]
                 | upper[17] | upper[19] | upper[21];

    assign hd[3] = upper[2]  | upper[3]  | upper[6]  | upper[7]
                 | upper[10] | upper[11] | upper[14] | upper[15]
                 | upper[18] | upper[19] | upper[22];

    assign hd[4] = upper[4]  | upper[5]  | upper[6]  | upper[7]
                 | upper[12] | upper[13] | upper[14] | upper[15]
                 | upper[20] | upper[21] | upper[22];

    assign hd[5] = upper[8]  | upper[9]  | upper[10] | upper[11]
                 | upper[12] | upper[13] | upper[14] | upper[15];

    assign hd[6] = upper[16] | upper[17] | upper[18] | upper[19]
                 | upper[20] | upper[21] | upper[22];

endmodule
