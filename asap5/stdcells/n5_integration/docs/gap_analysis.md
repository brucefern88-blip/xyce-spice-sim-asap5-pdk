# ASAP5/N5 OpenLane2 Integration — Gap Analysis

## Overview

This document identifies what was missing from the ASAP5 PDK for a full
RTL-to-GDSII OpenLane2 flow targeting the hamming_64b_cuboid_r4 design,
what was generated to fill those gaps, and what remains open.

Target: TSMC N5 5nm FinFET, 13-layer metal stack
Design: 64-bit Hamming Distance, Cuboid Radix-4 Architecture (combinational)

---

## 1. Gaps Identified

### 1.1 Technology LEF — Metal Stack Incomplete

**Gap:** Original `asap5_tech.lef` defined only 5 metal layers (M1-M5)
with 4 via layers (V1-V4). The design requires 10 signal layers (M1-M10)
plus 2 power layers (M11-M12) as specified in the TSMC N5 metal stack.

**Impact:** OpenROAD routing limited to M1-M5, cannot utilize M6-M10 for
digit reduction tree routing or M11-M12 for power grid.

**RC values were also inaccurate:** The original LEF used uniform RPERSQ
of 25.0 for M1-M3 and 8.0 for M4-M5, which does not reflect the actual
N5 metal stack where M2 has anomalously high resistance (225 Ω/μm).

### 1.2 Utility Cells Missing

**Gap:** No fill, tap, tie, endcap, or decap cells existed in the ASAP5
standard cell library.

| Cell Type | Purpose | Required By |
|-----------|---------|-------------|
| FILL (x1/x2/x4) | Fill empty row spaces | Detailed placement |
| TAP | Well/substrate contacts | Latch-up prevention |
| TIE_HI / TIE_LO | Tie unused inputs | Synthesis |
| ENDCAP_L / ENDCAP_R | Row boundary DRC | Floorplan |
| DECAPx2 | Power decoupling | Power integrity |

**Impact:** OpenLane2 Classic flow cannot complete placement, PDN, or
signoff steps without these cells.

### 1.3 Fused Hamming Cells Not in LEF/Liberty

**Gap:** The 4 fused Hamming cells (FUSED_A/E/F/G) exist as Magic layouts
and extracted SPICE netlists but are NOT present in the cell LEF or
Liberty timing library.

**Impact:** Pass A (structure-preserving synthesis) cannot instantiate
fused cells directly. Yosys will decompose fused-cell logic into basic
gates (XOR, AND, INV). The crosspoint topology is preserved at the
wiring level but fused cells become multi-gate clusters.

### 1.4 Single Timing Corner

**Gap:** Only TT/0.5V/25C Liberty file exists. No FF or SS corners.

**Impact:** STA signoff is single-corner only. Cannot perform multi-corner
timing analysis. Setup analysis uses TT (optimistic vs SS), hold analysis
uses TT (pessimistic vs FF).

### 1.5 SDC Constraints for Combinational Design

**Gap:** Original SDC template assumed a clocked design. The
hamming_64b_cuboid_r4 is purely combinational (no clock port).

**Impact:** Timing analysis requires a virtual clock and false paths.

### 1.6 OpenLane2 PDK Compatibility

**Gap:** OpenLane2 `pdk_compat.py` only recognizes sky130 and gf180mcu.
No ASAP5 PDK wrapper exists.

**Impact:** Must provide all PDK-specific config overrides explicitly in
config.json. Some flow steps may have hardcoded PDK assumptions.

---

## 2. Files Generated

### 2.1 Updated Technology LEF

| File | Description |
|------|-------------|
| `lef/n5_tech.lef` | Full 12-metal tech LEF (M1-M12, V1-V11) with N5 RC values |
| `../lef/asap5_tech.lef` | Original file updated in-place (same content) |

**Metal Stack RC Calibration (from TSMC N5 spec):**

| Layer | Pitch | Width | Thick | R (Ω/μm) | C (fF/μm) | RPERSQ | CPERSQDIST |
|-------|-------|-------|-------|-----------|-----------|--------|------------|
| M1 | 28nm | 14nm | 36nm | 40 | 0.28 | 0.560 | 0.02000 |
| M2 | 28nm | 14nm | 36nm | 225 | 0.27 | 3.150 | 0.01929 |
| M3 | 28nm | 14nm | 36nm | 99 | 0.22 | 1.386 | 0.01571 |
| M4 | 40nm | 20nm | 40nm | 117 | 0.20 | 2.340 | 0.01000 |
| M5 | 40nm | 20nm | 40nm | 52 | 0.26 | 1.040 | 0.01300 |
| M6 | 40nm | 20nm | 40nm | 16 | 0.16 | 0.320 | 0.00800 |
| M7 | 80nm | 40nm | 60nm | 11 | 0.17 | 0.440 | 0.00425 |
| M8 | 80nm | 40nm | 60nm | 11 | 0.17 | 0.440 | 0.00425 |
| M9 | 160nm | 80nm | 100nm | 11 | 0.19 | 0.880 | 0.00238 |
| M10 | 160nm | 80nm | 100nm | 0.4 | 0.35 | 0.032 | 0.00438 |
| M11 | 800nm | 400nm | 800nm | 0.4 | 0.35 | 0.160 | 0.00088 |
| M12 | 800nm | 400nm | 800nm | 0.4 | 0.35 | 0.160 | 0.00088 |

**Conversion formulas:**
- RPERSQ (Ω/sq) = R_per_μm × Width_μm
- CPERSQDIST (pF/μm²) = C_per_μm_fF / Width_μm / 1000

### 2.2 Utility Cells

| File | Contents |
|------|----------|
| `lef/n5_utility_cells.lef` | LEF macros: FILLx1/x2/x4, TAPx1, TIE_HI, TIE_LO, ENDCAP_L/R, DECAPx2 |
| `lib/n5_utility_cells_tt_0p5v_25c.lib` | Liberty timing for all utility cells |
| `verilog/n5_utility_cells.v` | Behavioral Verilog for Yosys |
| `cdl/n5_utility_cells.cdl` | CDL netlists for LVS |

**Cell specifications:**

| Cell | Class | Size (sites) | Area (nm²) | Logic |
|------|-------|-------------|------------|-------|
| FILLx1 | CORE SPACER | 1 | 44×140 | None |
| FILLx2 | CORE SPACER | 2 | 88×140 | None |
| FILLx4 | CORE SPACER | 4 | 176×140 | None |
| TAPx1 | CORE WELLTAP | 1 | 44×140 | None |
| TIE_HI | CORE | 1 | 44×140 | Y=1 |
| TIE_LO | CORE | 1 | 44×140 | Y=0 |
| ENDCAP_L | CORE ENDCAP PRE | 1 | 44×140 | None |
| ENDCAP_R | CORE ENDCAP POST | 1 | 44×140 | None |
| DECAPx2 | CORE ANTENNACELL | 2 | 88×140 | None |

### 2.3 SDC Constraints

| File | Description |
|------|-------------|
| `sdc/hamming_cuboid_r4.sdc` | Combinational design constraints with virtual clock (200ps period) |

### 2.4 OpenLane2 Configurations

| File | Description |
|------|-------------|
| `openlane2/config_pass_a.json` | Pass A: Structure-preserving (SYNTH_NO_FLAT=true, AREA strategy) |
| `openlane2/config_pass_b.json` | Pass B: Yosys-optimized (DELAY 3 strategy, buffering+sizing enabled) |

---

## 3. Remaining Open Items

### 3.1 High Priority (Required for Clean Flow)

| Item | Status | Notes |
|------|--------|-------|
| GDS for utility cells | NOT CREATED | Need Magic layouts or KLayout scripts. Flow can run synthesis+P&R without GDS but cannot produce final GDSII merge. |
| OpenLane2 PDK compat bypass | NOT DONE | May need to patch `pdk_compat.py` or set PDK env var to bypass auto-detection. |
| Buffer cell for CTS | N/A | Design is combinational — no CTS needed. |
| Antenna diode cell | NOT CREATED | May cause antenna DRC violations. Can set `DIODE_CELL=""` to skip. |

### 3.2 Medium Priority (Quality Improvements)

| Item | Status | Notes |
|------|--------|-------|
| FF/SS Liberty corners | NOT CREATED | Run `characterize_5x5.py` with FF/SS BSIM-CMG models for multi-corner STA. |
| Fused cells in LEF/Liberty | NOT CREATED | Need LEF extraction from Magic layouts + Liberty characterization for Pass A to use fused cells directly. |
| Via resistance in LEF | APPROXIMATED | Via resistance not specified in LEF (uses default). Should add RESISTANCE to CUT layers. |
| Doubled-width M1-M4 variant | NOT CREATED | Docx specifies doubled widths for power optimization. Would need second tech LEF variant. |

### 3.3 Low Priority (Polish)

| Item | Status | Notes |
|------|--------|-------|
| Pin placement config | NOT CREATED | For controlled I/O pin placement on die edges. |
| Power grid config | DEFAULT | M11/M12 power stripes not explicitly configured. |
| DRC rule deck for Magic | EXISTS | `asap5.tech` covers DRC but only for M1-M5 layers. |
| LVS rule deck | EXISTS | Calibre rules in PDK, but OpenLane2 uses Netgen. |

---

## 4. File Tree

```
n5_integration/
├── docs/
│   └── gap_analysis.md          ← this file
├── lef/
│   ├── n5_tech.lef              ← 12-metal tech LEF (N5 RC calibrated)
│   └── n5_utility_cells.lef     ← 9 utility cell LEF macros
├── lib/
│   └── n5_utility_cells_tt_0p5v_25c.lib  ← Liberty for utility cells
├── verilog/
│   └── n5_utility_cells.v       ← Behavioral Verilog for Yosys
├── cdl/
│   └── n5_utility_cells.cdl     ← CDL netlists for LVS
├── sdc/
│   └── hamming_cuboid_r4.sdc    ← Combinational SDC (virtual clock)
├── openlane2/
│   ├── config_pass_a.json       ← Structure-preserving synthesis
│   └── config_pass_b.json       ← Yosys-optimized synthesis
├── gds/
│   └── (empty — utility cell GDS TBD)
└── README.md                    ← (TBD)
```

---

## 5. How to Run

### Prerequisites
```bash
# Ensure Nix environment is available
cd ~/openlane2
nix develop
```

### Pass A — Structure-Preserving
```bash
cd /Users/bruce/CLAUDE/asap5/stdcells/n5_integration
python3 -m openlane --run-tag pass_a openlane2/config_pass_a.json
```

### Pass B — Yosys-Optimized
```bash
cd /Users/bruce/CLAUDE/asap5/stdcells/n5_integration
python3 -m openlane --run-tag pass_b openlane2/config_pass_b.json
```

### Compare PPA
After both runs complete, compare:
- Area: `report_design_area` from each run
- Timing: WNS/TNS from STA reports
- Power: `report_power` from each run
- Cell count: synthesis statistics
