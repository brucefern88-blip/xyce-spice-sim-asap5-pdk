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
