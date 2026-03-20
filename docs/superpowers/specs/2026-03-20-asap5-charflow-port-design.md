# ASAP5 Cell Characterization Flow — Port from sky130 (Xyce Engine)

**Date:** 2026-03-20
**Status:** Design
**Source:** `vsdStdCellCharacterizer_sky130` (GitHub: brucefern88-blip)
**Target:** ASAP5 5nm GAA nanosheet PDK, **Xyce BSIM-CMG**, Magic VLSI

---

## 1. Goal

Port the sky130 standard cell characterizer architecture to ASAP5 5nm GAA using **Xyce** (not ngspice) as the simulation engine:
- Fix all identified bugs (30+ issues across 6 files)
- Replace ngspice `.control`/`foreach` harnesses with Xyce `.STEP` + `.MEASURE` architecture
- Use calibrated BSIM-CMG level=107 models with `nfin` (not `w`) device instantiation
- Design and extract a DFF cell in Magic for ASAP5
- Characterize all 13 cells (12 combinational + DFF) producing a complete Liberty .lib at TT/0.7V/25C
- Use 20 parallel agents for implementation

## 2. Scope

### In Scope
- DFF cell layout in Magic (master-slave, TG-based, 16T, LVT)
- DFF extraction via Magic (`ext2spice -f ngspice`) + post-processing for Xyce (`w=` → `nfin=`)
- DFF functional verification via Xyce transient
- Combinational cell characterizer (`combchar.py`) — rewritten for Xyce `.STEP`/`.MEASURE`
- Sequential cell characterizer (`dff_char.py`) — Python-controlled bisection calling Xyce
- Liberty timing/power table generation (`scripts/timing.py`) — reads Xyce `.mt0` output
- Truth table / unate detection (`scripts/truths.py`) — eval/exec removed
- Liberty merge (`scripts/merge.py`) — robust regex, proper file handling
- PDK config layer (`config.py`) with ASAP5 Xyce defaults
- 5x5 slew/load characterization tables
- Single combined Liberty .lib output at TT/0.7V/25C
- Cross-validation: INVx1 tpd against known Xyce reference (13.6ps @ 1fF/5ps edges)

### Out of Scope
- Multi-corner characterization (TT only; `.STEP` infrastructure supports future corners)
- Multi-Vt characterization (LVT only; config supports RVT/SLVT/SRAM)
- Leakage power (no static power in Liberty)
- Noise characterization
- Fused Hamming cells (FUSED_A/E/F/G) — non-standard multi-output; characterize separately
- DFF min_pulse_width constraint (follow-up work)
- OpenSTA/OpenLane integration verification
- ngspice support (Xyce only)

### Simulator & Model Decision

**Simulator:** Xyce (`~/xyce-stack/install/xyce/bin/Xyce`)
- BSIM-CMG level=107 (GAA nanosheet, geomod=3)
- One analysis per deck (separate timing/caps/power netlists)
- `.STEP` for 5x5 sweep cross-product, `.MEASURE` for extraction
- Python-controlled bisection loop for DFF setup/hold

**Models:** Calibrated BSIM-CMG (`*_cal.pm`) at VDD=0.7V
```
asap5/spice/xyce_models/nmos_lvt_tt_cal.pm   # cgso=1.05e-9, cgdo=8.00e-10
asap5/spice/xyce_models/pmos_lvt_tt_cal.pm   # Cg=0.05fF/nfin, Cd=0.02fF/nfin
```

**Device instantiation:** `nfin=N` (BSIM-CMG has no W parameter)
```spice
* WRONG: mn1 Y A VSS VSS nmos_lvt l=16n w=32n
* RIGHT: mn1 Y A VSS VSS nmos_lvt l=16n nfin=2
```

**Include syntax:**
```spice
.include '/Users/bruce/CLAUDE/asap5/spice/xyce_models/nmos_lvt_tt_cal.pm'
.include '/Users/bruce/CLAUDE/asap5/spice/xyce_models/pmos_lvt_tt_cal.pm'
```

## 3. Architecture

### Directory Structure

```
asap5/charflow/
├── config.py                    # PDK + Xyce configuration
├── combchar.py                  # Combinational cell characterizer (Xyce .STEP/.MEASURE)
├── dff_char.py                  # Sequential cell characterizer (Python bisection + Xyce)
├── scripts/
│   ├── timing.py                # Reads Xyce .mt0 → Liberty tables
│   ├── truths.py                # Safe truth table / unate detection
│   ├── merge.py                 # Liberty file merger
│   └── xyce_utils.py            # Xyce netlist generation + .mt0 parsing
├── netlists/                    # Generated Xyce netlists (per cell, gitignored)
├── cells/
│   ├── DFFx1/
│   │   ├── DFFx1.mag            # Magic layout
│   │   ├── DFFx1_ext.spice      # Magic extraction output (has w=)
│   │   ├── DFFx1.spice          # Xyce-ready (nfin=, no w=)
│   │   └── DFFx1.lef            # LEF abstraction
│   └── ...                      # Symlinks/copies of existing stdcell SPICE
├── data/                        # Per-cell Xyce output (.prn, .mt0) (gitignored)
└── lib/
    └── asap5_charflow_tt_0p7v_25c.lib  # Combined Liberty output
```

### Data Flow

```
[Magic .mag] → extract → [.spice w=] → post-process → [.spice nfin=]
                                                            ↓
[config.py] → combchar.py/dff_char.py → [Xyce .cir netlists with .STEP/.MEASURE]
                                                            ↓
                                                     [Xyce binary]
                                                            ↓
                                                   [.mt0 measurement files]
                                                            ↓
                                          scripts/timing.py → [per-cell timing.lib]
                                                            ↓
                                          scripts/merge.py → [combined .lib]
```

### Xyce Harness Architecture (replaces ngspice `.control` loops)

**Combinational cells — single Xyce deck with nested `.STEP`:**

```spice
* INVx1_timing.cir — 5x5 delay/transition characterization
.include '...nmos_lvt_tt_cal.pm'
.include '...pmos_lvt_tt_cal.pm'

.OPTIONS DEVICE GMIN=1e-12
.OPTIONS NONLIN RELTOL=1e-4 ABSTOL=1e-9
.OPTIONS TIMEINT METHOD=trap RELTOL=1e-3 ABSTOL=1e-12
.OPTIONS MEASURE MEASDGT=5

.param vdd_val = 0.7
.param slew_val = 20p
.param load_val = 0.1f

* Nested .STEP creates 5x5 = 25 simulation points
.STEP slew_val LIST 20p 50p 100p 200p 500p
.STEP load_val LIST 0.1f 0.5f 1.0f 2.5f 10.0f

VDD vdd 0 DC {vdd_val}
VSS vss 0 DC 0

* 1.667x slew factor to match 20-80% rise time
.param actual_slew = {slew_val * 1.667}
VIN in 0 PULSE(0 {vdd_val} 200p {actual_slew} {actual_slew} 500p 1400p)

* DUT (subcircuit or inline)
.include 'INVx1.spice'
X1 in out vdd vss INVx1

CLOAD out 0 {load_val}

.TRAN 0.5p 2800p

* Delay measurements (50% VDD)
.MEASURE TRAN cell_fall TRIG V(in) VAL={vdd_val*0.5} RISE=1
+                       TARG V(out) VAL={vdd_val*0.5} FALL=1
.MEASURE TRAN cell_rise TRIG V(in) VAL={vdd_val*0.5} FALL=1
+                       TARG V(out) VAL={vdd_val*0.5} RISE=1

* Transition measurements (20-80% VDD)
.MEASURE TRAN fall_transition TRIG V(out) VAL={vdd_val*0.8} FALL=1
+                             TARG V(out) VAL={vdd_val*0.2} FALL=1
.MEASURE TRAN rise_transition TRIG V(out) VAL={vdd_val*0.2} RISE=1
+                             TARG V(out) VAL={vdd_val*0.8} RISE=1

* Power measurements
.MEASURE TRAN rise_power INTEG I(VDD)*V(vdd) FROM=200p TO=900p
.MEASURE TRAN fall_power INTEG I(VDD)*V(vdd) FROM=900p TO=1600p

.END
```

**Output:** Xyce writes `INVx1_timing.cir.mt0` with 25 rows (one per STEP combination), each containing all `.MEASURE` results. Python parses this into 5x5 Liberty tables.

**Input capacitance — AC deck (separate file, one per pin):**

```spice
* INVx1_caps_A.cir — input capacitance for pin A
.include '...nmos_lvt_tt_cal.pm'
.include '...pmos_lvt_tt_cal.pm'

.OPTIONS DEVICE GMIN=1e-12
.OPTIONS NONLIN RELTOL=1e-4 ABSTOL=1e-9

.param vdd_val = 0.7
VDD vdd 0 DC {vdd_val}
VSS vss 0 DC 0
VIN in 0 DC {vdd_val*0.5} AC 1

.include 'INVx1.spice'
X1 in out vdd vss INVx1

CLOAD out 0 1f

.AC DEC 1 1e9 1e9
.PRINT AC IR(VIN) II(VIN)

.END
```
Python computes: `Cin = |II(VIN)| / (2 * pi * 1e9)` in fF.

**DFF bisection — Python controls the loop:**

```python
# Pseudocode for setup time measurement
for d_slew in slew_vector:
    for clk_slew in slew_vector:
        lower, upper = -200p, 500p   # D-to-CLK offset bounds
        tpd_ref = None
        for iteration in range(20):
            mid = (lower + upper) / 2
            # Write Xyce netlist with D arriving at (CLK_edge + mid)
            write_dff_netlist(d_slew, clk_slew, d_offset=mid, ...)
            # Run Xyce
            run_xyce(netlist_path)
            # Parse .mt0 for CLK-to-Q propagation delay
            tpd = parse_mt0(netlist_path + '.mt0', 'tpd')
            if iteration == 0:
                tpd_ref = tpd
                continue
            tpd_goal = 1.1 * tpd_ref
            error = abs(tpd - tpd_goal) / tpd_goal
            if error < 0.01:  # 1% convergence
                break
            if tpd > tpd_goal:
                lower = mid    # D too close to CLK, move earlier
            else:
                upper = mid    # D too far from CLK, move later
        setup_time = CLK_edge - (d_edge + mid)
```

### SPICE Netlist Post-Processing (Magic → Xyce)

Magic extracts with `w=` parameters. BSIM-CMG requires `nfin=`. Post-processing script:

```python
def magic_to_xyce(input_spice, output_spice):
    """Convert Magic-extracted SPICE to Xyce BSIM-CMG compatible."""
    import re
    with open(input_spice) as f:
        text = f.read()
    # Remove w= parameter, add nfin=2 (ASAP5 minimum)
    text = re.sub(r'\bw=\S+', 'nfin=2', text)
    # Remove any leftover m= multiplier (use nfin for drive strength)
    text = re.sub(r'\bm=(\d+)', lambda m: f'nfin={int(m.group(1))*2}', text)
    with open(output_spice, 'w') as f:
        f.write(text)
```

## 4. DFF Cell Design

### Topology: Positive-Edge Master-Slave D Flip-Flop

```
D ──[TG1]──┬── M ──[TG2]──┬──[INV_OUT]── Q
           [INV1]         [INV2]
            │              │
            └──────────────┘
CLK ──[INV_CLK]── CLKb
```

**Transistor count:** 16T (no Q_N output)
- TG1: 4T (NMOS pass + PMOS pass, complementary clocks)
- INV1: 2T (master feedback inverter, weak)
- TG2: 4T (slave pass gate)
- INV2: 2T (slave feedback inverter, weak)
- INV_CLK: 2T (clock inverter, generates CLKb)
- INV_OUT: 2T (output buffer, drives Q)
- All devices: `nmos_lvt` / `pmos_lvt`, `l=16n`, `nfin=2` (ASAP5 minimum)
- Weak feedback: INV1/INV2 can use `nfin=1` if model supports, else `nfin=2`

**Physical parameters:**
- Cell height: 140 units (matching all existing ASAP5 stdcells)
- Estimated width: ~350-440 units (8-10 CPPs at 44nm each)
- VDD/VSS rails: same geometry as existing cells

**Pins:**
- `D` (input), `CLK` (clock), `Q` (output)
- Power: `VDD`, `VSS` (explicit in subckt)

### Extraction Flow
```bash
cd asap5/charflow/cells/DFFx1/
/Users/bruce/CLAUDE/magic_install/bin/magic -dnull -noconsole -T asap5 <<'EOF'
load DFFx1
extract all
ext2spice lvs
ext2spice -f ngspice -o DFFx1_ext.spice
quit -noprompt
EOF

# Post-process for Xyce: w= → nfin=
python3 -c "
import re
with open('DFFx1_ext.spice') as f: t = f.read()
t = re.sub(r'\bw=\S+', 'nfin=2', t)
with open('DFFx1.spice', 'w') as f: f.write(t)
"
```

### Functional Verification (Xyce transient)
```spice
* DFFx1_verify.cir — functional test
.include '...nmos_lvt_tt_cal.pm'
.include '...pmos_lvt_tt_cal.pm'

.OPTIONS DEVICE GMIN=1e-12
.OPTIONS NONLIN RELTOL=1e-4 ABSTOL=1e-9
.OPTIONS TIMEINT METHOD=trap RELTOL=1e-3 ABSTOL=1e-12

.param vdd_val = 0.7
VDD vdd 0 DC {vdd_val}
VSS vss 0 DC 0

* CLK: 2GHz (500ps period)
VCLK clk 0 PULSE(0 {vdd_val} 100p 5p 5p 245p 500p)

* D: pattern 1,0,1,1,0 with 500ps per bit (one CLK period each)
VD d 0 PWL(0 0 50p {vdd_val} 500p {vdd_val} 550p 0 1000p 0 1050p {vdd_val}
+ 1500p {vdd_val} 1550p {vdd_val} 2000p {vdd_val} 2050p 0 2500p 0)

.include 'DFFx1.spice'
X1 d clk q vdd vss DFFx1

CLOAD q 0 1.0f

.TRAN 0.5p 3000p
.PRINT TRAN V(d) V(clk) V(q)

* Verify CLK-to-Q delay on first rising CLK edge
.MEASURE TRAN tpd_rise TRIG V(clk) VAL={vdd_val*0.5} RISE=1
+                      TARG V(q) VAL={vdd_val*0.5} RISE=1

.END
```

## 5. Bug Fixes

### Critical Bugs (from sky130 characterizer)

| # | File | Bug | Fix |
|---|------|-----|-----|
| 1 | combchar.py:14 | `output_pins = 'Y'` string used as list | Use from LEF; always list |
| 2 | truths.py:54 | `eval(item)` arbitrary code execution | Safe AST expression evaluator |
| 3 | truths.py:92 | `truth_table()` returns `None` if no output change | Always return tuple or raise ValueError |
| 4 | dff.py:~293 | Bisection tolerance 7e-5, too tight for ASAP5 | Change to 0.01 (1% relative error) |
| 5 | dff.py:~264 | Duplicate `meas tran tpd` overwrites | Remove duplicate |
| 6 | timing.py:233 | `active_pin` variable shadowed in loop | Use `parsed_pin` |
| 7 | merge.py:70 | `MergeLib(base, cell)` missing `output_file` | Fix constructor |
| 8 | merge.py:56 | `[-4:]` fragile file-end slice | Use `rstrip()` + detection |

### Security Fixes

| # | Issue | Fix |
|---|-------|-----|
| 9 | `eval()`/`exec()` in truths.py, CDMChar.py | Safe expression evaluator using `operator` module |
| 10 | Shell injection via ngspice `shell rm` | N/A — Xyce has no shell commands; Python handles cleanup |
| 11 | Bare `except:` (8+ instances) | Catch specific exceptions |
| 12 | `subprocess.call()` ignores return code | `subprocess.run(check=True)` |

### Xyce-Specific Rewrites (replaces ngspice control flow)

| sky130/ngspice | ASAP5/Xyce |
|----------------|------------|
| `.control` / `.endc` block | Not supported; `.STEP` + `.MEASURE` in main deck |
| `foreach in_delay ... foreach out_cap ...` | `.STEP slew_val LIST ...` + `.STEP load_val LIST ...` |
| `alter @Vsource[pulse]` | Parameterized: `.param slew_val = 20p` + `.STEP` |
| `alter CLOAD $out_cap` | Parameterized: `.param load_val = 0.1f` + `.STEP` |
| `reset` between runs | Automatic — Xyce re-initializes each `.STEP` combination |
| `meas tran ...` in control block | `.MEASURE TRAN ...` in main deck |
| `echo ... >> file.txt` | Xyce writes `.mt0` file with all measurements |
| `dowhile` bisection loop | Python loop calling Xyce per iteration |
| `let var = expr` | `.param` or Python post-processing |
| `shell rm file` | Python `os.remove()` |

### Parameterization (sky130 → ASAP5/Xyce)

| # | Parameter | sky130 | ASAP5/Xyce |
|---|-----------|--------|------------|
| 1 | VDD | 1.8V | **0.7V** |
| 2 | 50% threshold | 0.9V | **0.35V** |
| 3 | 20% threshold | 0.36V | **0.14V** |
| 4 | 80% threshold | 1.44V | **0.56V** |
| 5 | Near-rail | 1.79V | **0.69V** |
| 6 | Model include | `.include 'sky130nm.lib'` | `.include '...nmos_lvt_tt_cal.pm'` + pmos |
| 7 | Power pins | VPWR/VGND/VPB/VNB | **VDD/VSS** |
| 8 | Simulator | ngspice -b | **Xyce** |
| 9 | Device width | `w=Xn` | **`nfin=N`** (no W for BSIM-CMG) |
| 10 | MOSFET level | 72 (ngspice) | **107** (Xyce BSIM-CMG) |
| 11 | Slew vector | 7 values (0.01n-1.5n) | **5 values: 20p 50p 100p 200p 500p** |
| 12 | Load vector | 7 values (0.5fF-130fF) | **5 values: 0.1f 0.5f 1.0f 2.5f 10.0f** |
| 13 | Sim time | 300ns | **2.8ns** |
| 14 | Sim step | 0.01ns | **0.5ps** |
| 15 | LUT template | `del_1_7_7` | **`delay_5x5`** |
| 16 | Time unit (Liberty) | 1ns | **1ns** (Liberty standard) |
| 17 | Cap unit (Liberty) | 1pF | **1pF** (Liberty standard, values in fF = 0.001pF) |
| 18 | Output format | ngspice text files | **Xyce `.mt0` measurement files** |
| 19 | Sweep mechanism | ngspice `foreach` | **Xyce `.STEP param LIST`** |
| 20 | Bisection | ngspice `dowhile` | **Python loop + Xyce subprocess** |

## 6. Xyce .mt0 Output Parsing

Xyce `.mt0` files are tab-separated with one row per `.STEP` combination:

```
TITLE                   STEP1           STEP2           cell_fall       cell_rise       ...
INVx1_timing.cir        2.00000e-11     1.00000e-16     1.21000e-11     1.50000e-11     ...
INVx1_timing.cir        2.00000e-11     5.00000e-16     1.35000e-11     1.68000e-11     ...
...
```

`scripts/xyce_utils.py` parses this into 5x5 numpy arrays:

```python
def parse_mt0(mt0_path, measure_names, n_slew=5, n_load=5):
    """Parse Xyce .mt0 into {measure_name: np.array(5,5)} dict."""
    import numpy as np
    tables = {name: np.zeros((n_slew, n_load)) for name in measure_names}
    with open(mt0_path) as f:
        header = f.readline().strip().split('\t')
        col_idx = {name: header.index(name) for name in measure_names}
        for i, line in enumerate(f):
            cols = line.strip().split('\t')
            row, col = divmod(i, n_load)
            for name in measure_names:
                tables[name][row, col] = float(cols[col_idx[name]])
    return tables
```

## 7. Optimization

- **Xyce `.STEP`:** Single Xyce invocation per cell produces all 25 measurement points (vs 49 separate ngspice runs in sky130 flow)
- **Parallel cells:** Each cell is an independent Xyce run — 20 agents launch concurrently
- **Subprocess:** `subprocess.run(['Xyce', '-max-warnings', '10', netlist], check=True)`
- **File I/O:** `pathlib.Path` throughout
- **No redundant simulation:** `.MEASURE` extracts all metrics in one transient run (delay + transition + power)
- **DFF bisection:** ~20 Xyce calls per (slew, slew) combination = ~500 total for 5x5

## 8. Agent Parallelization Plan (20 Agents)

### Wave 1: Infrastructure (Agents 1-7, all parallel)

| Agent | Task | Outputs |
|-------|------|---------|
| 1 | Design DFF in Magic + extract + post-process to nfin= | `DFFx1.mag`, `DFFx1.spice` |
| 2 | Write combchar.py (Xyce .STEP/.MEASURE harness gen + .mt0 parsing) | `combchar.py` |
| 3 | Write dff_char.py (Python bisection + Xyce subprocess, pin-configurable) | `dff_char.py` |
| 4 | Write scripts/timing.py (reads .mt0, generates Liberty tables) | `scripts/timing.py` |
| 5 | Write scripts/truths.py (safe expression eval, no exec/eval) | `scripts/truths.py` |
| 6 | Write scripts/merge.py (robust Liberty merge) | `scripts/merge.py` |
| 7 | Write config.py + scripts/xyce_utils.py + directory scaffolding | `config.py`, `xyce_utils.py` |

### Wave 2: Verification (Agents 8-10, after Wave 1)

| Agent | Task | Blocked By |
|-------|------|------------|
| 8 | DFF extraction sanity check + Xyce functional verification | Agent 1 |
| 9 | Smoke-test combchar on INVx1 — verify tpd ≈ 13.6ps @ 1fF/5ps | Agents 2,4,5,6,7 |
| 10 | Configure dff_char.py with actual DFF pin names + test bisection | Agents 1,3 |

### Wave 3: Full Characterization (Agents 11-17, after Wave 2)

| Agent | Cells | Type |
|-------|-------|------|
| 11 | INVx1, INVx2, INVx4 | 3 inverters |
| 12 | NAND2x1, NOR2x1 | 2 gates |
| 13 | AOI21x1, OAI21x1 | 2 compound |
| 14 | XOR2x1, XOR2x2, XNOR2x1, XNOR2x2 | 4 XOR/XNOR |
| 15 | MUX21x1 | 1 mux |
| 16 | DFFx1 setup/hold (bisection) | sequential constraints |
| 17 | DFFx1 delay/transition/power + input cap | sequential timing |

### Wave 4: Integration (Agents 18-20, after Wave 3)

| Agent | Task |
|-------|------|
| 18 | Liberty merge — combine all per-cell .lib |
| 19 | Cross-validate INVx1 against known Xyce reference data |
| 20 | Code review of entire charflow |

## 9. Liberty Output Format

### Library Header
```liberty
library (asap5_charflow_tt_0p7v_25c) {
    technology (cmos);
    delay_model : "table_lookup";
    time_unit : "1ns";
    voltage_unit : "1V";
    current_unit : "1mA";
    capacitive_load_unit (1, pf);
    pulling_resistance_unit : "1kohm";
    leakage_power_unit : "1nW";

    nom_process : 1;
    nom_temperature : 25;
    nom_voltage : 0.7;

    lu_table_template (delay_5x5) {
        variable_1 : input_net_transition;
        variable_2 : total_output_net_capacitance;
        index_1 ("0.020, 0.050, 0.100, 0.200, 0.500");
        index_2 ("0.0001, 0.0005, 0.001, 0.0025, 0.01");
    }
    lu_table_template (power_5x5) {
        variable_1 : input_net_transition;
        variable_2 : total_output_net_capacitance;
        index_1 ("0.020, 0.050, 0.100, 0.200, 0.500");
        index_2 ("0.0001, 0.0005, 0.001, 0.0025, 0.01");
    }
    lu_table_template (vio_5x5) {
        variable_1 : related_pin_transition;
        variable_2 : constrained_pin_transition;
        index_1 ("0.020, 0.050, 0.100, 0.200, 0.500");
        index_2 ("0.020, 0.050, 0.100, 0.200, 0.500");
    }

    /* cells follow */
}
```

### Combinational Cell Example
```liberty
cell ("INVx1") {
    area: 6160;
    pg_pin ("VDD") { pg_type: "primary_power"; voltage_name: "VDD"; }
    pg_pin ("VSS") { pg_type: "primary_ground"; voltage_name: "VSS"; }
    pin ("A") {
        direction: "input";
        capacitance: 0.0001000;
        fall_capacitance: 0.0000980;
        rise_capacitance: 0.0001020;
        max_transition: 0.5000000;
    }
    pin ("Y") {
        direction: "output";
        function: "!A";
        timing () {
            related_pin: "A";
            timing_sense: "negative_unate";
            timing_type: "combinational";
            cell_fall ("delay_5x5") { ... }
            cell_rise ("delay_5x5") { ... }
            fall_transition ("delay_5x5") { ... }
            rise_transition ("delay_5x5") { ... }
        }
        internal_power () {
            related_pin: "A";
            fall_power ("power_5x5") { ... }
            rise_power ("power_5x5") { ... }
        }
    }
}
```

### Sequential Cell Example (DFF)
```liberty
cell ("DFFx1") {
    area: 17600;
    ff ("IQ", "IQ_N") {
        clocked_on: "CLK";
        next_state: "D";
    }
    pg_pin ("VDD") { pg_type: "primary_power"; voltage_name: "VDD"; }
    pg_pin ("VSS") { pg_type: "primary_ground"; voltage_name: "VSS"; }
    pin ("CLK") {
        direction: "input";
        capacitance: ...;
        clock: "true";
    }
    pin ("D") {
        direction: "input";
        capacitance: ...;
        timing () {
            related_pin: "CLK";
            timing_type: "setup_rising";
            rise_constraint ("vio_5x5") { ... }
            fall_constraint ("vio_5x5") { ... }
        }
        timing () {
            related_pin: "CLK";
            timing_type: "hold_rising";
            rise_constraint ("vio_5x5") { ... }
            fall_constraint ("vio_5x5") { ... }
        }
    }
    pin ("Q") {
        direction: "output";
        function: "IQ";
        timing () {
            related_pin: "CLK";
            timing_type: "rising_edge";
            timing_sense: "non_unate";
            cell_rise ("delay_5x5") { ... }
            cell_fall ("delay_5x5") { ... }
            rise_transition ("delay_5x5") { ... }
            fall_transition ("delay_5x5") { ... }
        }
    }
}
```

**Note on multi-input arcs:** For cells with >1 input (NAND2, NOR2, etc.), the characterizer sweeps ALL input pins independently. Each pin gets its own timing/power group in the Liberty output.

## 10. Success Criteria

1. DFF cell passes functional verification in Xyce (Q follows D on rising CLK edge)
2. All 13 cells characterize without Xyce errors
3. Combined Liberty file parses cleanly (no syntax errors)
4. INVx1 tpd ≈ 13.6ps at 1fF load / 5ps edges (within 5% of known Xyce calibrated reference)
5. DFF setup time, hold time, and CLK-to-Q delay are physically reasonable (setup ~10-30ps, hold ~5-15ps, tpd ~15-40ps at 0.7V)
6. No `eval()` or `exec()` in final codebase
7. All subprocess calls check return codes
8. No bare `except:` clauses
9. All device instances use `nfin=N` (no `w=` in any Xyce netlist)
