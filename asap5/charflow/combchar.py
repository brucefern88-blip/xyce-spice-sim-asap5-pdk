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

        prn_path = Path(str(caps_netlist) + '.FD.prn')
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
