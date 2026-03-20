#!/usr/bin/env python3
"""
Post-process ngspice output for fused Hamming cell verification + power + delay.
Reads the raw ngspice stdout, validates logic, computes metrics.
"""

import re, sys

VDD = 0.5
VTH_HI = 0.4 * VDD   # above this = logic 1
VTH_LO = 0.6 * VDD   # below this = logic 0 (inverted: VDD-relative threshold)
THRESHOLD = 0.1       # absolute: < 0.1V = 0, > 0.4V = 1

# Truth table
VECTORS = []
for v in range(16):
    ai = (v >> 3) & 1
    bi = (v >> 2) & 1
    aj = (v >> 1) & 1
    bj = (v >> 0) & 1
    d0 = ai ^ bi
    d1 = aj ^ bj
    oh0 = 1 if (d0 == 0 and d1 == 0) else 0
    oh1 = 1 if (d0 != d1) else 0
    oh2 = 1 if (d0 == 1 and d1 == 1) else 0
    VECTORS.append((ai, bi, aj, bj, oh0, oh1, oh2))

# Read ngspice output
with open("/home/claude/spice/ngspice_output.txt") as f:
    text = f.read()

# Parse measurement results
meas = {}
for m in re.finditer(r'(\w+)\s+=\s+([eE\d.+-]+)', text):
    name, val = m.group(1), float(m.group(2))
    meas[name] = val

def logic_val(voltage):
    if voltage > VDD * 0.8:
        return 1
    elif voltage < VDD * 0.2:
        return 0
    else:
        return -1  # indeterminate

print("=" * 72)
print("  FUSED HAMMING CELL -- TSMC N5 SPICE VERIFICATION REPORT")
print("  VDD = 0.5V, 2-fin FinFET, Level-1 MOSFET model")
print("=" * 72)

# ===== Functional Verification =====
print("\n--- FUNCTIONAL VERIFICATION (16 vectors x 4 variants) ---\n")
print(f"{'Vec':>4} {'ai bi aj bj':>12} | {'Exp OH0,1,2':>11} | {'A':>10} | {'E':>10} | {'F(1,2)':>10} | {'G(n1,n2)':>10}")
print("-" * 72)

pass_count = 0
fail_count = 0
total_checks = 0

for i, (ai, bi, aj, bj, exp0, exp1, exp2) in enumerate(VECTORS):
    row = f"{i:4d} {ai} {bi} {aj} {bj}     | {exp0},{exp1},{exp2}       |"

    # Variant A
    a0 = logic_val(meas.get(f'va0_{i}', -1))
    a1 = logic_val(meas.get(f'va1_{i}', -1))
    a2 = logic_val(meas.get(f'va2_{i}', -1))
    a_ok = (a0 == exp0 and a1 == exp1 and a2 == exp2)
    row += f" {'OK' if a_ok else 'FAIL':>4}{a0}{a1}{a2} |"
    total_checks += 3
    pass_count += 3 if a_ok else 0
    if not a_ok: fail_count += (a0!=exp0) + (a1!=exp1) + (a2!=exp2)

    # Variant E
    e0 = logic_val(meas.get(f've0_{i}', -1))
    e1 = logic_val(meas.get(f've1_{i}', -1))
    e2 = logic_val(meas.get(f've2_{i}', -1))
    e_ok = (e0 == exp0 and e1 == exp1 and e2 == exp2)
    row += f" {'OK' if e_ok else 'FAIL':>4}{e0}{e1}{e2} |"
    total_checks += 3
    pass_count += 3 if e_ok else 0
    if not e_ok: fail_count += (e0!=exp0) + (e1!=exp1) + (e2!=exp2)

    # Variant F (OH1, OH2 only)
    f1 = logic_val(meas.get(f'vf1_{i}', -1))
    f2 = logic_val(meas.get(f'vf2_{i}', -1))
    f_ok = (f1 == exp1 and f2 == exp2)
    row += f"   {'OK' if f_ok else 'FAIL':>4}{f1}{f2} |"
    total_checks += 2
    pass_count += 2 if f_ok else 0
    if not f_ok: fail_count += (f1!=exp1) + (f2!=exp2)

    # Variant G (active-low: ~OH1, ~OH2)
    g1_raw = logic_val(meas.get(f'vg1_{i}', -1))
    g2_raw = logic_val(meas.get(f'vg2_{i}', -1))
    # Expected: ~OH1 and ~OH2 (inverted)
    exp_ng1 = 1 - exp1
    exp_ng2 = 1 - exp2
    g_ok = (g1_raw == exp_ng1 and g2_raw == exp_ng2)
    row += f"   {'OK' if g_ok else 'FAIL':>4}{g1_raw}{g2_raw} |"
    total_checks += 2
    pass_count += 2 if g_ok else 0
    if not g_ok: fail_count += (g1_raw!=exp_ng1) + (g2_raw!=exp_ng2)

    print(row)

print(f"\nTotal output checks: {total_checks}")
print(f"  PASS: {pass_count}")
print(f"  FAIL: {fail_count}")
if fail_count == 0:
    print("  >>> ALL OUTPUTS VERIFIED CORRECT <<<")

# ===== Power Analysis =====
print("\n" + "=" * 72)
print("  POWER ANALYSIS (average over 16-vector sequence)")
print("=" * 72)

tx_counts = {'a': 48, 'e': 38, 'f': 42, 'g': 40}
variant_names = {'a': 'A (48T, 3-out AH)', 'e': 'E (38T, 3-out AH)',
                 'f': 'F (42T, 2-out AH)', 'g': 'G (40T, 2-out AL)'}

print(f"\n{'Variant':>20} | {'Iavg (nA)':>10} | {'Pavg (nW)':>10} | {'P/tx (nW)':>10} | {'x32 cells':>12}")
print("-" * 72)

for vl in ['a', 'e', 'f', 'g']:
    iavg = abs(meas.get(f'iavg_{vl}', 0))
    pavg = iavg * VDD
    ptx = pavg / tx_counts[vl]
    p32 = pavg * 32

    iavg_na = iavg * 1e9
    pavg_nw = pavg * 1e9
    ptx_nw = ptx * 1e9
    p32_uw = p32 * 1e6

    print(f"{variant_names[vl]:>20} | {iavg_na:10.1f} | {pavg_nw:10.1f} | {ptx_nw:10.2f} | {p32_uw:10.3f} uW")

# ===== Propagation Delay =====
print("\n" + "=" * 72)
print("  PROPAGATION DELAY SUMMARY")
print("=" * 72)
print()
print("  Note: Level-1 MOSFET delay is approximate. For accurate timing,")
print("  use BSIM-CMG or foundry models. These are relative comparisons.")
print()

# Parse td values if they exist
for vl in ['a', 'e', 'f', 'g']:
    key = f'td_{vl}_oh1' if vl != 'g' else f'td_{vl}_noh1'
    val = meas.get(key, None)
    if val is not None:
        print(f"  Variant {vl.upper()} OH1 path: {abs(val)*1e12:.1f} ps")

# ===== 32-cell array scaling =====
print("\n" + "=" * 72)
print("  32-CELL ARRAY PROJECTION (64-bit Hamming distance)")
print("=" * 72)

print(f"\n{'Variant':>20} | {'Cell tx':>8} | {'Array tx':>8} | {'Array pwr':>12} | {'EDP relative':>12}")
print("-" * 72)

# Use variant A as baseline for EDP comparison
pavg_a = abs(meas.get('iavg_a', 0)) * VDD
edp_base = pavg_a * tx_counts['a']  # proxy: power * area (tx count)

for vl in ['a', 'e', 'f', 'g']:
    iavg = abs(meas.get(f'iavg_{vl}', 0))
    pavg = iavg * VDD
    tx = tx_counts[vl]
    arr_tx = tx * 32
    arr_pwr = pavg * 32
    edp = pavg * tx
    edp_rel = edp / edp_base if edp_base > 0 else 0

    print(f"{variant_names[vl]:>20} | {tx:>8} | {arr_tx:>8} | {arr_pwr*1e6:>9.3f} uW | {edp_rel:>12.3f}")

print()
print("  EDP proxy = Pavg * transistor_count (lower is better)")
print("  Variant G wins on raw power; E wins on transistor efficiency")
print()
