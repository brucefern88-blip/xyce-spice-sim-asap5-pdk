# AES Nangate45 Benchmark - larger design for meaningful runtime comparison
set test_dir "../OpenROAD/test"
set start_time [clock milliseconds]

proc elapsed_ms { start } {
    return [expr {[clock milliseconds] - $start}]
}

puts "========================================"
puts "  AES Nangate45 Benchmark"
puts "  Threads: [cpu_count]"
puts "========================================"

set_thread_count [cpu_count]

# Read
set t0 [clock milliseconds]
read_lef $test_dir/Nangate45/Nangate45_tech.lef
read_lef $test_dir/Nangate45/Nangate45_stdcell.lef
read_liberty $test_dir/Nangate45/Nangate45_typ.lib
read_verilog $test_dir/aes_nangate45.v
link_design aes_cipher_top
source $test_dir/flow_helpers.tcl
read_sdc $test_dir/aes_nangate45.sdc
puts "READ: [elapsed_ms $t0] ms"

# Floorplan
set t0 [clock milliseconds]
initialize_floorplan -site "FreePDK45_38x28_10R_NP_162NW_34O" \
    -die_area {0 0 1020 920.8} -core_area {10 12 1010 911.2}
source $test_dir/Nangate45/Nangate45.tracks
remove_buffers
tapcell -distance 120 -tapcell_master TAPCELL_X1 -endcap_master TAPCELL_X1
source $test_dir/Nangate45/Nangate45.pdn.tcl
pdngen
puts "FLOORPLAN+PDN: [elapsed_ms $t0] ms"

# Placement
set t0 [clock milliseconds]
set_global_routing_layer_adjustment {metal2-metal10} 0.5
set_routing_layers -signal metal2-metal10 -clock metal6-metal10
set_macro_extension 2
place_pins -hor_layers metal3 -ver_layers metal2
global_placement -routability_driven -density 0.3 -pad_left 2 -pad_right 2
puts "GLOBAL_PLACEMENT: [elapsed_ms $t0] ms"

# Repair
set t0 [clock milliseconds]
source $test_dir/Nangate45/Nangate45.rc
set_wire_rc -signal -layer metal3
set_wire_rc -clock -layer metal6
set_dont_use {CLKBUF_* AOI211_X1 OAI211_X1}
estimate_parasitics -placement
repair_design -slew_margin 0 -cap_margin 20
repair_tie_fanout -separation 5 "LOGIC0_X1/Z"
repair_tie_fanout -separation 5 "LOGIC1_X1/Z"
set_placement_padding -global -left 1 -right 1
detailed_placement
puts "REPAIR+DPL: [elapsed_ms $t0] ms"

# CTS
set t0 [clock milliseconds]
repair_clock_inverters
clock_tree_synthesis -root_buf BUF_X4 -buf_list BUF_X4 \
    -sink_clustering_enable -sink_clustering_max_diameter 100
repair_clock_nets
detailed_placement
puts "CTS: [elapsed_ms $t0] ms"

# Timing repair
set t0 [clock milliseconds]
set_propagated_clock [all_clocks]
estimate_parasitics -placement
repair_timing -skip_gate_cloning
detailed_placement
puts "TIMING_REPAIR: [elapsed_ms $t0] ms"

# Global route
set t0 [clock milliseconds]
pin_access
global_route -guide_file results/aes_route_guide -congestion_iterations 100 -verbose
puts "GLOBAL_ROUTING: [elapsed_ms $t0] ms"

# Antenna
set t0 [clock milliseconds]
repair_antennas -iterations 5
check_antennas
puts "ANTENNA: [elapsed_ms $t0] ms"

# Detailed route
set t0 [clock milliseconds]
detailed_route -output_drc results/aes_drc.rpt \
    -output_maze results/aes_maze.log -no_pin_access -verbose 0
set drv_count [detailed_route_num_drvs]
puts "DETAILED_ROUTING: [elapsed_ms $t0] ms (DRVs: $drv_count)"

# Fill + Extract
set t0 [clock milliseconds]
filler_placement "FILLCELL*"
define_process_corner -ext_model_index 0 X
extract_parasitics -ext_model_file $test_dir/Nangate45/Nangate45.rcx_rules
write_spef results/aes.spef
read_spef results/aes.spef
puts "FILL+EXTRACT: [elapsed_ms $t0] ms"

# Final report
puts "\n========================================"
puts "  AES RESULTS"
puts "========================================"
report_worst_slack -min -digits 3
report_worst_slack -max -digits 3
report_tns -digits 3
report_power -corner default
report_design_area
report_check_types -max_slew -max_capacitance -max_fanout -violators -digits 3
puts "DRC violations: $drv_count"

set total_time [elapsed_ms $start_time]
puts "\n  TOTAL RUNTIME: $total_time ms"
puts "  Instance count: [sta::network_instance_count]"
puts "========================================"
