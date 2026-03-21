#!/usr/bin/env python3
"""Generate ASAP5 5nm OAI21x1 GDS layout using gdstk.

OAI21x1: Y = !((A0 | A1) & B) — 6T, dual of AOI21
Cell: 132nm x 140nm (3 CPPs, CPP=44nm)

Gate order (dual Euler path): A0(x=22), A1(x=66), B(x=110)

NMOS pull-down: (A0 || A1) series B
  SD(7)=mid_n, A0, SD(44)=VSS, A1, SD(88)=mid_n, B, SD(125)=Y
  mid_n(7) and mid_n(88) connected via M1 strap

PMOS pull-up: (A0 series A1) || B
  SD(7)=VDD, A0, SD(44)=mid_p, A1, SD(88)=Y_p, B, SD(125)=VDD
"""

import gdstk

lib = gdstk.Library(unit=1e-9, precision=1e-12)
cell = lib.new_cell("OAI21x1")

# --- Layer definitions ---
L_NWELL  = 1
L_FIN    = 2
L_BOUND  = 5
L_POLY   = 7
L_ACTIVE = 11
L_NSEL   = 12
L_PSEL   = 13
L_M1     = 19
L_M2     = 20
L_V1     = 21
L_COG    = 87
L_SDT    = 88
L_COSD   = 89
L_LVT    = 98
L_TEXT   = 101

# --- Cell dimensions ---
CELL_W = 132   # 3 CPPs x 44nm
CELL_H = 140
HALF_H = 65    # NMOS/PMOS boundary

# Gate x-centers (CPP = 44nm, centered in each CPP)
GX_A0 = 22
GX_A1 = 66
GX_B  = 110

# SD contact x-centers (between/outside gates)
SD0 = 7     # left of A0
SD1 = 44    # between A0 and A1
SD2 = 88    # between A1 and B
SD3 = 125   # right of B

# Fin y-centers
NFIN = [25, 49]        # NMOS fins
PFIN = [91, 115]       # PMOS fins

# Poly width
PW = 16   # 8nm each side of center

# SD/COSD contact width
SDW = 10  # 5nm each side of center

# --- 1. BOUNDARY ---
cell.add(gdstk.rectangle((0, 0), (CELL_W, CELL_H), layer=L_BOUND))

# --- 2. NWELL (PMOS region, top half) ---
cell.add(gdstk.rectangle((0, HALF_H), (CELL_W, CELL_H), layer=L_NWELL))

# --- 3. FINS (horizontal nanosheets, 6nm tall, full cell width) ---
for yc in NFIN + PFIN:
    cell.add(gdstk.rectangle((0, yc - 3), (CELL_W, yc + 3), layer=L_FIN))

# --- 4. ACTIVE (continuous diffusion across all 3 gates) ---
cell.add(gdstk.rectangle((0, 18), (CELL_W, 56), layer=L_ACTIVE))    # NMOS
cell.add(gdstk.rectangle((0, 84), (CELL_W, 122), layer=L_ACTIVE))   # PMOS

# --- 5. NSELECT / PSELECT ---
cell.add(gdstk.rectangle((0, 0), (CELL_W, HALF_H), layer=L_NSEL))
cell.add(gdstk.rectangle((0, HALF_H), (CELL_W, CELL_H), layer=L_PSEL))

# --- 6. POLY (3 gate stripes, 16nm wide, spanning both NMOS and PMOS) ---
for gx in [GX_A0, GX_A1, GX_B]:
    cell.add(gdstk.rectangle((gx - 8, 5), (gx + 8, 135), layer=L_POLY))

# --- 7. SDT (source/drain trench contacts at each SD position) ---
# NMOS SD contacts
for sx in [SD0, SD1, SD2, SD3]:
    cell.add(gdstk.rectangle((sx - 5, 18), (sx + 5, 56), layer=L_SDT))
# PMOS SD contacts
for sx in [SD0, SD1, SD2, SD3]:
    cell.add(gdstk.rectangle((sx - 5, 84), (sx + 5, 122), layer=L_SDT))

# --- 8. COSD (co-drawn with SDT) ---
for sx in [SD0, SD1, SD2, SD3]:
    cell.add(gdstk.rectangle((sx - 5, 18), (sx + 5, 56), layer=L_COSD))
for sx in [SD0, SD1, SD2, SD3]:
    cell.add(gdstk.rectangle((sx - 5, 84), (sx + 5, 122), layer=L_COSD))

# --- 9. COG (gate contacts — one per gate, in the gap between NMOS/PMOS) ---
for gx in [GX_A0, GX_A1, GX_B]:
    cell.add(gdstk.rectangle((gx - 8, 60), (gx + 8, 75), layer=L_COG))

# --- 10. M1 routing ---
# VSS rail (bottom)
cell.add(gdstk.rectangle((0, 0), (CELL_W, 14), layer=L_M1))
# VDD rail (top)
cell.add(gdstk.rectangle((0, 126), (CELL_W, 140), layer=L_M1))

# NMOS net connections:
#   SD0(7)=mid_n, SD1(44)=VSS, SD2(88)=mid_n, SD3(125)=Y_n

# VSS: NMOS SD1(44) down to VSS rail
cell.add(gdstk.rectangle((SD1 - 5, 0), (SD1 + 5, 18), layer=L_M1))

# mid_n strap: connect SD0(7) to SD2(88) via horizontal M1 in NMOS region
# Route through the lower part of NMOS, below the fins
cell.add(gdstk.rectangle((SD0 - 5, 14), (SD0 + 5, 22), layer=L_M1))   # SD0 stub down
cell.add(gdstk.rectangle((SD2 - 5, 14), (SD2 + 5, 22), layer=L_M1))   # SD2 stub down
cell.add(gdstk.rectangle((SD0 - 5, 14), (SD2 + 5, 22), layer=L_M1))   # horizontal strap

# PMOS net connections:
#   SD0(7)=VDD, SD1(44)=mid_p, SD2(88)=Y_p, SD3(125)=VDD

# VDD: PMOS SD0(7) up to VDD rail
cell.add(gdstk.rectangle((SD0 - 5, 122), (SD0 + 5, 140), layer=L_M1))
# VDD: PMOS SD3(125) up to VDD rail
cell.add(gdstk.rectangle((SD3 - 5, 122), (SD3 + 5, 140), layer=L_M1))

# Output Y: connect NMOS Y at SD3(125) to PMOS Y at SD2(88)
# Vertical M1 strap on the right side, through the gap
cell.add(gdstk.rectangle((SD3 - 5, 56), (SD3 + 5, 70), layer=L_M1))   # NMOS Y up
cell.add(gdstk.rectangle((SD2 - 5, 70), (SD2 + 5, 84), layer=L_M1))   # PMOS Y down
cell.add(gdstk.rectangle((SD2 - 5, 65), (SD3 + 5, 75), layer=L_M1))   # horizontal bridge

# --- 11. LVT implant (full cell) ---
cell.add(gdstk.rectangle((0, 0), (CELL_W, CELL_H), layer=L_LVT))

# --- 12. TEXT labels ---
cell.add(gdstk.Label("A0",  (GX_A0, 70), layer=L_TEXT))
cell.add(gdstk.Label("A1",  (GX_A1, 70), layer=L_TEXT))
cell.add(gdstk.Label("B",   (GX_B, 70),  layer=L_TEXT))
cell.add(gdstk.Label("Y",   (SD3, 65),   layer=L_TEXT))
cell.add(gdstk.Label("VDD", (66, 133),   layer=L_TEXT))
cell.add(gdstk.Label("VSS", (66, 7),     layer=L_TEXT))

# --- Write GDS ---
outpath = "/Users/bruce/CLAUDE/asap5/charflow/gds/OAI21x1.gds"
lib.write_gds(outpath)
print(f"OAI21x1.gds written to {outpath}")
print(f"  Cell: {CELL_W}nm x {CELL_H}nm (3 CPPs)")
print(f"  6T: NMOS(A0||A1 series B), PMOS(A0 series A1 || B)")
print(f"  Gates: A0@x={GX_A0}, A1@x={GX_A1}, B@x={GX_B}")
print(f"  Layers: {len(cell.polygons)} polygons, {len(cell.labels)} labels")
