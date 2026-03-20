#!/usr/bin/env magic
# Run DRC and extraction on all XOR/XNOR cells
# Usage: magic -dnull -noconsole -T asap5 < run_drc_extract.tcl

foreach cellname {XOR2x1 XOR2x2 XNOR2x1 XNOR2x2} {
    puts "============================================"
    puts "Processing $cellname"
    puts "============================================"

    load $cellname

    # Select everything and run DRC
    select top cell
    puts "Running DRC on $cellname..."
    drc catchup
    drc why
    set count [drc list count]
    puts "DRC errors: $count"

    # Extract
    puts "Extracting $cellname..."
    extract all
    ext2spice lvs
    ext2spice -o /Users/bruce/CLAUDE/asap5/stdcells/spice/${cellname}_ext.spice

    # Save
    save

    puts "$cellname done."
    puts ""
}

puts "All cells processed."
quit -noprompt
