# ============================================================================
# SDC Constraints: hamming_64b_cuboid_r4
# Design: 64-bit Hamming Distance, Cuboid Radix-4 Architecture
# Process: ASAP5/N5 5nm — Purely Combinational (no clock)
# ============================================================================

# Virtual clock for timing analysis (200 ps period)
create_clock -name vclk -period 0.200

# Input/output constraints (25% of period each side)
set_input_delay -clock vclk 0.050 [all_inputs]
set_output_delay -clock vclk 0.050 [all_outputs]

# Input transition (100 ps typical driver slew)
set_input_transition 0.100 [all_inputs]

# Design constraints
set_max_fanout 8 [current_design]
set_max_transition 0.500 [current_design]
