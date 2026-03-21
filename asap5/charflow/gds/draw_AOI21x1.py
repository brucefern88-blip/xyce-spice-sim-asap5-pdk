#!/usr/bin/env python3
"""Generate ASAP5 5nm AOI21x1 GDS layout using gdstk.

AOI21x1: Y = !((A0 & A1) | B) -- 6 transistors (3 NMOS + 3 PMOS)

Cell: 132nm x 140nm (3 CPPs @ 44nm, cell height 140nm)
Gates: A0 at x=22, A1 at x=66, B at x=110

NMOS pulldown (series A0-A1 + parallel B):
  mn_a0: D=Y,     G=A0, S=mid_n   (A0 series top)
  mn_a1: D=mid_n, G=A1, S=VSS     (A1 series bottom)
  mn_b:  D=Y,     G=B,  S=VSS     (B parallel)

  Diffusion (L→R): Y | A0 | mid_n | A1 | VSS | B | Y
  S/D[0]=Y, S/D[1]=mid_n, S/D[2]=VSS, S/D[3]=Y
  Y at S/D[0] and S/D[3] connected via M2 horizontal strap.

PMOS pullup (parallel A0-A1 then series B):
  mp_a0: D=mid_p, G=A0, S=VDD     (A0 parallel)
  mp_a1: D=mid_p, G=A1, S=VDD     (A1 parallel)
  mp_b:  D=Y,     G=B,  S=mid_p   (B series)

  Diffusion (L→R): mid_p | A0 | VDD | A1 | mid_p | B | Y
  S/D[0]=mid_p, S/D[1]=VDD, S/D[2]=mid_p, S/D[3]=Y
  mid_p at S/D[0] and S/D[2] connected via M2 horizontal strap.
"""

import gdstk

lib = gdstk.Library(unit=1e-9, precision=1e-12)
cell = lib.new_cell("AOI21x1")

# --- Layer definitions (GDS#, datatype=0) ---
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

# --- Geometry constants ---
CELL_W   = 132          # 3 CPPs x 44nm
CELL_H   = 140
CPP      = 44
POLY_W   = 16           # gate width
FIN_H    = 6            # fin thickness
NWELL_Y  = 65           # NMOS/PMOS boundary
NMOS_FINS = [25, 49]    # NMOS fin y-centers
PMOS_FINS = [91, 115]   # PMOS fin y-centers
ACTIVE_N  = (18, 56)    # NMOS active y-range
ACTIVE_P  = (84, 122)   # PMOS active y-range

# Gate x-centers
XA0 = 22
XA1 = 66
XB  = 110

# S/D contact regions (between/outside gates, 10nm wide centered in gap)
# Gap between gate edge and next gate edge = CPP - POLY_W = 28nm
# Contact x-ranges (leave 2nm to gate edge)
SD_X = [
    (2, 12),       # S/D[0]: left of A0
    (32, 56),      # S/D[1]: between A0 and A1 (spans full gap)
    (76, 100),     # S/D[2]: between A1 and B
    (120, 130),    # S/D[3]: right of B
]

# --- 1. BOUNDARY ---
cell.add(gdstk.rectangle((0, 0), (CELL_W, CELL_H), layer=L_BOUND))

# --- 2. NWELL (PMOS region, top half) ---
cell.add(gdstk.rectangle((0, NWELL_Y), (CELL_W, CELL_H), layer=L_NWELL))

# --- 3. FIN (horizontal nanosheets, 6nm tall, full cell width) ---
for yc in NMOS_FINS + PMOS_FINS:
    cell.add(gdstk.rectangle((0, yc - FIN_H // 2), (CELL_W, yc + FIN_H // 2),
                             layer=L_FIN))

# --- 4. ACTIVE ---
cell.add(gdstk.rectangle((0, ACTIVE_N[0]), (CELL_W, ACTIVE_N[1]), layer=L_ACTIVE))
cell.add(gdstk.rectangle((0, ACTIVE_P[0]), (CELL_W, ACTIVE_P[1]), layer=L_ACTIVE))

# --- 5. NSELECT / PSELECT ---
cell.add(gdstk.rectangle((0, 0), (CELL_W, NWELL_Y), layer=L_NSEL))
cell.add(gdstk.rectangle((0, NWELL_Y), (CELL_W, CELL_H), layer=L_PSEL))

# --- 6. POLY (3 gate stripes, 16nm wide, spanning both active regions) ---
for xc in [XA0, XA1, XB]:
    cell.add(gdstk.rectangle((xc - POLY_W // 2, 5), (xc + POLY_W // 2, 135),
                             layer=L_POLY))

# --- 7. SDT (source/drain trench contacts on active regions) ---
for (x0, x1) in SD_X:
    cell.add(gdstk.rectangle((x0, ACTIVE_N[0]), (x1, ACTIVE_N[1]), layer=L_SDT))
    cell.add(gdstk.rectangle((x0, ACTIVE_P[0]), (x1, ACTIVE_P[1]), layer=L_SDT))

# --- 8. COSD (co-drawn with SDT) ---
for (x0, x1) in SD_X:
    cell.add(gdstk.rectangle((x0, ACTIVE_N[0]), (x1, ACTIVE_N[1]), layer=L_COSD))
    cell.add(gdstk.rectangle((x0, ACTIVE_P[0]), (x1, ACTIVE_P[1]), layer=L_COSD))

# --- 9. COG (gate contacts in the gap between NMOS and PMOS active) ---
# Each gate needs a COG in the mid-gap region (y=60..75)
for xc in [XA0, XA1, XB]:
    cell.add(gdstk.rectangle((xc - POLY_W // 2, 60), (xc + POLY_W // 2, 75),
                             layer=L_COG))

# --- 10. M1 (Metal1 routing -- vertical preferred) ---
# Power rails (horizontal, full width)
cell.add(gdstk.rectangle((0, 0), (CELL_W, 14), layer=L_M1))      # VSS rail
cell.add(gdstk.rectangle((0, 126), (CELL_W, 140), layer=L_M1))   # VDD rail

# NMOS S/D[2] = VSS: vertical strap down to VSS rail
cell.add(gdstk.rectangle((76, 0), (100, ACTIVE_N[0]), layer=L_M1))

# NMOS S/D[3] = Y: vertical strap (stays local, connects up to PMOS Y via M1)
# PMOS S/D[3] = Y: vertical strap connecting NMOS Y to PMOS Y
cell.add(gdstk.rectangle((120, ACTIVE_N[0]), (130, ACTIVE_P[1]), layer=L_M1))

# PMOS S/D[1] = VDD: vertical strap up to VDD rail
cell.add(gdstk.rectangle((32, ACTIVE_P[1]), (56, CELL_H), layer=L_M1))

# Gate A0 input: M1 vertical from COG to mid-cell
cell.add(gdstk.rectangle((14, 60), (30, 75), layer=L_M1))

# Gate A1 input: M1 vertical from COG
cell.add(gdstk.rectangle((58, 60), (74, 75), layer=L_M1))

# Gate B input: M1 vertical from COG
cell.add(gdstk.rectangle((102, 60), (118, 75), layer=L_M1))

# --- 11. M2 (Metal2 routing -- horizontal preferred) ---
# M2 strap: NMOS Y -- connect S/D[0] (x=2..12) to S/D[3] (x=120..130)
# Route at y just below NMOS active (y=10..16 conflicts with VSS rail)
# Use y within NMOS active region bottom
M2_Y_N = (12, 20)   # just above VSS rail, below NMOS active center
cell.add(gdstk.rectangle((2, M2_Y_N[0]), (130, M2_Y_N[1]), layer=L_M2))

# Via V1: S/D[0] NMOS to M2 Y strap
cell.add(gdstk.rectangle((2, M2_Y_N[0]), (12, M2_Y_N[1]), layer=L_V1))
# Via V1: S/D[3] NMOS to M2 Y strap
cell.add(gdstk.rectangle((120, M2_Y_N[0]), (130, M2_Y_N[1]), layer=L_V1))

# M2 strap: PMOS mid_p -- connect S/D[0] (x=2..12) to S/D[2] (x=76..100)
M2_Y_P = (122, 130)   # just below VDD rail, above PMOS active
cell.add(gdstk.rectangle((2, M2_Y_P[0]), (100, M2_Y_P[1]), layer=L_M2))

# Via V1: S/D[0] PMOS to M2 mid_p strap
cell.add(gdstk.rectangle((2, M2_Y_P[0]), (12, M2_Y_P[1]), layer=L_V1))
# Via V1: S/D[2] PMOS to M2 mid_p strap
cell.add(gdstk.rectangle((76, M2_Y_P[0]), (100, M2_Y_P[1]), layer=L_V1))

# --- 12. LVT implant (full cell) ---
cell.add(gdstk.rectangle((0, 0), (CELL_W, CELL_H), layer=L_LVT))

# --- 13. TEXT labels ---
cell.add(gdstk.Label("A0",  (XA0, 67), layer=L_TEXT))
cell.add(gdstk.Label("A1",  (XA1, 67), layer=L_TEXT))
cell.add(gdstk.Label("B",   (XB,  67), layer=L_TEXT))
cell.add(gdstk.Label("Y",   (125, 70), layer=L_TEXT))
cell.add(gdstk.Label("VDD", (66, 133), layer=L_TEXT))
cell.add(gdstk.Label("VSS", (66, 7),   layer=L_TEXT))

# --- Write GDS ---
outpath = "/Users/bruce/CLAUDE/asap5/charflow/gds/AOI21x1.gds"
lib.write_gds(outpath)
print(f"AOI21x1.gds written to {outpath}")
print(f"  Cell: {CELL_W}nm x {CELL_H}nm  (3 CPPs)")
print(f"  Gates: A0@x={XA0}, A1@x={XA1}, B@x={XB}")
print(f"  6 transistors: 3 NMOS (fins y={NMOS_FINS}) + 3 PMOS (fins y={PMOS_FINS})")
print(f"  M2 straps: NMOS Y (S/D[0]↔S/D[3]), PMOS mid_p (S/D[0]↔S/D[2])")
