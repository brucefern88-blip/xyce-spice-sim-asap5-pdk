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
    """Parse Xyce .STEP measurement files into {name: np.array} dict.

    Xyce with .STEP produces separate .mtN files (N=0..n_rows*n_cols-1).
    Each file has lines like: MEASURE_NAME = value
    The base path (mt0_path) should end in '.mt0'; we derive .mt1, .mt2, etc.

    For 5x5 STEP sweeps: n_rows=5 (slews), n_cols=5 (loads).
    Returns dict of 2D numpy arrays.
    """
    n_rows = n_rows or config.N_SLEW
    n_cols = n_cols or config.N_LOAD
    n_total = n_rows * n_cols
    tables = {name: np.zeros((n_rows, n_cols)) for name in measure_names}

    base = str(mt0_path)
    if base.endswith('.mt0'):
        base = base[:-1]  # '...cir.mt'
    else:
        raise ValueError(f'Expected path ending in .mt0, got: {mt0_path}')

    for idx in range(n_total):
        mt_file = f'{base}{idx}'
        row, col = divmod(idx, n_cols)
        measures = _parse_mt_file(mt_file)
        for name in measure_names:
            name_upper = name.upper()
            if name_upper in measures:
                tables[name][row, col] = measures[name_upper]
            else:
                tables[name][row, col] = float('nan')

    return tables


def _parse_mt_file(filepath):
    """Parse a single Xyce .mtN file with 'NAME = VALUE' lines."""
    measures = {}
    with open(filepath) as f:
        for line in f:
            line = line.strip()
            if not line or '=' not in line:
                continue
            name, _, val_str = line.partition('=')
            name = name.strip().upper()
            val_str = val_str.strip()
            try:
                measures[name] = float(val_str)
            except ValueError:
                measures[name] = float('nan')
    return measures


def parse_mt0_single(mt0_path, measure_name):
    """Parse a single scalar measure from a non-STEP .mt0 file.

    Handles both Xyce formats:
      - Tabular: header row then data row (whitespace-delimited)
      - NAME = VALUE: one measure per line
    """
    with open(mt0_path) as f:
        lines = [l.strip() for l in f if l.strip()]
    name_upper = measure_name.upper()

    # Try NAME = VALUE format first
    for line in lines:
        if '=' in line:
            parts = line.split('=', 1)
            if parts[0].strip().upper() == name_upper:
                val_str = parts[1].strip()
                if val_str.upper() == 'FAILED':
                    raise ValueError(f'Measure {measure_name} FAILED in {mt0_path}')
                return float(val_str)

    # Fall back to tabular format
    if len(lines) >= 2:
        header = lines[0].split()
        data = lines[1].split()
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


def _w_to_nfin(match):
    """Convert w=Xn to nfin=N. ASAP5: w=32n=2 fins (minimum), scale linearly."""
    w_str = match.group(0)[2:]  # strip 'w='
    w_str = re.sub(r'[a-zA-Z]+$', '', w_str)  # strip unit suffix (n, u, etc.)
    try:
        w_val = float(w_str)
    except ValueError:
        return 'nfin=2'
    # ASAP5: 32nm width = 2 drawn nanosheets (minimum device)
    nfin = max(2, round(w_val / 16))  # 16nm per nanosheet
    return f'nfin={nfin}'


def magic_to_xyce(input_spice, output_spice):
    """Convert Magic-extracted SPICE to Xyce BSIM-CMG compatible.

    Replaces w=<value> with nfin=N (scaled: w=32n→2, w=64n→4, w=128n→8).
    Handles m= multipliers by converting to nfin.
    """
    with open(input_spice) as f:
        text = f.read()
    text = re.sub(r'\bw=\S+', _w_to_nfin, text)
    text = re.sub(r'\bm=(\d+)', lambda m: f'nfin={int(m.group(1))*2}', text)
    Path(output_spice).write_text(text)
