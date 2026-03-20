# Build FUSED_F Double-Height Layout — Variant F (Hybrid, 42T)
# SLVT, ASAP5 5nm GAA, 528nm x 280nm (1.89:1)
#
# CRITICAL: Each INV needs proper VSS/VDD at source nodes.
# INV pairs share supply: [drain]-INV_A-[VSS/VDD]-INV_B-[drain]
#
# Row 1 (12 gates): INV_ai,INV_bi (paired), INV_aj,INV_bj (paired),
#                    OAI22_0 (4 gates), OAI22_1 (4 gates)
# Row 2 (9 gates): INV_d0,INV_d1 (paired), NOR2(oh2),
#                   AOI22(no1) (4 gates), INV(oh1)

proc gx {n} { return [expr {14 + $n * 44}] }
proc gxr {n} { return [expr {14 + $n * 44 + 16}] }

set W 528
set H 280

cellname rename (UNNAMED) FUSED_F
box 0 0 $W $H

# === NWELL ===
box 0 65 $W 215
paint nwell

# === POWER RAILS ===
box 0 0 $W 14
paint metal1
box 0 126 $W 154
paint metal1
box 0 266 $W 280
paint metal1

# === POLY ===
for {set n 0} {$n < 12} {incr n} {
    box [gx $n] 5 [gxr $n] 135
    paint poly
}
for {set n 0} {$n < 9} {incr n} {
    box [gx $n] 145 [gxr $n] 275
    paint poly
}

# === TRANSISTOR BUILDERS ===
proc r1_nmos {first last lpad rpad} {
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
proc r1_cogc {first last} {
    for {set n $first} {$n <= $last} {incr n} {
        set xl [gx $n]
        set xr [gxr $n]
        box [expr {$xl + 2}] 60 [expr {$xr - 2}] 70
        paint cogc
        box [expr {$xl + 2}] 60 [expr {$xr - 2}] 70
        paint metal1
        box $xl 58 [expr {$xl + 2}] 72
        paint poly
        box [expr {$xr - 2}] 58 $xr 72
        paint poly
    }
}
proc r1_build {first last lpad rpad} {
    r1_nmos $first $last $lpad $rpad
    r1_pmos $first $last $lpad $rpad
    r1_ndc $first $last $lpad $rpad
    r1_pdc $first $last $lpad $rpad
    r1_cogc $first $last
}

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
proc r2_cogc {first last} {
    for {set n $first} {$n <= $last} {incr n} {
        set xl [gx $n]
        set xr [gxr $n]
        box [expr {$xl + 2}] 208 [expr {$xr - 2}] 218
        paint cogc
        box [expr {$xl + 2}] 208 [expr {$xr - 2}] 218
        paint metal1
        box $xl 206 [expr {$xl + 2}] 220
        paint poly
        box [expr {$xr - 2}] 206 $xr 220
        paint poly
    }
}
proc r2_build {first last lpad rpad} {
    r2_pmos $first $last $lpad $rpad
    r2_nmos $first $last $lpad $rpad
    r2_pdc $first $last $lpad $rpad
    r2_ndc $first $last $lpad $rpad
    r2_cogc $first $last
}

# Helper: connect S/D position to VSS rail via M1 strip
proc r1_vss_tap {xl xr} {
    box $xl 0 $xr 45
    paint metal1
}
# Connect S/D to VDD rail via M1
proc r1_vdd_tap {xl xr} {
    box $xl 95 $xr 140
    paint metal1
}
# Row 2: VSS tap (top rail)
proc r2_vss_tap {xl xr} {
    box $xl 235 $xr 280
    paint metal1
}
# Row 2: VDD tap (shared middle rail)
proc r2_vdd_tap {xl xr} {
    box $xl 140 $xr 185
    paint metal1
}

# === BUILD BLOCKS ===

# Row 1: INV pair ai,bi (B0,B1) - shared VSS/VDD between them
# Layout: [nai]-B0(ai)-[VSS/VDD]-B1(bi)-[nbi]
# S/D NMOS: [nai=D]-B0(ai)-[VSS=S/S]-B1(bi)-[nbi=D]
# S/D PMOS: [nai=D]-B0(ai)-[VDD=S/S]-B1(bi)-[nbi=D]
r1_build 0 1 14 14

# Row 1: INV pair aj,bj (B2,B3) - same pattern
r1_build 2 3 14 14

# Row 1: OAI22_0 (B4-B7) and OAI22_1 (B8-B11)
r1_build 4 7 12 12
r1_build 8 11 12 14

# Row 2: INV pair d0,d1 (T0,T1) - shared supply between them
r2_build 0 1 14 14
# NOR2 oh2 (T2,T3)
r2_build 2 3 12 12
# AOI22 no1 (T4-T7)
r2_build 4 7 12 12
# INV oh1 (T8)
r2_build 8 8 12 14

# === SUPPLY TAPS ===
# INV pair B0,B1: center S/D (between B0-B1) is shared supply
# NMOS center is VSS, PMOS center is VDD
set inv01_center_l [expr {[gxr 0] + 2}]
set inv01_center_r [expr {[gx 1] - 2}]
r1_vss_tap $inv01_center_l $inv01_center_r
r1_vdd_tap $inv01_center_l $inv01_center_r

# INV pair B2,B3: center supply
set inv23_center_l [expr {[gxr 2] + 2}]
set inv23_center_r [expr {[gx 3] - 2}]
r1_vss_tap $inv23_center_l $inv23_center_r
r1_vdd_tap $inv23_center_l $inv23_center_r

# Row 2 INV pair T0,T1: center supply
set inv_t01_center_l [expr {[gxr 0] + 2}]
set inv_t01_center_r [expr {[gx 1] - 2}]
r2_vss_tap $inv_t01_center_l $inv_t01_center_r
r2_vdd_tap $inv_t01_center_l $inv_t01_center_r

# === M1 DRAIN CONNECTIONS — ROW 1 ===
proc r1_drain {gl gr} { box $gl 20 $gr 120; paint metal1 }

# INV B0,B1: drains at outer edges
# nai: left of B0
set nai_l [expr {[gx 0] - 12}]
set nai_r [expr {[gx 0] - 2}]
r1_drain $nai_l $nai_r

# nbi: right of B1
set nbi_l [expr {[gxr 1] + 2}]
set nbi_r [expr {[gxr 1] + 12}]
r1_drain $nbi_l $nbi_r

# INV B2,B3: drains at outer edges
# naj: left of B2
set naj_l [expr {[gx 2] - 12}]
set naj_r [expr {[gx 2] - 2}]
r1_drain $naj_l $naj_r

# nbj: right of B3
set nbj_l [expr {[gxr 3] + 2}]
set nbj_r [expr {[gxr 3] + 12}]
r1_drain $nbj_l $nbj_r

# OAI22_0 x0 output: NMOS between B5-B6, PMOS left of B4
set x0_nl [expr {[gxr 5] + 2}]
box $x0_nl 20 [expr {[gx 6] - 2}] 45
paint metal1
box [expr {[gx 4] - 10}] 95 [expr {[gx 4] - 2}] 120
paint metal1

# OAI22_1 x1 output
set x1_nl [expr {[gxr 9] + 2}]
box $x1_nl 20 [expr {[gx 10] - 2}] 45
paint metal1
box [expr {[gx 8] - 10}] 95 [expr {[gx 8] - 2}] 120
paint metal1

# === M1 DRAIN — ROW 2 ===
proc r2_drain {gl gr} { box $gl 160 $gr 260; paint metal1 }

# d0: left of T0
set d0_l [expr {[gx 0] - 12}]
set d0_r [expr {[gx 0] - 2}]
r2_drain $d0_l $d0_r

# d1: right of T1
set d1_l [expr {[gxr 1] + 2}]
set d1_r [expr {[gxr 1] + 12}]
r2_drain $d1_l $d1_r

# oh2: left of T2
set oh2_l [expr {[gx 2] - 10}]
set oh2_r [expr {[gx 2] - 2}]
r2_drain $oh2_l $oh2_r

# NOR2 PMOS series right of T3
box [expr {[gxr 3] + 2}] 160 [expr {[gxr 3] + 10}] 185
paint metal1

# AOI22 no1 drains
set no1a_l [expr {[gx 4] - 10}]
r2_drain $no1a_l [expr {[gx 4] - 2}]
set no1b_l [expr {[gx 6] - 10}]
r2_drain $no1b_l [expr {[gx 6] - 2}]

# oh1 right of T8
set oh1_l [expr {[gxr 8] + 2}]
r2_drain $oh1_l [expr {[gxr 8] + 12}]

# === M2 ROUTING — Row 1: nai→B4, nbi→B5, naj→B8, nbj→B9 ===
set nai_v [expr {$nai_l + 4}]
set g4v [expr {[gx 4] + 4}]
box $nai_v 24 [expr {$nai_v + 6}] 30
paint via1
box $nai_v 24 [expr {$g4v + 6}] 30
paint metal2
box $g4v 24 [expr {$g4v + 6}] 68
paint metal2
box $g4v 62 [expr {$g4v + 6}] 68
paint via1

set nbi_v [expr {$nbi_l + 4}]
set g5v [expr {[gx 5] + 4}]
box $nbi_v 34 [expr {$nbi_v + 6}] 40
paint via1
box $nbi_v 34 [expr {$g5v + 6}] 40
paint metal2
box $g5v 34 [expr {$g5v + 6}] 68
paint metal2
box $g5v 62 [expr {$g5v + 6}] 68
paint via1

set naj_v [expr {$naj_l + 4}]
set g8v [expr {[gx 8] + 4}]
box $naj_v 100 [expr {$naj_v + 6}] 106
paint via1
box $naj_v 100 [expr {$g8v + 6}] 106
paint metal2
box $g8v 62 [expr {$g8v + 6}] 106
paint metal2
box $g8v 62 [expr {$g8v + 6}] 68
paint via1

set nbj_v [expr {$nbj_l + 4}]
set g9v [expr {[gx 9] + 4}]
box $nbj_v 110 [expr {$nbj_v + 6}] 116
paint via1
box $nbj_v 110 [expr {$g9v + 6}] 116
paint metal2
box $g9v 62 [expr {$g9v + 6}] 116
paint metal2
box $g9v 62 [expr {$g9v + 6}] 68
paint via1

# === CROSS-ROW: x0, x1 via M3 ===
set x0_v [expr {$x0_nl + 2}]
box $x0_v 30 [expr {$x0_v + 6}] 36
paint via1
box $x0_v 30 [expr {$x0_v + 6}] 36
paint metal2
box $x0_v 30 [expr {$x0_v + 6}] 36
paint via2
box $x0_v 30 [expr {$x0_v + 6}] 212
paint metal3
box $x0_v 206 [expr {$x0_v + 6}] 212
paint via2
set t0v [expr {[gx 0] + 4}]
set t2v [expr {[gx 2] + 4}]
set t6v [expr {[gx 6] + 4}]
box $t0v 206 [expr {$x0_v + 6}] 212
paint metal2
box $t0v 206 [expr {$t0v + 6}] 212
paint via1
box $t2v 206 [expr {$t2v + 6}] 212
paint via1
box $t6v 206 [expr {$t6v + 6}] 212
paint via1
box $x0_v 206 [expr {$x0_v + 6}] 212
paint via1

set x1_v [expr {$x1_nl + 2}]
box $x1_v 30 [expr {$x1_v + 6}] 36
paint via1
box $x1_v 30 [expr {$x1_v + 6}] 36
paint metal2
box $x1_v 30 [expr {$x1_v + 6}] 36
paint via2
box $x1_v 30 [expr {$x1_v + 6}] 218
paint metal3
box $x1_v 212 [expr {$x1_v + 6}] 218
paint via2
set t1v [expr {[gx 1] + 4}]
set t3v [expr {[gx 3] + 4}]
set t5v [expr {[gx 5] + 4}]
box $t1v 212 [expr {$x1_v + 6}] 218
paint metal2
box $t1v 212 [expr {$t1v + 6}] 218
paint via1
box $t3v 212 [expr {$t3v + 6}] 218
paint via1
box $t5v 212 [expr {$t5v + 6}] 218
paint via1
box $x1_v 212 [expr {$x1_v + 6}] 218
paint via1

# === M2 ROUTING — Row 2 ===
set d0v [expr {$d0_l + 2}]
set t4v [expr {[gx 4] + 4}]
box $d0v 210 [expr {$t4v + 6}] 216
paint metal2
box $d0v 210 [expr {$d0v + 6}] 216
paint via1
box $t4v 210 [expr {$t4v + 6}] 216
paint via1

set d1v [expr {$d1_l + 2}]
set t7v [expr {[gx 7] + 4}]
box $d1v 240 [expr {$t7v + 6}] 246
paint metal2
box $d1v 240 [expr {$d1v + 6}] 246
paint via1
box $t7v 240 [expr {$t7v + 6}] 246
paint via1

set no1av [expr {$no1a_l + 2}]
set no1bv [expr {$no1b_l + 2}]
set t8v [expr {[gx 8] + 4}]
box $no1av 250 [expr {$t8v + 6}] 256
paint metal2
box $no1av 250 [expr {$no1av + 6}] 256
paint via1
box $no1bv 250 [expr {$no1bv + 6}] 256
paint via1
box $t8v 250 [expr {$t8v + 6}] 256
paint via1

# === LABELS ===
box [expr {[gx 0] + 4}] 65 [expr {[gx 0] + 10}] 65
label ai 1 metal1
box [expr {[gx 1] + 4}] 65 [expr {[gx 1] + 10}] 65
label bi 1 metal1
box [expr {[gx 2] + 4}] 65 [expr {[gx 2] + 10}] 65
label aj 1 metal1
box [expr {[gx 3] + 4}] 65 [expr {[gx 3] + 10}] 65
label bj 1 metal1
box [expr {$oh1_l + 4}] 210 [expr {$oh1_l + 4}] 210
label oh1 1 metal1
box [expr {$oh2_l + 4}] 210 [expr {$oh2_l + 4}] 210
label oh2 1 metal1
box [expr {$W / 2}] 7 [expr {$W / 2}] 7
label VSS 1 metal1
box [expr {$W / 2}] 140 [expr {$W / 2}] 140
label VDD 1 metal1

# === SAVE, DRC, EXTRACT ===
save /Users/bruce/CLAUDE/asap5/stdcells/fused_ppa/FUSED_F

drc catchup
set drc_count [drc count]
puts "DRC: $drc_count"

extract all
ext2spice lvs
ext2spice cthresh 0.01
ext2spice -f ngspice -o /Users/bruce/CLAUDE/asap5/stdcells/fused_ppa/FUSED_F_ext.spice

puts "FUSED_F DH: ${W}nm x ${H}nm, ratio=[format %.2f [expr {double($W)/$H}]]:1, 42T"
