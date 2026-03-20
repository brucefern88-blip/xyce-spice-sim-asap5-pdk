# Magic VLSI batch script: DRC + extract for NAND2x1 and NOR2x1
# Run with: magic -dnull -noconsole -T asap5 < run_magic.tcl

puts "============================================"
puts "Processing NAND2x1"
puts "============================================"

load /Users/bruce/CLAUDE/asap5/stdcells/layouts/NAND2x1

# Flatten and select all for DRC
select top cell
expand

# Run DRC
drc catchup
drc check
set drc_count [drc count]
puts "NAND2x1 DRC errors: $drc_count"
if {$drc_count > 0} {
    drc why
}

# Extract
extract all
ext2spice lvs
ext2spice -o /Users/bruce/CLAUDE/asap5/stdcells/spice/NAND2x1_ext.sp

puts ""
puts "============================================"
puts "Processing NOR2x1"
puts "============================================"

load /Users/bruce/CLAUDE/asap5/stdcells/layouts/NOR2x1

select top cell
expand

drc catchup
drc check
set drc_count [drc count]
puts "NOR2x1 DRC errors: $drc_count"
if {$drc_count > 0} {
    drc why
}

extract all
ext2spice lvs
ext2spice -o /Users/bruce/CLAUDE/asap5/stdcells/spice/NOR2x1_ext.sp

puts ""
puts "Done."
quit -noprompt
