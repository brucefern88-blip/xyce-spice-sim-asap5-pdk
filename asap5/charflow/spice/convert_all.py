#!/usr/bin/env python3
"""Convert all Magic-extracted SPICE files from w= to nfin= for Xyce."""
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).parent.parent.parent.parent))
from asap5.charflow.scripts.xyce_utils import magic_to_xyce
from pathlib import Path

SRC_DIR = Path('/Users/bruce/CLAUDE/asap5/stdcells/spice/extracted')
DST_DIR = Path(__file__).parent

for src in sorted(SRC_DIR.glob('*.sp')):
    dst = DST_DIR / f'{src.stem}.spice'
    magic_to_xyce(str(src), str(dst))
    print(f'  {src.name} -> {dst.name}')

print(f'Converted {len(list(SRC_DIR.glob("*.sp")))} files.')
