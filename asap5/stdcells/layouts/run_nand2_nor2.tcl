puts "=== NAND2x1 ==="
load NAND2x1
select top cell
expand
drc catchup
drc check
puts "NAND2x1 DRC count: [drc count]"
drc why
extract all
ext2spice lvs
ext2spice -o /Users/bruce/CLAUDE/asap5/stdcells/spice/NAND2x1_ext.sp
puts "NAND2x1 done"

puts ""
puts "=== NOR2x1 ==="
load NOR2x1
select top cell
expand
drc catchup
drc check
puts "NOR2x1 DRC count: [drc count]"
drc why
extract all
ext2spice lvs
ext2spice -o /Users/bruce/CLAUDE/asap5/stdcells/spice/NOR2x1_ext.sp
puts "NOR2x1 done"

quit -noprompt
