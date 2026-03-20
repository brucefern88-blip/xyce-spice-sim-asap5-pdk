# DRC and extract for AOI21x1 and OAI21x1
# Run from the layouts directory

puts "=== Loading AOI21x1 ==="
load /Users/bruce/CLAUDE/asap5/stdcells/layouts/AOI21x1
select top cell
box 0 0 260 140
puts "--- AOI21x1 DRC ---"
drc catchup
set cnt [drc count]
puts "AOI21x1 DRC errors: $cnt"
drc listall why
puts "--- AOI21x1 Extract ---"
extract all
ext2spice hierarchy on
ext2spice
puts "AOI21x1 extraction done"

puts ""
puts "=== Loading OAI21x1 ==="
load /Users/bruce/CLAUDE/asap5/stdcells/layouts/OAI21x1
select top cell
box 0 0 260 140
puts "--- OAI21x1 DRC ---"
drc catchup
set cnt [drc count]
puts "OAI21x1 DRC errors: $cnt"
drc listall why
puts "--- OAI21x1 Extract ---"
extract all
ext2spice hierarchy on
ext2spice
puts "OAI21x1 extraction done"

puts ""
puts "=== Complete ==="
quit -noprompt
