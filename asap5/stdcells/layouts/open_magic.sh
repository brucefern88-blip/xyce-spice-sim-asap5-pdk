#!/bin/bash
# Launch Magic with ASAP5 PDK and Virtuoso-like GUI panels
# Usage: ./open_magic.sh [cellname]   (default: INVx1)

CELL="${1:-INVx1}"
MAGIC=/Users/bruce/CLAUDE/magic_new/bin/magic
TECH=/Users/bruce/CLAUDE/asap5/magic/asap5.tech
DIR="$(cd "$(dirname "$0")" && pwd)"

export DISPLAY="${DISPLAY:-:0}"

if ! xdpyinfo >/dev/null 2>&1; then
    echo "No X11 display found. Starting XQuartz..."
    open -a XQuartz 2>/dev/null
    sleep 3
    export DISPLAY=:0
fi

echo "Opening Magic v8.3.625 (Cairo) with ASAP5 PDK"
echo "Cell: $CELL"
echo "Tech: $TECH"
echo ""
echo "New panels available in console:"
echo "  magic::propinspector   - Property Inspector"
echo "  magic::layermgr        - Layer Manager"

cd "$DIR"
exec "$MAGIC" -T "$TECH" "$CELL"
