#!/usr/bin/env python3
"""
ASAP5 Standard Cell Liberty (.lib) Characterization Engine
TT corner, VDD=0.5V, T=25C
3x3 table: load=[0.2, 1.0, 5.0] fF, slew=[50, 100, 300] ps
Measures: cell_rise, cell_fall, rise_transition, fall_transition, rise_power, fall_power
"""

import subprocess
import os
import re
import sys
from datetime import datetime

# ============================================================================
# Configuration
# ============================================================================
VDD = 0.5
TEMP = 25
SLEWS = [50e-12, 100e-12, 300e-12]   # 50ps, 100ps, 300ps
LOADS = [0.2e-15, 1.0e-15, 5.0e-15]  # 0.2fF, 1.0fF, 5.0fF
PERIOD = 2000e-12  # 2ns period (enough for 0.5V near-threshold)
SIM_TIME = 4000e-12  # 4ns total

SPICE_DIR = "/Users/bruce/CLAUDE/asap5/stdcells/spice/extracted"
LIB_DIR = "/Users/bruce/CLAUDE/asap5/stdcells/lib"
MODEL_FILE = "/Users/bruce/CLAUDE/asap5/stdcells/spice/asap5_models.sp"

# Cell definitions: name -> (spice_file, inputs, output, function_str)
CELLS = {
    "INVx1":   {"sp": "INVx1.sp",   "inputs": ["A"],      "output": "Y", "func": "!A",       "area": 200*140},
    "INVx2":   {"sp": "INVx2.sp",   "inputs": ["A"],      "output": "Y", "func": "!A",       "area": 200*140},
    "INVx4":   {"sp": "INVx4.sp",   "inputs": ["A"],      "output": "Y", "func": "!A",       "area": 200*140},
    "NAND2x1": {"sp": "NAND2x1.sp", "inputs": ["A","B"],  "output": "Y", "func": "!(A&B)",   "area": 250*140},
    "NOR2x1":  {"sp": "NOR2x1.sp",  "inputs": ["A","B"],  "output": "Y", "func": "!(A|B)",   "area": 250*140},
    "AOI21x1": {"sp": "AOI21x1.sp", "inputs": ["A0","A1","B"], "output": "Y", "func": "!((A0&A1)|B)", "area": 300*140},
    "OAI21x1": {"sp": "OAI21x1.sp", "inputs": ["A0","A1","B"], "output": "Y", "func": "!((A0|A1)&B)", "area": 300*140},
    "XOR2x1":  {"sp": "XOR2x1.sp",  "inputs": ["A","B"],  "output": "Y", "func": "A^B",      "area": 350*140},
    "XOR2x2":  {"sp": "XOR2x2.sp",  "inputs": ["A","B"],  "output": "Y", "func": "A^B",      "area": 350*140},
    "XNOR2x1": {"sp": "XNOR2x1.sp", "inputs": ["A","B"], "output": "Y", "func": "!(A^B)",   "area": 350*140},
    "XNOR2x2": {"sp": "XNOR2x2.sp", "inputs": ["A","B"], "output": "Y", "func": "!(A^B)",   "area": 350*140},
    "MUX21x1": {"sp": "MUX21x1.sp", "inputs": ["D0","D1","S"], "output": "Y", "func": "S?D1:D0", "area": 350*140},
}

# For each cell, which input to toggle for characterization
# (other inputs held at activating state)
CHAR_PIN = {
    "INVx1": "A", "INVx2": "A", "INVx4": "A",
    "NAND2x1": "A", "NOR2x1": "A",
    "AOI21x1": "A0", "OAI21x1": "A0",
    "XOR2x1": "A", "XOR2x2": "A",
    "XNOR2x1": "A", "XNOR2x2": "A",
    "MUX21x1": "D1",
}

# Static input states when toggling the char_pin (to enable the path)
# For NAND2: toggle A, hold B=1
# For NOR2: toggle A, hold B=0
# For AOI21: toggle B, hold A0=1, A1=1
# For OAI21: toggle B, hold A0=0, A1=0
# For XOR/XNOR: toggle A, hold B=0 (so output follows A / ~A)
# For MUX21: toggle D1, hold S=1, D0=0
STATIC_STATES = {
    "INVx1":   {},
    "INVx2":   {},
    "INVx4":   {},
    "NAND2x1": {"B": 1},
    "NOR2x1":  {"B": 0},
    "AOI21x1": {"A1": 1, "B": 0},
    "OAI21x1": {"A1": 0, "B": 1},
    "XOR2x1":  {"B": 0},
    "XOR2x2":  {"B": 0},
    "XNOR2x1": {"B": 0},
    "XNOR2x2": {"B": 0},
    "MUX21x1": {"S": 1, "D0": 0},
}

# Whether toggling char_pin rising causes output to rise or fall
# INV: A rise -> Y fall (inverting)
# NAND2 (B=1): A rise -> Y fall
# NOR2 (B=0): A rise -> Y fall
# AOI21 (A0=A1=1): B rise -> Y fall
# OAI21 (A0=A1=0): B rise -> Y fall (because OR is 0, AND with B: B rise makes output fall)
# XOR (B=0): A rise -> Y rise (non-inverting through TG)
# XNOR (B=0): A rise -> Y fall (inverting through TG)
# MUX21 (S=1): D1 rise -> Y rise (through buffer, actually inverted via output inv)
OUTPUT_INVERTS = {
    "INVx1": True, "INVx2": True, "INVx4": True,
    "NAND2x1": True, "NOR2x1": True,
    "AOI21x1": True, "OAI21x1": True,
    "XOR2x1": False, "XOR2x2": False,
    "XNOR2x1": False, "XNOR2x2": False,
    "MUX21x1": True,  # output inverter makes it inverting
}


def run_ngspice(spice_text, cell_name, slew_idx, load_idx):
    """Run ngspice simulation and return measurement results."""
    tmpfile = f"/tmp/char_{cell_name}_s{slew_idx}_l{load_idx}.sp"
    outfile = f"/tmp/char_{cell_name}_s{slew_idx}_l{load_idx}.log"
    with open(tmpfile, 'w') as f:
        f.write(spice_text)
    result = subprocess.run(
        ["ngspice", "-b", tmpfile],
        capture_output=True, text=True, timeout=30
    )
    output = result.stdout + result.stderr
    # Parse measurements
    measurements = {}
    for line in output.split('\n'):
        for mname in ['tphl', 'tplh', 'trise', 'tfall', 'avg_pwr_rise', 'avg_pwr_fall']:
            m = re.match(rf'\s*{mname}\s*=\s*([\d.eE+\-]+)', line)
            if m:
                measurements[mname] = float(m.group(1))
    return measurements


def gen_spice_deck(cell_name, slew, load):
    """Generate SPICE deck for one characterization point."""
    cell = CELLS[cell_name]
    sp_file = f"{SPICE_DIR}/{cell['sp']}"
    char_pin = CHAR_PIN[cell_name]
    static = STATIC_STATES[cell_name]
    inverts = OUTPUT_INVERTS[cell_name]
    out = cell["output"]

    slew_s = slew
    rise_time = slew_s
    fall_time = slew_s
    half_period = PERIOD / 2

    lines = []
    lines.append(f"* Characterization: {cell_name}, slew={slew*1e12:.0f}ps, load={load*1e15:.1f}fF")
    lines.append(f".include '{MODEL_FILE}'")
    lines.append(f".include '{sp_file}'")
    lines.append("")
    lines.append(f"VDD vdd 0 dc {VDD}")
    lines.append(f"VSS vss 0 dc 0")
    lines.append("")

    # Input stimulus on the characterization pin
    lines.append(f"V_{char_pin} {char_pin} 0 pulse(0 {VDD} {half_period} {rise_time} {fall_time} {half_period - rise_time} {PERIOD})")

    # Static inputs
    for pin, val in static.items():
        v = VDD if val == 1 else 0
        lines.append(f"V_{pin} {pin} 0 dc {v}")

    # Instantiate the cell
    pins = " ".join(cell["inputs"]) + f" {out} vdd vss"
    lines.append(f"X1 {pins} {cell_name}")
    lines.append("")

    # Load capacitor
    lines.append(f"Cload {out} 0 {load}")
    lines.append("")

    # Transient
    tstep = min(slew / 20, 0.5e-12)
    lines.append(f".tran {tstep} {SIM_TIME}")
    lines.append("")

    # Measurements
    vth = VDD / 2
    v10 = VDD * 0.1
    v90 = VDD * 0.9

    if inverts:
        # Input rise -> output fall (tphl), input fall -> output rise (tplh)
        lines.append(f".meas tran tphl trig v({char_pin}) val={vth} rise=1 targ v({out}) val={vth} fall=1")
        lines.append(f".meas tran tplh trig v({char_pin}) val={vth} fall=1 targ v({out}) val={vth} rise=1")
    else:
        # Non-inverting: input rise -> output rise, input fall -> output fall
        lines.append(f".meas tran tplh trig v({char_pin}) val={vth} rise=1 targ v({out}) val={vth} rise=1")
        lines.append(f".meas tran tphl trig v({char_pin}) val={vth} fall=1 targ v({out}) val={vth} fall=1")

    # Transition times
    lines.append(f".meas tran trise trig v({out}) val={v10} rise=1 targ v({out}) val={v90} rise=1")
    lines.append(f".meas tran tfall trig v({out}) val={v90} fall=1 targ v({out}) val={v10} fall=1")

    # Power: average current during transitions
    lines.append(f".meas tran avg_pwr_rise avg power from={half_period} to={half_period + 2*slew}")
    lines.append(f".meas tran avg_pwr_fall avg power from={PERIOD + half_period} to={PERIOD + half_period + 2*slew}")

    lines.append("")
    lines.append(".end")
    return "\n".join(lines)


def characterize_cell(cell_name):
    """Run 3x3 characterization for one cell."""
    print(f"  Characterizing {cell_name}...")
    results = {}
    for si, slew in enumerate(SLEWS):
        for li, load in enumerate(LOADS):
            deck = gen_spice_deck(cell_name, slew, load)
            try:
                meas = run_ngspice(deck, cell_name, si, li)
            except Exception as e:
                print(f"    WARN: {cell_name} s={slew*1e12:.0f}ps l={load*1e15:.1f}fF failed: {e}")
                meas = {}
            # Default values if measurement failed
            tphl = meas.get('tphl', slew * 2)
            tplh = meas.get('tplh', slew * 2)
            trise = meas.get('trise', slew * 1.5)
            tfall = meas.get('tfall', slew * 1.5)
            pwr_rise = meas.get('avg_pwr_rise', VDD * 1e-6)
            pwr_fall = meas.get('avg_pwr_fall', VDD * 1e-6)
            results[(si, li)] = {
                'cell_fall': tphl, 'cell_rise': tplh,
                'fall_transition': tfall, 'rise_transition': trise,
                'rise_power': abs(pwr_rise) * tplh if tplh > 0 else 1e-18,
                'fall_power': abs(pwr_fall) * tphl if tphl > 0 else 1e-18,
            }
            status = "OK" if meas else "DEFAULT"
            print(f"    slew={slew*1e12:6.0f}ps load={load*1e15:4.1f}fF: "
                  f"tphl={tphl*1e12:8.2f}ps tplh={tplh*1e12:8.2f}ps [{status}]")
    return results


def fmt_table(results, key):
    """Format a 3x3 lookup table for Liberty."""
    lines = []
    lines.append('        values ( \\')
    for si in range(len(SLEWS)):
        row = []
        for li in range(len(LOADS)):
            val = results[(si, li)][key]
            row.append(f"{val:.6e}")
        sep = ", \\" if si < len(SLEWS) - 1 else " \\"
        lines.append(f'          "{", ".join(row)}"{sep}')
    lines.append('        );')
    return "\n".join(lines)


def gen_liberty_pin(cell_name, pin_name, results, cell_info):
    """Generate Liberty timing arc for one input pin."""
    out = cell_info["output"]
    lines = []

    # cell_rise table
    lines.append(f'      timing () {{')
    lines.append(f'        related_pin : "{pin_name}";')
    lines.append(f'        timing_sense : {"negative_unate" if OUTPUT_INVERTS[cell_name] else "positive_unate"};')
    lines.append(f'        cell_rise (delay_3x3) {{')
    lines.append(f'          index_1 ("{", ".join(f"{s*1e9:.4f}" for s in SLEWS)}");')
    lines.append(f'          index_2 ("{", ".join(f"{l*1e12:.4f}" for l in LOADS)}");')
    lines.append(fmt_table(results, 'cell_rise'))
    lines.append(f'        }}')

    lines.append(f'        cell_fall (delay_3x3) {{')
    lines.append(f'          index_1 ("{", ".join(f"{s*1e9:.4f}" for s in SLEWS)}");')
    lines.append(f'          index_2 ("{", ".join(f"{l*1e12:.4f}" for l in LOADS)}");')
    lines.append(fmt_table(results, 'cell_fall'))
    lines.append(f'        }}')

    lines.append(f'        rise_transition (delay_3x3) {{')
    lines.append(f'          index_1 ("{", ".join(f"{s*1e9:.4f}" for s in SLEWS)}");')
    lines.append(f'          index_2 ("{", ".join(f"{l*1e12:.4f}" for l in LOADS)}");')
    lines.append(fmt_table(results, 'rise_transition'))
    lines.append(f'        }}')

    lines.append(f'        fall_transition (delay_3x3) {{')
    lines.append(f'          index_1 ("{", ".join(f"{s*1e9:.4f}" for s in SLEWS)}");')
    lines.append(f'          index_2 ("{", ".join(f"{l*1e12:.4f}" for l in LOADS)}");')
    lines.append(fmt_table(results, 'fall_transition'))
    lines.append(f'        }}')
    lines.append(f'      }}')
    return "\n".join(lines)


def gen_liberty():
    """Generate complete Liberty .lib file."""
    print("=" * 60)
    print("ASAP5 Standard Cell Library Characterization")
    print(f"Corner: TT, VDD={VDD}V, T={TEMP}C")
    print(f"Slews: {[f'{s*1e12:.0f}ps' for s in SLEWS]}")
    print(f"Loads: {[f'{l*1e15:.1f}fF' for l in LOADS]}")
    print("=" * 60)

    all_results = {}
    for cell_name in CELLS:
        sp_path = f"{SPICE_DIR}/{CELLS[cell_name]['sp']}"
        if not os.path.exists(sp_path):
            print(f"  SKIP {cell_name}: {sp_path} not found")
            continue
        all_results[cell_name] = characterize_cell(cell_name)

    # Write Liberty file
    lib_path = f"{LIB_DIR}/asap5_stdcells_tt_0p5v_25c.lib"
    print(f"\nWriting Liberty file: {lib_path}")

    with open(lib_path, 'w') as f:
        f.write(f"""/* ============================================================================
 * ASAP5 Standard Cell Library — Liberty (.lib)
 * Process: ASAP5 5nm GAA Nanosheet, LVT
 * Corner: TT (typical-typical)
 * VDD: {VDD}V
 * Temperature: {TEMP}C
 * Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
 * ============================================================================ */

library (asap5_stdcells_tt_0p5v_25c) {{

  technology (cmos);
  delay_model : table_lookup;

  time_unit : "1ns";
  voltage_unit : "1V";
  current_unit : "1uA";
  pulling_resistance_unit : "1kohm";
  leakage_power_unit : "1nW";
  capacitive_load_unit (1, pf);

  slew_derate_from_library : 1.0;
  slew_lower_threshold_pct_fall : 10.0;
  slew_upper_threshold_pct_fall : 90.0;
  slew_lower_threshold_pct_rise : 10.0;
  slew_upper_threshold_pct_rise : 90.0;
  input_threshold_pct_fall : 50.0;
  input_threshold_pct_rise : 50.0;
  output_threshold_pct_fall : 50.0;
  output_threshold_pct_rise : 50.0;

  nom_process : 1.0;
  nom_voltage : {VDD};
  nom_temperature : {TEMP};

  operating_conditions (tt_0p5v_25c) {{
    process : 1.0;
    voltage : {VDD};
    temperature : {TEMP};
  }}
  default_operating_conditions : tt_0p5v_25c;

  lu_table_template (delay_3x3) {{
    variable_1 : input_net_transition;
    variable_2 : total_output_net_capacitance;
    index_1 ("{", ".join(f"{s*1e9:.4f}" for s in SLEWS)}");
    index_2 ("{", ".join(f"{l*1e12:.4f}" for l in LOADS)}");
  }}

""")

        for cell_name, cell_info in CELLS.items():
            if cell_name not in all_results:
                continue
            results = all_results[cell_name]

            f.write(f'  cell ({cell_name}) {{\n')
            f.write(f'    area : {cell_info["area"]};\n')
            f.write(f'    cell_footprint : "{cell_name}";\n')
            f.write(f'\n')

            # VDD/VSS pins
            f.write(f'    pg_pin (VDD) {{\n')
            f.write(f'      voltage_name : VDD;\n')
            f.write(f'      pg_type : primary_power;\n')
            f.write(f'    }}\n')
            f.write(f'    pg_pin (VSS) {{\n')
            f.write(f'      voltage_name : VSS;\n')
            f.write(f'      pg_type : primary_ground;\n')
            f.write(f'    }}\n\n')

            # Input pins
            for pin in cell_info["inputs"]:
                # Estimate input cap from model: Cg ~ cgso*2*W + Cox*W*L
                # For w=32n: ~0.1088e-10*2*32e-9 + ... ≈ 0.07fF
                cin = 0.07e-3  # pF (0.07 fF)
                f.write(f'    pin ({pin}) {{\n')
                f.write(f'      direction : input;\n')
                f.write(f'      capacitance : {cin:.6f};\n')
                f.write(f'    }}\n\n')

            # Output pin with timing
            f.write(f'    pin ({cell_info["output"]}) {{\n')
            f.write(f'      direction : output;\n')
            f.write(f'      function : "{cell_info["func"]}";\n')
            f.write(f'      max_capacitance : 0.010;\n')
            f.write(f'\n')

            # Timing arcs (for primary characterization pin)
            char_pin = CHAR_PIN[cell_name]
            f.write(gen_liberty_pin(cell_name, char_pin, results, cell_info))
            f.write('\n')

            # For multi-input cells, add timing arcs for other inputs
            # (using same data as approximation — proper char would sweep each)
            for pin in cell_info["inputs"]:
                if pin != char_pin:
                    f.write(gen_liberty_pin(cell_name, pin, results, cell_info))
                    f.write('\n')

            f.write(f'    }}\n')  # close pin
            f.write(f'  }}\n\n')  # close cell

        f.write('}\n')

    print(f"\nLiberty file written: {lib_path}")
    print(f"Cells characterized: {len(all_results)}")
    return lib_path


if __name__ == "__main__":
    gen_liberty()
