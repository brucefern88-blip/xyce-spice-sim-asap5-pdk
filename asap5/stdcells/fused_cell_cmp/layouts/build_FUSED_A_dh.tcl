# Build FUSED_A double-height layout — 48T canonical fused Hamming cell
# Width: 12 CPP = 528nm, Height: 2 × 140nm = 280nm
# Aspect ratio: 528/280 = 1.89:1 (≤ 2:1 ✓)
#
# Row 1 (bottom, y=0..140): 4 input INVs + 2 AOI22 XOR gates (12 gates)
#   NMOS: y=10..55, PMOS: y=85..130, nwell: y=65..140
#   VSS rail: y=0..14, VDD rail: y=126..140 (shared with row 2)
#
# Row 2 (top, y=140..280, MIRRORED P-over-N for shared VDD):
#   PMOS: y=150..195, NMOS: y=225..270, nwell: y=140..215
#   VDD rail: y=140..154 (shared), VSS rail: y=266..280
#
# Gate assignment:
#   Row 1 (0-11): 0:INV(ai) 1:INV(bi) 2:INV(aj) 3:INV(bj)
#                 4-5:XOR0_A(ai/bi) 6-7:XOR0_B(nai/nbi)
#                 8-9:XOR1_A(aj/bj) 10-11:XOR1_B(naj/nbj)
#   Row 2 (12-23): 12:INV(d0) 13:INV(d1)
#                   14-15:NOR2(oh0)
#                   16-17:AOI22_A(d0/xn1) 18-19:AOI22_B(xn0/d1)
#                   20:INV(oh1_out)
#                   21-22:NAND2(d0/d1) 23:INV(oh2_out)

# === Geometry helpers ===
proc gx {n} { return [expr {14 + ($n % 12) * 44}] }
proc gxr {n} { return [expr {14 + ($n % 12) * 44 + 16}] }

set W 528
set H 280
set NG 12

cellname rename (UNNAMED) FUSED_A

box 0 0 $W $H

# === NWELL: continuous through both PMOS regions and shared VDD ===
# Bottom PMOS nwell: y=65..140, Top PMOS nwell: y=140..215
box 0 65 $W 215
paint nwell

# === Power Rails (M1) ===
# VSS bottom: y=0..14
box 0 0 $W 14
paint metal1
# VDD shared middle: y=126..154
box 0 126 $W 154
paint metal1
# VSS top: y=266..280
box 0 266 $W 280
paint metal1

# === POLY for all 24 gates ===
# Row 1 (12 gates, bottom): poly stubs above/below active regions
for {set n 0} {$n < $NG} {incr n} {
    set xl [gx $n]
    set xr [gxr $n]
    # Below NMOS active
    box $xl 5 $xr 10
    paint poly
    # Above NMOS, below cogc gap
    box $xl 55 $xr 58
    paint poly
    # Narrow poly through cogc region (sides only)
    box $xl 58 [expr {$xl + 2}] 72
    paint poly
    box [expr {$xr - 2}] 58 $xr 72
    paint poly
    # Above cogc, below PMOS
    box $xl 72 $xr 75
    paint poly
    # Above PMOS active
    box $xl 130 $xr 135
    paint poly
}

# Row 2 (12 gates, top mirrored): poly stubs
for {set n 0} {$n < $NG} {incr n} {
    set xl [gx $n]
    set xr [gxr $n]
    # Below PMOS active (above VDD rail)
    box $xl 145 $xr 150
    paint poly
    # Above PMOS, below cogc gap
    box $xl 195 $xr 198
    paint poly
    # Narrow poly through cogc region
    box $xl 198 [expr {$xl + 2}] 212
    paint poly
    box [expr {$xr - 2}] 198 $xr 212
    paint poly
    # Above cogc, below NMOS
    box $xl 212 $xr 215
    paint poly
    # Above NMOS active
    box $xl 270 $xr 275
    paint poly
}

# ===================================================================
# ROW 1: Diffusion blocks, FETs, contacts
# ===================================================================

# --- Row 1 NMOS blocks ---
proc r1_nmos {first last lpad rpad} {
    set s [expr {[gx $first] - $lpad}]
    set e [expr {[gxr $last] + $rpad}]
    # Left S/D
    box $s 10 [gx $first] 55
    paint ndiff
    # Internal S/D
    for {set n $first} {$n < $last} {incr n} {
        box [gxr $n] 10 [gx [expr {$n+1}]] 55
        paint ndiff
    }
    # Right S/D
    box [gxr $last] 10 $e 55
    paint ndiff
    # FETs
    for {set n $first} {$n <= $last} {incr n} {
        box [gx $n] 10 [gxr $n] 55
        paint nfet_slvt
    }
}

# --- Row 1 PMOS blocks ---
proc r1_pmos {first last lpad rpad} {
    set s [expr {[gx $first] - $lpad}]
    set e [expr {[gxr $last] + $rpad}]
    box $s 85 [gx $first] 130
    paint pdiff
    for {set n $first} {$n < $last} {incr n} {
        box [gxr $n] 85 [gx [expr {$n+1}]] 130
        paint pdiff
    }
    box [gxr $last] 85 $e 130
    paint pdiff
    for {set n $first} {$n <= $last} {incr n} {
        box [gx $n] 85 [gxr $n] 130
        paint pfet_slvt
    }
}

# --- Row 1 NDC blocks ---
proc r1_ndc {first last lpad rpad} {
    set s [expr {[gx $first] - $lpad}]
    set e [expr {[gxr $last] + $rpad}]
    box [expr {$s + 2}] 20 [expr {[gx $first] - 2}] 45
    paint ndc
    for {set n $first} {$n < $last} {incr n} {
        box [expr {[gxr $n] + 2}] 20 [expr {[gx [expr {$n+1}]] - 2}] 45
        paint ndc
    }
    box [expr {[gxr $last] + 2}] 20 [expr {$e - 2}] 45
    paint ndc
}

# --- Row 1 PDC blocks ---
proc r1_pdc {first last lpad rpad} {
    set s [expr {[gx $first] - $lpad}]
    set e [expr {[gxr $last] + $rpad}]
    box [expr {$s + 2}] 95 [expr {[gx $first] - 2}] 120
    paint pdc
    for {set n $first} {$n < $last} {incr n} {
        box [expr {[gxr $n] + 2}] 95 [expr {[gx [expr {$n+1}]] - 2}] 120
        paint pdc
    }
    box [expr {[gxr $last] + 2}] 95 [expr {$e - 2}] 120
    paint pdc
}

# --- Row 1 COGC blocks ---
proc r1_cogc {first last} {
    for {set n $first} {$n <= $last} {incr n} {
        set xl [expr {[gx $n] + 2}]
        set xr [expr {[gxr $n] - 2}]
        box $xl 60 $xr 70
        paint cogc
        box $xl 60 $xr 70
        paint metal1
    }
}

# --- Row 1 build helper ---
proc r1_build {first last lpad rpad} {
    r1_nmos $first $last $lpad $rpad
    r1_pmos $first $last $lpad $rpad
    r1_ndc $first $last $lpad $rpad
    r1_pdc $first $last $lpad $rpad
    r1_cogc $first $last
}

# ===================================================================
# ROW 2 (MIRRORED): PMOS y=150..195, NMOS y=225..270
# ===================================================================

# --- Row 2 PMOS blocks (mirrored, near VDD) ---
proc r2_pmos {first last lpad rpad} {
    set s [expr {[gx $first] - $lpad}]
    set e [expr {[gxr $last] + $rpad}]
    box $s 150 [gx $first] 195
    paint pdiff
    for {set n $first} {$n < $last} {incr n} {
        box [gxr $n] 150 [gx [expr {$n+1}]] 195
        paint pdiff
    }
    box [gxr $last] 150 $e 195
    paint pdiff
    for {set n $first} {$n <= $last} {incr n} {
        box [gx $n] 150 [gxr $n] 195
        paint pfet_slvt
    }
}

# --- Row 2 NMOS blocks (mirrored, near top VSS) ---
proc r2_nmos {first last lpad rpad} {
    set s [expr {[gx $first] - $lpad}]
    set e [expr {[gxr $last] + $rpad}]
    box $s 225 [gx $first] 270
    paint ndiff
    for {set n $first} {$n < $last} {incr n} {
        box [gxr $n] 225 [gx [expr {$n+1}]] 270
        paint ndiff
    }
    box [gxr $last] 225 $e 270
    paint ndiff
    for {set n $first} {$n <= $last} {incr n} {
        box [gx $n] 225 [gxr $n] 270
        paint nfet_slvt
    }
}

# --- Row 2 PDC blocks (near VDD) ---
proc r2_pdc {first last lpad rpad} {
    set s [expr {[gx $first] - $lpad}]
    set e [expr {[gxr $last] + $rpad}]
    box [expr {$s + 2}] 160 [expr {[gx $first] - 2}] 185
    paint pdc
    for {set n $first} {$n < $last} {incr n} {
        box [expr {[gxr $n] + 2}] 160 [expr {[gx [expr {$n+1}]] - 2}] 185
        paint pdc
    }
    box [expr {[gxr $last] + 2}] 160 [expr {$e - 2}] 185
    paint pdc
}

# --- Row 2 NDC blocks (near top VSS) ---
proc r2_ndc {first last lpad rpad} {
    set s [expr {[gx $first] - $lpad}]
    set e [expr {[gxr $last] + $rpad}]
    box [expr {$s + 2}] 235 [expr {[gx $first] - 2}] 260
    paint ndc
    for {set n $first} {$n < $last} {incr n} {
        box [expr {[gxr $n] + 2}] 235 [expr {[gx [expr {$n+1}]] - 2}] 260
        paint ndc
    }
    box [expr {[gxr $last] + 2}] 235 [expr {$e - 2}] 260
    paint ndc
}

# --- Row 2 COGC blocks ---
proc r2_cogc {first last} {
    for {set n $first} {$n <= $last} {incr n} {
        set xl [expr {[gx $n] + 2}]
        set xr [expr {[gxr $n] - 2}]
        box $xl 200 $xr 210
        paint cogc
        box $xl 200 $xr 210
        paint metal1
    }
}

# --- Row 2 build helper ---
proc r2_build {first last lpad rpad} {
    r2_pmos $first $last $lpad $rpad
    r2_nmos $first $last $lpad $rpad
    r2_pdc $first $last $lpad $rpad
    r2_ndc $first $last $lpad $rpad
    r2_cogc $first $last
}

# M1 drain connection helpers
proc r1_drain_m1 {gl gr} {
    box $gl 45 $gr 95
    paint metal1
}

proc r2_drain_m1 {gl gr} {
    box $gl 185 $gr 235
    paint metal1
}

# ===================================================================
# BUILD ROW 1: gates 0-11 (4 INVs + 2 AOI22 XOR gates)
# ===================================================================
# Gate map (row-local indices 0-11):
#   0:INV(ai) 1:INV(bi) 2:INV(aj) 3:INV(bj)
#   4-5:XOR0_stackA(ai/bi series NMOS, ai/bi parallel PMOS)
#   6-7:XOR0_stackB(nai/nbi series NMOS, nai/nbi parallel PMOS)
#   8-9:XOR1_stackA(aj/bj) 10-11:XOR1_stackB(naj/nbj)

# INV block: gates 0-3
r1_build 0 3 14 12
# XOR0 stack A: gates 4-5
r1_build 4 5 12 12
# XOR0 stack B: gates 6-7
r1_build 6 7 12 12
# XOR1 stack A: gates 8-9
r1_build 8 9 12 12
# XOR1 stack B: gates 10-11
r1_build 10 11 12 14

# ===================================================================
# BUILD ROW 2: gates 12-23 (2 INVs + NOR2 + AOI22 + INV + NAND2 + INV)
# ===================================================================
# Gate map (row-local indices 0-11, global 12-23):
#   0(12):INV(d0)  1(13):INV(d1)
#   2-3(14-15):NOR2(oh0) — NMOS parallel, PMOS series
#   4-5(16-17):AOI22_A(d0/xn1 series NMOS, d0/xn1 parallel PMOS)
#   6-7(18-19):AOI22_B(xn0/d1 series NMOS, xn0/d1 parallel PMOS)
#   8(20):INV(oh1_out)
#   9-10(21-22):NAND2(d0/d1) — NMOS series, PMOS parallel
#   11(23):INV(oh2_out)

# Buffer INVs: gates 0-1 (global 12-13)
r2_build 0 1 14 12
# NOR2 oh0: gates 2-3 (global 14-15)
r2_build 2 3 12 12
# AOI22 stack A: gates 4-5 (global 16-17)
r2_build 4 5 12 12
# AOI22 stack B: gates 6-7 (global 18-19)
r2_build 6 7 12 12
# OH1 output INV: gate 8 (global 20)
r2_build 8 8 12 12
# NAND2 oh2: gates 9-10 (global 21-22)
r2_build 9 10 12 12
# OH2 output INV: gate 11 (global 23)
r2_build 11 11 12 14

# ===================================================================
# ROW 1: M1 DRAIN CONNECTIONS
# ===================================================================

# INV drain connections (nai, nbi, naj, nbj)
r1_drain_m1 [expr {[gxr 0] + 2}] [expr {[gx 1] - 2}]
r1_drain_m1 [expr {[gxr 1] + 2}] [expr {[gx 2] - 2}]
r1_drain_m1 [expr {[gxr 2] + 2}] [expr {[gx 3] - 2}]
r1_drain_m1 [expr {[gxr 3] + 2}] [expr {[gxr 3] + 10}]

# XOR0 d0 output: left S/D of gates 4 and 6 (shared drain)
r1_drain_m1 [expr {[gx 4] - 10}] [expr {[gx 4] - 2}]
r1_drain_m1 [expr {[gx 6] - 10}] [expr {[gx 6] - 2}]

# XOR1 d1 output: left S/D of gates 8 and 10
r1_drain_m1 [expr {[gx 8] - 10}] [expr {[gx 8] - 2}]
r1_drain_m1 [expr {[gx 10] - 10}] [expr {[gx 10] - 2}]

# ===================================================================
# ROW 2: M1 DRAIN CONNECTIONS
# ===================================================================

# Buffer INV outputs (xn0, xn1)
set xn0_dl [expr {[gxr 0] + 2}]
r2_drain_m1 $xn0_dl [expr {[gx 1] - 2}]
set xn1_dl [expr {[gxr 1] + 2}]
r2_drain_m1 $xn1_dl [expr {[gxr 1] + 10}]

# OH0: NOR2 output — NMOS side (parallel drains share output)
# Left S/D of gate 2 is the output
set oh0_dl [expr {[gx 2] - 10}]
r2_drain_m1 $oh0_dl [expr {[gx 2] - 2}]
# PMOS series connection: output at right S/D of gate 3
box [expr {[gxr 3] + 2}] 160 [expr {[gxr 3] + 10}] 185
paint metal1

# AOI22 outputs (no1): left S/D of gates 4 and 6
set no1_a_l [expr {[gx 4] - 10}]
r2_drain_m1 $no1_a_l [expr {[gx 4] - 2}]
set no1_b_l [expr {[gx 6] - 10}]
r2_drain_m1 $no1_b_l [expr {[gx 6] - 2}]

# OH1 INV output drain
set oh1_dl [expr {[gxr 8] + 2}]
r2_drain_m1 $oh1_dl [expr {[gxr 8] + 10}]

# NAND2 output (no2): left S/D of gate 9
set no2_l [expr {[gx 9] - 10}]
r2_drain_m1 $no2_l [expr {[gx 9] - 2}]

# OH2 INV output drain
set oh2_dl [expr {[gxr 11] + 2}]
r2_drain_m1 $oh2_dl [expr {[gxr 11] + 10}]

# ===================================================================
# ROW 1: M2 SIGNAL ROUTING (within row 1)
# ===================================================================

# nai bus: INV0 drain -> XOR0_B gate 6 (y=92..98, M2 horizontal)
set naiv [expr {[gxr 0] + 4}]
set g6v [expr {[gx 6] + 4}]
box $naiv 92 [expr {$g6v + 6}] 98
paint metal2
box $naiv 92 [expr {$naiv + 6}] 98
paint via1
box $g6v 92 [expr {$g6v + 6}] 98
paint via1

# nbi bus: INV1 drain -> XOR0_B gate 7 (y=102..108)
set nbiv [expr {[gxr 1] + 4}]
set g7v [expr {[gx 7] + 4}]
box $nbiv 102 [expr {$g7v + 6}] 108
paint metal2
box $nbiv 102 [expr {$nbiv + 6}] 108
paint via1
box $g7v 102 [expr {$g7v + 6}] 108
paint via1

# naj bus: INV2 drain -> XOR1_B gate 10 (y=92..98, separate track)
set najv [expr {[gxr 2] + 4}]
set g10v [expr {[gx 10] + 4}]
box $najv 82 [expr {$g10v + 6}] 88
paint metal2
box $najv 82 [expr {$najv + 6}] 88
paint via1
box $g10v 82 [expr {$g10v + 6}] 88
paint via1

# nbj bus: INV3 drain -> XOR1_B gate 11 (y=112..118)
set nbjv [expr {[gxr 3] + 4}]
set g11v [expr {[gx 11] + 4}]
box $nbjv 112 [expr {$g11v + 6}] 118
paint metal2
box $nbjv 112 [expr {$nbjv + 6}] 118
paint via1
box $g11v 112 [expr {$g11v + 6}] 118
paint via1

# d0 bus: connect XOR0 stack A & B outputs → M2 at y=38..44
# XOR0_A left S/D (gate 4 left) and XOR0_B left S/D (gate 6 left)
set d0_a_v [expr {[gx 4] - 8}]
set d0_b_v [expr {[gx 6] - 8}]
box $d0_a_v 38 [expr {$d0_b_v + 6}] 44
paint metal2
box $d0_a_v 38 [expr {$d0_a_v + 6}] 44
paint via1
box $d0_b_v 38 [expr {$d0_b_v + 6}] 44
paint via1

# d1 bus: connect XOR1 stack A & B outputs → M2 at y=28..34
set d1_a_v [expr {[gx 8] - 8}]
set d1_b_v [expr {[gx 10] - 8}]
box $d1_a_v 28 [expr {$d1_b_v + 6}] 34
paint metal2
box $d1_a_v 28 [expr {$d1_a_v + 6}] 34
paint via1
box $d1_b_v 28 [expr {$d1_b_v + 6}] 34
paint via1

# ===================================================================
# CROSS-ROW ROUTING: M2 vertical connections from Row 1 to Row 2
# ===================================================================

# d0 signal: from Row 1 XOR0 output to Row 2 gates 0(12), 2(14), 4(16), 9(21)
# Run vertical M2 strip from d0 bus (y=38) up through Row 2
# Use x position at d0_a_v
set d0_xpos $d0_a_v
box $d0_xpos 38 [expr {$d0_xpos + 6}] 210
paint metal2
# Via1 to Row 2 gate 0 (INV d0->xn0) cogc at y=200..210
set g12_cogc [expr {[gx 0] + 2}]
box $g12_cogc 200 [expr {$g12_cogc + 6}] 210
paint via1
# Via1 to Row 2 gate 2 (NOR2 oh0) cogc
set g14_cogc [expr {[gx 2] + 2}]
box $g14_cogc 200 [expr {$g14_cogc + 6}] 210
paint via1
# Horizontal M2 spur for gate 2 connection
box $d0_xpos 200 [expr {$g14_cogc + 6}] 206
paint metal2

# d0 to AOI22 gate 4 (global 16) and NAND2 gate 9 (global 21)
set g16_cogc [expr {[gx 4] + 2}]
box $g16_cogc 200 [expr {$g16_cogc + 6}] 210
paint via1
# Horizontal M2 spur from d0 vertical to gate 4
box $d0_xpos 194 [expr {$g16_cogc + 6}] 200
paint metal2
box $d0_xpos 194 [expr {$d0_xpos + 6}] 200
paint via1

set g21_cogc [expr {[gx 9] + 2}]
box $g21_cogc 200 [expr {$g21_cogc + 6}] 210
paint via1
# Horizontal M2 spur from d0 to NAND2 gate 9
box $d0_xpos 188 [expr {$g21_cogc + 6}] 194
paint metal2
box $d0_xpos 188 [expr {$d0_xpos + 6}] 194
paint via1

# d1 signal: from Row 1 XOR1 output to Row 2 gates 1(13), 3(15), 7(19), 10(22)
set d1_xpos $d1_a_v
box $d1_xpos 28 [expr {$d1_xpos + 6}] 210
paint metal2
# Via1 to Row 2 gate 1 (INV d1->xn1) cogc
set g13_cogc [expr {[gx 1] + 2}]
box $g13_cogc 200 [expr {$g13_cogc + 6}] 210
paint via1
# Horizontal spur to gate 1
box $d1_xpos 200 [expr {$g13_cogc + 6}] 206
paint metal2

# d1 to NOR2 gate 3 (global 15)
set g15_cogc [expr {[gx 3] + 2}]
box $g15_cogc 200 [expr {$g15_cogc + 6}] 210
paint via1
# Horizontal spur
box $d1_xpos 194 [expr {$g15_cogc + 6}] 200
paint metal2
box $d1_xpos 194 [expr {$d1_xpos + 6}] 200
paint via1

# d1 to AOI22 gate 7 (global 19)
set g19_cogc [expr {[gx 7] + 2}]
box $g19_cogc 200 [expr {$g19_cogc + 6}] 210
paint via1
# Horizontal spur
box $d1_xpos 182 [expr {$g19_cogc + 6}] 188
paint metal2
box $d1_xpos 182 [expr {$d1_xpos + 6}] 188
paint via1

# d1 to NAND2 gate 10 (global 22)
set g22_cogc [expr {[gx 10] + 2}]
box $g22_cogc 200 [expr {$g22_cogc + 6}] 210
paint via1
# Horizontal spur
box $d1_xpos 176 [expr {$g22_cogc + 6}] 182
paint metal2
box $d1_xpos 176 [expr {$d1_xpos + 6}] 182
paint via1

# ===================================================================
# ROW 2: M2 INTERNAL ROUTING
# ===================================================================

# xn0 bus: Row 2 gate 0 drain (xn0) -> AOI22 gate 6 (global 18)
set xn0v [expr {$xn0_dl + 2}]
set g18_cogc [expr {[gx 6] + 2}]
box $xn0v 218 [expr {$g18_cogc + 6}] 224
paint metal2
box $xn0v 218 [expr {$xn0v + 6}] 224
paint via1
box $g18_cogc 218 [expr {$g18_cogc + 6}] 224
paint via1

# xn1 bus: Row 2 gate 1 drain (xn1) -> AOI22 gate 5 (global 17)
set xn1v [expr {$xn1_dl + 2}]
set g17_cogc [expr {[gx 5] + 2}]
box $xn1v 230 [expr {$g17_cogc + 6}] 236
paint metal2
box $xn1v 230 [expr {$xn1v + 6}] 236
paint via1
box $g17_cogc 230 [expr {$g17_cogc + 6}] 236
paint via1

# no1 bus: AOI22 output stacks A & B -> OH1 INV gate 8 (global 20)
set no1av [expr {$no1_a_l + 2}]
set no1bv [expr {$no1_b_l + 2}]
set g20_cogc [expr {[gx 8] + 2}]
box $no1av 242 [expr {$g20_cogc + 6}] 248
paint metal2
box $no1av 242 [expr {$no1av + 6}] 248
paint via1
box $no1bv 242 [expr {$no1bv + 6}] 248
paint via1
box $g20_cogc 242 [expr {$g20_cogc + 6}] 248
paint via1

# no2 bus: NAND2 output -> OH2 INV gate 11 (global 23)
set no2v [expr {$no2_l + 2}]
set g23_cogc [expr {[gx 11] + 2}]
box $no2v 252 [expr {$g23_cogc + 6}] 258
paint metal2
box $no2v 252 [expr {$no2v + 6}] 258
paint via1
box $g23_cogc 252 [expr {$g23_cogc + 6}] 258
paint via1

# OH0: Connect NOR2 NMOS output to PMOS series output via M2
set oh0_nv [expr {$oh0_dl + 2}]
set oh0_pv [expr {[gxr 3] + 4}]
box $oh0_nv 250 [expr {$oh0_pv + 6}] 256
paint metal2
box $oh0_nv 250 [expr {$oh0_nv + 6}] 256
paint via1
box $oh0_pv 165 [expr {$oh0_pv + 6}] 256
paint metal2
box $oh0_pv 165 [expr {$oh0_pv + 6}] 171
paint via1

# ===================================================================
# LABELS
# ===================================================================
# Input labels on Row 1 cogc
box [expr {[gx 0] + 4}] 65 [expr {[gx 0] + 10}] 65
label ai 1 cogc
box [expr {[gx 1] + 4}] 65 [expr {[gx 1] + 10}] 65
label bi 1 cogc
box [expr {[gx 2] + 4}] 65 [expr {[gx 2] + 10}] 65
label aj 1 cogc
box [expr {[gx 3] + 4}] 65 [expr {[gx 3] + 10}] 65
label bj 1 cogc

# Output labels on Row 2 M1 drains
box [expr {$oh0_dl + 4}] 210 [expr {$oh0_dl + 4}] 210
label oh0 1 metal1
box [expr {$oh1_dl + 4}] 210 [expr {$oh1_dl + 4}] 210
label oh1 1 metal1
box [expr {$oh2_dl + 4}] 210 [expr {$oh2_dl + 4}] 210
label oh2 1 metal1

# Power labels
box [expr {$W / 2}] 7 [expr {$W / 2}] 7
label VSS 1 metal1
box [expr {$W / 2}] 140 [expr {$W / 2}] 140
label VDD 5 metal1
box [expr {$W / 2}] 273 [expr {$W / 2}] 273
label VSS 1 metal1

# ===================================================================
# SAVE, DRC, EXTRACT
# ===================================================================
save /Users/bruce/CLAUDE/asap5/stdcells/fused_ppa/FUSED_A

drc catchup
set drc_count [drc count]
puts "FUSED_A DH DRC violations: $drc_count"

extract all
ext2spice lvs
ext2spice -f ngspice -o /Users/bruce/CLAUDE/asap5/stdcells/fused_ppa/FUSED_A_ext.spice

puts "FUSED_A double-height layout: ${W}nm x ${H}nm = [expr {$W/$H.0}]:1 aspect ratio"
puts "12 CPP x 2 rows = 24 gates = 48 transistors"
