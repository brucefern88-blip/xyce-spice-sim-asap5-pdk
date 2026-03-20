`timescale 1ps / 1fs
module hamming_64b_cuboid_r4_via (input wire [63:0] A, input wire [63:0] B, output wire [6:0] hd);
    wire [63:0] d, dn;
    genvar gi;
    generate for (gi=0; gi<64; gi=gi+1) begin : xor_stage
        assign d[gi] = A[gi] ^ B[gi]; assign dn[gi] = ~d[gi];
    end endgenerate

    // Stage 1B: 32 Fused Cells
    wire [95:0] cell_oh;
    generate for (gi=0; gi<32; gi=gi+1) begin : fc
        assign cell_oh[3*gi+0] = dn[2*gi] & dn[2*gi+1];
        assign cell_oh[3*gi+1] = d[2*gi] ^ d[2*gi+1];
        assign cell_oh[3*gi+2] = d[2*gi] & d[2*gi+1];
    end endgenerate

    // Stage 2 L1: 16x 3x3 via-grid macros
    wire [79:0] ps;
    XP_3x3_M2M3 xp3_s2l1_0 (.v0(cell_oh[0]), .v1(cell_oh[1]), .v2(cell_oh[2]), .h0(cell_oh[3]), .h1(cell_oh[4]), .h2(cell_oh[5]), .s0(ps[0]), .s1(ps[1]), .s2(ps[2]), .s3(ps[3]), .s4(ps[4]));
    XP_3x3_M2M3 xp3_s2l1_1 (.v0(cell_oh[6]), .v1(cell_oh[7]), .v2(cell_oh[8]), .h0(cell_oh[9]), .h1(cell_oh[10]), .h2(cell_oh[11]), .s0(ps[5]), .s1(ps[6]), .s2(ps[7]), .s3(ps[8]), .s4(ps[9]));
    XP_3x3_M2M3 xp3_s2l1_2 (.v0(cell_oh[12]), .v1(cell_oh[13]), .v2(cell_oh[14]), .h0(cell_oh[15]), .h1(cell_oh[16]), .h2(cell_oh[17]), .s0(ps[10]), .s1(ps[11]), .s2(ps[12]), .s3(ps[13]), .s4(ps[14]));
    XP_3x3_M2M3 xp3_s2l1_3 (.v0(cell_oh[18]), .v1(cell_oh[19]), .v2(cell_oh[20]), .h0(cell_oh[21]), .h1(cell_oh[22]), .h2(cell_oh[23]), .s0(ps[15]), .s1(ps[16]), .s2(ps[17]), .s3(ps[18]), .s4(ps[19]));
    XP_3x3_M2M3 xp3_s2l1_4 (.v0(cell_oh[24]), .v1(cell_oh[25]), .v2(cell_oh[26]), .h0(cell_oh[27]), .h1(cell_oh[28]), .h2(cell_oh[29]), .s0(ps[20]), .s1(ps[21]), .s2(ps[22]), .s3(ps[23]), .s4(ps[24]));
    XP_3x3_M2M3 xp3_s2l1_5 (.v0(cell_oh[30]), .v1(cell_oh[31]), .v2(cell_oh[32]), .h0(cell_oh[33]), .h1(cell_oh[34]), .h2(cell_oh[35]), .s0(ps[25]), .s1(ps[26]), .s2(ps[27]), .s3(ps[28]), .s4(ps[29]));
    XP_3x3_M2M3 xp3_s2l1_6 (.v0(cell_oh[36]), .v1(cell_oh[37]), .v2(cell_oh[38]), .h0(cell_oh[39]), .h1(cell_oh[40]), .h2(cell_oh[41]), .s0(ps[30]), .s1(ps[31]), .s2(ps[32]), .s3(ps[33]), .s4(ps[34]));
    XP_3x3_M2M3 xp3_s2l1_7 (.v0(cell_oh[42]), .v1(cell_oh[43]), .v2(cell_oh[44]), .h0(cell_oh[45]), .h1(cell_oh[46]), .h2(cell_oh[47]), .s0(ps[35]), .s1(ps[36]), .s2(ps[37]), .s3(ps[38]), .s4(ps[39]));
    XP_3x3_M2M3 xp3_s2l1_8 (.v0(cell_oh[48]), .v1(cell_oh[49]), .v2(cell_oh[50]), .h0(cell_oh[51]), .h1(cell_oh[52]), .h2(cell_oh[53]), .s0(ps[40]), .s1(ps[41]), .s2(ps[42]), .s3(ps[43]), .s4(ps[44]));
    XP_3x3_M2M3 xp3_s2l1_9 (.v0(cell_oh[54]), .v1(cell_oh[55]), .v2(cell_oh[56]), .h0(cell_oh[57]), .h1(cell_oh[58]), .h2(cell_oh[59]), .s0(ps[45]), .s1(ps[46]), .s2(ps[47]), .s3(ps[48]), .s4(ps[49]));
    XP_3x3_M2M3 xp3_s2l1_10 (.v0(cell_oh[60]), .v1(cell_oh[61]), .v2(cell_oh[62]), .h0(cell_oh[63]), .h1(cell_oh[64]), .h2(cell_oh[65]), .s0(ps[50]), .s1(ps[51]), .s2(ps[52]), .s3(ps[53]), .s4(ps[54]));
    XP_3x3_M2M3 xp3_s2l1_11 (.v0(cell_oh[66]), .v1(cell_oh[67]), .v2(cell_oh[68]), .h0(cell_oh[69]), .h1(cell_oh[70]), .h2(cell_oh[71]), .s0(ps[55]), .s1(ps[56]), .s2(ps[57]), .s3(ps[58]), .s4(ps[59]));
    XP_3x3_M2M3 xp3_s2l1_12 (.v0(cell_oh[72]), .v1(cell_oh[73]), .v2(cell_oh[74]), .h0(cell_oh[75]), .h1(cell_oh[76]), .h2(cell_oh[77]), .s0(ps[60]), .s1(ps[61]), .s2(ps[62]), .s3(ps[63]), .s4(ps[64]));
    XP_3x3_M2M3 xp3_s2l1_13 (.v0(cell_oh[78]), .v1(cell_oh[79]), .v2(cell_oh[80]), .h0(cell_oh[81]), .h1(cell_oh[82]), .h2(cell_oh[83]), .s0(ps[65]), .s1(ps[66]), .s2(ps[67]), .s3(ps[68]), .s4(ps[69]));
    XP_3x3_M2M3 xp3_s2l1_14 (.v0(cell_oh[84]), .v1(cell_oh[85]), .v2(cell_oh[86]), .h0(cell_oh[87]), .h1(cell_oh[88]), .h2(cell_oh[89]), .s0(ps[70]), .s1(ps[71]), .s2(ps[72]), .s3(ps[73]), .s4(ps[74]));
    XP_3x3_M2M3 xp3_s2l1_15 (.v0(cell_oh[90]), .v1(cell_oh[91]), .v2(cell_oh[92]), .h0(cell_oh[93]), .h1(cell_oh[94]), .h2(cell_oh[95]), .s0(ps[75]), .s1(ps[76]), .s2(ps[77]), .s3(ps[78]), .s4(ps[79]));

    // Stage 2 L2: 8x 5x5 via-grid macros
    wire [71:0] boh;
    XP_5x5_M2M3 xp5_s2l2_0 (.v0(ps[0]), .v1(ps[1]), .v2(ps[2]), .v3(ps[3]), .v4(ps[4]), .h0(ps[5]), .h1(ps[6]), .h2(ps[7]), .h3(ps[8]), .h4(ps[9]), .s0(boh[0]), .s1(boh[1]), .s2(boh[2]), .s3(boh[3]), .s4(boh[4]), .s5(boh[5]), .s6(boh[6]), .s7(boh[7]), .s8(boh[8]));
    XP_5x5_M2M3 xp5_s2l2_1 (.v0(ps[10]), .v1(ps[11]), .v2(ps[12]), .v3(ps[13]), .v4(ps[14]), .h0(ps[15]), .h1(ps[16]), .h2(ps[17]), .h3(ps[18]), .h4(ps[19]), .s0(boh[9]), .s1(boh[10]), .s2(boh[11]), .s3(boh[12]), .s4(boh[13]), .s5(boh[14]), .s6(boh[15]), .s7(boh[16]), .s8(boh[17]));
    XP_5x5_M2M3 xp5_s2l2_2 (.v0(ps[20]), .v1(ps[21]), .v2(ps[22]), .v3(ps[23]), .v4(ps[24]), .h0(ps[25]), .h1(ps[26]), .h2(ps[27]), .h3(ps[28]), .h4(ps[29]), .s0(boh[18]), .s1(boh[19]), .s2(boh[20]), .s3(boh[21]), .s4(boh[22]), .s5(boh[23]), .s6(boh[24]), .s7(boh[25]), .s8(boh[26]));
    XP_5x5_M2M3 xp5_s2l2_3 (.v0(ps[30]), .v1(ps[31]), .v2(ps[32]), .v3(ps[33]), .v4(ps[34]), .h0(ps[35]), .h1(ps[36]), .h2(ps[37]), .h3(ps[38]), .h4(ps[39]), .s0(boh[27]), .s1(boh[28]), .s2(boh[29]), .s3(boh[30]), .s4(boh[31]), .s5(boh[32]), .s6(boh[33]), .s7(boh[34]), .s8(boh[35]));
    XP_5x5_M2M3 xp5_s2l2_4 (.v0(ps[40]), .v1(ps[41]), .v2(ps[42]), .v3(ps[43]), .v4(ps[44]), .h0(ps[45]), .h1(ps[46]), .h2(ps[47]), .h3(ps[48]), .h4(ps[49]), .s0(boh[36]), .s1(boh[37]), .s2(boh[38]), .s3(boh[39]), .s4(boh[40]), .s5(boh[41]), .s6(boh[42]), .s7(boh[43]), .s8(boh[44]));
    XP_5x5_M2M3 xp5_s2l2_5 (.v0(ps[50]), .v1(ps[51]), .v2(ps[52]), .v3(ps[53]), .v4(ps[54]), .h0(ps[55]), .h1(ps[56]), .h2(ps[57]), .h3(ps[58]), .h4(ps[59]), .s0(boh[45]), .s1(boh[46]), .s2(boh[47]), .s3(boh[48]), .s4(boh[49]), .s5(boh[50]), .s6(boh[51]), .s7(boh[52]), .s8(boh[53]));
    XP_5x5_M2M3 xp5_s2l2_6 (.v0(ps[60]), .v1(ps[61]), .v2(ps[62]), .v3(ps[63]), .v4(ps[64]), .h0(ps[65]), .h1(ps[66]), .h2(ps[67]), .h3(ps[68]), .h4(ps[69]), .s0(boh[54]), .s1(boh[55]), .s2(boh[56]), .s3(boh[57]), .s4(boh[58]), .s5(boh[59]), .s6(boh[60]), .s7(boh[61]), .s8(boh[62]));
    XP_5x5_M2M3 xp5_s2l2_7 (.v0(ps[70]), .v1(ps[71]), .v2(ps[72]), .v3(ps[73]), .v4(ps[74]), .h0(ps[75]), .h1(ps[76]), .h2(ps[77]), .h3(ps[78]), .h4(ps[79]), .s0(boh[63]), .s1(boh[64]), .s2(boh[65]), .s3(boh[66]), .s4(boh[67]), .s5(boh[68]), .s6(boh[69]), .s7(boh[70]), .s8(boh[71]));

    // Stage 3: Radix-4 Split
    wire [31:0] lo; wire [23:0] hi;
    generate for (gi=0; gi<8; gi=gi+1) begin : r4
        assign lo[4*gi+0] = boh[9*gi+0] | boh[9*gi+4] | boh[9*gi+8];
        assign lo[4*gi+1] = boh[9*gi+1] | boh[9*gi+5];
        assign lo[4*gi+2] = boh[9*gi+2] | boh[9*gi+6];
        assign lo[4*gi+3] = boh[9*gi+3] | boh[9*gi+7];
        assign hi[3*gi+0] = boh[9*gi+0]|boh[9*gi+1]|boh[9*gi+2]|boh[9*gi+3];
        assign hi[3*gi+1] = boh[9*gi+4]|boh[9*gi+5]|boh[9*gi+6]|boh[9*gi+7];
        assign hi[3*gi+2] = boh[9*gi+8];
    end endgenerate

    // Stage 4 Lo L1: 4x 4x4 via-grid macros
    wire [27:0] ll1;
    XP_4x4_M4M5 xp4_lo_l1_0 (.v0(lo[0]), .v1(lo[1]), .v2(lo[2]), .v3(lo[3]), .h0(lo[4]), .h1(lo[5]), .h2(lo[6]), .h3(lo[7]), .s0(ll1[0]), .s1(ll1[1]), .s2(ll1[2]), .s3(ll1[3]), .s4(ll1[4]), .s5(ll1[5]), .s6(ll1[6]));
    XP_4x4_M4M5 xp4_lo_l1_1 (.v0(lo[8]), .v1(lo[9]), .v2(lo[10]), .v3(lo[11]), .h0(lo[12]), .h1(lo[13]), .h2(lo[14]), .h3(lo[15]), .s0(ll1[7]), .s1(ll1[8]), .s2(ll1[9]), .s3(ll1[10]), .s4(ll1[11]), .s5(ll1[12]), .s6(ll1[13]));
    XP_4x4_M4M5 xp4_lo_l1_2 (.v0(lo[16]), .v1(lo[17]), .v2(lo[18]), .v3(lo[19]), .h0(lo[20]), .h1(lo[21]), .h2(lo[22]), .h3(lo[23]), .s0(ll1[14]), .s1(ll1[15]), .s2(ll1[16]), .s3(ll1[17]), .s4(ll1[18]), .s5(ll1[19]), .s6(ll1[20]));
    XP_4x4_M4M5 xp4_lo_l1_3 (.v0(lo[24]), .v1(lo[25]), .v2(lo[26]), .v3(lo[27]), .h0(lo[28]), .h1(lo[29]), .h2(lo[30]), .h3(lo[31]), .s0(ll1[21]), .s1(ll1[22]), .s2(ll1[23]), .s3(ll1[24]), .s4(ll1[25]), .s5(ll1[26]), .s6(ll1[27]));

    // Stage 4 Hi L1: 4x 3x3 via-grid macros
    wire [19:0] hl1;
    XP_3x3_M4M5 xp3_hi_l1_0 (.v0(hi[0]), .v1(hi[1]), .v2(hi[2]), .h0(hi[3]), .h1(hi[4]), .h2(hi[5]), .s0(hl1[0]), .s1(hl1[1]), .s2(hl1[2]), .s3(hl1[3]), .s4(hl1[4]));
    XP_3x3_M4M5 xp3_hi_l1_1 (.v0(hi[6]), .v1(hi[7]), .v2(hi[8]), .h0(hi[9]), .h1(hi[10]), .h2(hi[11]), .s0(hl1[5]), .s1(hl1[6]), .s2(hl1[7]), .s3(hl1[8]), .s4(hl1[9]));
    XP_3x3_M4M5 xp3_hi_l1_2 (.v0(hi[12]), .v1(hi[13]), .v2(hi[14]), .h0(hi[15]), .h1(hi[16]), .h2(hi[17]), .s0(hl1[10]), .s1(hl1[11]), .s2(hl1[12]), .s3(hl1[13]), .s4(hl1[14]));
    XP_3x3_M4M5 xp3_hi_l1_3 (.v0(hi[18]), .v1(hi[19]), .v2(hi[20]), .h0(hi[21]), .h1(hi[22]), .h2(hi[23]), .s0(hl1[15]), .s1(hl1[16]), .s2(hl1[17]), .s3(hl1[18]), .s4(hl1[19]));

    // Stage 4 Lo L2+: crosspoint_sum std-cell (large)
    wire [25:0] ll2;
    generate for (gi=0; gi<2; gi=gi+1) begin : xp7
        crosspoint_sum #(.M(7),.N(7)) u (.v(ll1[14*gi+6:14*gi]), .h(ll1[14*gi+13:14*gi+7]), .s(ll2[13*gi+12:13*gi]));
    end endgenerate
    wire [24:0] low_sum;
    crosspoint_sum #(.M(13),.N(13)) u_lo_l3 (.v(ll2[12:0]), .h(ll2[25:13]), .s(low_sum));

    // Stage 4 Hi L2+: crosspoint_sum std-cell (large)
    wire [17:0] hl2;
    generate for (gi=0; gi<2; gi=gi+1) begin : xp5h
        crosspoint_sum #(.M(5),.N(5)) u (.v(hl1[10*gi+4:10*gi]), .h(hl1[10*gi+9:10*gi+5]), .s(hl2[9*gi+8:9*gi]));
    end endgenerate
    wire [16:0] high_sum;
    crosspoint_sum #(.M(9),.N(9)) u_hi_l3 (.v(hl2[8:0]), .h(hl2[17:9]), .s(high_sum));

    // Stage 4C: Carry Split + 4D: Carry Add
    wire [3:0] final_lo; wire [6:0] carry;
    assign final_lo[0] = low_sum[0]|low_sum[4]|low_sum[8]|low_sum[12]|low_sum[16]|low_sum[20]|low_sum[24];
    assign final_lo[1] = low_sum[1]|low_sum[5]|low_sum[9]|low_sum[13]|low_sum[17]|low_sum[21];
    assign final_lo[2] = low_sum[2]|low_sum[6]|low_sum[10]|low_sum[14]|low_sum[18]|low_sum[22];
    assign final_lo[3] = low_sum[3]|low_sum[7]|low_sum[11]|low_sum[15]|low_sum[19]|low_sum[23];
    assign carry[0] = low_sum[0]|low_sum[1]|low_sum[2]|low_sum[3];
    assign carry[1] = low_sum[4]|low_sum[5]|low_sum[6]|low_sum[7];
    assign carry[2] = low_sum[8]|low_sum[9]|low_sum[10]|low_sum[11];
    assign carry[3] = low_sum[12]|low_sum[13]|low_sum[14]|low_sum[15];
    assign carry[4] = low_sum[16]|low_sum[17]|low_sum[18]|low_sum[19];
    assign carry[5] = low_sum[20]|low_sum[21]|low_sum[22]|low_sum[23];
    assign carry[6] = low_sum[24];
    wire [22:0] upper;
    crosspoint_sum #(.M(17),.N(7)) u_carry (.v(high_sum), .h(carry), .s(upper));

    // Stage 5: Binary Conversion
    assign hd[0] = final_lo[1]|final_lo[3];
    assign hd[1] = final_lo[2]|final_lo[3];
    assign hd[2] = upper[1]|upper[3]|upper[5]|upper[7]|upper[9]|upper[11]|upper[13]|upper[15]|upper[17]|upper[19]|upper[21];
    assign hd[3] = upper[2]|upper[3]|upper[6]|upper[7]|upper[10]|upper[11]|upper[14]|upper[15]|upper[18]|upper[19]|upper[22];
    assign hd[4] = upper[4]|upper[5]|upper[6]|upper[7]|upper[12]|upper[13]|upper[14]|upper[15]|upper[20]|upper[21]|upper[22];
    assign hd[5] = upper[8]|upper[9]|upper[10]|upper[11]|upper[12]|upper[13]|upper[14]|upper[15];
    assign hd[6] = upper[16]|upper[17]|upper[18]|upper[19]|upper[20]|upper[21]|upper[22];
endmodule