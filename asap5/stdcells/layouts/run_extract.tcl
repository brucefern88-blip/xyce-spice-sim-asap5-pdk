load MUX21x1
extract all
ext2spice lvs
ext2spice cthresh 0.01
ext2spice
puts "=== SPICE extraction complete ==="
quit -noprompt
