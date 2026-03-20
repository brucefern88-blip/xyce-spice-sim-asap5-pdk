# OpenROAD PnR + Extraction + STA Flow
# Design: 16-bit counter
# Technology: Nangate45

set test_dir "../OpenROAD/test"

puts "========================================"
puts "  OpenROAD PnR Flow - Counter Design"
puts "========================================"

################################################################
# Step 1: Read Libraries & Design
################################################################
puts "\n=== Step 1: Read Libraries ==="
read_lef $test_dir/Nangate45/Nangate45_tech.lef
read_lef $test_dir/Nangate45/Nangate45_stdcell.lef
read_liberty $test_dir/Nangate45/Nangate45_typ.lib
read_verilog counter_synth.v
link_design counter
read_sdc counter.sdc

puts "Design loaded: [sta::network_instance_count] instances"

################################################################
# Step 2: Floorplanning
################################################################
puts "\n=== Step 2: Floorplanning ==="
set site "FreePDK45_38x28_10R_NP_162NW_34O"
initialize_floorplan -site $site \
    -die_area {0 0 100 100} \
    -core_area {5 5 95 95}

source $test_dir/Nangate45/Nangate45.tracks
remove_buffers

puts "Floorplan initialized: 100x100 um die"

################################################################
# Step 3: Tapcell Insertion
################################################################
puts "\n=== Step 3: Tapcell Insertion ==="
tapcell -distance 120 \
    -tapcell_master TAPCELL_X1 \
    -endcap_master TAPCELL_X1

################################################################
# Step 4: Power Distribution Network
################################################################
puts "\n=== Step 4: PDN Generation ==="
source $test_dir/Nangate45/Nangate45.pdn.tcl
pdngen

################################################################
# Step 5: Global Placement
################################################################
puts "\n=== Step 5: Global Placement ==="

# Set routing layers
set_global_routing_layer_adjustment {metal2-metal10} 0.5
set_routing_layers -signal metal2-metal10 -clock metal6-metal10
set_macro_extension 2

# Place pins
place_pins -hor_layers metal3 -ver_layers metal2

# Global placement
global_placement -routability_driven -density 0.4 \
    -pad_left 2 -pad_right 2

puts "Global placement complete"

################################################################
# Step 6: Repair Design (Slew/Cap/Fanout)
################################################################
puts "\n=== Step 6: Repair Design ==="

source $test_dir/Nangate45/Nangate45.rc
set_wire_rc -signal -layer metal3
set_wire_rc -clock -layer metal6
set_dont_use {CLKBUF_* AOI211_X1 OAI211_X1}

estimate_parasitics -placement

repair_design -slew_margin 0 -cap_margin 20
repair_tie_fanout -separation 5 "LOGIC0_X1/Z"
repair_tie_fanout -separation 5 "LOGIC1_X1/Z"

################################################################
# Step 7: Detailed Placement
################################################################
puts "\n=== Step 7: Detailed Placement ==="
set_placement_padding -global -left 1 -right 1
detailed_placement

puts "\n--- Post-Placement Timing (Ideal Clocks) ---"
report_worst_slack -min -digits 3
report_worst_slack -max -digits 3
report_tns -digits 3

################################################################
# Step 8: Clock Tree Synthesis
################################################################
puts "\n=== Step 8: Clock Tree Synthesis ==="
repair_clock_inverters

clock_tree_synthesis -root_buf BUF_X4 -buf_list BUF_X4 \
    -sink_clustering_enable \
    -sink_clustering_max_diameter 100

repair_clock_nets
detailed_placement

write_db results/counter_cts.db

################################################################
# Step 9: Timing Repair (Setup/Hold)
################################################################
puts "\n=== Step 9: Setup/Hold Timing Repair ==="
set_propagated_clock [all_clocks]
estimate_parasitics -placement

repair_timing -skip_gate_cloning

puts "\n--- Post-Repair Timing ---"
report_worst_slack -min -digits 3
report_worst_slack -max -digits 3
report_tns -digits 3

################################################################
# Step 10: Final Detailed Placement
################################################################
puts "\n=== Step 10: Final Detailed Placement ==="
detailed_placement
check_placement -verbose

################################################################
# Step 11: Global Routing
################################################################
puts "\n=== Step 11: Global Routing ==="
pin_access

global_route -guide_file results/counter.route_guide \
    -congestion_iterations 100 -verbose

write_verilog -remove_cells "FILLCELL*" results/counter_routed.v

################################################################
# Step 12: Antenna Repair
################################################################
puts "\n=== Step 12: Antenna Check/Repair ==="
repair_antennas -iterations 5
check_antennas

################################################################
# Step 13: Detailed Routing
################################################################
puts "\n=== Step 13: Detailed Routing ==="
detailed_route \
    -output_drc results/counter_route_drc.rpt \
    -output_maze results/counter_maze.log \
    -no_pin_access \
    -verbose 0

set drv_count [detailed_route_num_drvs]
puts "DRC violations after detailed routing: $drv_count"

write_db results/counter_route.db
write_def results/counter_route.def

################################################################
# Step 14: Filler Cell Placement
################################################################
puts "\n=== Step 14: Filler Cell Placement ==="
filler_placement "FILLCELL*"
check_placement -verbose

write_db results/counter_final.db

################################################################
# Step 15: Parasitic Extraction
################################################################
puts "\n=== Step 15: Parasitic Extraction ==="
define_process_corner -ext_model_index 0 X
extract_parasitics -ext_model_file $test_dir/Nangate45/Nangate45.rcx_rules

write_spef results/counter.spef
puts "SPEF written to results/counter.spef"

# Read back extracted parasitics for STA
read_spef results/counter.spef

################################################################
# Step 16: Final STA Report
################################################################
puts "\n========================================"
puts "  FINAL STATIC TIMING ANALYSIS"
puts "========================================"

puts "\n--- Critical Path (Setup) ---"
report_checks -path_delay max -format full_clock_expanded \
    -fields {input_pin slew capacitance} -digits 3

puts "\n--- Critical Path (Hold) ---"
report_checks -path_delay min -format full_clock_expanded \
    -fields {input_pin slew capacitance} -digits 3

puts "\n--- Worst Slack ---"
report_worst_slack -min -digits 3
report_worst_slack -max -digits 3

puts "\n--- Total Negative Slack ---"
report_tns -digits 3

puts "\n--- Slew/Cap/Fanout Violations ---"
report_check_types -max_slew -max_capacitance -max_fanout -violators -digits 3

puts "\n--- Clock Skew ---"
report_clock_skew -digits 3

puts "\n--- Power Report ---"
report_power -corner default

puts "\n--- Design Area ---"
report_design_area

puts "\n--- Floating Nets ---"
report_floating_nets -verbose

puts "\n========================================"
puts "  Flow Complete!"
puts "========================================"
