# Test: paint nsd directly and poly over it
cellname rename (UNNAMED) test_compose2

# Method 1: paint nsd directly
box 0 0 100 50
paint nsd

box 30 -10 46 60
paint poly

# Add nwell for NMOS check (at top)
# No nwell for NMOS (p-substrate)

# Now test PMOS
box 0 75 100 130
paint psd
box 30 65 46 140
paint poly
box 0 65 100 140
paint nwell

extract all

puts "=== Test 2 complete ==="

# Save and check
save test_compose2
quit -noprompt
