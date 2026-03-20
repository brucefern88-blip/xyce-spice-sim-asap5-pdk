#!/usr/bin/env python3
"""
Complete PPA study: Magic extracted layout → Xyce BSIM-CMG simulation
All 4 fused Hamming cell variants (A/E/F/G)
ONLY uses Xyce — NEVER ngspice.

Flow per variant:
  1. Magic extract all + ext2spice
  2. Parse extracted SPICE, convert to Xyce BSIM-CMG format
     (remove w=, add nfin=2, fix model names, add .OPTIONS)
  3. Run Xyce DC verification (16 vectors)
  4. Run Xyce transient delay measurement
  5. Generate .raw for LTspice waveform viewing
  6. Compare PPA across all variants
"""

import subprocess, os, re, sys, glob

WORKDIR = "/Users/bruce/CLAUDE/asap5/stdcells/fused_ppa"
MAGIC = "/Users/bruce/CLAUDE/magic_new/bin/magic"
TECH = "/Users/bruce/CLAUDE/asap5/magic/asap5.tech"
XYCE = os.path.expanduser("~/xyce-stack/install/xyce/bin/Xyce")
NMOS_MODEL = "/Users/bruce/CLAUDE/asap5/spice/xyce_models/nmos_slvt_tt_cal.pm"
PMOS_MODEL = "/Users/bruce/CLAUDE/asap5/spice/xyce_models/pmos_slvt_tt_cal.pm"
VDD = 0.5

# Variant metadata
VARIANTS = {
    'A': {'tx': 48, 'outputs': ['oh0','oh1','oh2'], 'active_high': True,
           'oh1_node': 'oh1', 'oh1_edge': 'RISE'},
    'E': {'tx': 38, 'outputs': ['oh0','oh1','oh2'], 'active_high': True,
           'oh1_node': 'oh1', 'oh1_edge': 'RISE'},
    'F': {'tx': 42, 'outputs': ['oh1','oh2'], 'active_high': True,
           'oh1_node': 'oh1', 'oh1_edge': 'RISE'},
    'G': {'tx': 40, 'outputs': ['noh1','noh2'], 'active_high': False,
           'oh1_node': 'noh1', 'oh1_edge': 'FALL'},
}

# Truth table
VECTORS = []
for v in range(16):
    ai = (v >> 3) & 1; bi = (v >> 2) & 1
    aj = (v >> 1) & 1; bj = (v >> 0) & 1
    d0 = ai ^ bi; d1 = aj ^ bj
    VECTORS.append({
        'ai': ai, 'bi': bi, 'aj': aj, 'bj': bj,
        'oh0': int(d0==0 and d1==0),
        'oh1': int(d0 != d1),
        'oh2': int(d0==1 and d1==1),
    })


def run_cmd(cmd, timeout=60):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, cwd=WORKDIR)
        return r.returncode, r.stdout, r.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "TIMEOUT"


def step1_extract(variant):
    """Run Magic extraction and ext2spice."""
    cell = f"FUSED_{variant}"
    print(f"  Extracting {cell}...")
    rc, out, err = run_cmd([MAGIC, "-dnull", "-noconsole", "-T", TECH],
                           timeout=30)
    # Run via stdin
    magic_cmds = f"""load {cell}
select top cell
extract all
ext2spice lvs
ext2spice -f ngspice -o {cell}_ext.spice
quit -noprompt
"""
    r = subprocess.run([MAGIC, "-dnull", "-noconsole", "-T", TECH],
                      input=magic_cmds, capture_output=True, text=True,
                      timeout=30, cwd=WORKDIR)
    ext_file = os.path.join(WORKDIR, f"{cell}_ext.spice")
    if os.path.exists(ext_file):
        ndev = sum(1 for l in open(ext_file) if l.startswith("M"))
        print(f"    {ndev} MOSFETs extracted")
        return ext_file
    else:
        print(f"    FAILED: no ext.spice produced")
        return None


def step2_convert_to_xyce(variant, ext_spice):
    """Convert extracted SPICE to Xyce BSIM-CMG format."""
    cell = f"FUSED_{variant}"
    meta = VARIANTS[variant]

    with open(ext_spice) as f:
        lines = f.readlines()

    # Parse MOSFET instances and parasitic caps
    devices = []
    caps = []
    for line in lines:
        line = line.strip()
        if line.startswith("M"):
            devices.append(line)
        elif line.startswith("C") and "0" in line.split():
            caps.append(line)

    # Convert each MOSFET: remove w=, add nfin=2, fix model name
    xyce_devices = []
    for dev in devices:
        parts = dev.split()
        name = parts[0]
        # MOSFET: Mname drain gate source bulk model [params]
        # Find and remove w= and ad=/pd=/as=/ps= params, add nfin=2
        new_parts = []
        model_found = False
        for p in parts:
            if p.startswith("w=") or p.startswith("ad=") or p.startswith("pd=") or \
               p.startswith("as=") or p.startswith("ps="):
                continue
            # Fix model names
            if "nmos" in p.lower() or "nfet" in p.lower():
                new_parts.append("nmos_slvt")
                model_found = True
            elif "pmos" in p.lower() or "pfet" in p.lower():
                new_parts.append("pmos_slvt")
                model_found = True
            elif p.startswith("l="):
                new_parts.append("l=16n")
            else:
                new_parts.append(p)
        if not any("nfin=" in p for p in new_parts):
            new_parts.append("nfin=2")
        xyce_devices.append(" ".join(new_parts))

    return xyce_devices, caps


def step3_write_dc_deck(variant, xyce_devices, caps, vec_idx):
    """Write Xyce DC verification deck for one vector."""
    cell = f"FUSED_{variant}"
    meta = VARIANTS[variant]
    vec = VECTORS[vec_idx]
    p = variant.lower()
    fname = os.path.join(WORKDIR, f"xdc_{p}_v{vec_idx}.cir")

    with open(fname, 'w') as f:
        f.write(f"* {cell} DC verification vec{vec_idx}\n")
        f.write(f".include '{NMOS_MODEL}'\n")
        f.write(f".include '{PMOS_MODEL}'\n")
        f.write(".OPTIONS DEVICE GMIN=1e-12\n")
        f.write(".OPTIONS NONLIN RELTOL=1e-4 ABSTOL=1e-9 SEARCHMETHOD=2\n\n")
        f.write(f"Vvdd VDD 0 {VDD}\nVgnd VSS 0 0\n")
        f.write(f"Vai ai 0 {VDD if vec['ai'] else 0}\n")
        f.write(f"Vbi bi 0 {VDD if vec['bi'] else 0}\n")
        f.write(f"Vaj aj 0 {VDD if vec['aj'] else 0}\n")
        f.write(f"Vbj bj 0 {VDD if vec['bj'] else 0}\n\n")
        for dev in xyce_devices:
            f.write(dev + "\n")
        f.write("\n")
        for cap in caps:
            f.write(cap + "\n")
        # Load caps on outputs
        for out in meta['outputs']:
            f.write(f"CL_{out} {out} 0 1f\n")
        f.write("\n.OP\n")
        out_str = " ".join(f"V({o})" for o in meta['outputs'])
        f.write(f".PRINT DC {out_str} I(Vvdd)\n")
        f.write(".END\n")
    return fname


def step4_write_tran_deck(variant, xyce_devices, caps, raw_file=None):
    """Write Xyce transient delay deck."""
    cell = f"FUSED_{variant}"
    meta = VARIANTS[variant]
    p = variant.lower()
    fname = os.path.join(WORKDIR, f"xtran_{p}.cir")

    with open(fname, 'w') as f:
        f.write(f"* {cell} Transient Delay — Xyce BSIM-CMG post-layout\n")
        f.write(f".include '{NMOS_MODEL}'\n")
        f.write(f".include '{PMOS_MODEL}'\n")
        f.write(".OPTIONS DEVICE GMIN=1e-12\n")
        f.write(".OPTIONS NONLIN RELTOL=1e-4 ABSTOL=1e-9\n")
        f.write(".OPTIONS TIMEINT METHOD=trap RELTOL=1e-3 ABSTOL=1e-12\n")
        f.write(".OPTIONS MEASURE MEASDGT=6\n\n")
        f.write(f"Vvdd VDD 0 {VDD}\nVgnd VSS 0 0\n")
        f.write(f"Vai ai 0 DC 0\n")
        f.write(f"Vbi bi 0 PWL(0 0 200p 0 205p {VDD})\n")
        f.write(f"Vaj aj 0 DC 0\n")
        f.write(f"Vbj bj 0 DC 0\n\n")
        for dev in xyce_devices:
            f.write(dev + "\n")
        f.write("\n")
        for cap in caps:
            f.write(cap + "\n")
        for out in meta['outputs']:
            f.write(f"CL_{out} {out} 0 1f\n")
        f.write(f"\n.TRAN 0.5p 800p\n\n")
        # Print all signals for waveform
        out_str = " ".join(f"V({o})" for o in meta['outputs'])
        f.write(f".PRINT TRAN V(bi) {out_str} I(Vvdd)\n\n")
        # Delay measurement
        node = meta['oh1_node']
        edge = meta['oh1_edge']
        f.write(f".MEASURE TRAN tpd_oh1 TRIG V(bi) VAL={VDD/2} RISE=1\n")
        f.write(f"+  TARG V({node}) VAL={VDD/2} {edge}=1\n")
        f.write(f".MEASURE TRAN i_avg AVG I(Vvdd) FROM=0 TO=800p\n")
        f.write(f".MEASURE TRAN i_switch AVG I(Vvdd) FROM=200p TO=600p\n")
        f.write(".END\n")
    return fname


def run_xyce(cir_file, raw_file=None, timeout=60):
    """Run Xyce simulation."""
    cmd = [XYCE, "-max-warnings", "10"]
    if raw_file:
        cmd += ["-r", raw_file]
    cmd.append(cir_file)
    rc, out, err = run_cmd(cmd, timeout=timeout)
    return rc


def parse_mt0(cir_file):
    """Parse Xyce .mt0 measurement file."""
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
    """Parse Xyce .prn output for DC values."""
    prn = cir_file + ".prn"
    if not os.path.exists(prn):
        return None
    with open(prn) as f:
        lines = f.readlines()
    header = lines[0].split() if lines else []
    for line in lines[1:]:
        parts = line.strip().split()
        if len(parts) >= 2:
            try:
                return {h: float(v) for h, v in zip(header[1:], parts[1:])}
            except ValueError:
                pass
    return None


def main():
    os.chdir(WORKDIR)

    print("=" * 78)
    print("  FUSED HAMMING CELL — COMPLETE POST-LAYOUT PPA STUDY")
    print("  Magic ASAP5 extracted → Xyce BSIM-CMG level=107 ONLY")
    print(f"  SLVT TT, VDD={VDD}V, nfin=2, L=16nm")
    print("=" * 78)

    results = {}

    for variant in ['A', 'E', 'F', 'G']:
        cell = f"FUSED_{variant}"
        meta = VARIANTS[variant]
        print(f"\n{'='*60}")
        print(f"  VARIANT {variant} ({meta['tx']}T)")
        print(f"{'='*60}")

        # Step 1: Extract
        ext_spice = step1_extract(variant)
        if not ext_spice:
            print(f"  SKIP: extraction failed")
            continue

        # Step 2: Convert to Xyce format
        xyce_devs, caps = step2_convert_to_xyce(variant, ext_spice)
        print(f"  Converted: {len(xyce_devs)} devices, {len(caps)} parasitic caps")

        # Step 3: DC verification (all 16 vectors)
        print(f"  DC verification (16 vectors)...")
        dc_pass = 0
        dc_fail = 0
        vth = VDD / 2

        for vi in range(16):
            cir = step3_write_dc_deck(variant, xyce_devs, caps, vi)
            run_xyce(cir)
            vals = parse_prn(cir)
            vec = VECTORS[vi]

            ok = True
            if vals:
                for out in meta['outputs']:
                    key = f"V({out.upper()})"
                    v = vals.get(key, None)
                    if v is None:
                        # Try lowercase
                        key = f"V({out})"
                        v = vals.get(key, None)
                    if v is not None:
                        measured = 1 if v > vth else 0
                        if meta['active_high']:
                            expected = vec.get(out, -1)
                        else:
                            # Active-low: noh1 HIGH = oh1 LOW
                            base = out.replace('noh', 'oh')
                            expected = 1 - vec.get(base, -1)
                        if measured != expected:
                            ok = False
                    else:
                        ok = False
            else:
                ok = False

            if ok:
                dc_pass += 1
            else:
                dc_fail += 1

            # Cleanup
            for ext in ['.cir', '.cir.prn', '.cir.mt0']:
                p = variant.lower()
                f = os.path.join(WORKDIR, f"xdc_{p}_v{vi}{ext}")
                if os.path.exists(f):
                    os.remove(f)

        status = "PASS" if dc_fail == 0 else f"FAIL ({dc_fail} vectors)"
        print(f"    DC: {dc_pass}/16 {status}")

        # Step 4: Transient delay + power
        print(f"  Transient simulation...")
        p = variant.lower()
        tran_cir = step4_write_tran_deck(variant, xyce_devs, caps)
        raw_file = os.path.join(WORKDIR, f"xyce_{p}.raw")
        run_xyce(tran_cir, raw_file=raw_file)

        measures = parse_mt0(tran_cir)
        tpd = measures.get('tpd_oh1', None)
        i_avg = measures.get('i_avg', None)
        i_switch = measures.get('i_switch', None)

        tpd_ps = abs(tpd) * 1e12 if tpd else -1
        p_sw = abs(i_switch) * VDD * 1e6 if i_switch else (abs(i_avg) * VDD * 1e6 if i_avg else -1)

        print(f"    tpd = {tpd_ps:.1f} ps")
        print(f"    P_switch = {p_sw:.4f} uW")
        print(f"    .raw file: {raw_file}")

        results[variant] = {
            'tx': meta['tx'],
            'dc_pass': dc_pass,
            'dc_fail': dc_fail,
            'tpd_ps': tpd_ps,
            'p_sw_uw': p_sw,
            'raw_file': raw_file,
        }

    # ===================== PPA Comparison =====================
    print(f"\n{'='*78}")
    print(f"  POST-LAYOUT PPA COMPARISON (Xyce BSIM-CMG, extracted parasitics)")
    print(f"{'='*78}")
    print(f"\n{'Variant':>10} │ {'Tx':>3} │ {'DC':>6} │ {'tpd(ps)':>8} │ {'P_sw(uW)':>9} │ {'EDP(rel)':>9} │ {'Raw File':>20}")
    print("─" * 78)

    base_edp = None
    for v in ['A','E','F','G']:
        if v not in results:
            continue
        r = results[v]
        edp = r['tpd_ps'] * r['p_sw_uw'] if r['tpd_ps'] > 0 and r['p_sw_uw'] > 0 else 0
        if v == 'A':
            base_edp = edp if edp > 0 else 1
        edp_rel = edp / base_edp if base_edp and base_edp > 0 else 0
        dc_str = f"{r['dc_pass']}/16" if r['dc_fail'] == 0 else f"FAIL"
        raw_name = os.path.basename(r['raw_file']) if r['raw_file'] else "n/a"
        print(f"  {v:>6}({r['tx']}T) │ {r['tx']:>3} │ {dc_str:>6} │ {r['tpd_ps']:>8.1f} │ {r['p_sw_uw']:>9.4f} │ {edp_rel:>9.3f} │ {raw_name:>20}")

    # Winners
    valid = {v: r for v, r in results.items() if r['tpd_ps'] > 0 and r['p_sw_uw'] > 0}
    if valid:
        best_speed = min(valid, key=lambda v: valid[v]['tpd_ps'])
        best_power = min(valid, key=lambda v: valid[v]['p_sw_uw'])
        best_edp = min(valid, key=lambda v: valid[v]['tpd_ps'] * valid[v]['p_sw_uw'])
        best_area = min(valid, key=lambda v: valid[v]['tx'])

        print(f"\n  WINNERS:")
        print(f"    Speed:  Variant {best_speed} ({valid[best_speed]['tpd_ps']:.1f} ps)")
        print(f"    Power:  Variant {best_power} ({valid[best_power]['p_sw_uw']:.4f} uW)")
        print(f"    EDP:    Variant {best_edp}")
        print(f"    Area:   Variant {best_area} ({valid[best_area]['tx']}T)")

    # Print .raw file paths for LTspice
    print(f"\n  .raw files for LTspice waveform viewing:")
    for v in ['A','E','F','G']:
        if v in results and results[v]['raw_file']:
            print(f"    open -a LTspice {results[v]['raw_file']}")

    print(f"\n{'='*78}")
    print(f"  ALL SIMULATIONS USED XYCE BSIM-CMG level=107 — NO ngspice")
    print(f"{'='*78}")


if __name__ == "__main__":
    main()
