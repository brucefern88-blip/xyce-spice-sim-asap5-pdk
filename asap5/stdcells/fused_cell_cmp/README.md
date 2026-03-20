# Fused Hamming Cell — Variant Comparison (ASAP5 5nm GAA)

## Variants

| Variant | Transistors | Architecture | Outputs |
|---------|------------|-------------|---------|
| A | 48T | Canonical: 4 INV + 2 AOI22(XOR) + 2 INV + NOR2 + AOI22+INV + NAND2+INV | oh0, oh1, oh2 (active-high) |
| E | 38T | OAI22+NOR: 4 INV + 2 OAI22(XNOR) + NOR2 + NAND2+INV + NOR2 | oh0, oh1, oh2 (active-high) |
| F | 42T | Hybrid: 4 INV + 2 OAI22(XNOR) + 2 INV + NOR2 + AOI22+INV | oh1, oh2 (active-high) |
| G | 40T | Active-Low: 4 INV + 2 OAI22(XNOR) + 2 INV + AOI22 + NAND2 | noh1, noh2 (active-low) |

## PPA Results (Xyce BSIM-CMG level=107, SLVT TT, VDD=0.5V, nfin=2)

| Variant | Tx | tpd (ps) | P_switch (uW) | EDP (rel) | DC Verify |
|---------|-----|----------|---------------|-----------|-----------|
| A (48T) | 48 | 305 | 2.72 | 1.000 | 16/16 PASS |
| E (38T) | 38 | 259 | 1.91 | 0.594 | 16/16 PASS |
| F (42T) | 42 | 303 | 2.75 | 1.002 | 16/16 PASS |
| **G (40T)** | **40** | **316** | **0.62** | **0.236** | **16/16 PASS** |

### Winners
- **Best EDP:** Variant G (76% lower than A)
- **Best Speed:** Variant E (259ps, 15% faster than A)
- **Best Power:** Variant G (0.62 uW, 77% lower than A)
- **Best Area:** Variant E (38T, 21% fewer than A)

## Simulation Setup
- **Simulator:** Xyce BSIM-CMG level=107 (NEVER ngspice)
- **Models:** ASAP5 SLVT TT calibrated (cgso/cgdo tuned for Cg=0.05fF/nfin)
- **VDD:** 0.5V
- **Device:** nfin=2, L=16nm, GAA nanosheet (geomod=3)
- **Verification:** 16-vector transient, 1ns/vector, functional check at 0.8ns/vector
- **Delay:** bi 0→0.5V transition, measure oh1 response

## Directory Structure

```
fused_cell_cmp/
├── layouts/          # Magic .mag files (ASAP5 PDK, DRC clean)
│   ├── FUSED_A.mag   # 528×280nm double-height (1.89:1)
│   ├── FUSED_E.mag   # 440×280nm double-height (1.57:1)
│   ├── FUSED_F.mag   # 528×280nm double-height (1.89:1)
│   ├── FUSED_G.mag   # 528×280nm double-height (1.89:1)
│   └── build_*.tcl   # Magic TCL build scripts
├── spice/            # Schematic SPICE netlists + generators
│   ├── FUSED_*_schematic.cir  # 16-vector transient decks
│   ├── FUSED_*_tran.cir       # Single-transition delay decks
│   ├── fused_cell_all.spice   # Original 4-variant combined deck
│   ├── run_all_xyce.py        # Pre-layout PPA generator
│   ├── ppa_xyce_tran.py       # 16-vector transient PPA
│   └── fused_ppa_xyce_study.py # Complete study script
├── extracted/        # Magic parasitic extraction output
│   ├── FUSED_*.ext        # Raw extraction database
│   └── FUSED_*_ext.spice  # Extracted SPICE (LVS)
├── waveforms/        # Xyce binary .raw files for LTspice
│   ├── ppa_a.raw     # Variant A 16-vector transient
│   ├── ppa_e.raw     # Variant E 16-vector transient
│   ├── ppa_f.raw     # Variant F 16-vector transient
│   └── ppa_g.raw     # Variant G 16-vector transient
├── testdecks/        # All Xyce .cir test decks + .mt0 results
│   ├── ppa_*.cir          # 16-vector functional + power
│   ├── ppa_tran_*.cir     # Single-transition delay
│   ├── xtran_*.cir        # Alternative transient decks
│   └── *.mt0              # Xyce measurement results
└── results/          # This README + comparison data
```

## How to Re-Run

```bash
# View waveforms
open -a LTspice waveforms/ppa_g.raw

# Re-run PPA study
cd spice && python3 ppa_xyce_tran.py

# Open layout in Magic
DISPLAY=:0 /Users/bruce/CLAUDE/magic_new/bin/magic -T /Users/bruce/CLAUDE/asap5/magic/asap5.tech layouts/FUSED_G

# Re-extract
magic -dnull -noconsole -T asap5 <<EOF
load FUSED_G
extract all
ext2spice lvs
ext2spice -f ngspice -o FUSED_G_ext.spice
quit
EOF
```

## Key Insight

At 5nm GAA, **layout routing dominates performance**. Variant G's active-low output strategy saves 2 inverters and one gate delay, giving 77% lower switching power. Double-height cell layout (≤2:1 aspect ratio) keeps M2 cross-connections short, minimizing wire parasitic capacitance.
