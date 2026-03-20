#!/usr/bin/env python3
"""
Generate ngspice netlists for fused Hamming cell variants A, E, F, G.
Transistor-level CMOS, TSMC N5 approximate models.
Full 16-vector functional verification + power measurement.

Device parameters (TSMC N5, 2-fin FinFET):
  Per fin:  IDSAT_N=9uA, IDSAT_P=6uA, Vtn=0.3V, |Vtp|=0.3V
            Cg=0.05fF, Cd=Cs=0.02fF
  2-fin:    IDSAT_N=18uA, IDSAT_P=12uA
            Cg=0.10fF, Cd=Cs=0.04fF

Level-1 MOSFET calibration:
  IDSAT = (KP/2)*(W/L)*(VGS-VT)^2
  W=100n, L=12n => W/L=8.333
  At VGS=0.5V, VT=0.3V: (VGS-VT)^2 = 0.04
  NMOS: 18uA = (KP_N/2)*8.333*0.04 => KP_N = 108u
  PMOS: 12uA = (KP_P/2)*8.333*0.04 => KP_P = 72u
"""

import os

# ===========================================================================
#  Constants
# ===========================================================================
VDD = 0.5
W = "100n"
L = "12n"
T_VEC = 1000e-12    # 1ns per input vector (adequate for 200mV overdrive)
N_VEC = 16
T_RISE = 5e-12      # 5ps rise/fall
C_LOAD = "1f"        # 1fF output load
C_INT = "0.15f"      # internal node parasitic

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


def pwl_source(name, node, bits):
    points = []
    for i, b in enumerate(bits):
        val = VDD if b else 0.0
        t_start = i * T_VEC
        if i == 0:
            points.append(f"{t_start:.4e} {val}")
        else:
            prev_val = VDD if bits[i-1] else 0.0
            if val != prev_val:
                points.append(f"{t_start:.4e} {prev_val}")
                points.append(f"{t_start + T_RISE:.4e} {val}")
            else:
                points.append(f"{t_start:.4e} {val}")
    return f"V{name} {node} 0 PWL({' '.join(points)})"


# ===========================================================================
#  Gate primitives
# ===========================================================================

def inv(prefix, out, inp, vdd, gnd):
    return (
        f"M{prefix}_p {out} {inp} {vdd} {vdd} pch W={W} L={L}\n"
        f"M{prefix}_n {out} {inp} {gnd} {gnd} nch W={W} L={L}\n"
        f"C{prefix}_i {out} 0 {C_INT}"
    )

def nand2(prefix, out, a, b, vdd, gnd):
    mid = f"{prefix}_ns"
    return (
        f"M{prefix}_p1 {out} {a} {vdd} {vdd} pch W={W} L={L}\n"
        f"M{prefix}_p2 {out} {b} {vdd} {vdd} pch W={W} L={L}\n"
        f"M{prefix}_n1 {out} {a} {mid} {gnd} nch W={W} L={L}\n"
        f"M{prefix}_n2 {mid} {b} {gnd} {gnd} nch W={W} L={L}\n"
        f"C{prefix}_i {out} 0 {C_INT}"
    )

def nor2(prefix, out, a, b, vdd, gnd):
    mid = f"{prefix}_ps"
    return (
        f"M{prefix}_p1 {mid} {a} {vdd} {vdd} pch W={W} L={L}\n"
        f"M{prefix}_p2 {out} {b} {mid} {vdd} pch W={W} L={L}\n"
        f"M{prefix}_n1 {out} {a} {gnd} {gnd} nch W={W} L={L}\n"
        f"M{prefix}_n2 {out} {b} {gnd} {gnd} nch W={W} L={L}\n"
        f"C{prefix}_i {out} 0 {C_INT}"
    )

def aoi22(prefix, out, a, b, c, d, vdd, gnd):
    """AOI22: ~(A&B + C&D). 8T. PUN stack=2, PDN stack=2."""
    pmid = f"{prefix}_pm"
    nm1 = f"{prefix}_nm1"
    nm2 = f"{prefix}_nm2"
    return (
        f"M{prefix}_p1 {pmid} {a} {vdd} {vdd} pch W={W} L={L}\n"
        f"M{prefix}_p2 {pmid} {b} {vdd} {vdd} pch W={W} L={L}\n"
        f"M{prefix}_p3 {out}  {c} {pmid} {vdd} pch W={W} L={L}\n"
        f"M{prefix}_p4 {out}  {d} {pmid} {vdd} pch W={W} L={L}\n"
        f"M{prefix}_n1 {out}  {a} {nm1} {gnd} nch W={W} L={L}\n"
        f"M{prefix}_n2 {nm1}  {b} {gnd} {gnd} nch W={W} L={L}\n"
        f"M{prefix}_n3 {out}  {c} {nm2} {gnd} nch W={W} L={L}\n"
        f"M{prefix}_n4 {nm2}  {d} {gnd} {gnd} nch W={W} L={L}\n"
        f"C{prefix}_i {out} 0 {C_INT}"
    )

def oai22(prefix, out, a, b, c, d, vdd, gnd):
    """OAI22: ~((A+B)&(C+D)). 8T. PUN stack=2, PDN stack=2."""
    pm1 = f"{prefix}_pm1"
    pm2 = f"{prefix}_pm2"
    nmid = f"{prefix}_nmid"
    return (
        f"M{prefix}_p1 {out}  {a} {pm1} {vdd} pch W={W} L={L}\n"
        f"M{prefix}_p2 {pm1}  {b} {vdd} {vdd} pch W={W} L={L}\n"
        f"M{prefix}_p3 {out}  {c} {pm2} {vdd} pch W={W} L={L}\n"
        f"M{prefix}_p4 {pm2}  {d} {vdd} {vdd} pch W={W} L={L}\n"
        f"M{prefix}_n1 {nmid} {a} {gnd} {gnd} nch W={W} L={L}\n"
        f"M{prefix}_n2 {nmid} {b} {gnd} {gnd} nch W={W} L={L}\n"
        f"M{prefix}_n3 {out}  {c} {nmid} {gnd} nch W={W} L={L}\n"
        f"M{prefix}_n4 {out}  {d} {nmid} {gnd} nch W={W} L={L}\n"
        f"C{prefix}_i {out} 0 {C_INT}"
    )


# ===========================================================================
#  Variant builders
# ===========================================================================

def variant_a(vdd, gnd, p="a"):
    """Canonical Two-Level: 48T, 3 active-high outputs."""
    parts = [f"* === VARIANT A: Canonical (48T) ==="]
    parts.append(inv(f"{p}_iai", f"{p}_nai", "ai", vdd, gnd))
    parts.append(inv(f"{p}_ibi", f"{p}_nbi", "bi", vdd, gnd))
    parts.append(inv(f"{p}_iaj", f"{p}_naj", "aj", vdd, gnd))
    parts.append(inv(f"{p}_ibj", f"{p}_nbj", "bj", vdd, gnd))
    # d0 = XOR(ai,bi) = AOI22(ai,bi,~ai,~bi)
    parts.append(aoi22(f"{p}_x0", f"{p}_d0", "ai", "bi", f"{p}_nai", f"{p}_nbi", vdd, gnd))
    # d1 = XOR(aj,bj) = AOI22(aj,bj,~aj,~bj)
    parts.append(aoi22(f"{p}_x1", f"{p}_d1", "aj", "bj", f"{p}_naj", f"{p}_nbj", vdd, gnd))
    # x0 = ~d0 (XNOR), x1 = ~d1
    parts.append(inv(f"{p}_id0", f"{p}_xn0", f"{p}_d0", vdd, gnd))
    parts.append(inv(f"{p}_id1", f"{p}_xn1", f"{p}_d1", vdd, gnd))
    # OH0 = NOR(d0, d1)
    parts.append(nor2(f"{p}_o0", f"{p}_oh0", f"{p}_d0", f"{p}_d1", vdd, gnd))
    parts.append(f"Cl{p}_oh0 {p}_oh0 0 {C_LOAD}")
    # ~OH1 = AOI22(d0,xn1,xn0,d1), OH1 = INV(~OH1)
    parts.append(aoi22(f"{p}_a1", f"{p}_no1", f"{p}_d0", f"{p}_xn1", f"{p}_xn0", f"{p}_d1", vdd, gnd))
    parts.append(inv(f"{p}_io1", f"{p}_oh1", f"{p}_no1", vdd, gnd))
    parts.append(f"Cl{p}_oh1 {p}_oh1 0 {C_LOAD}")
    # ~OH2 = NAND(d0,d1), OH2 = INV(~OH2)
    parts.append(nand2(f"{p}_n2", f"{p}_no2", f"{p}_d0", f"{p}_d1", vdd, gnd))
    parts.append(inv(f"{p}_io2", f"{p}_oh2", f"{p}_no2", vdd, gnd))
    parts.append(f"Cl{p}_oh2 {p}_oh2 0 {C_LOAD}")
    return "\n".join(parts)

def variant_e(vdd, gnd, p="e"):
    """OAI22 + NOR trick: 38T, 3 active-high outputs."""
    parts = [f"* === VARIANT E: OAI22+NOR (38T) ==="]
    parts.append(inv(f"{p}_iai", f"{p}_nai", "ai", vdd, gnd))
    parts.append(inv(f"{p}_ibi", f"{p}_nbi", "bi", vdd, gnd))
    parts.append(inv(f"{p}_iaj", f"{p}_naj", "aj", vdd, gnd))
    parts.append(inv(f"{p}_ibj", f"{p}_nbj", "bj", vdd, gnd))
    # x0 = XNOR(ai,bi) = OAI22(~ai,~bi,ai,bi)
    parts.append(oai22(f"{p}_q0", f"{p}_x0", f"{p}_nai", f"{p}_nbi", "ai", "bi", vdd, gnd))
    # x1 = XNOR(aj,bj) = OAI22(~aj,~bj,aj,bj)
    parts.append(oai22(f"{p}_q1", f"{p}_x1", f"{p}_naj", f"{p}_nbj", "aj", "bj", vdd, gnd))
    # OH2 = NOR(x0, x1) -- KEY TRICK
    parts.append(nor2(f"{p}_o2", f"{p}_oh2", f"{p}_x0", f"{p}_x1", vdd, gnd))
    parts.append(f"Cl{p}_oh2 {p}_oh2 0 {C_LOAD}")
    # OH0 = AND(x0,x1) = INV(NAND(x0,x1))
    parts.append(nand2(f"{p}_n0", f"{p}_no0", f"{p}_x0", f"{p}_x1", vdd, gnd))
    parts.append(inv(f"{p}_io0", f"{p}_oh0", f"{p}_no0", vdd, gnd))
    parts.append(f"Cl{p}_oh0 {p}_oh0 0 {C_LOAD}")
    # OH1 = NOR(OH0, OH2) -- one-hot constraint
    parts.append(nor2(f"{p}_o1", f"{p}_oh1", f"{p}_oh0", f"{p}_oh2", vdd, gnd))
    parts.append(f"Cl{p}_oh1 {p}_oh1 0 {C_LOAD}")
    return "\n".join(parts)

def variant_f(vdd, gnd, p="f"):
    """Hybrid: 42T, 2 active-high outputs (OH1+OH2)."""
    parts = [f"* === VARIANT F: Hybrid (42T) ==="]
    parts.append(inv(f"{p}_iai", f"{p}_nai", "ai", vdd, gnd))
    parts.append(inv(f"{p}_ibi", f"{p}_nbi", "bi", vdd, gnd))
    parts.append(inv(f"{p}_iaj", f"{p}_naj", "aj", vdd, gnd))
    parts.append(inv(f"{p}_ibj", f"{p}_nbj", "bj", vdd, gnd))
    # x0 = XNOR via OAI22
    parts.append(oai22(f"{p}_q0", f"{p}_x0", f"{p}_nai", f"{p}_nbi", "ai", "bi", vdd, gnd))
    # x1 = XNOR via OAI22
    parts.append(oai22(f"{p}_q1", f"{p}_x1", f"{p}_naj", f"{p}_nbj", "aj", "bj", vdd, gnd))
    # d0 = ~x0, d1 = ~x1
    parts.append(inv(f"{p}_ix0", f"{p}_d0", f"{p}_x0", vdd, gnd))
    parts.append(inv(f"{p}_ix1", f"{p}_d1", f"{p}_x1", vdd, gnd))
    # OH2 = NOR(x0, x1)
    parts.append(nor2(f"{p}_o2", f"{p}_oh2", f"{p}_x0", f"{p}_x1", vdd, gnd))
    parts.append(f"Cl{p}_oh2 {p}_oh2 0 {C_LOAD}")
    # ~OH1 = AOI22(d0,x1,x0,d1), OH1 = INV
    parts.append(aoi22(f"{p}_a1", f"{p}_no1", f"{p}_d0", f"{p}_x1", f"{p}_x0", f"{p}_d1", vdd, gnd))
    parts.append(inv(f"{p}_io1", f"{p}_oh1", f"{p}_no1", vdd, gnd))
    parts.append(f"Cl{p}_oh1 {p}_oh1 0 {C_LOAD}")
    return "\n".join(parts)

def variant_g(vdd, gnd, p="g"):
    """Active-Low dual: 40T, 2 active-low outputs (~OH1, ~OH2)."""
    parts = [f"* === VARIANT G: Active-Low (40T) ==="]
    parts.append(inv(f"{p}_iai", f"{p}_nai", "ai", vdd, gnd))
    parts.append(inv(f"{p}_ibi", f"{p}_nbi", "bi", vdd, gnd))
    parts.append(inv(f"{p}_iaj", f"{p}_naj", "aj", vdd, gnd))
    parts.append(inv(f"{p}_ibj", f"{p}_nbj", "bj", vdd, gnd))
    # x0 = XNOR via OAI22
    parts.append(oai22(f"{p}_q0", f"{p}_x0", f"{p}_nai", f"{p}_nbi", "ai", "bi", vdd, gnd))
    # x1 = XNOR via OAI22
    parts.append(oai22(f"{p}_q1", f"{p}_x1", f"{p}_naj", f"{p}_nbj", "aj", "bj", vdd, gnd))
    # d0 = ~x0, d1 = ~x1
    parts.append(inv(f"{p}_ix0", f"{p}_d0", f"{p}_x0", vdd, gnd))
    parts.append(inv(f"{p}_ix1", f"{p}_d1", f"{p}_x1", vdd, gnd))
    # ~OH1 = AOI22(d0,x1,x0,d1) -- no output INV!
    parts.append(aoi22(f"{p}_a1", f"{p}_noh1", f"{p}_d0", f"{p}_x1", f"{p}_x0", f"{p}_d1", vdd, gnd))
    parts.append(f"Cl{p}_noh1 {p}_noh1 0 {C_LOAD}")
    # ~OH2 = NAND(d0,d1) -- no output INV!
    parts.append(nand2(f"{p}_n2", f"{p}_noh2", f"{p}_d0", f"{p}_d1", vdd, gnd))
    parts.append(f"Cl{p}_noh2 {p}_noh2 0 {C_LOAD}")
    return "\n".join(parts)


# ===========================================================================
#  Assemble SPICE deck
# ===========================================================================

lines = []
lines.append("* Fused Hamming Cell -- TSMC N5 Transistor-Level SPICE")
lines.append("* Variants A(48T), E(38T), F(42T), G(40T)")
lines.append("* VDD=0.5V, 2-fin FinFET, 16-vector functional + power")
lines.append("")

# Models
lines.append("* --- MOSFET Models (TSMC N5 approx, 2-fin) ---")
lines.append(".model nch nmos level=1 vto=0.3 kp=108u lambda=0.08")
lines.append("+ tox=1.2n cgso=0.5f cgdo=0.5f cbd=0.04f cbs=0.04f")
lines.append(".model pch pmos level=1 vto=-0.3 kp=72u lambda=0.1")
lines.append("+ tox=1.2n cgso=0.5f cgdo=0.5f cbd=0.04f cbs=0.04f")
lines.append("")

# Independent VDD per variant for separate current measurement
for vl in ['a', 'e', 'f', 'g']:
    lines.append(f"Vdd_{vl} vdd_{vl} 0 {VDD}")
lines.append("")

# Input stimulus (PWL sources through all 16 vectors)
ai_bits = [v[0] for v in VECTORS]
bi_bits = [v[1] for v in VECTORS]
aj_bits = [v[2] for v in VECTORS]
bj_bits = [v[3] for v in VECTORS]

lines.append("* --- Input Stimulus (16 vectors x 100ps = 1.6ns) ---")
lines.append(pwl_source("ai", "ai", ai_bits))
lines.append(pwl_source("bi", "bi", bi_bits))
lines.append(pwl_source("aj", "aj", aj_bits))
lines.append(pwl_source("bj", "bj", bj_bits))
lines.append("")

# Variant netlists
lines.append(variant_a("vdd_a", "0", "a"))
lines.append("")
lines.append(variant_e("vdd_e", "0", "e"))
lines.append("")
lines.append(variant_f("vdd_f", "0", "f"))
lines.append("")
lines.append(variant_g("vdd_g", "0", "g"))
lines.append("")

# Simulation
t_total = N_VEC * T_VEC
t_step = 5e-12  # 5ps
lines.append(f".tran {t_step:.4e} {t_total:.4e}")
lines.append("")

# Control block
lines.append(".control")
lines.append("set noaskquit")
lines.append("run")
lines.append("")

# Verification: sample outputs at 80% into each 100ps window
lines.append('echo ""')
lines.append('echo "========================================================"')
lines.append('echo "  FUNCTIONAL VERIFICATION"')
lines.append('echo "========================================================"')

for i, (ai, bi, aj, bj, exp0, exp1, exp2) in enumerate(VECTORS):
    t_ns = (i + 0.8) * T_VEC * 1e9
    exp_noh1 = 1 - exp1
    exp_noh2 = 1 - exp2
    lines.append(f'echo "Vec{i:02d} ai={ai} bi={bi} aj={aj} bj={bj}  exp OH={{0,1,2}}={exp0},{exp1},{exp2}"')

    # Sample each variant at the settled time point
    # Use meas to extract voltage at time point
    lines.append(f"meas tran va0_{i} find v(a_oh0) at={t_ns:.4f}n")
    lines.append(f"meas tran va1_{i} find v(a_oh1) at={t_ns:.4f}n")
    lines.append(f"meas tran va2_{i} find v(a_oh2) at={t_ns:.4f}n")

    lines.append(f"meas tran ve0_{i} find v(e_oh0) at={t_ns:.4f}n")
    lines.append(f"meas tran ve1_{i} find v(e_oh1) at={t_ns:.4f}n")
    lines.append(f"meas tran ve2_{i} find v(e_oh2) at={t_ns:.4f}n")

    lines.append(f"meas tran vf1_{i} find v(f_oh1) at={t_ns:.4f}n")
    lines.append(f"meas tran vf2_{i} find v(f_oh2) at={t_ns:.4f}n")

    lines.append(f"meas tran vg1_{i} find v(g_noh1) at={t_ns:.4f}n")
    lines.append(f"meas tran vg2_{i} find v(g_noh2) at={t_ns:.4f}n")

# Power: average supply current over full simulation
lines.append("")
lines.append('echo ""')
lines.append('echo "========================================================"')
lines.append('echo "  POWER ANALYSIS"')
lines.append('echo "========================================================"')

for vl in ['a', 'e', 'f', 'g']:
    lines.append(f"meas tran iavg_{vl} avg i(vdd_{vl}) from=0 to={t_total:.4e}")

lines.append("")
lines.append('echo ""')
lines.append('echo "--- Per-cell power at VDD=0.5V ---"')
for vl in ['a', 'e', 'f', 'g']:
    lines.append(f'let pwr_{vl} = abs(iavg_{vl}) * {VDD}')
    lines.append(f'print pwr_{vl}')

lines.append("")

# Propagation delay measurement (vector 4: 0100 -> OH1 rises)
# Find the rising edge of OH1 for timing analysis
lines.append('echo ""')
lines.append('echo "========================================================"')
lines.append('echo "  PROPAGATION DELAY (OH1 critical path)"')
lines.append('echo "========================================================"')
# Measure delay from input transition to OH1 crossing VDD/2
# Vector 4 (0100): ai=0 bi=1 aj=0 bj=0 => d0=1,d1=0 => OH1=1
# Input bi rises at t=4*100ps = 400ps
t_in_edge = 4 * T_VEC
lines.append(f"meas tran td_a_oh1 trig v(bi) val=0.25 rise=1 targ v(a_oh1) val=0.25 rise=1")
lines.append(f"meas tran td_e_oh1 trig v(bi) val=0.25 rise=1 targ v(e_oh1) val=0.25 rise=1")
lines.append(f"meas tran td_f_oh1 trig v(bi) val=0.25 rise=1 targ v(f_oh1) val=0.25 rise=1")

# For G, measure ~OH1 falling (active-low = falling when OH1 would rise)
lines.append(f"meas tran td_g_noh1 trig v(bi) val=0.25 rise=1 targ v(g_noh1) val=0.25 fall=1")

lines.append("")
lines.append("quit")
lines.append(".endc")
lines.append("")
lines.append(".end")

# Write the deck
deck = "\n".join(lines)
with open("/home/claude/spice/fused_cell_all.spice", "w") as f:
    f.write(deck)

print(f"SPICE deck: {len(deck)} chars, {deck.count(chr(10))+1} lines")
print(f"\nTruth table:")
print(f"  ai bi aj bj | OH0 OH1 OH2")
for v in VECTORS:
    print(f"   {v[0]}  {v[1]}  {v[2]}  {v[3]}  |  {v[4]}   {v[5]}   {v[6]}")
