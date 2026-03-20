// Via-Grid Crosspoint Macros — Flat port names for Liberty compatibility

(* keep_hierarchy *)
module XP_3x3_M2M3 (v0, v1, v2, h0, h1, h2, s0, s1, s2, s3, s4);
    input v0;
    input v1;
    input v2;
    input h0;
    input h1;
    input h2;
    output s0;
    output s1;
    output s2;
    output s3;
    output s4;
    assign s0 = (v0 & h0);
    assign s1 = (v0 & h1) | (v1 & h0);
    assign s2 = (v0 & h2) | (v1 & h1) | (v2 & h0);
    assign s3 = (v1 & h2) | (v2 & h1);
    assign s4 = (v2 & h2);
endmodule

(* keep_hierarchy *)
module XP_5x5_M2M3 (v0, v1, v2, v3, v4, h0, h1, h2, h3, h4, s0, s1, s2, s3, s4, s5, s6, s7, s8);
    input v0;
    input v1;
    input v2;
    input v3;
    input v4;
    input h0;
    input h1;
    input h2;
    input h3;
    input h4;
    output s0;
    output s1;
    output s2;
    output s3;
    output s4;
    output s5;
    output s6;
    output s7;
    output s8;
    assign s0 = (v0 & h0);
    assign s1 = (v0 & h1) | (v1 & h0);
    assign s2 = (v0 & h2) | (v1 & h1) | (v2 & h0);
    assign s3 = (v0 & h3) | (v1 & h2) | (v2 & h1) | (v3 & h0);
    assign s4 = (v0 & h4) | (v1 & h3) | (v2 & h2) | (v3 & h1) | (v4 & h0);
    assign s5 = (v1 & h4) | (v2 & h3) | (v3 & h2) | (v4 & h1);
    assign s6 = (v2 & h4) | (v3 & h3) | (v4 & h2);
    assign s7 = (v3 & h4) | (v4 & h3);
    assign s8 = (v4 & h4);
endmodule

(* keep_hierarchy *)
module XP_4x4_M4M5 (v0, v1, v2, v3, h0, h1, h2, h3, s0, s1, s2, s3, s4, s5, s6);
    input v0;
    input v1;
    input v2;
    input v3;
    input h0;
    input h1;
    input h2;
    input h3;
    output s0;
    output s1;
    output s2;
    output s3;
    output s4;
    output s5;
    output s6;
    assign s0 = (v0 & h0);
    assign s1 = (v0 & h1) | (v1 & h0);
    assign s2 = (v0 & h2) | (v1 & h1) | (v2 & h0);
    assign s3 = (v0 & h3) | (v1 & h2) | (v2 & h1) | (v3 & h0);
    assign s4 = (v1 & h3) | (v2 & h2) | (v3 & h1);
    assign s5 = (v2 & h3) | (v3 & h2);
    assign s6 = (v3 & h3);
endmodule

(* keep_hierarchy *)
module XP_3x3_M4M5 (v0, v1, v2, h0, h1, h2, s0, s1, s2, s3, s4);
    input v0;
    input v1;
    input v2;
    input h0;
    input h1;
    input h2;
    output s0;
    output s1;
    output s2;
    output s3;
    output s4;
    assign s0 = (v0 & h0);
    assign s1 = (v0 & h1) | (v1 & h0);
    assign s2 = (v0 & h2) | (v1 & h1) | (v2 & h0);
    assign s3 = (v1 & h2) | (v2 & h1);
    assign s4 = (v2 & h2);
endmodule
