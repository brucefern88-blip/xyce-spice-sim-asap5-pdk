create_clock [get_ports clk] -period 5.0 -name core_clk
set_input_delay 1.0 -clock core_clk [all_inputs]
set_output_delay 1.0 -clock core_clk [all_outputs]
