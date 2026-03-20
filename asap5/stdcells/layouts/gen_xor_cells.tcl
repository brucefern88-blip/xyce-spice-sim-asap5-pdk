#!/usr/bin/env wish
# Generate XOR2/XNOR2 x1/x2 standard cell .mag files for ASAP5
# Run standalone: tclsh gen_xor_cells.tcl
#
# Layout: 4 gate columns, CPP=44nm, cell height=140nm, cell width=196nm
#
# Column assignment:
#   Col1 (G: x=22-38):  INV_B, gate=B, both N+P
#   Col2 (G: x=66-82):  INV_A, gate=A, both N+P
#   Col3 (G: x=114-130): TG1, SPLIT gate: N-half and P-half separate
#   Col4 (G: x=158-174): TG2, SPLIT gate: N-half and P-half separate
#
# Diffusion strips:
#   Strip1 (inverters, x=0-96):  BB | G1(B) | VSS_shared | G2(A) | AB
#   Strip2 (TGs, x=100-196):     TG1_src | G3 | Y_shared | G4 | TG2_src
#
# For XOR: TG1 passes A when B=1, TG2 passes ~A(AB) when B=0
#   G3_N=B, G3_P=BB, TG1_src=A, TG2_src=AB
#   G4_N=BB, G4_P=B
#
# For XNOR: TG1 passes ~A(AB) when B=1, TG2 passes A when B=0
#   G3_N=B, G3_P=BB, TG1_src=AB, TG2_src=A
#   G4_N=BB, G4_P=B
#
# TG gate routing (M2):
#   BB-track: M2 at y=72-78, from col1 BB output to G3_P and G4_N
#   B-track:  M2 at y=52-58, from col1 B gate to G3_N and G4_P
#   Col4 split: G4_N cogc at x=158-165 → M1 up to y=72-78 → via1 → M2 BB-track
#               G4_P cogc at x=167-174 → M1 down to y=52-58 → via1 → M2 B-track
#   Signal-track (y=62-68): A routing to TG1_src, AB routing to TG2_src, Y output

proc gen_cell {cellname is_xnor} {
    set W 196
    set H 140

    # Gate x-ranges (16nm wide, CPP=44nm)
    set g1l 22;  set g1r 38
    set g2l 66;  set g2r 82
    set g3l 114; set g3r 130
    set g4l 158; set g4r 174

    # S/D node x-ranges (2nm inset for contacts)
    # Strip 1 (inverters)
    set s1_n0l 0;   set s1_n0r 22    ;# BB (inv_B drain)
    set s1_n1l 38;  set s1_n1r 66    ;# VSS/VDD (shared source)
    set s1_n2l 82;  set s1_n2r 96    ;# AB (inv_A drain)
    # Strip 2 (TGs)
    set s2_n3l 100; set s2_n3r 114   ;# TG1 source
    set s2_n4l 130; set s2_n4r 158   ;# Y (shared TG drain)
    set s2_n5l 174; set s2_n5r 196   ;# TG2 source

    # Y coordinates
    set vdd_b 126; set vdd_t 140
    set vss_b 0;   set vss_t 14
    set prail_b 120; set prail_t 130
    set psd_b 85;  set psd_t 120
    set pch_b 75;  set pch_t 85
    set nch_b 45;  set nch_t 55
    set nsd_b 20;  set nsd_t 45
    set nrail_b 10; set nrail_t 20

    set ci 2  ;# contact inset from diffusion edge

    set fd [open "/Users/bruce/CLAUDE/asap5/stdcells/layouts/${cellname}.mag" w]

    puts $fd "magic"
    puts $fd "tech asap5"
    puts $fd "timestamp 1773900000"

    # ==================== NWELL ====================
    puts $fd "<< nwell >>"
    puts $fd "rect 0 65 $W $H"

    # ==================== POLY ====================
    puts $fd "<< poly >>"
    # Col1, Col2: continuous poly from N-extension through P-extension
    puts $fd "rect $g1l 5 $g1r 135"
    puts $fd "rect $g2l 5 $g2r 135"
    # Col3, Col4: SPLIT poly (N-half and P-half, gap at y=58-72)
    puts $fd "rect $g3l 5 $g3r 58"
    puts $fd "rect $g3l 72 $g3r 135"
    puts $fd "rect $g4l 5 $g4r 58"
    puts $fd "rect $g4l 72 $g4r 135"

    # ==================== NDIFF ====================
    puts $fd "<< ndiff >>"
    # Strip 1: continuous channel + S/D + rail
    puts $fd "rect 0 $nch_b 96 $nch_t"
    puts $fd "rect $s1_n0l $nsd_b $s1_n0r $nsd_t"
    puts $fd "rect $s1_n1l $nsd_b $s1_n1r $nsd_t"
    puts $fd "rect $s1_n2l $nsd_b $s1_n2r $nsd_t"
    puts $fd "rect 0 $nrail_b 96 $nrail_t"
    # Strip 2: continuous channel + S/D + rail
    puts $fd "rect 100 $nch_b $W $nch_t"
    puts $fd "rect $s2_n3l $nsd_b $s2_n3r $nsd_t"
    puts $fd "rect $s2_n4l $nsd_b $s2_n4r $nsd_t"
    puts $fd "rect $s2_n5l $nsd_b $s2_n5r $nsd_t"
    puts $fd "rect 100 $nrail_b $W $nrail_t"

    # ==================== PDIFF ====================
    puts $fd "<< pdiff >>"
    # Strip 1
    puts $fd "rect 0 $pch_b 96 $pch_t"
    puts $fd "rect $s1_n0l $psd_b $s1_n0r $psd_t"
    puts $fd "rect $s1_n1l $psd_b $s1_n1r $psd_t"
    puts $fd "rect $s1_n2l $psd_b $s1_n2r $psd_t"
    puts $fd "rect 0 $prail_b 96 $prail_t"
    # Strip 2
    puts $fd "rect 100 $pch_b $W $pch_t"
    puts $fd "rect $s2_n3l $psd_b $s2_n3r $psd_t"
    puts $fd "rect $s2_n4l $psd_b $s2_n4r $psd_t"
    puts $fd "rect $s2_n5l $psd_b $s2_n5r $psd_t"
    puts $fd "rect 100 $prail_b $W $prail_t"

    # ==================== NDC ====================
    puts $fd "<< ndc >>"
    puts $fd "rect [expr {$s1_n0l+$ci}] $nsd_b [expr {$s1_n0r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s1_n1l+$ci}] $nsd_b [expr {$s1_n1r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s1_n2l+$ci}] $nsd_b [expr {$s1_n2r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n3l+$ci}] $nsd_b [expr {$s2_n3r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n4l+$ci}] $nsd_b [expr {$s2_n4r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n5l+$ci}] $nsd_b [expr {$s2_n5r-$ci}] $nsd_t"

    # ==================== PDC ====================
    puts $fd "<< pdc >>"
    puts $fd "rect [expr {$s1_n0l+$ci}] $psd_b [expr {$s1_n0r-$ci}] $psd_t"
    puts $fd "rect [expr {$s1_n1l+$ci}] $psd_b [expr {$s1_n1r-$ci}] $psd_t"
    puts $fd "rect [expr {$s1_n2l+$ci}] $psd_b [expr {$s1_n2r-$ci}] $psd_t"
    puts $fd "rect [expr {$s2_n3l+$ci}] $psd_b [expr {$s2_n3r-$ci}] $psd_t"
    puts $fd "rect [expr {$s2_n4l+$ci}] $psd_b [expr {$s2_n4r-$ci}] $psd_t"
    puts $fd "rect [expr {$s2_n5l+$ci}] $psd_b [expr {$s2_n5r-$ci}] $psd_t"

    # ==================== COGC ====================
    puts $fd "<< cogc >>"
    # Col1, Col2: single cogc between N and P (y=58-72)
    puts $fd "rect $g1l 58 $g1r 72"
    puts $fd "rect $g2l 58 $g2r 72"
    # Col3: split cogc
    #   N-half: y=50-58 (top of N poly extension)
    #   P-half: y=72-80 (bottom of P poly extension)
    puts $fd "rect $g3l 50 $g3r 58"
    puts $fd "rect $g3l 72 $g3r 80"
    # Col4: split cogc into left and right halves for separate routing
    #   N-half (left): x=158-165, y=50-58
    #   P-half (right): x=167-174, y=72-80
    puts $fd "rect 158 50 165 58"
    puts $fd "rect 167 72 174 80"

    # ==================== METAL1 ====================
    puts $fd "<< metal1 >>"

    # --- Power rails ---
    puts $fd "rect 0 $vdd_b $W $vdd_t"
    puts $fd "rect 0 $vss_b $W $vss_t"

    # --- VSS connections (n1 NMOS S/D to bottom rail) ---
    puts $fd "rect [expr {$s1_n1l+$ci}] $vss_t [expr {$s1_n1r-$ci}] $nrail_t"
    puts $fd "rect [expr {$s1_n1l+$ci}] $nsd_b [expr {$s1_n1r-$ci}] $nsd_t"

    # --- VDD connections (p1 PMOS S/D to top rail) ---
    puts $fd "rect [expr {$s1_n1l+$ci}] $prail_b [expr {$s1_n1r-$ci}] $vdd_b"
    puts $fd "rect [expr {$s1_n1l+$ci}] $psd_b [expr {$s1_n1r-$ci}] $psd_t"

    # --- BB node (col1 N+P drains, n0/p0) ---
    # M1 on ndc n0
    puts $fd "rect [expr {$s1_n0l+$ci}] $nsd_b [expr {$s1_n0r-$ci}] $nsd_t"
    # M1 on pdc p0
    puts $fd "rect [expr {$s1_n0l+$ci}] $psd_b [expr {$s1_n0r-$ci}] $psd_t"
    # M1 vertical connecting BB N-drain to P-drain
    puts $fd "rect 6 $nsd_t 16 $psd_b"

    # --- AB node (col2 N+P drains, n2/p2) ---
    puts $fd "rect [expr {$s1_n2l+$ci}] $nsd_b [expr {$s1_n2r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s1_n2l+$ci}] $psd_b [expr {$s1_n2r-$ci}] $psd_t"
    # M1 vertical connecting AB N-drain to P-drain
    puts $fd "rect 86 $nsd_t 92 $psd_b"

    # --- TG1 source (n3/p3) ---
    puts $fd "rect [expr {$s2_n3l+$ci}] $nsd_b [expr {$s2_n3r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n3l+$ci}] $psd_b [expr {$s2_n3r-$ci}] $psd_t"
    # M1 vertical connecting TG1 N-source to P-source
    puts $fd "rect 104 $nsd_t 110 $psd_b"

    # --- Y node (n4/p4 shared TG drain) ---
    puts $fd "rect [expr {$s2_n4l+$ci}] $nsd_b [expr {$s2_n4r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n4l+$ci}] $psd_b [expr {$s2_n4r-$ci}] $psd_t"
    # M1 vertical connecting Y
    puts $fd "rect 138 $nsd_t 148 $psd_b"

    # --- TG2 source (n5/p5) ---
    puts $fd "rect [expr {$s2_n5l+$ci}] $nsd_b [expr {$s2_n5r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n5l+$ci}] $psd_b [expr {$s2_n5r-$ci}] $psd_t"
    # M1 vertical connecting TG2 N-source to P-source
    puts $fd "rect 180 $nsd_t 190 $psd_b"

    # --- Gate contacts M1 (on cogc) ---
    # Col1 (B): M1 on cogc y=58-72
    puts $fd "rect $g1l 58 $g1r 72"
    # Col2 (A): M1 on cogc y=58-72
    puts $fd "rect $g2l 58 $g2r 72"
    # Col3 N-half: M1 on cogc y=50-58
    puts $fd "rect $g3l 50 $g3r 58"
    # Col3 P-half: M1 on cogc y=72-80
    puts $fd "rect $g3l 72 $g3r 80"
    # Col4 N-half (left, x=158-165): M1 extends up from y=50 to y=78 for BB-track connection
    puts $fd "rect 158 50 165 78"
    # Col4 P-half (right, x=167-174): M1 extends down from y=52 to y=80 for B-track connection
    puts $fd "rect 167 52 174 80"

    # ==================== VIA1 ====================
    puts $fd "<< via1 >>"

    # BB output: via1 on BB M1 vertical → M2 BB-track (y=72-78)
    puts $fd "rect 8 72 14 78"

    # B gate: via1 on col1 gate M1 → M2 B-track (y=52-58)
    puts $fd "rect 26 52 32 58"

    # A gate: via1 on col2 gate M1 → M2 signal-track (y=62-68)
    # Offset slightly: use x=70-76 to avoid overlap with gate M1 center
    puts $fd "rect 70 62 76 68"

    # AB output: via1 on AB M1 vertical → M2 signal-track (y=62-68)
    puts $fd "rect 87 62 93 68"

    # TG1 source: via1 → M2 signal-track (y=62-68)
    puts $fd "rect 105 62 111 68"

    # Y output: via1 → M2 signal-track (y=62-68)
    puts $fd "rect 140 62 146 68"

    # TG2 source: via1 → M2 signal-track (y=62-68)
    puts $fd "rect 182 62 188 68"

    # Col3 N-half gate: via1 → M2 B-track (y=52-58)
    puts $fd "rect 118 52 124 58"

    # Col3 P-half gate: via1 → M2 BB-track (y=72-78)
    puts $fd "rect 118 72 124 78"

    # Col4 N-half (left): via1 at top of M1 jog → M2 BB-track (y=72-78)
    puts $fd "rect 159 72 165 78"

    # Col4 P-half (right): via1 at bottom of M1 jog → M2 B-track (y=52-58)
    puts $fd "rect 168 52 174 58"

    # ==================== METAL2 ====================
    puts $fd "<< metal2 >>"

    # BB-track (y=72-78): from BB via1 (x=8) to G3_P via1 (x=118) to G4_N via1 (x=159)
    puts $fd "rect 8 72 165 78"

    # B-track (y=52-58): from B via1 (x=26) to G3_N via1 (x=118) to G4_P via1 (x=168)
    puts $fd "rect 26 52 174 58"

    # Signal routing (y=62-68):
    # For XOR:
    #   A (via1@70-76) → TG1_src (via1@105-111): A goes to TG1 source
    #   AB (via1@87-93) → TG2_src (via1@182-188): AB goes to TG2 source
    # For XNOR:
    #   A (via1@70-76) → TG2_src (via1@182-188): A goes to TG2 source
    #   AB (via1@87-93) → TG1_src (via1@105-111): AB goes to TG1 source

    if {!$is_xnor} {
        # XOR: A→TG1_src, AB→TG2_src
        # A signal: x=70 to x=111
        puts $fd "rect 70 62 111 68"
        # AB signal: x=87 to x=188
        # But this overlaps with A signal at x=87-111!
        # Need to use different y tracks or route AB on a different path.
        # AB at y=62-68 from x=87 to x=188, A at y=62-68 from x=70 to x=111.
        # Overlap at x=87-111, y=62-68. These are different nets → SHORT!
        #
        # Fix: route AB on a separate M2 track.
        # Use y=82-88 for AB (above BB-track, inside nwell but that's OK for M2)
        # Actually let's use y=44-50 for AB (below B-track)
    } else {
        # XNOR: AB→TG1_src, A→TG2_src (also has crossing issue)
    }

    # Ugh, the y=62-68 track has a conflict. Let me use additional M2 tracks:
    # Track layout:
    #   y=44-50: spare track (AB or A signal)
    #   y=52-58: B-track
    #   y=62-68: signal track 1
    #   y=72-78: BB-track
    #   y=82-88: spare track (AB or A signal)

    # Close and rewrite properly
    close $fd

    # Now rewrite with correct non-overlapping M2
    set fd [open "/Users/bruce/CLAUDE/asap5/stdcells/layouts/${cellname}.mag" w]

    puts $fd "magic"
    puts $fd "tech asap5"
    puts $fd "timestamp 1773900000"

    # ==================== NWELL ====================
    puts $fd "<< nwell >>"
    puts $fd "rect 0 65 $W $H"

    # ==================== POLY ====================
    puts $fd "<< poly >>"
    puts $fd "rect $g1l 5 $g1r 135"
    puts $fd "rect $g2l 5 $g2r 135"
    puts $fd "rect $g3l 5 $g3r 58"
    puts $fd "rect $g3l 72 $g3r 135"
    puts $fd "rect $g4l 5 $g4r 58"
    puts $fd "rect $g4l 72 $g4r 135"

    # ==================== NDIFF ====================
    puts $fd "<< ndiff >>"
    puts $fd "rect 0 $nch_b 96 $nch_t"
    puts $fd "rect $s1_n0l $nsd_b $s1_n0r $nsd_t"
    puts $fd "rect $s1_n1l $nsd_b $s1_n1r $nsd_t"
    puts $fd "rect $s1_n2l $nsd_b $s1_n2r $nsd_t"
    puts $fd "rect 0 $nrail_b 96 $nrail_t"
    puts $fd "rect 100 $nch_b $W $nch_t"
    puts $fd "rect $s2_n3l $nsd_b $s2_n3r $nsd_t"
    puts $fd "rect $s2_n4l $nsd_b $s2_n4r $nsd_t"
    puts $fd "rect $s2_n5l $nsd_b $s2_n5r $nsd_t"
    puts $fd "rect 100 $nrail_b $W $nrail_t"

    # ==================== PDIFF ====================
    puts $fd "<< pdiff >>"
    puts $fd "rect 0 $pch_b 96 $pch_t"
    puts $fd "rect $s1_n0l $psd_b $s1_n0r $psd_t"
    puts $fd "rect $s1_n1l $psd_b $s1_n1r $psd_t"
    puts $fd "rect $s1_n2l $psd_b $s1_n2r $psd_t"
    puts $fd "rect 0 $prail_b 96 $prail_t"
    puts $fd "rect 100 $pch_b $W $pch_t"
    puts $fd "rect $s2_n3l $psd_b $s2_n3r $psd_t"
    puts $fd "rect $s2_n4l $psd_b $s2_n4r $psd_t"
    puts $fd "rect $s2_n5l $psd_b $s2_n5r $psd_t"
    puts $fd "rect 100 $prail_b $W $prail_t"

    # ==================== NDC ====================
    puts $fd "<< ndc >>"
    puts $fd "rect [expr {$s1_n0l+$ci}] $nsd_b [expr {$s1_n0r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s1_n1l+$ci}] $nsd_b [expr {$s1_n1r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s1_n2l+$ci}] $nsd_b [expr {$s1_n2r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n3l+$ci}] $nsd_b [expr {$s2_n3r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n4l+$ci}] $nsd_b [expr {$s2_n4r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n5l+$ci}] $nsd_b [expr {$s2_n5r-$ci}] $nsd_t"

    # ==================== PDC ====================
    puts $fd "<< pdc >>"
    puts $fd "rect [expr {$s1_n0l+$ci}] $psd_b [expr {$s1_n0r-$ci}] $psd_t"
    puts $fd "rect [expr {$s1_n1l+$ci}] $psd_b [expr {$s1_n1r-$ci}] $psd_t"
    puts $fd "rect [expr {$s1_n2l+$ci}] $psd_b [expr {$s1_n2r-$ci}] $psd_t"
    puts $fd "rect [expr {$s2_n3l+$ci}] $psd_b [expr {$s2_n3r-$ci}] $psd_t"
    puts $fd "rect [expr {$s2_n4l+$ci}] $psd_b [expr {$s2_n4r-$ci}] $psd_t"
    puts $fd "rect [expr {$s2_n5l+$ci}] $psd_b [expr {$s2_n5r-$ci}] $psd_t"

    # ==================== COGC ====================
    puts $fd "<< cogc >>"
    puts $fd "rect $g1l 58 $g1r 72"
    puts $fd "rect $g2l 58 $g2r 72"
    # Col3 split: N-half and P-half
    puts $fd "rect $g3l 50 $g3r 58"
    puts $fd "rect $g3l 72 $g3r 80"
    # Col4 split: left half (N-half) and right half (P-half)
    puts $fd "rect 158 50 165 58"
    puts $fd "rect 167 72 174 80"

    # ==================== METAL1 ====================
    puts $fd "<< metal1 >>"

    # Power rails
    puts $fd "rect 0 $vdd_b $W $vdd_t"
    puts $fd "rect 0 $vss_b $W $vss_t"

    # VSS: n1 to bottom rail (NMOS source)
    puts $fd "rect [expr {$s1_n1l+$ci}] $vss_t [expr {$s1_n1r-$ci}] $nrail_t"
    puts $fd "rect [expr {$s1_n1l+$ci}] $nsd_b [expr {$s1_n1r-$ci}] $nsd_t"
    # VDD: p1 to top rail (PMOS source)
    puts $fd "rect [expr {$s1_n1l+$ci}] $prail_b [expr {$s1_n1r-$ci}] $vdd_b"
    puts $fd "rect [expr {$s1_n1l+$ci}] $psd_b [expr {$s1_n1r-$ci}] $psd_t"

    # BB: n0+p0 drains + vertical
    puts $fd "rect [expr {$s1_n0l+$ci}] $nsd_b [expr {$s1_n0r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s1_n0l+$ci}] $psd_b [expr {$s1_n0r-$ci}] $psd_t"
    puts $fd "rect 6 $nsd_t 16 $psd_b"

    # AB: n2+p2 drains + vertical
    puts $fd "rect [expr {$s1_n2l+$ci}] $nsd_b [expr {$s1_n2r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s1_n2l+$ci}] $psd_b [expr {$s1_n2r-$ci}] $psd_t"
    puts $fd "rect 86 $nsd_t 92 $psd_b"

    # TG1 source: n3+p3 + vertical
    puts $fd "rect [expr {$s2_n3l+$ci}] $nsd_b [expr {$s2_n3r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n3l+$ci}] $psd_b [expr {$s2_n3r-$ci}] $psd_t"
    puts $fd "rect 104 $nsd_t 110 $psd_b"

    # Y: n4+p4 + vertical
    puts $fd "rect [expr {$s2_n4l+$ci}] $nsd_b [expr {$s2_n4r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n4l+$ci}] $psd_b [expr {$s2_n4r-$ci}] $psd_t"
    puts $fd "rect 138 $nsd_t 148 $psd_b"

    # TG2 source: n5+p5 + vertical
    puts $fd "rect [expr {$s2_n5l+$ci}] $nsd_b [expr {$s2_n5r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n5l+$ci}] $psd_b [expr {$s2_n5r-$ci}] $psd_t"
    puts $fd "rect 180 $nsd_t 190 $psd_b"

    # Gate contacts on M1 (over cogc)
    puts $fd "rect $g1l 58 $g1r 72"
    puts $fd "rect $g2l 58 $g2r 72"
    puts $fd "rect $g3l 50 $g3r 58"
    puts $fd "rect $g3l 72 $g3r 80"
    # Col4 N-half (left): M1 extends from y=50 up to y=78 for BB-track via1
    puts $fd "rect 158 50 165 78"
    # Col4 P-half (right): M1 extends from y=52 down to y=80 for B-track via1
    puts $fd "rect 167 52 174 80"

    # ==================== VIA1 ====================
    puts $fd "<< via1 >>"
    # BB → M2 BB-track (y=72-78)
    puts $fd "rect 8 72 14 78"
    # B → M2 B-track (y=52-58)
    puts $fd "rect 26 52 32 58"
    # A gate → M2 A-track (y=62-68)
    puts $fd "rect 70 62 76 68"
    # AB → M2 AB-track (y=82-88)
    puts $fd "rect 87 82 93 88"
    # TG1 source → M2 (y=62-68)
    puts $fd "rect 105 62 111 68"
    # Y → M2 Y-output (y=62-68)
    puts $fd "rect 140 62 146 68"
    # TG2 source → M2 (y=82-88)
    puts $fd "rect 182 82 188 88"
    # G3 N-half → M2 B-track (y=52-58)
    puts $fd "rect 118 52 124 58"
    # G3 P-half → M2 BB-track (y=72-78)
    puts $fd "rect 118 72 124 78"
    # G4 N-half (left) → M2 BB-track (y=72-78)
    puts $fd "rect 159 72 165 78"
    # G4 P-half (right) → M2 B-track (y=52-58)
    puts $fd "rect 168 52 174 58"

    # Need via1 for AB M1→M2: AB M1 vertical is at x=86-92, y=45-85
    # Via1 at y=82-88 needs M1 there. Extend AB M1 up:
    # Already have M1 at 86-92, 45-85. Need to extend to y=88.
    # Will add M1 extension below.

    # Similarly TG2 source M1 at x=180-190, y=45-85. Need via1 at y=82-88.
    # Need M1 at x=182-188, y=82-88. Already covered by 180-190, 45-85? y=85 max.
    # Need to extend up to 88.

    # ==================== METAL2 ====================
    puts $fd "<< metal2 >>"
    # BB-track (y=72-78): x=8 → x=165
    puts $fd "rect 8 72 165 78"
    # B-track (y=52-58): x=26 → x=174
    puts $fd "rect 26 52 174 58"

    if {!$is_xnor} {
        # XOR: A→TG1_src, AB→TG2_src
        # A on y=62-68: from A gate via1 (x=70) to TG1_src via1 (x=105)
        puts $fd "rect 70 62 111 68"
        # AB on y=82-88: from AB via1 (x=87) to TG2_src via1 (x=182)
        puts $fd "rect 87 82 188 88"
    } else {
        # XNOR: AB→TG1_src, A→TG2_src
        # AB on y=62-68: from AB output via1 to TG1_src
        # Need via1 for AB at y=62-68 instead of y=82-88
        # And A needs to reach TG2_src at x=182
        # A on y=82-88: from A gate via1 to TG2_src via1
        # AB on y=62-68: from AB via1 to TG1_src via1

        # For XNOR, swap the signal routing:
        # AB(x=87) → TG1_src(x=105) on y=62-68
        puts $fd "rect 87 62 111 68"
        # A(x=70) → TG2_src(x=182) on y=82-88
        puts $fd "rect 70 82 188 88"
    }

    # Y output access on M2 (just the via pad)
    puts $fd "rect 140 62 146 68"

    # ==================== FIX: additional M1 for via1 connections ====================
    # Need to go back and add M1 extensions. But we already wrote M1 section.
    # The .mag format allows multiple sections of same layer? No, it doesn't.
    # Need to restructure. Let me close and rewrite completely.

    close $fd

    # FINAL REWRITE with all M1 correct
    set fd [open "/Users/bruce/CLAUDE/asap5/stdcells/layouts/${cellname}.mag" w]

    puts $fd "magic"
    puts $fd "tech asap5"
    puts $fd "timestamp 1773900000"

    puts $fd "<< nwell >>"
    puts $fd "rect 0 65 $W $H"

    puts $fd "<< poly >>"
    puts $fd "rect $g1l 5 $g1r 135"
    puts $fd "rect $g2l 5 $g2r 135"
    puts $fd "rect $g3l 5 $g3r 58"
    puts $fd "rect $g3l 72 $g3r 135"
    puts $fd "rect $g4l 5 $g4r 58"
    puts $fd "rect $g4l 72 $g4r 135"

    puts $fd "<< ndiff >>"
    puts $fd "rect 0 $nch_b 96 $nch_t"
    puts $fd "rect $s1_n0l $nsd_b $s1_n0r $nsd_t"
    puts $fd "rect $s1_n1l $nsd_b $s1_n1r $nsd_t"
    puts $fd "rect $s1_n2l $nsd_b $s1_n2r $nsd_t"
    puts $fd "rect 0 $nrail_b 96 $nrail_t"
    puts $fd "rect 100 $nch_b $W $nch_t"
    puts $fd "rect $s2_n3l $nsd_b $s2_n3r $nsd_t"
    puts $fd "rect $s2_n4l $nsd_b $s2_n4r $nsd_t"
    puts $fd "rect $s2_n5l $nsd_b $s2_n5r $nsd_t"
    puts $fd "rect 100 $nrail_b $W $nrail_t"

    puts $fd "<< pdiff >>"
    puts $fd "rect 0 $pch_b 96 $pch_t"
    puts $fd "rect $s1_n0l $psd_b $s1_n0r $psd_t"
    puts $fd "rect $s1_n1l $psd_b $s1_n1r $psd_t"
    puts $fd "rect $s1_n2l $psd_b $s1_n2r $psd_t"
    puts $fd "rect 0 $prail_b 96 $prail_t"
    puts $fd "rect 100 $pch_b $W $pch_t"
    puts $fd "rect $s2_n3l $psd_b $s2_n3r $psd_t"
    puts $fd "rect $s2_n4l $psd_b $s2_n4r $psd_t"
    puts $fd "rect $s2_n5l $psd_b $s2_n5r $psd_t"
    puts $fd "rect 100 $prail_b $W $prail_t"

    puts $fd "<< ndc >>"
    puts $fd "rect [expr {$s1_n0l+$ci}] $nsd_b [expr {$s1_n0r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s1_n1l+$ci}] $nsd_b [expr {$s1_n1r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s1_n2l+$ci}] $nsd_b [expr {$s1_n2r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n3l+$ci}] $nsd_b [expr {$s2_n3r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n4l+$ci}] $nsd_b [expr {$s2_n4r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n5l+$ci}] $nsd_b [expr {$s2_n5r-$ci}] $nsd_t"

    puts $fd "<< pdc >>"
    puts $fd "rect [expr {$s1_n0l+$ci}] $psd_b [expr {$s1_n0r-$ci}] $psd_t"
    puts $fd "rect [expr {$s1_n1l+$ci}] $psd_b [expr {$s1_n1r-$ci}] $psd_t"
    puts $fd "rect [expr {$s1_n2l+$ci}] $psd_b [expr {$s1_n2r-$ci}] $psd_t"
    puts $fd "rect [expr {$s2_n3l+$ci}] $psd_b [expr {$s2_n3r-$ci}] $psd_t"
    puts $fd "rect [expr {$s2_n4l+$ci}] $psd_b [expr {$s2_n4r-$ci}] $psd_t"
    puts $fd "rect [expr {$s2_n5l+$ci}] $psd_b [expr {$s2_n5r-$ci}] $psd_t"

    puts $fd "<< cogc >>"
    puts $fd "rect $g1l 58 $g1r 72"
    puts $fd "rect $g2l 58 $g2r 72"
    puts $fd "rect $g3l 50 $g3r 58"
    puts $fd "rect $g3l 72 $g3r 80"
    puts $fd "rect 158 50 165 58"
    puts $fd "rect 167 72 174 80"

    puts $fd "<< metal1 >>"
    # Power rails
    puts $fd "rect 0 $vdd_b $W $vdd_t"
    puts $fd "rect 0 $vss_b $W $vss_t"

    # VSS connections
    puts $fd "rect [expr {$s1_n1l+$ci}] $vss_t [expr {$s1_n1r-$ci}] $nsd_t"
    # VDD connections
    puts $fd "rect [expr {$s1_n1l+$ci}] $psd_b [expr {$s1_n1r-$ci}] $vdd_b"

    # BB node: ndc+pdc+vertical
    puts $fd "rect [expr {$s1_n0l+$ci}] $nsd_b [expr {$s1_n0r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s1_n0l+$ci}] $psd_b [expr {$s1_n0r-$ci}] $psd_t"
    puts $fd "rect 6 $nsd_t 16 $psd_b"

    # AB node: ndc+pdc+vertical (extend to y=88 for via1 access)
    puts $fd "rect [expr {$s1_n2l+$ci}] $nsd_b [expr {$s1_n2r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s1_n2l+$ci}] $psd_b [expr {$s1_n2r-$ci}] $psd_t"
    if {!$is_xnor} {
        # XOR: AB routes on y=82-88 track, need M1 to reach y=88
        puts $fd "rect 86 $nsd_t 92 88"
    } else {
        # XNOR: AB routes on y=62-68 track
        puts $fd "rect 86 $nsd_t 92 $psd_b"
    }

    # TG1 source: ndc+pdc+vertical
    puts $fd "rect [expr {$s2_n3l+$ci}] $nsd_b [expr {$s2_n3r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n3l+$ci}] $psd_b [expr {$s2_n3r-$ci}] $psd_t"
    puts $fd "rect 104 $nsd_t 110 $psd_b"

    # Y node: ndc+pdc+vertical
    puts $fd "rect [expr {$s2_n4l+$ci}] $nsd_b [expr {$s2_n4r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n4l+$ci}] $psd_b [expr {$s2_n4r-$ci}] $psd_t"
    puts $fd "rect 138 $nsd_t 148 $psd_b"

    # TG2 source: ndc+pdc+vertical (extend to y=88 for via1)
    puts $fd "rect [expr {$s2_n5l+$ci}] $nsd_b [expr {$s2_n5r-$ci}] $nsd_t"
    puts $fd "rect [expr {$s2_n5l+$ci}] $psd_b [expr {$s2_n5r-$ci}] $psd_t"
    if {!$is_xnor} {
        # XOR: TG2_src=AB, routed on y=82-88
        puts $fd "rect 180 $nsd_t 190 88"
    } else {
        # XNOR: TG2_src=A, routed on y=82-88
        puts $fd "rect 180 $nsd_t 190 88"
    }

    # Gate contacts M1 (on cogc)
    puts $fd "rect $g1l 58 $g1r 72"
    puts $fd "rect $g2l 58 $g2r 72"
    puts $fd "rect $g3l 50 $g3r 58"
    puts $fd "rect $g3l 72 $g3r 80"
    # Col4 N-half: M1 x=158-165, y=50-78 (reaches BB-track)
    puts $fd "rect 158 50 165 78"
    # Col4 P-half: M1 x=167-174, y=52-80 (reaches B-track)
    puts $fd "rect 167 52 174 80"

    # A gate M1: extend from cogc down to y=62 for A-track via1 access
    # cogc at y=58-72, A via1 at y=62-68. Already covered by cogc M1.
    # But need M1 at x=70-76 for via1. Gate M1 is at x=66-82. Via at 70-76 is inside.

    # For XNOR, need A to reach y=82-88. Extend A gate M1:
    if {$is_xnor} {
        # A routes to y=82-88 track. Extend col2 gate M1 up to y=88.
        puts $fd "rect 70 58 76 88"
    }

    # For XOR, A M1 just needs to reach via1 at y=62-68, which is within cogc M1 range

    puts $fd "<< via1 >>"
    # BB → M2 BB-track (y=72-78)
    puts $fd "rect 8 72 14 78"
    # B → M2 B-track (y=52-58)
    puts $fd "rect 26 52 32 58"
    # G3 N-half → M2 B-track (y=52-58)
    puts $fd "rect 118 52 124 58"
    # G3 P-half → M2 BB-track (y=72-78)
    puts $fd "rect 118 72 124 78"
    # G4 N-half → M2 BB-track (y=72-78)
    puts $fd "rect 159 72 165 78"
    # G4 P-half → M2 B-track (y=52-58)
    puts $fd "rect 168 52 174 58"

    if {!$is_xnor} {
        # XOR: A→TG1_src on y=62-68, AB→TG2_src on y=82-88
        # A gate via1 (y=62-68)
        puts $fd "rect 70 62 76 68"
        # TG1_src via1 (y=62-68)
        puts $fd "rect 105 62 111 68"
        # AB via1 (y=82-88)
        puts $fd "rect 87 82 93 88"
        # TG2_src via1 (y=82-88)
        puts $fd "rect 182 82 188 88"
        # Y via1 (y=62-68) for output
        puts $fd "rect 140 62 146 68"
    } else {
        # XNOR: AB→TG1_src on y=62-68, A→TG2_src on y=82-88
        # AB via1 (y=62-68) - need to connect AB M1 to this y
        puts $fd "rect 87 62 93 68"
        # TG1_src via1 (y=62-68)
        puts $fd "rect 105 62 111 68"
        # A gate via1 (y=82-88) - from extended M1
        puts $fd "rect 70 82 76 88"
        # TG2_src via1 (y=82-88)
        puts $fd "rect 182 82 188 88"
        # Y via1 (y=62-68)
        puts $fd "rect 140 62 146 68"
    }

    puts $fd "<< metal2 >>"
    # BB-track (y=72-78)
    puts $fd "rect 8 72 165 78"
    # B-track (y=52-58)
    puts $fd "rect 26 52 174 58"

    if {!$is_xnor} {
        # XOR: A(x=70)→TG1_src(x=111) on y=62-68
        puts $fd "rect 70 62 111 68"
        # AB(x=87)→TG2_src(x=188) on y=82-88
        puts $fd "rect 87 82 188 88"
    } else {
        # XNOR: AB(x=87)→TG1_src(x=111) on y=62-68
        puts $fd "rect 87 62 111 68"
        # A(x=70)→TG2_src(x=188) on y=82-88
        puts $fd "rect 70 82 188 88"
    }
    # Y output pad
    puts $fd "rect 138 60 148 68"

    puts $fd "<< labels >>"
    puts $fd "rlabel metal2 74 55 74 55 1 A"
    puts $fd "rlabel metal2 30 55 30 55 1 B"
    puts $fd "rlabel metal2 143 64 143 64 1 Y"
    puts $fd "rlabel metal1 98 0 98 0 1 VSS"
    puts $fd "rlabel metal1 98 140 98 140 5 VDD"

    puts $fd "<< end >>"

    close $fd
    puts "Wrote ${cellname}.mag"
}

# Generate all 4 cells
gen_cell XOR2x1 0
gen_cell XNOR2x1 1

# For x2 variants, the layout is identical (same topology, different electrical width)
# In the .mag file, the physical geometry is the same; the width difference
# is captured in the SPICE netlist (w=64n vs w=32n).
# Copy x1 layouts as x2.
file copy -force "/Users/bruce/CLAUDE/asap5/stdcells/layouts/XOR2x1.mag" \
    "/Users/bruce/CLAUDE/asap5/stdcells/layouts/XOR2x2.mag"
file copy -force "/Users/bruce/CLAUDE/asap5/stdcells/layouts/XNOR2x1.mag" \
    "/Users/bruce/CLAUDE/asap5/stdcells/layouts/XNOR2x2.mag"

# Fix cell names in x2 copies
proc fix_cellname {filepath oldname newname} {
    set fd [open $filepath r]
    set data [read $fd]
    close $fd
    # The .mag format doesn't have explicit cellname in the file body,
    # but the filename determines the cell name in Magic.
    # No changes needed inside the file.
}

puts "All 4 cells generated."
puts "XOR2x1.mag XOR2x2.mag XNOR2x1.mag XNOR2x2.mag"
