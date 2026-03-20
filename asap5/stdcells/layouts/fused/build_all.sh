#!/bin/bash
# Build all 4 fused Hamming cell layouts
# Run from: /Users/bruce/CLAUDE/asap5/stdcells/layouts/fused/

MAGIC=/Users/bruce/CLAUDE/magic_install/bin/magic
DIR=/Users/bruce/CLAUDE/asap5/stdcells/layouts/fused

cd "$DIR"

echo "=== Building FUSED_A ==="
$MAGIC -dnull -noconsole -T asap5 build_fused_A.tcl 2>&1

echo ""
echo "=== Building FUSED_E ==="
$MAGIC -dnull -noconsole -T asap5 build_fused_E.tcl 2>&1

echo ""
echo "=== Building FUSED_F ==="
$MAGIC -dnull -noconsole -T asap5 build_fused_F.tcl 2>&1

echo ""
echo "=== Building FUSED_G ==="
$MAGIC -dnull -noconsole -T asap5 build_fused_G.tcl 2>&1

echo ""
echo "=== Summary ==="
for cell in FUSED_A FUSED_E FUSED_F FUSED_G; do
    if [ -f "${cell}.mag" ]; then
        echo "$cell: layout saved (.mag exists)"
    else
        echo "$cell: MISSING layout"
    fi
    if [ -f "${cell}_ext.spice" ]; then
        echo "$cell: SPICE extracted"
    else
        echo "$cell: MISSING extracted SPICE"
    fi
done
