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
