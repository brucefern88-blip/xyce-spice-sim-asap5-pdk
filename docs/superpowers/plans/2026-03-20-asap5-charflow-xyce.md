# ASAP5 Cell Characterization Flow (Xyce) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Characterize 13 ASAP5 5nm GAA cells (12 combinational + 1 DFF) using Xyce BSIM-CMG, producing a complete Liberty .lib at TT/0.7V/25C.

**Architecture:** Python orchestrator generates Xyce `.STEP`/`.MEASURE` netlists per cell, launches Xyce, parses `.mt0` output into Liberty tables. DFF setup/hold uses Python-controlled bisection loop. 20 parallel agents execute in 4 waves.

**Tech Stack:** Python 3, Xyce (BSIM-CMG level=107), Magic VLSI, calibrated ASAP5 models (`*_cal.pm`)

**Spec:** `docs/superpowers/specs/2026-03-20-asap5-charflow-port-design.md`

---

## File Structure

```
asap5/charflow/
├── __init__.py
├── config.py                     # PDK + Xyce configuration constants
├── combchar.py                   # Combinational cell characterizer (main entry point)
├── dff_char.py                   # Sequential cell characterizer (bisection)
├── run_all.py                    # Orchestrator: runs combchar + dff_char for all cells
├── scripts/
│   ├── __init__.py
│   ├── xyce_utils.py             # Netlist generation, Xyce invocation, .mt0 parsing
│   ├── timing.py                 # .mt0 tables → Liberty text blocks
│   ├── truths.py                 # Safe boolean expression evaluator + unate detection
│   └── merge.py                  # Combine per-cell .lib into library .lib
├── cells/
│   └── DFFx1/
│       ├── DFFx1.mag             # Magic layout (created in Task 1)
│       └── DFFx1.spice           # Xyce-ready subcircuit (nfin=, no w=)
├── spice/                        # Xyce-ready copies of extracted SPICE (nfin=)
│   ├── INVx1.spice
│   ├── ... (all 12 cells)
│   └── convert_all.py            # Batch w= → nfin= converter
├── netlists/                     # Generated Xyce decks (gitignored)
├── data/                         # Xyce output .prn/.mt0 (gitignored)
└── lib/
    ├── base_header.lib           # Liberty header template
    └── asap5_charflow_tt_0p7v_25c.lib  # Final combined output
```

### Key Reference Files (read-only, do NOT modify)

| File | Purpose |
|------|---------|
| `/Users/bruce/CLAUDE/asap5/spice/xyce_models/nmos_lvt_tt_cal.pm` | Calibrated NMOS BSIM-CMG model |
| `/Users/bruce/CLAUDE/asap5/spice/xyce_models/pmos_lvt_tt_cal.pm` | Calibrated PMOS BSIM-CMG model |
| `/Users/bruce/CLAUDE/asap5/stdcells/spice/extracted/*.sp` | Magic-extracted subcircuits (have `w=32n`) |
| `/Users/bruce/CLAUDE/asap5/stdcells/layouts/*.mag` | Magic cell layouts |
| `/Users/bruce/CLAUDE/asap5/magic/asap5.tech` | Magic tech file for ASAP5 |
| `~/xyce-stack/install/xyce/bin/Xyce` | Xyce binary |
| `/Users/bruce/CLAUDE/magic_install/bin/magic` | Magic VLSI binary |

### Key Constants

| Constant | Value |
|----------|-------|
| VDD | 0.7V |
| Slews | 20p, 50p, 100p, 200p, 500p |
| Loads | 0.1f, 0.5f, 1.0f, 2.5f, 10.0f |
| Sim time | 2800ps |
| Sim step | 0.5ps |
| 50% threshold | 0.35V |
| 20% threshold | 0.14V |
| 80% threshold | 0.56V |
| INVx1 reference tpd | 13.6ps @ 1fF/5ps |

---

## WAVE 1: Infrastructure (Tasks 1-7, all parallel)

---

### Task 1: DFF Cell — Magic Layout + Extraction

**Agent 1 — runs independently**

**Files:**
- Create: `asap5/charflow/cells/DFFx1/DFFx1.mag`
- Create: `asap5/charflow/cells/DFFx1/DFFx1.spice`

**Context:** The DFF is a 16T positive-edge master-slave flip-flop using transmission gates. All existing ASAP5 cells use cell height=140 Magic units, `nmos_lvt`/`pmos_lvt`, `l=16n`, `w=32n` (which maps to `nfin=2` for Xyce). Read existing layouts (e.g., `asap5/stdcells/layouts/INVx1.mag`, `XOR2x1.mag`) to understand the VDD/VSS rail geometry, metal layer conventions, and DRC-clean patterns.

**Topology:**
```
D ──[TG1]──┬── M ──[TG2]──┬──[INV_OUT]── Q
           [INV1]         [INV2]
CLK ──[INV_CLK]── CLKb
```

- [ ] **Step 1: Study existing cell layout conventions**

Read these files to understand ASAP5 Magic layout patterns:
```bash
/Users/bruce/CLAUDE/magic_install/bin/magic -dnull -noconsole -T asap5 <<'EOF'
load /Users/bruce/CLAUDE/asap5/stdcells/layouts/INVx1.mag
select top cell
box
what
EOF
```
Also read `/Users/bruce/CLAUDE/asap5/stdcells/layouts/XOR2x1.mag` (8T TG-based, closest topology to DFF).

- [ ] **Step 2: Create DFF Magic layout**

Create `/Users/bruce/CLAUDE/asap5/charflow/cells/DFFx1/DFFx1.mag` with 16 transistors:
- INV_CLK (2T): generates CLKb from CLK
- TG1 (4T): master pass gate, transparent when CLK=0 (NMOS gate=CLKb, PMOS gate=CLK)
- INV1 (2T): master feedback inverter (weak, drives node M back)
- TG2 (4T): slave pass gate, transparent when CLK=1 (NMOS gate=CLK, PMOS gate=CLKb)
- INV2 (2T): slave feedback inverter
- INV_OUT (2T): output buffer driving Q

Cell height: 140 units. Width: 8-10 CPPs (352-440 units). Pin names: D, CLK, Q, VDD, VSS.

Use Magic VLSI scripting (TCL) or interactive layout. Reference the existing `build_xor2x1.tcl` script for TG layout patterns.

- [ ] **Step 3: Extract parasitics**

```bash
cd /Users/bruce/CLAUDE/asap5/charflow/cells/DFFx1/
/Users/bruce/CLAUDE/magic_install/bin/magic -dnull -noconsole -T asap5 <<'EOF'
load DFFx1
extract all
ext2spice lvs
ext2spice -f ngspice -o DFFx1_ext.spice
quit -noprompt
EOF
```

- [ ] **Step 4: Post-process for Xyce (w= → nfin=)**

```bash
python3 -c "
import re
with open('/Users/bruce/CLAUDE/asap5/charflow/cells/DFFx1/DFFx1_ext.spice') as f:
    t = f.read()
t = re.sub(r'\bw=\S+', 'nfin=2', t)
with open('/Users/bruce/CLAUDE/asap5/charflow/cells/DFFx1/DFFx1.spice', 'w') as f:
    f.write(t)
"
```

- [ ] **Step 5: Verify subcircuit has correct pins**

The `.spice` file must have: `.subckt DFFx1 D CLK Q VDD VSS` (exact pin order may vary but must include all 5). Verify:
```bash
head -5 /Users/bruce/CLAUDE/asap5/charflow/cells/DFFx1/DFFx1.spice
```
Expected: `.subckt DFFx1 D CLK Q VDD VSS` with 16 MOSFET lines using `nfin=2`.

---

### Task 2: config.py + xyce_utils.py + Directory Scaffolding

**Agent 7 — runs independently**

**Files:**
- Create: `asap5/charflow/__init__.py`
- Create: `asap5/charflow/config.py`
- Create: `asap5/charflow/scripts/__init__.py`
- Create: `asap5/charflow/scripts/xyce_utils.py`
- Create: `asap5/charflow/spice/convert_all.py`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p /Users/bruce/CLAUDE/asap5/charflow/{scripts,cells/DFFx1,spice,netlists,data,lib}
touch /Users/bruce/CLAUDE/asap5/__init__.py
touch /Users/bruce/CLAUDE/asap5/charflow/__init__.py
touch /Users/bruce/CLAUDE/asap5/charflow/scripts/__init__.py
```

- [ ] **Step 2: Write config.py**

Create `/Users/bruce/CLAUDE/asap5/charflow/config.py`:

```python
"""ASAP5 Xyce characterization configuration."""
from pathlib import Path

# === Paths ===
CHARFLOW_DIR = Path(__file__).parent
XYCE_BIN = Path.home() / 'xyce-stack/install/xyce/bin/Xyce'
NMOS_MODEL = '/Users/bruce/CLAUDE/asap5/spice/xyce_models/nmos_lvt_tt_cal.pm'
PMOS_MODEL = '/Users/bruce/CLAUDE/asap5/spice/xyce_models/pmos_lvt_tt_cal.pm'
SPICE_DIR = CHARFLOW_DIR / 'spice'
NETLIST_DIR = CHARFLOW_DIR / 'netlists'
DATA_DIR = CHARFLOW_DIR / 'data'
LIB_DIR = CHARFLOW_DIR / 'lib'

# === Process ===
VDD = 0.7
THRESH_50 = VDD * 0.5   # 0.35V
THRESH_20 = VDD * 0.2   # 0.14V
THRESH_80 = VDD * 0.8   # 0.56V
NEAR_RAIL = VDD * 0.99  # 0.693V

# === Characterization Vectors ===
SLEWS = [20e-12, 50e-12, 100e-12, 200e-12, 500e-12]
LOADS = [0.1e-15, 0.5e-15, 1.0e-15, 2.5e-15, 10.0e-15]
N_SLEW = len(SLEWS)
N_LOAD = len(LOADS)

# === Simulation ===
SIM_STEP = 0.5e-12      # 0.5ps
SIM_TIME = 2800e-12      # 2.8ns
SLEW_FACTOR = 1.667      # 20-80% → 0-100% conversion

# === Xyce Options ===
XYCE_OPTIONS = """
.OPTIONS DEVICE GMIN=1e-12
.OPTIONS NONLIN RELTOL=1e-4 ABSTOL=1e-9
.OPTIONS TIMEINT METHOD=trap RELTOL=1e-3 ABSTOL=1e-12
.OPTIONS MEASURE MEASDGT=5
"""

# === Liberty ===
TIME_UNIT_NS = 1e-9
CAP_UNIT_PF = 1e-12
LUT_DELAY = 'delay_5x5'
LUT_POWER = 'power_5x5'
LUT_VIO = 'vio_5x5'

# === Power Pins ===
POWER_PINS = ['VDD']
GROUND_PINS = ['VSS']

# === Cell Definitions ===
# name -> {spice_file, inputs, output, func, area_um2}
CELLS = {
    'INVx1':   {'inputs': ['A'],           'output': 'Y', 'func': '!A',         'area': 44*140},
    'INVx2':   {'inputs': ['A'],           'output': 'Y', 'func': '!A',         'area': 88*140},
    'INVx4':   {'inputs': ['A'],           'output': 'Y', 'func': '!A',         'area': 176*140},
    'NAND2x1': {'inputs': ['A', 'B'],      'output': 'Y', 'func': '!(A&B)',     'area': 88*140},
    'NOR2x1':  {'inputs': ['A', 'B'],      'output': 'Y', 'func': '!(A|B)',     'area': 88*140},
    'AOI21x1': {'inputs': ['A0','A1','B'], 'output': 'Y', 'func': '!((A0&A1)|B)', 'area': 132*140},
    'OAI21x1': {'inputs': ['A0','A1','B'], 'output': 'Y', 'func': '!((A0|A1)&B)', 'area': 132*140},
    'XOR2x1':  {'inputs': ['A', 'B'],      'output': 'Y', 'func': 'A^B',        'area': 176*140},
    'XOR2x2':  {'inputs': ['A', 'B'],      'output': 'Y', 'func': 'A^B',        'area': 176*140},
    'XNOR2x1': {'inputs': ['A', 'B'],      'output': 'Y', 'func': '!(A^B)',     'area': 176*140},
    'XNOR2x2': {'inputs': ['A', 'B'],      'output': 'Y', 'func': '!(A^B)',     'area': 176*140},
    'MUX21x1': {'inputs': ['D0','D1','S'], 'output': 'Y', 'func': 'S?D1:D0',   'area': 176*140},
}

# Static input states when toggling active_pin (to enable the timing path)
STATIC_STATES = {
    'INVx1':   {},
    'INVx2':   {},
    'INVx4':   {},
    'NAND2x1': {'B': 1},
    'NOR2x1':  {'B': 0},
    'AOI21x1': {'A1': 1, 'B': 0},
    'OAI21x1': {'A1': 0, 'B': 1},
    'XOR2x1':  {'B': 0},
    'XOR2x2':  {'B': 0},
    'XNOR2x1': {'B': 0},
    'XNOR2x2': {'B': 0},
    'MUX21x1': {'S': 1, 'D0': 0},
}

# Whether active_pin RISE causes output FALL (inverting path)
OUTPUT_INVERTS = {
    'INVx1': True,  'INVx2': True,  'INVx4': True,
    'NAND2x1': True, 'NOR2x1': True,
    'AOI21x1': True, 'OAI21x1': True,
    'XOR2x1': False, 'XOR2x2': False,
    'XNOR2x1': True, 'XNOR2x2': True,
    'MUX21x1': False,
}

# DFF Configuration
DFF_CELL = 'DFFx1'
DFF_CLK_PIN = 'CLK'
DFF_D_PIN = 'D'
DFF_Q_PIN = 'Q'
DFF_BISECTION_ITERS = 20
DFF_BISECTION_TOL = 0.01  # 1% relative error
```

- [ ] **Step 3: Write xyce_utils.py**

Create `/Users/bruce/CLAUDE/asap5/charflow/scripts/xyce_utils.py`:

```python
"""Xyce netlist generation, invocation, and .mt0 parsing."""
import subprocess
import re
from pathlib import Path
import numpy as np
from .. import config


def spice_eng(value):
    """Format a float in SPICE engineering notation."""
    abs_val = abs(value)
    if abs_val == 0:
        return '0'
    prefixes = [(1e-15, 'f'), (1e-12, 'p'), (1e-9, 'n'), (1e-6, 'u'),
                (1e-3, 'm'), (1, ''), (1e3, 'k'), (1e6, 'meg')]
    for scale, suffix in prefixes:
        if abs_val < scale * 1000:
            return f'{value/scale:g}{suffix}'
    return f'{value:g}'


def run_xyce(netlist_path):
    """Run Xyce on a netlist. Raises on failure."""
    result = subprocess.run(
        [str(config.XYCE_BIN), '-max-warnings', '10', str(netlist_path)],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        raise RuntimeError(
            f'Xyce failed on {netlist_path}:\n{result.stderr[-2000:]}'
        )
    return result


def parse_mt0(mt0_path, measure_names, n_rows=None, n_cols=None):
    """Parse Xyce .mt0 measurement file into {name: np.array} dict.

    For 5x5 STEP sweeps: n_rows=5 (slews), n_cols=5 (loads).
    Returns dict of 2D numpy arrays.
    """
    n_rows = n_rows or config.N_SLEW
    n_cols = n_cols or config.N_LOAD
    tables = {name: np.zeros((n_rows, n_cols)) for name in measure_names}

    with open(mt0_path) as f:
        lines = f.readlines()

    # Header line has column names
    header = lines[0].strip().split()
    # Find column indices for requested measures
    col_idx = {}
    for name in measure_names:
        name_upper = name.upper()
        for i, h in enumerate(header):
            if h.upper() == name_upper:
                col_idx[name] = i
                break
        else:
            raise KeyError(f'Measure {name} not found in .mt0 header: {header}')

    # Data lines (skip header, track data index separately for blank lines)
    data_idx = 0
    for line in lines[1:]:
        if not line.strip():
            continue
        cols = line.strip().split()
        row, col = divmod(data_idx, n_cols)
        if row >= n_rows:
            break
        data_idx += 1
        for name in measure_names:
            val_str = cols[col_idx[name]]
            try:
                tables[name][row, col] = float(val_str)
            except ValueError:
                tables[name][row, col] = float('nan')

    return tables


def parse_mt0_single(mt0_path, measure_name):
    """Parse a single scalar measure from a non-STEP .mt0 file."""
    with open(mt0_path) as f:
        header = f.readline().strip().split()
        data = f.readline().strip().split()
    name_upper = measure_name.upper()
    for i, h in enumerate(header):
        if h.upper() == name_upper:
            return float(data[i])
    raise KeyError(f'{measure_name} not found in {mt0_path}')


def parse_ac_prn(prn_path):
    """Parse Xyce AC .prn file for IR/II columns → capacitance."""
    with open(prn_path) as f:
        lines = f.readlines()
    header = lines[0].strip().split()
    data = lines[1].strip().split()
    ir_idx = next(i for i, h in enumerate(header) if 'IR' in h.upper())
    ii_idx = next(i for i, h in enumerate(header) if 'II' in h.upper())
    ir = float(data[ir_idx])
    ii = float(data[ii_idx])
    freq = 1e9  # We always use 1GHz
    import math
    cap = math.sqrt(ir**2 + ii**2) / (2 * math.pi * freq)
    return cap


def gen_timing_netlist(cell_name, active_pin, static_states, output_pin,
                       spice_path, netlist_path):
    """Generate a Xyce timing characterization netlist with .STEP sweeps."""
    all_pins = _read_subckt_pins(spice_path)
    signal_pins = [p for p in all_pins if p not in ('VDD', 'VSS')]

    slew_list = ' '.join(spice_eng(s) for s in config.SLEWS)
    load_list = ' '.join(spice_eng(l) for l in config.LOADS)

    # Build voltage sources for static pins
    static_sources = []
    for pin in signal_pins:
        if pin == active_pin:
            continue
        if pin == output_pin:
            continue
        voltage = config.VDD if static_states.get(pin, 0) == 1 else 0
        static_sources.append(f'V{pin} {pin} 0 DC {voltage}')
    static_str = '\n'.join(static_sources)

    # Instance pins in subcircuit order
    inst_pins = ' '.join(all_pins)

    text = f"""* {cell_name} timing characterization — active pin: {active_pin}
.include '{config.NMOS_MODEL}'
.include '{config.PMOS_MODEL}'

{config.XYCE_OPTIONS}

.param vdd_val = {config.VDD}
.param slew_val = {spice_eng(config.SLEWS[0])}
.param load_val = {spice_eng(config.LOADS[0])}

.STEP slew_val LIST {slew_list}
.STEP load_val LIST {load_list}

VDD vdd 0 DC {{vdd_val}}
VSS vss 0 DC 0

.param actual_slew = {{slew_val * {config.SLEW_FACTOR}}}
V{active_pin} {active_pin} 0 PULSE(0 {{vdd_val}} 200p {{actual_slew}} {{actual_slew}} 500p 1400p)

{static_str}

.include '{spice_path}'
X1 {inst_pins} {cell_name}

CLOAD {output_pin} 0 {{load_val}}

.TRAN {spice_eng(config.SIM_STEP)} {spice_eng(config.SIM_TIME)}

* Delay measurements
.MEASURE TRAN cell_fall TRIG V({active_pin}) VAL={{vdd_val*0.5}} RISE=1
+                       TARG V({output_pin}) VAL={{vdd_val*0.5}} FALL=1
.MEASURE TRAN cell_rise TRIG V({active_pin}) VAL={{vdd_val*0.5}} FALL=1
+                       TARG V({output_pin}) VAL={{vdd_val*0.5}} RISE=1

* Transition measurements
.MEASURE TRAN fall_transition TRIG V({output_pin}) VAL={{vdd_val*0.8}} FALL=1
+                             TARG V({output_pin}) VAL={{vdd_val*0.2}} FALL=1
.MEASURE TRAN rise_transition TRIG V({output_pin}) VAL={{vdd_val*0.2}} RISE=1
+                             TARG V({output_pin}) VAL={{vdd_val*0.8}} RISE=1

* Power: integrate supply current (charge), multiply by VDD in Python
.MEASURE TRAN fall_power INTEG I(VDD) FROM=200p TO=900p
.MEASURE TRAN rise_power INTEG I(VDD) FROM=900p TO=1600p

.END
"""
    Path(netlist_path).write_text(text)
    return netlist_path


def gen_caps_netlist(cell_name, active_pin, static_states, output_pin,
                     spice_path, netlist_path):
    """Generate Xyce AC netlist for input capacitance of one pin."""
    all_pins = _read_subckt_pins(spice_path)
    signal_pins = [p for p in all_pins if p not in ('VDD', 'VSS')]

    static_sources = []
    for pin in signal_pins:
        if pin == active_pin:
            continue
        if pin == output_pin:
            continue
        voltage = config.VDD if static_states.get(pin, 0) == 1 else 0
        static_sources.append(f'V{pin} {pin} 0 DC {voltage}')
    static_str = '\n'.join(static_sources)
    inst_pins = ' '.join(all_pins)

    text = f"""* {cell_name} input capacitance — pin: {active_pin}
.include '{config.NMOS_MODEL}'
.include '{config.PMOS_MODEL}'

.OPTIONS DEVICE GMIN=1e-12
.OPTIONS NONLIN RELTOL=1e-4 ABSTOL=1e-9

.param vdd_val = {config.VDD}
VDD vdd 0 DC {{vdd_val}}
VSS vss 0 DC 0
V{active_pin} {active_pin} 0 DC {{vdd_val*0.5}} AC 1

{static_str}

.include '{spice_path}'
X1 {inst_pins} {cell_name}

CLOAD {output_pin} 0 1f

.AC DEC 1 1e9 1e9
.PRINT AC IR(V{active_pin}) II(V{active_pin})

.END
"""
    Path(netlist_path).write_text(text)
    return netlist_path


def _read_subckt_pins(spice_path):
    """Read .subckt line and return pin list (including VDD, VSS)."""
    with open(spice_path) as f:
        for line in f:
            if line.strip().lower().startswith('.subckt'):
                parts = line.split()
                return parts[2:]  # skip '.subckt' and cell_name
    raise ValueError(f'No .subckt found in {spice_path}')


def magic_to_xyce(input_spice, output_spice):
    """Convert Magic-extracted SPICE to Xyce BSIM-CMG compatible.

    Replaces w=<value> with nfin=2, handles m= multipliers.
    """
    with open(input_spice) as f:
        text = f.read()
    text = re.sub(r'\bw=\S+', 'nfin=2', text)
    text = re.sub(r'\bm=(\d+)', lambda m: f'nfin={int(m.group(1))*2}', text)
    Path(output_spice).write_text(text)
```

- [ ] **Step 4: Write convert_all.py (batch SPICE converter)**

Create `/Users/bruce/CLAUDE/asap5/charflow/spice/convert_all.py`:

```python
#!/usr/bin/env python3
"""Convert all Magic-extracted SPICE files from w= to nfin= for Xyce."""
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).parent.parent))
from scripts.xyce_utils import magic_to_xyce
from pathlib import Path

SRC_DIR = Path('/Users/bruce/CLAUDE/asap5/stdcells/spice/extracted')
DST_DIR = Path(__file__).parent

for src in sorted(SRC_DIR.glob('*.sp')):
    dst = DST_DIR / f'{src.stem}.spice'
    magic_to_xyce(str(src), str(dst))
    print(f'  {src.name} -> {dst.name}')

print(f'Converted {len(list(SRC_DIR.glob("*.sp")))} files.')
```

- [ ] **Step 5: Run converter and verify**

```bash
cd /Users/bruce/CLAUDE/asap5/charflow
python3 spice/convert_all.py
# Verify no w= remains:
grep -r 'w=' spice/*.spice && echo "FAIL: w= found" || echo "PASS: no w= found"
# Verify nfin= present:
grep -c 'nfin=' spice/INVx1.spice  # should be 2
```

---

### Task 3: scripts/truths.py — Safe Expression Evaluator

**Agent 5 — runs independently**

**Files:**
- Create: `asap5/charflow/scripts/truths.py`

- [ ] **Step 1: Write truths.py with safe evaluator**

Create `/Users/bruce/CLAUDE/asap5/charflow/scripts/truths.py`:

```python
"""Safe boolean expression evaluator and unate detection.

Replaces the original truths.py which used eval()/exec() — security risk.
Uses operator module for safe evaluation of logic expressions.
"""
import itertools
import operator
import re


def safe_eval_bool(expr, variables):
    """Evaluate a boolean expression safely using only known operators.

    Supports: &, |, ^, !, ~, and, or, not, parentheses.
    Variables are looked up in the 'variables' dict.

    Returns bool.
    """
    # Normalize operators
    expr = expr.replace('!', ' not ').replace('~', ' not ')
    expr = expr.replace('&', ' and ').replace('|', ' or ')
    expr = expr.replace('^', ' xor ')

    tokens = _tokenize(expr)
    result = _parse_expr(tokens, variables)
    return bool(result)


def _tokenize(expr):
    """Split expression into tokens."""
    return [t for t in re.findall(r'[()]|not|and|or|xor|\w+', expr) if t]


def _parse_expr(tokens, variables):
    """Recursive descent parser for boolean expressions."""
    pos = [0]

    def peek():
        return tokens[pos[0]] if pos[0] < len(tokens) else None

    def consume():
        t = tokens[pos[0]]
        pos[0] += 1
        return t

    def parse_or():
        left = parse_xor()
        while peek() == 'or':
            consume()
            right = parse_xor()
            left = left or right
        return left

    def parse_xor():
        left = parse_and()
        while peek() == 'xor':
            consume()
            right = parse_and()
            left = operator.xor(bool(left), bool(right))
        return left

    def parse_and():
        left = parse_not()
        while peek() == 'and':
            consume()
            right = parse_not()
            left = left and right
        return left

    def parse_not():
        if peek() == 'not':
            consume()
            return not parse_not()
        return parse_atom()

    def parse_atom():
        t = peek()
        if t == '(':
            consume()
            result = parse_or()
            if peek() == ')':
                consume()
            return result
        consume()
        if t in variables:
            return bool(variables[t])
        raise ValueError(f'Unknown variable: {t}')

    return parse_or()


def detect_unate(func_expr, input_pins, active_pin):
    """Detect whether active_pin is positive or negative unate.

    Returns (is_positive_unate: bool, static_pin_values: dict).
    static_pin_values maps non-active input pins to the logic values
    that enable the active_pin's timing path.
    """
    other_pins = [p for p in input_pins if p != active_pin]

    # Try all combinations of other pins to find one where
    # toggling active_pin changes the output
    for combo in itertools.product([False, True], repeat=len(other_pins)):
        pin_vals = dict(zip(other_pins, combo))

        # Evaluate with active_pin=0 and active_pin=1
        pin_vals[active_pin] = False
        out_low = safe_eval_bool(func_expr, pin_vals)

        pin_vals[active_pin] = True
        out_high = safe_eval_bool(func_expr, pin_vals)

        if out_low != out_high:
            # Found a sensitizing condition
            static_values = {p: int(v) for p, v in zip(other_pins, combo)}
            is_positive = (out_high == True and out_low == False)
            return is_positive, static_values

    raise ValueError(
        f'Cannot find sensitizing condition for {active_pin} in {func_expr}'
    )
```

- [ ] **Step 2: Verify with quick test**

```bash
cd /Users/bruce/CLAUDE/asap5/charflow
python3 -c "
from scripts.truths import detect_unate, safe_eval_bool

# INV: !A — A rising → Y falling (negative unate)
pos, static = detect_unate('!A', ['A'], 'A')
assert not pos, f'INV should be negative unate, got positive'
print(f'INV: positive_unate={pos}, static={static}')

# NAND2: !(A&B) — A rising (B=1) → Y falling (negative unate)
pos, static = detect_unate('!(A&B)', ['A','B'], 'A')
assert not pos and static.get('B') == 1
print(f'NAND2: positive_unate={pos}, static={static}')

# XOR2: A^B — A rising (B=0) → Y rising (positive unate)
pos, static = detect_unate('A^B', ['A','B'], 'A')
assert pos and static.get('B') == 0
print(f'XOR2: positive_unate={pos}, static={static}')

print('All unate detection tests passed.')
"
```

---

### Task 4: scripts/timing.py — Liberty Table Generator

**Agent 4 — runs independently**

**Files:**
- Create: `asap5/charflow/scripts/timing.py`

- [ ] **Step 1: Write timing.py**

Create `/Users/bruce/CLAUDE/asap5/charflow/scripts/timing.py`:

```python
"""Generate Liberty timing/power text blocks from Xyce .mt0 data."""
import numpy as np
from .. import config


def liberty_float(f):
    """Format float for Liberty file (10-char width)."""
    if isinstance(f, (bool, type(None))) or not isinstance(f, (int, float)):
        raise ValueError(f'{f!r} is not a float')
    f = float(f)
    if abs(f) >= 1e15 or (abs(f) < 1e-10 and f != 0):
        return f'{f:.6e}'
    return f'{f:.10f}'


def format_index(values, unit_scale):
    """Format index values for Liberty (convert to ns or pF)."""
    return ', '.join(liberty_float(v / unit_scale) for v in values)


def format_table(data_2d, unit_scale=1.0):
    """Format a 2D numpy array as Liberty values() block."""
    rows = []
    for row in data_2d:
        vals = ', '.join(liberty_float(abs(v) / unit_scale) for v in row)
        rows.append(f'"{vals}"')
    return ', \\\n                        '.join(rows)


def gen_timing_block(tables, active_pin, is_positive_unate):
    """Generate a Liberty timing() group from .mt0 parsed tables.

    tables: dict with keys cell_fall, cell_rise, fall_transition,
            rise_transition, fall_power, rise_power — each np.array(5,5)
    """
    unate = 'positive_unate' if is_positive_unate else 'negative_unate'
    slew_idx = format_index(config.SLEWS, config.TIME_UNIT_NS)
    load_idx = format_index(config.LOADS, config.CAP_UNIT_PF)

    def table_block(attr_name, lut_name, data, time_scale):
        vals = format_table(data, time_scale)
        return f"""{attr_name} ("{lut_name}") {{
                    index_1 ("{slew_idx}");
                    index_2 ("{load_idx}");
                    values ({vals});
                }}"""

    ns = config.TIME_UNIT_NS
    timing_str = f"""timing () {{
                related_pin : "{active_pin}";
                timing_sense : "{unate}";
                timing_type : "combinational";
                {table_block('cell_fall', config.LUT_DELAY, tables['cell_fall'], ns)}
                {table_block('cell_rise', config.LUT_DELAY, tables['cell_rise'], ns)}
                {table_block('fall_transition', config.LUT_DELAY, tables['fall_transition'], ns)}
                {table_block('rise_transition', config.LUT_DELAY, tables['rise_transition'], ns)}
            }}"""

    power_str = f"""internal_power () {{
                related_pin : "{active_pin}";
                {table_block('fall_power', config.LUT_POWER, tables['fall_power'], 1.0)}
                {table_block('rise_power', config.LUT_POWER, tables['rise_power'], 1.0)}
            }}"""

    return timing_str, power_str


def gen_pin_block(pin_name, capacitance, fall_cap, rise_cap):
    """Generate Liberty pin() input block with capacitances."""
    return f"""pin ("{pin_name}") {{
            capacitance : {liberty_float(capacitance / config.CAP_UNIT_PF)};
            direction : "input";
            fall_capacitance : {liberty_float(fall_cap / config.CAP_UNIT_PF)};
            max_transition : {liberty_float(config.SLEWS[-1] / config.TIME_UNIT_NS)};
            related_ground_pin : "VSS";
            related_power_pin : "VDD";
            rise_capacitance : {liberty_float(rise_cap / config.CAP_UNIT_PF)};
        }}"""


def gen_cell_liberty(cell_name, area, func_str, input_pins, output_pin,
                     timing_blocks, power_blocks, pin_blocks):
    """Assemble a complete Liberty cell() group."""
    timing_txt = '\n            '.join(timing_blocks)
    power_txt = '\n            '.join(power_blocks)
    pin_txt = '\n        '.join(pin_blocks)

    return f"""    cell ("{cell_name}") {{
        area : {area};
        pg_pin ("VDD") {{ pg_type : "primary_power"; voltage_name : "VDD"; }}
        pg_pin ("VSS") {{ pg_type : "primary_ground"; voltage_name : "VSS"; }}
        {pin_txt}
        pin ("{output_pin}") {{
            direction : "output";
            function : "{func_str}";
            {timing_txt}
            {power_txt}
        }}
    }}
"""
```

---

### Task 5: scripts/merge.py — Liberty Merger

**Agent 6 — runs independently**

**Files:**
- Create: `asap5/charflow/scripts/merge.py`
- Create: `asap5/charflow/lib/base_header.lib`

- [ ] **Step 1: Write base Liberty header**

Create `/Users/bruce/CLAUDE/asap5/charflow/lib/base_header.lib`:

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

    input_threshold_pct_fall : 50.0;
    input_threshold_pct_rise : 50.0;
    output_threshold_pct_fall : 50.0;
    output_threshold_pct_rise : 50.0;
    slew_lower_threshold_pct_fall : 20.0;
    slew_lower_threshold_pct_rise : 20.0;
    slew_upper_threshold_pct_fall : 80.0;
    slew_upper_threshold_pct_rise : 80.0;

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
```

- [ ] **Step 2: Write merge.py**

Create `/Users/bruce/CLAUDE/asap5/charflow/scripts/merge.py`:

```python
"""Merge per-cell Liberty text into a combined library file."""
from pathlib import Path
from .. import config


def merge_liberty(cell_texts, output_path=None):
    """Combine Liberty header + cell blocks into final .lib file.

    cell_texts: list of strings, each a complete cell() group
    output_path: where to write (default: config.LIB_DIR / combined .lib)
    """
    if output_path is None:
        output_path = config.LIB_DIR / 'asap5_charflow_tt_0p7v_25c.lib'

    header_path = config.LIB_DIR / 'base_header.lib'
    header = header_path.read_text()

    cells = '\n'.join(cell_texts)
    combined = f'{header}\n{cells}\n}}\n'

    Path(output_path).write_text(combined)
    return output_path
```

---

### Task 6: combchar.py — Combinational Cell Characterizer

**Agent 2 — runs independently**

**Files:**
- Create: `asap5/charflow/combchar.py`

- [ ] **Step 1: Write combchar.py**

Create `/Users/bruce/CLAUDE/asap5/charflow/combchar.py`:

```python
#!/usr/bin/env python3
"""Combinational cell characterizer using Xyce .STEP/.MEASURE.

For each cell and each input pin:
1. Generate timing netlist (5x5 slew x load .STEP sweep)
2. Generate AC capacitance netlist
3. Run Xyce
4. Parse .mt0 → Liberty timing/power tables
5. Write per-cell Liberty text
"""
import sys
from pathlib import Path
from . import config
from .scripts import xyce_utils, timing, truths


MEASURE_NAMES = [
    'cell_fall', 'cell_rise',
    'fall_transition', 'rise_transition',
    'fall_power', 'rise_power',
]


def characterize_cell(cell_name):
    """Characterize one combinational cell. Returns Liberty cell text."""
    cell_info = config.CELLS[cell_name]
    input_pins = cell_info['inputs']
    output_pin = cell_info['output']
    func_str = cell_info['func']
    area = cell_info['area']

    spice_path = config.SPICE_DIR / f'{cell_name}.spice'
    if not spice_path.exists():
        raise FileNotFoundError(f'SPICE file not found: {spice_path}')

    timing_blocks = []
    power_blocks = []
    pin_blocks = []

    for active_pin in input_pins:
        # Determine unate and static states from logic function
        is_pos, static = truths.detect_unate(func_str, input_pins, active_pin)

        # --- Timing characterization (5x5) ---
        netlist = config.NETLIST_DIR / f'{cell_name}_{active_pin}_timing.cir'
        xyce_utils.gen_timing_netlist(
            cell_name, active_pin, static, output_pin,
            str(spice_path), str(netlist)
        )
        xyce_utils.run_xyce(netlist)

        mt0_path = Path(str(netlist) + '.mt0')
        tables = xyce_utils.parse_mt0(str(mt0_path), MEASURE_NAMES)

        timing_blk, power_blk = timing.gen_timing_block(
            tables, active_pin, is_pos
        )
        timing_blocks.append(timing_blk)
        power_blocks.append(power_blk)

        # --- Input capacitance (AC) ---
        caps_netlist = config.NETLIST_DIR / f'{cell_name}_{active_pin}_caps.cir'
        xyce_utils.gen_caps_netlist(
            cell_name, active_pin, static, output_pin,
            str(spice_path), str(caps_netlist)
        )
        xyce_utils.run_xyce(caps_netlist)

        prn_path = Path(str(caps_netlist) + '.prn')
        cap_val = xyce_utils.parse_ac_prn(str(prn_path))

        pin_blk = timing.gen_pin_block(active_pin, cap_val, cap_val, cap_val)
        pin_blocks.append(pin_blk)

    cell_text = timing.gen_cell_liberty(
        cell_name, area, func_str, input_pins, output_pin,
        timing_blocks, power_blocks, pin_blocks
    )
    return cell_text


def main(cell_names=None):
    """Characterize cells. Returns list of Liberty cell texts."""
    if cell_names is None:
        cell_names = list(config.CELLS.keys())

    config.NETLIST_DIR.mkdir(parents=True, exist_ok=True)
    config.DATA_DIR.mkdir(parents=True, exist_ok=True)

    results = []
    for name in cell_names:
        print(f'Characterizing {name}...')
        cell_text = characterize_cell(name)
        results.append(cell_text)
        # Save per-cell Liberty
        per_cell_path = config.DATA_DIR / f'{name}_timing.lib'
        per_cell_path.write_text(cell_text)
        print(f'  -> {per_cell_path}')

    return results


if __name__ == '__main__':
    cells = sys.argv[1:] if len(sys.argv) > 1 else None
    main(cells)
```

---

### Task 7: dff_char.py — Sequential Cell Characterizer

**Agent 3 — runs independently**

**Files:**
- Create: `asap5/charflow/dff_char.py`

- [ ] **Step 1: Write dff_char.py**

Create `/Users/bruce/CLAUDE/asap5/charflow/dff_char.py`:

```python
#!/usr/bin/env python3
"""DFF characterizer: setup/hold via bisection, delay/power via .STEP.

Uses Python-controlled bisection loop (Xyce has no dowhile).
Each bisection iteration writes a Xyce netlist, runs it, parses .mt0.
"""
import math
from pathlib import Path
from . import config
from .scripts import xyce_utils, timing


def gen_dff_timing_netlist(spice_path, netlist_path):
    """Generate Xyce deck for DFF CLK-to-Q delay with .STEP sweeps."""
    all_pins = xyce_utils._read_subckt_pins(spice_path)
    inst_pins = ' '.join(all_pins)
    slew_list = ' '.join(xyce_utils.spice_eng(s) for s in config.SLEWS)
    load_list = ' '.join(xyce_utils.spice_eng(l) for l in config.LOADS)

    text = f"""* DFF CLK-to-Q delay characterization
.include '{config.NMOS_MODEL}'
.include '{config.PMOS_MODEL}'

{config.XYCE_OPTIONS}

.param vdd_val = {config.VDD}
.param slew_val = {xyce_utils.spice_eng(config.SLEWS[0])}
.param load_val = {xyce_utils.spice_eng(config.LOADS[0])}

.STEP slew_val LIST {slew_list}
.STEP load_val LIST {load_list}

VDD vdd 0 DC {{vdd_val}}
VSS vss 0 DC 0

.param actual_slew = {{slew_val * {config.SLEW_FACTOR}}}
* D goes high well before CLK to ensure setup is met
VD {config.DFF_D_PIN} 0 PULSE(0 {{vdd_val}} 100p {{actual_slew}} {{actual_slew}} 800p 2000p)
* CLK rises after D is stable
VCLK {config.DFF_CLK_PIN} 0 PULSE(0 {{vdd_val}} 500p {{actual_slew}} {{actual_slew}} 500p 2000p)

.include '{spice_path}'
X1 {inst_pins} {config.DFF_CELL}

CLOAD {config.DFF_Q_PIN} 0 {{load_val}}

.TRAN 0.5p 4000p

* CLK-to-Q delays
.MEASURE TRAN cell_rise TRIG V({config.DFF_CLK_PIN}) VAL={{vdd_val*0.5}} RISE=1
+                       TARG V({config.DFF_Q_PIN}) VAL={{vdd_val*0.5}} RISE=1
.MEASURE TRAN cell_fall TRIG V({config.DFF_CLK_PIN}) VAL={{vdd_val*0.5}} RISE=2
+                       TARG V({config.DFF_Q_PIN}) VAL={{vdd_val*0.5}} FALL=1

* Output transitions
.MEASURE TRAN rise_transition TRIG V({config.DFF_Q_PIN}) VAL={{vdd_val*0.2}} RISE=1
+                             TARG V({config.DFF_Q_PIN}) VAL={{vdd_val*0.8}} RISE=1
.MEASURE TRAN fall_transition TRIG V({config.DFF_Q_PIN}) VAL={{vdd_val*0.8}} FALL=1
+                             TARG V({config.DFF_Q_PIN}) VAL={{vdd_val*0.2}} FALL=1

.END
"""
    Path(netlist_path).write_text(text)


def gen_bisection_netlist(spice_path, netlist_path, d_slew, clk_slew,
                          d_offset, load, measure_type='setup_rise'):
    """Generate one Xyce netlist for a single bisection iteration."""
    all_pins = xyce_utils._read_subckt_pins(spice_path)
    inst_pins = ' '.join(all_pins)
    d_slew_actual = d_slew * config.SLEW_FACTOR
    clk_slew_actual = clk_slew * config.SLEW_FACTOR

    # CLK rises at 1000ps; D edge is at (1000ps + d_offset)
    clk_edge = 1000e-12
    d_edge = clk_edge + d_offset
    d_slew_s = xyce_utils.spice_eng(d_slew_actual)
    clk_slew_s = xyce_utils.spice_eng(clk_slew_actual)

    text = f"""* DFF bisection: {measure_type}, d_offset={xyce_utils.spice_eng(d_offset)}
.include '{config.NMOS_MODEL}'
.include '{config.PMOS_MODEL}'

{config.XYCE_OPTIONS}

.param vdd_val = {config.VDD}
VDD vdd 0 DC {{vdd_val}}
VSS vss 0 DC 0

* D signal
VD {config.DFF_D_PIN} 0 PWL(0 0 {xyce_utils.spice_eng(d_edge)} 0
+ {xyce_utils.spice_eng(d_edge + d_slew_actual)} {{vdd_val}}
+ {xyce_utils.spice_eng(d_edge + d_slew_actual + 800e-12)} {{vdd_val}}
+ {xyce_utils.spice_eng(d_edge + d_slew_actual + 800e-12 + d_slew_actual)} 0)

* CLK signal
VCLK {config.DFF_CLK_PIN} 0 PULSE(0 {{vdd_val}} {xyce_utils.spice_eng(clk_edge)} {clk_slew_s} {clk_slew_s} 500p 2000p)

.include '{spice_path}'
X1 {inst_pins} {config.DFF_CELL}

CLOAD {config.DFF_Q_PIN} 0 {xyce_utils.spice_eng(load)}

.TRAN 0.5p 4000p

* CLK-to-Q propagation delay
.MEASURE TRAN tpd TRIG V({config.DFF_CLK_PIN}) VAL={{vdd_val*0.5}} RISE=1
+                  TARG V({config.DFF_Q_PIN}) VAL={{vdd_val*0.5}} RISE=1

* Setup/hold time
.MEASURE TRAN t_constraint TRIG V({config.DFF_D_PIN}) VAL={{vdd_val*0.5}} RISE=1
+                          TARG V({config.DFF_CLK_PIN}) VAL={{vdd_val*0.5}} RISE=1

.END
"""
    Path(netlist_path).write_text(text)


def bisect_constraint(spice_path, d_slew, clk_slew, load, constraint_type='setup'):
    """Run bisection to find setup or hold time for one (d_slew, clk_slew, load) point.

    Returns (constraint_time_seconds, clk_to_q_delay_seconds).
    """
    lower = -500e-12 if constraint_type == 'setup' else -100e-12
    upper = 200e-12 if constraint_type == 'setup' else 500e-12
    tpd_ref = None

    for iteration in range(config.DFF_BISECTION_ITERS):
        mid = (lower + upper) / 2
        netlist = config.NETLIST_DIR / f'dff_bisect_{constraint_type}_{iteration}.cir'
        gen_bisection_netlist(str(spice_path), str(netlist),
                              d_slew, clk_slew, mid, load,
                              f'{constraint_type}_rise')
        try:
            xyce_utils.run_xyce(netlist)
            mt0 = Path(str(netlist) + '.mt0')
            tpd = xyce_utils.parse_mt0_single(str(mt0), 'tpd')
        except (RuntimeError, KeyError, FileNotFoundError):
            # Simulation failed = timing violation
            tpd = 0

        if iteration == 0:
            if tpd <= 0:
                raise RuntimeError('DFF reference simulation failed — check netlist')
            tpd_ref = tpd
            continue

        tpd_goal = 1.1 * tpd_ref

        if tpd <= 0 or tpd > 5 * tpd_ref:
            # Timing violation — tighten
            if constraint_type == 'setup':
                upper = mid
            else:
                lower = mid
            continue

        error = abs(tpd - tpd_goal) / tpd_goal
        if error < config.DFF_BISECTION_TOL:
            break

        if tpd > tpd_goal:
            # Delay too high = D too close to CLK, need more margin
            if constraint_type == 'setup':
                upper = mid   # Move D earlier (more setup margin)
            else:
                lower = mid   # Move D later (more hold margin)
        else:
            # Delay OK = can reduce margin
            if constraint_type == 'setup':
                lower = mid   # Move D closer to CLK
            else:
                upper = mid   # Move D closer to CLK

    # The constraint time is the D-to-CLK offset at convergence
    return abs(mid), tpd


def characterize_dff():
    """Full DFF characterization: delay + setup/hold. Returns Liberty cell text."""
    spice_path = config.CHARFLOW_DIR / 'cells' / 'DFFx1' / 'DFFx1.spice'
    if not spice_path.exists():
        raise FileNotFoundError(f'DFF SPICE not found: {spice_path}')

    config.NETLIST_DIR.mkdir(parents=True, exist_ok=True)

    # --- CLK-to-Q delay (5x5 .STEP) ---
    print('DFF: CLK-to-Q delay characterization...')
    delay_netlist = config.NETLIST_DIR / 'DFFx1_timing.cir'
    gen_dff_timing_netlist(str(spice_path), str(delay_netlist))
    xyce_utils.run_xyce(delay_netlist)

    mt0 = Path(str(delay_netlist) + '.mt0')
    delay_measures = ['cell_rise', 'cell_fall', 'rise_transition', 'fall_transition']
    delay_tables = xyce_utils.parse_mt0(str(mt0), delay_measures)

    # --- Input capacitance (AC) ---
    print('DFF: Input capacitance...')
    for pin_name in [config.DFF_D_PIN, config.DFF_CLK_PIN]:
        caps_netlist = config.NETLIST_DIR / f'DFFx1_{pin_name}_caps.cir'
        static = {}
        if pin_name == config.DFF_D_PIN:
            static = {config.DFF_CLK_PIN: 0}
        else:
            static = {config.DFF_D_PIN: 0}
        xyce_utils.gen_caps_netlist(
            config.DFF_CELL, pin_name, static, config.DFF_Q_PIN,
            str(spice_path), str(caps_netlist)
        )
        xyce_utils.run_xyce(caps_netlist)

    # --- Setup/Hold bisection (5x5 D_slew x CLK_slew) ---
    import numpy as np
    n = config.N_SLEW
    setup_table = np.zeros((n, n))
    hold_table = np.zeros((n, n))

    print('DFF: Setup time bisection...')
    for i, d_slew in enumerate(config.SLEWS):
        for j, clk_slew in enumerate(config.SLEWS):
            t_setup, _ = bisect_constraint(
                spice_path, d_slew, clk_slew, config.LOADS[2], 'setup')
            setup_table[i, j] = t_setup
            print(f'  setup[{i},{j}] = {t_setup*1e12:.1f}ps')

    print('DFF: Hold time bisection...')
    for i, d_slew in enumerate(config.SLEWS):
        for j, clk_slew in enumerate(config.SLEWS):
            t_hold, _ = bisect_constraint(
                spice_path, d_slew, clk_slew, config.LOADS[2], 'hold')
            hold_table[i, j] = t_hold
            print(f'  hold[{i},{j}] = {t_hold*1e12:.1f}ps')

    # --- Assemble Liberty text ---
    ns = config.TIME_UNIT_NS
    slew_idx = timing.format_index(config.SLEWS, ns)
    load_idx = timing.format_index(config.LOADS, config.CAP_UNIT_PF)

    # Parse actual cap values from AC results
    d_prn = Path(str(config.NETLIST_DIR / f'DFFx1_{config.DFF_D_PIN}_caps.cir') + '.prn')
    clk_prn = Path(str(config.NETLIST_DIR / f'DFFx1_{config.DFF_CLK_PIN}_caps.cir') + '.prn')
    d_cap = xyce_utils.parse_ac_prn(str(d_prn)) / config.CAP_UNIT_PF   # convert to pF
    clk_cap = xyce_utils.parse_ac_prn(str(clk_prn)) / config.CAP_UNIT_PF

    def constraint_block(table_2d, attr_name):
        vals = timing.format_table(table_2d, ns)
        return f"""{attr_name} ("{config.LUT_VIO}") {{
                    index_1 ("{slew_idx}");
                    index_2 ("{slew_idx}");
                    values ({vals});
                }}"""

    def delay_block(attr_name, data_2d):
        vals = timing.format_table(data_2d, ns)
        return f"""{attr_name} ("{config.LUT_DELAY}") {{
                    index_1 ("{slew_idx}");
                    index_2 ("{load_idx}");
                    values ({vals});
                }}"""

    cell_text = f"""    cell ("{config.DFF_CELL}") {{
        area : {400*140};
        ff ("IQ", "IQ_N") {{
            clocked_on : "CLK";
            next_state : "D";
        }}
        pg_pin ("VDD") {{ pg_type : "primary_power"; voltage_name : "VDD"; }}
        pg_pin ("VSS") {{ pg_type : "primary_ground"; voltage_name : "VSS"; }}
        pin ("CLK") {{
            capacitance : {timing.liberty_float(clk_cap)};
            clock : "true";
            direction : "input";
        }}
        pin ("D") {{
            capacitance : {timing.liberty_float(d_cap)};
            direction : "input";
            timing () {{
                related_pin : "CLK";
                timing_type : "setup_rising";
                {constraint_block(setup_table, 'rise_constraint')}
                {constraint_block(setup_table, 'fall_constraint')}
            }}
            timing () {{
                related_pin : "CLK";
                timing_type : "hold_rising";
                {constraint_block(hold_table, 'rise_constraint')}
                {constraint_block(hold_table, 'fall_constraint')}
            }}
        }}
        pin ("Q") {{
            direction : "output";
            function : "IQ";
            timing () {{
                related_pin : "CLK";
                timing_type : "rising_edge";
                timing_sense : "non_unate";
                {delay_block('cell_rise', delay_tables['cell_rise'])}
                {delay_block('cell_fall', delay_tables['cell_fall'])}
                {delay_block('rise_transition', delay_tables['rise_transition'])}
                {delay_block('fall_transition', delay_tables['fall_transition'])}
            }}
        }}
    }}
"""
    return cell_text


if __name__ == '__main__':
    text = characterize_dff()
    out = config.DATA_DIR / 'DFFx1_timing.lib'
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text)
    print(f'DFF Liberty written to {out}')
```

---

## WAVE 2: Verification (Tasks 8-10, after Wave 1)

---

### Task 8: DFF Functional Verification (Xyce Transient)

**Agent 8 — blocked on Task 1**

**Files:**
- Create: `asap5/charflow/cells/DFFx1/DFFx1_verify.cir`

- [ ] **Step 1: Verify DFFx1.spice has correct structure**

```bash
cat /Users/bruce/CLAUDE/asap5/charflow/cells/DFFx1/DFFx1.spice
# Must have: .subckt DFFx1 D CLK Q VDD VSS, 16 MOSFET lines with nfin=, no w=
grep -c 'nfin=' /Users/bruce/CLAUDE/asap5/charflow/cells/DFFx1/DFFx1.spice  # expect 16
grep 'w=' /Users/bruce/CLAUDE/asap5/charflow/cells/DFFx1/DFFx1.spice  # expect nothing
```

- [ ] **Step 2: Write and run verification netlist**

Write the verification netlist from the spec (Section 4, Functional Verification) to `asap5/charflow/cells/DFFx1/DFFx1_verify.cir`. Replace `'...'` model paths with full absolute paths. Run:

```bash
~/xyce-stack/install/xyce/bin/Xyce -max-warnings 10 /Users/bruce/CLAUDE/asap5/charflow/cells/DFFx1/DFFx1_verify.cir
```

- [ ] **Step 3: Verify Q follows D on rising CLK**

Check `.prn` output: Q should rise after first CLK rising edge (where D=1), and track the D pattern with one-clock-cycle latency. The `tpd_rise` measure in `.mt0` should be 15-50ps (physically reasonable for ASAP5 @ 0.7V).

---

### Task 9: Smoke-Test combchar on INVx1

**Agent 9 — blocked on Tasks 2-6**

- [ ] **Step 1: Run SPICE converter**

```bash
cd /Users/bruce/CLAUDE/asap5/charflow
python3 spice/convert_all.py
```

- [ ] **Step 2: Run combchar on INVx1 only**

```bash
cd /Users/bruce/CLAUDE/asap5/charflow
python3 -m asap5.charflow.combchar INVx1
```

Or equivalently:
```bash
cd /Users/bruce/CLAUDE
python3 -c "from asap5.charflow.combchar import main; main(['INVx1'])"
```

- [ ] **Step 3: Verify INVx1 tpd matches reference**

Check `data/INVx1_timing.lib` — the cell_fall value at slew=50ps/load=1fF should be approximately 12-15ps (reference: 13.6ps at 5ps edges / 1fF). The exact match won't be identical because characterization uses different input slews.

- [ ] **Step 4: Verify Liberty syntax**

```bash
# Basic syntax check — look for matched braces
python3 -c "
t = open('/Users/bruce/CLAUDE/asap5/charflow/data/INVx1_timing.lib').read()
assert t.count('{') == t.count('}'), 'Mismatched braces'
assert 'cell_fall' in t and 'cell_rise' in t
assert 'delay_5x5' in t
print('Liberty syntax OK')
"
```

---

### Task 10: Configure dff_char.py for Extracted DFF

**Agent 10 — blocked on Tasks 1, 7**

- [ ] **Step 1: Read actual DFF subcircuit pin order**

```bash
head -3 /Users/bruce/CLAUDE/asap5/charflow/cells/DFFx1/DFFx1.spice
```

- [ ] **Step 2: Update config.py DFF pin names if needed**

If the extracted `.subckt` has different pin order or names than `D CLK Q VDD VSS`, update the `DFF_*` constants in `config.py`.

- [ ] **Step 3: Test bisection on one point**

```bash
cd /Users/bruce/CLAUDE
python3 -c "
from asap5.charflow.dff_char import bisect_constraint
from asap5.charflow import config
spice = config.CHARFLOW_DIR / 'cells/DFFx1/DFFx1.spice'
t, tpd = bisect_constraint(str(spice), 50e-12, 50e-12, 1e-15, 'setup')
print(f'Setup time: {t*1e12:.1f}ps, CLK-to-Q: {tpd*1e12:.1f}ps')
"
```

Expected: setup ~10-30ps, tpd ~15-40ps at 0.7V.

---

## WAVE 3: Full Characterization (Tasks 11-17, all parallel after Wave 2)

---

### Task 11: Characterize INVx1, INVx2, INVx4

**Agent 11**

```bash
cd /Users/bruce/CLAUDE
python3 -c "from asap5.charflow.combchar import main; main(['INVx1','INVx2','INVx4'])"
```

Verify: `data/INVx1_timing.lib`, `data/INVx2_timing.lib`, `data/INVx4_timing.lib` all exist with valid Liberty content. INVx2 should show ~50% lower delay than INVx1, INVx4 ~75% lower.

### Task 12: Characterize NAND2x1, NOR2x1

**Agent 12**

```bash
python3 -c "from asap5.charflow.combchar import main; main(['NAND2x1','NOR2x1'])"
```

Verify both pins (A, B) have separate timing arcs. NAND2 cell_fall (A→Y) should be slower than INVx1 due to stacked NMOS.

### Task 13: Characterize AOI21x1, OAI21x1

**Agent 13**

```bash
python3 -c "from asap5.charflow.combchar import main; main(['AOI21x1','OAI21x1'])"
```

Three input pins each (A0, A1, B) — verify 3 timing arcs per cell.

### Task 14: Characterize XOR2x1, XOR2x2, XNOR2x1, XNOR2x2

**Agent 14**

```bash
python3 -c "from asap5.charflow.combchar import main; main(['XOR2x1','XOR2x2','XNOR2x1','XNOR2x2'])"
```

XOR should be positive_unate (A→Y when B=0), XNOR should be negative_unate.

### Task 15: Characterize MUX21x1

**Agent 15**

```bash
python3 -c "from asap5.charflow.combchar import main; main(['MUX21x1'])"
```

Three pins (D0, D1, S) — verify 3 timing arcs.

### Task 16: DFF Setup/Hold Bisection

**Agent 16**

```bash
cd /Users/bruce/CLAUDE
python3 -c "from asap5.charflow.dff_char import characterize_dff; characterize_dff()"
```

This runs ~500 Xyce invocations (20 iterations x 25 (d_slew, clk_slew) points x setup + hold). Expected runtime: 10-30 minutes. Verify setup times are 10-30ps, hold times are 5-15ps.

### Task 17: DFF Delay/Power + Input Cap

**Agent 17** — this runs as part of `characterize_dff()` (the CLK-to-Q .STEP and AC portions). If Task 16 runs `characterize_dff()` fully, this task just validates the results and writes the per-cell .lib.

```bash
cat /Users/bruce/CLAUDE/asap5/charflow/data/DFFx1_timing.lib
# Should have: ff() group, setup/hold constraints, CLK-to-Q delay tables
```

---

## WAVE 4: Integration (Tasks 18-20, after Wave 3)

---

### Task 18: Liberty Merge

**Agent 18**

- [ ] **Step 1: Merge all per-cell Liberty files**

```bash
cd /Users/bruce/CLAUDE
python3 -c "
from pathlib import Path
from asap5.charflow.scripts.merge import merge_liberty
from asap5.charflow import config

cell_texts = []
for lib_file in sorted(config.DATA_DIR.glob('*_timing.lib')):
    cell_texts.append(lib_file.read_text())
    print(f'  Added: {lib_file.name}')

out = merge_liberty(cell_texts)
print(f'Combined Liberty: {out}')
print(f'  Cells: {len(cell_texts)}')
"
```

- [ ] **Step 2: Verify combined Liberty**

```bash
python3 -c "
t = open('/Users/bruce/CLAUDE/asap5/charflow/lib/asap5_charflow_tt_0p7v_25c.lib').read()
assert t.count('{') == t.count('}'), f'Brace mismatch: {t.count(\"{\")} open, {t.count(\"}\")} close'
assert 'library (asap5_charflow_tt_0p7v_25c)' in t
cells = t.count('cell (')
print(f'Liberty valid: {cells} cells, {len(t)} chars')
assert cells == 13, f'Expected 13 cells, got {cells}'
print('PASS')
"
```

---

### Task 19: Cross-Validate INVx1

**Agent 19**

- [ ] **Step 1: Compare against known Xyce reference**

INVx1 calibrated reference: tpd = 13.6ps at 1fF / 5ps edges. The characterization uses different slew points but the 50ps-slew/1fF-load point should give a comparable result.

```bash
python3 -c "
from asap5.charflow.scripts.xyce_utils import parse_mt0
from pathlib import Path

mt0 = '/Users/bruce/CLAUDE/asap5/charflow/netlists/INVx1_A_timing.cir.mt0'
tables = parse_mt0(mt0, ['cell_fall', 'cell_rise'])

# Slew index 1 (50ps), Load index 2 (1fF)
tphl = abs(tables['cell_fall'][1, 2])
tplh = abs(tables['cell_rise'][1, 2])
tpd = (tphl + tplh) / 2

print(f'INVx1 @ 50ps slew / 1fF load:')
print(f'  tpHL = {tphl*1e12:.1f} ps')
print(f'  tpLH = {tplh*1e12:.1f} ps')
print(f'  tpd  = {tpd*1e12:.1f} ps')
print(f'  Reference: 13.6 ps @ 5ps/1fF')

# Allow 50% tolerance since slew differs (50ps vs 5ps)
assert 5e-12 < tpd < 50e-12, f'tpd {tpd*1e12:.1f}ps out of range'
print('PASS: tpd in expected range')
"
```

---

### Task 20: Code Review

**Agent 20 — use superpowers:requesting-code-review**

Review the entire `asap5/charflow/` directory for:
1. No `eval()` or `exec()` anywhere
2. No bare `except:` clauses
3. All `subprocess` calls use `check=True` or explicit error handling
4. No `w=` in any generated Xyce netlist — only `nfin=`
5. Liberty output has matched braces and correct syntax
6. All 13 cells present in combined .lib
7. DFF Liberty has `ff()` group, setup/hold constraints, CLK-to-Q delay
