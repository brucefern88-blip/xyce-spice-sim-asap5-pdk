`timescale 1ps / 1fs

module tb_xp;
    reg  [63:0] a, b;
    wire [6:0]  hd;

    function [6:0] golden_hd;
        input [63:0] va, vb;
        reg [63:0] x;
        integer i;
        begin
            x = va ^ vb;
            golden_hd = 0;
            for (i = 0; i < 64; i = i + 1)
                golden_hd = golden_hd + x[i];
        end
    endfunction

    hamming_64b_cuboid_r4_xp dut (.A(a), .B(b), .hd(hd));

    integer pass_count, fail_count, test_num;
    reg [6:0] expected;
    reg [63:0] lfsr;

    task check;
        begin
            #10;
            expected = golden_hd(a, b);
            if (hd !== expected) begin
                $display("FAIL test %0d: a=%h b=%h hd=%0d exp=%0d", test_num, a, b, hd, expected);
                fail_count = fail_count + 1;
            end
            pass_count = pass_count + (hd === expected);
            test_num = test_num + 1;
        end
    endtask

    integer i;
    initial begin
        pass_count = 0; fail_count = 0; test_num = 0;
        lfsr = 64'hDEADBEEFCAFEBABE;

        // Corner cases
        a = 64'h0; b = 64'h0; check;
        a = 64'hFFFFFFFFFFFFFFFF; b = 64'h0; check;
        a = 64'h0; b = 64'hFFFFFFFFFFFFFFFF; check;
        a = 64'hFFFFFFFFFFFFFFFF; b = 64'hFFFFFFFFFFFFFFFF; check;
        a = 64'hAAAAAAAAAAAAAAAA; b = 64'h5555555555555555; check;
        a = 64'h1; b = 64'h0; check;

        // 50000 random vectors
        for (i = 0; i < 50000; i = i + 1) begin
            lfsr = {lfsr[62:0], lfsr[63] ^ lfsr[62] ^ lfsr[60] ^ lfsr[59]};
            a = lfsr;
            lfsr = {lfsr[62:0], lfsr[63] ^ lfsr[62] ^ lfsr[60] ^ lfsr[59]};
            b = lfsr;
            check;
        end

        $display("Results: %0d PASS, %0d FAIL out of %0d tests", pass_count, fail_count, test_num);
        if (fail_count == 0) $display("ALL TESTS PASSED");
        $finish;
    end
endmodule
