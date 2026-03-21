#!/usr/bin/env python3
"""Generate ASAP5 5nm INVx2 GDS layout using gdstk.

INVx2: double-drive inverter, 4 fins per device.
Cell size: 44nm wide x 140nm tall (1 CPP).
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
CELL_W = 44
CELL_H = 140

# Fin positions (y-center), width = 6nm
NMOS_FINS = [19, 31, 43, 55]
PMOS_FINS = [85, 97, 109, 121]
FIN_W = 6  # fin height (thickness)

# Poly gate
POLY_X1 = 14
POLY_X2 = 30
POLY_W = POLY_X2 - POLY_X1  # 16nm gate length

# NWELL covers PMOS region (upper half)
NWELL_Y1 = 65
NWELL_Y2 = CELL_H

# Active regions (enclosing diffusion around fins)
N_ACTIVE = (0, NMOS_FINS[0] - 5, CELL_W, NMOS_FINS[-1] + 5)  # y=14..60
P_ACTIVE = (0, PMOS_FINS[0] - 5, CELL_W, PMOS_FINS[-1] + 5)  # y=80..126

# Select regions (wider than active)
N_SELECT = (0, 0, CELL_W, 65)
P_SELECT = (0, 65, CELL_W, CELL_H)

# VDD/VSS M1 rails
VDD_RAIL = (0, 126, CELL_W, CELL_H)
VSS_RAIL = (0, 0, CELL_W, 14)

# Source/drain contact regions (COSD) - between poly edge and cell edge
# Left S/D: x=0..14, Right S/D: x=30..44
N_COSD_L = (2, NMOS_FINS[0] - 3, POLY_X1, NMOS_FINS[-1] + 3)
N_COSD_R = (POLY_X2, NMOS_FINS[0] - 3, CELL_W - 2, NMOS_FINS[-1] + 3)
P_COSD_L = (2, PMOS_FINS[0] - 3, POLY_X1, PMOS_FINS[-1] + 3)
P_COSD_R = (POLY_X2, PMOS_FINS[0] - 3, CELL_W - 2, PMOS_FINS[-1] + 3)

# SDT (source/drain trench) - same as COSD but slightly wider
N_SDT_L = (1, NMOS_FINS[0] - 4, POLY_X1, NMOS_FINS[-1] + 4)
N_SDT_R = (POLY_X2, NMOS_FINS[0] - 4, CELL_W - 1, NMOS_FINS[-1] + 4)
P_SDT_L = (1, PMOS_FINS[0] - 4, POLY_X1, PMOS_FINS[-1] + 4)
P_SDT_R = (POLY_X2, PMOS_FINS[0] - 4, CELL_W - 1, PMOS_FINS[-1] + 4)

# Gate contact (COG) on poly between NMOS and PMOS
COG_RECT = (16, 65, 28, 75)

# M1 routing
# VDD tap: left S/D of PMOS to VDD rail
M1_VDD_TAP = (2, PMOS_FINS[-1] + 3, 16, 126)
# VSS tap: left S/D of NMOS to VSS rail
M1_VSS_TAP = (2, 14, 16, NMOS_FINS[0] - 3)
# Output Y: right S/D connects NMOS drain to PMOS drain
M1_Y = (32, NMOS_FINS[-1] + 3, CELL_W, PMOS_FINS[0] - 3)

# Poly extensions for gate input
POLY_GATE_N = (POLY_X1, NMOS_FINS[0] - 5, POLY_X2, NMOS_FINS[-1] + 5)
POLY_GATE_P = (POLY_X1, PMOS_FINS[0] - 5, POLY_X2, PMOS_FINS[-1] + 5)
POLY_CONN_L = (POLY_X1, NMOS_FINS[-1] + 5, POLY_X1 + 2, PMOS_FINS[0] - 5)
POLY_CONN_R = (POLY_X2 - 2, NMOS_FINS[-1] + 5, POLY_X2, PMOS_FINS[0] - 5)
POLY_MID = (POLY_X1, 65, POLY_X2, 75)


def rect(x1, y1, x2, y2):
    return (x1, y1), (x2, y1), (x2, y2), (x1, y2)


def add_rect(cell, layer, x1, y1, x2, y2):
    cell.add(gdstk.rectangle((x1, y1), (x2, y2), layer=layer[0], datatype=layer[1]))


def main():
    lib = gdstk.Library(unit=1e-9, precision=1e-12)
    cell = lib.new_cell("INVx2")

    # BOUNDARY
    add_rect(cell, L_BOUNDARY, 0, 0, CELL_W, CELL_H)

    # NWELL
    add_rect(cell, L_NWELL, 0, NWELL_Y1, CELL_W, NWELL_Y2)

    # FINs (horizontal stripes, full cell width)
    for fy in NMOS_FINS + PMOS_FINS:
        add_rect(cell, L_FIN, 0, fy - FIN_W // 2, CELL_W, fy + FIN_W // 2)

    # ACTIVE regions
    add_rect(cell, L_ACTIVE, *N_ACTIVE)
    add_rect(cell, L_ACTIVE, *P_ACTIVE)

    # NSELECT / PSELECT
    add_rect(cell, L_NSELECT, *N_SELECT)
    add_rect(cell, L_PSELECT, *P_SELECT)

    # POLY gate over NMOS fins
    add_rect(cell, L_POLY, POLY_X1, NMOS_FINS[0] - 5, POLY_X2, NMOS_FINS[-1] + 5)
    # POLY gate over PMOS fins
    add_rect(cell, L_POLY, POLY_X1, PMOS_FINS[0] - 5, POLY_X2, PMOS_FINS[-1] + 5)
    # POLY connection between N and P (two thin straps on edges)
    add_rect(cell, L_POLY, POLY_X1, NMOS_FINS[-1] + 5, POLY_X1 + 2, PMOS_FINS[0] - 5)
    add_rect(cell, L_POLY, POLY_X2 - 2, NMOS_FINS[-1] + 5, POLY_X2, PMOS_FINS[0] - 5)
    # POLY horizontal bar between N/P for gate contact
    add_rect(cell, L_POLY, POLY_X1, 65, POLY_X2, 75)

    # SDT (source/drain trench)
    for r in [N_SDT_L, N_SDT_R, P_SDT_L, P_SDT_R]:
        add_rect(cell, L_SDT, *r)

    # COSD (source/drain contacts)
    for r in [N_COSD_L, N_COSD_R, P_COSD_L, P_COSD_R]:
        add_rect(cell, L_COSD, *r)

    # COG (gate contact)
    add_rect(cell, L_COG, *COG_RECT)

    # M1 rails
    add_rect(cell, L_M1, *VDD_RAIL)
    add_rect(cell, L_M1, *VSS_RAIL)

    # M1 VDD/VSS taps
    add_rect(cell, L_M1, *M1_VDD_TAP)
    add_rect(cell, L_M1, *M1_VSS_TAP)

    # M1 output (Y) - connects NMOS and PMOS drains
    add_rect(cell, L_M1, *M1_Y)

    # LVT implant (covers entire cell)
    add_rect(cell, L_LVT, 0, 0, CELL_W, CELL_H)

    # TEXT labels
    cell.add(gdstk.Label("A", (22, 70), layer=L_TEXT[0], texttype=L_TEXT[1]))
    cell.add(gdstk.Label("Y", (38, 70), layer=L_TEXT[0], texttype=L_TEXT[1]))
    cell.add(gdstk.Label("VDD", (22, 133), layer=L_TEXT[0], texttype=L_TEXT[1]))
    cell.add(gdstk.Label("VSS", (22, 7), layer=L_TEXT[0], texttype=L_TEXT[1]))

    outfile = "/Users/bruce/CLAUDE/asap5/charflow/gds/INVx2.gds"
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
