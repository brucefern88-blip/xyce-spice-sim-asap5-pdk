// =============================================================================
// File:    popcount16_tb.v
// Purpose: Exhaustive testbench for the 16-bit via-crossbar popcount.
//
// Fixes vs original version:
//   1. Separated into its own file (filename matches module name)
//   2. Reference count uses explicit 5-bit accumulator to avoid WIDTHEXPAND
//      warnings on the 1-bit to 32-bit implicit expansion
//   3. Bit-slice sum written as an always block, not inline integer arithmetic
//   4. #delay kept (valid for iverilog simulation; suppress for Verilator)
// =============================================================================
`timescale 1ns/1ps

module popcount16_tb;
    reg  [15:0] dut_in;
    wire [4:0]  dut_out;

    // Instantiate design under test
    popcount16 dut (
        .in  (dut_in),
        .out (dut_out)
    );

    // Reference model: manually count bits using an explicit-width accumulator
    // Using integer arithmetic on 1-bit slices causes WIDTHEXPAND lint errors;
    // an always block with a 5-bit reg prevents that cleanly.
    reg [4:0] expected;
    integer   bit_idx;
    always @(*) begin
        expected = 5'd0;
        for (bit_idx = 0; bit_idx < 16; bit_idx = bit_idx + 1)
            expected = expected + {4'b0, dut_in[bit_idx]};  // zero-extend each bit
    end

    integer i;
    integer errors;

    initial begin
        $dumpfile("popcount16.vcd");
        $dumpvars(0, popcount16_tb);

        errors = 0;

        $display("=======================================================");
        $display("  16-bit Via-Crossbar Popcount — Exhaustive Verification");
        $display("=======================================================");

        // ---- Spot checks: boundary and structural cases ----
        dut_in = 16'h0000; #10;
        $display("in=0x0000  out=%0d  exp=%0d  %s", dut_out, expected,
                 (dut_out===expected) ? "PASS" : "FAIL");

        dut_in = 16'hFFFF; #10;
        $display("in=0xFFFF  out=%0d  exp=%0d  %s", dut_out, expected,
                 (dut_out===expected) ? "PASS" : "FAIL");

        dut_in = 16'h0001; #10;
        $display("in=0x0001  out=%0d  exp=%0d  %s", dut_out, expected,
                 (dut_out===expected) ? "PASS" : "FAIL");

        dut_in = 16'h8000; #10;
        $display("in=0x8000  out=%0d  exp=%0d  %s", dut_out, expected,
                 (dut_out===expected) ? "PASS" : "FAIL");

        dut_in = 16'hAAAA; #10;   // 1010...1010 — 8 ones spread across even bits
        $display("in=0xAAAA  out=%0d  exp=%0d  %s", dut_out, expected,
                 (dut_out===expected) ? "PASS" : "FAIL");

        dut_in = 16'h5555; #10;   // 0101...0101 — 8 ones on odd bits
        $display("in=0x5555  out=%0d  exp=%0d  %s", dut_out, expected,
                 (dut_out===expected) ? "PASS" : "FAIL");

        dut_in = 16'hF0F0; #10;   // 8 ones in upper nibbles
        $display("in=0xF0F0  out=%0d  exp=%0d  %s", dut_out, expected,
                 (dut_out===expected) ? "PASS" : "FAIL");

        dut_in = 16'h0F0F; #10;   // 8 ones in lower nibbles
        $display("in=0x0F0F  out=%0d  exp=%0d  %s", dut_out, expected,
                 (dut_out===expected) ? "PASS" : "FAIL");

        // ---- Full exhaustive sweep: all 65,536 input combinations ----
        $display("-------------------------------------------------------");
        $display("Running full 65,536-input exhaustive sweep...");

        for (i = 0; i < 65536; i = i + 1) begin
            dut_in = i[15:0];
            #10;
            if (dut_out !== expected) begin
                $display("FAIL: in=%016b  expected=%0d  got=%0d",
                          dut_in, expected, dut_out);
                errors = errors + 1;
                if (errors >= 10) begin
                    $display("Stopping after 10 failures.");
                    $finish;
                end
            end
        end

        $display("-------------------------------------------------------");
        if (errors == 0)
            $display("RESULT: ALL 65,536 TESTS PASSED  [OK]");
        else
            $display("RESULT: %0d ERROR(S) FOUND  [FAIL]", errors);
        $display("=======================================================");

        $finish;
    end
endmodule
