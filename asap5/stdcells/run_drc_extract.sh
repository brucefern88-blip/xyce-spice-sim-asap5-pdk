#!/bin/bash
# Run Magic VLSI DRC and extraction for NAND2x1 and NOR2x1
# Usage: bash run_drc_extract.sh

MAGIC=/Users/bruce/CLAUDE/magic_install/bin/magic
LAYOUTS=/Users/bruce/CLAUDE/asap5/stdcells/layouts
SPICE=/Users/bruce/CLAUDE/asap5/stdcells/spice

cd "$LAYOUTS"

for CELL in NAND2x1 NOR2x1; do
    echo "=========================================="
    echo "Processing $CELL"
    echo "=========================================="

    $MAGIC -dnull -noconsole -T asap5 <<EOF
load $CELL
select top cell
expand
drc catchup
drc check
puts "$CELL DRC errors: [drc count]"
drc why
extract all
ext2spice lvs
ext2spice -o ${SPICE}/${CELL}_ext.sp
puts "Extraction complete for $CELL"
quit -noprompt
EOF

    echo ""
done

echo "All done."
