#!/usr/bin/env python3
"""
Parse ngspice output from char_fused_all.sp and generate a comparison table
for fused Hamming cell variants A, E, F, G.

Usage:
    python3 gen_fused_report.py                  # reads char_fused_all.log
    python3 gen_fused_report.py --run             # runs ngspice first
    python3 gen_fused_report.py somefile.log      # reads specified file
"""

import re
import sys
import os
import subprocess

# Transistor counts
TCOUNTS = {"A": 48, "E": 38, "F": 42, "G": 40}

# Output ports per variant
OUTPUTS = {
    "A": ["oh0", "oh1", "oh2"],
    "E": ["oh0", "oh1", "oh2"],
    "F": ["oh1", "oh2"],
    "G": ["noh1", "noh2"],
}

VDD = 0.5
T_MEAS = 16.0e-9 - 0.2e-9     # measurement window (0.2ns to 16ns)
T_LEAK_WIN = 0.9e-9 - 0.3e-9   # leakage window (0.3ns to 0.9ns)

# Output switching events per variant over 16 vectors (from truth table analysis)
# OH0 transitions: 6 (high at vec 0,3,12,15; changes at boundaries 0/1,2/3,3/4,11/12,12/13,14/15)
# OH1 transitions: 12 (high at vec 1,2,4,7,8,11,13,14)
# OH2 transitions: 8 (high at vec 5,6,9,10)
# A,E: OH0(6)+OH1(12)+OH2(8) = 26 output transitions
# F: OH1(12)+OH2(8) = 20
# G: nOH1(12)+nOH2(8) = 20
N_SWITCH = {"A": 26, "E": 26, "F": 20, "G": 20}

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


def run_ngspice():
    """Run ngspice in batch mode and return combined output."""
    print("Running ngspice -b char_fused_all.sp ...")
    result = subprocess.run(
        ["ngspice", "-b", "char_fused_all.sp"],
        capture_output=True, text=True, timeout=300,
        cwd=SCRIPT_DIR
    )
    output = result.stdout + "\n" + result.stderr
    logpath = os.path.join(SCRIPT_DIR, "char_fused_all.log")
    with open(logpath, "w") as f:
        f.write(output)
    print(f"Saved output to {logpath} ({len(output)} bytes)")
    return output


def parse_measures(text):
    """Parse .meas results from ngspice output.
    Only keep the first occurrence of each measurement (avoid double-run dupes).
    """
    measures = {}
    for line in text.split("\n"):
        m = re.match(
            r'^\s*(\w+)\s*=\s*([+-]?\d+\.?\d*[eE][+-]?\d+|[+-]?\d+\.?\d*)\b',
            line
        )
        if m:
            name = m.group(1).lower()
            if name not in measures:  # first occurrence only
                try:
                    measures[name] = float(m.group(2))
                except ValueError:
                    pass
    return measures


def fmt(val, unit, digits=3):
    """Format value in engineering notation with unit."""
    if val is None:
        return "N/A"
    abs_val = abs(val)
    if abs_val == 0:
        return f"0 {unit}"
    prefixes = [
        (1e-15, "f"), (1e-12, "p"), (1e-9, "n"), (1e-6, "u"),
        (1e-3, "m"), (1, ""), (1e3, "k"),
    ]
    for scale, prefix in prefixes:
        if abs_val < scale * 1000:
            return f"{val/scale:.{digits}g} {prefix}{unit}"
    return f"{val:.{digits}g} {unit}"


def g(meas, key):
    return meas.get(key)


def main():
    logfile = os.path.join(SCRIPT_DIR, "char_fused_all.log")
    do_run = False

    for arg in sys.argv[1:]:
        if arg == "--run":
            do_run = True
        elif not arg.startswith("-"):
            logfile = arg

    if do_run:
        text = run_ngspice()
    else:
        try:
            with open(logfile, "r") as f:
                text = f.read()
            print(f"Reading from {logfile}")
        except FileNotFoundError:
            print(f"{logfile} not found, running ngspice...")
            text = run_ngspice()

    m = parse_measures(text)

    if not m:
        print("ERROR: No measurements found in ngspice output.")
        for line in text.split("\n")[:80]:
            print(f"  {line}")
        sys.exit(1)

    # --- Raw measurements ---
    print("\n" + "=" * 78)
    print("RAW MEASUREMENTS")
    print("=" * 78)
    for k in sorted(m.keys()):
        print(f"  {k:30s} = {m[k]:+13.5e}")

    # --- Per-variant power and energy ---
    # i(Vam_x) is positive when current flows from vdd_top into circuit
    # Power = i_avg * VDD, Energy = Q * VDD
    variants = ["A", "E", "F", "G"]
    pref = {"A": "a", "E": "e", "F": "f", "G": "g"}

    pavg = {}
    pleak = {}
    etotal = {}
    eleak = {}
    for v in variants:
        p = pref[v]
        i_avg = g(m, f"i{p}_avg")
        i_leak = g(m, f"i{p}_leak")
        pavg[v] = i_avg * VDD if i_avg is not None else None
        pleak[v] = i_leak * VDD if i_leak is not None else None
        q_total = g(m, f"q{p}_total")
        q_leak = g(m, f"q{p}_leak_q")
        etotal[v] = q_total * VDD if q_total is not None else None
        eleak[v] = q_leak * VDD if q_leak is not None else None

    edyn = {}
    eswitch = {}
    etrans = {}
    for v in variants:
        if etotal[v] is not None and pleak[v] is not None:
            edyn[v] = etotal[v] - pleak[v] * T_MEAS
        elif etotal[v] is not None:
            edyn[v] = etotal[v]
        else:
            edyn[v] = None

        if edyn[v] is not None:
            eswitch[v] = edyn[v] / N_SWITCH[v]
        else:
            eswitch[v] = None

        if etotal[v] is not None:
            etrans[v] = etotal[v] / TCOUNTS[v]
        else:
            etrans[v] = None

    # --- Delays ---
    delay_data = {
        "A": [
            ("bj->OH0 fall (hd 0->1)", g(m, "tpd_a_oh0_f_bj")),
            ("bj->OH1 rise (hd 0->1)", g(m, "tpd_a_oh1_r_bj")),
            ("bi->OH1 rise (hd 0->1)", g(m, "tpd_a_oh1_r_bi")),
            ("bj->OH2 rise (hd 1->2)", g(m, "tpd_a_oh2_r_bj")),
            ("bj->OH1 fall (hd 1->2)", g(m, "tpd_a_oh1_f_bj")),
        ],
        "E": [
            ("bj->OH0 fall (hd 0->1)", g(m, "tpd_e_oh0_f_bj")),
            ("bj->OH1 rise (hd 2->1)", g(m, "tpd_e_oh1_r_bj")),
            ("bi->OH1 rise (hd 0->1)", g(m, "tpd_e_oh1_r_bi")),
            ("bj->OH2 rise (hd 1->2)", g(m, "tpd_e_oh2_r_bj")),
        ],
        "F": [
            ("bj->OH1 rise (hd 0->1)", g(m, "tpd_f_oh1_r_bj")),
            ("bi->OH1 rise (hd 0->1)", g(m, "tpd_f_oh1_r_bi")),
            ("bj->OH2 rise (hd 1->2)", g(m, "tpd_f_oh2_r_bj")),
            ("bj->OH1 fall (hd 1->2)", g(m, "tpd_f_oh1_f_bj")),
        ],
        "G": [
            ("bj->nOH1 fall (hd 0->1)", g(m, "tpd_g_noh1_f_bj")),
            ("bi->nOH1 fall (hd 0->1)", g(m, "tpd_g_noh1_f_bi")),
            ("bj->nOH2 fall (hd 1->2)", g(m, "tpd_g_noh2_f_bj")),
            ("bj->nOH1 rise (hd 1->2)", g(m, "tpd_g_noh1_r_bj")),
        ],
    }

    # Transition times
    trise = {
        "A": g(m, "trise_a_oh1"),
        "E": g(m, "trise_e_oh1"),
        "F": g(m, "trise_f_oh1"),
        "G": g(m, "tfall_g_noh1"),
    }

    # Critical path delay: bj -> OH1/nOH1 (the longest input-to-output path)
    crit = {}
    for v in variants:
        delays = [d for _, d in delay_data[v] if d is not None and d > 0]
        crit[v] = max(delays) if delays else None

    # ==================================================================
    # REPORT
    # ==================================================================
    print("\n" + "=" * 78)
    print("FUSED HAMMING CELL CHARACTERIZATION REPORT")
    print(f"VDD = {VDD}V | T = 25C | C_load = 1fF | Input slew = 50ps")
    print("=" * 78)

    # --- Sanity Check ---
    print("\n--- Functional Sanity Check ---")
    checks = [
        ("A", "Vec 0 (hd=0)", "H L L",
         [g(m,"a_oh0_v0"), g(m,"a_oh1_v0"), g(m,"a_oh2_v0")]),
        ("A", "Vec 1 (hd=1)", "L H L",
         [g(m,"a_oh0_v1"), g(m,"a_oh1_v1"), g(m,"a_oh2_v1")]),
        ("A", "Vec 5 (hd=2)", "L L H",
         [g(m,"a_oh0_v5"), g(m,"a_oh1_v5"), g(m,"a_oh2_v5")]),
        ("E", "Vec 0 (hd=0)", "H x L",
         [g(m,"e_oh0_v0"), g(m,"e_oh1_v0"), None]),
        ("E", "Vec 1 (hd=1)", "x H x",
         [None, g(m,"e_oh1_v1"), None]),
        ("E", "Vec 5 (hd=2)", "x x H",
         [None, None, g(m,"e_oh2_v5")]),
        ("F", "Vec 1 (hd=1)", "H x",
         [g(m,"f_oh1_v1"), None]),
        ("F", "Vec 5 (hd=2)", "x H",
         [None, g(m,"f_oh2_v5")]),
        ("G", "Vec 0 (hd=0)", "H H",
         [g(m,"g_noh1_v0"), g(m,"g_noh2_v1")]),
        ("G", "Vec 1 (hd=1)", "L H",
         [g(m,"g_noh1_v1"), g(m,"g_noh2_v1")]),
        ("G", "Vec 5 (hd=2)", "x L",
         [None, g(m,"g_noh2_v5")]),
    ]
    all_pass = True
    for var, desc, expect, vals in checks:
        vstr = " ".join(f"{v:.3f}V" if v is not None else "---" for v in vals)
        # Simple pass/fail: H > 0.4V, L < 0.1V
        ok = True
        for v_meas, e in zip(vals, expect.split()):
            if v_meas is None or e == "x":
                continue
            if e == "H" and v_meas < 0.4:
                ok = False
            if e == "L" and v_meas > 0.1:
                ok = False
        status = "PASS" if ok else "FAIL"
        if not ok:
            all_pass = False
        print(f"  [{status}] {var} {desc}: {vstr}  (expect {expect})")
    print(f"  Overall: {'ALL PASS' if all_pass else 'SOME FAILURES'}")

    # --- Power Table ---
    print("\n--- Average Power ---")
    print(f"{'Variant':<12} {'#T':>4} {'P_avg':>12} {'P_leak':>12} {'P_dyn':>12}")
    print("-" * 58)
    for v in variants:
        p_dyn = pavg[v] - pleak[v] if pavg[v] and pleak[v] else None
        print(f"  {v:<10} {TCOUNTS[v]:>4d} "
              f"{fmt(pavg[v], 'W'):>12} {fmt(pleak[v], 'W'):>12} {fmt(p_dyn, 'W'):>12}")

    # --- Energy Table ---
    print("\n--- Energy (over {:.1f}ns window) ---".format(T_MEAS * 1e9))
    print(f"{'Variant':<12} {'E_total':>12} {'E_dynamic':>12} "
          f"{'E/switch':>12} {'E/transistor':>14}")
    print("-" * 68)
    for v in variants:
        print(f"  {v:<10} "
              f"{fmt(etotal[v], 'J'):>12} {fmt(edyn[v], 'J'):>12} "
              f"{fmt(eswitch[v], 'J'):>12} {fmt(etrans[v], 'J'):>14}")

    # --- Delay Table ---
    print("\n--- Propagation Delays (50% VDD threshold) ---")
    for v in variants:
        print(f"\n  Variant {v} ({TCOUNTS[v]}T):")
        for desc, val in delay_data[v]:
            is_crit = (val is not None and val == crit[v])
            mark = " <-- worst-case" if is_crit else ""
            print(f"    {desc:<30s} {fmt(val, 's'):>12}{mark}")

    # --- Transition Times ---
    print("\n--- Output Transition Times (10%-90% of VDD) ---")
    for v in variants:
        label = "OH1 rise" if v != "G" else "nOH1 fall"
        print(f"  Variant {v}: {label:<15s} {fmt(trise[v], 's'):>12}")

    # ==================================================================
    # Grand Comparison Table
    # ==================================================================
    W = 14
    print("\n" + "=" * 78)
    print("SUMMARY COMPARISON TABLE")
    print("=" * 78)
    hdr = f"{'Metric':<30} {'A (48T)':>{W}} {'E (38T)':>{W}} {'F (42T)':>{W}} {'G (40T)':>{W}}"
    print(hdr)
    print("-" * len(hdr))

    def row(label, vals, unit, digits=3):
        print(f"{label:<30}", end="")
        for v in variants:
            print(f" {fmt(vals.get(v), unit, digits):>{W-1}}", end="")
        print()

    row("Transistor count", {v: TCOUNTS[v] for v in variants}, "", 0)
    row("Output count", {v: len(OUTPUTS[v]) for v in variants}, "", 0)
    row("Worst-case delay", crit, "s")
    row("Avg power", pavg, "W")
    row("Leakage power", pleak, "W")
    row("Total energy", etotal, "J")
    row("Dynamic energy", edyn, "J")
    row("E per switch event", eswitch, "J")
    row("E per transistor", etrans, "J")
    row("OH1 transition time", trise, "s")

    # --- Normalized ---
    print(f"\n{'Normalized to Variant A':<30}", end="")
    for v in variants:
        print(f" {'':>{W-1}}", end="")
    print()
    print("-" * len(hdr))

    def row_norm(label, vals):
        ref = vals.get("A")
        print(f"{label:<30}", end="")
        for v in variants:
            val = vals.get(v)
            if val is not None and ref is not None and ref != 0:
                print(f" {val/ref:>{W-2}.3f}x", end="")
            else:
                print(f" {'N/A':>{W-1}}", end="")
        print()

    row_norm("Delay (norm)", crit)
    row_norm("Power (norm)", pavg)
    row_norm("Energy (norm)", etotal)
    row_norm("Transistors (norm)", {v: TCOUNTS[v] for v in variants})

    # PDP (power-delay product)
    pdp = {}
    for v in variants:
        if crit[v] and pavg[v]:
            pdp[v] = crit[v] * pavg[v]
        else:
            pdp[v] = None
    row_norm("PDP (norm)", pdp)

    # EDP (energy-delay product)
    edp = {}
    for v in variants:
        if crit[v] and etotal[v]:
            edp[v] = crit[v] * etotal[v]
        else:
            edp[v] = None
    row_norm("EDP (norm)", edp)

    print("\n" + "=" * 78)
    print("END OF REPORT")
    print("=" * 78)


if __name__ == "__main__":
    main()
