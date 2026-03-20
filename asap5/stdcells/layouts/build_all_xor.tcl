# ============================================================
# Build XOR2x1, XOR2x2, XNOR2x1, XNOR2x2 standard cells
# ASAP5 5nm GAA nanosheet in Magic VLSI
#
# 8T transmission-gate topology:
#   INV_B (2T) + INV_A (2T) + TG1 (2T) + TG2 (2T)
#
# Layout: 4 gate columns, CPP=44nm, cell height=140nm
# Gate positions: G1=22-38, G2=66-82, G3=110-126, G4=154-170
# Cell width: 192nm
#
# Conventions from existing inverter (asap5_inv.mag):
#   ndiff channel y=45-55, S/D y=20-45, bottom y=10-20
#   pdiff channel y=75-85, S/D y=85-120, top y=120-130
#   ndc contacts in S/D region y=20-45 (inset 2nm from diff edge)
#   pdc contacts in S/D region y=85-120
#   cogc (gate contact) y=58-72
#   poly y=5-58 (N extension) and y=72-135 (P extension)
#   M1 VDD y=126-140, M1 VSS y=0-14
#
# NMOS diffusion: two strips (inverters share VSS, TGs share Y)
#   Strip1 (inverters): x=0..98
#     n0(x=0-22)=BB | G1(B) | n1(x=38-66)=VSS | G2(A) | n2(x=82-98)=AB
#   Strip2 (TGs): x=108..192
#     n3(x=108-110)=A_src | G3 | n4(x=126-154)=Y | G4 | n5(x=170-192)=AB_src
#
#   For XOR:  G3_N=B, G4_N=BB.  n3=A_src, n5=AB_src
#   For XNOR: G3_N=B, G4_N=BB.  n3=AB_src, n5=A_src
#
# PMOS diffusion: same two strips
#   Strip1 (inverters): x=0..98
#     p0(x=0-22)=BB | G1(B) | p1(x=38-66)=VDD | G2(A) | p2(x=82-98)=AB
#   Strip2 (TGs): x=108..192
#     p3(x=108-110)=A_src | G3_P | p4(x=126-154)=Y | G4_P | p5(x=170-192)=AB_src
#
#   For XOR:  G3_P=BB, G4_P=B.  p3=A_src, p5=AB_src
#   For XNOR: G3_P=BB, G4_P=B.  p3=AB_src, p5=A_src
#
# Internal routing (M1 + M2):
#   BB: col1 N/P drain → col3/col4 TG gates (via M1 vertical + M2 horizontal)
#   AB: col2 N/P drain → col4 TG source (M2)
#   A:  input pin → col2 gate + col3 TG source (M2)
#   B:  input pin → col1 gate + col3/col4 TG gates
#   Y:  col3/col4 shared drain → output pin (M1)
#   VDD: col1/col2 PMOS shared source → top rail (M1)
#   VSS: col1/col2 NMOS shared source → bottom rail (M1)
#
# TG gate routing challenge:
#   Col3 NMOS gate=B, PMOS gate=BB (for XOR)
#   Col4 NMOS gate=BB, PMOS gate=B (for XOR)
#   Since poly is continuous N-to-P, a single poly stripe drives both N and P.
#   But TGs need DIFFERENT gates for N and P! This requires gate cut (gatecut layer).
#
#   Solution: Cut poly between N and P at col3 and col4, then route the two halves
#   separately to B and BB via cogc+M1+M2.
#
# Gate cut positions: between ndiff and pdiff regions
#   gatecut at y=60-70 (in the gap between N and P diffusions, y=55-75)
#   Col3: gatecut at x=110-126, y=60-70 → splits poly into N-half and P-half
#   Col4: gatecut at x=154-170, y=60-70 → splits poly into N-half and P-half
# ============================================================

proc build_xor_cell {cellname is_xnor is_x2} {
    puts "=== Building $cellname ==="

    # Create new cell
    load $cellname -force
    box 0 0 192 140

    # Cell dimensions
    set W 192
    set H 140

    # Gate x-positions (left edge of 16nm gate)
    set g1_l 22;  set g1_r 38
    set g2_l 66;  set g2_r 82
    set g3_l 110; set g3_r 126
    set g4_l 154; set g4_r 170

    # Y regions
    set nch_b 45;  set nch_t 55
    set pch_b 75;  set pch_t 85
    set nsd_b 20;  set nsd_t 45
    set psd_b 85;  set psd_t 120
    set nrail_b 10; set nrail_t 20
    set prail_b 120; set prail_t 130

    # Contact insets (2nm from diffusion edge)
    set ci 2

    # ===== NWELL =====
    box 0 65 $W $H
    paint nwell

    # ===== POLY (all 4 gates) =====
    # Col1 and Col2: continuous poly N-to-P (inverters, same gate signal)
    # N-side poly
    box $g1_l 5 $g1_r 58
    paint poly
    box $g2_l 5 $g2_r 58
    paint poly
    # P-side poly
    box $g1_l 72 $g1_r 135
    paint poly
    box $g2_l 72 $g2_r 135
    paint poly

    # Col3 and Col4: SPLIT poly (TGs need different N/P gates)
    # N-side poly only (y=5 to 58)
    box $g3_l 5 $g3_r 58
    paint poly
    box $g4_l 5 $g4_r 58
    paint poly
    # P-side poly only (y=72 to 135)
    box $g3_l 72 $g3_r 135
    paint poly
    box $g4_l 72 $g4_r 135
    paint poly

    # ===== NDIFF =====
    # Strip 1 (inverters): x=0 to x=98
    # Channel regions (continuous strip at y=45-55 through gates)
    box 0 $nch_b 98 $nch_t
    paint ndiff
    # S/D regions (y=20-45)
    box 0 $nsd_b [expr {$g1_l}] $nsd_t
    paint ndiff
    box $g1_r $nsd_b $g2_l $nsd_t
    paint ndiff
    box $g2_r $nsd_b 98 $nsd_t
    paint ndiff
    # Bottom rail extension
    box 0 $nrail_b 98 $nrail_t
    paint ndiff

    # Strip 2 (TGs): x=108 to x=192
    box 108 $nch_b $W $nch_t
    paint ndiff
    box 108 $nsd_b $g3_l $nsd_t
    paint ndiff
    box $g3_r $nsd_b $g4_l $nsd_t
    paint ndiff
    box $g4_r $nsd_b $W $nsd_t
    paint ndiff
    box 108 $nrail_b $W $nrail_t
    paint ndiff

    # ===== PDIFF =====
    # Strip 1 (inverters): x=0 to x=98
    box 0 $pch_b 98 $pch_t
    paint pdiff
    box 0 $psd_b [expr {$g1_l}] $psd_t
    paint pdiff
    box $g1_r $psd_b $g2_l $psd_t
    paint pdiff
    box $g2_r $psd_b 98 $psd_t
    paint pdiff
    box 0 $prail_b 98 $prail_t
    paint pdiff

    # Strip 2 (TGs): x=108 to x=192
    box 108 $pch_b $W $pch_t
    paint pdiff
    box 108 $psd_b $g3_l $psd_t
    paint pdiff
    box $g3_r $psd_b $g4_l $psd_t
    paint pdiff
    box $g4_r $psd_b $W $psd_t
    paint pdiff
    box 108 $prail_b $W $prail_t
    paint pdiff

    # ===== NDC (n-diffusion contacts) =====
    # Strip 1 S/D contacts
    # n0: BB (x=0+ci to g1_l-ci = 2 to 20)
    box [expr {0+$ci}] $nsd_b [expr {$g1_l-$ci}] $nsd_t
    paint ndc
    # n1: VSS (x=g1_r+ci to g2_l-ci = 40 to 64)
    box [expr {$g1_r+$ci}] $nsd_b [expr {$g2_l-$ci}] $nsd_t
    paint ndc
    # n2: AB (x=g2_r+ci to 98-ci = 84 to 96)
    box [expr {$g2_r+$ci}] $nsd_b [expr {98-$ci}] $nsd_t
    paint ndc

    # Strip 2 S/D contacts
    # n3: TG1_source (x=108+ci to g3_l-ci) -- very narrow, skip contact if too small
    # x=110 to 108... g3_l=110, so 108 to 110 is only 2nm. Too narrow for contact.
    # Need to adjust: make strip2 start earlier or extend S/D.
    # Let's extend strip2 leftward to x=100:
    # Actually let me reconsider the gap. Strip1 ends at x=98, strip2 can start at x=100.
    # Then n3 goes from 100 to 110 = 10nm. Still tight for a contact.
    # Let me widen: strip2 from x=96, but that overlaps with strip1 (ends at 98)...
    # Actually strip1 right S/D (AB) is at x=82-98. If we need more space for TG left S/D,
    # let me reconsider.
    #
    # Better approach: use a wider gap. Inverter strip: x=0-96, TG strip: x=100-192
    # G3 at x=110-126, so left S/D = x=100-110 = 10nm. Contact = 102-108 = 6nm. Marginal.
    # Or shift G3/G4 rightward. Let me use:
    #   G1=22-38, G2=66-82, G3=118-134, G4=162-178
    #   Cell width = 200nm
    # That gives: TG left S/D = 100-118 = 18nm, contact 102-116 = 14nm. OK.
    # TG mid S/D (Y) = 134-162 = 28nm. Good.
    # TG right S/D = 178-200 = 22nm. Good.
    # But cell width 200nm = same as inverter width for 1 gate? That seems wide for 4 gates.
    # Let me reconsider: 4 CPP = 176nm. With margins ~12nm each side = 200nm. Fine.

    # Actually, I realize I already erased some geometry. Let me restart this function
    # with corrected gate positions to allow proper contacts everywhere.
    # I'll abandon this paint approach and generate .mag files directly.

    puts "ERROR: need to recalculate geometry. Will generate .mag files directly."
}

# Instead of using paint commands, let's generate the .mag files as text
# This gives us precise control over every rectangle.

proc write_xor_mag {cellname is_xnor} {
    # Gate positions with proper spacing for contacts
    # G1=22-38, G2=66-82, G3=114-130, G4=158-174
    # Cell width = 196nm
    # Inverter strip: x=0-96 (n0=0-22, n1=38-66, n2=82-96)
    # Gap: 96-100 (no diffusion)
    # TG strip: x=100-196 (n3=100-114, n4=130-158, n5=174-196)

    set W 196
    set H 140

    set g1_l 22;  set g1_r 38
    set g2_l 66;  set g2_r 82
    set g3_l 114; set g3_r 130
    set g4_l 158; set g4_r 174

    # S/D node x-ranges
    # Strip1 (inverters)
    set n0_l 0;   set n0_r 22;   # BB
    set n1_l 38;  set n1_r 66;   # VSS
    set n2_l 82;  set n2_r 96;   # AB
    # Strip2 (TGs)
    set n3_l 100; set n3_r 114;  # TG1 source (A for XOR, AB for XNOR)
    set n4_l 130; set n4_r 158;  # Y (shared)
    set n5_l 174; set n5_r $W;   # TG2 source (AB for XOR, A for XNOR)

    # Same for PMOS
    set p0_l $n0_l; set p0_r $n0_r
    set p1_l $n1_l; set p1_r $n1_r
    set p2_l $n2_l; set p2_r $n2_r
    set p3_l $n3_l; set p3_r $n3_r
    set p4_l $n4_l; set p4_r $n4_r
    set p5_l $n5_l; set p5_r $n5_r

    # Contact inset
    set ci 2

    set fd [open "/Users/bruce/CLAUDE/asap5/stdcells/layouts/${cellname}.mag" w]

    puts $fd "magic"
    puts $fd "tech asap5"
    puts $fd "timestamp 1773900000"

    # -- NWELL --
    puts $fd "<< nwell >>"
    puts $fd "rect 0 65 $W $H"

    # -- POLY --
    # Inverter gates: continuous N-to-P
    puts $fd "<< poly >>"
    puts $fd "rect $g1_l 5 $g1_r 58"
    puts $fd "rect $g1_l 72 $g1_r 135"
    puts $fd "rect $g2_l 5 $g2_r 58"
    puts $fd "rect $g2_l 72 $g2_r 135"
    # TG gates: split N and P (separate poly pieces)
    puts $fd "rect $g3_l 5 $g3_r 58"
    puts $fd "rect $g3_l 72 $g3_r 135"
    puts $fd "rect $g4_l 5 $g4_r 58"
    puts $fd "rect $g4_l 72 $g4_r 135"

    # -- NDIFF --
    puts $fd "<< ndiff >>"
    # Strip 1 channel (y=45-55)
    puts $fd "rect 0 45 96 55"
    # Strip 1 S/D (y=20-45)
    puts $fd "rect $n0_l 20 $n0_r 45"
    puts $fd "rect $n1_l 20 $n1_r 45"
    puts $fd "rect $n2_l 20 $n2_r 45"
    # Strip 1 bottom (y=10-20)
    puts $fd "rect 0 10 96 20"
    # Strip 2 channel (y=45-55)
    puts $fd "rect 100 45 $W 55"
    # Strip 2 S/D (y=20-45)
    puts $fd "rect $n3_l 20 $n3_r 45"
    puts $fd "rect $n4_l 20 $n4_r 45"
    puts $fd "rect $n5_l 20 $n5_r 45"
    # Strip 2 bottom (y=10-20)
    puts $fd "rect 100 10 $W 20"

    # -- PDIFF --
    puts $fd "<< pdiff >>"
    # Strip 1 channel (y=75-85)
    puts $fd "rect 0 75 96 85"
    # Strip 1 S/D (y=85-120)
    puts $fd "rect $p0_l 85 $p0_r 120"
    puts $fd "rect $p1_l 85 $p1_r 120"
    puts $fd "rect $p2_l 85 $p2_r 120"
    # Strip 1 top (y=120-130)
    puts $fd "rect 0 120 96 130"
    # Strip 2 channel (y=75-85)
    puts $fd "rect 100 75 $W 85"
    # Strip 2 S/D (y=85-120)
    puts $fd "rect $p3_l 85 $p3_r 120"
    puts $fd "rect $p4_l 85 $p4_r 120"
    puts $fd "rect $p5_l 85 $p5_r 120"
    # Strip 2 top (y=120-130)
    puts $fd "rect 100 120 $W 130"

    # -- NDC (n-diffusion contacts) --
    puts $fd "<< ndc >>"
    puts $fd "rect [expr {$n0_l+$ci}] 20 [expr {$n0_r-$ci}] 45"
    puts $fd "rect [expr {$n1_l+$ci}] 20 [expr {$n1_r-$ci}] 45"
    puts $fd "rect [expr {$n2_l+$ci}] 20 [expr {$n2_r-$ci}] 45"
    puts $fd "rect [expr {$n3_l+$ci}] 20 [expr {$n3_r-$ci}] 45"
    puts $fd "rect [expr {$n4_l+$ci}] 20 [expr {$n4_r-$ci}] 45"
    puts $fd "rect [expr {$n5_l+$ci}] 20 [expr {$n5_r-$ci}] 45"

    # -- PDC (p-diffusion contacts) --
    puts $fd "<< pdc >>"
    puts $fd "rect [expr {$p0_l+$ci}] 85 [expr {$p0_r-$ci}] 120"
    puts $fd "rect [expr {$p1_l+$ci}] 85 [expr {$p1_r-$ci}] 120"
    puts $fd "rect [expr {$p2_l+$ci}] 85 [expr {$p2_r-$ci}] 120"
    puts $fd "rect [expr {$p3_l+$ci}] 85 [expr {$p3_r-$ci}] 120"
    puts $fd "rect [expr {$p4_l+$ci}] 85 [expr {$p4_r-$ci}] 120"
    puts $fd "rect [expr {$p5_l+$ci}] 85 [expr {$p5_r-$ci}] 120"

    # -- COGC (contact over gate) --
    # Only for inverter gates (col1, col2) where poly is continuous
    # For TG gates, we need separate N and P cogc contacts
    puts $fd "<< cogc >>"
    puts $fd "rect $g1_l 58 $g1_r 72"
    puts $fd "rect $g2_l 58 $g2_r 72"
    # TG gates: N-side cogc at y=50-58 (on N poly), P-side cogc at y=72-80 (on P poly)
    # Actually cogc connects poly to metal1. For split TG gates:
    # N-half cogc: on poly at top of N extension
    puts $fd "rect $g3_l 50 $g3_r 58"
    puts $fd "rect $g4_l 50 $g4_r 58"
    # P-half cogc: on poly at bottom of P extension
    puts $fd "rect $g3_l 72 $g3_r 80"
    puts $fd "rect $g4_l 72 $g4_r 80"

    # -- METAL1 --
    puts $fd "<< metal1 >>"
    # VDD rail (top)
    puts $fd "rect 0 126 $W 140"
    # VSS rail (bottom)
    puts $fd "rect 0 0 $W 14"

    # --- Power connections ---
    # VSS: n1 (NMOS shared source, x=38-66) → bottom rail
    puts $fd "rect [expr {$n1_l+$ci}] 14 [expr {$n1_r-$ci}] 20"
    puts $fd "rect [expr {$n1_l+$ci}] 20 [expr {$n1_r-$ci}] 45"

    # VDD: p1 (PMOS shared source, x=38-66) → top rail
    puts $fd "rect [expr {$p1_l+$ci}] 120 [expr {$p1_r-$ci}] 126"
    puts $fd "rect [expr {$p1_l+$ci}] 85 [expr {$p1_r-$ci}] 120"

    # --- BB signal (inverter B output) ---
    # n0 NMOS drain + p0 PMOS drain connected via M1 vertical
    # n0 contact: x=2-20, y=20-45 (on ndc)
    # p0 contact: x=2-20, y=85-120 (on pdc)
    puts $fd "rect [expr {$n0_l+$ci}] 20 [expr {$n0_r-$ci}] 45"
    puts $fd "rect [expr {$p0_l+$ci}] 85 [expr {$p0_r-$ci}] 120"
    # M1 vertical connecting N and P drains for BB
    puts $fd "rect 6 45 16 85"

    # --- AB signal (inverter A output) ---
    # n2 NMOS drain + p2 PMOS drain
    puts $fd "rect [expr {$n2_l+$ci}] 20 [expr {$n2_r-$ci}] 45"
    puts $fd "rect [expr {$p2_l+$ci}] 85 [expr {$p2_r-$ci}] 120"
    # M1 vertical connecting N and P drains for AB
    puts $fd "rect 86 45 92 85"

    # --- Y signal (TG shared drain) ---
    # n4 NMOS + p4 PMOS → Y output
    puts $fd "rect [expr {$n4_l+$ci}] 20 [expr {$n4_r-$ci}] 45"
    puts $fd "rect [expr {$p4_l+$ci}] 85 [expr {$p4_r-$ci}] 120"
    # M1 vertical connecting Y
    puts $fd "rect 138 45 148 85"

    # --- TG source contacts (M1 on ndc/pdc) ---
    # n3 (TG1 source)
    puts $fd "rect [expr {$n3_l+$ci}] 20 [expr {$n3_r-$ci}] 45"
    puts $fd "rect [expr {$p3_l+$ci}] 85 [expr {$p3_r-$ci}] 120"
    puts $fd "rect 104 45 110 85"

    # n5 (TG2 source)
    puts $fd "rect [expr {$n5_l+$ci}] 20 [expr {$n5_r-$ci}] 45"
    puts $fd "rect [expr {$p5_l+$ci}] 85 [expr {$p5_r-$ci}] 120"
    puts $fd "rect 178 45 188 85"

    # --- Inverter gate contacts (M1 on cogc) ---
    # G1 (B) gate contact at center of gap
    puts $fd "rect $g1_l 58 $g1_r 72"
    # G2 (A) gate contact
    puts $fd "rect $g2_l 58 $g2_r 72"

    # --- TG gate contacts (M1 on split cogc) ---
    # G3 N-half contact (y=50-58)
    puts $fd "rect $g3_l 50 $g3_r 58"
    # G3 P-half contact (y=72-80)
    puts $fd "rect $g3_l 72 $g3_r 80"
    # G4 N-half contact (y=50-58)
    puts $fd "rect $g4_l 50 $g4_r 58"
    # G4 P-half contact (y=72-80)
    puts $fd "rect $g4_l 72 $g4_r 80"

    # -- VIA1 and METAL2 for signal routing --
    puts $fd "<< via1 >>"

    # BB routing: from col1 output (M1 at x=6-16, y=60-70) to TG gates
    # Via1 on BB M1 vertical
    puts $fd "rect 8 62 14 68"

    # AB routing: from col2 output (M1 at x=86-92) to TG2 source
    # Via1 on AB M1 vertical
    puts $fd "rect 87 62 93 68"

    # A input: need to route from input to col3 TG source
    # We'll use M2 for A input routing
    # Via1 at G2 cogc (A gate) for A signal access
    puts $fd "rect 70 62 76 68"

    # B input: need to route to TG gates
    # Via1 at G1 cogc (B gate) for B signal access
    puts $fd "rect 26 62 32 68"

    # Y output: via1 at Y M1
    puts $fd "rect 140 62 146 68"

    # TG gate connections via M1-M2:
    # G3 N-half via
    puts $fd "rect 116 52 122 58"
    # G3 P-half via
    puts $fd "rect 116 72 122 78"
    # G4 N-half via
    puts $fd "rect 160 52 166 58"
    # G4 P-half via
    puts $fd "rect 160 72 166 78"

    # TG source vias (for A and AB routing)
    # n3/p3 TG1 source
    puts $fd "rect 104 62 110 68"
    # n5/p5 TG2 source
    puts $fd "rect 178 62 184 68"

    puts $fd "<< metal2 >>"

    # For XOR:
    #   G3: N-gate=B, P-gate=BB
    #   G4: N-gate=BB, P-gate=B
    #   TG1 source (n3/p3) = A
    #   TG2 source (n5/p5) = AB
    # For XNOR:
    #   G3: N-gate=B, P-gate=BB (same gates)
    #   G4: N-gate=BB, P-gate=B (same gates)
    #   TG1 source (n3/p3) = AB
    #   TG2 source (n5/p5) = A

    # BB signal M2 horizontal bus (y=62-68) from col1 output to TG gates
    # BB goes to: G3 P-half (BB), G4 N-half (BB)
    # Route at y=74-80 level (upper M2 track) -- no, let's use y=62-68 for BB
    # BB via at x=8-14. G3_P via at x=116-122,y=72-78. G4_N via at x=160-166,y=52-58.
    # These are at different y levels. Need M2 bus connecting them.
    # Use M2 track at y=74-78 for BB horizontal, with jogs:
    puts $fd "rect 8 60 14 70"
    # M2 from BB (x=8) → G3_P (x=116) at y=74-78
    puts $fd "rect 8 70 122 78"
    # M2 from G3_P → G4_N: need to connect y=74-78 at x=116-122 to y=52-58 at x=160-166
    # Vertical jog from y=52 to y=78 at x=160-166
    puts $fd "rect 122 52 166 78"

    # B signal M2 horizontal bus
    # B goes to: G3 N-half (B), G4 P-half (B)
    # B via at x=26-32, y=62-68. G3_N via at x=116-122,y=52-58. G4_P via at x=160-166,y=72-78.
    # Use M2 track at y=52-58 for B horizontal:
    puts $fd "rect 26 52 122 58"
    # B via access
    puts $fd "rect 26 58 32 68"
    # From G3_N (x=116,y=52) to G4_P (x=160,y=72): vertical jog
    # But BB already occupies x=122-166,y=52-78! Conflict!
    # Need to re-route. Let me use different y tracks.

    # Actually let me reconsider the M2 routing more carefully.
    # We have these signals to route on M2:
    # 1. BB: from via1@(8,62-68) to G3_P via1@(116,72-78) and G4_N via1@(160,52-58)
    # 2. B:  from via1@(26,62-68) to G3_N via1@(116,52-58) and G4_P via1@(160,72-78)
    # 3. A:  from via1@(70,62-68) to TG1_src via1@(104,62-68)
    # 4. AB: from via1@(87,62-68) to TG2_src via1@(178,62-68)
    # 5. Y:  via1@(140,62-68) for output
    #
    # Signals 3,4,5 are at y=62-68. Signals 1,2 need to reach y=52-58 and y=72-78.
    #
    # B and BB cross each other when routing to opposite TG halves.
    # This is the classic TG routing challenge. We need M2+M3 or clever layout.
    #
    # Simpler approach: route B and BB on two separate M2 y-tracks, using M1 jogs where needed.
    #
    # Let me reconsider the entire TG gate routing.
    # Alternative: instead of splitting every TG gate, what if we use a different column ordering?
    #
    # Reorder columns to avoid crossing:
    #   Col1: B inv (gate=B)
    #   Col2: TG1 (N=B, P=BB) - gate cut between N/P
    #   Col3: TG2 (N=BB, P=B) - gate cut between N/P
    #   Col4: A inv (gate=A)
    #
    # With this order:
    #   NMOS strip: all continuous from col1 to col4
    #     n0 | G1(B) | n1 | G2_N(B) | n2 | G3_N(BB) | n3 | G4(A) | n4
    #
    #   n0=BB (inv_B drain), n1=VSS/A?
    #   Hmm, sharing between inv_B source(VSS) and TG1_N...
    #   MN_invb: S=VSS, D=BB. MN_tg1: gate=B, S=A, D=Y.
    #   If col2=TG1: left=n1, right=n2. MN_tg1: S=A or D=Y on either side.
    #   n1 shared between invB.source(VSS) and tg1 left S/D(A or Y). Neither is VSS.
    #
    # This doesn't help with sharing. Let me just accept the split diffusion approach
    # and handle the crossing with one M2 track for each signal, using M1 for jogs.

    # REVISED M2 ROUTING PLAN:
    # M2 track 1 (y=78-84): BB horizontal
    # M2 track 2 (y=46-52): B horizontal
    # M2 track 3 (y=62-68): A, AB, Y horizontal
    #
    # Via1 positions adjusted:
    # BB: via1 at col1 output M1 → M2@y=78-84 → down to G3_P@y=72-78 → continue → down to G4_N@y=52-58
    # B: via1 at col1 gate M1 → M2@y=46-52 → to G3_N@y=52-58 → continue → to G4_P@y=72-78
    #
    # Hmm, we still have the crossing problem for the second endpoint.
    # BB needs to reach G4_N (y=52-58) and B needs to reach G4_P (y=72-78).
    # They have to cross in the vertical direction around col4.
    #
    # Solution: use M3 for one of the crossings, OR accept that in a 5nm process
    # we can route one signal on M2 and cross the other on M1 underneath.
    #
    # Actually simplest: put BB on M2 y=78-84 track, B on M2 y=46-52 track.
    # For the endpoints that are at the "wrong" y level, use short M1 vertical jogs
    # from M2 via1 down/up to the cogc contact.
    #
    # For BB reaching G4_N (needs y=52-58):
    #   M2 horizontal at y=78-84 reaches x=160 area
    #   Via1 down to M1 at x=160-166, y=78-84
    #   M1 vertical jog from y=58 down to y=78? No, M1 at that location might conflict.
    #
    # Actually this is getting complicated. Let me take a much simpler approach:
    # Use two separate cogc contacts (already split) and route each to the appropriate
    # M2 track directly:
    #   G3_N cogc connects to M1, via1, M2 B-track
    #   G3_P cogc connects to M1, via1, M2 BB-track
    #   G4_N cogc connects to M1, via1, M2 BB-track (different y from G3_N)
    #   G4_P cogc connects to M1, via1, M2 B-track (different y from G3_P)
    #
    # If B-track is at y=52-58 and BB-track is at y=72-78:
    #   G3_N (y=50-58) → via1 at y=52-58 → M2 B-track y=52-58 ✓ (same y)
    #   G3_P (y=72-80) → via1 at y=72-78 → M2 BB-track y=72-78 ✓ (same y)
    #   G4_N (y=50-58) → via1 at y=52-58 → needs M2 BB-track at y=72-78 ✗ (wrong y!)
    #   G4_P (y=72-80) → via1 at y=72-78 → needs M2 B-track at y=52-58 ✗ (wrong y!)
    #
    # The col4 connections are swapped from col3. That's the fundamental cross.
    # To solve: at col4, use M1 to connect G4_N cogc to a via1 that reaches M2 BB-track,
    # and G4_P cogc to a via1 that reaches M2 B-track.
    # But the cogc is at fixed y. We need M1 verticals to bridge:
    #   G4_N (y=50-58 M1 on cogc) → M1 extends up to y=72-78 → via1 → M2 BB-track
    #   G4_P (y=72-80 M1 on cogc) → M1 extends down to y=52-58 → via1 → M2 B-track
    # But these two M1 verticals would overlap/short at x=160-166, y=58-72!
    # They carry different signals (BB and B), so we can't let them overlap.
    #
    # Offset them in x:
    #   G4_N M1 vertical at x=160-164, from y=50 to y=78 → via1@(160-164,72-78)→M2 BB
    #   G4_P M1 vertical at x=166-170, from y=52 to y=80 → via1@(166-170,52-58)→M2 B
    # G4_N cogc at x=158-174 gives M1 at x=158-174. We can use x=158-163 for one and x=169-174 for other.
    # But the cogc is a single rectangle. The M1 on cogc covers the whole gate width.
    # We'd need to split the M1 into two halves, each carrying a different signal.
    # That means the cogc can't be a single piece either.
    #
    # This is getting very messy. Let me take a completely different approach.
    #
    # REVISED APPROACH: Don't split TG gates. Instead, use the same gate signal for
    # both N and P of each TG column, and rearrange which TG goes where.
    #
    # If col3 has gate=B (both N and P) and col4 has gate=BB (both N and P):
    #   Col3: both N and P gates = B
    #   Col4: both N and P gates = BB
    #
    # Then for TG1 (pass A when B=1): need N-gate=B, P-gate=BB
    #   But col3 has both gates=B, so we get N-gate=B ✓ but P-gate=B ✗ (need BB)
    #
    # That doesn't work for a transmission gate, which fundamentally needs complementary gates.
    #
    # FINAL APPROACH: Use M2 for one signal and M3 for the cross.
    # Route BB on M2 y=72-78 track from col1 to col3_P and col4_N
    # Route B on M2 y=52-58 track from col1 gate to col3_N and col4_P
    # At col4, BB needs to go from y=72-78 (M2) down to G4_N cogc at y=50-58:
    #   M2→via1→M1 vertical drop at x=160-164
    # At col4, B needs to go from y=52-58 (M2) up to G4_P cogc at y=72-80:
    #   Can't use M1 (would cross BB's M1 vertical at same x).
    #   Use M3: M2→via2→M3 at y=52-58 near col4, M3 runs vertically to y=72-78, M3→via2→M2→via1→M1.
    #   Too many layers.
    #
    # SIMPLEST CORRECT APPROACH:
    # At col4, use SEPARATE x positions for the two M1 vertical jogs:
    #   Left half of col4 poly (x=158-166): carries BB from M2 BB-track down to G4_N
    #   Right half of col4 poly (x=166-174): carries B from M2 B-track up to G4_P
    #   Split the col4 cogc into two pieces!
    #   G4_N cogc: x=158-164, y=50-58, M1: x=158-164, y=50-78, via1: x=158-164,y=72-78 → M2 BB
    #   G4_P cogc: x=166-174, y=72-80, M1: x=166-174, y=52-80, via1: x=166-174,y=52-58 → M2 B
    #   The M1 pieces are at different x ranges so they don't short!

    # OK that works. Let me restart the file write with this plan.

    close $fd
}

# Let me close and write .mag files directly with a cleaner script

quit -noprompt
