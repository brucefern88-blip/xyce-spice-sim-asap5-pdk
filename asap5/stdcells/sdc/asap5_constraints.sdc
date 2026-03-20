# ============================================================================
# ASAP5 Cuboid R4 Hamming Distance -- SDC Constraints
# Combinational design: virtual clock, no physical clock port
# Process: ASAP5 5nm GAA Nanosheet, LVT
# Corner: TT, VDD=0.5V, T=25C
# ============================================================================

# Virtual clock at 1 GHz (1ns period) -- no physical port
create_clock -name vclk -period 1.0

# Input delays relative to virtual clock
set_input_delay -clock vclk 0.0 [get_ports A[*]]
set_input_delay -clock vclk 0.0 [get_ports B[*]]

# Output delay: 100ps timing budget (0.9ns consumed by logic)
set_output_delay -clock vclk 0.9 [get_ports hd[*]]

# Input transition
set_input_transition 0.050 [all_inputs]

# Max fanout
set_max_fanout 16 [current_design]

# Max transition
set_max_transition 0.200 [current_design]

# Operating conditions
set_operating_conditions tt_0p5v_25c -library asap5_stdcells_tt_0p5v_25c
