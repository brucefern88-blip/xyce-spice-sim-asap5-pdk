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
* CLK and D timing for cell_rise (CLK rise 1 captures D=1) and
* cell_fall (CLK rise 2 captures D=0).
* D period = 2 * CLK period so D toggles once per two CLK cycles.
* Setup margin = actual_slew + 200ps between D settling and CLK rising.
.param setup_margin = {{actual_slew + 200p}}
.param clk_pw = {{MAX(500p, actual_slew + 200p)}}
.param clk_per = {{2*actual_slew + clk_pw + setup_margin}}
* D period is 2x CLK period; D pw spans one full CLK cycle
.param d_per = {{2*clk_per}}
.param d_pw = {{clk_per - 2*actual_slew}}
.param d_delay = 100p
.param clk_delay = {{d_delay + actual_slew + setup_margin}}
.param sim_end = {{clk_delay + 2*clk_per + actual_slew + 500p}}
* D goes high before CLK rise 1, low before CLK rise 2
VD {config.DFF_D_PIN} 0 PULSE(0 {{vdd_val}} {{d_delay}} {{actual_slew}} {{actual_slew}} {{d_pw}} {{d_per}})
* CLK rises after D is stable
VCLK {config.DFF_CLK_PIN} 0 PULSE(0 {{vdd_val}} {{clk_delay}} {{actual_slew}} {{actual_slew}} {{clk_pw}} {{clk_per}})

.include '{spice_path}'
X1 {inst_pins} {config.DFF_CELL}

CLOAD {config.DFF_Q_PIN} 0 {{load_val}}

* Initialize DFF to Q=0 (D=0 stored: master=0, MI=VDD, SL=VDD, SI=0, Q=0)
.IC V({config.DFF_Q_PIN})=0 V(X1:SL)={{vdd_val}} V(X1:MI)={{vdd_val}}
+ V(X1:ML)=0 V(X1:SI)=0 V(X1:CLKb)={{vdd_val}}

.TRAN 0.5p {{sim_end}}

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

    # CLK edge must be late enough that d_edge stays positive
    min_clk = abs(d_offset) + d_slew_actual + 200e-12
    clk_edge = max(1000e-12, min_clk)
    d_edge = clk_edge + d_offset
    d_slew_s = xyce_utils.spice_eng(d_slew_actual)
    clk_slew_s = xyce_utils.spice_eng(clk_slew_actual)

    # Scale PULSE pw and period so that tr + pw + tf < period.
    # Only one CLK rising edge is needed, so use a generous period.
    clk_pw = max(500e-12, clk_slew_actual)
    clk_period = 2 * clk_slew_actual + clk_pw + 500e-12
    clk_pw_s = xyce_utils.spice_eng(clk_pw)
    clk_per_s = xyce_utils.spice_eng(clk_period)
    sim_time = clk_edge + clk_period + 1000e-12

    text = f"""* DFF bisection: {measure_type}, d_offset={xyce_utils.spice_eng(d_offset)}
.include '{config.NMOS_MODEL}'
.include '{config.PMOS_MODEL}'

{config.XYCE_OPTIONS}

.param vdd_val = {config.VDD}
VDD vdd 0 DC {{vdd_val}}
VSS vss 0 DC 0

* D signal — stays high until well after CLK captures
VD {config.DFF_D_PIN} 0 PWL(0 0 {xyce_utils.spice_eng(d_edge)} 0
+ {xyce_utils.spice_eng(d_edge + d_slew_actual)} {{vdd_val}}
+ {xyce_utils.spice_eng(clk_edge + clk_slew_actual + 500e-12)} {{vdd_val}}
+ {xyce_utils.spice_eng(clk_edge + clk_slew_actual + 500e-12 + d_slew_actual)} 0)

* CLK signal — pw/period scaled to avoid tr+pw+tf > period
VCLK {config.DFF_CLK_PIN} 0 PULSE(0 {{vdd_val}} {xyce_utils.spice_eng(clk_edge)} {clk_slew_s} {clk_slew_s} {clk_pw_s} {clk_per_s})

.include '{spice_path}'
X1 {inst_pins} {config.DFF_CELL}

CLOAD {config.DFF_Q_PIN} 0 {xyce_utils.spice_eng(load)}

.TRAN 0.5p {xyce_utils.spice_eng(sim_time)}

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
    # Bisection bounds must account for actual slew widths.
    # D actual slew can be up to 833ps; ensure the reference point gives
    # D plenty of time to settle before/after CLK.
    d_slew_actual = d_slew * config.SLEW_FACTOR
    clk_slew_actual = clk_slew * config.SLEW_FACTOR
    margin = d_slew_actual + clk_slew_actual + 200e-12

    if constraint_type == 'setup':
        lower = -margin  # D far before CLK = guaranteed capture
        upper = margin   # D far after CLK = guaranteed fail
    else:
        lower = -margin  # D far before CLK = guaranteed fail for hold
        upper = margin   # D far after CLK = guaranteed capture for hold

    tpd_ref = None

    # Reference simulation: use a safe offset where DFF definitely captures.
    # For both setup and hold, D well before CLK (large negative offset)
    # ensures D is stable and captured. The bisection then narrows
    # from the safe side toward the constraint boundary.
    ref_offset = lower
    netlist = config.NETLIST_DIR / f'dff_bisect_{constraint_type}_ref.cir'
    gen_bisection_netlist(str(spice_path), str(netlist),
                          d_slew, clk_slew, ref_offset, load,
                          f'{constraint_type}_rise')
    try:
        xyce_utils.run_xyce(netlist)
        mt0 = Path(str(netlist) + '.mt0')
        tpd_ref = xyce_utils.parse_mt0_single(str(mt0), 'tpd')
    except (RuntimeError, KeyError, FileNotFoundError, ValueError):
        tpd_ref = 0

    if tpd_ref <= 0:
        raise RuntimeError('DFF reference simulation failed — check netlist')

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
        except (RuntimeError, KeyError, FileNotFoundError, ValueError):
            # Simulation failed or measure FAILED = timing violation
            tpd = 0

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

    # Parse actual cap values from AC results (Xyce uses .FD.prn for AC)
    d_prn = Path(str(config.NETLIST_DIR / f'DFFx1_{config.DFF_D_PIN}_caps.cir') + '.FD.prn')
    clk_prn = Path(str(config.NETLIST_DIR / f'DFFx1_{config.DFF_CLK_PIN}_caps.cir') + '.FD.prn')
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
