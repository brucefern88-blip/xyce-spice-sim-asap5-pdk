#!/usr/bin/env python3
"""Generate ASAP5 5nm MUX21x1 GDS layout using gdstk.

8T MUX: Y = ~(S ? D1 : D0) — inverted-output buffered transmission-gate mux.
  CPP1 (x=22):  INV_S  — generates SB = ~S
  CPP2 (x=66):  TG0    — passes D0 when S=0 (N-gate=SB, P-gate=S)
  CPP3 (x=110): TG1    — passes D1 when S=1 (N-gate=S, P-gate=SB)
  CPP4 (x=154): INV_OUT — buffers merged TG node M, drives Y = ~M

Cell: 176nm x 140nm (4 CPPs @ 44nm pitch).
2 fins per device: NMOS at y=25,49; PMOS at y=91,115.

TG gates use split poly (NMOS/PMOS segments separate) with independent
COG contacts, cross-connected via M2/V1:
  S  -> TG0-P gate, TG1-N gate  (upper M2 track y=80-86)
  SB -> TG0-N gate, TG1-P gate  (lower M2 track y=54-60)

S/D slots between gates are split where adjacent transistors belong to
different nets (INV_S drain=SB vs TG0 source=D0, etc.).
"""

import gdstk

lib = gdstk.Library(unit=1e-9, precision=1e-12)
cell = lib.new_cell("MUX21x1")

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

W = 176   # cell width  (4 CPPs * 44nm)
H = 140   # cell height

# CPP centers
CPP1 = 22    # INV_S
CPP2 = 66    # TG0
CPP3 = 110   # TG1
CPP4 = 154   # INV_OUT

PW = 8  # poly half-width (16nm gate)

# Fin centers
NFIN = [25, 49]
PFIN = [91, 115]

# Active region edges
NMOS_BOT = 18;  NMOS_TOP = 56
PMOS_BOT = 84;  PMOS_TOP = 122

# S/D contact slots (split where nets differ across shared diffusion)
#   slot0:  INV_S source (VSS/VDD)
#   slot1a: INV_S drain (SB)
#   slot1b: TG0 source (D0)
#   slot2a: TG0 drain (M)
#   slot2b: TG1 source (D1)
#   slot3a: TG1 drain (M)
#   slot3b: INV_OUT source (VSS/VDD)
#   slot4:  INV_OUT drain (Y)
sd_rects = {
    'slot0':  (2, 12),
    'slot1a': (31, 41),
    'slot1b': (47, 57),
    'slot2a': (75, 85),
    'slot2b': (91, 101),
    'slot3a': (119, 129),
    'slot3b': (135, 145),
    'slot4':  (164, 174),
}

# === BOUNDARY ===
cell.add(gdstk.rectangle((0, 0), (W, H), layer=L_BOUND))

# === NWELL (PMOS region) ===
cell.add(gdstk.rectangle((0, 65), (W, H), layer=L_NWELL))

# === FINS (6nm tall nanosheets, full cell width) ===
for yc in NFIN + PFIN:
    cell.add(gdstk.rectangle((0, yc - 3), (W, yc + 3), layer=L_FIN))

# === ACTIVE ===
cell.add(gdstk.rectangle((0, NMOS_BOT), (W, NMOS_TOP), layer=L_ACTIVE))
cell.add(gdstk.rectangle((0, PMOS_BOT), (W, PMOS_TOP), layer=L_ACTIVE))

# === NSELECT / PSELECT ===
cell.add(gdstk.rectangle((0, 0), (W, 65), layer=L_NSEL))
cell.add(gdstk.rectangle((0, 65), (W, H), layer=L_PSEL))

# === POLY ===
# INV_S and INV_OUT: continuous gate poly
cell.add(gdstk.rectangle((CPP1 - PW, 5), (CPP1 + PW, 135), layer=L_POLY))
cell.add(gdstk.rectangle((CPP4 - PW, 5), (CPP4 + PW, 135), layer=L_POLY))
# TG0: split poly — separate NMOS and PMOS gate segments
cell.add(gdstk.rectangle((CPP2 - PW, 5), (CPP2 + PW, 60), layer=L_POLY))
cell.add(gdstk.rectangle((CPP2 - PW, 75), (CPP2 + PW, 135), layer=L_POLY))
# TG1: split poly
cell.add(gdstk.rectangle((CPP3 - PW, 5), (CPP3 + PW, 60), layer=L_POLY))
cell.add(gdstk.rectangle((CPP3 - PW, 75), (CPP3 + PW, 135), layer=L_POLY))

# === SDT + COSD ===
for name, (x1, x2) in sd_rects.items():
    cell.add(gdstk.rectangle((x1, NMOS_BOT), (x2, NMOS_TOP), layer=L_SDT))
    cell.add(gdstk.rectangle((x1, NMOS_BOT), (x2, NMOS_TOP), layer=L_COSD))
    cell.add(gdstk.rectangle((x1, PMOS_BOT), (x2, PMOS_TOP), layer=L_SDT))
    cell.add(gdstk.rectangle((x1, PMOS_BOT), (x2, PMOS_TOP), layer=L_COSD))

# === COG (gate contacts) ===
# INV_S and INV_OUT: centered in NMOS-PMOS gap
cell.add(gdstk.rectangle((CPP1 - PW, 60), (CPP1 + PW, 75), layer=L_COG))
cell.add(gdstk.rectangle((CPP4 - PW, 60), (CPP4 + PW, 75), layer=L_COG))
# TG0/TG1: separate NMOS COG (y=56-63) and PMOS COG (y=77-84)
cell.add(gdstk.rectangle((CPP2 - PW, 56), (CPP2 + PW, 63), layer=L_COG))
cell.add(gdstk.rectangle((CPP2 - PW, 77), (CPP2 + PW, 84), layer=L_COG))
cell.add(gdstk.rectangle((CPP3 - PW, 56), (CPP3 + PW, 63), layer=L_COG))
cell.add(gdstk.rectangle((CPP3 - PW, 77), (CPP3 + PW, 84), layer=L_COG))

# === M1 routing ===
# Power rails
cell.add(gdstk.rectangle((0, 0), (W, 14), layer=L_M1))        # VSS
cell.add(gdstk.rectangle((0, 126), (W, H), layer=L_M1))       # VDD

# INV_S source (slot0) to power rails
cell.add(gdstk.rectangle((2, 0), (12, NMOS_BOT), layer=L_M1))
cell.add(gdstk.rectangle((2, PMOS_TOP), (12, H), layer=L_M1))

# INV_OUT source (slot3b) to power rails
cell.add(gdstk.rectangle((135, 0), (145, NMOS_BOT), layer=L_M1))
cell.add(gdstk.rectangle((135, PMOS_TOP), (145, H), layer=L_M1))

# SB node (slot1a): vertical M1 strap NMOS to PMOS
cell.add(gdstk.rectangle((31, NMOS_TOP), (41, PMOS_BOT), layer=L_M1))

# D0 pin (slot1b): vertical M1 strap
cell.add(gdstk.rectangle((47, NMOS_TOP), (57, PMOS_BOT), layer=L_M1))

# M node (slot2a): TG0 drain — vertical strap
cell.add(gdstk.rectangle((75, NMOS_TOP), (85, PMOS_BOT), layer=L_M1))

# D1 pin (slot2b): TG1 source — vertical strap
cell.add(gdstk.rectangle((91, NMOS_TOP), (101, PMOS_BOT), layer=L_M1))

# M node (slot3a): TG1 drain — vertical strap
cell.add(gdstk.rectangle((119, NMOS_TOP), (129, PMOS_BOT), layer=L_M1))

# M horizontal tie: slot2a (TG0 drain) to slot3a (TG1 drain)
cell.add(gdstk.rectangle((75, 67), (129, 73), layer=L_M1))

# M to INV_OUT gate: slot3a to CPP4 COG
cell.add(gdstk.rectangle((129, 67), (162, 73), layer=L_M1))

# Y output (slot4): vertical strap NMOS to PMOS
cell.add(gdstk.rectangle((164, NMOS_TOP), (174, PMOS_BOT), layer=L_M1))

# S input: M1 pad at CPP1 COG
cell.add(gdstk.rectangle((14, 64), (30, 71), layer=L_M1))

# === M2 + V1: TG gate cross-connections ===
# Upper M2 track (y=80-86): carries S signal
#   CPP1 gate -> TG0-P gate, TG1-N gate
# Lower M2 track (y=54-60): carries SB signal
#   slot1a (SB) -> TG0-N gate, TG1-P gate

# --- S route (upper track) ---
# V1 at CPP1: M1 jog from COG (y~67) up to M2 (y=80)
cell.add(gdstk.rectangle((18, 71), (26, 86), layer=L_M1))
cell.add(gdstk.rectangle((18, 80), (26, 86), layer=L_V1))
# M2 horizontal span
cell.add(gdstk.rectangle((18, 80), (118, 86), layer=L_M2))
# V1 down to TG0-P COG (x=58-74, y=77-84)
cell.add(gdstk.rectangle((58, 80), (74, 86), layer=L_V1))
cell.add(gdstk.rectangle((58, 77), (74, 80), layer=L_M1))
# V1 down to TG1-N COG (x=102-118, y=56-63) via M1 vertical jog
cell.add(gdstk.rectangle((102, 80), (118, 86), layer=L_V1))
cell.add(gdstk.rectangle((102, 63), (118, 80), layer=L_M1))

# --- SB route (lower track) ---
# V1 from slot1a M1 strap down to M2 level
cell.add(gdstk.rectangle((31, 54), (41, 56), layer=L_M1))
cell.add(gdstk.rectangle((31, 54), (41, 60), layer=L_V1))
# M2 horizontal span
cell.add(gdstk.rectangle((31, 54), (118, 60), layer=L_M2))
# V1 up to TG0-N COG (x=58-74, y=56-63)
cell.add(gdstk.rectangle((58, 54), (74, 60), layer=L_V1))
cell.add(gdstk.rectangle((58, 60), (74, 63), layer=L_M1))
# V1 up to TG1-P COG (x=102-118, y=77-84) via M1 vertical jog
cell.add(gdstk.rectangle((102, 54), (118, 60), layer=L_V1))
cell.add(gdstk.rectangle((102, 60), (118, 84), layer=L_M1))

# === LVT implant (full cell) ===
cell.add(gdstk.rectangle((0, 0), (W, H), layer=L_LVT))

# === TEXT labels ===
cell.add(gdstk.Label("S",   (22, 92),   layer=L_TEXT))
cell.add(gdstk.Label("D0",  (52, 70),   layer=L_TEXT))
cell.add(gdstk.Label("D1",  (96, 70),   layer=L_TEXT))
cell.add(gdstk.Label("Y",   (169, 70),  layer=L_TEXT))
cell.add(gdstk.Label("VDD", (88, 133),  layer=L_TEXT))
cell.add(gdstk.Label("VSS", (88, 7),    layer=L_TEXT))

# === Write GDS ===
outpath = "/Users/bruce/CLAUDE/asap5/charflow/gds/MUX21x1.gds"
lib.write_gds(outpath)
print(f"MUX21x1.gds written to {outpath}")
print(f"  Cell: {W}nm x {H}nm (4 CPPs)")
print(f"  8T: INV_S + TG0 + TG1 + INV_OUT")
print(f"  Split poly on TG gates for independent N/P control")
print(f"  M2/V1 cross-routing: S->TG0-P,TG1-N  SB->TG0-N,TG1-P")
