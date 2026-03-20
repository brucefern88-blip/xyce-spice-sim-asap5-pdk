#!/bin/bash
# Build, DRC, and extract AOI21x1 and OAI21x1 standard cells
# Usage: bash build_and_verify.sh

MAGIC=/Users/bruce/CLAUDE/magic_install/bin/magic
LAYOUTS=/Users/bruce/CLAUDE/asap5/stdcells/layouts
SCRIPTS=/Users/bruce/CLAUDE/asap5/stdcells/scripts

echo "=== Running DRC + Extraction for AOI21x1 and OAI21x1 ==="
cd "$LAYOUTS"

$MAGIC -noconsole -dnull -T asap5 <<'EOF'
puts "=== Loading AOI21x1 ==="
load AOI21x1
select top cell
box 0 0 260 140
puts "--- AOI21x1 DRC ---"
drc catchup
drc count
drc listall why
puts "--- AOI21x1 Extract ---"
extract all
ext2spice hierarchy on
ext2spice
puts "AOI21x1 done"
puts ""
puts "=== Loading OAI21x1 ==="
load OAI21x1
select top cell
box 0 0 260 140
puts "--- OAI21x1 DRC ---"
drc catchup
drc count
drc listall why
puts "--- OAI21x1 Extract ---"
extract all
ext2spice hierarchy on
ext2spice
puts "OAI21x1 done"
quit -noprompt
EOF

echo ""
echo "=== Generated files ==="
ls -la "$LAYOUTS"/AOI21x1.* "$LAYOUTS"/OAI21x1.* 2>/dev/null
echo ""
echo "=== Done ==="
