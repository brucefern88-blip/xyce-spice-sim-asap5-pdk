#!/usr/bin/env python3
"""Combine all individual cell GDS files into one ASAP5 library GDS."""
import gdstk
from pathlib import Path

gds_dir = Path(__file__).parent
lib = gdstk.Library(unit=1e-9, precision=1e-12, name="ASAP5_STDCELLS")

cell_names = [
    'INVx1', 'INVx2', 'INVx4',
    'NAND2x1', 'NOR2x1',
    'AOI21x1', 'OAI21x1',
    'XOR2x1', 'XOR2x2',
    'XNOR2x1', 'XNOR2x2',
    'MUX21x1',
    'DFFx1',
]

for name in cell_names:
    gds_file = gds_dir / f'{name}.gds'
    if gds_file.exists():
        cell_lib = gdstk.read_gds(str(gds_file))
        for cell in cell_lib.cells:
            lib.add(cell)
        print(f'  Added: {name}')
    else:
        print(f'  MISSING: {name}')

out = gds_dir / 'asap5_stdcells.gds'
lib.write_gds(str(out))
print(f'Combined library: {out} ({out.stat().st_size} bytes, {len(lib.cells)} cells)')
