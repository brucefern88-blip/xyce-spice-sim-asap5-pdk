#!/usr/bin/env python3
"""Generate ASAP5 5nm XOR2x2 GDS layout using gdstk.

8T transmission-gate XOR, 4 fins per device (x2 drive strength).
Topology: INV_B (CPP1) + INV_A (CPP2) + TG1 (CPP3) + TG2 (CPP4)
  TG1: passes A when B=1 (N-gate=B, P-gate=BB)
  TG2: passes AB when B=0 (N-gate=BB, P-gate=B)

Cell: 176nm x 140nm (4 CPPs @ 44nm).
"""

import gdstk

lib = gdstk.Library(unit=1e-9, precision=1e-12)
cell = lib.new_cell("XOR2x2")

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

W = 176  # cell width (4 CPPs)
H = 140  # cell height

# --- 1. BOUNDARY ---
cell.add(gdstk.rectangle((0, 0), (W, H), layer=L_BOUND))

# --- 2. NWELL (PMOS region, top half) ---
cell.add(gdstk.rectangle((0, 65), (W, H), layer=L_NWELL))

# --- 3. FINS (4 per device for x2 strength) ---
nmos_fins = [19, 31, 43, 55]
pmos_fins = [85, 97, 109, 121]
for yc in nmos_fins + pmos_fins:
    cell.add(gdstk.rectangle((0, yc - 3), (W, yc + 3), layer=L_FIN))

# --- 4. ACTIVE ---
cell.add(gdstk.rectangle((0, 12), (W, 62), layer=L_ACTIVE))   # NMOS
cell.add(gdstk.rectangle((0, 78), (W, 128), layer=L_ACTIVE))  # PMOS

# --- 5. NSELECT / PSELECT ---
cell.add(gdstk.rectangle((0, 0), (W, 65), layer=L_NSEL))
cell.add(gdstk.rectangle((0, 65), (W, H), layer=L_PSEL))

# --- 6. POLY (4 gate stripes, 16nm wide) ---
# CPP1 center=22: INV_B gate
cell.add(gdstk.rectangle((14, 5), (30, 135), layer=L_POLY))
# CPP2 center=66: INV_A gate
cell.add(gdstk.rectangle((58, 5), (74, 135), layer=L_POLY))
# CPP3 center=110: TG1 (split gate: N=B, P=BB)
cell.add(gdstk.rectangle((102, 5), (118, 58), layer=L_POLY))   # NMOS half
cell.add(gdstk.rectangle((102, 72), (118, 135), layer=L_POLY)) # PMOS half
# CPP4 center=154: TG2 (split gate: N=BB, P=B)
cell.add(gdstk.rectangle((146, 5), (162, 58), layer=L_POLY))   # NMOS half
cell.add(gdstk.rectangle((146, 72), (162, 135), layer=L_POLY)) # PMOS half

# NMOS active: y=12-62, PMOS active: y=78-128
NY1, NY2 = 12, 62   # NMOS SDT y range
PY1, PY2 = 78, 128  # PMOS SDT y range

# --- 7. SDT (source/drain contacts between poly gates) ---
# SD0 (x=2-12): INV_B source  -> NMOS=VSS, PMOS=VDD
cell.add(gdstk.rectangle((2, NY1), (12, NY2), layer=L_SDT))
cell.add(gdstk.rectangle((2, PY1), (12, PY2), layer=L_SDT))
# SD1 (x=32-42): INV_B drain = BB
cell.add(gdstk.rectangle((32, NY1), (42, NY2), layer=L_SDT))
cell.add(gdstk.rectangle((32, PY1), (42, PY2), layer=L_SDT))
# SD2 (x=46-56): INV_A source -> NMOS=VSS, PMOS=VDD
cell.add(gdstk.rectangle((46, NY1), (56, NY2), layer=L_SDT))
cell.add(gdstk.rectangle((46, PY1), (56, PY2), layer=L_SDT))
# SD3 (x=76-86): INV_A drain = AB
cell.add(gdstk.rectangle((76, NY1), (86, NY2), layer=L_SDT))
cell.add(gdstk.rectangle((76, PY1), (86, PY2), layer=L_SDT))
# SD4 (x=90-100): TG1 source -> A (NMOS) / A (PMOS)
cell.add(gdstk.rectangle((90, NY1), (100, NY2), layer=L_SDT))
cell.add(gdstk.rectangle((90, PY1), (100, PY2), layer=L_SDT))
# SD5 (x=120-130): TG1 drain / TG2 source = Y
cell.add(gdstk.rectangle((120, NY1), (130, NY2), layer=L_SDT))
cell.add(gdstk.rectangle((120, PY1), (130, PY2), layer=L_SDT))
# SD6 (x=134-144): TG2 source = AB
cell.add(gdstk.rectangle((134, NY1), (144, NY2), layer=L_SDT))
cell.add(gdstk.rectangle((134, PY1), (144, PY2), layer=L_SDT))
# SD7 (x=164-174): TG2 drain = Y
cell.add(gdstk.rectangle((164, NY1), (174, NY2), layer=L_SDT))
cell.add(gdstk.rectangle((164, PY1), (174, PY2), layer=L_SDT))

# --- 8. COSD (same rectangles as SDT) ---
for x1, x2 in [(2,12),(32,42),(46,56),(76,86),(90,100),(120,130),(134,144),(164,174)]:
    cell.add(gdstk.rectangle((x1, NY1), (x2, NY2), layer=L_COSD))
    cell.add(gdstk.rectangle((x1, PY1), (x2, PY2), layer=L_COSD))

# --- 9. COG (gate contacts) ---
# INV_B and INV_A: full-height gate contact (connects N and P gate)
cell.add(gdstk.rectangle((14, 60), (30, 75), layer=L_COG))   # CPP1 = B
cell.add(gdstk.rectangle((58, 60), (74, 75), layer=L_COG))   # CPP2 = A
# TG1 split gate contacts (N-gate and P-gate are different signals)
cell.add(gdstk.rectangle((102, 50), (118, 58), layer=L_COG))  # TG1 NMOS gate = B
cell.add(gdstk.rectangle((102, 72), (118, 80), layer=L_COG))  # TG1 PMOS gate = BB
# TG2 split gate contacts
cell.add(gdstk.rectangle((146, 50), (162, 58), layer=L_COG))  # TG2 NMOS gate = BB
cell.add(gdstk.rectangle((146, 72), (162, 80), layer=L_COG))  # TG2 PMOS gate = B

# --- 10. M1 (Metal1 routing) ---
# Power rails
cell.add(gdstk.rectangle((0, 0), (W, 14), layer=L_M1))       # VSS rail
cell.add(gdstk.rectangle((0, 126), (W, H), layer=L_M1))      # VDD rail

# VSS source straps: SD0 NMOS + SD2 NMOS to VSS rail
cell.add(gdstk.rectangle((2, 0), (12, NY1), layer=L_M1))      # SD0 NMOS -> VSS
cell.add(gdstk.rectangle((46, 0), (56, NY1), layer=L_M1))     # SD2 NMOS -> VSS

# VDD source straps: SD0 PMOS + SD2 PMOS to VDD rail
cell.add(gdstk.rectangle((2, PY2), (12, H), layer=L_M1))      # SD0 PMOS -> VDD
cell.add(gdstk.rectangle((46, PY2), (56, H), layer=L_M1))     # SD2 PMOS -> VDD

# BB internal node: connect SD1 NMOS to SD1 PMOS vertically
cell.add(gdstk.rectangle((34, NY2), (40, PY1), layer=L_M1))   # BB strap

# AB internal node: connect SD3 NMOS to SD3 PMOS vertically
cell.add(gdstk.rectangle((78, NY2), (84, PY1), layer=L_M1))   # AB strap

# A signal: connect SD4 NMOS to SD4 PMOS vertically (TG1 input)
cell.add(gdstk.rectangle((92, NY2), (98, PY1), layer=L_M1))   # A strap at TG1

# AB signal at TG2: connect SD6 NMOS to SD6 PMOS vertically
cell.add(gdstk.rectangle((136, NY2), (142, PY1), layer=L_M1)) # AB strap at TG2

# Y output: connect SD5 and SD7 (both TG outputs)
# SD5 NMOS-PMOS vertical strap
cell.add(gdstk.rectangle((122, NY2), (128, PY1), layer=L_M1)) # Y strap at SD5
# SD7 NMOS-PMOS vertical strap
cell.add(gdstk.rectangle((166, NY2), (172, PY1), layer=L_M1)) # Y strap at SD7

# COG to M1 straps for inverter gates
cell.add(gdstk.rectangle((14, 60), (30, 75), layer=L_M1))     # gate B contact pad
cell.add(gdstk.rectangle((58, 60), (74, 75), layer=L_M1))     # gate A contact pad

# TG split gate COG to M1
cell.add(gdstk.rectangle((102, 50), (118, 58), layer=L_M1))   # TG1 N-gate pad
cell.add(gdstk.rectangle((102, 72), (118, 80), layer=L_M1))   # TG1 P-gate pad
cell.add(gdstk.rectangle((146, 50), (162, 58), layer=L_M1))   # TG2 N-gate pad
cell.add(gdstk.rectangle((146, 72), (162, 80), layer=L_M1))   # TG2 P-gate pad

# --- 11. V1 (via1: M1 to M2) ---
# B signal routing: INV_B gate (CPP1) -> TG1 N-gate (CPP3)
cell.add(gdstk.rectangle((20, 62), (26, 68), layer=L_V1))     # on INV_B COG
cell.add(gdstk.rectangle((106, 52), (112, 58), layer=L_V1))   # on TG1 N-gate COG
# BB signal routing: BB node (SD1) -> TG1 P-gate (CPP3) -> TG2 N-gate (CPP4)
cell.add(gdstk.rectangle((34, 72), (40, 78), layer=L_V1))     # on BB M1 strap
cell.add(gdstk.rectangle((106, 72), (112, 78), layer=L_V1))   # on TG1 P-gate COG
cell.add(gdstk.rectangle((150, 52), (156, 58), layer=L_V1))   # on TG2 N-gate COG
# A signal routing: INV_A gate (CPP2) -> TG1 source (SD4)
cell.add(gdstk.rectangle((64, 62), (70, 68), layer=L_V1))     # on INV_A COG
cell.add(gdstk.rectangle((92, 62), (98, 68), layer=L_V1))     # on A M1 strap at TG1
# AB signal routing: AB node (SD3) -> TG2 source (SD6)
cell.add(gdstk.rectangle((78, 62), (84, 68), layer=L_V1))     # on AB M1 strap
cell.add(gdstk.rectangle((136, 62), (142, 68), layer=L_V1))   # on AB M1 strap at TG2
# B to TG2 P-gate
cell.add(gdstk.rectangle((150, 72), (156, 78), layer=L_V1))   # on TG2 P-gate COG
# Y output via
cell.add(gdstk.rectangle((122, 62), (128, 68), layer=L_V1))   # Y at SD5
cell.add(gdstk.rectangle((166, 82), (172, 88), layer=L_V1))   # Y at SD7

# --- 12. M2 (Metal2 routing) ---
# B signal: INV_B gate -> TG1 N-gate (horizontal run)
cell.add(gdstk.rectangle((20, 52), (112, 58), layer=L_M2))
# BB signal: SD1 -> TG1 P-gate -> TG2 N-gate
cell.add(gdstk.rectangle((34, 72), (156, 78), layer=L_M2))
# A signal: INV_A gate -> TG1 SD4
cell.add(gdstk.rectangle((64, 62), (98, 68), layer=L_M2))
# AB signal: SD3 -> TG2 SD6
cell.add(gdstk.rectangle((78, 62), (142, 68), layer=L_M2))
# B to TG2 P-gate: needs a separate M2 run
cell.add(gdstk.rectangle((20, 62), (26, 68), layer=L_M2))     # short stub up from B via
cell.add(gdstk.rectangle((150, 72), (156, 78), layer=L_M2))   # included in BB run above
# Y output: connect SD5 and SD7 via M2
cell.add(gdstk.rectangle((122, 82), (172, 88), layer=L_M2))

# --- 13. LVT implant (full cell) ---
cell.add(gdstk.rectangle((0, 0), (W, H), layer=L_LVT))

# --- 14. TEXT labels ---
cell.add(gdstk.Label("A",   (66, 70),  layer=L_TEXT))
cell.add(gdstk.Label("B",   (22, 70),  layer=L_TEXT))
cell.add(gdstk.Label("Y",   (147, 85), layer=L_TEXT))
cell.add(gdstk.Label("VDD", (88, 133), layer=L_TEXT))
cell.add(gdstk.Label("VSS", (88, 7),   layer=L_TEXT))

# --- Write GDS ---
outpath = "/Users/bruce/CLAUDE/asap5/charflow/gds/XOR2x2.gds"
lib.write_gds(outpath)
print(f"XOR2x2.gds written to {outpath}")
