#!/usr/bin/env python3
"""Generate ASAP5 5nm NOR2x1 GDS layout using gdstk.

NOR2x1: Y = ~(A + B), 4T cell
  NMOS: 2 parallel (both source=VSS, both drain=Y)
  PMOS: 2 series  (VDD -> A -> mid_p -> B -> Y)

Cell: 88nm x 140nm (2 CPPs @ 44nm)
Gate A at x=22, Gate B at x=66.

SD regions (3 diffusion breaks between/outside gates):
  Left   (x ~2-14):  NMOS source(VSS),  PMOS source(VDD)
  Middle (x ~30-58): NMOS drain(Y) shared, PMOS internal mid_p
  Right  (x ~74-86): NMOS source(VSS),  PMOS drain(Y)
"""

import gdstk

lib = gdstk.Library(unit=1e-9, precision=1e-12)
cell = lib.new_cell("NOR2x1")

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

# ============================================================
# 1. BOUNDARY — 88nm wide (2 CPP) x 140nm tall
# ============================================================
cell.add(gdstk.rectangle((0, 0), (88, 140), layer=L_BOUND))

# ============================================================
# 2. NWELL — PMOS region (top half, y >= 65)
# ============================================================
cell.add(gdstk.rectangle((0, 65), (88, 140), layer=L_NWELL))

# ============================================================
# 3. FINS — 6nm tall nanosheets, full cell width
# ============================================================
for y_center in [25, 49]:       # NMOS fins
    cell.add(gdstk.rectangle((0, y_center - 3), (88, y_center + 3), layer=L_FIN))
for y_center in [91, 115]:      # PMOS fins
    cell.add(gdstk.rectangle((0, y_center - 3), (88, y_center + 3), layer=L_FIN))

# ============================================================
# 4. ACTIVE — continuous strips spanning all SD + gate regions
# ============================================================
cell.add(gdstk.rectangle((0, 18), (88, 56), layer=L_ACTIVE))   # NMOS
cell.add(gdstk.rectangle((0, 84), (88, 122), layer=L_ACTIVE))  # PMOS

# ============================================================
# 5. NSELECT / PSELECT
# ============================================================
cell.add(gdstk.rectangle((0, 0), (88, 65), layer=L_NSEL))
cell.add(gdstk.rectangle((0, 65), (88, 140), layer=L_PSEL))

# ============================================================
# 6. POLY — two gate stripes, each 16nm wide, spanning both
#    NMOS and PMOS regions
#    Gate A center x=22 -> (14, 30)
#    Gate B center x=66 -> (58, 74)
# ============================================================
cell.add(gdstk.rectangle((14, 5), (30, 135), layer=L_POLY))   # Gate A
cell.add(gdstk.rectangle((58, 5), (74, 135), layer=L_POLY))   # Gate B

# ============================================================
# 7. SDT — source/drain trench contacts on each SD region
#    Left   (2, 14):  NMOS src VSS,  PMOS src VDD
#    Middle (34, 54): NMOS drain Y,  PMOS mid_p (internal)
#    Right  (74, 86): NMOS src VSS,  PMOS drain Y
# ============================================================
# Left SD
cell.add(gdstk.rectangle((2, 18), (12, 56), layer=L_SDT))     # NMOS src (VSS)
cell.add(gdstk.rectangle((2, 84), (12, 122), layer=L_SDT))    # PMOS src (VDD)
# Middle SD
cell.add(gdstk.rectangle((34, 18), (54, 56), layer=L_SDT))    # NMOS drain (Y)
cell.add(gdstk.rectangle((34, 84), (54, 122), layer=L_SDT))   # PMOS mid_p (internal)
# Right SD
cell.add(gdstk.rectangle((76, 18), (86, 56), layer=L_SDT))    # NMOS src (VSS)
cell.add(gdstk.rectangle((76, 84), (86, 122), layer=L_SDT))   # PMOS drain (Y)

# ============================================================
# 8. COSD — co-drawn with SDT (same rectangles)
# ============================================================
# Left SD
cell.add(gdstk.rectangle((2, 18), (12, 56), layer=L_COSD))
cell.add(gdstk.rectangle((2, 84), (12, 122), layer=L_COSD))
# Middle SD
cell.add(gdstk.rectangle((34, 18), (54, 56), layer=L_COSD))
cell.add(gdstk.rectangle((34, 84), (54, 122), layer=L_COSD))
# Right SD
cell.add(gdstk.rectangle((76, 18), (86, 56), layer=L_COSD))
cell.add(gdstk.rectangle((76, 84), (86, 122), layer=L_COSD))

# ============================================================
# 9. COG — gate contacts (in the gap between NMOS and PMOS)
#    One per gate, centered on each poly stripe
# ============================================================
cell.add(gdstk.rectangle((14, 60), (30, 75), layer=L_COG))    # Gate A contact
cell.add(gdstk.rectangle((58, 60), (74, 75), layer=L_COG))    # Gate B contact

# ============================================================
# 10. M1 — Metal1 routing
# ============================================================
# --- Power rails (full width) ---
cell.add(gdstk.rectangle((0, 0), (88, 14), layer=L_M1))       # VSS rail (bottom)
cell.add(gdstk.rectangle((0, 126), (88, 140), layer=L_M1))    # VDD rail (top)

# --- NMOS left source → VSS rail ---
cell.add(gdstk.rectangle((2, 0), (12, 18), layer=L_M1))

# --- NMOS right source → VSS rail ---
cell.add(gdstk.rectangle((76, 0), (86, 18), layer=L_M1))

# --- PMOS left source → VDD rail ---
cell.add(gdstk.rectangle((2, 122), (12, 140), layer=L_M1))

# --- Output Y: connect NMOS shared drain (middle) to PMOS drain (right) ---
# Vertical strap from NMOS middle drain up through gap to PMOS right drain
# Use a vertical M1 bar on the right side bridging PMOS drain to an
# intermediate point, and a horizontal bar connecting NMOS middle drain
# across to that vertical bar.

# NMOS middle drain strap (vertical, from drain up into routing channel)
cell.add(gdstk.rectangle((34, 56), (54, 64), layer=L_M1))

# Horizontal Y bus in the routing channel connecting middle to right
cell.add(gdstk.rectangle((34, 56), (86, 64), layer=L_M1))

# PMOS right drain strap (vertical, from drain down into routing channel)
cell.add(gdstk.rectangle((76, 64), (86, 84), layer=L_M1))

# ============================================================
# 11. LVT implant — full cell
# ============================================================
cell.add(gdstk.rectangle((0, 0), (88, 140), layer=L_LVT))

# ============================================================
# 12. TEXT labels
# ============================================================
cell.add(gdstk.Label("A",   (22, 68),  layer=L_TEXT))
cell.add(gdstk.Label("B",   (66, 68),  layer=L_TEXT))
cell.add(gdstk.Label("Y",   (81, 70),  layer=L_TEXT))
cell.add(gdstk.Label("VDD", (44, 133), layer=L_TEXT))
cell.add(gdstk.Label("VSS", (44, 7),   layer=L_TEXT))

# ============================================================
# Write GDS
# ============================================================
outpath = "/Users/bruce/CLAUDE/asap5/charflow/gds/NOR2x1.gds"
lib.write_gds(outpath)
print(f"NOR2x1.gds written to {outpath}")
