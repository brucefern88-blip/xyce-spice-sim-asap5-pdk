#!/usr/bin/env python3
"""Generate ASAP5 5nm NAND2x1 GDS layout using gdstk.

4T NAND2: 2 series NMOS (VSS -> A -> mid -> B -> Y)
          2 parallel PMOS (VDD -> A -> Y, VDD -> B -> Y)
Cell: 88nm wide (2 CPPs @ 44nm) x 140nm tall.
"""

import gdstk

lib = gdstk.Library(unit=1e-9, precision=1e-12)
cell = lib.new_cell("NAND2x1")

# --- Layer definitions (GDS#, datatype=0) ---
L_NWELL  = 1
L_FIN    = 2
L_BOUND  = 5
L_POLY   = 7
L_ACTIVE = 11
L_NSEL   = 12
L_PSEL   = 13
L_M1     = 19
L_COG    = 87
L_SDT    = 88
L_COSD   = 89
L_LVT    = 98
L_TEXT   = 101

# --- 1. BOUNDARY (2 CPPs wide x 140nm tall) ---
cell.add(gdstk.rectangle((0, 0), (88, 140), layer=L_BOUND))

# --- 2. NWELL (PMOS region, top half) ---
cell.add(gdstk.rectangle((0, 65), (88, 140), layer=L_NWELL))

# --- 3. FIN (horizontal nanosheets, 6nm tall, full cell width) ---
for y_center in [25, 49]:       # NMOS fins
    cell.add(gdstk.rectangle((0, y_center - 3), (88, y_center + 3), layer=L_FIN))
for y_center in [91, 115]:      # PMOS fins
    cell.add(gdstk.rectangle((0, y_center - 3), (88, y_center + 3), layer=L_FIN))

# --- 4. ACTIVE (continuous strips for NMOS and PMOS) ---
cell.add(gdstk.rectangle((0, 18), (88, 56), layer=L_ACTIVE))   # NMOS
cell.add(gdstk.rectangle((0, 84), (88, 122), layer=L_ACTIVE))  # PMOS

# --- 5. NSELECT / PSELECT ---
cell.add(gdstk.rectangle((0, 0), (88, 65), layer=L_NSEL))
cell.add(gdstk.rectangle((0, 65), (88, 140), layer=L_PSEL))

# --- 6. POLY (two gate stripes, 16nm wide each) ---
# Gate A at CPP1 center x=22
cell.add(gdstk.rectangle((14, 5), (30, 135), layer=L_POLY))
# Gate B at CPP2 center x=66
cell.add(gdstk.rectangle((58, 5), (74, 135), layer=L_POLY))

# --- 7. SDT (source/drain contacts) ---
# NMOS series: VSS_source -> gate_A -> mid_node -> gate_B -> Y_drain
cell.add(gdstk.rectangle((2, 18), (12, 56), layer=L_SDT))      # VSS source
cell.add(gdstk.rectangle((32, 18), (42, 56), layer=L_SDT))     # mid node (left)
cell.add(gdstk.rectangle((46, 18), (56, 56), layer=L_SDT))     # mid node (right)
cell.add(gdstk.rectangle((76, 18), (86, 56), layer=L_SDT))     # Y drain

# PMOS parallel: VDD_src_A -> gate_A -> Y_drain_A, VDD_src_B -> gate_B -> Y_drain_B
cell.add(gdstk.rectangle((2, 84), (12, 122), layer=L_SDT))     # VDD source A
cell.add(gdstk.rectangle((32, 84), (42, 122), layer=L_SDT))    # Y drain A
cell.add(gdstk.rectangle((46, 84), (56, 122), layer=L_SDT))    # VDD source B
cell.add(gdstk.rectangle((76, 84), (86, 122), layer=L_SDT))    # Y drain B

# --- 8. COSD (co-drawn with SDT, same rectangles) ---
# NMOS
cell.add(gdstk.rectangle((2, 18), (12, 56), layer=L_COSD))
cell.add(gdstk.rectangle((32, 18), (42, 56), layer=L_COSD))
cell.add(gdstk.rectangle((46, 18), (56, 56), layer=L_COSD))
cell.add(gdstk.rectangle((76, 18), (86, 56), layer=L_COSD))
# PMOS
cell.add(gdstk.rectangle((2, 84), (12, 122), layer=L_COSD))
cell.add(gdstk.rectangle((32, 84), (42, 122), layer=L_COSD))
cell.add(gdstk.rectangle((46, 84), (56, 122), layer=L_COSD))
cell.add(gdstk.rectangle((76, 84), (86, 122), layer=L_COSD))

# --- 9. COG (gate contacts in middle gap between NMOS/PMOS) ---
cell.add(gdstk.rectangle((14, 60), (30, 75), layer=L_COG))     # gate A contact
cell.add(gdstk.rectangle((58, 60), (74, 75), layer=L_COG))     # gate B contact

# --- 10. M1 (Metal1 routing) ---
# Power rails
cell.add(gdstk.rectangle((0, 0), (88, 14), layer=L_M1))        # VSS rail
cell.add(gdstk.rectangle((0, 126), (88, 140), layer=L_M1))     # VDD rail

# NMOS source (VSS) strap: SDT at x=2-12 down to VSS rail
cell.add(gdstk.rectangle((2, 0), (12, 18), layer=L_M1))

# PMOS source A (VDD) strap: SDT at x=2-12 up to VDD rail
cell.add(gdstk.rectangle((2, 122), (12, 140), layer=L_M1))

# PMOS source B (VDD) strap: SDT at x=46-56 up to VDD rail
cell.add(gdstk.rectangle((46, 122), (56, 140), layer=L_M1))

# Y output: connect NMOS drain (x=76-86) + PMOS drain A (x=32-42) + PMOS drain B (x=76-86)
# Vertical M1 strap on NMOS drain side connecting through to PMOS drain B
cell.add(gdstk.rectangle((76, 56), (86, 84), layer=L_M1))      # bridge NMOS Y to PMOS Y_B
# Horizontal M1 strap connecting PMOS drain A to PMOS drain B across middle
cell.add(gdstk.rectangle((32, 80), (86, 84), layer=L_M1))      # Y horizontal tie
# Vertical M1 strap on PMOS drain A
cell.add(gdstk.rectangle((32, 75), (42, 84), layer=L_M1))      # extend drain A down to strap

# --- 11. LVT implant (full cell) ---
cell.add(gdstk.rectangle((0, 0), (88, 140), layer=L_LVT))

# --- 12. TEXT labels ---
cell.add(gdstk.Label("A",   (22, 70),  layer=L_TEXT))
cell.add(gdstk.Label("B",   (66, 70),  layer=L_TEXT))
cell.add(gdstk.Label("Y",   (81, 70),  layer=L_TEXT))
cell.add(gdstk.Label("VDD", (44, 133), layer=L_TEXT))
cell.add(gdstk.Label("VSS", (44, 7),   layer=L_TEXT))

# --- Write GDS ---
outpath = "/Users/bruce/CLAUDE/asap5/charflow/gds/NAND2x1.gds"
lib.write_gds(outpath)
print(f"NAND2x1.gds written to {outpath}")
