# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

EDA workspace for circuit simulation and physical-design-aware digital logic verification targeting advanced FinFET/GAA process nodes (TSMC N5 5nm + ASAP5 5nm GAA nanosheet). Contains:

- **Custom Verilog designs** (`iverilog/`) — gate-level Hamming distance and popcount circuits with embedded TSMC N5 process annotations (metal stack RC, device Cg/Cd/Cs, Id_on/Id_off, multi-Vt)
- **ngspice BSIM-CMG models** (`spice/`) — TSMC N5 FinFET compact models calibrated to design targets, with device and inverter test harnesses
- **ASAP5 PDK** (`asap5/asap5PDK_r0p4/`) — Arizona State 5nm GAA nanosheet predictive PDK (BSIM-CMG level=72 geomod=3, 4 Vt flavors, 5 corners, 12 metals)
- **ASAP5 ngspice wrapper** (`asap5/spice/asap5_ngspice.lib`) — corner-selectable model library with absolute paths for ngspice
- **ASAP5 Magic tech file** (`asap5/magic/asap5.tech`) — 2917-line tech file for Magic VLSI (16 planes, 60+ types, 366 DRC rules, full RC extraction)
- **ASAP5 Standard Cell Library** (`asap5/stdcells/`) — 12 basic cells + 4 fused Hamming cells, layouts in Magic, extracted parasitics, Liberty .lib at TT/0.5V/25C
- **Magic VLSI** (`magic/`) — built from source v8.3.624 for macOS arm64, installed at `magic_install/`
- **Xyce SPICE simulator** (`install_xyce.sh`) — automated build of Sandia's Xyce circuit simulator and its dependencies (SuiteSparse, Trilinos)
- **Icarus Verilog** (`iverilog/iverilog/`) — upstream source of the open-source Verilog simulator (do not modify)
- **GTKWave setup** (`wv/install_vw.sh`) — waveform viewer installation for macOS

## Simulation Commands

All Verilog simulations use Icarus Verilog (`iverilog` + `vvp`), SystemVerilog-2012 mode. Run from `iverilog/`:

```bash
# Hamming distance — N5 floorplan variant
iverilog -g2012 -o ham_dis_64.vvp hamming_distance_64_n5_floorplan.v tb_hamming_distance_64.v && vvp ham_dis_64.vvp

# Hamming distance — 4D crosspoint variant (M1-M4 only)
iverilog -g2012 -o ham_dis_64.vvp hamming_distance_64_4d_n5_floorplan.v tb_hamming_distance_64.v && vvp ham_dis_64.vvp

# 64-bit radix-4 cuboid variant
iverilog -g2012 -o ham_dis_64.vvp 64b_cube_rad4.v tb_64b_cube_rad4.v && vvp ham_dis_64.vvp
```

Testbenches use golden-model comparison + 50,000 random vectors. Output VCD files can be viewed with GTKWave.

## Build Commands

```bash
# Install Icarus Verilog + GTKWave
brew install icarus-verilog  # or run iverilog/install_iverilog_gtkwav.sh

# Build Xyce SPICE simulator from source
./install_xyce.sh            # serial build
./install_xyce.sh --mpi      # with MPI parallel support
./install_xyce.sh --jobs 8   # custom core count
```

## ASAP5 5nm Cell Flow (Magic + ngspice + GTKWave)

Complete layout→extract→characterize→waveform flow for ASAP5 GAA nanosheet cells. Use skill `/5nm-cell-flow` for full reference.

```bash
# Layout + extract in Magic
/Users/bruce/CLAUDE/magic_install/bin/magic -dnull -noconsole -T asap5 <<'EOF'
load CELLNAME
extract all
ext2spice lvs
ext2spice -f ngspice -o CELLNAME_ext.spice
quit -noprompt
EOF

# Characterize (5x5 slew/load Liberty tables)
cd asap5/stdcells && python3 characterize_5x5.py

# View waveforms
gtkwave CELLNAME.vcd &
```

### ASAP5 Standard Cell Library

12 basic cells + 4 fused Hamming cells at TT/0.5V/25C:

| Cell | Type | Extracted tpd @1fF/100ps |
|------|------|--------------------------|
| INVx1/x2/x4 | 2T inverter | 83/63/49 ps |
| NAND2x1, NOR2x1 | 4T | 108/118 ps |
| AOI21x1, OAI21x1 | 6T compound | 258/254 ps |
| XOR2x1/x2, XNOR2x1/x2 | 8T TG | 90-145 ps |
| MUX21x1 | 8T TG+INV | 205 ps |
| FUSED_A/E/F/G | 38-48T Hamming | 88-131 ps |

Liberty file: `asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib`

### ASAP5 vs TSMC N5 Key Differences

| Parameter | ASAP5 (GAA) | TSMC N5 (FinFET) |
|-----------|-------------|------------------|
| geomod | 3 (nanosheet) | 1 (FinFET) |
| VDD | 0.7V nom | 0.75V nom |
| CPP | 44nm | 48nm |
| Metals | 12 | 13 |
| u0 NMOS | 0.055 m²/Vs | 0.030 m²/Vs |
| rdsw NMOS | 25 Ω·μm | 150 Ω·μm |
| eta0 (DIBL) | 7.7e-6 | 0.035 |
| Vt flavors | 4 (SLVT/LVT/RVT/SRAM) | 1 (LVT) |

## SPICE Simulation (ngspice + BSIM-CMG)

BSIM-CMG (level=72, version=107) FinFET compact models in `spice/`. Run from `spice/`:

```bash
ngspice test_n5_device.sp      # Id-Vgs sweeps at 0.75V and 0.40V
ngspice test_n5_inverter.sp    # CMOS inverter VTC + propagation delay
ngspice test_n5_caps.sp        # Cg, Cd, Cs extraction via AC analysis
```

Model library (`tsmc_n5_bsimcmg.lib`) supports 5 corners: `tt`, `ff`, `ss`, `sf`, `fs`. Multi-fin via `nfin=N`. Calibrated to device data in .v file headers.

## SPICE Simulation (Xyce + BSIM-CMG)

Xyce (Sandia's parallel electronic simulator) built from source at `~/xyce-stack/install/xyce/bin/Xyce`. Supports BSIM-CMG level=107 (FinFET/GAA). **Critical: Xyce uses `level = 107` for BSIM-CMG, not `level = 72` as in HSPICE/ngspice.**

```bash
# ASAP5 inverter simulations (from asap5/spice/)
Xyce test_asap5_inv_xyce_dc.cir       # DC VTC sweep @0.7V → V_trip=347mV
Xyce test_asap5_inv_xyce_tran.cir     # Transient delay → tpd≈25.7ps @1.6fF

# Convert HSPICE models for Xyce
sed 's/level = 72/level = 107/' hspice_model.pm > xyce_model.pm

# Suppress verbose BSIM-CMG info messages
Xyce -max-warnings 10 netlist.cir
```

Pre-converted ASAP5 Xyce models: `asap5/spice/xyce_models/` (LVT TT corner).

**Key Xyce rules:** One analysis type per netlist (no mixed .DC + .TRAN). No `.control`/`.endc` blocks. Use `.PRINT` and `.MEASURE` directly in deck.

### Xyce High-Precision Settings (BSIM-CMG Gold Standard)

All Xyce simulation files include high-accuracy solver options for FinFET/GAA BSIM-CMG models. These prioritize LTE reduction and tight nonlinear convergence over simulation speed.

```spice
* --- Nonlinear Solver (Newton-Raphson) ---
* RELTOL=1e-6: tight relative convergence (default 1e-3)
* ABSTOL=1e-12: absolute floor for leakage current accuracy
.OPTIONS NONLIN RELTOL=1e-6 ABSTOL=1e-12

* --- Time Integration (LTE Control) — transient only ---
* METHOD=trap: best energy conservation for digital transitions
* TRTOL=1.0: strict adaptive stepping (default 7.0)
* ABSTOL=1e-15: sub-femtoamp time integration precision
.OPTIONS TIMEINT METHOD=trap RELTOL=1e-6 ABSTOL=1e-15 TRTOL=1.0

* --- Charge & Voltage Tolerances ---
* VNTOL=1e-9: nanovolt node resolution
* CHGTOL=1e-16: precise multi-gate charge conservation
* GMIN=1e-15: low conductance floor, won't mask leakage
.OPTIONS DEVICE VNTOL=1e-9 CHGTOL=1e-16 GMIN=1e-15

* --- Max time step (transient) ---
* DTMAX=1p prevents aliasing fast 5ps rise/fall transitions
.TRAN 0.5p 400p 0 1p
```

| Parameter | High-Precision | Default | Why |
|-----------|---------------|---------|-----|
| RELTOL (NONLIN) | 1e-6 | 1e-3 | Sub-mV convergence |
| ABSTOL (NONLIN) | 1e-12 | 1e-6 | Leakage current floor |
| TRTOL | 1.0 | 7.0 | Strict LTE control |
| ABSTOL (TIMEINT) | 1e-15 | 1e-9 | Charge-based model accuracy |
| VNTOL | 1e-9 | 1e-6 | Nanovolt node precision |
| CHGTOL | 1e-16 | 1e-14 | FinFET gate charge conservation |
| GMIN | 1e-15 | 1e-12 | Won't mask sub-pA leakage |
| METHOD | trap | trap | Energy-conserving integration |
| DTMAX | 1p | adaptive | Captures 5ps edges |

**Performance note:** These settings increase Newton iterations and time steps significantly. For production PD tasks where speed matters, relax to `RELTOL=1e-4`, `TRTOL=7`, `ABSTOL=1e-9`. Use `METHOD=gear` if numerical ringing appears on stiff circuits.

## Skill Workflow for EDA Tasks

Map of available Claude skills to this project's workflows. Invoke these proactively when the task matches.

### RTL-to-GDSII PnR Flow (OpenLane2 + sky130)
- **`/rtl-to-gds-pnr`** — Use when running the complete open-source RTL-to-GDSII flow with OpenLane2. Covers Nix environment setup, config.json creation, sky130/gf180mcu PDK selection, Classic flow execution (78 stages: Yosys synthesis → OpenROAD P&R → Magic/KLayout DRC → Netgen LVS → STA signoff), metrics interpretation, and common issue debugging. Proven on pm32 signed multiplier design (1024/1024 tests, 78/78 flow stages, all signoff clean).

### Xyce Circuit Simulation (BSIM-CMG FinFET/GAA)
- **`/xyce-sim`** — Use when running SPICE simulations with Xyce. Covers BSIM-CMG model adaptation (level 72→107), DC/transient/AC analysis, .MEASURE statements, ASAP5 GAA and TSMC N5 FinFET model setup, multi-corner simulation, and Xyce build troubleshooting. Critical reference for Xyce vs ngspice syntax differences.

### 5nm Cell Flow (Layout → Extract → Characterize → Waveform)
- **`/5nm-cell-flow`** — Use when laying out standard cells or fused cells for ASAP5 5nm in Magic, extracting parasitics, running 5x5 Liberty characterization, or viewing analog waveforms in GTKWave. Covers diffusion sharing for Cg/Cd/Cs minimization, Magic extraction, ngspice simulation, VCD/FSDB waveform generation. Full automated flow from layout to Liberty .lib.

### PPA Analysis & Comparison
- **`/xlsx`** — Use when comparing architectures (N5 vs 4D vs radix-4), tracking PPA across design iterations, or parsing timing/power logs. Build spreadsheets with charts for: fin count vs delay tradeoffs, metal layer RC budgets, buffer insertion impact, Id_on/Id_off across corners and voltages.

### Design Reviews & Presentations
- **`/pptx`** — Use for PPA summary decks, architecture comparison slides, interview prep presentations. Include: block diagrams of crosspoint stages, metal stack assignments, delay breakdown waterfalls, power pie charts.

### Process Specs & Datasheets
- **`/pdf`** — Use when reading/extracting from TSMC design rule manuals, BSIM-CMG documentation, or published IEDM papers. Also for generating polished design documents with embedded tables and figures.

### Micro-Architecture Documentation
- **`/docx`** — Use for writing detailed design specs: physical design methodology, fused-cell architecture descriptions, buffer insertion strategy, wire RC analysis methodology.

### Interactive Design Tools
- **`/frontend-design`** — Use when building interactive visualizations: timing path explorers through the crosspoint stages, metal stack RC calculators, floorplan viewers for fused-cell placement, power/delay Pareto frontends, BSIM-CMG parameter sweepers.

### Architecture Diagrams
- **`/canvas-design`** — Use for creating clean block diagrams: crossbar topologies (3x3, 5x5, 13x13), metal layer assignment views, datapath flow from Stage 1 through Stage 5, fin layout cross-sections.

### Collaborative Specs
- **`/doc-coauthoring`** — Use for structured back-and-forth when writing detailed design proposals, flow documentation for the Xyce+iverilog+ngspice toolchain, or technical trade studies (e.g., 0.40V vs 0.75V design point analysis).

### Topology Visualization
- **`/algorithmic-art`** — Use for generating visual representations of interconnect topologies, crossbar connectivity patterns, wired-OR grid structures, or layout density heatmaps across metal layers.

## Architecture: Verilog Designs

The custom designs implement 64-bit Hamming distance using a **fused-cell + crosspoint** architecture:

1. **Stage 1** (M1/poly): 32 fused Hamming cells — each processes 2 bit-pairs, outputs one-hot {OH0, OH1, OH2}
2. **Stage 2** (M2/M3): Crosspoint matrices — wired-OR via grids convert one-hot to partial popcount
3. **Stage 3** (M4/M5): Radix-4 regrouping — merges byte-level counts
4. **Stage 4** (M5-M8): Hierarchical merge crosspoints (4x4 → 7x7 → 13x13)
5. **Stage 5** (M8/M9): Binary conversion — 25x17 wired-OR grid produces final hd[6:0]

The 4D variant (`hamming_distance_64_4d_n5_floorplan.v`) uses a hypercube crosspoint topology confined to M1-M4 only, leaving M5+ free for power/clock routing.

## TSMC N5 Process Parameters (embedded in .v files)

Key reference values used throughout the designs:

- **Device**: FinFET, fin pitch 25-27nm, CPP 48nm, 5T cell height ~128-135nm
- **Capacitances** (per fin, LVT): Cg ~0.05 fF, Cd ~0.02 fF, Cs ~0.02 fF
- **Currents** (NMOS LVT, per fin): Id_on ~55-75 μA @0.75V, ~5-12 μA @0.40V; Id_off ~10-20 nA
- **Metal stack**: 13 layers, M1-M3 extremely resistive (20-35 Ohm/um at 14nm width), M9-M10 semi-global (0.8-1.5 Ohm/um)
- **Design VDD**: 0.75V nominal, 0.40V near-threshold target
- **Critical insight**: Interconnect RC dominates gate delay for wires > ~2 um; M2/M3 wires > 0.5 um need buffering

## Key Files

| File | Purpose |
|------|---------|
| `iverilog/hamming_distance_64_n5_floorplan.v` | Main N5 design with full process/physical annotations |
| `iverilog/hamming_distance_64_4d_n5_floorplan.v` | 4D hypercube variant, M1-M4 only |
| `iverilog/tb_hamming_distance_64.v` | Shared testbench (golden model + 50k random vectors) |
| `iverilog/64b_cube_rad4.v` | Radix-4 cuboid variant |
| `iverilog/popcount16.v` | 16-bit popcount (N3 FinFET, XOR-AND via ROM) |
| `spice/tsmc_n5_bsimcmg.lib` | BSIM-CMG model library (NFET/PFET, 5 corners) |
| `spice/test_n5_device.sp` | Device Id-Vgs/Id-Vds characterization |
| `spice/test_n5_inverter.sp` | Inverter VTC + transient delay at 0.75V and 0.40V |
| `spice/test_n5_caps.sp` | AC capacitance extraction (Cg, Cd, Cs) |
| `install_xyce.sh` | Xyce build automation (SuiteSparse → Trilinos → Xyce) |
| `~/xyce-stack/install/xyce/bin/Xyce` | Xyce simulator binary (built from source) |
| `asap5/spice/xyce_models/` | Xyce-compatible ASAP5 BSIM-CMG models (level=107) |
| `asap5/spice/test_asap5_inv_xyce_dc.cir` | ASAP5 inverter DC VTC for Xyce |
| `asap5/spice/test_asap5_inv_xyce_tran.cir` | ASAP5 inverter transient delay for Xyce |
| `asap5/asap5PDK_r0p4/` | ASAP5 5nm GAA nanosheet PDK (BSIM-CMG, 4 Vt, 5 corners) |
| `asap5/spice/asap5_ngspice.lib` | ngspice-compatible ASAP5 model wrapper (5 corners) |
| `asap5/magic/asap5.tech` | Magic VLSI tech file (2917 lines, 16 planes, 366 DRC rules) |
| `asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib` | Liberty timing/power (12 cells, 5x5 tables) |
| `asap5/stdcells/spice/extracted/` | Extracted SPICE subcircuits with layout parasitics |
| `asap5/stdcells/layouts/` | Magic layouts (12 basic + 4 fused Hamming cells) |
| `asap5/stdcells/spice/fused/` | Fused Hamming cell variants A/E/F/G (38-48T) |
| `asap5/stdcells/characterize_5x5.py` | 5x5 Liberty characterization engine |
| `magic_install/bin/magic` | Magic VLSI v8.3.624 (built for macOS arm64) |
| `~/my_designs/pm32/pm32.v` | Signed 32x32 serial-parallel multiplier (OpenLane2 design) |
| `~/my_designs/pm32/spm.v` | SPM core: 32-stage carry-save chain + TCMP |
| `~/my_designs/pm32/tb_pm32.v` | Testbench (1024 signed vectors, NBA-safe timing) |
| `~/my_designs/pm32/config.json` | OpenLane2 config (sky130, 40 MHz, meta v2) |
| `~/openlane2/` | OpenLane2 repo (v2.3.10, Nix-based ASIC flow) |
