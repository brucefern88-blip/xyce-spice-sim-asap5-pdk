# Build FUSED_G double-height layout — 40T active-low fused Hamming cell
# Width: 12 CPP = 528nm, Height: 2 x 140nm = 280nm
# Aspect ratio: 528/280 = 1.89:1 (target <= 2:1)
#
# Double-height standard cell structure:
#   Row 1 (bottom): VSS(y=0..14) — NMOS(y=10..55) — cogc(y=60..70) — PMOS(y=85..130) — VDD(y=126..154)
#   Row 2 (top, mirrored): VDD(shared) — PMOS(y=150..195) — cogc(y=200..210) — NMOS(y=225..270) — VSS(y=266..280)
#
# Gate assignment:
#   Row 1 (gates R1_0..R1_11):
#     0:INV(ai) 1:INV(bi) 2:INV(aj) 3:INV(bj)
#     4:OAI22_0A(nai) 5:OAI22_0A(nbi) 6:OAI22_0B(ai) 7:OAI22_0B(bi)
#     8:OAI22_1A(naj) 9:OAI22_1A(nbj) 10:OAI22_1B(aj) 11:OAI22_1B(bj)
#   Row 2 (gates R2_0..R2_7):
#     0:INV(x0->d0) 1:INV(x1->d1)
#     2:AOI22_A(d0) 3:AOI22_A(x1) 4:AOI22_B(x0) 5:AOI22_B(d1)
#     6:NAND2(d0) 7:NAND2(d1)

# === Geometry helpers ===
# Row 1 and Row 2 share the same x-grid (12 CPP positions)
proc gx {n} { return [expr {14 + $n * 44}] }
proc gxr {n} { return [expr {14 + $n * 44 + 16}] }

set W 528
set H 280

cellname rename (UNNAMED) FUSED_G
box 0 0 $W $H

# === NWELL: continuous through both PMOS regions and shared VDD ===
box 0 65 $W 215
paint nwell

# === Power Rails (M1) ===
box 0 0 $W 14
paint metal1
box 0 126 $W 154
paint metal1
box 0 266 $W 280
paint metal1

# === POLY ===
# Row 1: 12 gates
for {set n 0} {$n < 12} {incr n} {
    set xl [gx $n]
    set xr [gxr $n]
    box $xl 5 $xr 10
    paint poly
    box $xl 55 $xr 58
    paint poly
    box $xl 58 [expr {$xl + 2}] 72
    paint poly
    box [expr {$xr - 2}] 58 $xr 72
    paint poly
    box $xl 72 $xr 75
    paint poly
    box $xl 130 $xr 135
    paint poly
}
# Row 2: 8 gates (positions 0-7)
for {set n 0} {$n < 8} {incr n} {
    set xl [gx $n]
    set xr [gxr $n]
    box $xl 145 $xr 150
    paint poly
    box $xl 195 $xr 198
    paint poly
    box $xl 198 [expr {$xl + 2}] 212
    paint poly
    box [expr {$xr - 2}] 198 $xr 212
    paint poly
    box $xl 212 $xr 215
    paint poly
    box $xl 270 $xr 275
    paint poly
}

# ===================================================================
# Helper procs — Row 1
# ===================================================================
proc r1_nmos {first last {lpad 14} {rpad 14}} {
    set s [expr {[gx $first] - $lpad}]
    set e [expr {[gxr $last] + $rpad}]
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
proc r1_pmos {first last {lpad 14} {rpad 14}} {
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
proc r1_ndc_at {xl xr} {
    box [expr {$xl + 2}] 20 [expr {$xr - 2}] 45
    paint ndc
}
proc r1_pdc_at {xl xr} {
    box [expr {$xl + 2}] 95 [expr {$xr - 2}] 120
    paint pdc
}
proc r1_cogc_at {n} {
    set xl [expr {[gx $n] + 2}]
    set xr [expr {[gxr $n] - 2}]
    box $xl 60 $xr 70
    paint cogc
    box $xl 60 $xr 70
    paint metal1
}
# S/D boundary helpers (return {left_x right_x} of the S/D region)
proc r1_sdl {g {pad 14}} { return [list [expr {[gx $g] - $pad}] [gx $g]] }
proc r1_sdb {g} { return [list [gxr $g] [gx [expr {$g+1}]]] }
proc r1_sdr {g {pad 14}} { return [list [gxr $g] [expr {[gxr $g] + $pad}]] }
# Full drain M1 (connects NMOS and PMOS S/D at same position)
proc r1_drain_m1 {sd} {
    box [expr {[lindex $sd 0] + 2}] 20 [expr {[lindex $sd 1] - 2}] 120
    paint metal1
}
# NMOS-only M1 pad
proc r1_nmos_m1 {sd} {
    box [expr {[lindex $sd 0] + 2}] 20 [expr {[lindex $sd 1] - 2}] 45
    paint metal1
}
# PMOS-only M1 pad
proc r1_pmos_m1 {sd} {
    box [expr {[lindex $sd 0] + 2}] 95 [expr {[lindex $sd 1] - 2}] 120
    paint metal1
}
# VSS connection (M1 from S/D to VSS rail)
proc r1_vss_m1 {sd} {
    box [expr {[lindex $sd 0] + 2}] 7 [expr {[lindex $sd 1] - 2}] 45
    paint metal1
}
# VDD connection (M1 from S/D to VDD rail)
proc r1_vdd_m1 {sd} {
    box [expr {[lindex $sd 0] + 2}] 95 [expr {[lindex $sd 1] - 2}] 133
    paint metal1
}

# ===================================================================
# Helper procs — Row 2 (mirrored: PMOS near VDD, NMOS near top VSS)
# ===================================================================
proc r2_pmos {first last {lpad 14} {rpad 14}} {
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
proc r2_nmos {first last {lpad 14} {rpad 14}} {
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
proc r2_pdc_at {xl xr} {
    box [expr {$xl + 2}] 160 [expr {$xr - 2}] 185
    paint pdc
}
proc r2_ndc_at {xl xr} {
    box [expr {$xl + 2}] 235 [expr {$xr - 2}] 260
    paint ndc
}
proc r2_cogc_at {n} {
    set xl [expr {[gx $n] + 2}]
    set xr [expr {[gxr $n] - 2}]
    box $xl 200 $xr 210
    paint cogc
    box $xl 200 $xr 210
    paint metal1
}
proc r2_sdl {g {pad 14}} { return [list [expr {[gx $g] - $pad}] [gx $g]] }
proc r2_sdb {g} { return [list [gxr $g] [gx [expr {$g+1}]]] }
proc r2_sdr {g {pad 14}} { return [list [gxr $g] [expr {[gxr $g] + $pad}]] }
# Full drain M1 (PMOS + NMOS)
proc r2_drain_m1 {sd} {
    box [expr {[lindex $sd 0] + 2}] 160 [expr {[lindex $sd 1] - 2}] 260
    paint metal1
}
# NMOS-only M1 pad
proc r2_nmos_m1 {sd} {
    box [expr {[lindex $sd 0] + 2}] 235 [expr {[lindex $sd 1] - 2}] 260
    paint metal1
}
# PMOS-only M1 pad
proc r2_pmos_m1 {sd} {
    box [expr {[lindex $sd 0] + 2}] 160 [expr {[lindex $sd 1] - 2}] 185
    paint metal1
}
# VSS top connection
proc r2_vss_m1 {sd} {
    box [expr {[lindex $sd 0] + 2}] 235 [expr {[lindex $sd 1] - 2}] 273
    paint metal1
}
# VDD shared connection
proc r2_vdd_m1 {sd} {
    box [expr {[lindex $sd 0] + 2}] 147 [expr {[lindex $sd 1] - 2}] 185
    paint metal1
}

# ===================================================================
# BUILD ROW 1 DIFFUSION BLOCKS
# ===================================================================
# Each block is a continuous diff region with shared S/D between gates.
# Blocks are separated by diffusion breaks (gap >= 4nm between them).
# Outer edges use 14nm pad, inner boundaries use 12nm pad for 4nm gap.
#
# Block 1: Gates 0-1 (INV ai, INV bi)
#   N: nai-G0(ai)-VSS-G1(bi)-nbi
#   P: nai-G0(ai)-VDD-G1(bi)-nbi
r1_nmos 0 1 14 12
r1_pmos 0 1 14 12
foreach p {0 1} { r1_cogc_at $p }
set nai [r1_sdl 0 14]
set vss01 [r1_sdb 0]
set nbi [r1_sdr 1 12]
r1_ndc_at [lindex $nai 0] [lindex $nai 1]
r1_ndc_at [lindex $vss01 0] [lindex $vss01 1]
r1_ndc_at [lindex $nbi 0] [lindex $nbi 1]
r1_pdc_at [lindex $nai 0] [lindex $nai 1]
r1_pdc_at [lindex $vss01 0] [lindex $vss01 1]
r1_pdc_at [lindex $nbi 0] [lindex $nbi 1]
r1_drain_m1 $nai
r1_vss_m1 $vss01
r1_vdd_m1 $vss01
r1_drain_m1 $nbi

# Block 2: Gates 2-3 (INV aj, INV bj)
#   N: naj-G2(aj)-VSS-G3(bj)-nbj
#   P: naj-G2(aj)-VDD-G3(bj)-nbj
r1_nmos 2 3 12 12
r1_pmos 2 3 12 12
foreach p {2 3} { r1_cogc_at $p }
set naj [r1_sdl 2 12]
set vss23 [r1_sdb 2]
set nbj [r1_sdr 3 12]
r1_ndc_at [lindex $naj 0] [lindex $naj 1]
r1_ndc_at [lindex $vss23 0] [lindex $vss23 1]
r1_ndc_at [lindex $nbj 0] [lindex $nbj 1]
r1_pdc_at [lindex $naj 0] [lindex $naj 1]
r1_pdc_at [lindex $vss23 0] [lindex $vss23 1]
r1_pdc_at [lindex $nbj 0] [lindex $nbj 1]
r1_drain_m1 $naj
r1_vss_m1 $vss23
r1_vdd_m1 $vss23
r1_drain_m1 $nbj

# Block 3: Gates 4-5 (OAI22 XOR0 stack A)
#   N: VSS-G4(nai)-q0nmid-G5(nbi)-VSS (parallel NMOS)
#   P: x0-G4(nai)-q0pm1-G5(nbi)-VDD (series PMOS)
r1_nmos 4 5 12 12
r1_pmos 4 5 12 12
foreach p {4 5} { r1_cogc_at $p }
set oai0a_l [r1_sdl 4 12]
set q0nmid_45 [r1_sdb 4]
set oai0a_r [r1_sdr 5 12]
r1_ndc_at [lindex $oai0a_l 0] [lindex $oai0a_l 1]
r1_ndc_at [lindex $q0nmid_45 0] [lindex $q0nmid_45 1]
r1_ndc_at [lindex $oai0a_r 0] [lindex $oai0a_r 1]
r1_pdc_at [lindex $oai0a_l 0] [lindex $oai0a_l 1]
r1_pdc_at [lindex $q0nmid_45 0] [lindex $q0nmid_45 1]
r1_pdc_at [lindex $oai0a_r 0] [lindex $oai0a_r 1]
# N left=VSS, N right=VSS; P left=x0, P right=VDD
r1_vss_m1 $oai0a_l
r1_vss_m1 $oai0a_r
r1_pmos_m1 $oai0a_l ;# x0 PMOS pad only (NMOS is VSS)
r1_vdd_m1 $oai0a_r

# Block 4: Gates 6-7 (OAI22 XOR0 stack B)
#   N: x0-G6(ai)-q0nmid-G7(bi)-x0 (parallel NMOS)
#   P: x0-G6(ai)-q0pm2-G7(bi)-VDD (series PMOS)
r1_nmos 6 7 12 12
r1_pmos 6 7 12 12
foreach p {6 7} { r1_cogc_at $p }
set oai0b_l [r1_sdl 6 12]
set q0nmid_67 [r1_sdb 6]
set oai0b_r [r1_sdr 7 12]
r1_ndc_at [lindex $oai0b_l 0] [lindex $oai0b_l 1]
r1_ndc_at [lindex $q0nmid_67 0] [lindex $q0nmid_67 1]
r1_ndc_at [lindex $oai0b_r 0] [lindex $oai0b_r 1]
r1_pdc_at [lindex $oai0b_l 0] [lindex $oai0b_l 1]
r1_pdc_at [lindex $q0nmid_67 0] [lindex $q0nmid_67 1]
r1_pdc_at [lindex $oai0b_r 0] [lindex $oai0b_r 1]
# N left=x0, N right=x0; P left=x0, P right=VDD
r1_drain_m1 $oai0b_l ;# x0: both N and P share this
r1_nmos_m1 $oai0b_r  ;# x0 NMOS pad only (PMOS=VDD)
r1_vdd_m1 $oai0b_r

# Block 5: Gates 8-9 (OAI22 XOR1 stack A)
#   N: VSS-G8(naj)-q1nmid-G9(nbj)-VSS
#   P: x1-G8(naj)-q1pm1-G9(nbj)-VDD
r1_nmos 8 9 12 12
r1_pmos 8 9 12 12
foreach p {8 9} { r1_cogc_at $p }
set oai1a_l [r1_sdl 8 12]
set q1nmid_89 [r1_sdb 8]
set oai1a_r [r1_sdr 9 12]
r1_ndc_at [lindex $oai1a_l 0] [lindex $oai1a_l 1]
r1_ndc_at [lindex $q1nmid_89 0] [lindex $q1nmid_89 1]
r1_ndc_at [lindex $oai1a_r 0] [lindex $oai1a_r 1]
r1_pdc_at [lindex $oai1a_l 0] [lindex $oai1a_l 1]
r1_pdc_at [lindex $q1nmid_89 0] [lindex $q1nmid_89 1]
r1_pdc_at [lindex $oai1a_r 0] [lindex $oai1a_r 1]
r1_vss_m1 $oai1a_l
r1_vss_m1 $oai1a_r
r1_pmos_m1 $oai1a_l ;# x1 PMOS pad
r1_vdd_m1 $oai1a_r

# Block 6: Gates 10-11 (OAI22 XOR1 stack B)
#   N: x1-G10(aj)-q1nmid-G11(bj)-x1
#   P: x1-G10(aj)-q1pm2-G11(bj)-VDD
r1_nmos 10 11 12 14
r1_pmos 10 11 12 14
foreach p {10 11} { r1_cogc_at $p }
set oai1b_l [r1_sdl 10 12]
set q1nmid_1011 [r1_sdb 10]
set oai1b_r [r1_sdr 11 14]
r1_ndc_at [lindex $oai1b_l 0] [lindex $oai1b_l 1]
r1_ndc_at [lindex $q1nmid_1011 0] [lindex $q1nmid_1011 1]
r1_ndc_at [lindex $oai1b_r 0] [lindex $oai1b_r 1]
r1_pdc_at [lindex $oai1b_l 0] [lindex $oai1b_l 1]
r1_pdc_at [lindex $q1nmid_1011 0] [lindex $q1nmid_1011 1]
r1_pdc_at [lindex $oai1b_r 0] [lindex $oai1b_r 1]
r1_drain_m1 $oai1b_l
r1_nmos_m1 $oai1b_r
r1_vdd_m1 $oai1b_r

# ===================================================================
# BUILD ROW 2 DIFFUSION BLOCKS
# ===================================================================

# Block 7: Gates R2_0-R2_1 (INV x0->d0, INV x1->d1)
#   N: d0-G0(x0)-VSS-G1(x1)-d1
#   P: d0-G0(x0)-VDD-G1(x1)-d1
r2_pmos 0 1 14 12
r2_nmos 0 1 14 12
foreach p {0 1} { r2_cogc_at $p }
set d0 [r2_sdl 0 14]
set r2_vs01 [r2_sdb 0]
set d1 [r2_sdr 1 12]
r2_pdc_at [lindex $d0 0] [lindex $d0 1]
r2_pdc_at [lindex $r2_vs01 0] [lindex $r2_vs01 1]
r2_pdc_at [lindex $d1 0] [lindex $d1 1]
r2_ndc_at [lindex $d0 0] [lindex $d0 1]
r2_ndc_at [lindex $r2_vs01 0] [lindex $r2_vs01 1]
r2_ndc_at [lindex $d1 0] [lindex $d1 1]
r2_drain_m1 $d0
r2_vdd_m1 $r2_vs01
r2_vss_m1 $r2_vs01
r2_drain_m1 $d1

# Block 8: Gates R2_2-R2_3 (AOI22 noh1 stack A)
#   N: noh1-G2(d0)-a1nm1-G3(x1)-VSS (series)
#   P: VDD-G2(d0)-a1pm-G3(x1)-VDD (parallel)
r2_pmos 2 3 12 12
r2_nmos 2 3 12 12
foreach p {2 3} { r2_cogc_at $p }
set aoi_a_l [r2_sdl 2 12]
set a1nm1 [r2_sdb 2]
set aoi_a_r [r2_sdr 3 12]
r2_pdc_at [lindex $aoi_a_l 0] [lindex $aoi_a_l 1]
r2_pdc_at [lindex $a1nm1 0] [lindex $a1nm1 1]
r2_pdc_at [lindex $aoi_a_r 0] [lindex $aoi_a_r 1]
r2_ndc_at [lindex $aoi_a_l 0] [lindex $aoi_a_l 1]
r2_ndc_at [lindex $a1nm1 0] [lindex $a1nm1 1]
r2_ndc_at [lindex $aoi_a_r 0] [lindex $aoi_a_r 1]
# N left=noh1 (NMOS pad), N right=VSS; P left=VDD, P right=VDD
r2_nmos_m1 $aoi_a_l ;# noh1 NMOS pad only
r2_vdd_m1 $aoi_a_l  ;# VDD on PMOS side
r2_vss_m1 $aoi_a_r
r2_vdd_m1 $aoi_a_r

# Block 9: Gates R2_4-R2_5 (AOI22 noh1 stack B)
#   N: noh1-G4(x0)-a1nm2-G5(d1)-VSS (series)
#   P: noh1-G4(x0)-a1pm-G5(d1)-noh1 (parallel, output=noh1)
r2_pmos 4 5 12 12
r2_nmos 4 5 12 12
foreach p {4 5} { r2_cogc_at $p }
set aoi_b_l [r2_sdl 4 12]
set a1nm2 [r2_sdb 4]
set aoi_b_r [r2_sdr 5 12]
r2_pdc_at [lindex $aoi_b_l 0] [lindex $aoi_b_l 1]
r2_pdc_at [lindex $a1nm2 0] [lindex $a1nm2 1]
r2_pdc_at [lindex $aoi_b_r 0] [lindex $aoi_b_r 1]
r2_ndc_at [lindex $aoi_b_l 0] [lindex $aoi_b_l 1]
r2_ndc_at [lindex $a1nm2 0] [lindex $a1nm2 1]
r2_ndc_at [lindex $aoi_b_r 0] [lindex $aoi_b_r 1]
# N left=noh1 (NMOS pad), N right=VSS
# P left=noh1 (full drain), P between=a1pm, P right=noh1 (PMOS pad)
r2_drain_m1 $aoi_b_l ;# noh1: NMOS and PMOS both = noh1
r2_vss_m1 $aoi_b_r   ;# VSS on NMOS side
r2_pmos_m1 $aoi_b_r  ;# noh1 PMOS pad at right (NMOS=VSS, different signal)

# Block 10: Gates R2_6-R2_7 (NAND2 noh2)
#   N: noh2-G6(d0)-n2ns-G7(d1)-VSS (series)
#   P: noh2-G6(d0)-VDD-G7(d1)-noh2 (parallel)
r2_pmos 6 7 12 14
r2_nmos 6 7 12 14
foreach p {6 7} { r2_cogc_at $p }
set nand_l [r2_sdl 6 12]
set n2ns [r2_sdb 6]
set nand_r [r2_sdr 7 14]
r2_pdc_at [lindex $nand_l 0] [lindex $nand_l 1]
r2_pdc_at [lindex $n2ns 0] [lindex $n2ns 1]
r2_pdc_at [lindex $nand_r 0] [lindex $nand_r 1]
r2_ndc_at [lindex $nand_l 0] [lindex $nand_l 1]
r2_ndc_at [lindex $n2ns 0] [lindex $n2ns 1]
r2_ndc_at [lindex $nand_r 0] [lindex $nand_r 1]
# N left=noh2 (drain), N right=VSS
# P left=noh2, P between=VDD, P right=noh2
r2_drain_m1 $nand_l ;# noh2: both N and P
r2_vss_m1 $nand_r   ;# VSS on NMOS side
r2_pmos_m1 $nand_r  ;# noh2 PMOS pad (NMOS=VSS)
r2_vdd_m1 $n2ns     ;# VDD between 6-7

# ===================================================================
# ROW 1: M2 INTRA-ROW ROUTING
# ===================================================================

# --- nai: INV0 drain -> OAI22 gate 4 cogc ---
# nai drain M1 at r1_sdl(0), via1 up to M2, route to gate 4 cogc via1
set nai_v [expr {[lindex $nai 0] + 4}]
set g4_v [expr {[gx 4] + 4}]
box $nai_v 100 [expr {$g4_v + 6}] 106
paint metal2
box $nai_v 100 [expr {$nai_v + 6}] 106
paint via1
box $g4_v 100 [expr {$g4_v + 6}] 106
paint via1

# --- nbi: INV1 drain -> OAI22 gate 5 cogc ---
set nbi_v [expr {[lindex $nbi 0] + 4}]
set g5_v [expr {[gx 5] + 4}]
box $nbi_v 92 [expr {$g5_v + 6}] 98
paint metal2
box $nbi_v 92 [expr {$nbi_v + 6}] 98
paint via1
box $g5_v 92 [expr {$g5_v + 6}] 98
paint via1

# --- naj: INV2 drain -> OAI22 gate 8 cogc ---
set naj_v [expr {[lindex $naj 0] + 4}]
set g8_v [expr {[gx 8] + 4}]
box $naj_v 100 [expr {$g8_v + 6}] 106
paint metal2
box $naj_v 100 [expr {$naj_v + 6}] 106
paint via1
box $g8_v 100 [expr {$g8_v + 6}] 106
paint via1

# --- nbj: INV3 drain -> OAI22 gate 9 cogc ---
set nbj_v [expr {[lindex $nbj 0] + 4}]
set g9_v [expr {[gx 9] + 4}]
box $nbj_v 92 [expr {$g9_v + 6}] 98
paint metal2
box $nbj_v 92 [expr {$nbj_v + 6}] 98
paint via1
box $g9_v 92 [expr {$g9_v + 6}] 98
paint via1

# --- ai: gate 0 cogc -> gate 6 cogc (OAI22 stack B) ---
set g0_v [expr {[gx 0] + 4}]
set g6_v [expr {[gx 6] + 4}]
box $g0_v 110 [expr {$g6_v + 6}] 116
paint metal2
box $g0_v 110 [expr {$g0_v + 6}] 116
paint via1
box $g6_v 110 [expr {$g6_v + 6}] 116
paint via1

# --- bi: gate 1 cogc -> gate 7 cogc ---
set g1_v [expr {[gx 1] + 4}]
set g7_v [expr {[gx 7] + 4}]
box $g1_v 118 [expr {$g7_v + 6}] 124
paint metal2
box $g1_v 118 [expr {$g1_v + 6}] 124
paint via1
box $g7_v 118 [expr {$g7_v + 6}] 124
paint via1

# --- aj: gate 2 cogc -> gate 10 cogc ---
set g2_v [expr {[gx 2] + 4}]
set g10_v [expr {[gx 10] + 4}]
box $g2_v 110 [expr {$g10_v + 6}] 116
paint metal2
box $g2_v 110 [expr {$g2_v + 6}] 116
paint via1
box $g10_v 110 [expr {$g10_v + 6}] 116
paint via1

# --- bj: gate 3 cogc -> gate 11 cogc ---
set g3_v [expr {[gx 3] + 4}]
set g11_v [expr {[gx 11] + 4}]
box $g3_v 118 [expr {$g11_v + 6}] 124
paint metal2
box $g3_v 118 [expr {$g3_v + 6}] 124
paint via1
box $g11_v 118 [expr {$g11_v + 6}] 124
paint via1

# --- q0nmid: NMOS between 4-5 to between 6-7 ---
set q0_45v [expr {[lindex $q0nmid_45 0] + 4}]
set q0_67v [expr {[lindex $q0nmid_67 0] + 4}]
box $q0_45v 34 [expr {$q0_67v + 6}] 40
paint metal2
box $q0_45v 34 [expr {$q0_45v + 6}] 40
paint via1
box $q0_67v 34 [expr {$q0_67v + 6}] 40
paint via1

# --- q1nmid: NMOS between 8-9 to between 10-11 ---
set q1_89v [expr {[lindex $q1nmid_89 0] + 4}]
set q1_1011v [expr {[lindex $q1nmid_1011 0] + 4}]
box $q1_89v 34 [expr {$q1_1011v + 6}] 40
paint metal2
box $q1_89v 34 [expr {$q1_89v + 6}] 40
paint via1
box $q1_1011v 34 [expr {$q1_1011v + 6}] 40
paint via1

# --- x0 net: connect XOR0 PMOS+NMOS outputs within row 1 ---
# x0 at: PMOS left of 4 (pad), drain_m1 left of 6 (full), NMOS right of 7 (pad)
set x0_p4v [expr {[lindex $oai0a_l 0] + 4}]
set x0_l6v [expr {[lindex $oai0b_l 0] + 4}]
set x0_n7v [expr {[lindex $oai0b_r 0] + 4}]
# M2 horizontal bus at y=82..88
box $x0_p4v 82 [expr {$x0_n7v + 6}] 88
paint metal2
box $x0_p4v 82 [expr {$x0_p4v + 6}] 88
paint via1
box $x0_l6v 82 [expr {$x0_l6v + 6}] 88
paint via1
box $x0_n7v 82 [expr {$x0_n7v + 6}] 88
paint via1

# --- x1 net: connect XOR1 PMOS+NMOS outputs within row 1 ---
set x1_p8v [expr {[lindex $oai1a_l 0] + 4}]
set x1_l10v [expr {[lindex $oai1b_l 0] + 4}]
set x1_n11v [expr {[lindex $oai1b_r 0] + 4}]
box $x1_p8v 82 [expr {$x1_n11v + 6}] 88
paint metal2
box $x1_p8v 82 [expr {$x1_p8v + 6}] 88
paint via1
box $x1_l10v 82 [expr {$x1_l10v + 6}] 88
paint via1
box $x1_n11v 82 [expr {$x1_n11v + 6}] 88
paint via1

# ===================================================================
# CROSS-ROW M2 ROUTING: x0 and x1 from Row 1 to Row 2
# ===================================================================
# x0 needs to reach: R2 gate 0 (INV input) and R2 gate 4 (AOI22 input)
# x1 needs to reach: R2 gate 1 (INV input) and R2 gate 3 (AOI22 input)
#
# Strategy: run vertical M2 from Row 1 x0/x1 bus through VDD rail
# to Row 2 cogc level. M2 crosses M1 VDD rail without shorting.

# x0 cross-row: vertical M2 at x position aligned with R2 gate 0 cogc
set r2g0_v [expr {[gx 0] + 4}]
set r2g4_v [expr {[gx 4] + 4}]
# Vertical M2 from Row 1 x0 bus (y=82) to Row 2 cogc (y=210)
box $r2g0_v 82 [expr {$r2g0_v + 6}] 210
paint metal2
# Via1 to Row 1 x0 bus (this via is already part of x0 bus above)
# Via1 at Row 2 gate 0 cogc for INV(x0) input
box $r2g0_v 200 [expr {$r2g0_v + 6}] 210
paint via1
# M2 spur to Row 2 gate 4 cogc for AOI22(x0) input
box $r2g0_v 190 [expr {$r2g4_v + 6}] 196
paint metal2
box $r2g4_v 190 [expr {$r2g4_v + 6}] 200
paint metal2
box $r2g4_v 200 [expr {$r2g4_v + 6}] 210
paint via1

# x1 cross-row: vertical M2 at x position aligned with R2 gate 1 cogc
set r2g1_v [expr {[gx 1] + 4}]
set r2g3_v [expr {[gx 3] + 4}]
# Vertical M2 from Row 1 (need to connect to x1 bus which starts at x1_p8v)
# R2 gate 1 cogc at x=62, but x1 bus is at x=~350. Need M2 horizontal run.
# Use a two-step route: horizontal M2 spur from x1 bus to R2 gate 1 vertical
box $r2g1_v 76 [expr {$x1_p8v + 6}] 82
paint metal2
# Vertical M2 from y=76 up through VDD to Row 2 cogc
box $r2g1_v 76 [expr {$r2g1_v + 6}] 210
paint metal2
# Via1 at Row 2 gate 1 cogc for INV(x1) input
box $r2g1_v 200 [expr {$r2g1_v + 6}] 210
paint via1
# M2 spur to Row 2 gate 3 cogc for AOI22(x1) input
box $r2g1_v 184 [expr {$r2g3_v + 6}] 190
paint metal2
box $r2g3_v 184 [expr {$r2g3_v + 6}] 200
paint metal2
box $r2g3_v 200 [expr {$r2g3_v + 6}] 210
paint via1

# ===================================================================
# ROW 2: M2 INTRA-ROW ROUTING
# ===================================================================

# --- d0: INV output (R2 sdl 0) -> AOI22 gate 2 + NAND2 gate 6 ---
set d0_v [expr {[lindex $d0 0] + 4}]
set r2g2_v [expr {[gx 2] + 4}]
set r2g6_v [expr {[gx 6] + 4}]
box $d0_v 218 [expr {$r2g6_v + 6}] 224
paint metal2
box $d0_v 218 [expr {$d0_v + 6}] 224
paint via1
box $r2g2_v 218 [expr {$r2g2_v + 6}] 224
paint via1
box $r2g6_v 218 [expr {$r2g6_v + 6}] 224
paint via1

# --- d1: INV output (R2 sdr 1) -> AOI22 gate 5 + NAND2 gate 7 ---
set d1_v [expr {[lindex $d1 0] + 4}]
set r2g5_v [expr {[gx 5] + 4}]
set r2g7_v [expr {[gx 7] + 4}]
box $d1_v 228 [expr {$r2g7_v + 6}] 234
paint metal2
box $d1_v 228 [expr {$d1_v + 6}] 234
paint via1
box $r2g5_v 228 [expr {$r2g5_v + 6}] 234
paint via1
box $r2g7_v 228 [expr {$r2g7_v + 6}] 234
paint via1

# --- a1pm: AOI22 PMOS between 2-3 to between 4-5 ---
set a1pm_1v [expr {[lindex $a1nm1 0] + 4}]
set a1pm_2v [expr {[lindex $a1nm2 0] + 4}]
box $a1pm_1v 166 [expr {$a1pm_2v + 6}] 172
paint metal2
box $a1pm_1v 166 [expr {$a1pm_1v + 6}] 172
paint via1
box $a1pm_2v 166 [expr {$a1pm_2v + 6}] 172
paint via1

# --- noh1: connect all noh1 nodes ---
# noh1 NMOS pads: left of R2 gate 2 (aoi_a_l) and R2 drain_m1 left of gate 4 (aoi_b_l)
# noh1 PMOS pads: right of R2 gate 5 (aoi_b_r)
# The drain_m1 at aoi_b_l connects both NMOS and PMOS noh1.
# Connect aoi_a_l NMOS pad to aoi_b_l drain_m1 via M2
set noh1_nl2v [expr {[lindex $aoi_a_l 0] + 4}]
set noh1_l4v [expr {[lindex $aoi_b_l 0] + 4}]
set noh1_pr5v [expr {[lindex $aoi_b_r 0] + 4}]
# M2 horizontal connecting noh1 NMOS pad at left-of-2 to drain at left-of-4
box $noh1_nl2v 248 [expr {$noh1_l4v + 6}] 254
paint metal2
box $noh1_nl2v 248 [expr {$noh1_nl2v + 6}] 254
paint via1
box $noh1_l4v 248 [expr {$noh1_l4v + 6}] 254
paint via1
# Connect PMOS noh1 at right-of-5 to same net via vertical M2
box $noh1_pr5v 172 [expr {$noh1_pr5v + 6}] 178
paint via1
box $noh1_pr5v 178 [expr {$noh1_pr5v + 6}] 248
paint metal2
# Also need via1 at noh1_pr5v y=248 to connect to the horizontal M2 bus
box $noh1_pr5v 248 [expr {$noh1_pr5v + 6}] 254
paint via1

# --- noh2: connect PMOS right-of-7 to main noh2 (drain left-of-6) ---
set noh2_l6v [expr {[lindex $nand_l 0] + 4}]
set noh2_pr7v [expr {[lindex $nand_r 0] + 4}]
# Vertical M2 from PMOS pad to NMOS region, then horizontal to left
box $noh2_pr7v 172 [expr {$noh2_pr7v + 6}] 178
paint via1
box $noh2_pr7v 178 [expr {$noh2_pr7v + 6}] 240
paint metal2
box $noh2_l6v 240 [expr {$noh2_pr7v + 6}] 246
paint metal2
box $noh2_l6v 240 [expr {$noh2_l6v + 6}] 246
paint via1

# ===================================================================
# LABELS
# ===================================================================
box [expr {[gx 0] + 4}] 65 [expr {[gx 0] + 10}] 65
label ai 1 cogc
box [expr {[gx 1] + 4}] 65 [expr {[gx 1] + 10}] 65
label bi 1 cogc
box [expr {[gx 2] + 4}] 65 [expr {[gx 2] + 10}] 65
label aj 1 cogc
box [expr {[gx 3] + 4}] 65 [expr {[gx 3] + 10}] 65
label bj 1 cogc

box [expr {[lindex $aoi_a_l 0] + 4}] 250 [expr {[lindex $aoi_a_l 0] + 4}] 250
label noh1 1 metal1
box [expr {[lindex $nand_l 0] + 4}] 242 [expr {[lindex $nand_l 0] + 4}] 242
label noh2 1 metal1

box [expr {$W / 2}] 7 [expr {$W / 2}] 7
label VSS 1 metal1
box [expr {$W / 2}] 140 [expr {$W / 2}] 140
label VDD 3 metal1
box [expr {$W / 2}] 273 [expr {$W / 2}] 273
label VSS 1 metal1

# ===================================================================
# SAVE, DRC, EXTRACT
# ===================================================================
save /Users/bruce/CLAUDE/asap5/stdcells/fused_ppa/FUSED_G

drc catchup
drc catchup
set drc_count [drc list count total]
puts "FUSED_G DH DRC violations: $drc_count"

extract all
ext2spice lvs
ext2spice -f ngspice -o /Users/bruce/CLAUDE/asap5/stdcells/fused_ppa/FUSED_G_ext.spice

ext2spice cthresh 0
ext2spice -f ngspice -o /Users/bruce/CLAUDE/asap5/stdcells/fused_ppa/FUSED_G_ext_full.spice

puts "FUSED_G double-height layout: ${W}nm x ${H}nm = [expr {double($W)/$H}]:1 aspect ratio"
puts "12 CPP x 2 rows, 20 gates = 40 transistors (SLVT, active-low)"
