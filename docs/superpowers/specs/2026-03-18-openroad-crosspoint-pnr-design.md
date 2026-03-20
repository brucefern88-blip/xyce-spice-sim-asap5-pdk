# OpenROAD Custom Crosspoint PnR for 64-bit Hamming Distance (ASAP5 5nm)

**Date**: 2026-03-18
**Status**: Approved
**Approach**: Staged TCL Flow (Approach C) — Hybrid synthesis + ECO custom routing

## Overview

Implement the 64-bit cuboid radix-4 Hamming distance circuit in OpenROAD v26Q1 using the ASAP5 5nm GAA nanosheet PDK. The design uses FUSED_G cells (40T, active-low) with output inverters to produce active-high one-hot {oh0, oh1, oh2} outputs. Crosspoint matrices (46 structures, 1,605 grid points) are initially synthesized to standard cells, then ECO-replaced with via-only custom routes on designated metal layers (M2-M10) to achieve minimum wire capacitance.

## Metal Stack (TSMC N5, 13 layers)

| Layer | Pitch | Width | Thick | R (Ω/μm) | C (fF/μm) | Direction |
|-------|-------|-------|-------|-----------|-----------|-----------|
| M1 | 28nm | 14nm | 36nm | 40 | 0.28 | H |
| M2 | 28nm | 14nm | 36nm | 225 | 0.27 | V |
| M3 | 28nm | 14nm | 36nm | 99 | 0.22 | H |
| M4 | 40nm | 20nm | 40nm | 117 | 0.20 | V |
| M5 | 40nm | 20nm | 40nm | 52 | 0.26 | H |
| M6 | 40nm | 20nm | 40nm | 16 | 0.16 | V |
| M7 | 80nm | 40nm | 60nm | 11 | 0.17 | H |
| M8 | 80nm | 40nm | 60nm | 11 | 0.17 | V |
| M9 | 160nm | 80nm | 100nm | 11 | 0.19 | H |
| M10 | 160nm | 80nm | 100nm | 0.4 | 0.19 | V |
| M11 | 800nm | 400nm | 800nm | 0.4 | 0.35 | H |
| M12 | 800nm | 400nm | 800nm | 0.4 | 0.4 | V |

## Cell Library Extension

### FUSED_G_OH Wrapper (48T)
- FUSED_G core (40T): inputs ai, bi, aj, bj → active-low noh1, noh2
- 2x INVx1 (4T): noh1→oh1, noh2→oh2
- 1x NOR2x1 (4T): oh0 = NOR(oh1, oh2)
- Total: 48T, 3 active-high one-hot outputs

### Files Modified
- asap5_tech.lef: M6-M12 + V5-V11
- asap5_stdcells.lef: 4 FUSED macros (A/E/F/G)
- asap5_stdcells_tt_0p5v_25c.lib: 4 FUSED Liberty cells
- asap5_stdcells.v: 4 behavioral Verilog modules
- asap5_cells.v: 4 specify-timing modules
- asap5_stdcells.cdl: 4 CDL subcircuits

## 4-Pass PnR Flow

### Pass 1: Synthesis + Placement
- Yosys synthesis with extended cell library
- 32x FUSED_G_OH placed in 8x4 cuboid grid (3.52 x 1.12 um)
- Crosspoint logic synthesized to NAND/NOR/INV (temporary)

### Pass 2: Standard Routing (M1-M10)
- OpenROAD global + detailed route
- Power grid on M11/M12 (400nm wide, 800nm pitch)
- Non-default rules: doubled wire widths on M1-M4

### Pass 3: ECO Custom Crosspoint Routing
- Rip up synthesized crosspoint cell routes
- Remove crosspoint cells (ECO delete)
- Replace with via-only routes per metal layer map:
  - Stage 2: M2/M3 (16x 3x3 + 8x 5x5)
  - Stage 4 Low: M5/M6 (4x4), M6/M7 (7x7), M7/M8 (13x13)
  - Stage 4 High: M5/M6 (3x3), M6/M7 (5x5), M7/M8 (9x9)
  - Stage 4D Carry: M7/M8 (17x7)
  - Stage 5 Binary: M9/M10 (7x 4x23)

### Pass 4: GUI Verification
- Visual inspection of crosspoint via arrays
- Per-net parasitic measurement
- DRC check on doubled-width wires
- STA timing + power signoff

## Signoff Targets

| Metric | Target |
|--------|--------|
| Critical path | < 106 ps worst, ~75 ps typical |
| Wire capacitance | ~132 fF total |
| Dynamic power @ 1 GHz | ~31 uW |
| Buffer count | 121 mandatory + 32 optional |
| Transistor count | ~1,248 |
| DRC violations | 0 |
| Crosspoint vias | ~1,283 |
