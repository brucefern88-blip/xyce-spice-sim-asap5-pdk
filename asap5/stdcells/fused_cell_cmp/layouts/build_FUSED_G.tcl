# Build FUSED_G layout — Variant G (Active-Low, 40T, 20 gate pitches, SLVT)
# Width: 20 * 44 = 880nm, Height: 140nm
# Optimized: correct S/D sharing, diffusion breaks between blocks
#
# CRITICAL FIX: Use 12nm S/D extension (not 14nm) to leave 4nm gap
# between adjacent blocks that should NOT share diffusion.
# Only paint full 14nm extension where blocks physically share a S/D node.

proc gx {n} { return [expr {14 + $n * 44}] }
proc gxr {n} { return [expr {14 + $n * 44 + 16}] }

set W 880
set H 140
set NG 20
set SD_EXT 12

cellname rename (UNNAMED) FUSED_G
box 0 0 $W $H

# === NWELL ===
box 0 65 $W $H
paint nwell

# === Power rails ===
box 0 126 $W $H
paint metal1
box 0 0 $W 14
paint metal1

# === POLY ===
for {set n 0} {$n < $NG} {incr n} {
    set xl [gx $n]
    set xr [gxr $n]
    box $xl 5 $xr 10
    paint poly
    box $xl 55 $xr 58
    paint poly
    box $xl 72 $xr 75
    paint poly
    box $xl 130 $xr 135
    paint poly
}

# === Diffusion with controlled extensions ===
# nmos_block_ex: NMOS block with explicit left/right S/D extensions
proc nmos_block_ex {first last lext rext} {
    set s [expr {[gx $first] - $lext}]
    set e [expr {[gxr $last] + $rext}]
    box $s 10 [gx $first] 55
    paint ndiff
    for {set n $first} {$n < $last} {incr n} {
        box [gxr $n] 10 [gx [expr {$n+1}]] 55
        paint ndiff
    }
    box [gxr $last] 10 $e 55
    paint ndiff
    for {set n $first} {$n <= $last} {incr n} {
        box [gx $n] 10 [gxr $n] 55
        paint nfet_slvt
    }
}
proc pmos_block_ex {first last lext rext} {
    set s [expr {[gx $first] - $lext}]
    set e [expr {[gxr $last] + $rext}]
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

# S/D contact helpers
proc ndc_region {xl xr} {
    box [expr {$xl + 2}] 20 [expr {$xr - 2}] 45
    paint ndc
}
proc pdc_region {xl xr} {
    box [expr {$xl + 2}] 95 [expr {$xr - 2}] 120
    paint pdc
}
proc cogc_at {n} {
    set xl [expr {[gx $n] + 2}]
    set xr [expr {[gxr $n] - 2}]
    box $xl 60 $xr 70
    paint cogc
    box $xl 60 $xr 70
    paint metal1
}
# Vertical M1 connecting NMOS S/D to PMOS S/D (signal drain)
proc drain_m1_v {xl xr} {
    box [expr {$xl + 2}] 20 [expr {$xr - 2}] 120
    paint metal1
}
# M1 connecting ndc to VSS rail
proc vss_connect {xl xr} {
    box [expr {$xl + 2}] 7 [expr {$xr - 2}] 45
    paint metal1
}
# M1 connecting pdc to VDD rail
proc vdd_connect {xl xr} {
    box [expr {$xl + 2}] 95 [expr {$xr - 2}] 133
    paint metal1
}
# M1 pad in NMOS S/D only
proc nmos_m1_pad {xl xr} {
    box [expr {$xl + 2}] 20 [expr {$xr - 2}] 45
    paint metal1
}
# M1 pad in PMOS S/D only
proc pmos_m1_pad {xl xr} {
    box [expr {$xl + 2}] 95 [expr {$xr - 2}] 120
    paint metal1
}

# S/D boundary helpers
proc sd_l {first lext} { return [list [expr {[gx $first] - $lext}] [gx $first]] }
proc sd_m {n} { return [list [gxr $n] [gx [expr {$n+1}]]] }
proc sd_r {last rext} { return [list [gxr $last] [expr {[gxr $last] + $rext}]] }

# ============================================================
# BUILD BLOCKS WITH CORRECT EXTENSIONS
# Adjacent blocks use 12nm extension to leave 4nm gap
# ============================================================

set E $SD_EXT

# --- Block [0,1]: INV ai, INV bi ---
# N: nai-G0-VSS-G1-nbi   P: nai-G0-VDD-G1-nbi
# Left neighbor: none (cell edge). Right neighbor: block [2,3]
nmos_block_ex 0 1 14 $E
pmos_block_ex 0 1 14 $E
set nai_n [sd_l 0 14]; set vss01 [sd_m 0]; set nbi_n [sd_r 1 $E]
ndc_region [lindex $nai_n 0] [lindex $nai_n 1]
ndc_region [lindex $vss01 0] [lindex $vss01 1]
ndc_region [lindex $nbi_n 0] [lindex $nbi_n 1]
set nai_p [sd_l 0 14]; set vdd01 [sd_m 0]; set nbi_p [sd_r 1 $E]
pdc_region [lindex $nai_p 0] [lindex $nai_p 1]
pdc_region [lindex $vdd01 0] [lindex $vdd01 1]
pdc_region [lindex $nbi_p 0] [lindex $nbi_p 1]
cogc_at 0; cogc_at 1
drain_m1_v [lindex $nai_n 0] [lindex $nai_n 1]
drain_m1_v [lindex $nbi_n 0] [lindex $nbi_n 1]
vss_connect [lindex $vss01 0] [lindex $vss01 1]
vdd_connect [lindex $vdd01 0] [lindex $vdd01 1]

# --- Block [2,3]: INV aj, INV bj ---
# Left: block [0,1]. Right: block [4,5]
nmos_block_ex 2 3 $E $E
pmos_block_ex 2 3 $E $E
set naj_n [sd_l 2 $E]; set vss23 [sd_m 2]; set nbj_n [sd_r 3 $E]
ndc_region [lindex $naj_n 0] [lindex $naj_n 1]
ndc_region [lindex $vss23 0] [lindex $vss23 1]
ndc_region [lindex $nbj_n 0] [lindex $nbj_n 1]
set naj_p [sd_l 2 $E]; set vdd23 [sd_m 2]; set nbj_p [sd_r 3 $E]
pdc_region [lindex $naj_p 0] [lindex $naj_p 1]
pdc_region [lindex $vdd23 0] [lindex $vdd23 1]
pdc_region [lindex $nbj_p 0] [lindex $nbj_p 1]
cogc_at 2; cogc_at 3
drain_m1_v [lindex $naj_n 0] [lindex $naj_n 1]
drain_m1_v [lindex $nbj_n 0] [lindex $nbj_n 1]
vss_connect [lindex $vss23 0] [lindex $vss23 1]
vdd_connect [lindex $vdd23 0] [lindex $vdd23 1]

# --- Block [4,5]: OAI22 XOR0 stackA ---
# N: VSS-G4(nai)-q0nmid-G5(nbi)-VSS
# P: x0-G4(nai)-q0pm1-G5(nbi)-VDD
nmos_block_ex 4 5 $E $E
pmos_block_ex 4 5 $E $E
set vss_l4 [sd_l 4 $E]; set q0nm [sd_m 4]; set vss_r5 [sd_r 5 $E]
ndc_region [lindex $vss_l4 0] [lindex $vss_l4 1]
ndc_region [lindex $q0nm 0] [lindex $q0nm 1]
ndc_region [lindex $vss_r5 0] [lindex $vss_r5 1]
set x0_p4 [sd_l 4 $E]; set q0pm1 [sd_m 4]; set vdd_p5 [sd_r 5 $E]
pdc_region [lindex $x0_p4 0] [lindex $x0_p4 1]
pdc_region [lindex $q0pm1 0] [lindex $q0pm1 1]
pdc_region [lindex $vdd_p5 0] [lindex $vdd_p5 1]
cogc_at 4; cogc_at 5
vss_connect [lindex $vss_l4 0] [lindex $vss_l4 1]
vss_connect [lindex $vss_r5 0] [lindex $vss_r5 1]
# x0 PMOS drain at left — just pmos M1 pad (different signal from NMOS left=VSS)
pmos_m1_pad [lindex $x0_p4 0] [lindex $x0_p4 1]
vdd_connect [lindex $vdd_p5 0] [lindex $vdd_p5 1]

# --- Block [6,7]: OAI22 XOR0 stackB ---
# N: x0-G6(ai)-q0nmid-G7(bi)-x0
# P: x0-G6(ai)-q0pm2-G7(bi)-VDD
nmos_block_ex 6 7 $E $E
pmos_block_ex 6 7 $E $E
set x0_nl6 [sd_l 6 $E]; set q0nm2 [sd_m 6]; set x0_nr7 [sd_r 7 $E]
ndc_region [lindex $x0_nl6 0] [lindex $x0_nl6 1]
ndc_region [lindex $q0nm2 0] [lindex $q0nm2 1]
ndc_region [lindex $x0_nr7 0] [lindex $x0_nr7 1]
set x0_pl6 [sd_l 6 $E]; set q0pm2 [sd_m 6]; set vdd_p7 [sd_r 7 $E]
pdc_region [lindex $x0_pl6 0] [lindex $x0_pl6 1]
pdc_region [lindex $q0pm2 0] [lindex $q0pm2 1]
pdc_region [lindex $vdd_p7 0] [lindex $vdd_p7 1]
cogc_at 6; cogc_at 7
# x0 at left: NMOS and PMOS are both x0 — drain_m1_v connects them
drain_m1_v [lindex $x0_nl6 0] [lindex $x0_nl6 1]
vdd_connect [lindex $vdd_p7 0] [lindex $vdd_p7 1]

# --- Block [8,9]: OAI22 XOR1 stackA ---
nmos_block_ex 8 9 $E $E
pmos_block_ex 8 9 $E $E
set vss_l8 [sd_l 8 $E]; set q1nm [sd_m 8]; set vss_r9 [sd_r 9 $E]
ndc_region [lindex $vss_l8 0] [lindex $vss_l8 1]
ndc_region [lindex $q1nm 0] [lindex $q1nm 1]
ndc_region [lindex $vss_r9 0] [lindex $vss_r9 1]
set x1_p8 [sd_l 8 $E]; set q1pm1 [sd_m 8]; set vdd_p9 [sd_r 9 $E]
pdc_region [lindex $x1_p8 0] [lindex $x1_p8 1]
pdc_region [lindex $q1pm1 0] [lindex $q1pm1 1]
pdc_region [lindex $vdd_p9 0] [lindex $vdd_p9 1]
cogc_at 8; cogc_at 9
vss_connect [lindex $vss_l8 0] [lindex $vss_l8 1]
vss_connect [lindex $vss_r9 0] [lindex $vss_r9 1]
pmos_m1_pad [lindex $x1_p8 0] [lindex $x1_p8 1]
vdd_connect [lindex $vdd_p9 0] [lindex $vdd_p9 1]

# --- Block [10,11]: OAI22 XOR1 stackB ---
nmos_block_ex 10 11 $E $E
pmos_block_ex 10 11 $E $E
set x1_nl10 [sd_l 10 $E]; set q1nm2 [sd_m 10]; set x1_nr11 [sd_r 11 $E]
ndc_region [lindex $x1_nl10 0] [lindex $x1_nl10 1]
ndc_region [lindex $q1nm2 0] [lindex $q1nm2 1]
ndc_region [lindex $x1_nr11 0] [lindex $x1_nr11 1]
set x1_pl10 [sd_l 10 $E]; set q1pm2 [sd_m 10]; set vdd_p11 [sd_r 11 $E]
pdc_region [lindex $x1_pl10 0] [lindex $x1_pl10 1]
pdc_region [lindex $q1pm2 0] [lindex $q1pm2 1]
pdc_region [lindex $vdd_p11 0] [lindex $vdd_p11 1]
cogc_at 10; cogc_at 11
drain_m1_v [lindex $x1_nl10 0] [lindex $x1_nl10 1]
vdd_connect [lindex $vdd_p11 0] [lindex $vdd_p11 1]

# --- Block [12]: Buffer INV x0→d0 ---
# N: VSS-G12(x0)-d0   P: VDD-G12(x0)-d0
nmos_block_ex 12 12 $E $E
pmos_block_ex 12 12 $E $E
set vss_l12 [sd_l 12 $E]; set d0_sd [sd_r 12 $E]
ndc_region [lindex $vss_l12 0] [lindex $vss_l12 1]
ndc_region [lindex $d0_sd 0] [lindex $d0_sd 1]
pdc_region [lindex $vss_l12 0] [lindex $vss_l12 1]
pdc_region [lindex $d0_sd 0] [lindex $d0_sd 1]
cogc_at 12
vss_connect [lindex $vss_l12 0] [lindex $vss_l12 1]
vdd_connect [lindex $vss_l12 0] [lindex $vss_l12 1]
drain_m1_v [lindex $d0_sd 0] [lindex $d0_sd 1]

# --- Block [13]: Buffer INV x1→d1 ---
nmos_block_ex 13 13 $E $E
pmos_block_ex 13 13 $E $E
set vss_l13 [sd_l 13 $E]; set d1_sd [sd_r 13 $E]
ndc_region [lindex $vss_l13 0] [lindex $vss_l13 1]
ndc_region [lindex $d1_sd 0] [lindex $d1_sd 1]
pdc_region [lindex $vss_l13 0] [lindex $vss_l13 1]
pdc_region [lindex $d1_sd 0] [lindex $d1_sd 1]
cogc_at 13
vss_connect [lindex $vss_l13 0] [lindex $vss_l13 1]
vdd_connect [lindex $vss_l13 0] [lindex $vss_l13 1]
drain_m1_v [lindex $d1_sd 0] [lindex $d1_sd 1]

# --- Block [14,15]: AOI22 stackA ---
# N: noh1-G14(d0)-a1nm1-G15(x1)-VSS
# P: VDD-G14(d0)-a1pm-G15(x1)-VDD
nmos_block_ex 14 15 $E $E
pmos_block_ex 14 15 $E $E
set noh1_nl [sd_l 14 $E]; set a1nm1 [sd_m 14]; set vss_r15 [sd_r 15 $E]
ndc_region [lindex $noh1_nl 0] [lindex $noh1_nl 1]
ndc_region [lindex $a1nm1 0] [lindex $a1nm1 1]
ndc_region [lindex $vss_r15 0] [lindex $vss_r15 1]
set vdd_l14 [sd_l 14 $E]; set a1pm_p1 [sd_m 14]; set vdd_r15 [sd_r 15 $E]
pdc_region [lindex $vdd_l14 0] [lindex $vdd_l14 1]
pdc_region [lindex $a1pm_p1 0] [lindex $a1pm_p1 1]
pdc_region [lindex $vdd_r15 0] [lindex $vdd_r15 1]
cogc_at 14; cogc_at 15
# NMOS noh1 at left — only NMOS M1 pad (PMOS left is VDD)
nmos_m1_pad [lindex $noh1_nl 0] [lindex $noh1_nl 1]
vss_connect [lindex $vss_r15 0] [lindex $vss_r15 1]
vdd_connect [lindex $vdd_l14 0] [lindex $vdd_l14 1]
vdd_connect [lindex $vdd_r15 0] [lindex $vdd_r15 1]
# a1pm PMOS pad
pmos_m1_pad [lindex $a1pm_p1 0] [lindex $a1pm_p1 1]

# --- Block [16,17]: AOI22 stackB ---
# N: noh1-G16(x0)-a1nm2-G17(d1)-VSS
# P: noh1-G16(x0)-a1pm-G17(d1)-noh1
nmos_block_ex 16 17 $E $E
pmos_block_ex 16 17 $E $E
set noh1_nl2 [sd_l 16 $E]; set a1nm2 [sd_m 16]; set vss_r17 [sd_r 17 $E]
ndc_region [lindex $noh1_nl2 0] [lindex $noh1_nl2 1]
ndc_region [lindex $a1nm2 0] [lindex $a1nm2 1]
ndc_region [lindex $vss_r17 0] [lindex $vss_r17 1]
set noh1_pl2 [sd_l 16 $E]; set a1pm_p2 [sd_m 16]; set noh1_pr2 [sd_r 17 $E]
pdc_region [lindex $noh1_pl2 0] [lindex $noh1_pl2 1]
pdc_region [lindex $a1pm_p2 0] [lindex $a1pm_p2 1]
pdc_region [lindex $noh1_pr2 0] [lindex $noh1_pr2 1]
cogc_at 16; cogc_at 17
# N/P left = noh1 drain (both NMOS and PMOS)
drain_m1_v [lindex $noh1_nl2 0] [lindex $noh1_nl2 1]
vss_connect [lindex $vss_r17 0] [lindex $vss_r17 1]
# PMOS right = noh1 drain (only PMOS, NMOS right = VSS)
pmos_m1_pad [lindex $noh1_pr2 0] [lindex $noh1_pr2 1]
# a1pm PMOS pad
pmos_m1_pad [lindex $a1pm_p2 0] [lindex $a1pm_p2 1]

# --- Block [18,19]: NAND2 nOH2 ---
# N: noh2-G18(d0)-n2ns-G19(d1)-VSS
# P: noh2-G18(d0)-VDD-G19(d1)-noh2
nmos_block_ex 18 19 $E 14
pmos_block_ex 18 19 $E 14
set noh2_nl [sd_l 18 $E]; set n2ns [sd_m 18]; set vss_r19 [sd_r 19 14]
ndc_region [lindex $noh2_nl 0] [lindex $noh2_nl 1]
ndc_region [lindex $n2ns 0] [lindex $n2ns 1]
ndc_region [lindex $vss_r19 0] [lindex $vss_r19 1]
set noh2_pl [sd_l 18 $E]; set vdd_1819 [sd_m 18]; set noh2_pr [sd_r 19 14]
pdc_region [lindex $noh2_pl 0] [lindex $noh2_pl 1]
pdc_region [lindex $vdd_1819 0] [lindex $vdd_1819 1]
pdc_region [lindex $noh2_pr 0] [lindex $noh2_pr 1]
cogc_at 18; cogc_at 19
# N/P left = noh2 drain
drain_m1_v [lindex $noh2_nl 0] [lindex $noh2_nl 1]
vss_connect [lindex $vss_r19 0] [lindex $vss_r19 1]
vdd_connect [lindex $vdd_1819 0] [lindex $vdd_1819 1]
# PMOS right = noh2 (only PMOS, NMOS right = VSS)
pmos_m1_pad [lindex $noh2_pr 0] [lindex $noh2_pr 1]

# ============================================================
# M2 SIGNAL ROUTING
# ============================================================

# --- x0 net ---
# Sources: PMOS left of 4 (pad), NMOS/PMOS left of 6 (drain_m1_v)
# NMOS right of 7 (ndc pad)
# Destinations: gate 12 (cogc), gate 16 (cogc)
set x0_p4x [expr {[lindex $x0_p4 0] + 4}]
set x0_l6x [expr {[lindex $x0_nl6 0] + 4}]
set x0_r7x [expr {[lindex $x0_nr7 0] + 4}]
set g12c [expr {[gx 12] + 4}]
set g16c [expr {[gx 16] + 4}]
# M2 bus y=62-68
box $x0_p4x 62 [expr {$g16c + 6}] 68
paint metal2
# Via1 to PMOS x0 pad at left of 4
box $x0_p4x 98 [expr {$x0_p4x + 6}] 104
paint via1
box $x0_p4x 62 [expr {$x0_p4x + 6}] 104
paint metal2
# Via1 to drain_m1_v at left of 6
box $x0_l6x 62 [expr {$x0_l6x + 6}] 68
paint via1
# Via1 to NMOS x0 pad at right of 7
box $x0_r7x 30 [expr {$x0_r7x + 6}] 36
paint via1
box $x0_r7x 36 [expr {$x0_r7x + 6}] 62
paint metal2
# Via1 to gate 12 cogc
box $g12c 62 [expr {$g12c + 6}] 68
paint via1
# Via1 to gate 16 cogc
box $g16c 62 [expr {$g16c + 6}] 68
paint via1

# --- x1 net ---
set x1_p8x [expr {[lindex $x1_p8 0] + 4}]
set x1_l10x [expr {[lindex $x1_nl10 0] + 4}]
set x1_r11x [expr {[lindex $x1_nr11 0] + 4}]
set g13c [expr {[gx 13] + 4}]
set g15c [expr {[gx 15] + 4}]
# M2 bus y=52-58
box $x1_p8x 52 [expr {$g15c + 6}] 58
paint metal2
box $x1_p8x 98 [expr {$x1_p8x + 6}] 104
paint via1
box $x1_p8x 52 [expr {$x1_p8x + 6}] 104
paint metal2
box $x1_l10x 52 [expr {$x1_l10x + 6}] 58
paint via1
box $x1_r11x 30 [expr {$x1_r11x + 6}] 36
paint via1
box $x1_r11x 36 [expr {$x1_r11x + 6}] 52
paint metal2
box $g13c 52 [expr {$g13c + 6}] 58
paint via1
box $g15c 52 [expr {$g15c + 6}] 58
paint via1

# --- d0 net: drain of INV12 → gate 14, gate 18 ---
set d0x [expr {[lindex $d0_sd 0] + 4}]
set g14c [expr {[gx 14] + 4}]
set g18c [expr {[gx 18] + 4}]
box $d0x 72 [expr {$g18c + 6}] 78
paint metal2
box $d0x 72 [expr {$d0x + 6}] 78
paint via1
box $g14c 72 [expr {$g14c + 6}] 78
paint via1
box $g18c 72 [expr {$g18c + 6}] 78
paint via1

# --- d1 net: drain of INV13 → gate 17, gate 19 ---
set d1x [expr {[lindex $d1_sd 0] + 4}]
set g17c [expr {[gx 17] + 4}]
set g19c [expr {[gx 19] + 4}]
box $d1x 82 [expr {$g19c + 6}] 88
paint metal2
box $d1x 82 [expr {$d1x + 6}] 88
paint via1
box $g17c 82 [expr {$g17c + 6}] 88
paint via1
box $g19c 82 [expr {$g19c + 6}] 88
paint via1

# --- nai net: INV0 drain → gate 4 ---
set naix [expr {[lindex $nai_n 0] + 4}]
set g4c [expr {[gx 4] + 4}]
box $naix 100 [expr {$g4c + 6}] 106
paint metal2
box $naix 100 [expr {$naix + 6}] 106
paint via1
box $g4c 100 [expr {$g4c + 6}] 106
paint via1

# --- nbi net: INV1 drain → gate 5 ---
set nbix [expr {[lindex $nbi_n 0] + 4}]
set g5c [expr {[gx 5] + 4}]
box $nbix 92 [expr {$g5c + 6}] 98
paint metal2
box $nbix 92 [expr {$nbix + 6}] 98
paint via1
box $g5c 92 [expr {$g5c + 6}] 98
paint via1

# --- naj net: INV2 drain → gate 8 ---
set najx [expr {[lindex $naj_n 0] + 4}]
set g8c [expr {[gx 8] + 4}]
box $najx 100 [expr {$g8c + 6}] 106
paint metal2
box $najx 100 [expr {$najx + 6}] 106
paint via1
box $g8c 100 [expr {$g8c + 6}] 106
paint via1

# --- nbj net: INV3 drain → gate 9 ---
set nbjx [expr {[lindex $nbj_n 0] + 4}]
set g9c [expr {[gx 9] + 4}]
box $nbjx 92 [expr {$g9c + 6}] 98
paint metal2
box $nbjx 92 [expr {$nbjx + 6}] 98
paint via1
box $g9c 92 [expr {$g9c + 6}] 98
paint via1

# --- q0nmid: NMOS between 4-5 → between 6-7 ---
set q0m1x [expr {[lindex $q0nm 0] + 4}]
set q0m2x [expr {[lindex $q0nm2 0] + 4}]
box $q0m1x 42 [expr {$q0m2x + 6}] 48
paint metal2
box $q0m1x 42 [expr {$q0m1x + 6}] 48
paint via1
box $q0m2x 42 [expr {$q0m2x + 6}] 48
paint via1

# --- q1nmid: NMOS between 8-9 → between 10-11 ---
set q1m1x [expr {[lindex $q1nm 0] + 4}]
set q1m2x [expr {[lindex $q1nm2 0] + 4}]
box $q1m1x 42 [expr {$q1m2x + 6}] 48
paint metal2
box $q1m1x 42 [expr {$q1m1x + 6}] 48
paint via1
box $q1m2x 42 [expr {$q1m2x + 6}] 48
paint via1

# --- ai direct: gate 0 → gate 6 ---
set g0c [expr {[gx 0] + 4}]
set g6c [expr {[gx 6] + 4}]
box $g0c 110 [expr {$g6c + 6}] 116
paint metal2
box $g0c 110 [expr {$g0c + 6}] 116
paint via1
box $g6c 110 [expr {$g6c + 6}] 116
paint via1

# --- bi direct: gate 1 → gate 7 ---
set g1c [expr {[gx 1] + 4}]
set g7c [expr {[gx 7] + 4}]
box $g1c 118 [expr {$g7c + 6}] 124
paint metal2
box $g1c 118 [expr {$g1c + 6}] 124
paint via1
box $g7c 118 [expr {$g7c + 6}] 124
paint via1

# --- aj direct: gate 2 → gate 10 ---
set g2c [expr {[gx 2] + 4}]
set g10c [expr {[gx 10] + 4}]
box $g2c 110 [expr {$g10c + 6}] 116
paint metal2
box $g2c 110 [expr {$g2c + 6}] 116
paint via1
box $g10c 110 [expr {$g10c + 6}] 116
paint via1

# --- bj direct: gate 3 → gate 11 ---
set g3c [expr {[gx 3] + 4}]
set g11c [expr {[gx 11] + 4}]
box $g3c 118 [expr {$g11c + 6}] 124
paint metal2
box $g3c 118 [expr {$g3c + 6}] 124
paint via1
box $g11c 118 [expr {$g11c + 6}] 124
paint via1

# --- noh1: connect NMOS pads and PMOS pads ---
# noh1 sources: NMOS left 14, N/P left 16 (drain_m1_v), PMOS right 17
# Route via M2 at y=32-38
set noh1_n14x [expr {[lindex $noh1_nl 0] + 4}]
set noh1_l16x [expr {[lindex $noh1_nl2 0] + 4}]
set noh1_p17x [expr {[lindex $noh1_pr2 0] + 4}]
# M2 horizontal bus connecting noh1 NMOS pad at left14 to drain_m1_v at left16
box $noh1_n14x 32 [expr {$noh1_l16x + 6}] 38
paint metal2
box $noh1_n14x 32 [expr {$noh1_n14x + 6}] 38
paint via1
box $noh1_l16x 32 [expr {$noh1_l16x + 6}] 38
paint via1
# Connect PMOS noh1 right of 17 to noh1 bus via M2 vertical
box $noh1_p17x 100 [expr {$noh1_p17x + 6}] 106
paint via1
box $noh1_p17x 38 [expr {$noh1_p17x + 6}] 106
paint metal2

# --- a1pm: PMOS pad between 14-15 → between 16-17 ---
set a1pm1x [expr {[lindex $a1pm_p1 0] + 4}]
set a1pm2x [expr {[lindex $a1pm_p2 0] + 4}]
box $a1pm1x 88 [expr {$a1pm2x + 6}] 94
paint metal2
box $a1pm1x 88 [expr {$a1pm1x + 6}] 94
paint via1
box $a1pm2x 88 [expr {$a1pm2x + 6}] 94
paint via1

# --- noh2: connect PMOS right of 19 to drain_m1_v at left of 18 ---
set noh2_l18x [expr {[lindex $noh2_nl 0] + 4}]
set noh2_p19x [expr {[lindex $noh2_pr 0] + 4}]
box $noh2_l18x 25 [expr {$noh2_p19x + 6}] 31
paint metal2
box $noh2_l18x 25 [expr {$noh2_l18x + 6}] 31
paint via1
box $noh2_p19x 100 [expr {$noh2_p19x + 6}] 106
paint via1
box $noh2_p19x 31 [expr {$noh2_p19x + 6}] 106
paint metal2

# ============================================================
# LABELS
# ============================================================
box [expr {[gx 0] + 4}] 65 [expr {[gx 0] + 10}] 65
label ai 1 cogc
box [expr {[gx 1] + 4}] 65 [expr {[gx 1] + 10}] 65
label bi 1 cogc
box [expr {[gx 2] + 4}] 65 [expr {[gx 2] + 10}] 65
label aj 1 cogc
box [expr {[gx 3] + 4}] 65 [expr {[gx 3] + 10}] 65
label bj 1 cogc

# noh1 label on M2 bus (not on ndc!)
box [expr {$noh1_n14x + 2}] 35 [expr {$noh1_n14x + 2}] 35
label noh1 1 metal2

# noh2 label on M2 bus
box [expr {$noh2_l18x + 2}] 28 [expr {$noh2_l18x + 2}] 28
label noh2 1 metal2

box [expr {$W / 2}] 133 [expr {$W / 2}] 133
label VDD 3 metal1
box [expr {$W / 2}] 7 [expr {$W / 2}] 7
label VSS 1 metal1

save /Users/bruce/CLAUDE/asap5/stdcells/fused_ppa/FUSED_G

drc catchup
set drc_count [drc count]
puts "FUSED_G DRC violations: $drc_count"

extract all
ext2spice lvs
ext2spice -f ngspice -o /Users/bruce/CLAUDE/asap5/stdcells/fused_ppa/FUSED_G_ext.spice

ext2spice cthresh 0
ext2spice -f ngspice -o /Users/bruce/CLAUDE/asap5/stdcells/fused_ppa/FUSED_G_ext_full.spice

puts "FUSED_G layout complete: ${W}nm x ${H}nm, $NG gate pitches, 40T (SLVT)"
