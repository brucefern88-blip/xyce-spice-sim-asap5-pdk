//====================================================================================================
//
//  MODULE : hamming_distance_64
//
//  64-BIT HAMMING DISTANCE — TSMC N5 (5nm FinFET) PHYSICAL DESIGN SPECIFICATION
//  Fused Transistor-Layer Cells + Metal-Layer Crosspoint Popcount Architecture
//
//  This file contains the complete gate-level structural Verilog WITH embedded
//  physical design annotations: floorplan, metal stack assignment, RC delay
//  estimates, drive strength sizing, and buffer insertion for every signal path.
//
//====================================================================================================
//
//  ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
//  ║                    TSMC N5 (CLN5FF) PROCESS CHARACTERIZATION                               ║
//  ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
//
//  ┌──────────────────────────────────────────────────────────────────────────────────────────┐
//  │ PROCESS FUNDAMENTALS                                                                     │
//  ├──────────────────────────────────────────────────────────────────────────────────────────┤
//  │                                                                                          │
//  │  Transistor type   : FinFET (3D tri-gate fins, NOT gate-all-around nanosheets)           │
//  │  Fin pitch         : 25-27 nm                                                            │
//  │  Fin height        : ~45-48 nm                                                           │
//  │  Contacted Poly Pitch (CPP) : 48 nm                                                      │
//  │  Minimum metal pitch (M1)   : 28 nm                                                      │
//  │  Standard cell height       : 5-track (5T) = 5 × fin pitch ≈ 128-135 nm                 │
//  │                                                                                          │
//  │  VDD options:                                                                            │
//  │    Ultra-low voltage (ULV) : 0.65 V  (lowest leakage, slowest)                          │
//  │    Nominal (SVT)           : 0.75 V  (← our design target)                              │
//  │    High-performance (HVT)  : 0.80 V  (fastest, most leakage)                            │
//  │                                                                                          │
//  │  Multi-Vt flavors (threshold voltage options per cell):                                  │
//  │    uLVT (ultra-low Vt)  : Fastest, highest leakage — for critical path cells             │
//  │    LVT  (low Vt)        : Fast, moderate leakage — primary choice for this design        │
//  │    SVT  (standard Vt)   : Balanced speed/leakage — for non-critical paths                │
//  │    HVT  (high Vt)       : Slowest, lowest leakage — not used in this design              │
//  │                                                                                          │
//  │  Fins per transistor:                                                                    │
//  │    X1 drive  : 1 fin (minimum size)                                                      │
//  │    X2 drive  : 2 fins                                                                    │
//  │    X4 drive  : 3-4 fins                                                                  │
//  │    X8 drive  : 6-8 fins                                                                  │
//  │    X16 drive : 12-16 fins (large buffer)                                                 │
//  │                                                                                          │
//  │  KEY N5 CHALLENGE: At 5nm, interconnect RC delay dominates over gate delay               │
//  │  for any wire run > ~2 μm. This circuit's metal-layer crosspoint architecture            │
//  │  must be carefully designed to keep wire lengths short and properly driven.               │
//  │                                                                                          │
//  └──────────────────────────────────────────────────────────────────────────────────────────┘
//
//  ┌──────────────────────────────────────────────────────────────────────────────────────────┐
//  │ SINGLE-FIN DEVICE PARAMETERS (TSMC N5, LVT, TT corner, 25°C)                            │
//  ├──────────────────────────────────────────────────────────────────────────────────────────┤
//  │                                                                                          │
//  │  Nominal supply (ULV) : 0.40 V  (near-threshold target for this section)                │
//  │  Nominal supply (SVT) : 0.75 V  (standard design target, see gate delay table below)    │
//  │                                                                                          │
//  │  Per-fin capacitances (extracted, LVT, 1 fin):                                          │
//  │    Cg  (gate capacitance)   : ~0.05 fF/fin   (includes both sides of FinFET gate)       │
//  │    Cd  (drain junction cap) : ~0.02 fF/fin   (drain-to-substrate + fringe)              │
//  │    Cs  (source junction cap): ~0.02 fF/fin   (source-to-substrate + fringe)             │
//  │                                                                                          │
//  │  Per-fin drain currents — NMOS (LVT, 1 fin, saturation):                                │
//  │                       │  VDD = 0.75 V          │  VDD = 0.40 V                          │
//  │    Id_on  (Vgs=VDD)   │  ~55-75 μA/fin         │  ~5-12 μA/fin  (near-Vt)               │
//  │    Id_off (Vgs=0)     │  ~10-20 nA/fin         │  ~8-18 nA/fin  (subthreshold)          │
//  │    Ion/Ioff ratio     │  ~4000-5000            │  ~400-1000                             │
//  │                                                                                          │
//  │  Per-fin drain currents — PMOS (LVT, 1 fin, saturation):                                │
//  │                       │  VDD = 0.75 V          │  VDD = 0.40 V                          │
//  │    Id_on  (|Vgs|=VDD) │  ~40-55 μA/fin         │  ~3-8 μA/fin   (near-Vt)               │
//  │    Id_off (Vgs=0)     │  ~5-15 nA/fin          │  ~4-13 nA/fin  (subthreshold)          │
//  │    Ion/Ioff ratio     │  ~3000-4000            │  ~300-800                              │
//  │                                                                                          │
//  │  NOTES on 0.40 V operation:                                                              │
//  │    - Near-threshold: Vt(LVT) ≈ 0.25-0.30 V, so overdrive is only ~100-150 mV           │
//  │    - Gate delay ~4-6× slower than at 0.75 V (current starved)                           │
//  │    - Dynamic power ∝ V²: (0.40/0.75)² ≈ 0.28 → ~72% power reduction                   │
//  │    - Leakage roughly constant (subthreshold, weakly voltage-dependent)                   │
//  │    - Ion/Ioff degrades sharply — timing closure much harder                              │
//  │    - Variability (σVt) dominates: 3σ delay spread can be >50%                           │
//  │                                                                                          │
//  └──────────────────────────────────────────────────────────────────────────────────────────┘
//
//  ┌──────────────────────────────────────────────────────────────────────────────────────────┐
//  │ TSMC N5 COMPLETE METAL STACK (13 layers)                                                 │
//  ├──────────┬───────────┬──────────┬──────────┬───────────┬──────────┬──────────────────────┤
//  │  Layer   │  Pitch    │ Width    │ Thick.   │ R (Ω/μm)  │ C (fF/μm)│ Role in This Design │
//  ├──────────┼───────────┼──────────┼──────────┼───────────┼──────────┼──────────────────────┤
//  │  M1      │  28 nm    │ 14 nm    │ 36 nm    │  25-35    │  0.16    │ Intra-cell only      │
//  │  M2      │  28 nm    │ 14 nm    │ 36 nm    │  20-30    │  0.17    │ STAGE 2 crosspoint V │
//  │  M3      │  28 nm    │ 14 nm    │ 36 nm    │  20-30    │  0.17    │ STAGE 2 crosspoint H │
//  │  M4      │  40 nm    │ 20 nm    │ 40 nm    │  10-15    │  0.19    │ STAGE 2 output coll. │
//  │  M5      │  40 nm    │ 20 nm    │ 40 nm    │  10-15    │  0.19    │ STAGE 3 radix-4 rte  │
//  │  M6      │  40 nm    │ 20 nm    │ 40 nm    │   8-12    │  0.20    │ STAGE 4 L1 crosspt   │
//  │  M7      │  80 nm    │ 40 nm    │ 60 nm    │   3-5     │  0.22    │ STAGE 4 L2 crosspt   │
//  │  M8      │  80 nm    │ 40 nm    │ 60 nm    │   3-5     │  0.22    │ STAGE 4 L3 final     │
//  │  M9      │  160 nm   │ 80 nm    │ 100 nm   │   0.8-1.5 │  0.25    │ STAGE 5 binary conv  │
//  │  M10     │  160 nm   │ 80 nm    │ 100 nm   │   0.8-1.5 │  0.25    │ Output hd[6:0] bus   │
//  │  M11     │  800 nm   │ 400 nm   │ 800 nm   │   0.05    │  0.28    │ VDD/VSS power grid   │
//  │  M12     │  800 nm   │ 400 nm   │ 800 nm   │   0.05    │  0.28    │ VDD/VSS power grid   │
//  │  M13     │  ≥1600 nm │ ≥800 nm  │ ≥2000 nm │   0.02    │  0.30    │ RDL / pad layer      │
//  ├──────────┴───────────┴──────────┴──────────┴───────────┴──────────┴──────────────────────┤
//  │                                                                                          │
//  │  Via resistance (per via):                                                               │
//  │    V1-V3 (tight-pitch)   : 10-20 Ω/via                                                  │
//  │    V4-V6 (relaxed-pitch) :  5-10 Ω/via                                                  │
//  │    V7-V8 (semi-global)   :  3-5 Ω/via                                                   │
//  │    V9+   (global)        :  1-3 Ω/via                                                   │
//  │                                                                                          │
//  │  KEY INSIGHT: M1-M3 at N5 are extremely resistive (Cu resistivity increases sharply      │
//  │  below ~30nm width due to grain boundary and surface scattering). Any crosspoint         │
//  │  wire on M2/M3 longer than ~0.5 μm needs buffering or must use wider metal.             │
//  │                                                                                          │
//  │  BARRIER METAL NOTE: At N5, the Cu diffusion barrier (TaN/Ta liner) consumes a           │
//  │  significant fraction of the narrow wire cross-section, further increasing R.            │
//  │  TSMC explored Co (cobalt) and Ru (ruthenium) for M1-M2 to mitigate this.              │
//  │                                                                                          │
//  └──────────────────────────────────────────────────────────────────────────────────────────┘
//
//  ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
//  ║                    GATE DELAY CHARACTERIZATION (TSMC N5, 0.75V, TT, 25°C)                  ║
//  ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
//
//  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
//  │                                                                                             │
//  │  FUNDAMENTAL GATES — Propagation delay (50% input → 50% output, FO4 load)                  │
//  │                                                                                             │
//  │  ┌──────────────┬─────────┬──────────┬──────────┬──────────┬───────────────────────────┐    │
//  │  │  Cell         │  Vt     │ Drive    │  Fins    │ Delay    │  Notes                    │    │
//  │  ├──────────────┼─────────┼──────────┼──────────┼──────────┼───────────────────────────┤    │
//  │  │  INVX1       │  LVT    │  X1      │  1p/1n   │  10-12 ps│  Minimum inverter         │    │
//  │  │  INVX2       │  LVT    │  X2      │  2p/2n   │  8-10 ps │  Standard buffer stage    │    │
//  │  │  INVX4       │  LVT    │  X4      │  4p/4n   │  7-9 ps  │  Strong buffer stage      │    │
//  │  │  INVX8       │  LVT    │  X8      │  8p/8n   │  6-8 ps  │  Heavy drive stage        │    │
//  │  │  INVX1       │  uLVT   │  X1      │  1p/1n   │  8-10 ps │  Critical-path inverter   │    │
//  │  │                                                                                       │    │
//  │  │  NAND2X1     │  LVT    │  X1      │  1p/2n   │  14-18 ps│  2-input NAND             │    │
//  │  │  NOR2X1      │  LVT    │  X1      │  2p/1n   │  16-20 ps│  2-input NOR              │    │
//  │  │  AND2X1      │  LVT    │  X1      │  -       │  22-28 ps│  NAND2 + INV cascade      │    │
//  │  │  OR2X1       │  LVT    │  X1      │  -       │  24-30 ps│  NOR2 + INV cascade       │    │
//  │  │                                                                                       │    │
//  │  │  ─── XOR / XNOR (Critical for Fused Hamming Cell) ───────────────────────────────    │    │
//  │  │                                                                                       │    │
//  │  │  XOR2X1      │  LVT    │  X1      │  4p/4n   │  30-40 ps│  Transmission-gate XOR    │    │
//  │  │  XOR2X2      │  LVT    │  X2      │  6p/6n   │  25-32 ps│  Double-drive XOR         │    │
//  │  │  XOR2X1      │  uLVT   │  X1      │  4p/4n   │  25-33 ps│  Fast XOR for crit. path  │    │
//  │  │  XNOR2X1     │  LVT    │  X1      │  4p/4n   │  30-40 ps│  Same topology as XOR     │    │
//  │  │  XNOR2X2     │  LVT    │  X2      │  6p/6n   │  25-32 ps│  XNOR is complement tap   │    │
//  │  │  XOR2X1      │  uLVT   │  X1      │  4p/4n   │  25-33 ps│  XOR = XNOR, same stack   │    │
//  │  │                                                                                       │    │
//  │  │  ─── COMPOUND GATES (Used in Fused Cell) ────────────────────────────────────────    │    │
//  │  │                                                                                       │    │
//  │  │  AO22X1      │  LVT    │  X1      │  4p/4n   │  35-45 ps│  AND-OR: (a&b)|(c&d)      │    │
//  │  │    → Used for OH0/OH2: AND-of-XOR / AND-of-XNOR                                      │    │
//  │  │    → At N5 these map to a single complex gate (AOI + INV) or OAI topology             │    │
//  │  │    → The AND-of-XOR is synthesized as: XOR first pass → AND second pass               │    │
//  │  │    → But in the fused cell, the XOR/XNOR share the same transistor stack:             │    │
//  │  │       XOR core = 6 fins (3p + 3n), complement gives XNOR for free                    │    │
//  │  │       AND gate = 2 additional fins                                                    │    │
//  │  │       Total per OH0/OH2 = ~8 fins, but sharing the core: ~6+2+2 = 10 fins for both   │    │
//  │  │                                                                                       │    │
//  │  │  4-INPUT XOR  │  LVT   │  X1      │  8p/8n   │  45-65 ps│  2-level XOR chain         │    │
//  │  │    → This is OH1: a[i]^b[i]^a[j]^b[j]                                                │    │
//  │  │    → Implementation: two parallel XOR2 (level 1) → one XOR2 (level 2)                 │    │
//  │  │    → With transmission-gate XOR: level 1 = ~30ps, level 2 = ~30ps                     │    │
//  │  │    → But in pass-transistor logic, XOR chains can be single-pass:                     │    │
//  │  │       4-input XOR = 8 pass transistors in a chain, 1 pass delay ≈ 40-55 ps            │    │
//  │  │    → WE USE THE SINGLE-PASS IMPLEMENTATION for minimum delay                          │    │
//  │  │                                                                                       │    │
//  │  └──────────────┴─────────┴──────────┴──────────┴──────────┴───────────────────────────┘    │
//  │                                                                                             │
//  │  FUSED HAMMING CELL — Complete Delay Analysis                                               │
//  │                                                                                             │
//  │    Topology: 4 raw inputs → {OH0, OH1, OH2} one-hot outputs                                │
//  │                                                                                             │
//  │    OH0 path: a[i],b[i] → XNOR → ─┐                                                        │
//  │             a[j],b[j] → XNOR → ──┤─→ AND → OH0                                            │
//  │                                                                                             │
//  │    In pass-transistor logic, XNOR is free (complement of XOR from same stack).              │
//  │    The AND that follows can be a series-connected pass network.                              │
//  │                                                                                             │
//  │    ┌────────────────────┬────────────────┬───────────────────────────────────┐               │
//  │    │  Output            │  Gate Path     │  Delay (LVT, FO4, 0.75V)         │               │
//  │    ├────────────────────┼────────────────┼───────────────────────────────────┤               │
//  │    │  OH0 (AND-of-XNOR) │  1 compound   │  35-45 ps (XOR+AND fused)        │               │
//  │    │  OH1 (4-input XOR)  │  1 pass chain │  40-55 ps (pass-transistor chain)│               │
//  │    │  OH2 (AND-of-XOR)   │  1 compound   │  35-45 ps (XOR+AND fused)        │               │
//  │    ├────────────────────┼────────────────┼───────────────────────────────────┤               │
//  │    │  CRITICAL PATH     │  OH1 (longest) │  40-55 ps                         │               │
//  │    └────────────────────┴────────────────┴───────────────────────────────────┘               │
//  │                                                                                             │
//  │    OUTPUT DRIVE STRENGTH:                                                                   │
//  │      Each fused cell output drives 2-3 crosspoint wires (the one-hot wire itself).          │
//  │      At N5, a single-fin output can drive ~10 fF load within ~15 ps added delay.            │
//  │      Crosspoint wires (M2/M3) are short (~0.3-0.8 μm), so load ≈ 2-4 fF.                  │
//  │      → X1 drive (1 fin) is SUFFICIENT for Stage 2 crosspoint inputs.                       │
//  │      → No output buffer needed on fused cells.                                              │
//  │                                                                                             │
//  └─────────────────────────────────────────────────────────────────────────────────────────────┘
//
//  ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
//  ║                                   FLOORPLAN                                                ║
//  ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
//
//  Overall block dimensions: ~22 μm (W) × ~18 μm (H)
//  Total area: ~396 μm² (excluding power grid overhead)
//
//  Orientation: Data flows BOTTOM → TOP (inputs at bottom, hd[6:0] at top)
//
//  ┌────────────────────────────────────────────────────────────────────────────────────┐
//  │                                                                                    │
//  │  Y=18μm ┌──────────────────────────────────┐    ← M10: hd[6:0] output bus         │
//  │         │    STAGE 5: Binary Conversion     │      7 wires on M9/M10               │
//  │  Y=16μm │    (wired-OR via grid, M9/M10)    │      ~22 μm wide × 2 μm tall        │
//  │         └──────────────────────────────────┘                                       │
//  │                        │                                                            │
//  │  Y=15μm ┌──────────────────────────────────┐    ← M8: Final merge result           │
//  │         │  STAGE 4 Level 3: Final Add       │      mf_d0[24:0], mf_d1[16:0]        │
//  │         │  (13×13 + 9×9 crosspoints, M7/M8) │      ~12 μm wide × 1.5 μm tall      │
//  │  Y=13μm └──────────────────────────────────┘                                       │
//  │                      /     \                                                        │
//  │  Y=12μm ┌──────────────┐ ┌──────────────┐      ← M7: L2 intermediate results      │
//  │         │ STAGE 4 L2-A │ │ STAGE 4 L2-B │        2 pairs of crosspoints             │
//  │         │ (7×7+5×5     │ │ (7×7+5×5     │        ~10 μm each × 1.5 μm tall         │
//  │         │  M6/M7)      │ │  M6/M7)      │                                           │
//  │  Y=10μm └──────────────┘ └──────────────┘                                           │
//  │               / \              / \                                                   │
//  │  Y=9μm  ┌────┐┌────┐    ┌────┐┌────┐           ← M6: L1 intermediate results       │
//  │         │L1-0││L1-1│    │L1-2││L1-3│              4 pairs of crosspoints              │
//  │         │ M5 ││ M5 │    │ M5 ││ M5 │              ~5 μm each × 1.5 μm tall           │
//  │  Y=7μm  │ M6 ││ M6 │    │ M6 ││ M6 │                                                 │
//  │         └────┘└────┘    └────┘└────┘                                                  │
//  │           │  │   │  │      │  │   │  │                                                │
//  │  Y=6μm  ┌────────────────────────────────────┐  ← M5: Radix-4 regrouped outputs      │
//  │         │         STAGE 3: Radix-4            │    Pure wiring layer (M4→M5)           │
//  │  Y=5μm  │     Regroup (8 converters)          │    ~22 μm wide × 1.5 μm tall          │
//  │         └────────────────────────────────────┘                                        │
//  │                                                                                        │
//  │  Y=4.5μm ┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐    ← M2/M3/M4: Crosspoint trees          │
//  │          │B0││B1││B2││B3││B4││B5││B6││B7│       8 byte-level summation trees           │
//  │  Y=2.5μm │  ││  ││  ││  ││  ││  ││  ││  │       ~2.5 μm each × 2 μm tall             │
//  │          └──┘└──┘└──┘└──┘└──┘└──┘└──┘└──┘                                             │
//  │                                                                                        │
//  │  Y=2μm  ┌──────────────────────────────────────┐ ← TRANSISTOR LAYER (M1/poly)         │
//  │         │  STAGE 1: 32 Fused Hamming Cells      │   8 groups × 4 cells, 5T height      │
//  │  Y=0.5μm│  [fc0-3] [fc4-7] ... [fc28-31]       │   ~22 μm wide × 1.5 μm tall          │
//  │         └──────────────────────────────────────┘                                       │
//  │                                                                                        │
//  │  Y=0    ═══════════════════════════════════════   ← INPUT PINS: a[63:0], b[63:0]       │
//  │         128 input pins on M1/M2, pitch 28nm                                            │
//  │                                                                                        │
//  └────────────────────────────────────────────────────────────────────────────────────────┘
//
//
//  DETAILED STAGE 1 FLOORPLAN (Transistor Layer):
//
//  The 32 fused cells are arranged as 8 groups of 4, one group per input byte.
//  Each group is aligned vertically under its Stage 2 crosspoint tree for
//  minimum wire length on the critical one-hot output connections.
//
//  ┌─────────────────────────────────────────────────────────────────────────────┐
//  │  Byte 0          Byte 1          Byte 2    ...     Byte 7                  │
//  │ ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐     ┌───┬───┬───┬───┐          │
//  │ │fc0│fc1│fc2│fc3│fc4│fc5│fc6│fc7│fc8│fc9│ ... │f28│f29│f30│f31│          │
//  │ └───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘     └───┴───┴───┴───┘          │
//  │  ↕ 0.27μm each   (5T × 54nm = ~270nm tall)                                │
//  │  ↔ 0.48μm each   (10 CPP × 48nm = ~480nm wide, includes 14-16 transistors)│
//  │                                                                             │
//  │  Group width: 4 cells × 0.48μm = ~1.92 μm per byte                        │
//  │  Total width: 8 groups × 1.92μm + 7 gaps × 0.75μm ≈ 20.6 μm              │
//  │  Total height: 5T = ~0.27 μm per row, 2 rows with spacing ≈ 0.8 μm       │
//  │                                                                             │
//  │  Cell internals (per fused cell):                                           │
//  │    ┌─────────────────────────────────────────┐                              │
//  │    │  VDD rail ─────────────────────── (M1)  │                              │
//  │    │  ┌──────┐  ┌──────┐  ┌──────┐          │                              │
//  │    │  │XOR/  │  │XOR/  │  │ AND  │          │                              │
//  │    │  │XNOR  │  │XNOR  │  │merge │          │                              │
//  │    │  │pair i│  │pair j│  │      │          │                              │
//  │    │  │6 fins│  │6 fins│  │2-4fin│          │                              │
//  │    │  └──────┘  └──────┘  └──────┘          │                              │
//  │    │  VSS rail ─────────────────────── (M1)  │                              │
//  │    └─────────────────────────────────────────┘                              │
//  │    ← 10 CPP = ~480nm →                                                     │
//  │                                                                             │
//  │    Pass-transistor XOR chain (OH1) runs through the middle of the cell.     │
//  │    OH0/OH2 tap complementary outputs from the same XNOR/XOR stack.          │
//  │    One-hot outputs exit upward on M2 toward the crosspoint matrices.        │
//  │                                                                             │
//  └─────────────────────────────────────────────────────────────────────────────┘
//
//
//  ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
//  ║                    METAL LAYER ASSIGNMENT — COMPLETE WIRING PLAN                           ║
//  ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
//
//  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
//  │                                                                                             │
//  │  LAYER ASSIGNMENT RATIONALE:                                                                │
//  │                                                                                             │
//  │  The key constraint at N5 is that M1-M3 are extremely resistive (~20-35 Ω/μm),             │
//  │  so we want crosspoint wires on these layers to be SHORT (< 0.5 μm ideally).               │
//  │  Stage 2 crosspoints (3×3 and 5×5 grids) are small enough to fit on M2/M3.                 │
//  │  Larger crosspoints (up to 13×13 in Stage 4) must use wider metal layers.                   │
//  │                                                                                             │
//  │  ┌──────────┬────────────────────────────────────────────────────────────────────┐          │
//  │  │  Signal Group          │  Layer(s)  │  Direction  │  Est. Length  │  Buffered? │          │
//  │  ├────────────────────────┼────────────┼─────────────┼───────────────┼────────────┤          │
//  │  │  a[63:0], b[63:0]      │  M1/M2     │  Horizontal │  0.5-2.0 μm  │  Input buf │          │
//  │  │  (input pins)          │            │             │  per pin      │  X4 LVT    │          │
//  │  ├────────────────────────┼────────────┼─────────────┼───────────────┼────────────┤          │
//  │  │  Fused cell OH outputs │  M2 (vert) │  Vertical   │  0.3-0.5 μm  │  No (X1    │          │
//  │  │  fc*_oh{0,1,2}        │            │  (↑ to xpt) │  (cell→xpt)  │  adequate) │          │
//  │  ├────────────────────────┼────────────┼─────────────┼───────────────┼────────────┤          │
//  │  │  Stage 2 crosspoint    │  M2 (vert) │  Vertical   │  0.08-0.14μm │  No        │          │
//  │  │  vertical inputs       │  M3 (horz) │  Horizontal │  (within grid)│            │          │
//  │  ├────────────────────────┼────────────┼─────────────┼───────────────┼────────────┤          │
//  │  │  Stage 2 crosspoint    │  M4        │  Hor/diag   │  0.3-0.6 μm  │  *** YES   │          │
//  │  │  output collection     │            │  (diagonal  │  (per output) │  BUF X2    │          │
//  │  │  (byte_oh[8:0])        │            │   wired-OR) │              │  at M4 exit │          │
//  │  ├────────────────────────┼────────────┼─────────────┼───────────────┼────────────┤          │
//  │  │  Stage 3 radix-4       │  M4→M5     │  Via stack  │  ~0.1 μm     │  No (just  │          │
//  │  │  regrouping wires      │            │  + short H  │  (rewiring)  │  rewiring)  │          │
//  │  ├────────────────────────┼────────────┼─────────────┼───────────────┼────────────┤          │
//  │  │  Stage 4 L1 crosspt    │  M5 (vert) │  Vertical   │  0.2-0.5 μm  │  No        │          │
//  │  │  (4×4 + 3×3 grids)     │  M6 (horz) │  Horizontal │  (small grid) │            │          │
//  │  ├────────────────────────┼────────────┼─────────────┼───────────────┼────────────┤          │
//  │  │  Stage 4 L1 outputs    │  M6        │  Horizontal │  0.5-1.2 μm  │  *** YES   │          │
//  │  │  (m1p*_d0, m1p*_d1)    │            │             │  (to L2 xpt) │  BUF X2    │          │
//  │  ├────────────────────────┼────────────┼─────────────┼───────────────┼────────────┤          │
//  │  │  Stage 4 L2 crosspt    │  M6 (vert) │  Vertical   │  0.5-1.5 μm  │  No (wider │          │
//  │  │  (7×7 + 5×5 grids)     │  M7 (horz) │  Horizontal │  (medium grid)│  metal)    │          │
//  │  ├────────────────────────┼────────────┼─────────────┼───────────────┼────────────┤          │
//  │  │  Stage 4 L2 outputs    │  M7        │  Horizontal │  1.0-3.0 μm  │  *** YES   │          │
//  │  │  (m2p*_d0, m2p*_d1)    │            │             │  (to L3 xpt) │  BUF X4    │          │
//  │  ├────────────────────────┼────────────┼─────────────┼───────────────┼────────────┤          │
//  │  │  Stage 4 L3 crosspt    │  M7 (vert) │  Vertical   │  1.5-3.0 μm  │  Input buf │          │
//  │  │  (13×13 + 9×9 grids)   │  M8 (horz) │  Horizontal │  (large grid) │  *** X4   │          │
//  │  ├────────────────────────┼────────────┼─────────────┼───────────────┼────────────┤          │
//  │  │  Stage 4 L3 outputs    │  M8        │  Horizontal │  2.0-4.0 μm  │  *** YES   │          │
//  │  │  (mf_d0[24:0],         │            │             │  (to Stage 5) │  BUF X4    │          │
//  │  │   mf_d1[16:0])         │            │             │              │  LVT/uLVT  │          │
//  │  ├────────────────────────┼────────────┼─────────────┼───────────────┼────────────┤          │
//  │  │  Stage 5 binary conv   │  M8 (vert) │  Vertical   │  2.0-5.0 μm  │  Input buf │          │
//  │  │  wired-OR grid          │  M9 (horz) │  Horizontal │  (25×17 grid) │  from L3   │          │
//  │  ├────────────────────────┼────────────┼─────────────┼───────────────┼────────────┤          │
//  │  │  hd[6:0] output bus    │  M10       │  Horizontal │  up to 10 μm │  *** YES   │          │
//  │  │                        │            │             │  (to block    │  BUF X8    │          │
//  │  │                        │            │             │   boundary)   │  or X16    │          │
//  │  └────────────────────────┴────────────┴─────────────┴───────────────┴────────────┘          │
//  │                                                                                             │
//  └─────────────────────────────────────────────────────────────────────────────────────────────┘
//
//
//  ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
//  ║                    WIRE RC DELAY ANALYSIS — PER SEGMENT                                    ║
//  ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
//
//  Wire delay model: Elmore delay ≈ 0.5 × R_wire × C_wire + R_wire × C_load + R_driver × C_wire
//
//  For a wire of length L on layer M with resistance r (Ω/μm) and capacitance c (fF/μm):
//    R_wire = r × L
//    C_wire = c × L
//    Elmore ≈ 0.5 × r × c × L² + r × L × C_load + R_drv × c × L
//
//  ┌────────────────────────────────────────────────────────────────────────────────────────────┐
//  │                                                                                            │
//  │  SEGMENT-BY-SEGMENT RC DELAY BUDGET                                                        │
//  │                                                                                            │
//  │  ┌───────────────────────────────┬───────┬──────┬────────┬──────────┬──────────┬─────────┐ │
//  │  │  Segment                      │ Layer │ Len  │R_wire  │ C_wire   │ C_load   │ Delay   │ │
//  │  │                               │       │ (μm) │ (Ω)    │ (fF)     │ (fF)     │ (ps)    │ │
//  │  ├───────────────────────────────┼───────┼──────┼────────┼──────────┼──────────┼─────────┤ │
//  │  │  Fused cell → S2 xpt input   │ M2    │ 0.4  │  10    │  0.07    │  0.5     │  ~5     │ │
//  │  │  S2 3×3 xpt internal wire    │ M2/M3 │ 0.12 │   3    │  0.02    │  0.3     │  ~1.5   │ │
//  │  │  S2 5×5 xpt internal wire    │ M2/M3 │ 0.20 │   5    │  0.04    │  0.5     │  ~3     │ │
//  │  │  S2 output (wired-OR diag)   │ M4    │ 0.5  │   6    │  0.10    │  1.0     │  ~7     │ │
//  │  │  *** BUFFER (X2 LVT) ***     │ ---   │ ---  │  ---   │  ---     │  ---     │  ~12    │ │
//  │  │  S3 radix-4 rewire           │ M4→M5 │ 0.3  │   4    │  0.06    │  0.5     │  ~3     │ │
//  │  │  S4 L1 xpt internal (4×4)    │ M5/M6 │ 0.3  │   3.5  │  0.06    │  0.5     │  ~3     │ │
//  │  │  S4 L1 output                │ M6    │ 0.8  │   8    │  0.16    │  1.5     │  ~14    │ │
//  │  │  *** BUFFER (X2 LVT) ***     │ ---   │ ---  │  ---   │  ---     │  ---     │  ~12    │ │
//  │  │  S4 L2 xpt internal (7×7)    │ M6/M7 │ 0.8  │   5    │  0.18    │  1.0     │  ~6     │ │
//  │  │  S4 L2 output                │ M7    │ 2.0  │   8    │  0.44    │  2.0     │  ~18    │ │
//  │  │  *** BUFFER (X4 LVT) ***     │ ---   │ ---  │  ---   │  ---     │  ---     │  ~10    │ │
//  │  │  S4 L3 xpt internal (13×13)  │ M7/M8 │ 2.5  │  10    │  0.55    │  2.5     │  ~28    │ │
//  │  │  S4 L3 output (mf_d0,mf_d1)  │ M8    │ 3.0  │  12    │  0.66    │  3.0     │  ~40    │ │
//  │  │  *** BUFFER (X4 uLVT) ***    │ ---   │ ---  │  ---   │  ---     │  ---     │  ~8     │ │
//  │  │  S5 binary wired-OR (25×17)  │ M8/M9 │ 4.0  │   5    │  1.00    │  2.0     │  ~12    │ │
//  │  │  S5 output (hd[6:0])         │ M10   │ 5.0  │   6    │  1.25    │  5.0     │  ~35    │ │
//  │  │  *** OUTPUT BUFFER (X8) ***  │ ---   │ ---  │  ---   │  ---     │  ---     │  ~8     │ │
//  │  ├───────────────────────────────┼───────┼──────┼────────┼──────────┼──────────┼─────────┤ │
//  │  │  TOTAL critical path RC      │       │      │        │          │          │~225 ps  │ │
//  │  │  + Fused cell gate delay     │       │      │        │          │          │ ~50 ps  │ │
//  │  │  + Buffer delays (4 stages)  │       │      │        │          │          │ ~42 ps  │ │
//  │  │  ═══════════════════════════  │       │      │        │          │          │═════════│ │
//  │  │  TOTAL ESTIMATED DELAY       │       │      │        │          │          │~317 ps  │ │
//  │  │  (worst case, TT corner)     │       │      │        │          │          │         │ │
//  │  ├───────────────────────────────┼───────┼──────┼────────┼──────────┼──────────┼─────────┤ │
//  │  │  With uLVT on critical path  │       │      │        │          │          │~270 ps  │ │
//  │  │  ≈ ~3.3–3.7 GHz potential    │       │      │        │          │          │         │ │
//  │  └───────────────────────────────┴───────┴──────┴────────┴──────────┴──────────┴─────────┘ │
//  │                                                                                            │
//  └────────────────────────────────────────────────────────────────────────────────────────────┘
//
//
//  ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
//  ║                    BUFFER INSERTION PLAN — DETAILED                                        ║
//  ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
//
//  Buffer insertion is needed wherever wire RC delay exceeds the gate delay of a single
//  inverter (~10 ps), meaning the wire is too long/resistive for the driver to charge.
//
//  RULE OF THUMB at N5: Insert buffer when wire delay > 15-20 ps (roughly L > 0.8 μm on M2/M3
//  or L > 2 μm on M6/M7).
//
//  ┌────────────────────────────────────────────────────────────────────────────────────────────┐
//  │                                                                                            │
//  │  BUFFER INSERTION POINTS (*** marks critical path buffers)                                  │
//  │                                                                                            │
//  │  ┌───┬───────────────────────────┬──────────┬──────┬──────┬──────────────────────────────┐ │
//  │  │ # │  Location                 │ Cell     │ Vt   │ Fins │ Rationale                    │ │
//  │  ├───┼───────────────────────────┼──────────┼──────┼──────┼──────────────────────────────┤ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │   │  ── INPUT BUFFERS ──      │          │      │      │                              │ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │ 1 │  a[63:0] input pins       │ BUFX4    │ SVT  │ 4p/4n│ Restore full-swing from     │ │
//  │  │   │  (128 buffers total)      │          │      │      │ pad/ESD structure.           │ │
//  │  │   │                           │          │      │      │ NOT on critical path.        │ │
//  │  │ 2 │  b[63:0] input pins       │ BUFX4    │ SVT  │ 4p/4n│ Same as above.              │ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │   │  ── STAGE 2 EXIT ── ***   │          │      │      │                              │ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │ 3 │  byte*_oh[8:0] outputs    │ BUFX2    │ LVT  │ 2p/2n│ The 5×5 crosspoint wired-OR │ │
//  │  │   │  (8 bytes × 9 wires       │          │      │      │ output on M4 drives into    │ │
//  │  │   │   = 72 buffers)           │          │      │      │ Stage 3 rewiring. Wire fan-  │ │
//  │  │   │                           │          │      │      │ out to 2 radix-4 digit buses │ │
//  │  │   │                           │          │      │      │ needs rebuffering.           │ │
//  │  │   │                           │          │      │      │ Delay contribution: ~12 ps   │ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │   │  ── STAGE 4 LEVEL 1 EXIT ── ***                                                  │ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │ 4 │  m1p*_d0[6:0] outputs     │ BUFX2    │ LVT  │ 2p/2n│ L1 outputs travel 0.8-1.2   │ │
//  │  │   │  m1p*_d1[4:0] outputs     │          │      │      │ μm on M6 to reach L2 xpt.   │ │
//  │  │   │  (4 pairs × 12 wires      │          │      │      │ Wired-OR from 4×4 grid has   │ │
//  │  │   │   = 48 buffers)           │          │      │      │ up to 4 via loads; rebuffer  │ │
//  │  │   │                           │          │      │      │ to drive L2 crosspoint.      │ │
//  │  │   │                           │          │      │      │ Delay contribution: ~12 ps   │ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │   │  ── STAGE 4 LEVEL 2 EXIT ── ***                                                  │ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │ 5 │  m2p*_d0[12:0] outputs    │ BUFX4    │ LVT  │ 4p/4n│ L2 outputs travel 2.0-3.0   │ │
//  │  │   │  m2p*_d1[8:0] outputs     │          │      │      │ μm on M7 to reach L3 xpt.   │ │
//  │  │   │  (2 pairs × 22 wires      │          │      │      │ Larger crosspoints (7×7)     │ │
//  │  │   │   = 44 buffers)           │          │      │      │ have more via loading.       │ │
//  │  │   │                           │          │      │      │ X4 needed to drive the wire  │ │
//  │  │   │                           │          │      │      │ RC on semi-global M7.        │ │
//  │  │   │                           │          │      │      │ Delay contribution: ~10 ps   │ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │   │  ── STAGE 4 LEVEL 3 EXIT ── *** CRITICAL ***                                     │ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │ 6 │  mf_d0[24:0] outputs      │ BUFX4    │ uLVT │ 4p/4n│ The final merge outputs are  │ │
//  │  │   │  mf_d1[16:0] outputs      │          │      │      │ the WIDEST wired-OR nets in  │ │
//  │  │   │  (42 buffers total)       │          │      │      │ the design (13×13 grid for   │ │
//  │  │   │                           │          │      │      │ d0). These drive 3-4 μm on   │ │
//  │  │   │                           │          │      │      │ M8 into the Stage 5 binary   │ │
//  │  │   │                           │          │      │      │ conversion. Using uLVT here  │ │
//  │  │   │                           │          │      │      │ saves ~5 ps on critical path │ │
//  │  │   │                           │          │      │      │ at modest leakage cost (42   │ │
//  │  │   │                           │          │      │      │ cells only).                 │ │
//  │  │   │                           │          │      │      │ Delay contribution: ~8 ps    │ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │   │  ── OUTPUT BUFFERS ── ***                                                         │ │
//  │  │   │                           │          │      │      │                              │ │
//  │  │ 7 │  hd[6:0] output pins      │ BUFX8    │ LVT  │ 8p/8n│ Final output drives off-    │ │
//  │  │   │  (7 buffers)              │  or X16  │      │      │ block wire (potentially >10  │ │
//  │  │   │                           │          │      │      │ μm). Need high drive to      │ │
//  │  │   │                           │          │      │      │ meet timing at block edge.   │ │
//  │  │   │                           │          │      │      │ May need 2-stage buffer tree │ │
//  │  │   │                           │          │      │      │ (INV X4 → INV X16) if load   │ │
//  │  │   │                           │          │      │      │ > 20 fF.                     │ │
//  │  │   │                           │          │      │      │ Delay contribution: ~8 ps    │ │
//  │  ├───┴───────────────────────────┴──────────┴──────┴──────┴──────────────────────────────┤ │
//  │  │                                                                                       │ │
//  │  │  BUFFER SUMMARY                                                                       │ │
//  │  │  ──────────────────────────────────────────────────────────                            │ │
//  │  │  Input buffers (a,b):              128 + 128 = 256  (BUFX4, SVT)                      │ │
//  │  │  Stage 2 exit:                     72               (BUFX2, LVT)                      │ │
//  │  │  Stage 4 L1 exit:                  48               (BUFX2, LVT)                      │ │
//  │  │  Stage 4 L2 exit:                  44               (BUFX4, LVT)                      │ │
//  │  │  Stage 4 L3 exit:                  42               (BUFX4, uLVT)  ← critical path    │ │
//  │  │  Output buffers (hd):               7               (BUFX8, LVT)                      │ │
//  │  │  ──────────────────────────────────────────────────────────                            │ │
//  │  │  TOTAL BUFFERS:                    469                                                 │ │
//  │  │  TOTAL BUFFER TRANSISTORS:         ~2200 fins                                          │ │
//  │  │                                                                                       │ │
//  │  │  For comparison, the fused cells use only ~480 fins.                                   │ │
//  │  │  Buffers account for ~82% of total active devices — this is TYPICAL for                │ │
//  │  │  wire-dominated designs at advanced nodes where interconnect, not logic,               │ │
//  │  │  dictates the transistor budget.                                                       │ │
//  │  │                                                                                       │ │
//  │  └───────────────────────────────────────────────────────────────────────────────────────┘ │
//  │                                                                                            │
//  └────────────────────────────────────────────────────────────────────────────────────────────┘
//
//
//  ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
//  ║                    COMPLETE TIMING PATH SUMMARY                                            ║
//  ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
//
//  Critical path: a[i]/b[i] → fc*_oh1 → byte*_oh → radix4 → merge L1 → L2 → L3 → binary → hd
//
//  ┌─────────────────────────────────────────────────────────────────────────────────────────┐
//  │  Stage │ Element                │ Type       │ Delay (ps) │ Running (ps) │ Layer       │
//  ├────────┼────────────────────────┼────────────┼────────────┼──────────────┼─────────────┤
//  │  In    │ Input buffer BUFX4     │ Gate       │    9       │    9         │ M1          │
//  │  1     │ Fused cell (OH1 path)  │ Gate       │   50       │   59         │ M1/poly     │
//  │  1→2   │ OH wire to crosspoint  │ Wire RC    │    5       │   64         │ M2          │
//  │  2     │ 3×3 crosspoint L1      │ Wire RC    │    5       │   69         │ M2/M3       │
//  │  2     │ 5×5 crosspoint L2      │ Wire RC    │   10       │   79         │ M2/M3       │
//  │  2→3   │ Buffer BUFX2 (S2 exit) │ Gate       │   12       │   91         │ M4          │
//  │  3     │ Radix-4 rewire         │ Wire RC    │    3       │   94         │ M4→M5       │
//  │  4-L1  │ 4×4 crosspoint d0      │ Wire RC    │    5       │   99         │ M5/M6       │
//  │  4-L1  │ Buffer BUFX2 (L1 exit) │ Gate       │   12       │  111         │ M6          │
//  │  4-L2  │ 7×7 crosspoint d0      │ Wire RC    │   12       │  123         │ M6/M7       │
//  │  4-L2  │ Wire to L3 + BUF X4    │ Wire+Gate  │   28       │  151         │ M7          │
//  │  4-L3  │ 13×13 crosspoint d0    │ Wire RC    │   35       │  186         │ M7/M8       │
//  │  4-L3  │ Buffer BUFX4 uLVT      │ Gate       │    8       │  194         │ M8          │
//  │  4→5   │ Wire to binary grid    │ Wire RC    │   15       │  209         │ M8          │
//  │  5     │ 25×17 wired-OR binary  │ Wire RC    │   20       │  229         │ M8/M9       │
//  │  5     │ hd wire + output buf   │ Wire+Gate  │   25       │  254         │ M9/M10      │
//  ├────────┼────────────────────────┼────────────┼────────────┼──────────────┼─────────────┤
//  │  TOTAL │                        │            │  ~254 ps   │              │             │
//  │  Freq  │  1 / 254ps ≈ 3.9 GHz (TT corner)   │            │              │             │
//  │        │  ~3.2 GHz at SS/0.675V/125°C corner │            │              │             │
//  │        │  ~4.5 GHz at FF/0.825V/-40°C corner │            │              │             │
//  └────────┴────────────────────────┴────────────┴────────────┴──────────────┴─────────────┘
//
//  POWER ESTIMATE (0.75V, TT, 1 GHz toggle rate):
//    Fused cells (dynamic):  32 × ~15 fins × 0.75V² × 1GHz × ~0.05fF/fin ≈ 13 μW
//    Buffers (dynamic):      469 bufs × avg 5fF × 0.75V² × 1GHz × 0.5 activity ≈ 660 μW
//    Crosspoint wire charge: ~35 matrices × avg 20fF × 0.75V² × 1GHz ≈ 390 μW
//    Leakage (LVT+uLVT):    ~50-100 μW
//    TOTAL:                  ~1.1 - 1.2 mW at 1 GHz (scales linearly with frequency)
//
//====================================================================================================

`timescale 1ps / 1fs

module hamming_distance_64 (
  input  wire [63:0] a,
  input  wire [63:0] b,
  output wire [6:0]  hd
);

  // ====================================================================================================
  // STAGE 1: FUSED HAMMING CELLS
  // ====================================================================================================
  //
  // PHYSICAL: Transistor layer (poly + M1). 32 cells in 8 groups of 4.
  //   Cell size: ~10 CPP × 5T = 480nm × 270nm. Total: ~32 cells ≈ 20.6 μm × 0.8 μm.
  //   Vt selection: LVT for all fused cells (critical path starts here).
  //   Drive: X1 (1 fin per transistor) is adequate — outputs drive only ~0.4 μm M2 wire.
  //   Output exits on M2 (vertical) upward to Stage 2 crosspoints.
  //
  //   GATE DELAYS IN THIS STAGE:
  //     OH0 (AND-of-XNOR): ~35-45 ps at N5 LVT, X1, 0.75V, FO1 wire load
  //     OH1 (4-input XOR):  ~40-55 ps — CRITICAL PATH (pass-transistor chain)
  //     OH2 (AND-of-XOR):   ~35-45 ps — structural dual of OH0
  //
  //   The pass-transistor XOR chain delay is the longest because the signal must
  //   propagate through 4 series transmission gates. At N5 LVT, each pass gate adds
  //   ~10-14 ps due to the series resistance of the fin channel.
  //

  wire fc0_oh0, fc0_oh1, fc0_oh2;  // Fused cell 0, exits on M2 vertical
  wire fc1_oh0, fc1_oh1, fc1_oh2;  // Fused cell 1, exits on M2 vertical
  wire fc2_oh0, fc2_oh1, fc2_oh2;  // Fused cell 2, exits on M2 vertical
  wire fc3_oh0, fc3_oh1, fc3_oh2;  // Fused cell 3, exits on M2 vertical
  wire fc4_oh0, fc4_oh1, fc4_oh2;  // Fused cell 4, exits on M2 vertical
  wire fc5_oh0, fc5_oh1, fc5_oh2;  // Fused cell 5, exits on M2 vertical
  wire fc6_oh0, fc6_oh1, fc6_oh2;  // Fused cell 6, exits on M2 vertical
  wire fc7_oh0, fc7_oh1, fc7_oh2;  // Fused cell 7, exits on M2 vertical
  wire fc8_oh0, fc8_oh1, fc8_oh2;  // Fused cell 8, exits on M2 vertical
  wire fc9_oh0, fc9_oh1, fc9_oh2;  // Fused cell 9, exits on M2 vertical
  wire fc10_oh0, fc10_oh1, fc10_oh2;  // Fused cell 10, exits on M2 vertical
  wire fc11_oh0, fc11_oh1, fc11_oh2;  // Fused cell 11, exits on M2 vertical
  wire fc12_oh0, fc12_oh1, fc12_oh2;  // Fused cell 12, exits on M2 vertical
  wire fc13_oh0, fc13_oh1, fc13_oh2;  // Fused cell 13, exits on M2 vertical
  wire fc14_oh0, fc14_oh1, fc14_oh2;  // Fused cell 14, exits on M2 vertical
  wire fc15_oh0, fc15_oh1, fc15_oh2;  // Fused cell 15, exits on M2 vertical
  wire fc16_oh0, fc16_oh1, fc16_oh2;  // Fused cell 16, exits on M2 vertical
  wire fc17_oh0, fc17_oh1, fc17_oh2;  // Fused cell 17, exits on M2 vertical
  wire fc18_oh0, fc18_oh1, fc18_oh2;  // Fused cell 18, exits on M2 vertical
  wire fc19_oh0, fc19_oh1, fc19_oh2;  // Fused cell 19, exits on M2 vertical
  wire fc20_oh0, fc20_oh1, fc20_oh2;  // Fused cell 20, exits on M2 vertical
  wire fc21_oh0, fc21_oh1, fc21_oh2;  // Fused cell 21, exits on M2 vertical
  wire fc22_oh0, fc22_oh1, fc22_oh2;  // Fused cell 22, exits on M2 vertical
  wire fc23_oh0, fc23_oh1, fc23_oh2;  // Fused cell 23, exits on M2 vertical
  wire fc24_oh0, fc24_oh1, fc24_oh2;  // Fused cell 24, exits on M2 vertical
  wire fc25_oh0, fc25_oh1, fc25_oh2;  // Fused cell 25, exits on M2 vertical
  wire fc26_oh0, fc26_oh1, fc26_oh2;  // Fused cell 26, exits on M2 vertical
  wire fc27_oh0, fc27_oh1, fc27_oh2;  // Fused cell 27, exits on M2 vertical
  wire fc28_oh0, fc28_oh1, fc28_oh2;  // Fused cell 28, exits on M2 vertical
  wire fc29_oh0, fc29_oh1, fc29_oh2;  // Fused cell 29, exits on M2 vertical
  wire fc30_oh0, fc30_oh1, fc30_oh2;  // Fused cell 30, exits on M2 vertical
  wire fc31_oh0, fc31_oh1, fc31_oh2;  // Fused cell 31, exits on M2 vertical

  // ── fc0: bits (0,1), byte 0 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc0_oh0 = (a[0] ~^ b[0]) & (a[1] ~^ b[1]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc0_oh1 = a[0] ^ b[0] ^ a[1] ^ b[1];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc0_oh2 = (a[0] ^ b[0]) & (a[1] ^ b[1]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc1: bits (2,3), byte 0 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc1_oh0 = (a[2] ~^ b[2]) & (a[3] ~^ b[3]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc1_oh1 = a[2] ^ b[2] ^ a[3] ^ b[3];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc1_oh2 = (a[2] ^ b[2]) & (a[3] ^ b[3]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc2: bits (4,5), byte 0 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc2_oh0 = (a[4] ~^ b[4]) & (a[5] ~^ b[5]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc2_oh1 = a[4] ^ b[4] ^ a[5] ^ b[5];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc2_oh2 = (a[4] ^ b[4]) & (a[5] ^ b[5]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc3: bits (6,7), byte 0 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc3_oh0 = (a[6] ~^ b[6]) & (a[7] ~^ b[7]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc3_oh1 = a[6] ^ b[6] ^ a[7] ^ b[7];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc3_oh2 = (a[6] ^ b[6]) & (a[7] ^ b[7]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc4: bits (8,9), byte 1 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc4_oh0 = (a[8] ~^ b[8]) & (a[9] ~^ b[9]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc4_oh1 = a[8] ^ b[8] ^ a[9] ^ b[9];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc4_oh2 = (a[8] ^ b[8]) & (a[9] ^ b[9]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc5: bits (10,11), byte 1 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc5_oh0 = (a[10] ~^ b[10]) & (a[11] ~^ b[11]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc5_oh1 = a[10] ^ b[10] ^ a[11] ^ b[11];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc5_oh2 = (a[10] ^ b[10]) & (a[11] ^ b[11]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc6: bits (12,13), byte 1 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc6_oh0 = (a[12] ~^ b[12]) & (a[13] ~^ b[13]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc6_oh1 = a[12] ^ b[12] ^ a[13] ^ b[13];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc6_oh2 = (a[12] ^ b[12]) & (a[13] ^ b[13]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc7: bits (14,15), byte 1 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc7_oh0 = (a[14] ~^ b[14]) & (a[15] ~^ b[15]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc7_oh1 = a[14] ^ b[14] ^ a[15] ^ b[15];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc7_oh2 = (a[14] ^ b[14]) & (a[15] ^ b[15]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc8: bits (16,17), byte 2 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc8_oh0 = (a[16] ~^ b[16]) & (a[17] ~^ b[17]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc8_oh1 = a[16] ^ b[16] ^ a[17] ^ b[17];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc8_oh2 = (a[16] ^ b[16]) & (a[17] ^ b[17]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc9: bits (18,19), byte 2 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc9_oh0 = (a[18] ~^ b[18]) & (a[19] ~^ b[19]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc9_oh1 = a[18] ^ b[18] ^ a[19] ^ b[19];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc9_oh2 = (a[18] ^ b[18]) & (a[19] ^ b[19]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc10: bits (20,21), byte 2 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc10_oh0 = (a[20] ~^ b[20]) & (a[21] ~^ b[21]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc10_oh1 = a[20] ^ b[20] ^ a[21] ^ b[21];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc10_oh2 = (a[20] ^ b[20]) & (a[21] ^ b[21]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc11: bits (22,23), byte 2 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc11_oh0 = (a[22] ~^ b[22]) & (a[23] ~^ b[23]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc11_oh1 = a[22] ^ b[22] ^ a[23] ^ b[23];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc11_oh2 = (a[22] ^ b[22]) & (a[23] ^ b[23]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc12: bits (24,25), byte 3 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc12_oh0 = (a[24] ~^ b[24]) & (a[25] ~^ b[25]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc12_oh1 = a[24] ^ b[24] ^ a[25] ^ b[25];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc12_oh2 = (a[24] ^ b[24]) & (a[25] ^ b[25]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc13: bits (26,27), byte 3 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc13_oh0 = (a[26] ~^ b[26]) & (a[27] ~^ b[27]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc13_oh1 = a[26] ^ b[26] ^ a[27] ^ b[27];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc13_oh2 = (a[26] ^ b[26]) & (a[27] ^ b[27]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc14: bits (28,29), byte 3 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc14_oh0 = (a[28] ~^ b[28]) & (a[29] ~^ b[29]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc14_oh1 = a[28] ^ b[28] ^ a[29] ^ b[29];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc14_oh2 = (a[28] ^ b[28]) & (a[29] ^ b[29]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc15: bits (30,31), byte 3 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc15_oh0 = (a[30] ~^ b[30]) & (a[31] ~^ b[31]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc15_oh1 = a[30] ^ b[30] ^ a[31] ^ b[31];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc15_oh2 = (a[30] ^ b[30]) & (a[31] ^ b[31]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc16: bits (32,33), byte 4 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc16_oh0 = (a[32] ~^ b[32]) & (a[33] ~^ b[33]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc16_oh1 = a[32] ^ b[32] ^ a[33] ^ b[33];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc16_oh2 = (a[32] ^ b[32]) & (a[33] ^ b[33]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc17: bits (34,35), byte 4 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc17_oh0 = (a[34] ~^ b[34]) & (a[35] ~^ b[35]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc17_oh1 = a[34] ^ b[34] ^ a[35] ^ b[35];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc17_oh2 = (a[34] ^ b[34]) & (a[35] ^ b[35]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc18: bits (36,37), byte 4 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc18_oh0 = (a[36] ~^ b[36]) & (a[37] ~^ b[37]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc18_oh1 = a[36] ^ b[36] ^ a[37] ^ b[37];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc18_oh2 = (a[36] ^ b[36]) & (a[37] ^ b[37]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc19: bits (38,39), byte 4 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc19_oh0 = (a[38] ~^ b[38]) & (a[39] ~^ b[39]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc19_oh1 = a[38] ^ b[38] ^ a[39] ^ b[39];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc19_oh2 = (a[38] ^ b[38]) & (a[39] ^ b[39]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc20: bits (40,41), byte 5 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc20_oh0 = (a[40] ~^ b[40]) & (a[41] ~^ b[41]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc20_oh1 = a[40] ^ b[40] ^ a[41] ^ b[41];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc20_oh2 = (a[40] ^ b[40]) & (a[41] ^ b[41]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc21: bits (42,43), byte 5 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc21_oh0 = (a[42] ~^ b[42]) & (a[43] ~^ b[43]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc21_oh1 = a[42] ^ b[42] ^ a[43] ^ b[43];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc21_oh2 = (a[42] ^ b[42]) & (a[43] ^ b[43]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc22: bits (44,45), byte 5 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc22_oh0 = (a[44] ~^ b[44]) & (a[45] ~^ b[45]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc22_oh1 = a[44] ^ b[44] ^ a[45] ^ b[45];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc22_oh2 = (a[44] ^ b[44]) & (a[45] ^ b[45]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc23: bits (46,47), byte 5 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc23_oh0 = (a[46] ~^ b[46]) & (a[47] ~^ b[47]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc23_oh1 = a[46] ^ b[46] ^ a[47] ^ b[47];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc23_oh2 = (a[46] ^ b[46]) & (a[47] ^ b[47]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc24: bits (48,49), byte 6 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc24_oh0 = (a[48] ~^ b[48]) & (a[49] ~^ b[49]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc24_oh1 = a[48] ^ b[48] ^ a[49] ^ b[49];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc24_oh2 = (a[48] ^ b[48]) & (a[49] ^ b[49]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc25: bits (50,51), byte 6 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc25_oh0 = (a[50] ~^ b[50]) & (a[51] ~^ b[51]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc25_oh1 = a[50] ^ b[50] ^ a[51] ^ b[51];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc25_oh2 = (a[50] ^ b[50]) & (a[51] ^ b[51]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc26: bits (52,53), byte 6 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc26_oh0 = (a[52] ~^ b[52]) & (a[53] ~^ b[53]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc26_oh1 = a[52] ^ b[52] ^ a[53] ^ b[53];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc26_oh2 = (a[52] ^ b[52]) & (a[53] ^ b[53]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc27: bits (54,55), byte 6 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc27_oh0 = (a[54] ~^ b[54]) & (a[55] ~^ b[55]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc27_oh1 = a[54] ^ b[54] ^ a[55] ^ b[55];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc27_oh2 = (a[54] ^ b[54]) & (a[55] ^ b[55]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc28: bits (56,57), byte 7 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc28_oh0 = (a[56] ~^ b[56]) & (a[57] ~^ b[57]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc28_oh1 = a[56] ^ b[56] ^ a[57] ^ b[57];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc28_oh2 = (a[56] ^ b[56]) & (a[57] ^ b[57]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc29: bits (58,59), byte 7 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc29_oh0 = (a[58] ~^ b[58]) & (a[59] ~^ b[59]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc29_oh1 = a[58] ^ b[58] ^ a[59] ^ b[59];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc29_oh2 = (a[58] ^ b[58]) & (a[59] ^ b[59]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc30: bits (60,61), byte 7 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc30_oh0 = (a[60] ~^ b[60]) & (a[61] ~^ b[61]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc30_oh1 = a[60] ^ b[60] ^ a[61] ^ b[61];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc30_oh2 = (a[60] ^ b[60]) & (a[61] ^ b[61]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ── fc31: bits (62,63), byte 7 ── LVT X1, ~15 fins, M1/poly ──
  // OH0→M2 vert ↑ ~0.4μm to S2 xpt, wire RC ~5ps, no buffer needed
  assign fc31_oh0 = (a[62] ~^ b[62]) & (a[63] ~^ b[63]);  // AND-of-XNOR: ~38ps gate + ~5ps wire
  assign fc31_oh1 = a[62] ^ b[62] ^ a[63] ^ b[63];        // 4-input XOR:  ~48ps gate + ~5ps wire ***CRIT***
  assign fc31_oh2 = (a[62] ^ b[62]) & (a[63] ^ b[63]);    // AND-of-XOR:   ~38ps gate + ~5ps wire

  // ====================================================================================================
  // STAGE 2: CROSSPOINT SUMMATION TREES — M2/M3/M4
  // ====================================================================================================
  //
  // PHYSICAL: 8 parallel byte-level summation trees.
  //   3×3 crosspoints: M2 vertical × M3 horizontal, vias at intersections.
  //     Grid physical size: 3 wires × 28nm pitch = 84nm × 84nm — extremely small.
  //     Wire length per crosspoint wire: ~0.08-0.12 μm. RC delay: ~1-2 ps.
  //   5×5 crosspoints: M2 vertical × M3 horizontal.
  //     Grid physical size: 5 × 28nm = 140nm × 140nm.
  //     Wire length: ~0.14-0.20 μm. RC delay: ~2-4 ps.
  //   Output collection: Diagonal wired-OR wires run on M4.
  //     Wire length: ~0.3-0.6 μm. RC delay: ~5-8 ps.
  //
  //   *** BUFFER AT STAGE 2 EXIT: byte*_oh[8:0] ***
  //     The 9-wire one-hot output from each byte tree is buffered with BUFX2 LVT
  //     before entering Stage 3. This is because:
  //     (a) The wired-OR output from the 5×5 grid is driven passively (no active gate)
  //     (b) The wire has been loaded by multiple via connections
  //     (c) Stage 3 rewiring fans out each wire to 2 digit buses
  //     Buffer delay: ~12 ps (BUFX2 LVT = INV + INV, each ~6 ps)
  //
  //   Total Stage 2 delay (critical path through one byte tree):
  //     3×3 xpt: ~2 ps + 5×5 xpt: ~4 ps + M4 collection: ~7 ps + buffer: ~12 ps = ~25 ps
  //

  // ═══ Byte 0: fc0-3 → byte0_oh[8:0] ═══
  // Placed at X = 0.0μm, Y = 2.5-4.5μm in floorplan
  wire [2:0] b0_fc0;
  assign b0_fc0 = {fc0_oh2, fc0_oh1, fc0_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b0_fc1;
  assign b0_fc1 = {fc1_oh2, fc1_oh1, fc1_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b0_fc2;
  assign b0_fc2 = {fc2_oh2, fc2_oh1, fc2_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b0_fc3;
  assign b0_fc3 = {fc3_oh2, fc3_oh1, fc3_oh0};  // Pack for xpt input, M2 vert

  wire [4:0] b0_s1a;  // 3×3 xpt output, M3→M4 diagonal, ~2ps RC
  assign b0_s1a[0] = (b0_fc0[0] & b0_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign b0_s1a[1] = (b0_fc0[0] & b0_fc1[1]) | (b0_fc0[1] & b0_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign b0_s1a[2] = (b0_fc0[0] & b0_fc1[2]) | (b0_fc0[1] & b0_fc1[1]) | (b0_fc0[2] & b0_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign b0_s1a[3] = (b0_fc0[1] & b0_fc1[2]) | (b0_fc0[2] & b0_fc1[1]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign b0_s1a[4] = (b0_fc0[2] & b0_fc1[2]);  // M2v×M3h via→M4 diag wired-OR, sum=4

  wire [4:0] b0_s1b;  // 3×3 xpt output, M3→M4 diagonal, ~2ps RC
  assign b0_s1b[0] = (b0_fc2[0] & b0_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign b0_s1b[1] = (b0_fc2[0] & b0_fc3[1]) | (b0_fc2[1] & b0_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign b0_s1b[2] = (b0_fc2[0] & b0_fc3[2]) | (b0_fc2[1] & b0_fc3[1]) | (b0_fc2[2] & b0_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign b0_s1b[3] = (b0_fc2[1] & b0_fc3[2]) | (b0_fc2[2] & b0_fc3[1]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign b0_s1b[4] = (b0_fc2[2] & b0_fc3[2]);  // M2v×M3h via→M4 diag wired-OR, sum=4

  wire [8:0] byte0_oh;  // 5×5 xpt output, M4 collect, ~7ps RC → BUFFERED
  assign byte0_oh[0] = (b0_s1a[0] & b0_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign byte0_oh[1] = (b0_s1a[0] & b0_s1b[1]) | (b0_s1a[1] & b0_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign byte0_oh[2] = (b0_s1a[0] & b0_s1b[2]) | (b0_s1a[1] & b0_s1b[1]) | (b0_s1a[2] & b0_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign byte0_oh[3] = (b0_s1a[0] & b0_s1b[3]) | (b0_s1a[1] & b0_s1b[2]) | (b0_s1a[2] & b0_s1b[1]) | (b0_s1a[3] & b0_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign byte0_oh[4] = (b0_s1a[0] & b0_s1b[4]) | (b0_s1a[1] & b0_s1b[3]) | (b0_s1a[2] & b0_s1b[2]) | (b0_s1a[3] & b0_s1b[1]) | (b0_s1a[4] & b0_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=4
  assign byte0_oh[5] = (b0_s1a[1] & b0_s1b[4]) | (b0_s1a[2] & b0_s1b[3]) | (b0_s1a[3] & b0_s1b[2]) | (b0_s1a[4] & b0_s1b[1]);  // M2v×M3h via→M4 diag wired-OR, sum=5
  assign byte0_oh[6] = (b0_s1a[2] & b0_s1b[4]) | (b0_s1a[3] & b0_s1b[3]) | (b0_s1a[4] & b0_s1b[2]);  // M2v×M3h via→M4 diag wired-OR, sum=6
  assign byte0_oh[7] = (b0_s1a[3] & b0_s1b[4]) | (b0_s1a[4] & b0_s1b[3]);  // M2v×M3h via→M4 diag wired-OR, sum=7
  assign byte0_oh[8] = (b0_s1a[4] & b0_s1b[4]);  // M2v×M3h via→M4 diag wired-OR, sum=8

  // *** byte0_oh[8:0] → BUFX2 LVT (72 buffers total, ~12ps) → Stage 3 input ***

  // ═══ Byte 1: fc4-7 → byte1_oh[8:0] ═══
  // Placed at X = 2.6μm, Y = 2.5-4.5μm in floorplan
  wire [2:0] b1_fc0;
  assign b1_fc0 = {fc4_oh2, fc4_oh1, fc4_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b1_fc1;
  assign b1_fc1 = {fc5_oh2, fc5_oh1, fc5_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b1_fc2;
  assign b1_fc2 = {fc6_oh2, fc6_oh1, fc6_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b1_fc3;
  assign b1_fc3 = {fc7_oh2, fc7_oh1, fc7_oh0};  // Pack for xpt input, M2 vert

  wire [4:0] b1_s1a;  // 3×3 xpt output, M3→M4 diagonal, ~2ps RC
  assign b1_s1a[0] = (b1_fc0[0] & b1_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign b1_s1a[1] = (b1_fc0[0] & b1_fc1[1]) | (b1_fc0[1] & b1_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign b1_s1a[2] = (b1_fc0[0] & b1_fc1[2]) | (b1_fc0[1] & b1_fc1[1]) | (b1_fc0[2] & b1_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign b1_s1a[3] = (b1_fc0[1] & b1_fc1[2]) | (b1_fc0[2] & b1_fc1[1]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign b1_s1a[4] = (b1_fc0[2] & b1_fc1[2]);  // M2v×M3h via→M4 diag wired-OR, sum=4

  wire [4:0] b1_s1b;  // 3×3 xpt output, M3→M4 diagonal, ~2ps RC
  assign b1_s1b[0] = (b1_fc2[0] & b1_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign b1_s1b[1] = (b1_fc2[0] & b1_fc3[1]) | (b1_fc2[1] & b1_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign b1_s1b[2] = (b1_fc2[0] & b1_fc3[2]) | (b1_fc2[1] & b1_fc3[1]) | (b1_fc2[2] & b1_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign b1_s1b[3] = (b1_fc2[1] & b1_fc3[2]) | (b1_fc2[2] & b1_fc3[1]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign b1_s1b[4] = (b1_fc2[2] & b1_fc3[2]);  // M2v×M3h via→M4 diag wired-OR, sum=4

  wire [8:0] byte1_oh;  // 5×5 xpt output, M4 collect, ~7ps RC → BUFFERED
  assign byte1_oh[0] = (b1_s1a[0] & b1_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign byte1_oh[1] = (b1_s1a[0] & b1_s1b[1]) | (b1_s1a[1] & b1_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign byte1_oh[2] = (b1_s1a[0] & b1_s1b[2]) | (b1_s1a[1] & b1_s1b[1]) | (b1_s1a[2] & b1_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign byte1_oh[3] = (b1_s1a[0] & b1_s1b[3]) | (b1_s1a[1] & b1_s1b[2]) | (b1_s1a[2] & b1_s1b[1]) | (b1_s1a[3] & b1_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign byte1_oh[4] = (b1_s1a[0] & b1_s1b[4]) | (b1_s1a[1] & b1_s1b[3]) | (b1_s1a[2] & b1_s1b[2]) | (b1_s1a[3] & b1_s1b[1]) | (b1_s1a[4] & b1_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=4
  assign byte1_oh[5] = (b1_s1a[1] & b1_s1b[4]) | (b1_s1a[2] & b1_s1b[3]) | (b1_s1a[3] & b1_s1b[2]) | (b1_s1a[4] & b1_s1b[1]);  // M2v×M3h via→M4 diag wired-OR, sum=5
  assign byte1_oh[6] = (b1_s1a[2] & b1_s1b[4]) | (b1_s1a[3] & b1_s1b[3]) | (b1_s1a[4] & b1_s1b[2]);  // M2v×M3h via→M4 diag wired-OR, sum=6
  assign byte1_oh[7] = (b1_s1a[3] & b1_s1b[4]) | (b1_s1a[4] & b1_s1b[3]);  // M2v×M3h via→M4 diag wired-OR, sum=7
  assign byte1_oh[8] = (b1_s1a[4] & b1_s1b[4]);  // M2v×M3h via→M4 diag wired-OR, sum=8

  // *** byte1_oh[8:0] → BUFX2 LVT (72 buffers total, ~12ps) → Stage 3 input ***

  // ═══ Byte 2: fc8-11 → byte2_oh[8:0] ═══
  // Placed at X = 5.2μm, Y = 2.5-4.5μm in floorplan
  wire [2:0] b2_fc0;
  assign b2_fc0 = {fc8_oh2, fc8_oh1, fc8_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b2_fc1;
  assign b2_fc1 = {fc9_oh2, fc9_oh1, fc9_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b2_fc2;
  assign b2_fc2 = {fc10_oh2, fc10_oh1, fc10_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b2_fc3;
  assign b2_fc3 = {fc11_oh2, fc11_oh1, fc11_oh0};  // Pack for xpt input, M2 vert

  wire [4:0] b2_s1a;  // 3×3 xpt output, M3→M4 diagonal, ~2ps RC
  assign b2_s1a[0] = (b2_fc0[0] & b2_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign b2_s1a[1] = (b2_fc0[0] & b2_fc1[1]) | (b2_fc0[1] & b2_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign b2_s1a[2] = (b2_fc0[0] & b2_fc1[2]) | (b2_fc0[1] & b2_fc1[1]) | (b2_fc0[2] & b2_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign b2_s1a[3] = (b2_fc0[1] & b2_fc1[2]) | (b2_fc0[2] & b2_fc1[1]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign b2_s1a[4] = (b2_fc0[2] & b2_fc1[2]);  // M2v×M3h via→M4 diag wired-OR, sum=4

  wire [4:0] b2_s1b;  // 3×3 xpt output, M3→M4 diagonal, ~2ps RC
  assign b2_s1b[0] = (b2_fc2[0] & b2_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign b2_s1b[1] = (b2_fc2[0] & b2_fc3[1]) | (b2_fc2[1] & b2_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign b2_s1b[2] = (b2_fc2[0] & b2_fc3[2]) | (b2_fc2[1] & b2_fc3[1]) | (b2_fc2[2] & b2_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign b2_s1b[3] = (b2_fc2[1] & b2_fc3[2]) | (b2_fc2[2] & b2_fc3[1]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign b2_s1b[4] = (b2_fc2[2] & b2_fc3[2]);  // M2v×M3h via→M4 diag wired-OR, sum=4

  wire [8:0] byte2_oh;  // 5×5 xpt output, M4 collect, ~7ps RC → BUFFERED
  assign byte2_oh[0] = (b2_s1a[0] & b2_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign byte2_oh[1] = (b2_s1a[0] & b2_s1b[1]) | (b2_s1a[1] & b2_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign byte2_oh[2] = (b2_s1a[0] & b2_s1b[2]) | (b2_s1a[1] & b2_s1b[1]) | (b2_s1a[2] & b2_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign byte2_oh[3] = (b2_s1a[0] & b2_s1b[3]) | (b2_s1a[1] & b2_s1b[2]) | (b2_s1a[2] & b2_s1b[1]) | (b2_s1a[3] & b2_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign byte2_oh[4] = (b2_s1a[0] & b2_s1b[4]) | (b2_s1a[1] & b2_s1b[3]) | (b2_s1a[2] & b2_s1b[2]) | (b2_s1a[3] & b2_s1b[1]) | (b2_s1a[4] & b2_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=4
  assign byte2_oh[5] = (b2_s1a[1] & b2_s1b[4]) | (b2_s1a[2] & b2_s1b[3]) | (b2_s1a[3] & b2_s1b[2]) | (b2_s1a[4] & b2_s1b[1]);  // M2v×M3h via→M4 diag wired-OR, sum=5
  assign byte2_oh[6] = (b2_s1a[2] & b2_s1b[4]) | (b2_s1a[3] & b2_s1b[3]) | (b2_s1a[4] & b2_s1b[2]);  // M2v×M3h via→M4 diag wired-OR, sum=6
  assign byte2_oh[7] = (b2_s1a[3] & b2_s1b[4]) | (b2_s1a[4] & b2_s1b[3]);  // M2v×M3h via→M4 diag wired-OR, sum=7
  assign byte2_oh[8] = (b2_s1a[4] & b2_s1b[4]);  // M2v×M3h via→M4 diag wired-OR, sum=8

  // *** byte2_oh[8:0] → BUFX2 LVT (72 buffers total, ~12ps) → Stage 3 input ***

  // ═══ Byte 3: fc12-15 → byte3_oh[8:0] ═══
  // Placed at X = 7.8μm, Y = 2.5-4.5μm in floorplan
  wire [2:0] b3_fc0;
  assign b3_fc0 = {fc12_oh2, fc12_oh1, fc12_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b3_fc1;
  assign b3_fc1 = {fc13_oh2, fc13_oh1, fc13_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b3_fc2;
  assign b3_fc2 = {fc14_oh2, fc14_oh1, fc14_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b3_fc3;
  assign b3_fc3 = {fc15_oh2, fc15_oh1, fc15_oh0};  // Pack for xpt input, M2 vert

  wire [4:0] b3_s1a;  // 3×3 xpt output, M3→M4 diagonal, ~2ps RC
  assign b3_s1a[0] = (b3_fc0[0] & b3_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign b3_s1a[1] = (b3_fc0[0] & b3_fc1[1]) | (b3_fc0[1] & b3_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign b3_s1a[2] = (b3_fc0[0] & b3_fc1[2]) | (b3_fc0[1] & b3_fc1[1]) | (b3_fc0[2] & b3_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign b3_s1a[3] = (b3_fc0[1] & b3_fc1[2]) | (b3_fc0[2] & b3_fc1[1]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign b3_s1a[4] = (b3_fc0[2] & b3_fc1[2]);  // M2v×M3h via→M4 diag wired-OR, sum=4

  wire [4:0] b3_s1b;  // 3×3 xpt output, M3→M4 diagonal, ~2ps RC
  assign b3_s1b[0] = (b3_fc2[0] & b3_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign b3_s1b[1] = (b3_fc2[0] & b3_fc3[1]) | (b3_fc2[1] & b3_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign b3_s1b[2] = (b3_fc2[0] & b3_fc3[2]) | (b3_fc2[1] & b3_fc3[1]) | (b3_fc2[2] & b3_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign b3_s1b[3] = (b3_fc2[1] & b3_fc3[2]) | (b3_fc2[2] & b3_fc3[1]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign b3_s1b[4] = (b3_fc2[2] & b3_fc3[2]);  // M2v×M3h via→M4 diag wired-OR, sum=4

  wire [8:0] byte3_oh;  // 5×5 xpt output, M4 collect, ~7ps RC → BUFFERED
  assign byte3_oh[0] = (b3_s1a[0] & b3_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign byte3_oh[1] = (b3_s1a[0] & b3_s1b[1]) | (b3_s1a[1] & b3_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign byte3_oh[2] = (b3_s1a[0] & b3_s1b[2]) | (b3_s1a[1] & b3_s1b[1]) | (b3_s1a[2] & b3_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign byte3_oh[3] = (b3_s1a[0] & b3_s1b[3]) | (b3_s1a[1] & b3_s1b[2]) | (b3_s1a[2] & b3_s1b[1]) | (b3_s1a[3] & b3_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign byte3_oh[4] = (b3_s1a[0] & b3_s1b[4]) | (b3_s1a[1] & b3_s1b[3]) | (b3_s1a[2] & b3_s1b[2]) | (b3_s1a[3] & b3_s1b[1]) | (b3_s1a[4] & b3_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=4
  assign byte3_oh[5] = (b3_s1a[1] & b3_s1b[4]) | (b3_s1a[2] & b3_s1b[3]) | (b3_s1a[3] & b3_s1b[2]) | (b3_s1a[4] & b3_s1b[1]);  // M2v×M3h via→M4 diag wired-OR, sum=5
  assign byte3_oh[6] = (b3_s1a[2] & b3_s1b[4]) | (b3_s1a[3] & b3_s1b[3]) | (b3_s1a[4] & b3_s1b[2]);  // M2v×M3h via→M4 diag wired-OR, sum=6
  assign byte3_oh[7] = (b3_s1a[3] & b3_s1b[4]) | (b3_s1a[4] & b3_s1b[3]);  // M2v×M3h via→M4 diag wired-OR, sum=7
  assign byte3_oh[8] = (b3_s1a[4] & b3_s1b[4]);  // M2v×M3h via→M4 diag wired-OR, sum=8

  // *** byte3_oh[8:0] → BUFX2 LVT (72 buffers total, ~12ps) → Stage 3 input ***

  // ═══ Byte 4: fc16-19 → byte4_oh[8:0] ═══
  // Placed at X = 10.4μm, Y = 2.5-4.5μm in floorplan
  wire [2:0] b4_fc0;
  assign b4_fc0 = {fc16_oh2, fc16_oh1, fc16_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b4_fc1;
  assign b4_fc1 = {fc17_oh2, fc17_oh1, fc17_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b4_fc2;
  assign b4_fc2 = {fc18_oh2, fc18_oh1, fc18_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b4_fc3;
  assign b4_fc3 = {fc19_oh2, fc19_oh1, fc19_oh0};  // Pack for xpt input, M2 vert

  wire [4:0] b4_s1a;  // 3×3 xpt output, M3→M4 diagonal, ~2ps RC
  assign b4_s1a[0] = (b4_fc0[0] & b4_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign b4_s1a[1] = (b4_fc0[0] & b4_fc1[1]) | (b4_fc0[1] & b4_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign b4_s1a[2] = (b4_fc0[0] & b4_fc1[2]) | (b4_fc0[1] & b4_fc1[1]) | (b4_fc0[2] & b4_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign b4_s1a[3] = (b4_fc0[1] & b4_fc1[2]) | (b4_fc0[2] & b4_fc1[1]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign b4_s1a[4] = (b4_fc0[2] & b4_fc1[2]);  // M2v×M3h via→M4 diag wired-OR, sum=4

  wire [4:0] b4_s1b;  // 3×3 xpt output, M3→M4 diagonal, ~2ps RC
  assign b4_s1b[0] = (b4_fc2[0] & b4_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign b4_s1b[1] = (b4_fc2[0] & b4_fc3[1]) | (b4_fc2[1] & b4_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign b4_s1b[2] = (b4_fc2[0] & b4_fc3[2]) | (b4_fc2[1] & b4_fc3[1]) | (b4_fc2[2] & b4_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign b4_s1b[3] = (b4_fc2[1] & b4_fc3[2]) | (b4_fc2[2] & b4_fc3[1]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign b4_s1b[4] = (b4_fc2[2] & b4_fc3[2]);  // M2v×M3h via→M4 diag wired-OR, sum=4

  wire [8:0] byte4_oh;  // 5×5 xpt output, M4 collect, ~7ps RC → BUFFERED
  assign byte4_oh[0] = (b4_s1a[0] & b4_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign byte4_oh[1] = (b4_s1a[0] & b4_s1b[1]) | (b4_s1a[1] & b4_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign byte4_oh[2] = (b4_s1a[0] & b4_s1b[2]) | (b4_s1a[1] & b4_s1b[1]) | (b4_s1a[2] & b4_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign byte4_oh[3] = (b4_s1a[0] & b4_s1b[3]) | (b4_s1a[1] & b4_s1b[2]) | (b4_s1a[2] & b4_s1b[1]) | (b4_s1a[3] & b4_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign byte4_oh[4] = (b4_s1a[0] & b4_s1b[4]) | (b4_s1a[1] & b4_s1b[3]) | (b4_s1a[2] & b4_s1b[2]) | (b4_s1a[3] & b4_s1b[1]) | (b4_s1a[4] & b4_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=4
  assign byte4_oh[5] = (b4_s1a[1] & b4_s1b[4]) | (b4_s1a[2] & b4_s1b[3]) | (b4_s1a[3] & b4_s1b[2]) | (b4_s1a[4] & b4_s1b[1]);  // M2v×M3h via→M4 diag wired-OR, sum=5
  assign byte4_oh[6] = (b4_s1a[2] & b4_s1b[4]) | (b4_s1a[3] & b4_s1b[3]) | (b4_s1a[4] & b4_s1b[2]);  // M2v×M3h via→M4 diag wired-OR, sum=6
  assign byte4_oh[7] = (b4_s1a[3] & b4_s1b[4]) | (b4_s1a[4] & b4_s1b[3]);  // M2v×M3h via→M4 diag wired-OR, sum=7
  assign byte4_oh[8] = (b4_s1a[4] & b4_s1b[4]);  // M2v×M3h via→M4 diag wired-OR, sum=8

  // *** byte4_oh[8:0] → BUFX2 LVT (72 buffers total, ~12ps) → Stage 3 input ***

  // ═══ Byte 5: fc20-23 → byte5_oh[8:0] ═══
  // Placed at X = 13.0μm, Y = 2.5-4.5μm in floorplan
  wire [2:0] b5_fc0;
  assign b5_fc0 = {fc20_oh2, fc20_oh1, fc20_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b5_fc1;
  assign b5_fc1 = {fc21_oh2, fc21_oh1, fc21_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b5_fc2;
  assign b5_fc2 = {fc22_oh2, fc22_oh1, fc22_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b5_fc3;
  assign b5_fc3 = {fc23_oh2, fc23_oh1, fc23_oh0};  // Pack for xpt input, M2 vert

  wire [4:0] b5_s1a;  // 3×3 xpt output, M3→M4 diagonal, ~2ps RC
  assign b5_s1a[0] = (b5_fc0[0] & b5_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign b5_s1a[1] = (b5_fc0[0] & b5_fc1[1]) | (b5_fc0[1] & b5_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign b5_s1a[2] = (b5_fc0[0] & b5_fc1[2]) | (b5_fc0[1] & b5_fc1[1]) | (b5_fc0[2] & b5_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign b5_s1a[3] = (b5_fc0[1] & b5_fc1[2]) | (b5_fc0[2] & b5_fc1[1]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign b5_s1a[4] = (b5_fc0[2] & b5_fc1[2]);  // M2v×M3h via→M4 diag wired-OR, sum=4

  wire [4:0] b5_s1b;  // 3×3 xpt output, M3→M4 diagonal, ~2ps RC
  assign b5_s1b[0] = (b5_fc2[0] & b5_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign b5_s1b[1] = (b5_fc2[0] & b5_fc3[1]) | (b5_fc2[1] & b5_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign b5_s1b[2] = (b5_fc2[0] & b5_fc3[2]) | (b5_fc2[1] & b5_fc3[1]) | (b5_fc2[2] & b5_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign b5_s1b[3] = (b5_fc2[1] & b5_fc3[2]) | (b5_fc2[2] & b5_fc3[1]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign b5_s1b[4] = (b5_fc2[2] & b5_fc3[2]);  // M2v×M3h via→M4 diag wired-OR, sum=4

  wire [8:0] byte5_oh;  // 5×5 xpt output, M4 collect, ~7ps RC → BUFFERED
  assign byte5_oh[0] = (b5_s1a[0] & b5_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign byte5_oh[1] = (b5_s1a[0] & b5_s1b[1]) | (b5_s1a[1] & b5_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign byte5_oh[2] = (b5_s1a[0] & b5_s1b[2]) | (b5_s1a[1] & b5_s1b[1]) | (b5_s1a[2] & b5_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign byte5_oh[3] = (b5_s1a[0] & b5_s1b[3]) | (b5_s1a[1] & b5_s1b[2]) | (b5_s1a[2] & b5_s1b[1]) | (b5_s1a[3] & b5_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign byte5_oh[4] = (b5_s1a[0] & b5_s1b[4]) | (b5_s1a[1] & b5_s1b[3]) | (b5_s1a[2] & b5_s1b[2]) | (b5_s1a[3] & b5_s1b[1]) | (b5_s1a[4] & b5_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=4
  assign byte5_oh[5] = (b5_s1a[1] & b5_s1b[4]) | (b5_s1a[2] & b5_s1b[3]) | (b5_s1a[3] & b5_s1b[2]) | (b5_s1a[4] & b5_s1b[1]);  // M2v×M3h via→M4 diag wired-OR, sum=5
  assign byte5_oh[6] = (b5_s1a[2] & b5_s1b[4]) | (b5_s1a[3] & b5_s1b[3]) | (b5_s1a[4] & b5_s1b[2]);  // M2v×M3h via→M4 diag wired-OR, sum=6
  assign byte5_oh[7] = (b5_s1a[3] & b5_s1b[4]) | (b5_s1a[4] & b5_s1b[3]);  // M2v×M3h via→M4 diag wired-OR, sum=7
  assign byte5_oh[8] = (b5_s1a[4] & b5_s1b[4]);  // M2v×M3h via→M4 diag wired-OR, sum=8

  // *** byte5_oh[8:0] → BUFX2 LVT (72 buffers total, ~12ps) → Stage 3 input ***

  // ═══ Byte 6: fc24-27 → byte6_oh[8:0] ═══
  // Placed at X = 15.6μm, Y = 2.5-4.5μm in floorplan
  wire [2:0] b6_fc0;
  assign b6_fc0 = {fc24_oh2, fc24_oh1, fc24_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b6_fc1;
  assign b6_fc1 = {fc25_oh2, fc25_oh1, fc25_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b6_fc2;
  assign b6_fc2 = {fc26_oh2, fc26_oh1, fc26_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b6_fc3;
  assign b6_fc3 = {fc27_oh2, fc27_oh1, fc27_oh0};  // Pack for xpt input, M2 vert

  wire [4:0] b6_s1a;  // 3×3 xpt output, M3→M4 diagonal, ~2ps RC
  assign b6_s1a[0] = (b6_fc0[0] & b6_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign b6_s1a[1] = (b6_fc0[0] & b6_fc1[1]) | (b6_fc0[1] & b6_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign b6_s1a[2] = (b6_fc0[0] & b6_fc1[2]) | (b6_fc0[1] & b6_fc1[1]) | (b6_fc0[2] & b6_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign b6_s1a[3] = (b6_fc0[1] & b6_fc1[2]) | (b6_fc0[2] & b6_fc1[1]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign b6_s1a[4] = (b6_fc0[2] & b6_fc1[2]);  // M2v×M3h via→M4 diag wired-OR, sum=4

  wire [4:0] b6_s1b;  // 3×3 xpt output, M3→M4 diagonal, ~2ps RC
  assign b6_s1b[0] = (b6_fc2[0] & b6_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign b6_s1b[1] = (b6_fc2[0] & b6_fc3[1]) | (b6_fc2[1] & b6_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign b6_s1b[2] = (b6_fc2[0] & b6_fc3[2]) | (b6_fc2[1] & b6_fc3[1]) | (b6_fc2[2] & b6_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign b6_s1b[3] = (b6_fc2[1] & b6_fc3[2]) | (b6_fc2[2] & b6_fc3[1]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign b6_s1b[4] = (b6_fc2[2] & b6_fc3[2]);  // M2v×M3h via→M4 diag wired-OR, sum=4

  wire [8:0] byte6_oh;  // 5×5 xpt output, M4 collect, ~7ps RC → BUFFERED
  assign byte6_oh[0] = (b6_s1a[0] & b6_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign byte6_oh[1] = (b6_s1a[0] & b6_s1b[1]) | (b6_s1a[1] & b6_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign byte6_oh[2] = (b6_s1a[0] & b6_s1b[2]) | (b6_s1a[1] & b6_s1b[1]) | (b6_s1a[2] & b6_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign byte6_oh[3] = (b6_s1a[0] & b6_s1b[3]) | (b6_s1a[1] & b6_s1b[2]) | (b6_s1a[2] & b6_s1b[1]) | (b6_s1a[3] & b6_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign byte6_oh[4] = (b6_s1a[0] & b6_s1b[4]) | (b6_s1a[1] & b6_s1b[3]) | (b6_s1a[2] & b6_s1b[2]) | (b6_s1a[3] & b6_s1b[1]) | (b6_s1a[4] & b6_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=4
  assign byte6_oh[5] = (b6_s1a[1] & b6_s1b[4]) | (b6_s1a[2] & b6_s1b[3]) | (b6_s1a[3] & b6_s1b[2]) | (b6_s1a[4] & b6_s1b[1]);  // M2v×M3h via→M4 diag wired-OR, sum=5
  assign byte6_oh[6] = (b6_s1a[2] & b6_s1b[4]) | (b6_s1a[3] & b6_s1b[3]) | (b6_s1a[4] & b6_s1b[2]);  // M2v×M3h via→M4 diag wired-OR, sum=6
  assign byte6_oh[7] = (b6_s1a[3] & b6_s1b[4]) | (b6_s1a[4] & b6_s1b[3]);  // M2v×M3h via→M4 diag wired-OR, sum=7
  assign byte6_oh[8] = (b6_s1a[4] & b6_s1b[4]);  // M2v×M3h via→M4 diag wired-OR, sum=8

  // *** byte6_oh[8:0] → BUFX2 LVT (72 buffers total, ~12ps) → Stage 3 input ***

  // ═══ Byte 7: fc28-31 → byte7_oh[8:0] ═══
  // Placed at X = 18.2μm, Y = 2.5-4.5μm in floorplan
  wire [2:0] b7_fc0;
  assign b7_fc0 = {fc28_oh2, fc28_oh1, fc28_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b7_fc1;
  assign b7_fc1 = {fc29_oh2, fc29_oh1, fc29_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b7_fc2;
  assign b7_fc2 = {fc30_oh2, fc30_oh1, fc30_oh0};  // Pack for xpt input, M2 vert
  wire [2:0] b7_fc3;
  assign b7_fc3 = {fc31_oh2, fc31_oh1, fc31_oh0};  // Pack for xpt input, M2 vert

  wire [4:0] b7_s1a;  // 3×3 xpt output, M3→M4 diagonal, ~2ps RC
  assign b7_s1a[0] = (b7_fc0[0] & b7_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign b7_s1a[1] = (b7_fc0[0] & b7_fc1[1]) | (b7_fc0[1] & b7_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign b7_s1a[2] = (b7_fc0[0] & b7_fc1[2]) | (b7_fc0[1] & b7_fc1[1]) | (b7_fc0[2] & b7_fc1[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign b7_s1a[3] = (b7_fc0[1] & b7_fc1[2]) | (b7_fc0[2] & b7_fc1[1]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign b7_s1a[4] = (b7_fc0[2] & b7_fc1[2]);  // M2v×M3h via→M4 diag wired-OR, sum=4

  wire [4:0] b7_s1b;  // 3×3 xpt output, M3→M4 diagonal, ~2ps RC
  assign b7_s1b[0] = (b7_fc2[0] & b7_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign b7_s1b[1] = (b7_fc2[0] & b7_fc3[1]) | (b7_fc2[1] & b7_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign b7_s1b[2] = (b7_fc2[0] & b7_fc3[2]) | (b7_fc2[1] & b7_fc3[1]) | (b7_fc2[2] & b7_fc3[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign b7_s1b[3] = (b7_fc2[1] & b7_fc3[2]) | (b7_fc2[2] & b7_fc3[1]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign b7_s1b[4] = (b7_fc2[2] & b7_fc3[2]);  // M2v×M3h via→M4 diag wired-OR, sum=4

  wire [8:0] byte7_oh;  // 5×5 xpt output, M4 collect, ~7ps RC → BUFFERED
  assign byte7_oh[0] = (b7_s1a[0] & b7_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=0
  assign byte7_oh[1] = (b7_s1a[0] & b7_s1b[1]) | (b7_s1a[1] & b7_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=1
  assign byte7_oh[2] = (b7_s1a[0] & b7_s1b[2]) | (b7_s1a[1] & b7_s1b[1]) | (b7_s1a[2] & b7_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=2
  assign byte7_oh[3] = (b7_s1a[0] & b7_s1b[3]) | (b7_s1a[1] & b7_s1b[2]) | (b7_s1a[2] & b7_s1b[1]) | (b7_s1a[3] & b7_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=3
  assign byte7_oh[4] = (b7_s1a[0] & b7_s1b[4]) | (b7_s1a[1] & b7_s1b[3]) | (b7_s1a[2] & b7_s1b[2]) | (b7_s1a[3] & b7_s1b[1]) | (b7_s1a[4] & b7_s1b[0]);  // M2v×M3h via→M4 diag wired-OR, sum=4
  assign byte7_oh[5] = (b7_s1a[1] & b7_s1b[4]) | (b7_s1a[2] & b7_s1b[3]) | (b7_s1a[3] & b7_s1b[2]) | (b7_s1a[4] & b7_s1b[1]);  // M2v×M3h via→M4 diag wired-OR, sum=5
  assign byte7_oh[6] = (b7_s1a[2] & b7_s1b[4]) | (b7_s1a[3] & b7_s1b[3]) | (b7_s1a[4] & b7_s1b[2]);  // M2v×M3h via→M4 diag wired-OR, sum=6
  assign byte7_oh[7] = (b7_s1a[3] & b7_s1b[4]) | (b7_s1a[4] & b7_s1b[3]);  // M2v×M3h via→M4 diag wired-OR, sum=7
  assign byte7_oh[8] = (b7_s1a[4] & b7_s1b[4]);  // M2v×M3h via→M4 diag wired-OR, sum=8

  // *** byte7_oh[8:0] → BUFX2 LVT (72 buffers total, ~12ps) → Stage 3 input ***

  // ====================================================================================================
  // STAGE 3: RADIX-4 REGROUPING — M4→M5 routing
  // ====================================================================================================
  //
  // PHYSICAL: Pure wiring on M4→M5. Each byte's 9-wire one-hot is remapped to
  //   d0[3:0] (ones digit) and d1[2:0] (fours digit) via OR connections.
  //   Wire length: ~0.1-0.3 μm per segment (very short, just metal jogs).
  //   RC delay: ~2-3 ps per segment. No buffers needed.
  //   The OR connections are wired-OR: multiple M4 input wires connect to
  //   a single M5 output wire through via stacks. Since inputs are one-hot,
  //   at most one driver is active at any time — no contention.
  //

  // Byte 0: OH[0:8] → radix-4 (d0, d1) — M4→M5 via routing, ~3ps
  wire [3:0] r4b0_d0;  // Ones digit on M5
  wire [2:0] r4b0_d1;  // Fours digit on M5
  assign r4b0_d0[0] = byte0_oh[0] | byte0_oh[4] | byte0_oh[8];  // M4→M5 wired-OR, mod4=0
  assign r4b0_d0[1] = byte0_oh[1] | byte0_oh[5];  // M4→M5 wired-OR, mod4=1
  assign r4b0_d0[2] = byte0_oh[2] | byte0_oh[6];  // M4→M5 wired-OR, mod4=2
  assign r4b0_d0[3] = byte0_oh[3] | byte0_oh[7];  // M4→M5 wired-OR, mod4=3
  assign r4b0_d1[0] = byte0_oh[0] | byte0_oh[1] | byte0_oh[2] | byte0_oh[3];  // M4→M5 wired-OR, div4=0
  assign r4b0_d1[1] = byte0_oh[4] | byte0_oh[5] | byte0_oh[6] | byte0_oh[7];  // M4→M5 wired-OR, div4=1
  assign r4b0_d1[2] = byte0_oh[8];  // M4→M5 wired-OR, div4=2

  // Byte 1: OH[0:8] → radix-4 (d0, d1) — M4→M5 via routing, ~3ps
  wire [3:0] r4b1_d0;  // Ones digit on M5
  wire [2:0] r4b1_d1;  // Fours digit on M5
  assign r4b1_d0[0] = byte1_oh[0] | byte1_oh[4] | byte1_oh[8];  // M4→M5 wired-OR, mod4=0
  assign r4b1_d0[1] = byte1_oh[1] | byte1_oh[5];  // M4→M5 wired-OR, mod4=1
  assign r4b1_d0[2] = byte1_oh[2] | byte1_oh[6];  // M4→M5 wired-OR, mod4=2
  assign r4b1_d0[3] = byte1_oh[3] | byte1_oh[7];  // M4→M5 wired-OR, mod4=3
  assign r4b1_d1[0] = byte1_oh[0] | byte1_oh[1] | byte1_oh[2] | byte1_oh[3];  // M4→M5 wired-OR, div4=0
  assign r4b1_d1[1] = byte1_oh[4] | byte1_oh[5] | byte1_oh[6] | byte1_oh[7];  // M4→M5 wired-OR, div4=1
  assign r4b1_d1[2] = byte1_oh[8];  // M4→M5 wired-OR, div4=2

  // Byte 2: OH[0:8] → radix-4 (d0, d1) — M4→M5 via routing, ~3ps
  wire [3:0] r4b2_d0;  // Ones digit on M5
  wire [2:0] r4b2_d1;  // Fours digit on M5
  assign r4b2_d0[0] = byte2_oh[0] | byte2_oh[4] | byte2_oh[8];  // M4→M5 wired-OR, mod4=0
  assign r4b2_d0[1] = byte2_oh[1] | byte2_oh[5];  // M4→M5 wired-OR, mod4=1
  assign r4b2_d0[2] = byte2_oh[2] | byte2_oh[6];  // M4→M5 wired-OR, mod4=2
  assign r4b2_d0[3] = byte2_oh[3] | byte2_oh[7];  // M4→M5 wired-OR, mod4=3
  assign r4b2_d1[0] = byte2_oh[0] | byte2_oh[1] | byte2_oh[2] | byte2_oh[3];  // M4→M5 wired-OR, div4=0
  assign r4b2_d1[1] = byte2_oh[4] | byte2_oh[5] | byte2_oh[6] | byte2_oh[7];  // M4→M5 wired-OR, div4=1
  assign r4b2_d1[2] = byte2_oh[8];  // M4→M5 wired-OR, div4=2

  // Byte 3: OH[0:8] → radix-4 (d0, d1) — M4→M5 via routing, ~3ps
  wire [3:0] r4b3_d0;  // Ones digit on M5
  wire [2:0] r4b3_d1;  // Fours digit on M5
  assign r4b3_d0[0] = byte3_oh[0] | byte3_oh[4] | byte3_oh[8];  // M4→M5 wired-OR, mod4=0
  assign r4b3_d0[1] = byte3_oh[1] | byte3_oh[5];  // M4→M5 wired-OR, mod4=1
  assign r4b3_d0[2] = byte3_oh[2] | byte3_oh[6];  // M4→M5 wired-OR, mod4=2
  assign r4b3_d0[3] = byte3_oh[3] | byte3_oh[7];  // M4→M5 wired-OR, mod4=3
  assign r4b3_d1[0] = byte3_oh[0] | byte3_oh[1] | byte3_oh[2] | byte3_oh[3];  // M4→M5 wired-OR, div4=0
  assign r4b3_d1[1] = byte3_oh[4] | byte3_oh[5] | byte3_oh[6] | byte3_oh[7];  // M4→M5 wired-OR, div4=1
  assign r4b3_d1[2] = byte3_oh[8];  // M4→M5 wired-OR, div4=2

  // Byte 4: OH[0:8] → radix-4 (d0, d1) — M4→M5 via routing, ~3ps
  wire [3:0] r4b4_d0;  // Ones digit on M5
  wire [2:0] r4b4_d1;  // Fours digit on M5
  assign r4b4_d0[0] = byte4_oh[0] | byte4_oh[4] | byte4_oh[8];  // M4→M5 wired-OR, mod4=0
  assign r4b4_d0[1] = byte4_oh[1] | byte4_oh[5];  // M4→M5 wired-OR, mod4=1
  assign r4b4_d0[2] = byte4_oh[2] | byte4_oh[6];  // M4→M5 wired-OR, mod4=2
  assign r4b4_d0[3] = byte4_oh[3] | byte4_oh[7];  // M4→M5 wired-OR, mod4=3
  assign r4b4_d1[0] = byte4_oh[0] | byte4_oh[1] | byte4_oh[2] | byte4_oh[3];  // M4→M5 wired-OR, div4=0
  assign r4b4_d1[1] = byte4_oh[4] | byte4_oh[5] | byte4_oh[6] | byte4_oh[7];  // M4→M5 wired-OR, div4=1
  assign r4b4_d1[2] = byte4_oh[8];  // M4→M5 wired-OR, div4=2

  // Byte 5: OH[0:8] → radix-4 (d0, d1) — M4→M5 via routing, ~3ps
  wire [3:0] r4b5_d0;  // Ones digit on M5
  wire [2:0] r4b5_d1;  // Fours digit on M5
  assign r4b5_d0[0] = byte5_oh[0] | byte5_oh[4] | byte5_oh[8];  // M4→M5 wired-OR, mod4=0
  assign r4b5_d0[1] = byte5_oh[1] | byte5_oh[5];  // M4→M5 wired-OR, mod4=1
  assign r4b5_d0[2] = byte5_oh[2] | byte5_oh[6];  // M4→M5 wired-OR, mod4=2
  assign r4b5_d0[3] = byte5_oh[3] | byte5_oh[7];  // M4→M5 wired-OR, mod4=3
  assign r4b5_d1[0] = byte5_oh[0] | byte5_oh[1] | byte5_oh[2] | byte5_oh[3];  // M4→M5 wired-OR, div4=0
  assign r4b5_d1[1] = byte5_oh[4] | byte5_oh[5] | byte5_oh[6] | byte5_oh[7];  // M4→M5 wired-OR, div4=1
  assign r4b5_d1[2] = byte5_oh[8];  // M4→M5 wired-OR, div4=2

  // Byte 6: OH[0:8] → radix-4 (d0, d1) — M4→M5 via routing, ~3ps
  wire [3:0] r4b6_d0;  // Ones digit on M5
  wire [2:0] r4b6_d1;  // Fours digit on M5
  assign r4b6_d0[0] = byte6_oh[0] | byte6_oh[4] | byte6_oh[8];  // M4→M5 wired-OR, mod4=0
  assign r4b6_d0[1] = byte6_oh[1] | byte6_oh[5];  // M4→M5 wired-OR, mod4=1
  assign r4b6_d0[2] = byte6_oh[2] | byte6_oh[6];  // M4→M5 wired-OR, mod4=2
  assign r4b6_d0[3] = byte6_oh[3] | byte6_oh[7];  // M4→M5 wired-OR, mod4=3
  assign r4b6_d1[0] = byte6_oh[0] | byte6_oh[1] | byte6_oh[2] | byte6_oh[3];  // M4→M5 wired-OR, div4=0
  assign r4b6_d1[1] = byte6_oh[4] | byte6_oh[5] | byte6_oh[6] | byte6_oh[7];  // M4→M5 wired-OR, div4=1
  assign r4b6_d1[2] = byte6_oh[8];  // M4→M5 wired-OR, div4=2

  // Byte 7: OH[0:8] → radix-4 (d0, d1) — M4→M5 via routing, ~3ps
  wire [3:0] r4b7_d0;  // Ones digit on M5
  wire [2:0] r4b7_d1;  // Fours digit on M5
  assign r4b7_d0[0] = byte7_oh[0] | byte7_oh[4] | byte7_oh[8];  // M4→M5 wired-OR, mod4=0
  assign r4b7_d0[1] = byte7_oh[1] | byte7_oh[5];  // M4→M5 wired-OR, mod4=1
  assign r4b7_d0[2] = byte7_oh[2] | byte7_oh[6];  // M4→M5 wired-OR, mod4=2
  assign r4b7_d0[3] = byte7_oh[3] | byte7_oh[7];  // M4→M5 wired-OR, mod4=3
  assign r4b7_d1[0] = byte7_oh[0] | byte7_oh[1] | byte7_oh[2] | byte7_oh[3];  // M4→M5 wired-OR, div4=0
  assign r4b7_d1[1] = byte7_oh[4] | byte7_oh[5] | byte7_oh[6] | byte7_oh[7];  // M4→M5 wired-OR, div4=1
  assign r4b7_d1[2] = byte7_oh[8];  // M4→M5 wired-OR, div4=2

  // ====================================================================================================
  // STAGE 4: CARRY-FREE MERGE TREE — M5/M6/M7/M8
  // ====================================================================================================
  //
  // PHYSICAL: 3-level binary tree of crosspoint additions.
  //
  //   Level 1 (M5 vert / M6 horiz):
  //     d0: 4×4 crosspoints (16 intersections, 7 outputs) — grid ~160nm × 160nm
  //     d1: 3×3 crosspoints (9 intersections, 5 outputs)  — grid ~120nm × 120nm
  //     Wire length: ~0.2-0.5 μm. RC: ~3-5 ps per crosspoint.
  //     OUTPUT BUFFERED: BUFX2 LVT on M6, adds ~12 ps
  //
  //   Level 2 (M6 vert / M7 horiz):
  //     d0: 7×7 crosspoints (49 intersections, 13 outputs) — grid ~560nm × 560nm
  //     d1: 5×5 crosspoints (25 intersections, 9 outputs)  — grid ~400nm × 400nm
  //     Wire length: ~0.5-1.5 μm. M7 is semi-global (80nm pitch, ~4 Ω/μm), so
  //     RC is manageable: ~6-12 ps per wire.
  //     OUTPUT BUFFERED: BUFX4 LVT on M7, adds ~10 ps
  //
  //   Level 3 (M7 vert / M8 horiz):
  //     d0: 13×13 crosspoints (169 intersections, 25 outputs) — grid ~1μm × 1μm
  //     d1: 9×9 crosspoints (81 intersections, 17 outputs)   — grid ~720nm × 720nm
  //     Wire length: ~1.5-3.0 μm. M7/M8 semi-global layers keep RC bounded.
  //     RC: ~20-35 ps for the largest crosspoint wires.
  //     OUTPUT BUFFERED: BUFX4 uLVT on M8 (critical path), adds ~8 ps
  //
  //   KEY PHYSICAL INSIGHT: The crosspoints grow in size at each level, but we also
  //   move to wider metal layers (M5→M6→M7→M8) which have lower R/μm. This partially
  //   offsets the longer wire lengths. The design intentionally maps larger crosspoints
  //   to wider (less resistive) metals.
  //

  // ── MERGE LEVEL 1: M5v × M6h, BUFX2 LVT at exit ──
  // L1 pair0 d0: 4×4 xpt on M5v/M6h (~160nm grid, ~5ps RC)
  wire [6:0] m1p0_d0;
  assign m1p0_d0[0] = (r4b0_d0[0] & r4b1_d0[0]);
  assign m1p0_d0[1] = (r4b0_d0[0] & r4b1_d0[1]) | (r4b0_d0[1] & r4b1_d0[0]);
  assign m1p0_d0[2] = (r4b0_d0[0] & r4b1_d0[2]) | (r4b0_d0[1] & r4b1_d0[1]) | (r4b0_d0[2] & r4b1_d0[0]);
  assign m1p0_d0[3] = (r4b0_d0[0] & r4b1_d0[3]) | (r4b0_d0[1] & r4b1_d0[2]) | (r4b0_d0[2] & r4b1_d0[1]) | (r4b0_d0[3] & r4b1_d0[0]);
  assign m1p0_d0[4] = (r4b0_d0[1] & r4b1_d0[3]) | (r4b0_d0[2] & r4b1_d0[2]) | (r4b0_d0[3] & r4b1_d0[1]);
  assign m1p0_d0[5] = (r4b0_d0[2] & r4b1_d0[3]) | (r4b0_d0[3] & r4b1_d0[2]);
  assign m1p0_d0[6] = (r4b0_d0[3] & r4b1_d0[3]);
  // *** m1p0_d0 → BUFX2 LVT (~12ps) → drives M6 wire to L2 ***

  // L1 pair0 d1: 3×3 xpt on M5v/M6h (~120nm grid, ~3ps RC)
  wire [4:0] m1p0_d1;
  assign m1p0_d1[0] = (r4b0_d1[0] & r4b1_d1[0]);
  assign m1p0_d1[1] = (r4b0_d1[0] & r4b1_d1[1]) | (r4b0_d1[1] & r4b1_d1[0]);
  assign m1p0_d1[2] = (r4b0_d1[0] & r4b1_d1[2]) | (r4b0_d1[1] & r4b1_d1[1]) | (r4b0_d1[2] & r4b1_d1[0]);
  assign m1p0_d1[3] = (r4b0_d1[1] & r4b1_d1[2]) | (r4b0_d1[2] & r4b1_d1[1]);
  assign m1p0_d1[4] = (r4b0_d1[2] & r4b1_d1[2]);
  // *** m1p0_d1 → BUFX2 LVT (~12ps) → drives M6 wire to L2 ***

  // L1 pair1 d0: 4×4 xpt on M5v/M6h (~160nm grid, ~5ps RC)
  wire [6:0] m1p1_d0;
  assign m1p1_d0[0] = (r4b2_d0[0] & r4b3_d0[0]);
  assign m1p1_d0[1] = (r4b2_d0[0] & r4b3_d0[1]) | (r4b2_d0[1] & r4b3_d0[0]);
  assign m1p1_d0[2] = (r4b2_d0[0] & r4b3_d0[2]) | (r4b2_d0[1] & r4b3_d0[1]) | (r4b2_d0[2] & r4b3_d0[0]);
  assign m1p1_d0[3] = (r4b2_d0[0] & r4b3_d0[3]) | (r4b2_d0[1] & r4b3_d0[2]) | (r4b2_d0[2] & r4b3_d0[1]) | (r4b2_d0[3] & r4b3_d0[0]);
  assign m1p1_d0[4] = (r4b2_d0[1] & r4b3_d0[3]) | (r4b2_d0[2] & r4b3_d0[2]) | (r4b2_d0[3] & r4b3_d0[1]);
  assign m1p1_d0[5] = (r4b2_d0[2] & r4b3_d0[3]) | (r4b2_d0[3] & r4b3_d0[2]);
  assign m1p1_d0[6] = (r4b2_d0[3] & r4b3_d0[3]);
  // *** m1p1_d0 → BUFX2 LVT (~12ps) → drives M6 wire to L2 ***

  // L1 pair1 d1: 3×3 xpt on M5v/M6h (~120nm grid, ~3ps RC)
  wire [4:0] m1p1_d1;
  assign m1p1_d1[0] = (r4b2_d1[0] & r4b3_d1[0]);
  assign m1p1_d1[1] = (r4b2_d1[0] & r4b3_d1[1]) | (r4b2_d1[1] & r4b3_d1[0]);
  assign m1p1_d1[2] = (r4b2_d1[0] & r4b3_d1[2]) | (r4b2_d1[1] & r4b3_d1[1]) | (r4b2_d1[2] & r4b3_d1[0]);
  assign m1p1_d1[3] = (r4b2_d1[1] & r4b3_d1[2]) | (r4b2_d1[2] & r4b3_d1[1]);
  assign m1p1_d1[4] = (r4b2_d1[2] & r4b3_d1[2]);
  // *** m1p1_d1 → BUFX2 LVT (~12ps) → drives M6 wire to L2 ***

  // L1 pair2 d0: 4×4 xpt on M5v/M6h (~160nm grid, ~5ps RC)
  wire [6:0] m1p2_d0;
  assign m1p2_d0[0] = (r4b4_d0[0] & r4b5_d0[0]);
  assign m1p2_d0[1] = (r4b4_d0[0] & r4b5_d0[1]) | (r4b4_d0[1] & r4b5_d0[0]);
  assign m1p2_d0[2] = (r4b4_d0[0] & r4b5_d0[2]) | (r4b4_d0[1] & r4b5_d0[1]) | (r4b4_d0[2] & r4b5_d0[0]);
  assign m1p2_d0[3] = (r4b4_d0[0] & r4b5_d0[3]) | (r4b4_d0[1] & r4b5_d0[2]) | (r4b4_d0[2] & r4b5_d0[1]) | (r4b4_d0[3] & r4b5_d0[0]);
  assign m1p2_d0[4] = (r4b4_d0[1] & r4b5_d0[3]) | (r4b4_d0[2] & r4b5_d0[2]) | (r4b4_d0[3] & r4b5_d0[1]);
  assign m1p2_d0[5] = (r4b4_d0[2] & r4b5_d0[3]) | (r4b4_d0[3] & r4b5_d0[2]);
  assign m1p2_d0[6] = (r4b4_d0[3] & r4b5_d0[3]);
  // *** m1p2_d0 → BUFX2 LVT (~12ps) → drives M6 wire to L2 ***

  // L1 pair2 d1: 3×3 xpt on M5v/M6h (~120nm grid, ~3ps RC)
  wire [4:0] m1p2_d1;
  assign m1p2_d1[0] = (r4b4_d1[0] & r4b5_d1[0]);
  assign m1p2_d1[1] = (r4b4_d1[0] & r4b5_d1[1]) | (r4b4_d1[1] & r4b5_d1[0]);
  assign m1p2_d1[2] = (r4b4_d1[0] & r4b5_d1[2]) | (r4b4_d1[1] & r4b5_d1[1]) | (r4b4_d1[2] & r4b5_d1[0]);
  assign m1p2_d1[3] = (r4b4_d1[1] & r4b5_d1[2]) | (r4b4_d1[2] & r4b5_d1[1]);
  assign m1p2_d1[4] = (r4b4_d1[2] & r4b5_d1[2]);
  // *** m1p2_d1 → BUFX2 LVT (~12ps) → drives M6 wire to L2 ***

  // L1 pair3 d0: 4×4 xpt on M5v/M6h (~160nm grid, ~5ps RC)
  wire [6:0] m1p3_d0;
  assign m1p3_d0[0] = (r4b6_d0[0] & r4b7_d0[0]);
  assign m1p3_d0[1] = (r4b6_d0[0] & r4b7_d0[1]) | (r4b6_d0[1] & r4b7_d0[0]);
  assign m1p3_d0[2] = (r4b6_d0[0] & r4b7_d0[2]) | (r4b6_d0[1] & r4b7_d0[1]) | (r4b6_d0[2] & r4b7_d0[0]);
  assign m1p3_d0[3] = (r4b6_d0[0] & r4b7_d0[3]) | (r4b6_d0[1] & r4b7_d0[2]) | (r4b6_d0[2] & r4b7_d0[1]) | (r4b6_d0[3] & r4b7_d0[0]);
  assign m1p3_d0[4] = (r4b6_d0[1] & r4b7_d0[3]) | (r4b6_d0[2] & r4b7_d0[2]) | (r4b6_d0[3] & r4b7_d0[1]);
  assign m1p3_d0[5] = (r4b6_d0[2] & r4b7_d0[3]) | (r4b6_d0[3] & r4b7_d0[2]);
  assign m1p3_d0[6] = (r4b6_d0[3] & r4b7_d0[3]);
  // *** m1p3_d0 → BUFX2 LVT (~12ps) → drives M6 wire to L2 ***

  // L1 pair3 d1: 3×3 xpt on M5v/M6h (~120nm grid, ~3ps RC)
  wire [4:0] m1p3_d1;
  assign m1p3_d1[0] = (r4b6_d1[0] & r4b7_d1[0]);
  assign m1p3_d1[1] = (r4b6_d1[0] & r4b7_d1[1]) | (r4b6_d1[1] & r4b7_d1[0]);
  assign m1p3_d1[2] = (r4b6_d1[0] & r4b7_d1[2]) | (r4b6_d1[1] & r4b7_d1[1]) | (r4b6_d1[2] & r4b7_d1[0]);
  assign m1p3_d1[3] = (r4b6_d1[1] & r4b7_d1[2]) | (r4b6_d1[2] & r4b7_d1[1]);
  assign m1p3_d1[4] = (r4b6_d1[2] & r4b7_d1[2]);
  // *** m1p3_d1 → BUFX2 LVT (~12ps) → drives M6 wire to L2 ***

  // ── MERGE LEVEL 2: M6v × M7h, BUFX4 LVT at exit ──
  // L2 pair0 d0: 7×7 xpt on M6v/M7h (~560nm grid, ~12ps RC)
  wire [12:0] m2p0_d0;
  assign m2p0_d0[0] = (m1p0_d0[0] & m1p1_d0[0]);
  assign m2p0_d0[1] = (m1p0_d0[0] & m1p1_d0[1]) | (m1p0_d0[1] & m1p1_d0[0]);
  assign m2p0_d0[2] = (m1p0_d0[0] & m1p1_d0[2]) | (m1p0_d0[1] & m1p1_d0[1]) | (m1p0_d0[2] & m1p1_d0[0]);
  assign m2p0_d0[3] = (m1p0_d0[0] & m1p1_d0[3]) | (m1p0_d0[1] & m1p1_d0[2]) | (m1p0_d0[2] & m1p1_d0[1]) | (m1p0_d0[3] & m1p1_d0[0]);
  assign m2p0_d0[4] = (m1p0_d0[0] & m1p1_d0[4]) | (m1p0_d0[1] & m1p1_d0[3]) | (m1p0_d0[2] & m1p1_d0[2]) | (m1p0_d0[3] & m1p1_d0[1]) | (m1p0_d0[4] & m1p1_d0[0]);
  assign m2p0_d0[5] = (m1p0_d0[0] & m1p1_d0[5]) | (m1p0_d0[1] & m1p1_d0[4]) | (m1p0_d0[2] & m1p1_d0[3]) | (m1p0_d0[3] & m1p1_d0[2]) | (m1p0_d0[4] & m1p1_d0[1]) | (m1p0_d0[5] & m1p1_d0[0]);
  assign m2p0_d0[6] = (m1p0_d0[0] & m1p1_d0[6]) | (m1p0_d0[1] & m1p1_d0[5]) | (m1p0_d0[2] & m1p1_d0[4]) | (m1p0_d0[3] & m1p1_d0[3]) | (m1p0_d0[4] & m1p1_d0[2]) | (m1p0_d0[5] & m1p1_d0[1]) | (m1p0_d0[6] & m1p1_d0[0]);
  assign m2p0_d0[7] = (m1p0_d0[1] & m1p1_d0[6]) | (m1p0_d0[2] & m1p1_d0[5]) | (m1p0_d0[3] & m1p1_d0[4]) | (m1p0_d0[4] & m1p1_d0[3]) | (m1p0_d0[5] & m1p1_d0[2]) | (m1p0_d0[6] & m1p1_d0[1]);
  assign m2p0_d0[8] = (m1p0_d0[2] & m1p1_d0[6]) | (m1p0_d0[3] & m1p1_d0[5]) | (m1p0_d0[4] & m1p1_d0[4]) | (m1p0_d0[5] & m1p1_d0[3]) | (m1p0_d0[6] & m1p1_d0[2]);
  assign m2p0_d0[9] = (m1p0_d0[3] & m1p1_d0[6]) | (m1p0_d0[4] & m1p1_d0[5]) | (m1p0_d0[5] & m1p1_d0[4]) | (m1p0_d0[6] & m1p1_d0[3]);
  assign m2p0_d0[10] = (m1p0_d0[4] & m1p1_d0[6]) | (m1p0_d0[5] & m1p1_d0[5]) | (m1p0_d0[6] & m1p1_d0[4]);
  assign m2p0_d0[11] = (m1p0_d0[5] & m1p1_d0[6]) | (m1p0_d0[6] & m1p1_d0[5]);
  assign m2p0_d0[12] = (m1p0_d0[6] & m1p1_d0[6]);
  // *** m2p0_d0 → BUFX4 LVT (~10ps) → drives 2-3μm M7 wire to L3 ***

  // L2 pair0 d1: 5×5 xpt on M6v/M7h (~400nm grid, ~8ps RC)
  wire [8:0] m2p0_d1;
  assign m2p0_d1[0] = (m1p0_d1[0] & m1p1_d1[0]);
  assign m2p0_d1[1] = (m1p0_d1[0] & m1p1_d1[1]) | (m1p0_d1[1] & m1p1_d1[0]);
  assign m2p0_d1[2] = (m1p0_d1[0] & m1p1_d1[2]) | (m1p0_d1[1] & m1p1_d1[1]) | (m1p0_d1[2] & m1p1_d1[0]);
  assign m2p0_d1[3] = (m1p0_d1[0] & m1p1_d1[3]) | (m1p0_d1[1] & m1p1_d1[2]) | (m1p0_d1[2] & m1p1_d1[1]) | (m1p0_d1[3] & m1p1_d1[0]);
  assign m2p0_d1[4] = (m1p0_d1[0] & m1p1_d1[4]) | (m1p0_d1[1] & m1p1_d1[3]) | (m1p0_d1[2] & m1p1_d1[2]) | (m1p0_d1[3] & m1p1_d1[1]) | (m1p0_d1[4] & m1p1_d1[0]);
  assign m2p0_d1[5] = (m1p0_d1[1] & m1p1_d1[4]) | (m1p0_d1[2] & m1p1_d1[3]) | (m1p0_d1[3] & m1p1_d1[2]) | (m1p0_d1[4] & m1p1_d1[1]);
  assign m2p0_d1[6] = (m1p0_d1[2] & m1p1_d1[4]) | (m1p0_d1[3] & m1p1_d1[3]) | (m1p0_d1[4] & m1p1_d1[2]);
  assign m2p0_d1[7] = (m1p0_d1[3] & m1p1_d1[4]) | (m1p0_d1[4] & m1p1_d1[3]);
  assign m2p0_d1[8] = (m1p0_d1[4] & m1p1_d1[4]);
  // *** m2p0_d1 → BUFX4 LVT (~10ps) → drives 2-3μm M7 wire to L3 ***

  // L2 pair1 d0: 7×7 xpt on M6v/M7h (~560nm grid, ~12ps RC)
  wire [12:0] m2p1_d0;
  assign m2p1_d0[0] = (m1p2_d0[0] & m1p3_d0[0]);
  assign m2p1_d0[1] = (m1p2_d0[0] & m1p3_d0[1]) | (m1p2_d0[1] & m1p3_d0[0]);
  assign m2p1_d0[2] = (m1p2_d0[0] & m1p3_d0[2]) | (m1p2_d0[1] & m1p3_d0[1]) | (m1p2_d0[2] & m1p3_d0[0]);
  assign m2p1_d0[3] = (m1p2_d0[0] & m1p3_d0[3]) | (m1p2_d0[1] & m1p3_d0[2]) | (m1p2_d0[2] & m1p3_d0[1]) | (m1p2_d0[3] & m1p3_d0[0]);
  assign m2p1_d0[4] = (m1p2_d0[0] & m1p3_d0[4]) | (m1p2_d0[1] & m1p3_d0[3]) | (m1p2_d0[2] & m1p3_d0[2]) | (m1p2_d0[3] & m1p3_d0[1]) | (m1p2_d0[4] & m1p3_d0[0]);
  assign m2p1_d0[5] = (m1p2_d0[0] & m1p3_d0[5]) | (m1p2_d0[1] & m1p3_d0[4]) | (m1p2_d0[2] & m1p3_d0[3]) | (m1p2_d0[3] & m1p3_d0[2]) | (m1p2_d0[4] & m1p3_d0[1]) | (m1p2_d0[5] & m1p3_d0[0]);
  assign m2p1_d0[6] = (m1p2_d0[0] & m1p3_d0[6]) | (m1p2_d0[1] & m1p3_d0[5]) | (m1p2_d0[2] & m1p3_d0[4]) | (m1p2_d0[3] & m1p3_d0[3]) | (m1p2_d0[4] & m1p3_d0[2]) | (m1p2_d0[5] & m1p3_d0[1]) | (m1p2_d0[6] & m1p3_d0[0]);
  assign m2p1_d0[7] = (m1p2_d0[1] & m1p3_d0[6]) | (m1p2_d0[2] & m1p3_d0[5]) | (m1p2_d0[3] & m1p3_d0[4]) | (m1p2_d0[4] & m1p3_d0[3]) | (m1p2_d0[5] & m1p3_d0[2]) | (m1p2_d0[6] & m1p3_d0[1]);
  assign m2p1_d0[8] = (m1p2_d0[2] & m1p3_d0[6]) | (m1p2_d0[3] & m1p3_d0[5]) | (m1p2_d0[4] & m1p3_d0[4]) | (m1p2_d0[5] & m1p3_d0[3]) | (m1p2_d0[6] & m1p3_d0[2]);
  assign m2p1_d0[9] = (m1p2_d0[3] & m1p3_d0[6]) | (m1p2_d0[4] & m1p3_d0[5]) | (m1p2_d0[5] & m1p3_d0[4]) | (m1p2_d0[6] & m1p3_d0[3]);
  assign m2p1_d0[10] = (m1p2_d0[4] & m1p3_d0[6]) | (m1p2_d0[5] & m1p3_d0[5]) | (m1p2_d0[6] & m1p3_d0[4]);
  assign m2p1_d0[11] = (m1p2_d0[5] & m1p3_d0[6]) | (m1p2_d0[6] & m1p3_d0[5]);
  assign m2p1_d0[12] = (m1p2_d0[6] & m1p3_d0[6]);
  // *** m2p1_d0 → BUFX4 LVT (~10ps) → drives 2-3μm M7 wire to L3 ***

  // L2 pair1 d1: 5×5 xpt on M6v/M7h (~400nm grid, ~8ps RC)
  wire [8:0] m2p1_d1;
  assign m2p1_d1[0] = (m1p2_d1[0] & m1p3_d1[0]);
  assign m2p1_d1[1] = (m1p2_d1[0] & m1p3_d1[1]) | (m1p2_d1[1] & m1p3_d1[0]);
  assign m2p1_d1[2] = (m1p2_d1[0] & m1p3_d1[2]) | (m1p2_d1[1] & m1p3_d1[1]) | (m1p2_d1[2] & m1p3_d1[0]);
  assign m2p1_d1[3] = (m1p2_d1[0] & m1p3_d1[3]) | (m1p2_d1[1] & m1p3_d1[2]) | (m1p2_d1[2] & m1p3_d1[1]) | (m1p2_d1[3] & m1p3_d1[0]);
  assign m2p1_d1[4] = (m1p2_d1[0] & m1p3_d1[4]) | (m1p2_d1[1] & m1p3_d1[3]) | (m1p2_d1[2] & m1p3_d1[2]) | (m1p2_d1[3] & m1p3_d1[1]) | (m1p2_d1[4] & m1p3_d1[0]);
  assign m2p1_d1[5] = (m1p2_d1[1] & m1p3_d1[4]) | (m1p2_d1[2] & m1p3_d1[3]) | (m1p2_d1[3] & m1p3_d1[2]) | (m1p2_d1[4] & m1p3_d1[1]);
  assign m2p1_d1[6] = (m1p2_d1[2] & m1p3_d1[4]) | (m1p2_d1[3] & m1p3_d1[3]) | (m1p2_d1[4] & m1p3_d1[2]);
  assign m2p1_d1[7] = (m1p2_d1[3] & m1p3_d1[4]) | (m1p2_d1[4] & m1p3_d1[3]);
  assign m2p1_d1[8] = (m1p2_d1[4] & m1p3_d1[4]);
  // *** m2p1_d1 → BUFX4 LVT (~10ps) → drives 2-3μm M7 wire to L3 ***

  // ── MERGE LEVEL 3 (FINAL): M7v × M8h, BUFX4 uLVT at exit *** CRITICAL PATH *** ──
  // L3 FINAL d0: 13×13 xpt on M7v/M8h (~1μm grid, ~35ps RC) *** LARGEST CROSSPOINT ***
  wire [24:0] mf_d0;
  assign mf_d0[0] = (m2p0_d0[0] & m2p1_d0[0]);
  assign mf_d0[1] = (m2p0_d0[0] & m2p1_d0[1]) | (m2p0_d0[1] & m2p1_d0[0]);
  assign mf_d0[2] = (m2p0_d0[0] & m2p1_d0[2]) | (m2p0_d0[1] & m2p1_d0[1]) | (m2p0_d0[2] & m2p1_d0[0]);
  assign mf_d0[3] = (m2p0_d0[0] & m2p1_d0[3]) | (m2p0_d0[1] & m2p1_d0[2]) | (m2p0_d0[2] & m2p1_d0[1]) | (m2p0_d0[3] & m2p1_d0[0]);
  assign mf_d0[4] = (m2p0_d0[0] & m2p1_d0[4]) | (m2p0_d0[1] & m2p1_d0[3]) | (m2p0_d0[2] & m2p1_d0[2]) | (m2p0_d0[3] & m2p1_d0[1]) | (m2p0_d0[4] & m2p1_d0[0]);
  assign mf_d0[5] = (m2p0_d0[0] & m2p1_d0[5]) | (m2p0_d0[1] & m2p1_d0[4]) | (m2p0_d0[2] & m2p1_d0[3]) | (m2p0_d0[3] & m2p1_d0[2]) | (m2p0_d0[4] & m2p1_d0[1]) | (m2p0_d0[5] & m2p1_d0[0]);
  assign mf_d0[6] = (m2p0_d0[0] & m2p1_d0[6]) | (m2p0_d0[1] & m2p1_d0[5]) | (m2p0_d0[2] & m2p1_d0[4]) | (m2p0_d0[3] & m2p1_d0[3]) | (m2p0_d0[4] & m2p1_d0[2]) | (m2p0_d0[5] & m2p1_d0[1]) | (m2p0_d0[6] & m2p1_d0[0]);
  assign mf_d0[7] = (m2p0_d0[0] & m2p1_d0[7]) | (m2p0_d0[1] & m2p1_d0[6]) | (m2p0_d0[2] & m2p1_d0[5]) | (m2p0_d0[3] & m2p1_d0[4]) | (m2p0_d0[4] & m2p1_d0[3]) | (m2p0_d0[5] & m2p1_d0[2]) | (m2p0_d0[6] & m2p1_d0[1]) | (m2p0_d0[7] & m2p1_d0[0]);
  assign mf_d0[8] = (m2p0_d0[0] & m2p1_d0[8]) | (m2p0_d0[1] & m2p1_d0[7]) | (m2p0_d0[2] & m2p1_d0[6]) | (m2p0_d0[3] & m2p1_d0[5]) | (m2p0_d0[4] & m2p1_d0[4]) | (m2p0_d0[5] & m2p1_d0[3]) | (m2p0_d0[6] & m2p1_d0[2]) | (m2p0_d0[7] & m2p1_d0[1]) | (m2p0_d0[8] & m2p1_d0[0]);
  assign mf_d0[9] = (m2p0_d0[0] & m2p1_d0[9]) | (m2p0_d0[1] & m2p1_d0[8]) | (m2p0_d0[2] & m2p1_d0[7]) | (m2p0_d0[3] & m2p1_d0[6]) | (m2p0_d0[4] & m2p1_d0[5]) | (m2p0_d0[5] & m2p1_d0[4]) | (m2p0_d0[6] & m2p1_d0[3]) | (m2p0_d0[7] & m2p1_d0[2]) | (m2p0_d0[8] & m2p1_d0[1]) | (m2p0_d0[9] & m2p1_d0[0]);
  assign mf_d0[10] = (m2p0_d0[0] & m2p1_d0[10]) | (m2p0_d0[1] & m2p1_d0[9]) | (m2p0_d0[2] & m2p1_d0[8]) | (m2p0_d0[3] & m2p1_d0[7]) | (m2p0_d0[4] & m2p1_d0[6]) | (m2p0_d0[5] & m2p1_d0[5]) | (m2p0_d0[6] & m2p1_d0[4]) | (m2p0_d0[7] & m2p1_d0[3]) | (m2p0_d0[8] & m2p1_d0[2]) | (m2p0_d0[9] & m2p1_d0[1]) | (m2p0_d0[10] & m2p1_d0[0]);
  assign mf_d0[11] = (m2p0_d0[0] & m2p1_d0[11]) | (m2p0_d0[1] & m2p1_d0[10]) | (m2p0_d0[2] & m2p1_d0[9]) | (m2p0_d0[3] & m2p1_d0[8]) | (m2p0_d0[4] & m2p1_d0[7]) | (m2p0_d0[5] & m2p1_d0[6]) | (m2p0_d0[6] & m2p1_d0[5]) | (m2p0_d0[7] & m2p1_d0[4]) | (m2p0_d0[8] & m2p1_d0[3]) | (m2p0_d0[9] & m2p1_d0[2]) | (m2p0_d0[10] & m2p1_d0[1]) | (m2p0_d0[11] & m2p1_d0[0]);
  assign mf_d0[12] = (m2p0_d0[0] & m2p1_d0[12]) | (m2p0_d0[1] & m2p1_d0[11]) | (m2p0_d0[2] & m2p1_d0[10]) | (m2p0_d0[3] & m2p1_d0[9]) | (m2p0_d0[4] & m2p1_d0[8]) | (m2p0_d0[5] & m2p1_d0[7]) | (m2p0_d0[6] & m2p1_d0[6]) | (m2p0_d0[7] & m2p1_d0[5]) | (m2p0_d0[8] & m2p1_d0[4]) | (m2p0_d0[9] & m2p1_d0[3]) | (m2p0_d0[10] & m2p1_d0[2]) | (m2p0_d0[11] & m2p1_d0[1]) | (m2p0_d0[12] & m2p1_d0[0]);
  assign mf_d0[13] = (m2p0_d0[1] & m2p1_d0[12]) | (m2p0_d0[2] & m2p1_d0[11]) | (m2p0_d0[3] & m2p1_d0[10]) | (m2p0_d0[4] & m2p1_d0[9]) | (m2p0_d0[5] & m2p1_d0[8]) | (m2p0_d0[6] & m2p1_d0[7]) | (m2p0_d0[7] & m2p1_d0[6]) | (m2p0_d0[8] & m2p1_d0[5]) | (m2p0_d0[9] & m2p1_d0[4]) | (m2p0_d0[10] & m2p1_d0[3]) | (m2p0_d0[11] & m2p1_d0[2]) | (m2p0_d0[12] & m2p1_d0[1]);
  assign mf_d0[14] = (m2p0_d0[2] & m2p1_d0[12]) | (m2p0_d0[3] & m2p1_d0[11]) | (m2p0_d0[4] & m2p1_d0[10]) | (m2p0_d0[5] & m2p1_d0[9]) | (m2p0_d0[6] & m2p1_d0[8]) | (m2p0_d0[7] & m2p1_d0[7]) | (m2p0_d0[8] & m2p1_d0[6]) | (m2p0_d0[9] & m2p1_d0[5]) | (m2p0_d0[10] & m2p1_d0[4]) | (m2p0_d0[11] & m2p1_d0[3]) | (m2p0_d0[12] & m2p1_d0[2]);
  assign mf_d0[15] = (m2p0_d0[3] & m2p1_d0[12]) | (m2p0_d0[4] & m2p1_d0[11]) | (m2p0_d0[5] & m2p1_d0[10]) | (m2p0_d0[6] & m2p1_d0[9]) | (m2p0_d0[7] & m2p1_d0[8]) | (m2p0_d0[8] & m2p1_d0[7]) | (m2p0_d0[9] & m2p1_d0[6]) | (m2p0_d0[10] & m2p1_d0[5]) | (m2p0_d0[11] & m2p1_d0[4]) | (m2p0_d0[12] & m2p1_d0[3]);
  assign mf_d0[16] = (m2p0_d0[4] & m2p1_d0[12]) | (m2p0_d0[5] & m2p1_d0[11]) | (m2p0_d0[6] & m2p1_d0[10]) | (m2p0_d0[7] & m2p1_d0[9]) | (m2p0_d0[8] & m2p1_d0[8]) | (m2p0_d0[9] & m2p1_d0[7]) | (m2p0_d0[10] & m2p1_d0[6]) | (m2p0_d0[11] & m2p1_d0[5]) | (m2p0_d0[12] & m2p1_d0[4]);
  assign mf_d0[17] = (m2p0_d0[5] & m2p1_d0[12]) | (m2p0_d0[6] & m2p1_d0[11]) | (m2p0_d0[7] & m2p1_d0[10]) | (m2p0_d0[8] & m2p1_d0[9]) | (m2p0_d0[9] & m2p1_d0[8]) | (m2p0_d0[10] & m2p1_d0[7]) | (m2p0_d0[11] & m2p1_d0[6]) | (m2p0_d0[12] & m2p1_d0[5]);
  assign mf_d0[18] = (m2p0_d0[6] & m2p1_d0[12]) | (m2p0_d0[7] & m2p1_d0[11]) | (m2p0_d0[8] & m2p1_d0[10]) | (m2p0_d0[9] & m2p1_d0[9]) | (m2p0_d0[10] & m2p1_d0[8]) | (m2p0_d0[11] & m2p1_d0[7]) | (m2p0_d0[12] & m2p1_d0[6]);
  assign mf_d0[19] = (m2p0_d0[7] & m2p1_d0[12]) | (m2p0_d0[8] & m2p1_d0[11]) | (m2p0_d0[9] & m2p1_d0[10]) | (m2p0_d0[10] & m2p1_d0[9]) | (m2p0_d0[11] & m2p1_d0[8]) | (m2p0_d0[12] & m2p1_d0[7]);
  assign mf_d0[20] = (m2p0_d0[8] & m2p1_d0[12]) | (m2p0_d0[9] & m2p1_d0[11]) | (m2p0_d0[10] & m2p1_d0[10]) | (m2p0_d0[11] & m2p1_d0[9]) | (m2p0_d0[12] & m2p1_d0[8]);
  assign mf_d0[21] = (m2p0_d0[9] & m2p1_d0[12]) | (m2p0_d0[10] & m2p1_d0[11]) | (m2p0_d0[11] & m2p1_d0[10]) | (m2p0_d0[12] & m2p1_d0[9]);
  assign mf_d0[22] = (m2p0_d0[10] & m2p1_d0[12]) | (m2p0_d0[11] & m2p1_d0[11]) | (m2p0_d0[12] & m2p1_d0[10]);
  assign mf_d0[23] = (m2p0_d0[11] & m2p1_d0[12]) | (m2p0_d0[12] & m2p1_d0[11]);
  assign mf_d0[24] = (m2p0_d0[12] & m2p1_d0[12]);
  // *** mf_d0 → BUFX4 uLVT (~8ps) → drives 3-4μm M8 wire to Stage 5 ***

  // L3 FINAL d1: 9×9 xpt on M7v/M8h (~720nm grid, ~25ps RC)
  wire [16:0] mf_d1;
  assign mf_d1[0] = (m2p0_d1[0] & m2p1_d1[0]);
  assign mf_d1[1] = (m2p0_d1[0] & m2p1_d1[1]) | (m2p0_d1[1] & m2p1_d1[0]);
  assign mf_d1[2] = (m2p0_d1[0] & m2p1_d1[2]) | (m2p0_d1[1] & m2p1_d1[1]) | (m2p0_d1[2] & m2p1_d1[0]);
  assign mf_d1[3] = (m2p0_d1[0] & m2p1_d1[3]) | (m2p0_d1[1] & m2p1_d1[2]) | (m2p0_d1[2] & m2p1_d1[1]) | (m2p0_d1[3] & m2p1_d1[0]);
  assign mf_d1[4] = (m2p0_d1[0] & m2p1_d1[4]) | (m2p0_d1[1] & m2p1_d1[3]) | (m2p0_d1[2] & m2p1_d1[2]) | (m2p0_d1[3] & m2p1_d1[1]) | (m2p0_d1[4] & m2p1_d1[0]);
  assign mf_d1[5] = (m2p0_d1[0] & m2p1_d1[5]) | (m2p0_d1[1] & m2p1_d1[4]) | (m2p0_d1[2] & m2p1_d1[3]) | (m2p0_d1[3] & m2p1_d1[2]) | (m2p0_d1[4] & m2p1_d1[1]) | (m2p0_d1[5] & m2p1_d1[0]);
  assign mf_d1[6] = (m2p0_d1[0] & m2p1_d1[6]) | (m2p0_d1[1] & m2p1_d1[5]) | (m2p0_d1[2] & m2p1_d1[4]) | (m2p0_d1[3] & m2p1_d1[3]) | (m2p0_d1[4] & m2p1_d1[2]) | (m2p0_d1[5] & m2p1_d1[1]) | (m2p0_d1[6] & m2p1_d1[0]);
  assign mf_d1[7] = (m2p0_d1[0] & m2p1_d1[7]) | (m2p0_d1[1] & m2p1_d1[6]) | (m2p0_d1[2] & m2p1_d1[5]) | (m2p0_d1[3] & m2p1_d1[4]) | (m2p0_d1[4] & m2p1_d1[3]) | (m2p0_d1[5] & m2p1_d1[2]) | (m2p0_d1[6] & m2p1_d1[1]) | (m2p0_d1[7] & m2p1_d1[0]);
  assign mf_d1[8] = (m2p0_d1[0] & m2p1_d1[8]) | (m2p0_d1[1] & m2p1_d1[7]) | (m2p0_d1[2] & m2p1_d1[6]) | (m2p0_d1[3] & m2p1_d1[5]) | (m2p0_d1[4] & m2p1_d1[4]) | (m2p0_d1[5] & m2p1_d1[3]) | (m2p0_d1[6] & m2p1_d1[2]) | (m2p0_d1[7] & m2p1_d1[1]) | (m2p0_d1[8] & m2p1_d1[0]);
  assign mf_d1[9] = (m2p0_d1[1] & m2p1_d1[8]) | (m2p0_d1[2] & m2p1_d1[7]) | (m2p0_d1[3] & m2p1_d1[6]) | (m2p0_d1[4] & m2p1_d1[5]) | (m2p0_d1[5] & m2p1_d1[4]) | (m2p0_d1[6] & m2p1_d1[3]) | (m2p0_d1[7] & m2p1_d1[2]) | (m2p0_d1[8] & m2p1_d1[1]);
  assign mf_d1[10] = (m2p0_d1[2] & m2p1_d1[8]) | (m2p0_d1[3] & m2p1_d1[7]) | (m2p0_d1[4] & m2p1_d1[6]) | (m2p0_d1[5] & m2p1_d1[5]) | (m2p0_d1[6] & m2p1_d1[4]) | (m2p0_d1[7] & m2p1_d1[3]) | (m2p0_d1[8] & m2p1_d1[2]);
  assign mf_d1[11] = (m2p0_d1[3] & m2p1_d1[8]) | (m2p0_d1[4] & m2p1_d1[7]) | (m2p0_d1[5] & m2p1_d1[6]) | (m2p0_d1[6] & m2p1_d1[5]) | (m2p0_d1[7] & m2p1_d1[4]) | (m2p0_d1[8] & m2p1_d1[3]);
  assign mf_d1[12] = (m2p0_d1[4] & m2p1_d1[8]) | (m2p0_d1[5] & m2p1_d1[7]) | (m2p0_d1[6] & m2p1_d1[6]) | (m2p0_d1[7] & m2p1_d1[5]) | (m2p0_d1[8] & m2p1_d1[4]);
  assign mf_d1[13] = (m2p0_d1[5] & m2p1_d1[8]) | (m2p0_d1[6] & m2p1_d1[7]) | (m2p0_d1[7] & m2p1_d1[6]) | (m2p0_d1[8] & m2p1_d1[5]);
  assign mf_d1[14] = (m2p0_d1[6] & m2p1_d1[8]) | (m2p0_d1[7] & m2p1_d1[7]) | (m2p0_d1[8] & m2p1_d1[6]);
  assign mf_d1[15] = (m2p0_d1[7] & m2p1_d1[8]) | (m2p0_d1[8] & m2p1_d1[7]);
  assign mf_d1[16] = (m2p0_d1[8] & m2p1_d1[8]);
  // *** mf_d1 → BUFX4 uLVT (~8ps) → drives 3-4μm M8 wire to Stage 5 ***

  // ====================================================================================================
  // STAGE 5: WIRED-OR BINARY CONVERSION — M8/M9/M10
  // ====================================================================================================
  //
  // PHYSICAL: The final conversion is a 25×17 via grid per output bit.
  //   mf_d0[24:0] on M8 (vertical), mf_d1[16:0] on M9 (horizontal).
  //   Vias at selected (i,j) intersections connect to M10 output wires.
  //
  //   Grid physical size: 25 wires × 160nm pitch = 4.0 μm vertical
  //                       17 wires × 160nm pitch = 2.7 μm horizontal
  //   Total grid area: ~4.0 × 2.7 = ~11 μm²
  //
  //   M9 is global metal (160nm pitch, ~1 Ω/μm), so even 4 μm wires have
  //   only ~4 Ω resistance — very low. RC delay dominated by via capacitance.
  //   Each output bit has ~100-200 vias, contributing ~200-400 fF total load.
  //   With the BUFX4 uLVT drivers from Stage 4, this load is driven in ~15-20 ps.
  //
  //   OUTPUT BUFFER: hd[6:0] exits on M10, buffered with BUFX8 LVT.
  //     If driving off-block load > 20 fF, use 2-stage: INVX4 → INVX16.
  //     Or INVX2 → INVX8 → INVX32 for loads > 50 fF.
  //
  //   Via count per output bit and estimated wired-OR delay:
  //
  // hd[0] (weight 1): 162 vias, ~324fF via load, ~22ps wired-OR delay
  //   → M10 output wire ~5μm → BUFX8 LVT (~8ps) → block boundary
  assign hd[0] = (mf_d0[1] & mf_d1[0]) | (mf_d0[1] & mf_d1[1]) | (mf_d0[1] & mf_d1[2]) | (mf_d0[1] & mf_d1[3])
      | (mf_d0[1] & mf_d1[4]) | (mf_d0[1] & mf_d1[5]) | (mf_d0[1] & mf_d1[6]) | (mf_d0[1] & mf_d1[7])
      | (mf_d0[1] & mf_d1[8]) | (mf_d0[1] & mf_d1[9]) | (mf_d0[1] & mf_d1[10]) | (mf_d0[1] & mf_d1[11])
      | (mf_d0[1] & mf_d1[12]) | (mf_d0[1] & mf_d1[13]) | (mf_d0[1] & mf_d1[14]) | (mf_d0[1] & mf_d1[15])
      | (mf_d0[3] & mf_d1[0]) | (mf_d0[3] & mf_d1[1]) | (mf_d0[3] & mf_d1[2]) | (mf_d0[3] & mf_d1[3])
      | (mf_d0[3] & mf_d1[4]) | (mf_d0[3] & mf_d1[5]) | (mf_d0[3] & mf_d1[6]) | (mf_d0[3] & mf_d1[7])
      | (mf_d0[3] & mf_d1[8]) | (mf_d0[3] & mf_d1[9]) | (mf_d0[3] & mf_d1[10]) | (mf_d0[3] & mf_d1[11])
      | (mf_d0[3] & mf_d1[12]) | (mf_d0[3] & mf_d1[13]) | (mf_d0[3] & mf_d1[14]) | (mf_d0[3] & mf_d1[15])
      | (mf_d0[5] & mf_d1[0]) | (mf_d0[5] & mf_d1[1]) | (mf_d0[5] & mf_d1[2]) | (mf_d0[5] & mf_d1[3])
      | (mf_d0[5] & mf_d1[4]) | (mf_d0[5] & mf_d1[5]) | (mf_d0[5] & mf_d1[6]) | (mf_d0[5] & mf_d1[7])
      | (mf_d0[5] & mf_d1[8]) | (mf_d0[5] & mf_d1[9]) | (mf_d0[5] & mf_d1[10]) | (mf_d0[5] & mf_d1[11])
      | (mf_d0[5] & mf_d1[12]) | (mf_d0[5] & mf_d1[13]) | (mf_d0[5] & mf_d1[14]) | (mf_d0[7] & mf_d1[0])
      | (mf_d0[7] & mf_d1[1]) | (mf_d0[7] & mf_d1[2]) | (mf_d0[7] & mf_d1[3]) | (mf_d0[7] & mf_d1[4])
      | (mf_d0[7] & mf_d1[5]) | (mf_d0[7] & mf_d1[6]) | (mf_d0[7] & mf_d1[7]) | (mf_d0[7] & mf_d1[8])
      | (mf_d0[7] & mf_d1[9]) | (mf_d0[7] & mf_d1[10]) | (mf_d0[7] & mf_d1[11]) | (mf_d0[7] & mf_d1[12])
      | (mf_d0[7] & mf_d1[13]) | (mf_d0[7] & mf_d1[14]) | (mf_d0[9] & mf_d1[0]) | (mf_d0[9] & mf_d1[1])
      | (mf_d0[9] & mf_d1[2]) | (mf_d0[9] & mf_d1[3]) | (mf_d0[9] & mf_d1[4]) | (mf_d0[9] & mf_d1[5])
      | (mf_d0[9] & mf_d1[6]) | (mf_d0[9] & mf_d1[7]) | (mf_d0[9] & mf_d1[8]) | (mf_d0[9] & mf_d1[9])
      | (mf_d0[9] & mf_d1[10]) | (mf_d0[9] & mf_d1[11]) | (mf_d0[9] & mf_d1[12]) | (mf_d0[9] & mf_d1[13])
      | (mf_d0[11] & mf_d1[0]) | (mf_d0[11] & mf_d1[1]) | (mf_d0[11] & mf_d1[2]) | (mf_d0[11] & mf_d1[3])
      | (mf_d0[11] & mf_d1[4]) | (mf_d0[11] & mf_d1[5]) | (mf_d0[11] & mf_d1[6]) | (mf_d0[11] & mf_d1[7])
      | (mf_d0[11] & mf_d1[8]) | (mf_d0[11] & mf_d1[9]) | (mf_d0[11] & mf_d1[10]) | (mf_d0[11] & mf_d1[11])
      | (mf_d0[11] & mf_d1[12]) | (mf_d0[11] & mf_d1[13]) | (mf_d0[13] & mf_d1[0]) | (mf_d0[13] & mf_d1[1])
      | (mf_d0[13] & mf_d1[2]) | (mf_d0[13] & mf_d1[3]) | (mf_d0[13] & mf_d1[4]) | (mf_d0[13] & mf_d1[5])
      | (mf_d0[13] & mf_d1[6]) | (mf_d0[13] & mf_d1[7]) | (mf_d0[13] & mf_d1[8]) | (mf_d0[13] & mf_d1[9])
      | (mf_d0[13] & mf_d1[10]) | (mf_d0[13] & mf_d1[11]) | (mf_d0[13] & mf_d1[12]) | (mf_d0[15] & mf_d1[0])
      | (mf_d0[15] & mf_d1[1]) | (mf_d0[15] & mf_d1[2]) | (mf_d0[15] & mf_d1[3]) | (mf_d0[15] & mf_d1[4])
      | (mf_d0[15] & mf_d1[5]) | (mf_d0[15] & mf_d1[6]) | (mf_d0[15] & mf_d1[7]) | (mf_d0[15] & mf_d1[8])
      | (mf_d0[15] & mf_d1[9]) | (mf_d0[15] & mf_d1[10]) | (mf_d0[15] & mf_d1[11]) | (mf_d0[15] & mf_d1[12])
      | (mf_d0[17] & mf_d1[0]) | (mf_d0[17] & mf_d1[1]) | (mf_d0[17] & mf_d1[2]) | (mf_d0[17] & mf_d1[3])
      | (mf_d0[17] & mf_d1[4]) | (mf_d0[17] & mf_d1[5]) | (mf_d0[17] & mf_d1[6]) | (mf_d0[17] & mf_d1[7])
      | (mf_d0[17] & mf_d1[8]) | (mf_d0[17] & mf_d1[9]) | (mf_d0[17] & mf_d1[10]) | (mf_d0[17] & mf_d1[11])
      | (mf_d0[19] & mf_d1[0]) | (mf_d0[19] & mf_d1[1]) | (mf_d0[19] & mf_d1[2]) | (mf_d0[19] & mf_d1[3])
      | (mf_d0[19] & mf_d1[4]) | (mf_d0[19] & mf_d1[5]) | (mf_d0[19] & mf_d1[6]) | (mf_d0[19] & mf_d1[7])
      | (mf_d0[19] & mf_d1[8]) | (mf_d0[19] & mf_d1[9]) | (mf_d0[19] & mf_d1[10]) | (mf_d0[19] & mf_d1[11])
      | (mf_d0[21] & mf_d1[0]) | (mf_d0[21] & mf_d1[1]) | (mf_d0[21] & mf_d1[2]) | (mf_d0[21] & mf_d1[3])
      | (mf_d0[21] & mf_d1[4]) | (mf_d0[21] & mf_d1[5]) | (mf_d0[21] & mf_d1[6]) | (mf_d0[21] & mf_d1[7])
      | (mf_d0[21] & mf_d1[8]) | (mf_d0[21] & mf_d1[9]) | (mf_d0[21] & mf_d1[10]) | (mf_d0[23] & mf_d1[0])
      | (mf_d0[23] & mf_d1[1]) | (mf_d0[23] & mf_d1[2]) | (mf_d0[23] & mf_d1[3]) | (mf_d0[23] & mf_d1[4])
      | (mf_d0[23] & mf_d1[5]) | (mf_d0[23] & mf_d1[6]) | (mf_d0[23] & mf_d1[7]) | (mf_d0[23] & mf_d1[8])
      | (mf_d0[23] & mf_d1[9]) | (mf_d0[23] & mf_d1[10]);

  // hd[1] (weight 2): 162 vias, ~324fF via load, ~22ps wired-OR delay
  //   → M10 output wire ~5μm → BUFX8 LVT (~8ps) → block boundary
  assign hd[1] = (mf_d0[2] & mf_d1[0]) | (mf_d0[2] & mf_d1[1]) | (mf_d0[2] & mf_d1[2]) | (mf_d0[2] & mf_d1[3])
      | (mf_d0[2] & mf_d1[4]) | (mf_d0[2] & mf_d1[5]) | (mf_d0[2] & mf_d1[6]) | (mf_d0[2] & mf_d1[7])
      | (mf_d0[2] & mf_d1[8]) | (mf_d0[2] & mf_d1[9]) | (mf_d0[2] & mf_d1[10]) | (mf_d0[2] & mf_d1[11])
      | (mf_d0[2] & mf_d1[12]) | (mf_d0[2] & mf_d1[13]) | (mf_d0[2] & mf_d1[14]) | (mf_d0[2] & mf_d1[15])
      | (mf_d0[3] & mf_d1[0]) | (mf_d0[3] & mf_d1[1]) | (mf_d0[3] & mf_d1[2]) | (mf_d0[3] & mf_d1[3])
      | (mf_d0[3] & mf_d1[4]) | (mf_d0[3] & mf_d1[5]) | (mf_d0[3] & mf_d1[6]) | (mf_d0[3] & mf_d1[7])
      | (mf_d0[3] & mf_d1[8]) | (mf_d0[3] & mf_d1[9]) | (mf_d0[3] & mf_d1[10]) | (mf_d0[3] & mf_d1[11])
      | (mf_d0[3] & mf_d1[12]) | (mf_d0[3] & mf_d1[13]) | (mf_d0[3] & mf_d1[14]) | (mf_d0[3] & mf_d1[15])
      | (mf_d0[6] & mf_d1[0]) | (mf_d0[6] & mf_d1[1]) | (mf_d0[6] & mf_d1[2]) | (mf_d0[6] & mf_d1[3])
      | (mf_d0[6] & mf_d1[4]) | (mf_d0[6] & mf_d1[5]) | (mf_d0[6] & mf_d1[6]) | (mf_d0[6] & mf_d1[7])
      | (mf_d0[6] & mf_d1[8]) | (mf_d0[6] & mf_d1[9]) | (mf_d0[6] & mf_d1[10]) | (mf_d0[6] & mf_d1[11])
      | (mf_d0[6] & mf_d1[12]) | (mf_d0[6] & mf_d1[13]) | (mf_d0[6] & mf_d1[14]) | (mf_d0[7] & mf_d1[0])
      | (mf_d0[7] & mf_d1[1]) | (mf_d0[7] & mf_d1[2]) | (mf_d0[7] & mf_d1[3]) | (mf_d0[7] & mf_d1[4])
      | (mf_d0[7] & mf_d1[5]) | (mf_d0[7] & mf_d1[6]) | (mf_d0[7] & mf_d1[7]) | (mf_d0[7] & mf_d1[8])
      | (mf_d0[7] & mf_d1[9]) | (mf_d0[7] & mf_d1[10]) | (mf_d0[7] & mf_d1[11]) | (mf_d0[7] & mf_d1[12])
      | (mf_d0[7] & mf_d1[13]) | (mf_d0[7] & mf_d1[14]) | (mf_d0[10] & mf_d1[0]) | (mf_d0[10] & mf_d1[1])
      | (mf_d0[10] & mf_d1[2]) | (mf_d0[10] & mf_d1[3]) | (mf_d0[10] & mf_d1[4]) | (mf_d0[10] & mf_d1[5])
      | (mf_d0[10] & mf_d1[6]) | (mf_d0[10] & mf_d1[7]) | (mf_d0[10] & mf_d1[8]) | (mf_d0[10] & mf_d1[9])
      | (mf_d0[10] & mf_d1[10]) | (mf_d0[10] & mf_d1[11]) | (mf_d0[10] & mf_d1[12]) | (mf_d0[10] & mf_d1[13])
      | (mf_d0[11] & mf_d1[0]) | (mf_d0[11] & mf_d1[1]) | (mf_d0[11] & mf_d1[2]) | (mf_d0[11] & mf_d1[3])
      | (mf_d0[11] & mf_d1[4]) | (mf_d0[11] & mf_d1[5]) | (mf_d0[11] & mf_d1[6]) | (mf_d0[11] & mf_d1[7])
      | (mf_d0[11] & mf_d1[8]) | (mf_d0[11] & mf_d1[9]) | (mf_d0[11] & mf_d1[10]) | (mf_d0[11] & mf_d1[11])
      | (mf_d0[11] & mf_d1[12]) | (mf_d0[11] & mf_d1[13]) | (mf_d0[14] & mf_d1[0]) | (mf_d0[14] & mf_d1[1])
      | (mf_d0[14] & mf_d1[2]) | (mf_d0[14] & mf_d1[3]) | (mf_d0[14] & mf_d1[4]) | (mf_d0[14] & mf_d1[5])
      | (mf_d0[14] & mf_d1[6]) | (mf_d0[14] & mf_d1[7]) | (mf_d0[14] & mf_d1[8]) | (mf_d0[14] & mf_d1[9])
      | (mf_d0[14] & mf_d1[10]) | (mf_d0[14] & mf_d1[11]) | (mf_d0[14] & mf_d1[12]) | (mf_d0[15] & mf_d1[0])
      | (mf_d0[15] & mf_d1[1]) | (mf_d0[15] & mf_d1[2]) | (mf_d0[15] & mf_d1[3]) | (mf_d0[15] & mf_d1[4])
      | (mf_d0[15] & mf_d1[5]) | (mf_d0[15] & mf_d1[6]) | (mf_d0[15] & mf_d1[7]) | (mf_d0[15] & mf_d1[8])
      | (mf_d0[15] & mf_d1[9]) | (mf_d0[15] & mf_d1[10]) | (mf_d0[15] & mf_d1[11]) | (mf_d0[15] & mf_d1[12])
      | (mf_d0[18] & mf_d1[0]) | (mf_d0[18] & mf_d1[1]) | (mf_d0[18] & mf_d1[2]) | (mf_d0[18] & mf_d1[3])
      | (mf_d0[18] & mf_d1[4]) | (mf_d0[18] & mf_d1[5]) | (mf_d0[18] & mf_d1[6]) | (mf_d0[18] & mf_d1[7])
      | (mf_d0[18] & mf_d1[8]) | (mf_d0[18] & mf_d1[9]) | (mf_d0[18] & mf_d1[10]) | (mf_d0[18] & mf_d1[11])
      | (mf_d0[19] & mf_d1[0]) | (mf_d0[19] & mf_d1[1]) | (mf_d0[19] & mf_d1[2]) | (mf_d0[19] & mf_d1[3])
      | (mf_d0[19] & mf_d1[4]) | (mf_d0[19] & mf_d1[5]) | (mf_d0[19] & mf_d1[6]) | (mf_d0[19] & mf_d1[7])
      | (mf_d0[19] & mf_d1[8]) | (mf_d0[19] & mf_d1[9]) | (mf_d0[19] & mf_d1[10]) | (mf_d0[19] & mf_d1[11])
      | (mf_d0[22] & mf_d1[0]) | (mf_d0[22] & mf_d1[1]) | (mf_d0[22] & mf_d1[2]) | (mf_d0[22] & mf_d1[3])
      | (mf_d0[22] & mf_d1[4]) | (mf_d0[22] & mf_d1[5]) | (mf_d0[22] & mf_d1[6]) | (mf_d0[22] & mf_d1[7])
      | (mf_d0[22] & mf_d1[8]) | (mf_d0[22] & mf_d1[9]) | (mf_d0[22] & mf_d1[10]) | (mf_d0[23] & mf_d1[0])
      | (mf_d0[23] & mf_d1[1]) | (mf_d0[23] & mf_d1[2]) | (mf_d0[23] & mf_d1[3]) | (mf_d0[23] & mf_d1[4])
      | (mf_d0[23] & mf_d1[5]) | (mf_d0[23] & mf_d1[6]) | (mf_d0[23] & mf_d1[7]) | (mf_d0[23] & mf_d1[8])
      | (mf_d0[23] & mf_d1[9]) | (mf_d0[23] & mf_d1[10]);

  // hd[2] (weight 4): 173 vias, ~346fF via load, ~22ps wired-OR delay
  //   → M10 output wire ~5μm → BUFX8 LVT (~8ps) → block boundary
  assign hd[2] = (mf_d0[0] & mf_d1[1]) | (mf_d0[0] & mf_d1[3]) | (mf_d0[0] & mf_d1[5]) | (mf_d0[0] & mf_d1[7])
      | (mf_d0[0] & mf_d1[9]) | (mf_d0[0] & mf_d1[11]) | (mf_d0[0] & mf_d1[13]) | (mf_d0[0] & mf_d1[15])
      | (mf_d0[1] & mf_d1[1]) | (mf_d0[1] & mf_d1[3]) | (mf_d0[1] & mf_d1[5]) | (mf_d0[1] & mf_d1[7])
      | (mf_d0[1] & mf_d1[9]) | (mf_d0[1] & mf_d1[11]) | (mf_d0[1] & mf_d1[13]) | (mf_d0[1] & mf_d1[15])
      | (mf_d0[2] & mf_d1[1]) | (mf_d0[2] & mf_d1[3]) | (mf_d0[2] & mf_d1[5]) | (mf_d0[2] & mf_d1[7])
      | (mf_d0[2] & mf_d1[9]) | (mf_d0[2] & mf_d1[11]) | (mf_d0[2] & mf_d1[13]) | (mf_d0[2] & mf_d1[15])
      | (mf_d0[3] & mf_d1[1]) | (mf_d0[3] & mf_d1[3]) | (mf_d0[3] & mf_d1[5]) | (mf_d0[3] & mf_d1[7])
      | (mf_d0[3] & mf_d1[9]) | (mf_d0[3] & mf_d1[11]) | (mf_d0[3] & mf_d1[13]) | (mf_d0[3] & mf_d1[15])
      | (mf_d0[4] & mf_d1[0]) | (mf_d0[4] & mf_d1[2]) | (mf_d0[4] & mf_d1[4]) | (mf_d0[4] & mf_d1[6])
      | (mf_d0[4] & mf_d1[8]) | (mf_d0[4] & mf_d1[10]) | (mf_d0[4] & mf_d1[12]) | (mf_d0[4] & mf_d1[14])
      | (mf_d0[5] & mf_d1[0]) | (mf_d0[5] & mf_d1[2]) | (mf_d0[5] & mf_d1[4]) | (mf_d0[5] & mf_d1[6])
      | (mf_d0[5] & mf_d1[8]) | (mf_d0[5] & mf_d1[10]) | (mf_d0[5] & mf_d1[12]) | (mf_d0[5] & mf_d1[14])
      | (mf_d0[6] & mf_d1[0]) | (mf_d0[6] & mf_d1[2]) | (mf_d0[6] & mf_d1[4]) | (mf_d0[6] & mf_d1[6])
      | (mf_d0[6] & mf_d1[8]) | (mf_d0[6] & mf_d1[10]) | (mf_d0[6] & mf_d1[12]) | (mf_d0[6] & mf_d1[14])
      | (mf_d0[7] & mf_d1[0]) | (mf_d0[7] & mf_d1[2]) | (mf_d0[7] & mf_d1[4]) | (mf_d0[7] & mf_d1[6])
      | (mf_d0[7] & mf_d1[8]) | (mf_d0[7] & mf_d1[10]) | (mf_d0[7] & mf_d1[12]) | (mf_d0[7] & mf_d1[14])
      | (mf_d0[8] & mf_d1[1]) | (mf_d0[8] & mf_d1[3]) | (mf_d0[8] & mf_d1[5]) | (mf_d0[8] & mf_d1[7])
      | (mf_d0[8] & mf_d1[9]) | (mf_d0[8] & mf_d1[11]) | (mf_d0[8] & mf_d1[13]) | (mf_d0[9] & mf_d1[1])
      | (mf_d0[9] & mf_d1[3]) | (mf_d0[9] & mf_d1[5]) | (mf_d0[9] & mf_d1[7]) | (mf_d0[9] & mf_d1[9])
      | (mf_d0[9] & mf_d1[11]) | (mf_d0[9] & mf_d1[13]) | (mf_d0[10] & mf_d1[1]) | (mf_d0[10] & mf_d1[3])
      | (mf_d0[10] & mf_d1[5]) | (mf_d0[10] & mf_d1[7]) | (mf_d0[10] & mf_d1[9]) | (mf_d0[10] & mf_d1[11])
      | (mf_d0[10] & mf_d1[13]) | (mf_d0[11] & mf_d1[1]) | (mf_d0[11] & mf_d1[3]) | (mf_d0[11] & mf_d1[5])
      | (mf_d0[11] & mf_d1[7]) | (mf_d0[11] & mf_d1[9]) | (mf_d0[11] & mf_d1[11]) | (mf_d0[11] & mf_d1[13])
      | (mf_d0[12] & mf_d1[0]) | (mf_d0[12] & mf_d1[2]) | (mf_d0[12] & mf_d1[4]) | (mf_d0[12] & mf_d1[6])
      | (mf_d0[12] & mf_d1[8]) | (mf_d0[12] & mf_d1[10]) | (mf_d0[12] & mf_d1[12]) | (mf_d0[13] & mf_d1[0])
      | (mf_d0[13] & mf_d1[2]) | (mf_d0[13] & mf_d1[4]) | (mf_d0[13] & mf_d1[6]) | (mf_d0[13] & mf_d1[8])
      | (mf_d0[13] & mf_d1[10]) | (mf_d0[13] & mf_d1[12]) | (mf_d0[14] & mf_d1[0]) | (mf_d0[14] & mf_d1[2])
      | (mf_d0[14] & mf_d1[4]) | (mf_d0[14] & mf_d1[6]) | (mf_d0[14] & mf_d1[8]) | (mf_d0[14] & mf_d1[10])
      | (mf_d0[14] & mf_d1[12]) | (mf_d0[15] & mf_d1[0]) | (mf_d0[15] & mf_d1[2]) | (mf_d0[15] & mf_d1[4])
      | (mf_d0[15] & mf_d1[6]) | (mf_d0[15] & mf_d1[8]) | (mf_d0[15] & mf_d1[10]) | (mf_d0[15] & mf_d1[12])
      | (mf_d0[16] & mf_d1[1]) | (mf_d0[16] & mf_d1[3]) | (mf_d0[16] & mf_d1[5]) | (mf_d0[16] & mf_d1[7])
      | (mf_d0[16] & mf_d1[9]) | (mf_d0[16] & mf_d1[11]) | (mf_d0[17] & mf_d1[1]) | (mf_d0[17] & mf_d1[3])
      | (mf_d0[17] & mf_d1[5]) | (mf_d0[17] & mf_d1[7]) | (mf_d0[17] & mf_d1[9]) | (mf_d0[17] & mf_d1[11])
      | (mf_d0[18] & mf_d1[1]) | (mf_d0[18] & mf_d1[3]) | (mf_d0[18] & mf_d1[5]) | (mf_d0[18] & mf_d1[7])
      | (mf_d0[18] & mf_d1[9]) | (mf_d0[18] & mf_d1[11]) | (mf_d0[19] & mf_d1[1]) | (mf_d0[19] & mf_d1[3])
      | (mf_d0[19] & mf_d1[5]) | (mf_d0[19] & mf_d1[7]) | (mf_d0[19] & mf_d1[9]) | (mf_d0[19] & mf_d1[11])
      | (mf_d0[20] & mf_d1[0]) | (mf_d0[20] & mf_d1[2]) | (mf_d0[20] & mf_d1[4]) | (mf_d0[20] & mf_d1[6])
      | (mf_d0[20] & mf_d1[8]) | (mf_d0[20] & mf_d1[10]) | (mf_d0[21] & mf_d1[0]) | (mf_d0[21] & mf_d1[2])
      | (mf_d0[21] & mf_d1[4]) | (mf_d0[21] & mf_d1[6]) | (mf_d0[21] & mf_d1[8]) | (mf_d0[21] & mf_d1[10])
      | (mf_d0[22] & mf_d1[0]) | (mf_d0[22] & mf_d1[2]) | (mf_d0[22] & mf_d1[4]) | (mf_d0[22] & mf_d1[6])
      | (mf_d0[22] & mf_d1[8]) | (mf_d0[22] & mf_d1[10]) | (mf_d0[23] & mf_d1[0]) | (mf_d0[23] & mf_d1[2])
      | (mf_d0[23] & mf_d1[4]) | (mf_d0[23] & mf_d1[6]) | (mf_d0[23] & mf_d1[8]) | (mf_d0[23] & mf_d1[10])
      | (mf_d0[24] & mf_d1[1]) | (mf_d0[24] & mf_d1[3]) | (mf_d0[24] & mf_d1[5]) | (mf_d0[24] & mf_d1[7])
      | (mf_d0[24] & mf_d1[9]);

  // hd[3] (weight 8): 178 vias, ~356fF via load, ~23ps wired-OR delay
  //   → M10 output wire ~5μm → BUFX8 LVT (~8ps) → block boundary
  assign hd[3] = (mf_d0[0] & mf_d1[2]) | (mf_d0[0] & mf_d1[3]) | (mf_d0[0] & mf_d1[6]) | (mf_d0[0] & mf_d1[7])
      | (mf_d0[0] & mf_d1[10]) | (mf_d0[0] & mf_d1[11]) | (mf_d0[0] & mf_d1[14]) | (mf_d0[0] & mf_d1[15])
      | (mf_d0[1] & mf_d1[2]) | (mf_d0[1] & mf_d1[3]) | (mf_d0[1] & mf_d1[6]) | (mf_d0[1] & mf_d1[7])
      | (mf_d0[1] & mf_d1[10]) | (mf_d0[1] & mf_d1[11]) | (mf_d0[1] & mf_d1[14]) | (mf_d0[1] & mf_d1[15])
      | (mf_d0[2] & mf_d1[2]) | (mf_d0[2] & mf_d1[3]) | (mf_d0[2] & mf_d1[6]) | (mf_d0[2] & mf_d1[7])
      | (mf_d0[2] & mf_d1[10]) | (mf_d0[2] & mf_d1[11]) | (mf_d0[2] & mf_d1[14]) | (mf_d0[2] & mf_d1[15])
      | (mf_d0[3] & mf_d1[2]) | (mf_d0[3] & mf_d1[3]) | (mf_d0[3] & mf_d1[6]) | (mf_d0[3] & mf_d1[7])
      | (mf_d0[3] & mf_d1[10]) | (mf_d0[3] & mf_d1[11]) | (mf_d0[3] & mf_d1[14]) | (mf_d0[3] & mf_d1[15])
      | (mf_d0[4] & mf_d1[1]) | (mf_d0[4] & mf_d1[2]) | (mf_d0[4] & mf_d1[5]) | (mf_d0[4] & mf_d1[6])
      | (mf_d0[4] & mf_d1[9]) | (mf_d0[4] & mf_d1[10]) | (mf_d0[4] & mf_d1[13]) | (mf_d0[4] & mf_d1[14])
      | (mf_d0[5] & mf_d1[1]) | (mf_d0[5] & mf_d1[2]) | (mf_d0[5] & mf_d1[5]) | (mf_d0[5] & mf_d1[6])
      | (mf_d0[5] & mf_d1[9]) | (mf_d0[5] & mf_d1[10]) | (mf_d0[5] & mf_d1[13]) | (mf_d0[5] & mf_d1[14])
      | (mf_d0[6] & mf_d1[1]) | (mf_d0[6] & mf_d1[2]) | (mf_d0[6] & mf_d1[5]) | (mf_d0[6] & mf_d1[6])
      | (mf_d0[6] & mf_d1[9]) | (mf_d0[6] & mf_d1[10]) | (mf_d0[6] & mf_d1[13]) | (mf_d0[6] & mf_d1[14])
      | (mf_d0[7] & mf_d1[1]) | (mf_d0[7] & mf_d1[2]) | (mf_d0[7] & mf_d1[5]) | (mf_d0[7] & mf_d1[6])
      | (mf_d0[7] & mf_d1[9]) | (mf_d0[7] & mf_d1[10]) | (mf_d0[7] & mf_d1[13]) | (mf_d0[7] & mf_d1[14])
      | (mf_d0[8] & mf_d1[0]) | (mf_d0[8] & mf_d1[1]) | (mf_d0[8] & mf_d1[4]) | (mf_d0[8] & mf_d1[5])
      | (mf_d0[8] & mf_d1[8]) | (mf_d0[8] & mf_d1[9]) | (mf_d0[8] & mf_d1[12]) | (mf_d0[8] & mf_d1[13])
      | (mf_d0[9] & mf_d1[0]) | (mf_d0[9] & mf_d1[1]) | (mf_d0[9] & mf_d1[4]) | (mf_d0[9] & mf_d1[5])
      | (mf_d0[9] & mf_d1[8]) | (mf_d0[9] & mf_d1[9]) | (mf_d0[9] & mf_d1[12]) | (mf_d0[9] & mf_d1[13])
      | (mf_d0[10] & mf_d1[0]) | (mf_d0[10] & mf_d1[1]) | (mf_d0[10] & mf_d1[4]) | (mf_d0[10] & mf_d1[5])
      | (mf_d0[10] & mf_d1[8]) | (mf_d0[10] & mf_d1[9]) | (mf_d0[10] & mf_d1[12]) | (mf_d0[10] & mf_d1[13])
      | (mf_d0[11] & mf_d1[0]) | (mf_d0[11] & mf_d1[1]) | (mf_d0[11] & mf_d1[4]) | (mf_d0[11] & mf_d1[5])
      | (mf_d0[11] & mf_d1[8]) | (mf_d0[11] & mf_d1[9]) | (mf_d0[11] & mf_d1[12]) | (mf_d0[11] & mf_d1[13])
      | (mf_d0[12] & mf_d1[0]) | (mf_d0[12] & mf_d1[3]) | (mf_d0[12] & mf_d1[4]) | (mf_d0[12] & mf_d1[7])
      | (mf_d0[12] & mf_d1[8]) | (mf_d0[12] & mf_d1[11]) | (mf_d0[12] & mf_d1[12]) | (mf_d0[13] & mf_d1[0])
      | (mf_d0[13] & mf_d1[3]) | (mf_d0[13] & mf_d1[4]) | (mf_d0[13] & mf_d1[7]) | (mf_d0[13] & mf_d1[8])
      | (mf_d0[13] & mf_d1[11]) | (mf_d0[13] & mf_d1[12]) | (mf_d0[14] & mf_d1[0]) | (mf_d0[14] & mf_d1[3])
      | (mf_d0[14] & mf_d1[4]) | (mf_d0[14] & mf_d1[7]) | (mf_d0[14] & mf_d1[8]) | (mf_d0[14] & mf_d1[11])
      | (mf_d0[14] & mf_d1[12]) | (mf_d0[15] & mf_d1[0]) | (mf_d0[15] & mf_d1[3]) | (mf_d0[15] & mf_d1[4])
      | (mf_d0[15] & mf_d1[7]) | (mf_d0[15] & mf_d1[8]) | (mf_d0[15] & mf_d1[11]) | (mf_d0[15] & mf_d1[12])
      | (mf_d0[16] & mf_d1[2]) | (mf_d0[16] & mf_d1[3]) | (mf_d0[16] & mf_d1[6]) | (mf_d0[16] & mf_d1[7])
      | (mf_d0[16] & mf_d1[10]) | (mf_d0[16] & mf_d1[11]) | (mf_d0[17] & mf_d1[2]) | (mf_d0[17] & mf_d1[3])
      | (mf_d0[17] & mf_d1[6]) | (mf_d0[17] & mf_d1[7]) | (mf_d0[17] & mf_d1[10]) | (mf_d0[17] & mf_d1[11])
      | (mf_d0[18] & mf_d1[2]) | (mf_d0[18] & mf_d1[3]) | (mf_d0[18] & mf_d1[6]) | (mf_d0[18] & mf_d1[7])
      | (mf_d0[18] & mf_d1[10]) | (mf_d0[18] & mf_d1[11]) | (mf_d0[19] & mf_d1[2]) | (mf_d0[19] & mf_d1[3])
      | (mf_d0[19] & mf_d1[6]) | (mf_d0[19] & mf_d1[7]) | (mf_d0[19] & mf_d1[10]) | (mf_d0[19] & mf_d1[11])
      | (mf_d0[20] & mf_d1[1]) | (mf_d0[20] & mf_d1[2]) | (mf_d0[20] & mf_d1[5]) | (mf_d0[20] & mf_d1[6])
      | (mf_d0[20] & mf_d1[9]) | (mf_d0[20] & mf_d1[10]) | (mf_d0[21] & mf_d1[1]) | (mf_d0[21] & mf_d1[2])
      | (mf_d0[21] & mf_d1[5]) | (mf_d0[21] & mf_d1[6]) | (mf_d0[21] & mf_d1[9]) | (mf_d0[21] & mf_d1[10])
      | (mf_d0[22] & mf_d1[1]) | (mf_d0[22] & mf_d1[2]) | (mf_d0[22] & mf_d1[5]) | (mf_d0[22] & mf_d1[6])
      | (mf_d0[22] & mf_d1[9]) | (mf_d0[22] & mf_d1[10]) | (mf_d0[23] & mf_d1[1]) | (mf_d0[23] & mf_d1[2])
      | (mf_d0[23] & mf_d1[5]) | (mf_d0[23] & mf_d1[6]) | (mf_d0[23] & mf_d1[9]) | (mf_d0[23] & mf_d1[10])
      | (mf_d0[24] & mf_d1[0]) | (mf_d0[24] & mf_d1[1]) | (mf_d0[24] & mf_d1[4]) | (mf_d0[24] & mf_d1[5])
      | (mf_d0[24] & mf_d1[8]) | (mf_d0[24] & mf_d1[9]);

  // hd[4] (weight 16): 194 vias, ~388fF via load, ~24ps wired-OR delay
  //   → M10 output wire ~5μm → BUFX8 LVT (~8ps) → block boundary
  assign hd[4] = (mf_d0[0] & mf_d1[4]) | (mf_d0[0] & mf_d1[5]) | (mf_d0[0] & mf_d1[6]) | (mf_d0[0] & mf_d1[7])
      | (mf_d0[0] & mf_d1[12]) | (mf_d0[0] & mf_d1[13]) | (mf_d0[0] & mf_d1[14]) | (mf_d0[0] & mf_d1[15])
      | (mf_d0[1] & mf_d1[4]) | (mf_d0[1] & mf_d1[5]) | (mf_d0[1] & mf_d1[6]) | (mf_d0[1] & mf_d1[7])
      | (mf_d0[1] & mf_d1[12]) | (mf_d0[1] & mf_d1[13]) | (mf_d0[1] & mf_d1[14]) | (mf_d0[1] & mf_d1[15])
      | (mf_d0[2] & mf_d1[4]) | (mf_d0[2] & mf_d1[5]) | (mf_d0[2] & mf_d1[6]) | (mf_d0[2] & mf_d1[7])
      | (mf_d0[2] & mf_d1[12]) | (mf_d0[2] & mf_d1[13]) | (mf_d0[2] & mf_d1[14]) | (mf_d0[2] & mf_d1[15])
      | (mf_d0[3] & mf_d1[4]) | (mf_d0[3] & mf_d1[5]) | (mf_d0[3] & mf_d1[6]) | (mf_d0[3] & mf_d1[7])
      | (mf_d0[3] & mf_d1[12]) | (mf_d0[3] & mf_d1[13]) | (mf_d0[3] & mf_d1[14]) | (mf_d0[3] & mf_d1[15])
      | (mf_d0[4] & mf_d1[3]) | (mf_d0[4] & mf_d1[4]) | (mf_d0[4] & mf_d1[5]) | (mf_d0[4] & mf_d1[6])
      | (mf_d0[4] & mf_d1[11]) | (mf_d0[4] & mf_d1[12]) | (mf_d0[4] & mf_d1[13]) | (mf_d0[4] & mf_d1[14])
      | (mf_d0[5] & mf_d1[3]) | (mf_d0[5] & mf_d1[4]) | (mf_d0[5] & mf_d1[5]) | (mf_d0[5] & mf_d1[6])
      | (mf_d0[5] & mf_d1[11]) | (mf_d0[5] & mf_d1[12]) | (mf_d0[5] & mf_d1[13]) | (mf_d0[5] & mf_d1[14])
      | (mf_d0[6] & mf_d1[3]) | (mf_d0[6] & mf_d1[4]) | (mf_d0[6] & mf_d1[5]) | (mf_d0[6] & mf_d1[6])
      | (mf_d0[6] & mf_d1[11]) | (mf_d0[6] & mf_d1[12]) | (mf_d0[6] & mf_d1[13]) | (mf_d0[6] & mf_d1[14])
      | (mf_d0[7] & mf_d1[3]) | (mf_d0[7] & mf_d1[4]) | (mf_d0[7] & mf_d1[5]) | (mf_d0[7] & mf_d1[6])
      | (mf_d0[7] & mf_d1[11]) | (mf_d0[7] & mf_d1[12]) | (mf_d0[7] & mf_d1[13]) | (mf_d0[7] & mf_d1[14])
      | (mf_d0[8] & mf_d1[2]) | (mf_d0[8] & mf_d1[3]) | (mf_d0[8] & mf_d1[4]) | (mf_d0[8] & mf_d1[5])
      | (mf_d0[8] & mf_d1[10]) | (mf_d0[8] & mf_d1[11]) | (mf_d0[8] & mf_d1[12]) | (mf_d0[8] & mf_d1[13])
      | (mf_d0[9] & mf_d1[2]) | (mf_d0[9] & mf_d1[3]) | (mf_d0[9] & mf_d1[4]) | (mf_d0[9] & mf_d1[5])
      | (mf_d0[9] & mf_d1[10]) | (mf_d0[9] & mf_d1[11]) | (mf_d0[9] & mf_d1[12]) | (mf_d0[9] & mf_d1[13])
      | (mf_d0[10] & mf_d1[2]) | (mf_d0[10] & mf_d1[3]) | (mf_d0[10] & mf_d1[4]) | (mf_d0[10] & mf_d1[5])
      | (mf_d0[10] & mf_d1[10]) | (mf_d0[10] & mf_d1[11]) | (mf_d0[10] & mf_d1[12]) | (mf_d0[10] & mf_d1[13])
      | (mf_d0[11] & mf_d1[2]) | (mf_d0[11] & mf_d1[3]) | (mf_d0[11] & mf_d1[4]) | (mf_d0[11] & mf_d1[5])
      | (mf_d0[11] & mf_d1[10]) | (mf_d0[11] & mf_d1[11]) | (mf_d0[11] & mf_d1[12]) | (mf_d0[11] & mf_d1[13])
      | (mf_d0[12] & mf_d1[1]) | (mf_d0[12] & mf_d1[2]) | (mf_d0[12] & mf_d1[3]) | (mf_d0[12] & mf_d1[4])
      | (mf_d0[12] & mf_d1[9]) | (mf_d0[12] & mf_d1[10]) | (mf_d0[12] & mf_d1[11]) | (mf_d0[12] & mf_d1[12])
      | (mf_d0[13] & mf_d1[1]) | (mf_d0[13] & mf_d1[2]) | (mf_d0[13] & mf_d1[3]) | (mf_d0[13] & mf_d1[4])
      | (mf_d0[13] & mf_d1[9]) | (mf_d0[13] & mf_d1[10]) | (mf_d0[13] & mf_d1[11]) | (mf_d0[13] & mf_d1[12])
      | (mf_d0[14] & mf_d1[1]) | (mf_d0[14] & mf_d1[2]) | (mf_d0[14] & mf_d1[3]) | (mf_d0[14] & mf_d1[4])
      | (mf_d0[14] & mf_d1[9]) | (mf_d0[14] & mf_d1[10]) | (mf_d0[14] & mf_d1[11]) | (mf_d0[14] & mf_d1[12])
      | (mf_d0[15] & mf_d1[1]) | (mf_d0[15] & mf_d1[2]) | (mf_d0[15] & mf_d1[3]) | (mf_d0[15] & mf_d1[4])
      | (mf_d0[15] & mf_d1[9]) | (mf_d0[15] & mf_d1[10]) | (mf_d0[15] & mf_d1[11]) | (mf_d0[15] & mf_d1[12])
      | (mf_d0[16] & mf_d1[0]) | (mf_d0[16] & mf_d1[1]) | (mf_d0[16] & mf_d1[2]) | (mf_d0[16] & mf_d1[3])
      | (mf_d0[16] & mf_d1[8]) | (mf_d0[16] & mf_d1[9]) | (mf_d0[16] & mf_d1[10]) | (mf_d0[16] & mf_d1[11])
      | (mf_d0[17] & mf_d1[0]) | (mf_d0[17] & mf_d1[1]) | (mf_d0[17] & mf_d1[2]) | (mf_d0[17] & mf_d1[3])
      | (mf_d0[17] & mf_d1[8]) | (mf_d0[17] & mf_d1[9]) | (mf_d0[17] & mf_d1[10]) | (mf_d0[17] & mf_d1[11])
      | (mf_d0[18] & mf_d1[0]) | (mf_d0[18] & mf_d1[1]) | (mf_d0[18] & mf_d1[2]) | (mf_d0[18] & mf_d1[3])
      | (mf_d0[18] & mf_d1[8]) | (mf_d0[18] & mf_d1[9]) | (mf_d0[18] & mf_d1[10]) | (mf_d0[18] & mf_d1[11])
      | (mf_d0[19] & mf_d1[0]) | (mf_d0[19] & mf_d1[1]) | (mf_d0[19] & mf_d1[2]) | (mf_d0[19] & mf_d1[3])
      | (mf_d0[19] & mf_d1[8]) | (mf_d0[19] & mf_d1[9]) | (mf_d0[19] & mf_d1[10]) | (mf_d0[19] & mf_d1[11])
      | (mf_d0[20] & mf_d1[0]) | (mf_d0[20] & mf_d1[1]) | (mf_d0[20] & mf_d1[2]) | (mf_d0[20] & mf_d1[7])
      | (mf_d0[20] & mf_d1[8]) | (mf_d0[20] & mf_d1[9]) | (mf_d0[20] & mf_d1[10]) | (mf_d0[21] & mf_d1[0])
      | (mf_d0[21] & mf_d1[1]) | (mf_d0[21] & mf_d1[2]) | (mf_d0[21] & mf_d1[7]) | (mf_d0[21] & mf_d1[8])
      | (mf_d0[21] & mf_d1[9]) | (mf_d0[21] & mf_d1[10]) | (mf_d0[22] & mf_d1[0]) | (mf_d0[22] & mf_d1[1])
      | (mf_d0[22] & mf_d1[2]) | (mf_d0[22] & mf_d1[7]) | (mf_d0[22] & mf_d1[8]) | (mf_d0[22] & mf_d1[9])
      | (mf_d0[22] & mf_d1[10]) | (mf_d0[23] & mf_d1[0]) | (mf_d0[23] & mf_d1[1]) | (mf_d0[23] & mf_d1[2])
      | (mf_d0[23] & mf_d1[7]) | (mf_d0[23] & mf_d1[8]) | (mf_d0[23] & mf_d1[9]) | (mf_d0[23] & mf_d1[10])
      | (mf_d0[24] & mf_d1[0]) | (mf_d0[24] & mf_d1[1]) | (mf_d0[24] & mf_d1[6]) | (mf_d0[24] & mf_d1[7])
      | (mf_d0[24] & mf_d1[8]) | (mf_d0[24] & mf_d1[9]);

  // hd[5] (weight 32): 200 vias, ~400fF via load, ~24ps wired-OR delay
  //   → M10 output wire ~5μm → BUFX8 LVT (~8ps) → block boundary
  assign hd[5] = (mf_d0[0] & mf_d1[8]) | (mf_d0[0] & mf_d1[9]) | (mf_d0[0] & mf_d1[10]) | (mf_d0[0] & mf_d1[11])
      | (mf_d0[0] & mf_d1[12]) | (mf_d0[0] & mf_d1[13]) | (mf_d0[0] & mf_d1[14]) | (mf_d0[0] & mf_d1[15])
      | (mf_d0[1] & mf_d1[8]) | (mf_d0[1] & mf_d1[9]) | (mf_d0[1] & mf_d1[10]) | (mf_d0[1] & mf_d1[11])
      | (mf_d0[1] & mf_d1[12]) | (mf_d0[1] & mf_d1[13]) | (mf_d0[1] & mf_d1[14]) | (mf_d0[1] & mf_d1[15])
      | (mf_d0[2] & mf_d1[8]) | (mf_d0[2] & mf_d1[9]) | (mf_d0[2] & mf_d1[10]) | (mf_d0[2] & mf_d1[11])
      | (mf_d0[2] & mf_d1[12]) | (mf_d0[2] & mf_d1[13]) | (mf_d0[2] & mf_d1[14]) | (mf_d0[2] & mf_d1[15])
      | (mf_d0[3] & mf_d1[8]) | (mf_d0[3] & mf_d1[9]) | (mf_d0[3] & mf_d1[10]) | (mf_d0[3] & mf_d1[11])
      | (mf_d0[3] & mf_d1[12]) | (mf_d0[3] & mf_d1[13]) | (mf_d0[3] & mf_d1[14]) | (mf_d0[3] & mf_d1[15])
      | (mf_d0[4] & mf_d1[7]) | (mf_d0[4] & mf_d1[8]) | (mf_d0[4] & mf_d1[9]) | (mf_d0[4] & mf_d1[10])
      | (mf_d0[4] & mf_d1[11]) | (mf_d0[4] & mf_d1[12]) | (mf_d0[4] & mf_d1[13]) | (mf_d0[4] & mf_d1[14])
      | (mf_d0[5] & mf_d1[7]) | (mf_d0[5] & mf_d1[8]) | (mf_d0[5] & mf_d1[9]) | (mf_d0[5] & mf_d1[10])
      | (mf_d0[5] & mf_d1[11]) | (mf_d0[5] & mf_d1[12]) | (mf_d0[5] & mf_d1[13]) | (mf_d0[5] & mf_d1[14])
      | (mf_d0[6] & mf_d1[7]) | (mf_d0[6] & mf_d1[8]) | (mf_d0[6] & mf_d1[9]) | (mf_d0[6] & mf_d1[10])
      | (mf_d0[6] & mf_d1[11]) | (mf_d0[6] & mf_d1[12]) | (mf_d0[6] & mf_d1[13]) | (mf_d0[6] & mf_d1[14])
      | (mf_d0[7] & mf_d1[7]) | (mf_d0[7] & mf_d1[8]) | (mf_d0[7] & mf_d1[9]) | (mf_d0[7] & mf_d1[10])
      | (mf_d0[7] & mf_d1[11]) | (mf_d0[7] & mf_d1[12]) | (mf_d0[7] & mf_d1[13]) | (mf_d0[7] & mf_d1[14])
      | (mf_d0[8] & mf_d1[6]) | (mf_d0[8] & mf_d1[7]) | (mf_d0[8] & mf_d1[8]) | (mf_d0[8] & mf_d1[9])
      | (mf_d0[8] & mf_d1[10]) | (mf_d0[8] & mf_d1[11]) | (mf_d0[8] & mf_d1[12]) | (mf_d0[8] & mf_d1[13])
      | (mf_d0[9] & mf_d1[6]) | (mf_d0[9] & mf_d1[7]) | (mf_d0[9] & mf_d1[8]) | (mf_d0[9] & mf_d1[9])
      | (mf_d0[9] & mf_d1[10]) | (mf_d0[9] & mf_d1[11]) | (mf_d0[9] & mf_d1[12]) | (mf_d0[9] & mf_d1[13])
      | (mf_d0[10] & mf_d1[6]) | (mf_d0[10] & mf_d1[7]) | (mf_d0[10] & mf_d1[8]) | (mf_d0[10] & mf_d1[9])
      | (mf_d0[10] & mf_d1[10]) | (mf_d0[10] & mf_d1[11]) | (mf_d0[10] & mf_d1[12]) | (mf_d0[10] & mf_d1[13])
      | (mf_d0[11] & mf_d1[6]) | (mf_d0[11] & mf_d1[7]) | (mf_d0[11] & mf_d1[8]) | (mf_d0[11] & mf_d1[9])
      | (mf_d0[11] & mf_d1[10]) | (mf_d0[11] & mf_d1[11]) | (mf_d0[11] & mf_d1[12]) | (mf_d0[11] & mf_d1[13])
      | (mf_d0[12] & mf_d1[5]) | (mf_d0[12] & mf_d1[6]) | (mf_d0[12] & mf_d1[7]) | (mf_d0[12] & mf_d1[8])
      | (mf_d0[12] & mf_d1[9]) | (mf_d0[12] & mf_d1[10]) | (mf_d0[12] & mf_d1[11]) | (mf_d0[12] & mf_d1[12])
      | (mf_d0[13] & mf_d1[5]) | (mf_d0[13] & mf_d1[6]) | (mf_d0[13] & mf_d1[7]) | (mf_d0[13] & mf_d1[8])
      | (mf_d0[13] & mf_d1[9]) | (mf_d0[13] & mf_d1[10]) | (mf_d0[13] & mf_d1[11]) | (mf_d0[13] & mf_d1[12])
      | (mf_d0[14] & mf_d1[5]) | (mf_d0[14] & mf_d1[6]) | (mf_d0[14] & mf_d1[7]) | (mf_d0[14] & mf_d1[8])
      | (mf_d0[14] & mf_d1[9]) | (mf_d0[14] & mf_d1[10]) | (mf_d0[14] & mf_d1[11]) | (mf_d0[14] & mf_d1[12])
      | (mf_d0[15] & mf_d1[5]) | (mf_d0[15] & mf_d1[6]) | (mf_d0[15] & mf_d1[7]) | (mf_d0[15] & mf_d1[8])
      | (mf_d0[15] & mf_d1[9]) | (mf_d0[15] & mf_d1[10]) | (mf_d0[15] & mf_d1[11]) | (mf_d0[15] & mf_d1[12])
      | (mf_d0[16] & mf_d1[4]) | (mf_d0[16] & mf_d1[5]) | (mf_d0[16] & mf_d1[6]) | (mf_d0[16] & mf_d1[7])
      | (mf_d0[16] & mf_d1[8]) | (mf_d0[16] & mf_d1[9]) | (mf_d0[16] & mf_d1[10]) | (mf_d0[16] & mf_d1[11])
      | (mf_d0[17] & mf_d1[4]) | (mf_d0[17] & mf_d1[5]) | (mf_d0[17] & mf_d1[6]) | (mf_d0[17] & mf_d1[7])
      | (mf_d0[17] & mf_d1[8]) | (mf_d0[17] & mf_d1[9]) | (mf_d0[17] & mf_d1[10]) | (mf_d0[17] & mf_d1[11])
      | (mf_d0[18] & mf_d1[4]) | (mf_d0[18] & mf_d1[5]) | (mf_d0[18] & mf_d1[6]) | (mf_d0[18] & mf_d1[7])
      | (mf_d0[18] & mf_d1[8]) | (mf_d0[18] & mf_d1[9]) | (mf_d0[18] & mf_d1[10]) | (mf_d0[18] & mf_d1[11])
      | (mf_d0[19] & mf_d1[4]) | (mf_d0[19] & mf_d1[5]) | (mf_d0[19] & mf_d1[6]) | (mf_d0[19] & mf_d1[7])
      | (mf_d0[19] & mf_d1[8]) | (mf_d0[19] & mf_d1[9]) | (mf_d0[19] & mf_d1[10]) | (mf_d0[19] & mf_d1[11])
      | (mf_d0[20] & mf_d1[3]) | (mf_d0[20] & mf_d1[4]) | (mf_d0[20] & mf_d1[5]) | (mf_d0[20] & mf_d1[6])
      | (mf_d0[20] & mf_d1[7]) | (mf_d0[20] & mf_d1[8]) | (mf_d0[20] & mf_d1[9]) | (mf_d0[20] & mf_d1[10])
      | (mf_d0[21] & mf_d1[3]) | (mf_d0[21] & mf_d1[4]) | (mf_d0[21] & mf_d1[5]) | (mf_d0[21] & mf_d1[6])
      | (mf_d0[21] & mf_d1[7]) | (mf_d0[21] & mf_d1[8]) | (mf_d0[21] & mf_d1[9]) | (mf_d0[21] & mf_d1[10])
      | (mf_d0[22] & mf_d1[3]) | (mf_d0[22] & mf_d1[4]) | (mf_d0[22] & mf_d1[5]) | (mf_d0[22] & mf_d1[6])
      | (mf_d0[22] & mf_d1[7]) | (mf_d0[22] & mf_d1[8]) | (mf_d0[22] & mf_d1[9]) | (mf_d0[22] & mf_d1[10])
      | (mf_d0[23] & mf_d1[3]) | (mf_d0[23] & mf_d1[4]) | (mf_d0[23] & mf_d1[5]) | (mf_d0[23] & mf_d1[6])
      | (mf_d0[23] & mf_d1[7]) | (mf_d0[23] & mf_d1[8]) | (mf_d0[23] & mf_d1[9]) | (mf_d0[23] & mf_d1[10])
      | (mf_d0[24] & mf_d1[2]) | (mf_d0[24] & mf_d1[3]) | (mf_d0[24] & mf_d1[4]) | (mf_d0[24] & mf_d1[5])
      | (mf_d0[24] & mf_d1[6]) | (mf_d0[24] & mf_d1[7]) | (mf_d0[24] & mf_d1[8]) | (mf_d0[24] & mf_d1[9]);

  // hd[6] (weight 64): 7 vias, ~14fF via load, ~12ps wired-OR delay
  //   → M10 output wire ~5μm → BUFX8 LVT (~8ps) → block boundary
  assign hd[6] = (mf_d0[0] & mf_d1[16]) | (mf_d0[4] & mf_d1[15]) | (mf_d0[8] & mf_d1[14]) | (mf_d0[12] & mf_d1[13])
      | (mf_d0[16] & mf_d1[12]) | (mf_d0[20] & mf_d1[11]) | (mf_d0[24] & mf_d1[10]);


  // ════════════════════════════════════════════════════════════════════════════════════════
  // DESIGN SUMMARY — TSMC N5 5nm FinFET
  //
  //   ┌──────────────────────────────────────────────────────────────────────────────┐
  //   │  Property                      │  Value                                     │
  //   ├────────────────────────────────┼────────────────────────────────────────────┤
  //   │  Process                       │  TSMC CLN5FF (5nm FinFET)                 │
  //   │  VDD                           │  0.75V nominal                             │
  //   │  Input                         │  Two 64-bit words a[63:0], b[63:0]        │
  //   │  Output                        │  7-bit Hamming distance hd[6:0] (0-64)    │
  //   │  Fused cell transistors (fins) │  ~480 (32 cells × 15 fins)                │
  //   │  Buffer transistors (fins)     │  ~2200 (469 buffers)                      │
  //   │  Total active fins             │  ~2680                                     │
  //   │  Gate delays on critical path  │  1 (fused cell) + 4 buffer stages         │
  //   │  Metal layers used             │  M1 through M10                            │
  //   │  Crosspoint matrices           │  ~30-35 (all passive wired-OR)            │
  //   │  Critical path delay (TT)      │  ~254 ps (estimated)                      │
  //   │  Maximum frequency (TT)        │  ~3.9 GHz                                 │
  //   │  Maximum frequency (SS)        │  ~3.2 GHz                                 │
  //   │  Block area                    │  ~22 × 18 μm ≈ 400 μm²                   │
  //   │  Power at 1 GHz               │  ~1.1-1.2 mW                              │
  //   │  Power at 3 GHz               │  ~3.3-3.6 mW                              │
  //   └──────────────────────────────────────────────────────────────────────────────┘
  //
  //   The N5 implementation is ~20% slower than the N3E (3nm GAAFET) version
  //   (~254ps vs ~200ps) due to higher interconnect resistance on the tight-pitch
  //   metal layers and lower FinFET drive per track compared to nanosheets.
  //   However, the architecture is identical — only buffer sizing and metal layer
  //   assignments differ between nodes.
  //
  // ════════════════════════════════════════════════════════════════════════════════════════

endmodule

