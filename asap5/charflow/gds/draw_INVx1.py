#!/usr/bin/env python3
"""Generate ASAP5 5nm INVx1 inverter GDS layout using gdstk."""

import gdstk

lib = gdstk.Library(unit=1e-9, precision=1e-12)
cell = lib.new_cell("INVx1")

# --- Layer definitions (GDS#, datatype) ---
L_NWELL  = 1
L_FIN    = 2
L_BOUND  = 5
L_POLY   = 7
L_GCUT   = 10
L_ACTIVE = 11
L_NSEL   = 12
L_PSEL   = 13
L_M1     = 19
L_COG    = 87
L_SDT    = 88
L_COSD   = 89
L_LVT    = 98
L_TEXT   = 101

# --- 1. BOUNDARY ---
cell.add(gdstk.rectangle((0, 0), (44, 140), layer=L_BOUND))

# --- 2. NWELL (PMOS region, top half) ---
cell.add(gdstk.rectangle((0, 65), (44, 140), layer=L_NWELL))

# --- 3. FIN (horizontal nanosheets, 6nm tall, full cell width) ---
for y_center in [25, 49]:       # NMOS fins
    cell.add(gdstk.rectangle((0, y_center - 3), (44, y_center + 3), layer=L_FIN))
for y_center in [91, 115]:      # PMOS fins
    cell.add(gdstk.rectangle((0, y_center - 3), (44, y_center + 3), layer=L_FIN))

# --- 4. ACTIVE ---
cell.add(gdstk.rectangle((0, 18), (44, 56), layer=L_ACTIVE))   # NMOS
cell.add(gdstk.rectangle((0, 84), (44, 122), layer=L_ACTIVE))  # PMOS

# --- 5. NSELECT / PSELECT ---
cell.add(gdstk.rectangle((0, 0), (44, 65), layer=L_NSEL))
cell.add(gdstk.rectangle((0, 65), (44, 140), layer=L_PSEL))

# --- 6. POLY (gate stripe, 16nm wide) ---
cell.add(gdstk.rectangle((14, 5), (30, 135), layer=L_POLY))

# --- 7. SDT (source/drain contacts) ---
cell.add(gdstk.rectangle((2, 18), (12, 56), layer=L_SDT))    # NMOS source (VSS)
cell.add(gdstk.rectangle((32, 18), (42, 56), layer=L_SDT))   # NMOS drain (Y)
cell.add(gdstk.rectangle((32, 84), (42, 122), layer=L_SDT))  # PMOS source (VDD)
cell.add(gdstk.rectangle((2, 84), (12, 122), layer=L_SDT))   # PMOS drain (Y)

# --- 8. COSD (co-drawn with SDT) ---
cell.add(gdstk.rectangle((2, 18), (12, 56), layer=L_COSD))
cell.add(gdstk.rectangle((32, 18), (42, 56), layer=L_COSD))
cell.add(gdstk.rectangle((32, 84), (42, 122), layer=L_COSD))
cell.add(gdstk.rectangle((2, 84), (12, 122), layer=L_COSD))

# --- 9. COG (gate contact in middle gap) ---
cell.add(gdstk.rectangle((14, 60), (30, 75), layer=L_COG))

# --- 10. M1 (Metal1 routing) ---
cell.add(gdstk.rectangle((0, 0), (44, 14), layer=L_M1))        # VSS rail
cell.add(gdstk.rectangle((0, 126), (44, 140), layer=L_M1))     # VDD rail
cell.add(gdstk.rectangle((2, 0), (12, 18), layer=L_M1))        # NMOS source to VSS
cell.add(gdstk.rectangle((32, 122), (42, 140), layer=L_M1))    # PMOS source to VDD
cell.add(gdstk.rectangle((32, 56), (42, 84), layer=L_M1))      # Output Y strap

# --- 11. LVT implant (full cell) ---
cell.add(gdstk.rectangle((0, 0), (44, 140), layer=L_LVT))

# --- 12. TEXT labels ---
cell.add(gdstk.Label("A",   (22, 70),  layer=L_TEXT))
cell.add(gdstk.Label("Y",   (37, 70),  layer=L_TEXT))
cell.add(gdstk.Label("VDD", (22, 133), layer=L_TEXT))
cell.add(gdstk.Label("VSS", (22, 7),   layer=L_TEXT))

# --- Write GDS ---
outpath = "/Users/bruce/CLAUDE/asap5/charflow/gds/INVx1.gds"
lib.write_gds(outpath)
print(f"INVx1.gds written to {outpath}")
