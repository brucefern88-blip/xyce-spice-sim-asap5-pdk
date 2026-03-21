#!/usr/bin/env python3
"""Generate ASAP5 5nm INVx4 GDS layout using gdstk.

INVx4: quad-drive inverter, 8 fins per device (4 fins x 2 poly gates).
Cell size: 88nm wide x 140nm tall (2 CPPs at 44nm pitch).
Two parallel poly gates connected together, drains merged on M1.
"""

import gdstk

# --- Layer map (ASAP5) ---
L_NWELL    = (1, 0)
L_FIN      = (2, 0)
L_BOUNDARY = (5, 0)
L_POLY     = (7, 0)
L_ACTIVE   = (11, 0)
L_NSELECT  = (12, 0)
L_PSELECT  = (13, 0)
L_M1       = (19, 0)
L_SDT      = (88, 0)
L_COSD     = (89, 0)
L_COG      = (87, 0)
L_LVT      = (98, 0)
L_TEXT     = (101, 0)

# --- Dimensions (all nm) ---
CELL_W = 88
CELL_H = 140
CPP = 44  # contacted poly pitch

# Fin positions (y-center), width = 6nm
# 4 fins per device per gate column, same y for both columns
NMOS_FINS = [19, 31, 43, 55]
PMOS_FINS = [85, 97, 109, 121]
FIN_W = 6  # fin thickness

# Two poly gates, each 16nm wide, at CPP spacing
# Gate 1: x=14..30, Gate 2: x=58..74
POLY_G1_X1 = 14
POLY_G1_X2 = 30
POLY_G2_X1 = 58
POLY_G2_X2 = 74

# NWELL covers PMOS region (upper half)
NWELL_Y1 = 65
NWELL_Y2 = CELL_H

# Active regions (enclosing all fins)
N_ACTIVE = (0, NMOS_FINS[0] - 5, CELL_W, NMOS_FINS[-1] + 5)  # y=14..60
P_ACTIVE = (0, PMOS_FINS[0] - 5, CELL_W, PMOS_FINS[-1] + 5)  # y=80..126

# Select regions
N_SELECT = (0, 0, CELL_W, 65)
P_SELECT = (0, 65, CELL_W, CELL_H)

# VDD/VSS M1 rails (span full 88nm width)
VDD_RAIL = (0, 126, CELL_W, CELL_H)
VSS_RAIL = (0, 0, CELL_W, 14)

# Source/drain contact regions (COSD) for each gate
# Gate 1: left S/D x=2..14, right S/D x=30..42
# Gate 2: left S/D x=46..58, right S/D x=74..86
# Shared middle S/D between gates: x=30..58 (merged drain)

# NMOS COSD
N_COSD_L1 = (2, NMOS_FINS[0] - 3, POLY_G1_X1, NMOS_FINS[-1] + 3)       # left source G1
N_COSD_MID = (POLY_G1_X2, NMOS_FINS[0] - 3, POLY_G2_X1, NMOS_FINS[-1] + 3)  # shared drain
N_COSD_R2 = (POLY_G2_X2, NMOS_FINS[0] - 3, CELL_W - 2, NMOS_FINS[-1] + 3)  # right source G2

# PMOS COSD
P_COSD_L1 = (2, PMOS_FINS[0] - 3, POLY_G1_X1, PMOS_FINS[-1] + 3)
P_COSD_MID = (POLY_G1_X2, PMOS_FINS[0] - 3, POLY_G2_X1, PMOS_FINS[-1] + 3)
P_COSD_R2 = (POLY_G2_X2, PMOS_FINS[0] - 3, CELL_W - 2, PMOS_FINS[-1] + 3)

# SDT (slightly wider than COSD)
N_SDT_L1 = (1, NMOS_FINS[0] - 4, POLY_G1_X1, NMOS_FINS[-1] + 4)
N_SDT_MID = (POLY_G1_X2, NMOS_FINS[0] - 4, POLY_G2_X1, NMOS_FINS[-1] + 4)
N_SDT_R2 = (POLY_G2_X2, NMOS_FINS[0] - 4, CELL_W - 1, NMOS_FINS[-1] + 4)

P_SDT_L1 = (1, PMOS_FINS[0] - 4, POLY_G1_X1, PMOS_FINS[-1] + 4)
P_SDT_MID = (POLY_G1_X2, PMOS_FINS[0] - 4, POLY_G2_X1, PMOS_FINS[-1] + 4)
P_SDT_R2 = (POLY_G2_X2, PMOS_FINS[0] - 4, CELL_W - 1, PMOS_FINS[-1] + 4)

# Gate contacts (COG) on poly between NMOS and PMOS, one per gate
COG_G1 = (POLY_G1_X1 + 2, 65, POLY_G1_X2 - 2, 75)
COG_G2 = (POLY_G2_X1 + 2, 65, POLY_G2_X2 - 2, 75)


def add_rect(cell, layer, x1, y1, x2, y2):
    cell.add(gdstk.rectangle((x1, y1), (x2, y2), layer=layer[0], datatype=layer[1]))


def main():
    lib = gdstk.Library(unit=1e-9, precision=1e-12)
    cell = lib.new_cell("INVx4")

    # BOUNDARY
    add_rect(cell, L_BOUNDARY, 0, 0, CELL_W, CELL_H)

    # NWELL
    add_rect(cell, L_NWELL, 0, NWELL_Y1, CELL_W, NWELL_Y2)

    # FINs (horizontal stripes, full cell width - both gate columns share fins)
    for fy in NMOS_FINS + PMOS_FINS:
        add_rect(cell, L_FIN, 0, fy - FIN_W // 2, CELL_W, fy + FIN_W // 2)

    # ACTIVE regions (span full width, covering both gate columns)
    add_rect(cell, L_ACTIVE, *N_ACTIVE)
    add_rect(cell, L_ACTIVE, *P_ACTIVE)

    # NSELECT / PSELECT
    add_rect(cell, L_NSELECT, *N_SELECT)
    add_rect(cell, L_PSELECT, *P_SELECT)

    # POLY Gate 1 - over NMOS
    add_rect(cell, L_POLY, POLY_G1_X1, NMOS_FINS[0] - 5, POLY_G1_X2, NMOS_FINS[-1] + 5)
    # POLY Gate 1 - over PMOS
    add_rect(cell, L_POLY, POLY_G1_X1, PMOS_FINS[0] - 5, POLY_G1_X2, PMOS_FINS[-1] + 5)
    # POLY Gate 1 - connection straps between N and P
    add_rect(cell, L_POLY, POLY_G1_X1, NMOS_FINS[-1] + 5, POLY_G1_X1 + 2, PMOS_FINS[0] - 5)
    add_rect(cell, L_POLY, POLY_G1_X2 - 2, NMOS_FINS[-1] + 5, POLY_G1_X2, PMOS_FINS[0] - 5)
    # POLY Gate 1 - horizontal bar for COG
    add_rect(cell, L_POLY, POLY_G1_X1, 65, POLY_G1_X2, 75)

    # POLY Gate 2 - over NMOS
    add_rect(cell, L_POLY, POLY_G2_X1, NMOS_FINS[0] - 5, POLY_G2_X2, NMOS_FINS[-1] + 5)
    # POLY Gate 2 - over PMOS
    add_rect(cell, L_POLY, POLY_G2_X1, PMOS_FINS[0] - 5, POLY_G2_X2, PMOS_FINS[-1] + 5)
    # POLY Gate 2 - connection straps between N and P
    add_rect(cell, L_POLY, POLY_G2_X1, NMOS_FINS[-1] + 5, POLY_G2_X1 + 2, PMOS_FINS[0] - 5)
    add_rect(cell, L_POLY, POLY_G2_X2 - 2, NMOS_FINS[-1] + 5, POLY_G2_X2, PMOS_FINS[0] - 5)
    # POLY Gate 2 - horizontal bar for COG
    add_rect(cell, L_POLY, POLY_G2_X1, 65, POLY_G2_X2, 75)

    # M1 horizontal bar connecting Gate 1 and Gate 2 poly contacts (input A)
    add_rect(cell, L_M1, POLY_G1_X1, 66, POLY_G2_X2, 74)

    # SDT (source/drain trench)
    for r in [N_SDT_L1, N_SDT_MID, N_SDT_R2, P_SDT_L1, P_SDT_MID, P_SDT_R2]:
        add_rect(cell, L_SDT, *r)

    # COSD (source/drain contacts)
    for r in [N_COSD_L1, N_COSD_MID, N_COSD_R2, P_COSD_L1, P_COSD_MID, P_COSD_R2]:
        add_rect(cell, L_COSD, *r)

    # COG (gate contacts) - one per gate
    add_rect(cell, L_COG, *COG_G1)
    add_rect(cell, L_COG, *COG_G2)

    # M1 rails (span full 88nm width)
    add_rect(cell, L_M1, *VDD_RAIL)
    add_rect(cell, L_M1, *VSS_RAIL)

    # M1 VDD tap: left source of G1 (PMOS) to VDD rail
    add_rect(cell, L_M1, 2, PMOS_FINS[-1] + 3, 14, 126)
    # M1 VDD tap: right source of G2 (PMOS) to VDD rail
    add_rect(cell, L_M1, 74, PMOS_FINS[-1] + 3, 86, 126)

    # M1 VSS tap: left source of G1 (NMOS) to VSS rail
    add_rect(cell, L_M1, 2, 14, 14, NMOS_FINS[0] - 3)
    # M1 VSS tap: right source of G2 (NMOS) to VSS rail
    add_rect(cell, L_M1, 74, 14, 86, NMOS_FINS[0] - 3)

    # M1 output Y: connects both drain regions (mid between gates)
    # Vertical bar spanning NMOS drain to PMOS drain through middle S/D region
    add_rect(cell, L_M1, 34, NMOS_FINS[0] - 3, 54, PMOS_FINS[-1] + 3)

    # LVT implant (covers entire cell)
    add_rect(cell, L_LVT, 0, 0, CELL_W, CELL_H)

    # TEXT labels
    cell.add(gdstk.Label("A", (44, 70), layer=L_TEXT[0], texttype=L_TEXT[1]))
    cell.add(gdstk.Label("Y", (44, 38), layer=L_TEXT[0], texttype=L_TEXT[1]))
    cell.add(gdstk.Label("VDD", (44, 133), layer=L_TEXT[0], texttype=L_TEXT[1]))
    cell.add(gdstk.Label("VSS", (44, 7), layer=L_TEXT[0], texttype=L_TEXT[1]))

    outfile = "/Users/bruce/CLAUDE/asap5/charflow/gds/INVx4.gds"
    lib.write_gds(outfile)
    print(f"Wrote {outfile}")

    import os
    sz = os.path.getsize(outfile)
    print(f"File size: {sz} bytes")

    # Summary
    print(f"Cell: {cell.name}")
    bb = cell.bounding_box()
    print(f"Bounding box: ({bb[0][0]:.0f}, {bb[0][1]:.0f}) to ({bb[1][0]:.0f}, {bb[1][1]:.0f}) nm")
    print(f"Polygons: {len(cell.polygons)}")
    print(f"Labels: {len(cell.labels)}")


if __name__ == "__main__":
    main()
