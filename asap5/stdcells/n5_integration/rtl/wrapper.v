module hamming_64b_cuboid_r4 (
    input  wire [63:0] A,
    input  wire [63:0] B,
    output wire [6:0]  hd
);
    hamming_64b_cuboid_r4_xp u_dut (.A(A), .B(B), .hd(hd));
endmodule
