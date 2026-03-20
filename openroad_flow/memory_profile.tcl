# OpenROAD Memory Profiling Script
# Captures RSS (Resident Set Size) before and after each PnR stage
# Outputs timeline to results/memory_profile.txt

set test_dir "../OpenROAD/test"
set outfile "results/memory_profile.txt"
set outfd [open $outfile w]

# --- Memory sampling via ps RSS (in KB) ---
proc get_rss_kb {} {
    set my_pid [pid]
    set rss [string trim [exec ps -o rss= -p $my_pid]]
    return $rss
}

proc get_timestamp {} {
    return [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
}

# Record a memory sample and print/log it
proc mem_sample {stage label fd} {
    set rss [get_rss_kb]
    set rss_mb [format "%.1f" [expr {$rss / 1024.0}]]
    set ts [get_timestamp]
    set line [format "%-40s  RSS: %8d KB  (%6s MB)  @ %s" "${stage}: ${label}" $rss $rss_mb $ts]
    puts $line
    puts $fd $line
    flush $fd
    return $rss
}

# Store all samples for summary analysis
set mem_timeline {}

proc record {stage label fd} {
    upvar 1 mem_timeline timeline
    set rss [mem_sample $stage $label $fd]
    lappend timeline [list $stage $label $rss]
}

puts $outfd "================================================================="
puts $outfd "  OpenROAD Memory Profile - Counter PnR Flow"
puts $outfd "  Started: [get_timestamp]"
puts $outfd "================================================================="
puts $outfd ""
flush $outfd

puts "================================================================="
puts "  OpenROAD Memory Profile - Counter PnR Flow"
puts "================================================================="

################################################################
# Baseline
################################################################
record "00-BASELINE" "before_any_load" $outfd

################################################################
# Step 1: Read Libraries & Design
################################################################
puts "\n=== Step 1: Read Libraries ==="
record "01-READ_LIBS" "before" $outfd

read_lef $test_dir/Nangate45/Nangate45_tech.lef
read_lef $test_dir/Nangate45/Nangate45_stdcell.lef
record "01-READ_LIBS" "after_lef" $outfd

read_liberty $test_dir/Nangate45/Nangate45_typ.lib
record "01-READ_LIBS" "after_liberty" $outfd

read_verilog counter_synth.v
link_design counter
record "01-READ_LIBS" "after_verilog_link" $outfd

read_sdc counter.sdc
record "01-READ_LIBS" "after_sdc" $outfd

puts "Design loaded: [sta::network_instance_count] instances"

################################################################
# Step 2: Floorplanning
################################################################
puts "\n=== Step 2: Floorplanning ==="
record "02-FLOORPLAN" "before" $outfd

set site "FreePDK45_38x28_10R_NP_162NW_34O"
initialize_floorplan -site $site \
    -die_area {0 0 100 100} \
    -core_area {5 5 95 95}
source $test_dir/Nangate45/Nangate45.tracks
remove_buffers

record "02-FLOORPLAN" "after" $outfd

################################################################
# Step 3: Tapcell Insertion
################################################################
puts "\n=== Step 3: Tapcell Insertion ==="
record "03-TAPCELL" "before" $outfd

tapcell -distance 120 \
    -tapcell_master TAPCELL_X1 \
    -endcap_master TAPCELL_X1

record "03-TAPCELL" "after" $outfd

################################################################
# Step 4: Power Distribution Network
################################################################
puts "\n=== Step 4: PDN Generation ==="
record "04-PDN" "before" $outfd

source $test_dir/Nangate45/Nangate45.pdn.tcl
pdngen

record "04-PDN" "after" $outfd

################################################################
# Step 5: Global Placement
################################################################
puts "\n=== Step 5: Global Placement ==="
record "05-GLOBAL_PLACE" "before" $outfd

set_global_routing_layer_adjustment {metal2-metal10} 0.5
set_routing_layers -signal metal2-metal10 -clock metal6-metal10
set_macro_extension 2
place_pins -hor_layers metal3 -ver_layers metal2
global_placement -routability_driven -density 0.4 \
    -pad_left 2 -pad_right 2

record "05-GLOBAL_PLACE" "after" $outfd

################################################################
# Step 6: Repair Design
################################################################
puts "\n=== Step 6: Repair Design ==="
record "06-REPAIR_DESIGN" "before" $outfd

source $test_dir/Nangate45/Nangate45.rc
set_wire_rc -signal -layer metal3
set_wire_rc -clock -layer metal6
set_dont_use {CLKBUF_* AOI211_X1 OAI211_X1}
estimate_parasitics -placement
repair_design -slew_margin 0 -cap_margin 20
repair_tie_fanout -separation 5 "LOGIC0_X1/Z"
repair_tie_fanout -separation 5 "LOGIC1_X1/Z"

record "06-REPAIR_DESIGN" "after" $outfd

################################################################
# Step 7: Detailed Placement
################################################################
puts "\n=== Step 7: Detailed Placement ==="
record "07-DETAIL_PLACE" "before" $outfd

set_placement_padding -global -left 1 -right 1
detailed_placement

record "07-DETAIL_PLACE" "after" $outfd

################################################################
# Step 8: Clock Tree Synthesis
################################################################
puts "\n=== Step 8: Clock Tree Synthesis ==="
record "08-CTS" "before" $outfd

repair_clock_inverters
clock_tree_synthesis -root_buf BUF_X4 -buf_list BUF_X4 \
    -sink_clustering_enable \
    -sink_clustering_max_diameter 100
repair_clock_nets
detailed_placement
write_db results/counter_cts.db

record "08-CTS" "after" $outfd

################################################################
# Step 9: Timing Repair
################################################################
puts "\n=== Step 9: Setup/Hold Timing Repair ==="
record "09-TIMING_REPAIR" "before" $outfd

set_propagated_clock [all_clocks]
estimate_parasitics -placement
repair_timing -skip_gate_cloning

record "09-TIMING_REPAIR" "after" $outfd

################################################################
# Step 10: Final Detailed Placement
################################################################
puts "\n=== Step 10: Final Detailed Placement ==="
record "10-FINAL_DPLACE" "before" $outfd

detailed_placement
check_placement -verbose

record "10-FINAL_DPLACE" "after" $outfd

################################################################
# Step 11: Global Routing
################################################################
puts "\n=== Step 11: Global Routing ==="
record "11-GLOBAL_ROUTE" "before" $outfd

pin_access
global_route -guide_file results/counter.route_guide \
    -congestion_iterations 100 -verbose
write_verilog -remove_cells "FILLCELL*" results/counter_routed.v

record "11-GLOBAL_ROUTE" "after" $outfd

################################################################
# Step 12: Antenna Repair
################################################################
puts "\n=== Step 12: Antenna Check/Repair ==="
record "12-ANTENNA" "before" $outfd

repair_antennas -iterations 5
check_antennas

record "12-ANTENNA" "after" $outfd

################################################################
# Step 13: Detailed Routing
################################################################
puts "\n=== Step 13: Detailed Routing ==="
record "13-DETAIL_ROUTE" "before" $outfd

detailed_route \
    -output_drc results/counter_route_drc.rpt \
    -output_maze results/counter_maze.log \
    -no_pin_access \
    -verbose 0

set drv_count [detailed_route_num_drvs]
puts "DRC violations after detailed routing: $drv_count"

record "13-DETAIL_ROUTE" "after" $outfd

write_db results/counter_route.db
write_def results/counter_route.def

################################################################
# Step 14: Filler Cell Placement
################################################################
puts "\n=== Step 14: Filler Cell Placement ==="
record "14-FILLER" "before" $outfd

filler_placement "FILLCELL*"
check_placement -verbose
write_db results/counter_final.db

record "14-FILLER" "after" $outfd

################################################################
# Step 15: Parasitic Extraction
################################################################
puts "\n=== Step 15: Parasitic Extraction ==="
record "15-EXTRACTION" "before" $outfd

define_process_corner -ext_model_index 0 X
extract_parasitics -ext_model_file $test_dir/Nangate45/Nangate45.rcx_rules
write_spef results/counter.spef
read_spef results/counter.spef

record "15-EXTRACTION" "after" $outfd

################################################################
# Step 16: Final STA
################################################################
puts "\n=== Step 16: Final STA ==="
record "16-FINAL_STA" "before" $outfd

report_checks -path_delay max -format full_clock_expanded \
    -fields {input_pin slew capacitance} -digits 3
report_checks -path_delay min -format full_clock_expanded \
    -fields {input_pin slew capacitance} -digits 3
report_worst_slack -min -digits 3
report_worst_slack -max -digits 3
report_tns -digits 3
report_check_types -max_slew -max_capacitance -max_fanout -violators -digits 3
report_clock_skew -digits 3
report_power -corner default
report_design_area

record "16-FINAL_STA" "after" $outfd

################################################################
# Summary Analysis
################################################################
puts $outfd ""
puts $outfd "================================================================="
puts $outfd "  MEMORY PROFILE SUMMARY"
puts $outfd "================================================================="
puts $outfd ""

puts "\n================================================================="
puts "  MEMORY PROFILE SUMMARY"
puts "================================================================="

# Find peak, compute deltas per stage
set peak_rss 0
set peak_stage ""
set prev_rss 0
set stage_deltas {}

# Group by stage: compute before/after delta
set stages {}
array set stage_before {}
array set stage_after {}

foreach entry $mem_timeline {
    set stage [lindex $entry 0]
    set label [lindex $entry 1]
    set rss   [lindex $entry 2]

    if {$rss > $peak_rss} {
        set peak_rss $rss
        set peak_stage "$stage ($label)"
    }

    if {$label eq "before" || $label eq "before_any_load"} {
        set stage_before($stage) $rss
        if {[lsearch $stages $stage] == -1} {
            lappend stages $stage
        }
    } else {
        # Use the last "after*" sample for the stage
        set stage_after($stage) $rss
    }
}

# Print per-stage memory delta table
set hdr [format "%-25s %10s %10s %10s %10s" "Stage" "Before(KB)" "After(KB)" "Delta(KB)" "Delta(MB)"]
puts $outfd $hdr
puts $hdr
set sep [string repeat "-" 70]
puts $outfd $sep
puts $sep

set prev_after_rss 0
set monotonic_increasing 1
set increase_count 0
set total_stages_with_after 0

foreach stage $stages {
    if {[info exists stage_before($stage)] && [info exists stage_after($stage)]} {
        set b $stage_before($stage)
        set a $stage_after($stage)
        set delta [expr {$a - $b}]
        set delta_mb [format "%.1f" [expr {$delta / 1024.0}]]
        set line [format "%-25s %10d %10d %10d %10s" $stage $b $a $delta $delta_mb]
        puts $outfd $line
        puts $line

        incr total_stages_with_after
        if {$prev_after_rss > 0 && $a < $prev_after_rss} {
            set monotonic_increasing 0
        }
        if {$delta > 0} {
            incr increase_count
        }
        set prev_after_rss $a
    }
}

puts $outfd ""
puts ""

set peak_mb [format "%.1f" [expr {$peak_rss / 1024.0}]]
set baseline_rss 0
if {[info exists stage_before(00-BASELINE)]} {
    set baseline_rss $stage_before(00-BASELINE)
}
set baseline_mb [format "%.1f" [expr {$baseline_rss / 1024.0}]]
set total_growth [expr {$peak_rss - $baseline_rss}]
set total_growth_mb [format "%.1f" [expr {$total_growth / 1024.0}]]

set summary_lines {}
lappend summary_lines "Peak RSS:             $peak_rss KB ($peak_mb MB) at $peak_stage"
lappend summary_lines "Baseline RSS:         $baseline_rss KB ($baseline_mb MB)"
lappend summary_lines "Total growth:         $total_growth KB ($total_growth_mb MB)"
lappend summary_lines ""

if {$monotonic_increasing && $total_stages_with_after > 2} {
    lappend summary_lines "WARNING: RSS is monotonically increasing across all stages."
    lappend summary_lines "  This is EXPECTED for a batch PnR flow (data structures accumulate)."
    lappend summary_lines "  A true leak would show growth continuing after flow completion"
    lappend summary_lines "  or disproportionate growth in repeated operations."
} else {
    lappend summary_lines "RSS is NOT monotonically increasing - some stages released memory."
}

lappend summary_lines ""
lappend summary_lines "Stages with memory increase: $increase_count / $total_stages_with_after"

# Identify the largest memory consumers
lappend summary_lines ""
lappend summary_lines "--- Largest memory consumers (by delta) ---"

# Build sortable list of stage deltas
set delta_list {}
foreach stage $stages {
    if {[info exists stage_before($stage)] && [info exists stage_after($stage)]} {
        set delta [expr {$stage_after($stage) - $stage_before($stage)}]
        lappend delta_list [list $stage $delta]
    }
}

# Sort descending by delta
set delta_list [lsort -index 1 -integer -decreasing $delta_list]

set rank 1
foreach item $delta_list {
    set s [lindex $item 0]
    set d [lindex $item 1]
    set d_mb [format "%.1f" [expr {$d / 1024.0}]]
    lappend summary_lines "  #${rank}: $s  +${d} KB (+${d_mb} MB)"
    incr rank
    if {$rank > 5} break
}

lappend summary_lines ""
lappend summary_lines "Completed: [get_timestamp]"

foreach line $summary_lines {
    puts $outfd $line
    puts $line
}

close $outfd
puts "\nMemory profile written to $outfile"
