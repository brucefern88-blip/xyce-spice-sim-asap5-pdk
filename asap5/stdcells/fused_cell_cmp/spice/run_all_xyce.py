#!/usr/bin/env python3
"""
Fused Hamming Cell PPA Comparison — ASAP5 5nm GAA + Xyce BSIM-CMG
Variants: A(48T), E(38T), F(42T), G(40T)

Flow per variant:
  1. Generate Xyce netlist with BSIM-CMG level=107 calibrated models
  2. Run DC functional verification (16 vectors via .STEP)
  3. Run transient for delay measurement
  4. Report Power, Performance (delay), Area (transistor count)

Uses: nfin=2 (minimum ASAP5 device), SLVT TT, VDD=0.5V
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
CINT = "0.1f"  # internal node parasitic (pre-layout estimate)

# ============================================================
# Gate primitives — Xyce BSIM-CMG (nfin, no W)
# ============================================================

def inv(p, out, inp, vdd, gnd):
    return (f"Mp_{p} {out} {inp} {vdd} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
            f"Mn_{p} {out} {inp} {gnd} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
            f"C_{p} {out} 0 {CINT}\n")

def nand2(p, out, a, b, vdd, gnd):
    ns = f"{p}_ns"
    return (f"Mp1_{p} {out} {a} {vdd} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
            f"Mp2_{p} {out} {b} {vdd} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
            f"Mn1_{p} {out} {a} {ns} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
            f"Mn2_{p} {ns} {b} {gnd} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
            f"C_{p} {out} 0 {CINT}\n")

def nor2(p, out, a, b, vdd, gnd):
    ps = f"{p}_ps"
    return (f"Mp1_{p} {ps} {a} {vdd} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
            f"Mp2_{p} {out} {b} {ps} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
            f"Mn1_{p} {out} {a} {gnd} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
            f"Mn2_{p} {out} {b} {gnd} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
            f"C_{p} {out} 0 {CINT}\n")

def aoi22(p, out, a, b, c, d, vdd, gnd):
    pm = f"{p}_pm"; nm1 = f"{p}_nm1"; nm2 = f"{p}_nm2"
    return (f"Mp1_{p} {pm} {a} {vdd} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
            f"Mp2_{p} {pm} {b} {vdd} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
            f"Mp3_{p} {out} {c} {pm} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
            f"Mp4_{p} {out} {d} {pm} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
            f"Mn1_{p} {out} {a} {nm1} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
            f"Mn2_{p} {nm1} {b} {gnd} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
            f"Mn3_{p} {out} {c} {nm2} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
            f"Mn4_{p} {nm2} {d} {gnd} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
            f"C_{p} {out} 0 {CINT}\n")

def oai22(p, out, a, b, c, d, vdd, gnd):
    pm1 = f"{p}_pm1"; pm2 = f"{p}_pm2"; nmid = f"{p}_nmid"
    return (f"Mp1_{p} {out} {a} {pm1} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
            f"Mp2_{p} {pm1} {b} {vdd} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
            f"Mp3_{p} {out} {c} {pm2} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
            f"Mp4_{p} {pm2} {d} {vdd} {vdd} pmos_slvt l={L} nfin={NFIN}\n"
            f"Mn1_{p} {nmid} {a} {gnd} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
            f"Mn2_{p} {nmid} {b} {gnd} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
            f"Mn3_{p} {out} {c} {nmid} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
            f"Mn4_{p} {out} {d} {nmid} {gnd} nmos_slvt l={L} nfin={NFIN}\n"
            f"C_{p} {out} 0 {CINT}\n")

# ============================================================
# Variant builders
# ============================================================

def build_variant_a(vdd="VDD", gnd="0", p="a"):
    """Canonical 48T: 4 INV + 2 AOI22 + 2 INV + NOR2 + AOI22+INV + NAND2+INV"""
    s = f"* VARIANT A: Canonical (48T)\n"
    s += inv(f"{p}_iai", f"{p}_nai", "ai", vdd, gnd)
    s += inv(f"{p}_ibi", f"{p}_nbi", "bi", vdd, gnd)
    s += inv(f"{p}_iaj", f"{p}_naj", "aj", vdd, gnd)
    s += inv(f"{p}_ibj", f"{p}_nbj", "bj", vdd, gnd)
    s += aoi22(f"{p}_x0", f"{p}_d0", "ai","bi",f"{p}_nai",f"{p}_nbi", vdd, gnd)
    s += aoi22(f"{p}_x1", f"{p}_d1", "aj","bj",f"{p}_naj",f"{p}_nbj", vdd, gnd)
    s += inv(f"{p}_id0", f"{p}_xn0", f"{p}_d0", vdd, gnd)
    s += inv(f"{p}_id1", f"{p}_xn1", f"{p}_d1", vdd, gnd)
    s += nor2(f"{p}_o0", f"{p}_oh0", f"{p}_d0", f"{p}_d1", vdd, gnd)
    s += f"CL_{p}_oh0 {p}_oh0 0 {CLOAD}\n"
    s += aoi22(f"{p}_a1", f"{p}_no1", f"{p}_d0",f"{p}_xn1",f"{p}_xn0",f"{p}_d1", vdd, gnd)
    s += inv(f"{p}_io1", f"{p}_oh1", f"{p}_no1", vdd, gnd)
    s += f"CL_{p}_oh1 {p}_oh1 0 {CLOAD}\n"
    s += nand2(f"{p}_n2", f"{p}_no2", f"{p}_d0", f"{p}_d1", vdd, gnd)
    s += inv(f"{p}_io2", f"{p}_oh2", f"{p}_no2", vdd, gnd)
    s += f"CL_{p}_oh2 {p}_oh2 0 {CLOAD}\n"
    return s

def build_variant_e(vdd="VDD", gnd="0", p="e"):
    """OAI22+NOR 38T: 4 INV + 2 OAI22 + NOR2 + NAND2+INV + NOR2"""
    s = f"* VARIANT E: OAI22+NOR (38T)\n"
    s += inv(f"{p}_iai", f"{p}_nai", "ai", vdd, gnd)
    s += inv(f"{p}_ibi", f"{p}_nbi", "bi", vdd, gnd)
    s += inv(f"{p}_iaj", f"{p}_naj", "aj", vdd, gnd)
    s += inv(f"{p}_ibj", f"{p}_nbj", "bj", vdd, gnd)
    s += oai22(f"{p}_q0", f"{p}_x0", f"{p}_nai",f"{p}_nbi","ai","bi", vdd, gnd)
    s += oai22(f"{p}_q1", f"{p}_x1", f"{p}_naj",f"{p}_nbj","aj","bj", vdd, gnd)
    s += nor2(f"{p}_o2", f"{p}_oh2", f"{p}_x0", f"{p}_x1", vdd, gnd)
    s += f"CL_{p}_oh2 {p}_oh2 0 {CLOAD}\n"
    s += nand2(f"{p}_n0", f"{p}_no0", f"{p}_x0", f"{p}_x1", vdd, gnd)
    s += inv(f"{p}_io0", f"{p}_oh0", f"{p}_no0", vdd, gnd)
    s += f"CL_{p}_oh0 {p}_oh0 0 {CLOAD}\n"
    s += nor2(f"{p}_o1", f"{p}_oh1", f"{p}_oh0", f"{p}_oh2", vdd, gnd)
    s += f"CL_{p}_oh1 {p}_oh1 0 {CLOAD}\n"
    return s

def build_variant_f(vdd="VDD", gnd="0", p="f"):
    """Hybrid 42T: 4 INV + 2 OAI22 + 2 INV + NOR2 + AOI22+INV"""
    s = f"* VARIANT F: Hybrid (42T)\n"
    s += inv(f"{p}_iai", f"{p}_nai", "ai", vdd, gnd)
    s += inv(f"{p}_ibi", f"{p}_nbi", "bi", vdd, gnd)
    s += inv(f"{p}_iaj", f"{p}_naj", "aj", vdd, gnd)
    s += inv(f"{p}_ibj", f"{p}_nbj", "bj", vdd, gnd)
    s += oai22(f"{p}_q0", f"{p}_x0", f"{p}_nai",f"{p}_nbi","ai","bi", vdd, gnd)
    s += oai22(f"{p}_q1", f"{p}_x1", f"{p}_naj",f"{p}_nbj","aj","bj", vdd, gnd)
    s += inv(f"{p}_ix0", f"{p}_d0", f"{p}_x0", vdd, gnd)
    s += inv(f"{p}_ix1", f"{p}_d1", f"{p}_x1", vdd, gnd)
    s += nor2(f"{p}_o2", f"{p}_oh2", f"{p}_x0", f"{p}_x1", vdd, gnd)
    s += f"CL_{p}_oh2 {p}_oh2 0 {CLOAD}\n"
    s += aoi22(f"{p}_a1", f"{p}_no1", f"{p}_d0",f"{p}_x1",f"{p}_x0",f"{p}_d1", vdd, gnd)
    s += inv(f"{p}_io1", f"{p}_oh1", f"{p}_no1", vdd, gnd)
    s += f"CL_{p}_oh1 {p}_oh1 0 {CLOAD}\n"
    return s

def build_variant_g(vdd="VDD", gnd="0", p="g"):
    """Active-Low 40T: 4 INV + 2 OAI22 + 2 INV + AOI22 + NAND2"""
    s = f"* VARIANT G: Active-Low (40T)\n"
    s += inv(f"{p}_iai", f"{p}_nai", "ai", vdd, gnd)
    s += inv(f"{p}_ibi", f"{p}_nbi", "bi", vdd, gnd)
    s += inv(f"{p}_iaj", f"{p}_naj", "aj", vdd, gnd)
    s += inv(f"{p}_ibj", f"{p}_nbj", "bj", vdd, gnd)
    s += oai22(f"{p}_q0", f"{p}_x0", f"{p}_nai",f"{p}_nbi","ai","bi", vdd, gnd)
    s += oai22(f"{p}_q1", f"{p}_x1", f"{p}_naj",f"{p}_nbj","aj","bj", vdd, gnd)
    s += inv(f"{p}_ix0", f"{p}_d0", f"{p}_x0", vdd, gnd)
    s += inv(f"{p}_ix1", f"{p}_d1", f"{p}_x1", vdd, gnd)
    s += aoi22(f"{p}_a1", f"{p}_noh1", f"{p}_d0",f"{p}_x1",f"{p}_x0",f"{p}_d1", vdd, gnd)
    s += f"CL_{p}_noh1 {p}_noh1 0 {CLOAD}\n"
    s += nand2(f"{p}_n2", f"{p}_noh2", f"{p}_d0", f"{p}_d1", vdd, gnd)
    s += f"CL_{p}_noh2 {p}_noh2 0 {CLOAD}\n"
    return s

VARIANTS = {
    'A': (build_variant_a, 48, ['oh0','oh1','oh2'], True),
    'E': (build_variant_e, 38, ['oh0','oh1','oh2'], True),
    'F': (build_variant_f, 42, ['oh1','oh2'], True),
    'G': (build_variant_g, 40, ['noh1','noh2'], False),  # active-low
}

# Truth table
VECTORS = []
for v in range(16):
    ai = (v >> 3) & 1; bi = (v >> 2) & 1
    aj = (v >> 1) & 1; bj = (v >> 0) & 1
    d0 = ai ^ bi; d1 = aj ^ bj
    oh0 = int(d0 == 0 and d1 == 0)
    oh1 = int(d0 != d1)
    oh2 = int(d0 == 1 and d1 == 1)
    VECTORS.append((ai, bi, aj, bj, oh0, oh1, oh2))

# ============================================================
# Generate Xyce DC verification netlist per variant
# ============================================================

def write_dc_netlist(variant_key, vec_idx):
    """Write Xyce .OP netlist for one variant + one vector."""
    builder, tx_count, outs, active_high = VARIANTS[variant_key]
    ai, bi, aj, bj, oh0, oh1, oh2 = VECTORS[vec_idx]
    p = variant_key.lower()
    fname = os.path.join(WORKDIR, f"dc_{p}_v{vec_idx}.cir")

    with open(fname, 'w') as f:
        f.write(f"* FUSED_{variant_key} DC vec{vec_idx} ai={ai} bi={bi} aj={aj} bj={bj}\n")
        f.write(f".include '{NMOS_MODEL}'\n")
        f.write(f".include '{PMOS_MODEL}'\n")
        f.write(".OPTIONS DEVICE GMIN=1e-12\n")
        f.write(".OPTIONS NONLIN RELTOL=1e-4 ABSTOL=1e-9 SEARCHMETHOD=2\n\n")
        f.write(f"Vvdd VDD 0 {VDD}\n")
        f.write(f"Vai ai 0 {VDD if ai else 0}\n")
        f.write(f"Vbi bi 0 {VDD if bi else 0}\n")
        f.write(f"Vaj aj 0 {VDD if aj else 0}\n")
        f.write(f"Vbj bj 0 {VDD if bj else 0}\n\n")
        f.write(builder())
        f.write("\n.OP\n")
        out_nodes = [f"{p}_{o}" for o in outs]
        f.write(f".PRINT DC {' '.join(f'V({n})' for n in out_nodes)} I(Vvdd)\n")
        f.write(".END\n")
    return fname

# ============================================================
# Generate Xyce transient delay netlist per variant
# ============================================================

def write_tran_netlist(variant_key):
    """Transient: bi transitions 0->VDD at 200ps, measure OH1 delay."""
    builder, tx_count, outs, active_high = VARIANTS[variant_key]
    p = variant_key.lower()
    fname = os.path.join(WORKDIR, f"tran_{p}.cir")

    # Determine which output to measure for delay
    if variant_key == 'G':
        meas_node = f"{p}_noh1"
        meas_edge = "FALL"
    else:
        meas_node = f"{p}_oh1"
        meas_edge = "RISE"

    with open(fname, 'w') as f:
        f.write(f"* FUSED_{variant_key} Transient Delay\n")
        f.write(f".include '{NMOS_MODEL}'\n")
        f.write(f".include '{PMOS_MODEL}'\n")
        f.write(".OPTIONS DEVICE GMIN=1e-12\n")
        f.write(".OPTIONS NONLIN RELTOL=1e-4 ABSTOL=1e-9\n")
        f.write(".OPTIONS TIMEINT METHOD=trap RELTOL=1e-3 ABSTOL=1e-12\n")
        f.write(".OPTIONS MEASURE MEASDGT=5\n\n")
        f.write(f"Vvdd VDD 0 {VDD}\n")
        f.write(f"Vai ai 0 DC 0\n")
        f.write(f"Vbi bi 0 PWL(0 0 200p 0 205p {VDD})\n")
        f.write(f"Vaj aj 0 DC 0\n")
        f.write(f"Vbj bj 0 DC 0\n\n")
        f.write(builder())
        f.write(f"\n.TRAN 0.5p 800p\n")
        out_nodes = [f"{p}_{o}" for o in outs]
        f.write(f".PRINT TRAN V(bi) {' '.join(f'V({n})' for n in out_nodes)} I(Vvdd)\n\n")
        # Delay measurement
        f.write(f".MEASURE TRAN tpd_oh1 TRIG V(bi) VAL={VDD/2} RISE=1\n")
        f.write(f"+  TARG V({meas_node}) VAL={VDD/2} {meas_edge}=1\n")
        # Power
        f.write(f".MEASURE TRAN i_avg AVG I(Vvdd) FROM=0 TO=800p\n")
        f.write(f".MEASURE TRAN i_switch AVG I(Vvdd) FROM=200p TO=600p\n")
        f.write(".END\n")
    return fname

# ============================================================
# Run Xyce and parse results
# ============================================================

def run_xyce(cir_file, timeout=30):
    cmd = [XYCE, "-max-warnings", "10", cir_file]
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
    """Parse .cir.prn for DC output voltages."""
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
    print("=" * 72)
    print("  FUSED HAMMING CELL — XYCE BSIM-CMG PPA COMPARISON")
    print(f"  ASAP5 5nm GAA, SLVT TT, VDD={VDD}V, nfin={NFIN}, L={L}")
    print("=" * 72)

    if not os.path.exists(XYCE):
        print(f"ERROR: Xyce not found at {XYCE}")
        sys.exit(1)

    # ===== DC Functional Verification =====
    print(f"\n--- DC FUNCTIONAL VERIFICATION (16 vectors x 4 variants) ---")

    vth = VDD / 2.0
    dc_results = {}

    for vk in ['A','E','F','G']:
        builder, tx_count, outs, active_high = VARIANTS[vk]
        p = vk.lower()
        passed = 0
        failed = 0

        for vi in range(16):
            cir = write_dc_netlist(vk, vi)
            rc, _, _ = run_xyce(cir)
            vals = parse_prn(cir)

            ai, bi, aj, bj, exp0, exp1, exp2 = VECTORS[vi]

            if vals and len(vals) >= len(outs):
                measured = {}
                for idx, oname in enumerate(outs):
                    v = vals[idx]
                    if active_high:
                        measured[oname] = 1 if v > vth else 0
                    else:
                        # active-low: noh1 HIGH means oh1=0
                        measured[oname] = 1 if v > vth else 0

                # Check expected
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
            else:
                failed += 1

            # Cleanup
            for ext in ['.cir', '.cir.prn', '.cir.mt0']:
                f = os.path.join(WORKDIR, f"dc_{p}_v{vi}{ext}")
                if os.path.exists(f): os.remove(f)

        dc_results[vk] = (passed, failed)
        status = "PASS" if failed == 0 else "FAIL"
        print(f"  Variant {vk} ({tx_count}T): {passed}/16 {status}")

    # ===== Transient Delay + Power =====
    print(f"\n--- TRANSIENT DELAY + POWER (bi: 0→VDD @ 200ps) ---")

    tran_results = {}
    for vk in ['A','E','F','G']:
        builder, tx_count, outs, active_high = VARIANTS[vk]
        p = vk.lower()
        cir = write_tran_netlist(vk)
        rc, stdout, stderr = run_xyce(cir, timeout=60)

        measures = parse_mt0(cir)
        tpd = measures.get('tpd_oh1', None)
        i_avg = measures.get('i_avg', None)
        i_switch = measures.get('i_switch', None)

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

        tran_results[vk] = {
            'tpd_ps': tpd_ps,
            'p_switch_uw': p_switch_uw,
            'i_avg': abs(i_avg) if i_avg else 0,
            'i_switch': abs(i_switch) if i_switch else 0,
            'tx_count': tx_count,
        }

        print(f"  Variant {vk} ({tx_count}T): tpd={tpd_ps:.1f}ps, P_switch={p_switch_uw:.4f}uW")

    # ===== PPA Summary =====
    print(f"\n{'='*72}")
    print(f"  PPA COMPARISON SUMMARY")
    print(f"{'='*72}")
    print(f"\n{'Variant':>10} | {'Transistors':>11} | {'tpd (ps)':>10} | {'P_sw (uW)':>10} | {'EDP (rel)':>10} | {'Area*Delay':>11}")
    print("-" * 72)

    # Use A as baseline
    base = tran_results['A']
    base_edp = base['tpd_ps'] * base['p_switch_uw'] if base['tpd_ps'] > 0 else 1
    base_ad = base['tpd_ps'] * base['tx_count'] if base['tpd_ps'] > 0 else 1

    for vk in ['A','E','F','G']:
        r = tran_results[vk]
        edp = r['tpd_ps'] * r['p_switch_uw'] if r['tpd_ps'] > 0 else 0
        edp_rel = edp / base_edp if base_edp > 0 else 0
        ad = r['tpd_ps'] * r['tx_count'] if r['tpd_ps'] > 0 else 0
        ad_rel = ad / base_ad if base_ad > 0 else 0

        print(f"  {vk:>7} | {r['tx_count']:>11} | {r['tpd_ps']:>10.1f} | {r['p_switch_uw']:>10.4f} | {edp_rel:>10.3f} | {ad_rel:>10.3f}")

    print(f"\n  EDP = Energy-Delay Product (tpd × P_switch, lower is better)")
    print(f"  Area*Delay = tpd × transistor_count (lower is better)")

    # Find winner
    best_edp = min(tran_results.items(), key=lambda x: x[1]['tpd_ps']*x[1]['p_switch_uw'] if x[1]['tpd_ps']>0 else 1e9)
    best_area = min(tran_results.items(), key=lambda x: x[1]['tx_count'])
    best_speed = min(tran_results.items(), key=lambda x: x[1]['tpd_ps'] if x[1]['tpd_ps']>0 else 1e9)
    best_power = min(tran_results.items(), key=lambda x: x[1]['p_switch_uw'] if x[1]['p_switch_uw']>0 else 1e9)

    print(f"\n  WINNERS:")
    print(f"    Best EDP:   Variant {best_edp[0]} ({best_edp[1]['tx_count']}T)")
    print(f"    Best Area:  Variant {best_area[0]} ({best_area[1]['tx_count']}T)")
    print(f"    Best Speed: Variant {best_speed[0]} ({best_speed[1]['tpd_ps']:.1f}ps)")
    print(f"    Best Power: Variant {best_power[0]} ({best_power[1]['p_switch_uw']:.4f}uW)")

if __name__ == "__main__":
    main()
