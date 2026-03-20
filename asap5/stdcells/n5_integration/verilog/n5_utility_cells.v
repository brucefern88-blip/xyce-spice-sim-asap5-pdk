// ============================================================================
// ASAP5/N5 Utility Cells -- Behavioral Verilog for Yosys
// Process: ASAP5 5nm GAA Nanosheet (N5-compatible)
// Corner: TT (typical-typical)
// VDD: 0.5V
// Temperature: 25C
// Generated for OpenLane2 integration
// ============================================================================

// --- FILLx1: 1-site filler (no logic) ---
(* blackbox *)
module FILLx1 ();
endmodule

// --- FILLx2: 2-site filler (no logic) ---
(* blackbox *)
module FILLx2 ();
endmodule

// --- FILLx4: 4-site filler (no logic) ---
(* blackbox *)
module FILLx4 ();
endmodule

// --- TAPx1: Well tap cell (no logic) ---
(* blackbox *)
module TAPx1 ();
endmodule

// --- TIE_HI: Tie-high cell (output = 1'b1) ---
module TIE_HI (output Y);
  assign Y = 1'b1;
endmodule

// --- TIE_LO: Tie-low cell (output = 1'b0) ---
module TIE_LO (output Y);
  assign Y = 1'b0;
endmodule

// --- ENDCAP_L: Left row endcap (no logic) ---
(* blackbox *)
module ENDCAP_L ();
endmodule

// --- ENDCAP_R: Right row endcap (no logic) ---
(* blackbox *)
module ENDCAP_R ();
endmodule

// --- DECAPx2: Decoupling capacitor (no logic) ---
(* blackbox *)
module DECAPx2 ();
endmodule
