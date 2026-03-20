# Load AES design into OpenROAD, run PnR, save DB, and keep GUI open
set test_dir "../OpenROAD/test"

read_lef $test_dir/Nangate45/Nangate45_tech.lef
read_lef $test_dir/Nangate45/Nangate45_stdcell.lef
read_liberty $test_dir/Nangate45/Nangate45_typ.lib

source $test_dir/flow_helpers.tcl
read_verilog $test_dir/aes_nangate45.v
link_design aes_cipher_top
read_sdc $test_dir/aes_nangate45.sdc

set_thread_count [cpu_count]

# Floorplan
initialize_floorplan -site "FreePDK45_38x28_10R_NP_162NW_34O" \
    -die_area {0 0 1020 920.8} -core_area {10 12 1010 911.2}
source $test_dir/Nangate45/Nangate45.tracks
remove_buffers
tapcell -distance 120 -tapcell_master TAPCELL_X1 -endcap_master TAPCELL_X1
source $test_dir/Nangate45/Nangate45.pdn.tcl
pdngen

# Placement
set_global_routing_layer_adjustment {metal2-metal10} 0.5
set_routing_layers -signal metal2-metal10 -clock metal6-metal10
set_macro_extension 2
place_pins -hor_layers metal3 -ver_layers metal2
global_placement -routability_driven -density 0.3 -pad_left 2 -pad_right 2

# Repair
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

# CTS
repair_clock_inverters
clock_tree_synthesis -root_buf BUF_X4 -buf_list BUF_X4 \
    -sink_clustering_enable -sink_clustering_max_diameter 100
repair_clock_nets
detailed_placement

# Timing repair
set_propagated_clock [all_clocks]
estimate_parasitics -placement
repair_timing -skip_gate_cloning
detailed_placement

# Global route
pin_access
global_route -guide_file results/aes_gui_route_guide -congestion_iterations 100 -verbose

# Detailed route
detailed_route -output_drc results/aes_gui_drc.rpt \
    -output_maze results/aes_gui_maze.log -no_pin_access -verbose 0

# Filler
filler_placement "FILLCELL*"

# Save DB
write_db results/aes_routed.db
puts "AES database saved to results/aes_routed.db"
puts "Design ready for GUI viewing"

# Zoom to fit
gui::fit
