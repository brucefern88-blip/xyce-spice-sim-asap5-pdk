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
    'MUX21x1': {'inputs': ['D0','D1','S'], 'output': 'Y', 'func': '(S&D1)|(!S&D0)',   'area': 176*140},
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
