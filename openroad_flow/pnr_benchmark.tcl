# OpenROAD PnR Benchmark Flow - with timing instrumentation
# Design: 16-bit counter on Nangate45

set test_dir "../OpenROAD/test"
set start_time [clock milliseconds]

proc elapsed_ms { start } {
    return [expr {[clock milliseconds] - $start}]
}

puts "========================================"
puts "  OpenROAD PnR Benchmark Flow"
puts "  Threads: [cpu_count]"
puts "========================================"

set_thread_count [cpu_count]

################################################################
# Read Libraries & Design
set t0 [clock milliseconds]
read_lef $test_dir/Nangate45/Nangate45_tech.lef
read_lef $test_dir/Nangate45/Nangate45_stdcell.lef
read_liberty $test_dir/Nangate45/Nangate45_typ.lib
read_verilog counter_synth.v
link_design counter
read_sdc counter.sdc
puts "READ: [elapsed_ms $t0] ms"

################################################################
# Floorplanning
set t0 [clock milliseconds]
initialize_floorplan -site "FreePDK45_38x28_10R_NP_162NW_34O" \
    -die_area {0 0 100 100} \
    -core_area {5 5 95 95}
source $test_dir/Nangate45/Nangate45.tracks
remove_buffers
puts "FLOORPLAN: [elapsed_ms $t0] ms"

################################################################
# Tapcell + PDN
set t0 [clock milliseconds]
tapcell -distance 120 -tapcell_master TAPCELL_X1 -endcap_master TAPCELL_X1
source $test_dir/Nangate45/Nangate45.pdn.tcl
pdngen
puts "TAPCELL+PDN: [elapsed_ms $t0] ms"

################################################################
# Global Placement
set t0 [clock milliseconds]
set_global_routing_layer_adjustment {metal2-metal10} 0.5
set_routing_layers -signal metal2-metal10 -clock metal6-metal10
set_macro_extension 2
place_pins -hor_layers metal3 -ver_layers metal2
global_placement -routability_driven -density 0.4 -pad_left 2 -pad_right 2
puts "GLOBAL_PLACEMENT: [elapsed_ms $t0] ms"

################################################################
# Repair Design
set t0 [clock milliseconds]
source $test_dir/Nangate45/Nangate45.rc
set_wire_rc -signal -layer metal3
set_wire_rc -clock -layer metal6
set_dont_use {CLKBUF_* AOI211_X1 OAI211_X1}
estimate_parasitics -placement
repair_design -slew_margin 0 -cap_margin 20
repair_tie_fanout -separation 5 "LOGIC0_X1/Z"
repair_tie_fanout -separation 5 "LOGIC1_X1/Z"
puts "REPAIR_DESIGN: [elapsed_ms $t0] ms"

################################################################
# Detailed Placement
set t0 [clock milliseconds]
set_placement_padding -global -left 1 -right 1
detailed_placement
puts "DETAILED_PLACEMENT: [elapsed_ms $t0] ms"

################################################################
# CTS
set t0 [clock milliseconds]
repair_clock_inverters
clock_tree_synthesis -root_buf BUF_X4 -buf_list BUF_X4 \
    -sink_clustering_enable -sink_clustering_max_diameter 100
repair_clock_nets
detailed_placement
puts "CTS: [elapsed_ms $t0] ms"

################################################################
# Timing Repair
set t0 [clock milliseconds]
set_propagated_clock [all_clocks]
estimate_parasitics -placement
repair_timing -skip_gate_cloning
detailed_placement
puts "TIMING_REPAIR: [elapsed_ms $t0] ms"

################################################################
# Global Routing
set t0 [clock milliseconds]
pin_access
global_route -guide_file results/bench_route_guide -congestion_iterations 100 -verbose
puts "GLOBAL_ROUTING: [elapsed_ms $t0] ms"

################################################################
# Antenna Repair
set t0 [clock milliseconds]
repair_antennas -iterations 5
check_antennas
puts "ANTENNA: [elapsed_ms $t0] ms"

################################################################
# Detailed Routing
set t0 [clock milliseconds]
detailed_route \
    -output_drc results/bench_drc.rpt \
    -output_maze results/bench_maze.log \
    -no_pin_access -verbose 0
set drv_count [detailed_route_num_drvs]
puts "DETAILED_ROUTING: [elapsed_ms $t0] ms (DRVs: $drv_count)"

################################################################
# Filler + Extraction
set t0 [clock milliseconds]
filler_placement "FILLCELL*"
define_process_corner -ext_model_index 0 X
extract_parasitics -ext_model_file $test_dir/Nangate45/Nangate45.rcx_rules
write_spef results/bench.spef
read_spef results/bench.spef
puts "FILL+EXTRACT: [elapsed_ms $t0] ms"

################################################################
# Final STA
puts "\n========================================"
puts "  RESULTS"
puts "========================================"

puts "\n--- Timing ---"
report_worst_slack -min -digits 3
report_worst_slack -max -digits 3
report_tns -digits 3

puts "\n--- Power ---"
report_power -corner default

puts "\n--- Area ---"
report_design_area

puts "\n--- DRC ---"
puts "DRC violations: $drv_count"

set total_time [elapsed_ms $start_time]
puts "\n========================================"
puts "  TOTAL RUNTIME: $total_time ms"
puts "========================================"
