#!/bin/bash
# Launch LayoutEditor with ASAP5 PDK
# Usage:
#   ./launch_layouteditor.sh              # Open LayoutEditor with ASAP5 layers
#   ./launch_layouteditor.sh file.gds     # Open a specific GDS
#   ./launch_layouteditor.sh --library    # Open the combined ASAP5 cell library

CHARFLOW_DIR="$(cd "$(dirname "$0")" && pwd)"
GDS_DIR="$CHARFLOW_DIR/gds"
LAYER_MACRO="$CHARFLOW_DIR/layouteditor/autoLayerMacro.layout"

case "$1" in
    --library)
        COMBINED="$GDS_DIR/asap5_stdcells.gds"
        if [ ! -f "$COMBINED" ]; then
            echo "Building combined library..."
            cd "$GDS_DIR" && python3 combine_library.py
        fi
        open /Applications/layout.app "$COMBINED"
        ;;
    "")
        open /Applications/layout.app
        ;;
    *)
        open /Applications/layout.app "$1"
        ;;
esac

echo "LayoutEditor opened."
echo "To load ASAP5 layers: Utilities > Macro > Browse > select:"
echo "  $LAYER_MACRO"
