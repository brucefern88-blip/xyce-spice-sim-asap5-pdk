#!/usr/bin/env python3
"""Generate PPA summary table from individual cell PPA reports."""
import re
from pathlib import Path

ppa_dir = Path(__file__).parent
cells = ['INVx1','INVx2','INVx4','NAND2x1','NOR2x1','AOI21x1','OAI21x1',
         'XOR2x1','XOR2x2','XNOR2x1','XNOR2x2','MUX21x1','DFFx1']

print("="*90)
print(f"{'Cell':<12} {'Area(nm²)':>10} {'CPPs':>5} {'T#':>3} "
      f"{'tpd@0.7V':>10} {'E@0.7V':>10} "
      f"{'tpd@0.4V':>10} {'E@0.4V':>10}")
print("="*90)

for cell in cells:
    ppa_file = ppa_dir / f'{cell}_ppa.txt'
    if not ppa_file.exists():
        print(f"{cell:<12} {'MISSING':>10}")
        continue
    text = ppa_file.read_text()

    # Parse area (e.g. "= 6160 nm^2")
    area_m = re.search(r'=\s*([\d,]+)\s*nm', text)
    area = area_m.group(1).replace(',', '') if area_m else '?'

    # Parse CPPs (e.g. "(1 CPP)" or "(2 CPPs)")
    cpp_m = re.search(r'(\d+)\s*CPPs?\b', text)
    cpps = cpp_m.group(1) if cpp_m else '?'

    # Parse transistor count (e.g. "2T" or "8T")
    t_m = re.search(r'(\d+)T\s', text)
    tcount = t_m.group(1) if t_m else '?'

    # Parse tpd and energy for both voltage sections
    tpd_07 = tpd_04 = e_07 = e_04 = '---'

    lines = text.split('\n')
    section = None
    for line in lines:
        # Detect section headers: "=== ... @ 0.7V ..." or "=== ... @ 0.40V ..."
        hdr = re.search(r'@\s*(0\.7|0\.4)', line)
        if hdr:
            section = '07' if hdr.group(1) == '0.7' else '04'

        # tpd line: "tpd:    14.1 ps"
        tpd_m = re.match(r'\s*tpd:\s+(.+)', line)
        if tpd_m:
            val = tpd_m.group(1).strip()
            if section == '07': tpd_07 = val
            elif section == '04': tpd_04 = val

        # Energy line: "Energy/cycle:   592.3 aJ (...)"
        e_m = re.match(r'\s*Energy/cycle:\s+(.+?)(?:\s*\(|$)', line)
        if e_m:
            val = e_m.group(1).strip()
            if section == '07': e_07 = val
            elif section == '04': e_04 = val

    print(f"{cell:<12} {area:>10} {cpps:>5} {tcount:>3} "
          f"{tpd_07:>10} {e_07:>10} "
          f"{tpd_04:>10} {e_04:>10}")

print("="*90)
print("Conditions: TT corner, 1fF load, 5ps edges")
print("0.7V = LVT calibrated BSIM-CMG, 0.4V = SLVT calibrated BSIM-CMG")
