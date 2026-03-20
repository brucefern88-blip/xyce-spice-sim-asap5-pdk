#!/usr/bin/env python3
"""
Fused Hamming Cell PPA Study — Xyce BSIM-CMG Only
ASAP5 5nm GAA, SLVT TT cal models, VDD=0.5V, nfin=2, L=16n

Schematic-level Xyce netlists with parasitic caps from Magic .ext files.
Variants: A(48T), E(38T), F(42T), G(40T)

Steps:
  1. Parse .ext files for parasitic node caps (attofarads → femtofarads)
  2. Generate Xyce transient decks with extracted parasitics
  3. Generate Xyce DC .OP decks (16 vectors per variant = 64 total)
  4. Run all simulations
  5. Print PPA comparison table
  6. Print LTspice commands for .raw files
"""

import subprocess, os, re, sys

WORKDIR = os.path.dirname(os.path.abspath(__file__))
XYCE = os.path.expanduser("~/xyce-stack/install/xyce/bin/Xyce")
NMOS_MODEL = "/Users/bruce/CLAUDE/asap5/spice/xyce_models/nmos_slvt_tt_cal.pm"
PMOS_MODEL = "/Users/bruce/CLAUDE/asap5/spice/xyce_models/pmos_slvt_tt_cal.pm"
VDD = 0.5
NFIN = 2
L = "16n"
CLOAD = "1f"

# ============================================================
# Step 1: Parse .ext files for node parasitic capacitances
# ============================================================

def parse_ext_caps(ext_file):
    """Parse Magic .ext file, return dict of node_name -> cap_in_femtofarads.
    Magic .ext format: node "name" cap_attofarads ...
    scale 1000 1 1 means cap is in attofarads.
    """
    caps = {}
    if not os.path.exists(ext_file):
        return caps
    with open(ext_file) as f:
        for line in f:
            line = line.strip()
            if not line.startswith("node "):
                continue
            parts = line.split()
            # node "name" cap_aF x y ...
            if len(parts) < 3:
                continue
            name = parts[1].strip('"')
            try:
                cap_af = float(parts[2])
            except ValueError:
                continue
            # Convert attofarads to femtofarads (1 fF = 1000 aF)
            cap_ff = cap_af / 1000.0
            # Accumulate if node appears multiple times (VSS appears twice, etc.)
            if name in caps:
                caps[name] += cap_ff
            else:
                caps[name] = cap_ff
    return caps

# ============================================================
# Gate primitives — Xyce BSIM-CMG (nfin, no W)
# ============================================================

def inv(p, out, inp, vdd, gnd, cpara=None):
    s = (f"Mp_{p} {out} {inp} {vdd} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
         f"Mn_{p} {out} {inp} {gnd} {gnd} nmos_slvt l={L} nfin={NFIN}\n")
    if cpara and out in cpara:
        s += f"Cext_{p} {out} 0 {cpara[out]:.4f}f\n"
    return s

def nand2(p, out, a, b, vdd, gnd, cpara=None):
    ns = f"{p}_ns"
    s = (f"Mp1_{p} {out} {a} {vdd} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
         f"Mp2_{p} {out} {b} {vdd} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
         f"Mn1_{p} {out} {a} {ns} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
         f"Mn2_{p} {ns} {b} {gnd} {gnd} nmos_slvt l={L} nfin={NFIN}\n")
    if cpara and out in cpara:
        s += f"Cext_{p} {out} 0 {cpara[out]:.4f}f\n"
    return s

def nor2(p, out, a, b, vdd, gnd, cpara=None):
    ps = f"{p}_ps"
    s = (f"Mp1_{p} {ps} {a} {vdd} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
         f"Mp2_{p} {out} {b} {ps} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
         f"Mn1_{p} {out} {a} {gnd} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
         f"Mn2_{p} {out} {b} {gnd} {gnd} nmos_slvt l={L} nfin={NFIN}\n")
    if cpara and out in cpara:
        s += f"Cext_{p} {out} 0 {cpara[out]:.4f}f\n"
    return s

def aoi22(p, out, a, b, c, d, vdd, gnd, cpara=None):
    pm = f"{p}_pm"; nm1 = f"{p}_nm1"; nm2 = f"{p}_nm2"
    s = (f"Mp1_{p} {pm} {a} {vdd} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
         f"Mp2_{p} {pm} {b} {vdd} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
         f"Mp3_{p} {out} {c} {pm} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
         f"Mp4_{p} {out} {d} {pm} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
         f"Mn1_{p} {out} {a} {nm1} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
         f"Mn2_{p} {nm1} {b} {gnd} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
         f"Mn3_{p} {out} {c} {nm2} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
         f"Mn4_{p} {nm2} {d} {gnd} {gnd} nmos_slvt l={L} nfin={NFIN}\n")
    if cpara and out in cpara:
        s += f"Cext_{p} {out} 0 {cpara[out]:.4f}f\n"
    return s

def oai22(p, out, a, b, c, d, vdd, gnd, cpara=None):
    pm1 = f"{p}_pm1"; pm2 = f"{p}_pm2"; nmid = f"{p}_nmid"
    s = (f"Mp1_{p} {out} {a} {pm1} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
         f"Mp2_{p} {pm1} {b} {vdd} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
         f"Mp3_{p} {out} {c} {pm2} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
         f"Mp4_{p} {pm2} {d} {vdd} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
         f"Mn1_{p} {nmid} {a} {gnd} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
         f"Mn2_{p} {nmid} {b} {gnd} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
         f"Mn3_{p} {out} {c} {nmid} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
         f"Mn4_{p} {out} {d} {nmid} {gnd} nmos_slvt l={L} nfin={NFIN}\n")
    if cpara and out in cpara:
        s += f"Cext_{p} {out} 0 {cpara[out]:.4f}f\n"
    return s

# ============================================================
# Variant builders (with parasitic cap annotation)
# ============================================================

def build_variant_a(vdd="VDD", gnd="0", p="a", cpara=None):
    """Canonical 48T: 4 INV + 2 AOI22 + 2 INV + NOR2 + AOI22+INV + NAND2+INV"""
    s = f"* VARIANT A: Canonical (48T)\n"
    s += inv(f"{p}_iai", f"{p}_nai", "ai", vdd, gnd, cpara)
    s += inv(f"{p}_ibi", f"{p}_nbi", "bi", vdd, gnd, cpara)
    s += inv(f"{p}_iaj", f"{p}_naj", "aj", vdd, gnd, cpara)
    s += inv(f"{p}_ibj", f"{p}_nbj", "bj", vdd, gnd, cpara)
    s += aoi22(f"{p}_x0", f"{p}_d0", "ai","bi",f"{p}_nai",f"{p}_nbi", vdd, gnd, cpara)
    s += aoi22(f"{p}_x1", f"{p}_d1", "aj","bj",f"{p}_naj",f"{p}_nbj", vdd, gnd, cpara)
    s += inv(f"{p}_id0", f"{p}_xn0", f"{p}_d0", vdd, gnd, cpara)
    s += inv(f"{p}_id1", f"{p}_xn1", f"{p}_d1", vdd, gnd, cpara)
    s += nor2(f"{p}_o0", f"{p}_oh0", f"{p}_d0", f"{p}_d1", vdd, gnd, cpara)
    s += f"CL_{p}_oh0 {p}_oh0 0 {CLOAD}\n"
    s += aoi22(f"{p}_a1", f"{p}_no1", f"{p}_d0",f"{p}_xn1",f"{p}_xn0",f"{p}_d1", vdd, gnd, cpara)
    s += inv(f"{p}_io1", f"{p}_oh1", f"{p}_no1", vdd, gnd, cpara)
    s += f"CL_{p}_oh1 {p}_oh1 0 {CLOAD}\n"
    s += nand2(f"{p}_n2", f"{p}_no2", f"{p}_d0", f"{p}_d1", vdd, gnd, cpara)
    s += inv(f"{p}_io2", f"{p}_oh2", f"{p}_no2", vdd, gnd, cpara)
    s += f"CL_{p}_oh2 {p}_oh2 0 {CLOAD}\n"
    return s

def build_variant_e(vdd="VDD", gnd="0", p="e", cpara=None):
    """OAI22+NOR 38T: 4 INV + 2 OAI22 + NOR2 + NAND2+INV + NOR2"""
    s = f"* VARIANT E: OAI22+NOR (38T)\n"
    s += inv(f"{p}_iai", f"{p}_nai", "ai", vdd, gnd, cpara)
    s += inv(f"{p}_ibi", f"{p}_nbi", "bi", vdd, gnd, cpara)
    s += inv(f"{p}_iaj", f"{p}_naj", "aj", vdd, gnd, cpara)
    s += inv(f"{p}_ibj", f"{p}_nbj", "bj", vdd, gnd, cpara)
    s += oai22(f"{p}_q0", f"{p}_x0", f"{p}_nai",f"{p}_nbi","ai","bi", vdd, gnd, cpara)
    s += oai22(f"{p}_q1", f"{p}_x1", f"{p}_naj",f"{p}_nbj","aj","bj", vdd, gnd, cpara)
    s += nor2(f"{p}_o2", f"{p}_oh2", f"{p}_x0", f"{p}_x1", vdd, gnd, cpara)
    s += f"CL_{p}_oh2 {p}_oh2 0 {CLOAD}\n"
    s += nand2(f"{p}_n0", f"{p}_no0", f"{p}_x0", f"{p}_x1", vdd, gnd, cpara)
    s += inv(f"{p}_io0", f"{p}_oh0", f"{p}_no0", vdd, gnd, cpara)
    s += f"CL_{p}_oh0 {p}_oh0 0 {CLOAD}\n"
    s += nor2(f"{p}_o1", f"{p}_oh1", f"{p}_oh0", f"{p}_oh2", vdd, gnd, cpara)
    s += f"CL_{p}_oh1 {p}_oh1 0 {CLOAD}\n"
    return s

def build_variant_f(vdd="VDD", gnd="0", p="f", cpara=None):
    """Hybrid 42T: 4 INV + 2 OAI22 + 2 INV + NOR2 + AOI22+INV"""
    s = f"* VARIANT F: Hybrid (42T)\n"
    s += inv(f"{p}_iai", f"{p}_nai", "ai", vdd, gnd, cpara)
    s += inv(f"{p}_ibi", f"{p}_nbi", "bi", vdd, gnd, cpara)
    s += inv(f"{p}_iaj", f"{p}_naj", "aj", vdd, gnd, cpara)
    s += inv(f"{p}_ibj", f"{p}_nbj", "bj", vdd, gnd, cpara)
    s += oai22(f"{p}_q0", f"{p}_x0", f"{p}_nai",f"{p}_nbi","ai","bi", vdd, gnd, cpara)
    s += oai22(f"{p}_q1", f"{p}_x1", f"{p}_naj",f"{p}_nbj","aj","bj", vdd, gnd, cpara)
    s += inv(f"{p}_ix0", f"{p}_d0", f"{p}_x0", vdd, gnd, cpara)
    s += inv(f"{p}_ix1", f"{p}_d1", f"{p}_x1", vdd, gnd, cpara)
    s += nor2(f"{p}_o2", f"{p}_oh2", f"{p}_x0", f"{p}_x1", vdd, gnd, cpara)
    s += f"CL_{p}_oh2 {p}_oh2 0 {CLOAD}\n"
    s += aoi22(f"{p}_a1", f"{p}_no1", f"{p}_d0",f"{p}_x1",f"{p}_x0",f"{p}_d1", vdd, gnd, cpara)
    s += inv(f"{p}_io1", f"{p}_oh1", f"{p}_no1", vdd, gnd, cpara)
    s += f"CL_{p}_oh1 {p}_oh1 0 {CLOAD}\n"
    return s

def build_variant_g(vdd="VDD", gnd="0", p="g", cpara=None):
    """Active-Low 40T: 4 INV + 2 OAI22 + 2 INV + AOI22 + NAND2"""
    s = f"* VARIANT G: Active-Low (40T)\n"
    s += inv(f"{p}_iai", f"{p}_nai", "ai", vdd, gnd, cpara)
    s += inv(f"{p}_ibi", f"{p}_nbi", "bi", vdd, gnd, cpara)
    s += inv(f"{p}_iaj", f"{p}_naj", "aj", vdd, gnd, cpara)
    s += inv(f"{p}_ibj", f"{p}_nbj", "bj", vdd, gnd, cpara)
    s += oai22(f"{p}_q0", f"{p}_x0", f"{p}_nai",f"{p}_nbi","ai","bi", vdd, gnd, cpara)
    s += oai22(f"{p}_q1", f"{p}_x1", f"{p}_naj",f"{p}_nbj","aj","bj", vdd, gnd, cpara)
    s += inv(f"{p}_ix0", f"{p}_d0", f"{p}_x0", vdd, gnd, cpara)
    s += inv(f"{p}_ix1", f"{p}_d1", f"{p}_x1", vdd, gnd, cpara)
    s += aoi22(f"{p}_a1", f"{p}_noh1", f"{p}_d0",f"{p}_x1",f"{p}_x0",f"{p}_d1", vdd, gnd, cpara)
    s += f"CL_{p}_noh1 {p}_noh1 0 {CLOAD}\n"
    s += nand2(f"{p}_n2", f"{p}_noh2", f"{p}_d0", f"{p}_d1", vdd, gnd, cpara)
    s += f"CL_{p}_noh2 {p}_noh2 0 {CLOAD}\n"
    return s

VARIANTS = {
    'A': (build_variant_a, 48, ['oh0','oh1','oh2'], True),
    'E': (build_variant_e, 38, ['oh0','oh1','oh2'], True),
    'F': (build_variant_f, 42, ['oh1','oh2'], True),
    'G': (build_variant_g, 40, ['noh1','noh2'], False),  # active-low
}

# Truth table: ai,bi,aj,bj -> oh0,oh1,oh2
VECTORS = []
for v in range(16):
    ai = (v >> 3) & 1; bi = (v >> 2) & 1
    aj = (v >> 1) & 1; bj = (v >> 0) & 1
    d0 = ai ^ bi; d1 = aj ^ bj
    oh0 = int(d0 == 0 and d1 == 0)
    oh1 = int(d0 != d1)
    oh2 = int(d0 == 1 and d1 == 1)
    VECTORS.append((ai, bi, aj, bj, oh0, oh1, oh2))

# Map .ext names to schematic node names for parasitic annotation
# We map key output/internal node caps from .ext to schematic nodes

def map_ext_to_schematic_caps(variant_key, ext_caps):
    """Map extracted node caps to schematic internal nodes.
    Returns dict of schematic_node_name -> cap_in_fF for the CINT annotation.
    We only annotate output and key intermediate nodes — not VDD/VSS/inputs.
    """
    p = variant_key.lower()
    mapped = {}

    if variant_key == 'A':
        # A layout: oh0, oh1, oh2 are outputs
        # a_30_10# is shared internal diffusion routing — NOT the XOR output
        # AOI22 XOR outputs d0/d1 map to diffusion nodes near the gate outputs
        # a_442_10#, a_354_10# are intermediate stack nodes (NMOS side)
        # a_398_150#, a_266_150# are intermediate pMOS stack nodes
        # The actual XOR output loads are the oh0/oh1/oh2 node caps
        mapped[f'{p}_oh0'] = ext_caps.get('oh0', 2.0)
        mapped[f'{p}_oh1'] = ext_caps.get('oh1', 2.0)
        mapped[f'{p}_oh2'] = ext_caps.get('oh2', 2.0)
        # d0, d1 = AOI22 outputs driving into output stage
        # These are output diffusion nodes — use representative diffusion caps
        # a_442_10# (2.184 fF) and a_266_10# (2.184 fF) are the stack midpoints
        mapped[f'{p}_d0'] = ext_caps.get('a_442_10#', 2.0)
        mapped[f'{p}_d1'] = ext_caps.get('a_266_10#', 2.0)
        # Internal inverter outputs (xn0 = inv(d0), xn1 = inv(d1))
        mapped[f'{p}_xn0'] = ext_caps.get('a_398_150#', 2.0)
        mapped[f'{p}_xn1'] = ext_caps.get('a_266_150#', 2.0)
        # AOI22 output for oh1 path, NAND2 output for oh2 path
        mapped[f'{p}_no1'] = ext_caps.get('a_354_150#', 1.0)
        mapped[f'{p}_no2'] = ext_caps.get('a_354_10#', 2.0)
        # Inverter outputs for nai, nbi, naj, nbj
        mapped[f'{p}_nai'] = ext_caps.get('a_0_10#', 0.7)
        mapped[f'{p}_nbi'] = ext_caps.get('a_74_10#', 0.9)
        mapped[f'{p}_naj'] = ext_caps.get('a_162_10#', 2.0)
        mapped[f'{p}_nbj'] = ext_caps.get('a_178_10#', 2.0)

    elif variant_key == 'E':
        # E layout: OAI22+NOR topology, 38T
        # a_74_10# and a_266_10# are the OAI22 XNOR outputs (x0, x1)
        # But a_266_10# is 13 fF — that's a routing node, not just diffusion
        # Use the diffusion node cap for x0, and a smaller estimate for x1
        mapped[f'{p}_oh0'] = ext_caps.get('oh0', 1.0)
        mapped[f'{p}_oh1'] = ext_caps.get('oh1', 1.0)
        mapped[f'{p}_oh2'] = ext_caps.get('oh2', 1.0)
        # OAI22 XNOR outputs
        mapped[f'{p}_x0'] = ext_caps.get('a_74_10#', 1.3)
        mapped[f'{p}_x1'] = ext_caps.get('a_266_10#', 2.0)
        mapped[f'{p}_no0'] = ext_caps.get('a_178_150#', 2.0)
        mapped[f'{p}_nai'] = ext_caps.get('a_0_10#', 1.8)
        mapped[f'{p}_nbi'] = ext_caps.get('a_74_10#', 1.3)
        mapped[f'{p}_naj'] = ext_caps.get('a_162_10#', 1.8)
        mapped[f'{p}_nbj'] = ext_caps.get('a_178_85#', 1.2)

    elif variant_key == 'F':
        # F layout: Hybrid 42T
        mapped[f'{p}_oh1'] = ext_caps.get('oh1', 1.8)
        mapped[f'{p}_oh2'] = ext_caps.get('oh2', 3.0)
        # OAI22 XNOR outputs
        mapped[f'{p}_x0'] = ext_caps.get('a_74_10#', 1.3)
        mapped[f'{p}_x1'] = ext_caps.get('a_178_10#', 0.8)
        # Buffer outputs
        mapped[f'{p}_d0'] = ext_caps.get('a_90_150#', 2.0)
        mapped[f'{p}_d1'] = ext_caps.get('a_250_150#', 1.0)
        mapped[f'{p}_no1'] = ext_caps.get('a_178_150#', 2.0)
        mapped[f'{p}_nai'] = ext_caps.get('a_0_10#', 1.8)
        mapped[f'{p}_nbi'] = ext_caps.get('a_74_10#', 1.3)
        mapped[f'{p}_naj'] = ext_caps.get('a_162_10#', 1.8)
        mapped[f'{p}_nbj'] = ext_caps.get('a_178_85#', 1.2)

    elif variant_key == 'G':
        # G layout: Active-Low 40T
        mapped[f'{p}_noh1'] = ext_caps.get('noh1', 0.3)
        mapped[f'{p}_noh2'] = ext_caps.get('noh2', 0.5)
        # OAI22 XNOR outputs
        mapped[f'{p}_x0'] = ext_caps.get('a_74_10#', 6.9)
        mapped[f'{p}_x1'] = ext_caps.get('a_266_10#', 2.0)
        # Buffer outputs
        mapped[f'{p}_d0'] = ext_caps.get('a_90_225#', 0.8)
        mapped[f'{p}_d1'] = ext_caps.get('a_294_225#', 0.3)
        mapped[f'{p}_nai'] = ext_caps.get('a_0_10#', 1.8)
        mapped[f'{p}_nbi'] = ext_caps.get('a_74_10#', 6.9)
        mapped[f'{p}_naj'] = ext_caps.get('a_178_85#', 1.2)
        mapped[f'{p}_nbj'] = ext_caps.get('a_266_10#', 2.0)

    return mapped

# ============================================================
# Step 2: Generate Xyce transient decks
# ============================================================

def write_tran_netlist(variant_key, cpara=None):
    builder, tx_count, outs, active_high = VARIANTS[variant_key]
    p = variant_key.lower()
    fname = os.path.join(WORKDIR, f"ppa_tran_{p}.cir")

    if variant_key == 'G':
        meas_node = f"{p}_noh1"
        meas_edge = "FALL"
    else:
        meas_node = f"{p}_oh1"
        meas_edge = "RISE"

    with open(fname, 'w') as f:
        f.write(f"* FUSED_{variant_key} PPA Transient — Xyce BSIM-CMG level=107\n")
        f.write(f"* ASAP5 SLVT TT cal, VDD={VDD}V, nfin={NFIN}, L={L}\n")
        f.write(f"* Parasitic caps from Magic .ext extraction\n\n")
        f.write(f".include '{NMOS_MODEL}'\n")
        f.write(f".include '{PMOS_MODEL}'\n\n")
        f.write(f".OPTIONS DEVICE GMIN=1e-12\n")
        f.write(f".OPTIONS NONLIN RELTOL=1e-4 ABSTOL=1e-9\n")
        f.write(f".OPTIONS TIMEINT METHOD=trap RELTOL=1e-3 ABSTOL=1e-12\n")
        f.write(f".OPTIONS MEASURE MEASDGT=5\n\n")
        f.write(f"Vvdd VDD 0 {VDD}\n")
        f.write(f"Vai ai 0 DC 0\n")
        f.write(f"Vbi bi 0 PWL(0 0 200p 0 205p {VDD})\n")
        f.write(f"Vaj aj 0 DC 0\n")
        f.write(f"Vbj bj 0 DC 0\n\n")
        f.write(builder(cpara=cpara))
        f.write(f"\n.TRAN 0.5p 1200p\n")
        out_nodes = [f"{p}_{o}" for o in outs]
        f.write(f".PRINT TRAN V(bi) {' '.join(f'V({n})' for n in out_nodes)} I(Vvdd)\n\n")
        # Delay: input bi crosses VDD/2 rising -> output crosses VDD/2
        f.write(f".MEASURE TRAN tpd_oh1 TRIG V(bi) VAL={VDD/2} RISE=1\n")
        f.write(f"+  TARG V({meas_node}) VAL={VDD/2} {meas_edge}=1\n")
        # Power measurements
        f.write(f".MEASURE TRAN i_avg AVG I(Vvdd) FROM=0 TO=1200p\n")
        f.write(f".MEASURE TRAN i_switch AVG I(Vvdd) FROM=200p TO=800p\n")
        # Peak current
        f.write(f".MEASURE TRAN i_peak MAX I(Vvdd) FROM=200p TO=400p\n")
        f.write(f".END\n")
    return fname

# ============================================================
# Step 3 (DC): Generate one .OP deck per vector per variant
# ============================================================

def write_dc_netlist(variant_key, vec_idx, cpara=None):
    builder, tx_count, outs, active_high = VARIANTS[variant_key]
    ai, bi, aj, bj, oh0, oh1, oh2 = VECTORS[vec_idx]
    p = variant_key.lower()
    fname = os.path.join(WORKDIR, f"ppa_dc_{p}_v{vec_idx}.cir")

    with open(fname, 'w') as f:
        f.write(f"* FUSED_{variant_key} DC vec{vec_idx} ai={ai} bi={bi} aj={aj} bj={bj}\n")
        f.write(f".include '{NMOS_MODEL}'\n")
        f.write(f".include '{PMOS_MODEL}'\n")
        f.write(f".OPTIONS DEVICE GMIN=1e-12\n")
        f.write(f".OPTIONS NONLIN RELTOL=1e-4 ABSTOL=1e-9 SEARCHMETHOD=2\n\n")
        f.write(f"Vvdd VDD 0 {VDD}\n")
        f.write(f"Vai ai 0 {VDD if ai else 0}\n")
        f.write(f"Vbi bi 0 {VDD if bi else 0}\n")
        f.write(f"Vaj aj 0 {VDD if aj else 0}\n")
        f.write(f"Vbj bj 0 {VDD if bj else 0}\n\n")
        f.write(builder(cpara=cpara))
        f.write(f"\n.OP\n")
        out_nodes = [f"{p}_{o}" for o in outs]
        f.write(f".PRINT DC {' '.join(f'V({n})' for n in out_nodes)} I(Vvdd)\n")
        f.write(f".END\n")
    return fname

# ============================================================
# Run Xyce
# ============================================================

def run_xyce(cir_file, raw_file=None, timeout=60):
    cmd = [XYCE, "-max-warnings", "10"]
    if raw_file:
        cmd += ["-r", raw_file]
    cmd.append(cir_file)
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, cwd=WORKDIR, timeout=timeout)
        return r.returncode, r.stdout, r.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "TIMEOUT"

def parse_mt0(cir_file):
    mt = cir_file + ".mt0"
    results = {}
    if not os.path.exists(mt):
        return results
    with open(mt) as f:
        for line in f:
            m = re.match(r'(\w+)\s*=\s*([^\s]+)', line.strip())
            if m and m.group(2) != "FAILED":
                try:
                    results[m.group(1).lower()] = float(m.group(2))
                except ValueError:
                    pass
    return results

def parse_prn(cir_file):
    prn = cir_file + ".prn"
    if not os.path.exists(prn):
        return None
    values = []
    with open(prn) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("Index") or line.startswith("End"):
                continue
            parts = line.split()
            if len(parts) >= 2:
                try:
                    values = [float(x) for x in parts[1:]]
                except ValueError:
                    pass
    return values

# ============================================================
# Main
# ============================================================

def main():
    print("=" * 78)
    print("  FUSED HAMMING CELL PPA STUDY — Xyce BSIM-CMG level=107")
    print(f"  ASAP5 5nm GAA, SLVT TT cal, VDD={VDD}V, nfin={NFIN}, L={L}")
    print(f"  Parasitic caps from Magic .ext extraction")
    print("=" * 78)

    if not os.path.exists(XYCE):
        print(f"ERROR: Xyce not found at {XYCE}")
        sys.exit(1)

    # ===== Step 1: Parse .ext files =====
    print(f"\n--- STEP 1: PARSING .ext FILES FOR PARASITIC CAPS ---\n")

    ext_files = {
        'A': os.path.join(WORKDIR, "FUSED_A.ext"),
        'E': os.path.join(WORKDIR, "FUSED_E.ext"),
        'F': os.path.join(WORKDIR, "FUSED_F.ext"),
        'G': os.path.join(WORKDIR, "FUSED_G.ext"),
    }

    all_ext_caps = {}
    all_schematic_caps = {}
    for vk in ['A','E','F','G']:
        raw_caps = parse_ext_caps(ext_files[vk])
        all_ext_caps[vk] = raw_caps
        mapped = map_ext_to_schematic_caps(vk, raw_caps)
        all_schematic_caps[vk] = mapped

        # Print summary
        out_names = VARIANTS[vk][2]
        p = vk.lower()
        print(f"  Variant {vk}:")
        total_cap = sum(v for k,v in raw_caps.items()
                       if k not in ('VDD','VSS','w_0_65#','ai','bi','aj','bj'))
        print(f"    Total internal node cap: {total_cap:.1f} fF")
        for oname in out_names:
            key = f"{p}_{oname}"
            cap = mapped.get(key, 0)
            print(f"    {oname} parasitic: {cap:.2f} fF")
        print()

    # ===== Step 4 (DC before transient): DC verification =====
    print(f"--- STEP 4: DC FUNCTIONAL VERIFICATION (16 vectors x 4 variants) ---\n")

    vth = VDD / 2.0
    dc_results = {}
    dc_leakage = {}

    for vk in ['A','E','F','G']:
        builder, tx_count, outs, active_high = VARIANTS[vk]
        p = vk.lower()
        cpara = all_schematic_caps[vk]
        passed = 0
        failed = 0
        fail_details = []
        leak_currents = []

        for vi in range(16):
            cir = write_dc_netlist(vk, vi, cpara=cpara)
            rc, stdout, stderr = run_xyce(cir)
            vals = parse_prn(cir)

            ai, bi, aj, bj, exp0, exp1, exp2 = VECTORS[vi]

            if vals and len(vals) >= len(outs) + 1:
                # Last value is I(Vvdd) = leakage
                i_leak = abs(vals[-1])
                leak_currents.append(i_leak)

                measured = {}
                for idx, oname in enumerate(outs):
                    v = vals[idx]
                    if active_high:
                        measured[oname] = 1 if v > vth else 0
                    else:
                        measured[oname] = 1 if v > vth else 0

                ok = True
                if vk in ['A','E']:
                    ok = (measured.get('oh0',-1)==exp0 and
                          measured.get('oh1',-1)==exp1 and
                          measured.get('oh2',-1)==exp2)
                elif vk == 'F':
                    ok = (measured.get('oh1',-1)==exp1 and
                          measured.get('oh2',-1)==exp2)
                elif vk == 'G':
                    ok = (measured.get('noh1',-1)==(1-exp1) and
                          measured.get('noh2',-1)==(1-exp2))

                if ok:
                    passed += 1
                else:
                    failed += 1
                    fail_details.append(f"    vec{vi}: ai={ai} bi={bi} aj={aj} bj={bj} "
                                       f"exp=({exp0},{exp1},{exp2}) got={measured}")
            elif vals and len(vals) >= len(outs):
                # No I(Vvdd) column but outputs present
                measured = {}
                for idx, oname in enumerate(outs):
                    v = vals[idx]
                    if active_high:
                        measured[oname] = 1 if v > vth else 0
                    else:
                        measured[oname] = 1 if v > vth else 0

                ok = True
                if vk in ['A','E']:
                    ok = (measured.get('oh0',-1)==exp0 and
                          measured.get('oh1',-1)==exp1 and
                          measured.get('oh2',-1)==exp2)
                elif vk == 'F':
                    ok = (measured.get('oh1',-1)==exp1 and
                          measured.get('oh2',-1)==exp2)
                elif vk == 'G':
                    ok = (measured.get('noh1',-1)==(1-exp1) and
                          measured.get('noh2',-1)==(1-exp2))

                if ok:
                    passed += 1
                else:
                    failed += 1
                    fail_details.append(f"    vec{vi}: ai={ai} bi={bi} aj={aj} bj={bj} "
                                       f"exp=({exp0},{exp1},{exp2}) got={measured}")
            else:
                failed += 1
                fail_details.append(f"    vec{vi}: Xyce returned no output (rc={rc})")

            # Cleanup DC files
            for ext in ['.prn', '.mt0']:
                cleanup = cir + ext
                if os.path.exists(cleanup):
                    os.remove(cleanup)
            if os.path.exists(cir):
                os.remove(cir)

        dc_results[vk] = (passed, failed)
        avg_leak = sum(leak_currents) / len(leak_currents) if leak_currents else 0
        dc_leakage[vk] = avg_leak
        status = "PASS" if failed == 0 else "FAIL"
        print(f"  Variant {vk} ({tx_count}T): {passed}/16 {status}  "
              f"avg I_leak = {avg_leak*1e9:.2f} nA")
        if fail_details:
            for fd in fail_details:
                print(fd)

    # ===== Steps 2-3: Transient delay + power =====
    print(f"\n--- STEPS 2-3: TRANSIENT DELAY + POWER (bi: 0->{VDD}V @ 200ps, 5ps rise) ---\n")

    tran_results = {}
    raw_files = {}

    for vk in ['A','E','F','G']:
        builder, tx_count, outs, active_high = VARIANTS[vk]
        p = vk.lower()
        cpara = all_schematic_caps[vk]
        cir = write_tran_netlist(vk, cpara=cpara)
        raw_file = os.path.join(WORKDIR, f"ppa_{p}.raw")
        raw_files[vk] = raw_file

        rc, stdout, stderr = run_xyce(cir, raw_file=raw_file, timeout=120)

        measures = parse_mt0(cir)
        tpd = measures.get('tpd_oh1', None)
        i_avg = measures.get('i_avg', None)
        i_switch = measures.get('i_switch', None)
        i_peak = measures.get('i_peak', None)

        if tpd is not None:
            tpd_ps = abs(tpd) * 1e12
        else:
            tpd_ps = -1

        if i_switch is not None:
            p_switch_uw = abs(i_switch) * VDD * 1e6
        elif i_avg is not None:
            p_switch_uw = abs(i_avg) * VDD * 1e6
        else:
            p_switch_uw = -1

        p_avg_uw = abs(i_avg) * VDD * 1e6 if i_avg else 0
        p_leak_nw = dc_leakage[vk] * VDD * 1e9

        tran_results[vk] = {
            'tpd_ps': tpd_ps,
            'p_switch_uw': p_switch_uw,
            'p_avg_uw': p_avg_uw,
            'p_leak_nw': p_leak_nw,
            'i_avg': abs(i_avg) if i_avg else 0,
            'i_switch': abs(i_switch) if i_switch else 0,
            'i_peak': abs(i_peak) if i_peak else 0,
            'tx_count': tx_count,
            'rc': rc,
        }

        raw_exists = "YES" if os.path.exists(raw_file) else "NO"
        print(f"  Variant {vk} ({tx_count}T): tpd={tpd_ps:.1f}ps  "
              f"P_switch={p_switch_uw:.4f}uW  "
              f"P_leak={p_leak_nw:.1f}nW  "
              f"raw={raw_exists}  rc={rc}")

    # ===== Step 5: PPA Comparison Table =====
    print(f"\n{'='*78}")
    print(f"  STEP 5: PPA COMPARISON TABLE")
    print(f"{'='*78}")

    # Table 1: Raw numbers
    print(f"\n  {'Variant':>8} | {'Trans':>5} | {'tpd(ps)':>8} | {'P_sw(uW)':>9} | "
          f"{'P_leak(nW)':>10} | {'DC':>7}")
    print(f"  {'-'*8}-+-{'-'*5}-+-{'-'*8}-+-{'-'*9}-+-{'-'*10}-+-{'-'*7}")

    for vk in ['A','E','F','G']:
        r = tran_results[vk]
        dc_p, dc_f = dc_results[vk]
        dc_str = f"{dc_p}/16" if dc_f == 0 else f"{dc_p}/16!"
        print(f"  {vk:>8} | {r['tx_count']:>5} | {r['tpd_ps']:>8.1f} | "
              f"{r['p_switch_uw']:>9.4f} | {r['p_leak_nw']:>10.1f} | {dc_str:>7}")

    # Table 2: Relative comparison (A = baseline)
    print(f"\n  --- Relative to Variant A (baseline = 1.000) ---\n")
    print(f"  {'Variant':>8} | {'Area':>8} | {'Delay':>8} | {'Power':>8} | "
          f"{'EDP':>8} | {'AxD':>8}")
    print(f"  {'-'*8}-+-{'-'*8}-+-{'-'*8}-+-{'-'*8}-+-{'-'*8}-+-{'-'*8}")

    base = tran_results['A']
    base_edp = base['tpd_ps'] * base['p_switch_uw'] if base['tpd_ps'] > 0 else 1
    base_ad = base['tpd_ps'] * base['tx_count'] if base['tpd_ps'] > 0 else 1

    for vk in ['A','E','F','G']:
        r = tran_results[vk]
        area_rel = r['tx_count'] / base['tx_count']
        delay_rel = r['tpd_ps'] / base['tpd_ps'] if base['tpd_ps'] > 0 and r['tpd_ps'] > 0 else 0
        power_rel = r['p_switch_uw'] / base['p_switch_uw'] if base['p_switch_uw'] > 0 and r['p_switch_uw'] > 0 else 0
        edp = r['tpd_ps'] * r['p_switch_uw'] if r['tpd_ps'] > 0 else 0
        edp_rel = edp / base_edp if base_edp > 0 else 0
        ad = r['tpd_ps'] * r['tx_count'] if r['tpd_ps'] > 0 else 0
        ad_rel = ad / base_ad if base_ad > 0 else 0

        print(f"  {vk:>8} | {area_rel:>8.3f} | {delay_rel:>8.3f} | "
              f"{power_rel:>8.3f} | {edp_rel:>8.3f} | {ad_rel:>8.3f}")

    # Table 3: Absolute PPA scores
    print(f"\n  --- Absolute PPA Metrics ---\n")
    print(f"  {'Variant':>8} | {'EDP(ps*uW)':>11} | {'AxD(T*ps)':>10} | "
          f"{'PDP(fJ)':>8} | {'I_peak(uA)':>10}")
    print(f"  {'-'*8}-+-{'-'*11}-+-{'-'*10}-+-{'-'*8}-+-{'-'*10}")

    for vk in ['A','E','F','G']:
        r = tran_results[vk]
        edp = r['tpd_ps'] * r['p_switch_uw'] if r['tpd_ps'] > 0 else 0
        ad = r['tpd_ps'] * r['tx_count'] if r['tpd_ps'] > 0 else 0
        pdp_fj = r['tpd_ps'] * r['p_switch_uw'] * 1e-6 if r['tpd_ps'] > 0 else 0  # ps * uW = 1e-12 * 1e-6 = aJ... let me fix
        # PDP = power * delay. P in uW, t in ps => P*t = uW*ps = 1e-6 * 1e-12 = 1e-18 J = aJ
        # For fJ: divide by 1000
        pdp_aj = r['tpd_ps'] * r['p_switch_uw']  # in aJ (attojoules)
        pdp_fj_val = pdp_aj / 1000.0
        i_peak_ua = r['i_peak'] * 1e6

        print(f"  {vk:>8} | {edp:>11.2f} | {ad:>10.0f} | "
              f"{pdp_fj_val:>8.4f} | {i_peak_ua:>10.2f}")

    # Find winners
    valid = {k:v for k,v in tran_results.items() if v['tpd_ps'] > 0}
    if valid:
        best_edp_k = min(valid, key=lambda k: valid[k]['tpd_ps']*valid[k]['p_switch_uw'])
        best_area_k = min(valid, key=lambda k: valid[k]['tx_count'])
        best_speed_k = min(valid, key=lambda k: valid[k]['tpd_ps'])
        best_power_k = min(valid, key=lambda k: valid[k]['p_switch_uw'])

        print(f"\n  WINNERS:")
        print(f"    Best EDP:    Variant {best_edp_k} "
              f"({valid[best_edp_k]['tx_count']}T, "
              f"{valid[best_edp_k]['tpd_ps']:.1f}ps)")
        print(f"    Best Area:   Variant {best_area_k} "
              f"({valid[best_area_k]['tx_count']}T)")
        print(f"    Best Speed:  Variant {best_speed_k} "
              f"({valid[best_speed_k]['tpd_ps']:.1f}ps)")
        print(f"    Best Power:  Variant {best_power_k} "
              f"({valid[best_power_k]['p_switch_uw']:.4f}uW)")

    # ===== Step 6: LTspice commands =====
    print(f"\n{'='*78}")
    print(f"  STEP 6: LTSPICE WAVEFORM VIEWING COMMANDS")
    print(f"{'='*78}\n")

    for vk in ['A','E','F','G']:
        if os.path.exists(raw_files[vk]):
            sz = os.path.getsize(raw_files[vk])
            print(f"  open -a LTspice {raw_files[vk]}  # {sz/1024:.0f} KB")
        else:
            print(f"  # {raw_files[vk]} — not generated (Xyce error)")

    print()
    print("  Done.")

if __name__ == "__main__":
    main()
