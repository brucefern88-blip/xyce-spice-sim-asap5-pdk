#!/usr/bin/env python3
"""Generate ASAP5 5nm XOR2x1 GDS layout using gdstk.

XOR2x1: Y = A ^ B — 8T (2 inverters + 2 transmission gates)
Cell: 176nm x 140nm (4 CPPs, CPP=44nm)

Structure:
  CPP1 (x=22): INV_B — generates BB=~B
  CPP2 (x=66): INV_A — generates AB=~A
  CPP3 (x=110): TG1 — N-gate=B, P-gate=BB, passes A to Y
  CPP4 (x=154): TG2 — N-gate=BB, P-gate=B, passes AB(~A) to Y

Each gate has 2 NMOS fins (y=25,49) and 2 PMOS fins (y=91,115).
TG gates use GCUT to split poly for independent N/P gate control.
M2 cross-routes B and BB to complementary TG gate halves.

SD region net assignments (left to right):
  SD0 (2..12):    INV_B source  → VDD/VSS
  SD1 (34..56):   left=BB (INV_B drain), right=VDD/VSS (INV_A source)
  SD2 (78..100):  left=AB/~A (INV_A drain), right=A (TG1 source)
  SD3 (122..144): left=Y (TG1 drain), right=AB feed (TG2 source)
  SD4 (164..174): Y (TG2 drain)
"""

import gdstk

lib = gdstk.Library(unit=1e-9, precision=1e-12)
cell = lib.new_cell("XOR2x1")

# --- Layer definitions ---
L_NWELL  = 1
L_FIN    = 2
L_BOUND  = 5
L_POLY   = 7
L_GCUT   = 10
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
W, H = 176, 140
CPP1, CPP2, CPP3, CPP4 = 22, 66, 110, 154
NMOS_BOT, NMOS_TOP = 18, 56
PMOS_BOT, PMOS_TOP = 84, 122
RAIL_H = 14
SD = [(2, 12), (34, 56), (78, 100), (122, 144), (164, 174)]

# ============================================================
# Physical layers
# ============================================================
cell.add(gdstk.rectangle((0, 0), (W, H), layer=L_BOUND))
cell.add(gdstk.rectangle((0, 65), (W, H), layer=L_NWELL))

for yc in [25, 49, 91, 115]:
    cell.add(gdstk.rectangle((0, yc - 3), (W, yc + 3), layer=L_FIN))

cell.add(gdstk.rectangle((0, NMOS_BOT), (W, NMOS_TOP), layer=L_ACTIVE))
cell.add(gdstk.rectangle((0, PMOS_BOT), (W, PMOS_TOP), layer=L_ACTIVE))

cell.add(gdstk.rectangle((0, 0),  (W, 65), layer=L_NSEL))
cell.add(gdstk.rectangle((0, 65), (W, H),  layer=L_PSEL))
cell.add(gdstk.rectangle((0, 0),  (W, H),  layer=L_LVT))

# ============================================================
# POLY gates — 4 stripes, GCUT splits TG gates
# ============================================================
for xc in [CPP1, CPP2, CPP3, CPP4]:
    cell.add(gdstk.rectangle((xc - 8, 5), (xc + 8, 135), layer=L_POLY))

for xc in [CPP3, CPP4]:
    cell.add(gdstk.rectangle((xc - 8, 60), (xc + 8, 70), layer=L_GCUT))

# ============================================================
# SDT + COSD (source/drain contacts)
# ============================================================
for xl, xr in SD:
    for yb, yt in [(NMOS_BOT, NMOS_TOP), (PMOS_BOT, PMOS_TOP)]:
        cell.add(gdstk.rectangle((xl, yb), (xr, yt), layer=L_SDT))
        cell.add(gdstk.rectangle((xl, yb), (xr, yt), layer=L_COSD))

# ============================================================
# COG — gate contacts
# ============================================================
# INV gates (CPP1, CPP2): unified COG in mid-gap
for xc in [CPP1, CPP2]:
    cell.add(gdstk.rectangle((xc - 8, 60), (xc + 8, 75), layer=L_COG))

# TG gates (CPP3, CPP4): split N-half and P-half COG
for xc in [CPP3, CPP4]:
    cell.add(gdstk.rectangle((xc - 6, 56), (xc + 6, 60), layer=L_COG))
    cell.add(gdstk.rectangle((xc - 6, 70), (xc + 6, 78), layer=L_COG))

# ============================================================
# M1 power rails
# ============================================================
cell.add(gdstk.rectangle((0, 0), (W, RAIL_H), layer=L_M1))
cell.add(gdstk.rectangle((0, H - RAIL_H), (W, H), layer=L_M1))

# ============================================================
# M1 SD routing
# ============================================================
# SD0: INV_B source → rails
cell.add(gdstk.rectangle((2, 0),        (12, NMOS_BOT), layer=L_M1))
cell.add(gdstk.rectangle((2, PMOS_TOP), (12, H),        layer=L_M1))

# SD1 left (34..44): BB strap (INV_B drain, N↔P)
cell.add(gdstk.rectangle((34, NMOS_TOP), (44, PMOS_BOT), layer=L_M1))
# SD1 right (46..56): INV_A source → rails
cell.add(gdstk.rectangle((46, 0),        (56, NMOS_BOT), layer=L_M1))
cell.add(gdstk.rectangle((46, PMOS_TOP), (56, H),        layer=L_M1))

# SD2 left (78..88): AB strap (INV_A drain = ~A)
cell.add(gdstk.rectangle((78, NMOS_TOP), (88, PMOS_BOT), layer=L_M1))
# SD2 right (90..100): A strap (TG1 source)
cell.add(gdstk.rectangle((90, NMOS_TOP), (100, PMOS_BOT), layer=L_M1))

# SD3 left (122..132): Y strap (TG1 drain)
cell.add(gdstk.rectangle((122, NMOS_TOP), (132, PMOS_BOT), layer=L_M1))
# SD3 right (134..144): AB feed (TG2 source)
cell.add(gdstk.rectangle((134, NMOS_TOP), (144, PMOS_BOT), layer=L_M1))

# SD4 (164..174): Y strap (TG2 drain)
cell.add(gdstk.rectangle((164, NMOS_TOP), (174, PMOS_BOT), layer=L_M1))

# Y bus — horizontal M1 connecting TG1 drain (SD3L) and TG2 drain (SD4)
cell.add(gdstk.rectangle((122, 58), (174, 64), layer=L_M1))

# AB bus — horizontal M1 connecting INV_A drain (SD2L) and TG2 source (SD3R)
cell.add(gdstk.rectangle((78, 74), (144, 80), layer=L_M1))

# ============================================================
# M1 gate-input stubs (COG → M1)
# ============================================================
# B input at CPP1 COG
cell.add(gdstk.rectangle((14, 60), (30, 75), layer=L_M1))
# A input at CPP2 COG
cell.add(gdstk.rectangle((58, 60), (74, 75), layer=L_M1))

# ============================================================
# M1 stubs for TG gate connections (bridge COG to M2 vias)
# ============================================================
# CPP3 N-gate=B: stub from COG (56..60) down to M2 B-track (46..52)
cell.add(gdstk.rectangle((104, 46), (112, 60), layer=L_M1))
# CPP3 P-gate=BB: stub from COG (70..78) up to M2 BB-track (82..88)
cell.add(gdstk.rectangle((104, 70), (112, 88), layer=L_M1))
# CPP4 N-gate=BB: stub from COG (56..60) up to M2 BB-track (82..88)
cell.add(gdstk.rectangle((152, 56), (160, 88), layer=L_M1))
# CPP4 P-gate=B: stub from COG (70..78) down to M2 B-track (46..52)
cell.add(gdstk.rectangle((148, 46), (152, 78), layer=L_M1))
# B input: stub from CPP1 COG (60..75) down to M2 B-track (46..52)
cell.add(gdstk.rectangle((18, 46), (26, 60), layer=L_M1))

# ============================================================
# M2 cross-routing (B and BB to TG split gates)
# ============================================================
# B track (y=46..52): CPP1 → CPP3 N-gate → CPP4 P-gate
cell.add(gdstk.rectangle((18, 46), (152, 52), layer=L_M2))
# BB track (y=82..88): SD1 BB → CPP3 P-gate → CPP4 N-gate
cell.add(gdstk.rectangle((36, 82), (160, 88), layer=L_M2))

# ============================================================
# V1 vias (M1 ↔ M2)
# ============================================================
# B signal vias
cell.add(gdstk.rectangle((18, 46), (26, 52), layer=L_V1))    # B @ CPP1
cell.add(gdstk.rectangle((104, 46), (112, 52), layer=L_V1))  # B @ CPP3 Ngate
cell.add(gdstk.rectangle((148, 46), (152, 52), layer=L_V1))  # B @ CPP4 Pgate

# BB signal vias
cell.add(gdstk.rectangle((36, 82), (44, 88), layer=L_V1))    # BB @ SD1
cell.add(gdstk.rectangle((104, 82), (112, 88), layer=L_V1))  # BB @ CPP3 Pgate
cell.add(gdstk.rectangle((152, 82), (160, 88), layer=L_V1))  # BB @ CPP4 Ngate

# ============================================================
# TEXT labels
# ============================================================
cell.add(gdstk.Label("A",   (95, 70),  layer=L_TEXT))
cell.add(gdstk.Label("B",   (22, 70),  layer=L_TEXT))
cell.add(gdstk.Label("Y",   (148, 62), layer=L_TEXT))
cell.add(gdstk.Label("VDD", (88, 133), layer=L_TEXT))
cell.add(gdstk.Label("VSS", (88, 7),   layer=L_TEXT))

# ============================================================
# Write GDS
# ============================================================
outpath = "/Users/bruce/CLAUDE/asap5/charflow/gds/XOR2x1.gds"
lib.write_gds(outpath)
print(f"XOR2x1.gds written to {outpath}")
print(f"  Cell: {cell.name}, {W}nm x {H}nm, 4 CPPs")
print(f"  8T: INV_B(2T) + INV_A(2T) + TG1(2T) + TG2(2T)")
print(f"  GCUT splits TG poly for independent N/P gate control")
print(f"  M2 cross-routes B/BB to complementary TG gate halves")
print(f"  Layers: NWELL FIN BOUND POLY GCUT ACTIVE NSEL PSEL")
print(f"          M1 M2 V1 SDT COSD COG LVT TEXT")
