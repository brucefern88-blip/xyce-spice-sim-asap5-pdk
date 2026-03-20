`timescale 1ps / 1fs

module tb_hamming_distance_64;

  reg  [63:0] a, b;
  wire [6:0]  hd;
  
  // Golden model: behavioral popcount of XOR
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

  hamming_distance_64 dut (.a(a), .b(b), .hd(hd));us

  integer pass_count, fail_count, test_num;
  reg [6:0] expected;
  
  // LFSR for pseudo-random vectors
  reg [63:0] lfsr;
  
  task check;
    begin
      #10;
      expected = golden_hd(a, b);
      if (hd !== expected) begin
        $display("FAIL test %0d: a=%h b=%h  hd=%0d expected=%0d", 
                 test_num, a, b, hd, expected);
        fail_count = fail_count + 1;
      end else begin
        pass_count = pass_count + 1;
      end
      test_num = test_num + 1;
    end
  endtask

  initial begin
    $dumpfile("ham_dis_64.vcd");
    $dumpvars(0, tb_hamming_distance_64);
    pass_count = 0;
    fail_count = 0;
    test_num   = 0;
    lfsr       = 64'hDEAD_BEEF_CAFE_BABE;

    // ── Corner cases ──
    
    // HD = 0 (identical)
    a = 64'h0000_0000_0000_0000; b = 64'h0000_0000_0000_0000; check;
    a = 64'hFFFF_FFFF_FFFF_FFFF; b = 64'hFFFF_FFFF_FFFF_FFFF; check;
    a = 64'hA5A5_A5A5_A5A5_A5A5; b = 64'hA5A5_A5A5_A5A5_A5A5; check;
    
    // HD = 64 (all bits differ)
    a = 64'h0000_0000_0000_0000; b = 64'hFFFF_FFFF_FFFF_FFFF; check;
    a = 64'hFFFF_FFFF_FFFF_FFFF; b = 64'h0000_0000_0000_0000; check;
    a = 64'hAAAA_AAAA_AAAA_AAAA; b = 64'h5555_5555_5555_5555; check;
    
    // HD = 1 (single bit)
    a = 64'h0000_0000_0000_0000; b = 64'h0000_0000_0000_0001; check;
    a = 64'h0000_0000_0000_0000; b = 64'h8000_0000_0000_0000; check;
    a = 64'h0000_0000_0000_0000; b = 64'h0000_0001_0000_0000; check;
    
    // HD = 32 (half bits differ)
    a = 64'hFFFF_FFFF_0000_0000; b = 64'h0000_0000_0000_0000; check;
    a = 64'hAAAA_AAAA_AAAA_AAAA; b = 64'h0000_0000_0000_0000; check;
    
    // HD = 2
    a = 64'h0000_0000_0000_0003; b = 64'h0000_0000_0000_0000; check;
    
    // HD = 8 (one byte fully differs)
    a = 64'h0000_0000_0000_00FF; b = 64'h0000_0000_0000_0000; check;
    
    // Alternating patterns
    a = 64'hF0F0_F0F0_F0F0_F0F0; b = 64'h0F0F_0F0F_0F0F_0F0F; check;  // HD=64
    a = 64'hFF00_FF00_FF00_FF00; b = 64'h00FF_00FF_00FF_00FF; check;  // HD=64
    
    // Walking ones
    a = 64'h0000_0000_0000_0000;
    b = 64'h0000_0000_0000_0001; check;  // HD=1
    b = 64'h0000_0000_0000_0003; check;  // HD=2
    b = 64'h0000_0000_0000_000F; check;  // HD=4
    b = 64'h0000_0000_0000_00FF; check;  // HD=8
    b = 64'h0000_0000_0000_FFFF; check;  // HD=16
    b = 64'h0000_0000_FFFF_FFFF; check;  // HD=32
    b = 64'hFFFF_FFFF_FFFF_FFFF; check;  // HD=64
    
    // Specific known values
    a = 64'h1234_5678_9ABC_DEF0; b = 64'hFEDC_BA98_7654_3210; check;
    a = 64'hDEAD_BEEF_CAFE_BABE; b = 64'h0BAD_F00D_DEAD_C0DE; check;
    
    // ── Random vectors (500 tests) ──
    repeat (50000) begin
      // Simple LFSR-style PRNG
      lfsr = {lfsr[62:0], lfsr[63] ^ lfsr[62] ^ lfsr[60] ^ lfsr[59]};
      a = lfsr;
      lfsr = {lfsr[62:0], lfsr[63] ^ lfsr[62] ^ lfsr[60] ^ lfsr[59]};
      b = lfsr;
      check;
    end
    
    // ── Report ──
    $display("====================================");
    $display("  PASS: %0d   FAIL: %0d   TOTAL: %0d", pass_count, fail_count, test_num);
    if (fail_count == 0)
      $display("  ALL TESTS PASSED");
    else
      $display("  *** FAILURES DETECTED ***");
    $display("====================================");
    $finish;
    
    $dumpfile("ham_dis_64.vcd"); // Name of the waveform file
    $dumpvars(0, tb_hamming_distance_64); // 0 means dump all signals in the module
  end

endmodule
