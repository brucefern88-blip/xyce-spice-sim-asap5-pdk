# ============================================================================
# EXPERIMENT: Wired-OR / Wired-AND Methodology in OpenROAD
# ============================================================================
# Goal: Find efficient ways to implement passive crosspoint operations
# using OpenROAD's placement and routing capabilities.
#
# Three approaches tested:
#   1. Placement grouping — cluster crosspoint cells to minimize wire RC
#   2. Custom net topology — manipulate net connections for multi-tap wires
#   3. Direct via insertion — create crosspoint via patterns programmatically
# ============================================================================

read_liberty /Users/bruce/CLAUDE/asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib
read_liberty /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/lib/n5_utility_cells_tt_0p5v_25c.lib
read_db /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/openlane2/runs/pass_a/final/odb/hamming_64b_cuboid_r4_xp.odb

set_wire_rc -layer M2
estimate_parasitics -global_routing
read_sdc /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/sdc/hamming_cuboid_r4.sdc

set block [ord::get_db_block]
set db [ord::get_db]
set tech [$db getTech]

puts "\n================================================================"
puts " EXPERIMENT 1: Analyze current crosspoint cell placement spread"
puts "================================================================\n"

# For each crosspoint type, measure the bounding box of its cells
proc measure_crosspoint_bbox {block pattern} {
    set min_x 999999
    set min_y 999999
    set max_x 0
    set max_y 0
    set count 0

    foreach inst [$block getInsts] {
        set name [$inst getName]
        if {[string match $pattern $name]} {
            set bbox [$inst getBBox]
            set x [$bbox xMin]
            set y [$bbox yMin]
            set x2 [$bbox xMax]
            set y2 [$bbox yMax]
            if {$x < $min_x} {set min_x $x}
            if {$y < $min_y} {set min_y $y}
            if {$x2 > $max_x} {set max_x $x2}
            if {$y2 > $max_y} {set max_y $y2}
            incr count
        }
    }

    if {$count == 0} {return "no cells found"}

    set dx [expr {($max_x - $min_x) / 1000.0}]
    set dy [expr {($max_y - $min_y) / 1000.0}]
    set area [expr {$dx * $dy}]
    return [format "%3d cells  bbox: %.2f x %.2f um = %.2f um²" $count $dx $dy $area]
}

puts "Crosspoint placement spread (current):"
puts "  3x3 S2L1 #0:   [measure_crosspoint_bbox $block {xp3_s2l1\[0\]*}]"
puts "  3x3 S2L1 #8:   [measure_crosspoint_bbox $block {xp3_s2l1\[8\]*}]"
puts "  5x5 S2L2 #0:   [measure_crosspoint_bbox $block {xp5_s2l2\[0\]*}]"
puts "  5x5 S2L2 #4:   [measure_crosspoint_bbox $block {xp5_s2l2\[4\]*}]"
puts "  4x4 Lo L1 #0:  [measure_crosspoint_bbox $block {xp4_lo_l1\[0\]*}]"
puts "  7x7 Lo L2 #0:  [measure_crosspoint_bbox $block {xp7_lo_l2\[0\]*}]"
puts "  7x7 Lo L2 #1:  [measure_crosspoint_bbox $block {xp7_lo_l2\[1\]*}]"
puts "  13x13 Lo L3:   [measure_crosspoint_bbox $block {u_xp13_lo_l3*}]"
puts "  3x3 Hi L1 #0:  [measure_crosspoint_bbox $block {xp3_hi_l1\[0\]*}]"
puts "  5x5 Hi L2 #0:  [measure_crosspoint_bbox $block {xp5_hi_l2\[0\]*}]"
puts "  9x9 Hi L3:     [measure_crosspoint_bbox $block {u_xp9_hi_l3*}]"
puts "  17x7 Carry:    [measure_crosspoint_bbox $block {u_xp17x7_carry*}]"

puts "\n================================================================"
puts " EXPERIMENT 2: Analyze crosspoint net topology"
puts "================================================================\n"

# Count nets and their fanout within each crosspoint
proc analyze_crosspoint_nets {block pattern} {
    set nets_internal 0
    set nets_external 0
    set max_fanout 0

    foreach net [$block getNets] {
        set name [$net getName]
        if {[string match $pattern $name]} {
            set iterm_count [llength [$net getITerms]]
            if {$iterm_count > $max_fanout} {set max_fanout $iterm_count}
            incr nets_internal
        }
    }
    return [format "internal nets: %d, max fanout: %d" $nets_internal $max_fanout]
}

puts "Crosspoint net analysis:"
puts "  3x3 S2L1 #0:   [analyze_crosspoint_nets $block {xp3_s2l1\[0\]*}]"
puts "  13x13 Lo L3:   [analyze_crosspoint_nets $block {u_xp13_lo_l3*}]"
puts "  17x7 Carry:    [analyze_crosspoint_nets $block {u_xp17x7_carry*}]"

puts "\n================================================================"
puts " EXPERIMENT 3: Measure wire RC for crosspoint connections"
puts "================================================================\n"

# Find the highest-RC nets (these are the crosspoint wires)
set net_delays {}
foreach net [$block getNets] {
    set name [$net getName]
    set wire [$net getWire]
    if {$wire == "NULL"} continue
    set iterm_count [llength [$net getITerms]]
    if {$iterm_count < 2} continue

    # Get wire length
    set bbox [$net getBBox]
    set wl [expr {([$bbox xMax] - [$bbox xMin] + [$bbox yMax] - [$bbox yMin]) / 1000.0}]

    if {$wl > 1.0} {
        lappend net_delays [list $name $wl $iterm_count]
    }
}

# Sort by wire length descending
set net_delays [lsort -index 1 -real -decreasing $net_delays]

puts "Top 20 longest nets (potential crosspoint wires):"
puts [format "  %-50s  %8s  %6s" "Net" "WL(um)" "Fanout"]
puts "  [string repeat - 70]"
set i 0
foreach nd $net_delays {
    if {$i >= 20} break
    puts [format "  %-50s  %8.2f  %6d" [lindex $nd 0] [lindex $nd 1] [lindex $nd 2]]
    incr i
}

puts "\n================================================================"
puts " EXPERIMENT 4: Identify wired-AND/OR patterns in netlist"  
puts "================================================================\n"

# Count cell types within each crosspoint module
proc count_xp_cells {block pattern} {
    set nand 0; set nor 0; set inv 0; set aoi 0; set oai 0; set xor 0; set buf 0; set other 0
    foreach inst [$block getInsts] {
        set name [$inst getName]
        if {![string match $pattern $name]} continue
        set master [[$inst getMaster] getName]
        switch -glob $master {
            NAND* {incr nand}
            NOR*  {incr nor}
            INV*  {incr inv}
            AOI*  {incr aoi}
            OAI*  {incr oai}
            XOR* - XNOR* {incr xor}
            BUF*  {incr buf}
            default {incr other}
        }
    }
    return [format "NAND:%d NOR:%d INV:%d AOI:%d OAI:%d XOR:%d BUF:%d" $nand $nor $inv $aoi $oai $xor $buf]
}

puts "Cell composition per crosspoint type:"
puts "  3x3 (14 cells): [count_xp_cells $block {xp3_s2l1\[0\]*}]"
puts "  5x5 (38 cells): [count_xp_cells $block {xp5_s2l2\[0\]*}]"
puts "  4x4 (25 cells): [count_xp_cells $block {xp4_lo_l1\[0\]*}]"
puts "  7x7 (73 cells): [count_xp_cells $block {xp7_lo_l2\[0\]*}]"
puts "  9x9 (120 cells): [count_xp_cells $block {u_xp9_hi_l3*}]"
puts "  13x13 (173 cells): [count_xp_cells $block {u_xp13_lo_l3*}]"
puts "  17x7 (250 cells): [count_xp_cells $block {u_xp17x7_carry*}]"

puts "\n================================================================"
puts " METHODOLOGY PROPOSAL"
puts "================================================================\n"

puts "Based on analysis, the optimal methodology for wired-AND/OR in OpenROAD:"
puts ""
puts "1. COMPOUND GATES: ABC already maps AND+OR → AOI21/OAI21 compound cells."
puts "   Each compound cell implements one crosspoint intersection + partial OR"
puts "   in a single gate delay. This is the standard-cell equivalent of a via."
puts ""
puts "2. PLACEMENT GROUPING: Force each crosspoint's cells into a tight region"
puts "   using create_region constraints. This minimizes inter-cell wire RC,"
puts "   approximating the sub-pitch wire lengths of a passive crosspoint."
puts ""
puts "3. LAYER-AWARE ROUTING: Constrain each crosspoint stage to specific"
puts "   metal layers using set_routing_layers per-net, matching the docx"
puts "   metal layer assignment (M2/M3 for Stage 2, M6 for Stage 4 L1, etc.)"
puts ""
puts "4. CUSTOM VIA INSERTION: For critical crosspoints (13x13, 17x7),"
puts "   post-route optimization can replace gate-level AND+OR with direct"
puts "   via connections where the one-hot encoding guarantees no contention."

exit
