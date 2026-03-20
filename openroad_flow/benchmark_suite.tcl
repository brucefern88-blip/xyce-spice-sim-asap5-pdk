# OpenROAD PnR Benchmark Suite
# Runs counter (87 cells) and AES (156K cells) with per-stage timing,
# memory tracking, and metric collection.
# Outputs: results/benchmark_results.csv, results/benchmark_report.txt

set test_dir "../OpenROAD/test"

# ---- Utility procs ----

proc elapsed_ms { start } {
    return [expr {[clock milliseconds] - $start}]
}

proc peak_mem_mb {} {
    # macOS: use ps to get resident set size of current process
    if {[catch {
        set pid [pid]
        set rss [exec ps -o rss= -p $pid]
        set mb [expr {$rss / 1024.0}]
    }]} {
        # Fallback: try /proc on Linux
        if {[catch {
            set f [open "/proc/self/status" r]
            set data [read $f]
            close $f
            regexp {VmRSS:\s+(\d+)} $data -> kb
            set mb [expr {$kb / 1024.0}]
        }]} {
            set mb 0.0
        }
    }
    return [format "%.1f" $mb]
}

proc get_instance_count {} {
    if {[catch {set n [sta::network_instance_count]} err]} {
        return 0
    }
    return $n
}

proc get_wns {} {
    if {[catch {set wns [sta::worst_slack -max]} err]} {
        return "N/A"
    }
    return [format "%.3f" $wns]
}

proc get_tns {} {
    if {[catch {set tns [sta::total_negative_slack -max]} err]} {
        return "N/A"
    }
    return [format "%.3f" $tns]
}

proc get_design_area {} {
    if {[catch {
        set metrics [sta::design_area]
    } err]} {
        return "N/A"
    }
    return [format "%.1f" $metrics]
}

proc get_power_total {} {
    # Attempt to capture total power from report_power output
    if {[catch {
        set rpt [report_power -corner default -digits 6]
    } err]} {
        return "N/A"
    }
    return "see_report"
}

# ---- CSV setup ----

file mkdir results
set csv_file "results/benchmark_results.csv"
set rpt_file "results/benchmark_report.txt"

set csv_fd [open $csv_file w]
puts $csv_fd "design,stage,runtime_ms,instances,WNS,TNS,DRC,area,power_mw,peak_mem_mb"

set rpt_fd [open $rpt_file w]
proc report_line { fd msg } {
    puts $fd $msg
    puts $msg
}

proc log_stage { csv_fd design stage runtime_ms instances wns tns drc area power mem } {
    puts $csv_fd "$design,$stage,$runtime_ms,$instances,$wns,$tns,$drc,$area,$power,$mem"
    flush $csv_fd
}

report_line $rpt_fd "========================================================"
report_line $rpt_fd "  OpenROAD PnR Benchmark Suite"
report_line $rpt_fd "  Date: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
report_line $rpt_fd "  Threads: [cpu_count]"
report_line $rpt_fd "========================================================"

set_thread_count [cpu_count]

################################################################
#  DESIGN 1: Counter (87 cells)
################################################################
set design_name "counter"
set design_start [clock milliseconds]

report_line $rpt_fd "\n--------------------------------------------------------"
report_line $rpt_fd "  Design: $design_name"
report_line $rpt_fd "--------------------------------------------------------"

# Stage: READ
set t0 [clock milliseconds]
read_lef $test_dir/Nangate45/Nangate45_tech.lef
read_lef $test_dir/Nangate45/Nangate45_stdcell.lef
read_liberty $test_dir/Nangate45/Nangate45_typ.lib
read_verilog counter_synth.v
link_design counter
read_sdc counter.sdc
set rt [elapsed_ms $t0]
set inst [get_instance_count]
log_stage $csv_fd $design_name "read" $rt $inst "N/A" "N/A" 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms  (%d instances)" "READ" $rt $inst]

# Stage: FLOORPLAN
set t0 [clock milliseconds]
initialize_floorplan -site "FreePDK45_38x28_10R_NP_162NW_34O" \
    -die_area {0 0 100 100} \
    -core_area {5 5 95 95}
source $test_dir/Nangate45/Nangate45.tracks
remove_buffers
set rt [elapsed_ms $t0]
set inst [get_instance_count]
log_stage $csv_fd $design_name "floorplan" $rt $inst "N/A" "N/A" 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms" "FLOORPLAN" $rt]

# Stage: TAPCELL + PDN
set t0 [clock milliseconds]
tapcell -distance 120 -tapcell_master TAPCELL_X1 -endcap_master TAPCELL_X1
source $test_dir/Nangate45/Nangate45.pdn.tcl
pdngen
set rt [elapsed_ms $t0]
set inst [get_instance_count]
log_stage $csv_fd $design_name "tapcell_pdn" $rt $inst "N/A" "N/A" 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms" "TAPCELL+PDN" $rt]

# Stage: GLOBAL PLACEMENT
set t0 [clock milliseconds]
set_global_routing_layer_adjustment {metal2-metal10} 0.5
set_routing_layers -signal metal2-metal10 -clock metal6-metal10
set_macro_extension 2
place_pins -hor_layers metal3 -ver_layers metal2
global_placement -routability_driven -density 0.4 -pad_left 2 -pad_right 2
set rt [elapsed_ms $t0]
set inst [get_instance_count]
log_stage $csv_fd $design_name "global_placement" $rt $inst "N/A" "N/A" 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms" "GLOBAL_PLACEMENT" $rt]

# Stage: REPAIR DESIGN
set t0 [clock milliseconds]
source $test_dir/Nangate45/Nangate45.rc
set_wire_rc -signal -layer metal3
set_wire_rc -clock -layer metal6
set_dont_use {CLKBUF_* AOI211_X1 OAI211_X1}
estimate_parasitics -placement
repair_design -slew_margin 0 -cap_margin 20
repair_tie_fanout -separation 5 "LOGIC0_X1/Z"
repair_tie_fanout -separation 5 "LOGIC1_X1/Z"
set rt [elapsed_ms $t0]
set inst [get_instance_count]
set wns [get_wns]
set tns [get_tns]
log_stage $csv_fd $design_name "repair_design" $rt $inst $wns $tns 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms  WNS=%s TNS=%s" "REPAIR_DESIGN" $rt $wns $tns]

# Stage: DETAILED PLACEMENT
set t0 [clock milliseconds]
set_placement_padding -global -left 1 -right 1
detailed_placement
set rt [elapsed_ms $t0]
set inst [get_instance_count]
set wns [get_wns]
set tns [get_tns]
log_stage $csv_fd $design_name "detailed_placement" $rt $inst $wns $tns 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms  WNS=%s TNS=%s" "DETAILED_PLACEMENT" $rt $wns $tns]

# Stage: CTS
set t0 [clock milliseconds]
repair_clock_inverters
clock_tree_synthesis -root_buf BUF_X4 -buf_list BUF_X4 \
    -sink_clustering_enable -sink_clustering_max_diameter 100
repair_clock_nets
detailed_placement
set rt [elapsed_ms $t0]
set inst [get_instance_count]
set wns [get_wns]
set tns [get_tns]
log_stage $csv_fd $design_name "cts" $rt $inst $wns $tns 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms  WNS=%s TNS=%s" "CTS" $rt $wns $tns]

# Stage: TIMING REPAIR
set t0 [clock milliseconds]
set_propagated_clock [all_clocks]
estimate_parasitics -placement
repair_timing -skip_gate_cloning
detailed_placement
set rt [elapsed_ms $t0]
set inst [get_instance_count]
set wns [get_wns]
set tns [get_tns]
log_stage $csv_fd $design_name "timing_repair" $rt $inst $wns $tns 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms  WNS=%s TNS=%s" "TIMING_REPAIR" $rt $wns $tns]

# Stage: GLOBAL ROUTING
set t0 [clock milliseconds]
pin_access
global_route -guide_file results/counter_bench_route_guide \
    -congestion_iterations 100 -verbose
set rt [elapsed_ms $t0]
set inst [get_instance_count]
set wns [get_wns]
set tns [get_tns]
log_stage $csv_fd $design_name "global_routing" $rt $inst $wns $tns 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms" "GLOBAL_ROUTING" $rt]

# Stage: ANTENNA REPAIR
set t0 [clock milliseconds]
repair_antennas -iterations 5
check_antennas
set rt [elapsed_ms $t0]
log_stage $csv_fd $design_name "antenna_repair" $rt $inst "N/A" "N/A" 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms" "ANTENNA_REPAIR" $rt]

# Stage: DETAILED ROUTING
set t0 [clock milliseconds]
detailed_route \
    -output_drc results/counter_bench_drc.rpt \
    -output_maze results/counter_bench_maze.log \
    -no_pin_access -verbose 0
set drv_count [detailed_route_num_drvs]
set rt [elapsed_ms $t0]
set inst [get_instance_count]
set wns [get_wns]
set tns [get_tns]
log_stage $csv_fd $design_name "detailed_routing" $rt $inst $wns $tns $drv_count "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms  DRVs=%d" "DETAILED_ROUTING" $rt $drv_count]

# Stage: FILLER + EXTRACTION
set t0 [clock milliseconds]
filler_placement "FILLCELL*"
define_process_corner -ext_model_index 0 X
extract_parasitics -ext_model_file $test_dir/Nangate45/Nangate45.rcx_rules
write_spef results/counter_bench.spef
read_spef results/counter_bench.spef
set rt [elapsed_ms $t0]
log_stage $csv_fd $design_name "fill_extract" $rt $inst "N/A" "N/A" 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms" "FILL+EXTRACT" $rt]

# Stage: FINAL STA
set t0 [clock milliseconds]
set final_wns [get_wns]
set final_tns [get_tns]
set final_area [get_design_area]
set final_inst [get_instance_count]
set rt [elapsed_ms $t0]
log_stage $csv_fd $design_name "final_sta" $rt $final_inst $final_wns $final_tns $drv_count $final_area "N/A" [peak_mem_mb]

set counter_total [elapsed_ms $design_start]
report_line $rpt_fd ""
report_line $rpt_fd [format "  %-25s %8d ms" "TOTAL" $counter_total]
report_line $rpt_fd "  Final instances: $final_inst"
report_line $rpt_fd "  Final WNS: $final_wns ns"
report_line $rpt_fd "  Final TNS: $final_tns ns"
report_line $rpt_fd "  Final area: $final_area"
report_line $rpt_fd "  DRC violations: $drv_count"
report_line $rpt_fd "  Peak memory: [peak_mem_mb] MB"

# Write counter DB and clean up for next design
write_db results/counter_bench_final.db

# Power report (captured to report file)
puts $rpt_fd "\n  --- Power ---"
report_power -corner default

puts $rpt_fd "\n  --- Timing ---"
report_checks -path_delay max -format full_clock_expanded \
    -fields {input_pin slew capacitance} -digits 3

################################################################
#  DESIGN 2: AES (156K cells)
################################################################
# Clear state for the next design by restarting in the same process.
# OpenROAD doesn't have a clean "reset" so we rely on read_* overwriting.

set design_name "aes"
set design_start [clock milliseconds]

report_line $rpt_fd "\n--------------------------------------------------------"
report_line $rpt_fd "  Design: $design_name"
report_line $rpt_fd "--------------------------------------------------------"

# Stage: READ
set t0 [clock milliseconds]
read_lef $test_dir/Nangate45/Nangate45_tech.lef
read_lef $test_dir/Nangate45/Nangate45_stdcell.lef
read_liberty $test_dir/Nangate45/Nangate45_typ.lib
read_verilog $test_dir/aes_nangate45.v
link_design aes_cipher_top
source $test_dir/flow_helpers.tcl
read_sdc $test_dir/aes_nangate45.sdc
set rt [elapsed_ms $t0]
set inst [get_instance_count]
log_stage $csv_fd $design_name "read" $rt $inst "N/A" "N/A" 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms  (%d instances)" "READ" $rt $inst]

# Stage: FLOORPLAN
set t0 [clock milliseconds]
initialize_floorplan -site "FreePDK45_38x28_10R_NP_162NW_34O" \
    -die_area {0 0 1020 920.8} -core_area {10 12 1010 911.2}
source $test_dir/Nangate45/Nangate45.tracks
remove_buffers
set rt [elapsed_ms $t0]
set inst [get_instance_count]
log_stage $csv_fd $design_name "floorplan" $rt $inst "N/A" "N/A" 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms" "FLOORPLAN" $rt]

# Stage: TAPCELL + PDN
set t0 [clock milliseconds]
tapcell -distance 120 -tapcell_master TAPCELL_X1 -endcap_master TAPCELL_X1
source $test_dir/Nangate45/Nangate45.pdn.tcl
pdngen
set rt [elapsed_ms $t0]
set inst [get_instance_count]
log_stage $csv_fd $design_name "tapcell_pdn" $rt $inst "N/A" "N/A" 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms" "TAPCELL+PDN" $rt]

# Stage: GLOBAL PLACEMENT
set t0 [clock milliseconds]
set_global_routing_layer_adjustment {metal2-metal10} 0.5
set_routing_layers -signal metal2-metal10 -clock metal6-metal10
set_macro_extension 2
place_pins -hor_layers metal3 -ver_layers metal2
global_placement -routability_driven -density 0.3 -pad_left 2 -pad_right 2
set rt [elapsed_ms $t0]
set inst [get_instance_count]
log_stage $csv_fd $design_name "global_placement" $rt $inst "N/A" "N/A" 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms" "GLOBAL_PLACEMENT" $rt]

# Stage: REPAIR DESIGN
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
set rt [elapsed_ms $t0]
set inst [get_instance_count]
set wns [get_wns]
set tns [get_tns]
log_stage $csv_fd $design_name "repair_design" $rt $inst $wns $tns 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms  WNS=%s TNS=%s" "REPAIR+DPL" $rt $wns $tns]

# Stage: CTS
set t0 [clock milliseconds]
repair_clock_inverters
clock_tree_synthesis -root_buf BUF_X4 -buf_list BUF_X4 \
    -sink_clustering_enable -sink_clustering_max_diameter 100
repair_clock_nets
detailed_placement
set rt [elapsed_ms $t0]
set inst [get_instance_count]
set wns [get_wns]
set tns [get_tns]
log_stage $csv_fd $design_name "cts" $rt $inst $wns $tns 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms  WNS=%s TNS=%s" "CTS" $rt $wns $tns]

# Stage: TIMING REPAIR
set t0 [clock milliseconds]
set_propagated_clock [all_clocks]
estimate_parasitics -placement
repair_timing -skip_gate_cloning
detailed_placement
set rt [elapsed_ms $t0]
set inst [get_instance_count]
set wns [get_wns]
set tns [get_tns]
log_stage $csv_fd $design_name "timing_repair" $rt $inst $wns $tns 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms  WNS=%s TNS=%s" "TIMING_REPAIR" $rt $wns $tns]

# Stage: GLOBAL ROUTING
set t0 [clock milliseconds]
pin_access
global_route -guide_file results/aes_bench_route_guide \
    -congestion_iterations 100 -verbose
set rt [elapsed_ms $t0]
set inst [get_instance_count]
set wns [get_wns]
set tns [get_tns]
log_stage $csv_fd $design_name "global_routing" $rt $inst $wns $tns 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms" "GLOBAL_ROUTING" $rt]

# Stage: ANTENNA REPAIR
set t0 [clock milliseconds]
repair_antennas -iterations 5
check_antennas
set rt [elapsed_ms $t0]
log_stage $csv_fd $design_name "antenna_repair" $rt $inst "N/A" "N/A" 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms" "ANTENNA_REPAIR" $rt]

# Stage: DETAILED ROUTING
set t0 [clock milliseconds]
detailed_route \
    -output_drc results/aes_bench_drc.rpt \
    -output_maze results/aes_bench_maze.log \
    -no_pin_access -verbose 0
set drv_count [detailed_route_num_drvs]
set rt [elapsed_ms $t0]
set inst [get_instance_count]
set wns [get_wns]
set tns [get_tns]
log_stage $csv_fd $design_name "detailed_routing" $rt $inst $wns $tns $drv_count "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms  DRVs=%d" "DETAILED_ROUTING" $rt $drv_count]

# Stage: FILLER + EXTRACTION
set t0 [clock milliseconds]
filler_placement "FILLCELL*"
define_process_corner -ext_model_index 0 X
extract_parasitics -ext_model_file $test_dir/Nangate45/Nangate45.rcx_rules
write_spef results/aes_bench.spef
read_spef results/aes_bench.spef
set rt [elapsed_ms $t0]
log_stage $csv_fd $design_name "fill_extract" $rt $inst "N/A" "N/A" 0 "N/A" "N/A" [peak_mem_mb]
report_line $rpt_fd [format "  %-25s %8d ms" "FILL+EXTRACT" $rt]

# Stage: FINAL STA
set t0 [clock milliseconds]
set final_wns [get_wns]
set final_tns [get_tns]
set final_area [get_design_area]
set final_inst [get_instance_count]
set rt [elapsed_ms $t0]
log_stage $csv_fd $design_name "final_sta" $rt $final_inst $final_wns $final_tns $drv_count $final_area "N/A" [peak_mem_mb]

set aes_total [elapsed_ms $design_start]
report_line $rpt_fd ""
report_line $rpt_fd [format "  %-25s %8d ms" "TOTAL" $aes_total]
report_line $rpt_fd "  Final instances: $final_inst"
report_line $rpt_fd "  Final WNS: $final_wns ns"
report_line $rpt_fd "  Final TNS: $final_tns ns"
report_line $rpt_fd "  Final area: $final_area"
report_line $rpt_fd "  DRC violations: $drv_count"
report_line $rpt_fd "  Peak memory: [peak_mem_mb] MB"

# Write AES DB
write_db results/aes_bench_final.db

# Power report
puts $rpt_fd "\n  --- Power ---"
report_power -corner default

puts $rpt_fd "\n  --- Timing ---"
report_checks -path_delay max -format full_clock_expanded \
    -fields {input_pin slew capacitance} -digits 3

################################################################
#  Summary
################################################################
report_line $rpt_fd "\n========================================================"
report_line $rpt_fd "  BENCHMARK SUMMARY"
report_line $rpt_fd "========================================================"
report_line $rpt_fd [format "  %-15s %10s %10s" "Design" "Total (ms)" "Instances"]
report_line $rpt_fd [format "  %-15s %10d %10d" "counter" $counter_total [get_instance_count]]
report_line $rpt_fd [format "  %-15s %10d %10d" "aes" $aes_total $final_inst]
report_line $rpt_fd ""
report_line $rpt_fd "  CSV: results/benchmark_results.csv"
report_line $rpt_fd "  Report: results/benchmark_report.txt"
report_line $rpt_fd "========================================================"

close $csv_fd
close $rpt_fd

puts "\nBenchmark suite complete."
puts "  CSV:    results/benchmark_results.csv"
puts "  Report: results/benchmark_report.txt"
