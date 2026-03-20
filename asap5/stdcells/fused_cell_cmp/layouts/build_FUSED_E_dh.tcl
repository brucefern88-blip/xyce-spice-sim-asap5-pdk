# Build FUSED_E double-height layout — Variant E (OAI22+NOR, 38T, SLVT)
# 440nm x 280nm, 10 CPP x 2 rows, aspect ratio 1.57:1
#
# Row 1 (bottom): VSS(y=0..14) - NMOS(y=10..55) - cogc(y=60..70) - PMOS(y=85..130) - VDD(y=126..154)
# Row 2 (top, mirrored): VDD(y=126..154) - PMOS(y=150..195) - cogc(y=210..220) - NMOS(y=225..270) - VSS(y=266..280)
#
# Row 1 gates (9): G0(ai INV) G1(bi INV) | G2(nai) G3(nbi) | G4(ai) G5(bi) | G6(x0 NOR) G7(x1 NOR) | G8(no0 INV)
# Row 2 gates (10): G0(aj INV) G1(bj INV) | G2(naj) G3(nbj) | G4(aj) G5(bj) | G6(x0 NAND) G7(x1 NAND) | G8(oh0) G9(oh2)

proc gx {n} { return [expr {14 + $n * 44}] }
proc gxr {n} { return [expr {14 + $n * 44 + 16}] }

set W 440
set H 280

cellname rename (UNNAMED) FUSED_E
box 0 0 $W $H

# === NWELL and POWER RAILS ===
box 0 65 $W 215
paint nwell
box 0 0 $W 14
paint metal1
box 0 126 $W 154
paint metal1
box 0 266 $W 280
paint metal1

# === R1 POLY (9 gates) ===
for {set n 0} {$n < 9} {incr n} {
    set xl [gx $n]
    set xr [gxr $n]
    box $xl 5 $xr 10
    paint poly
    box $xl 55 $xr 60
    paint poly
    box $xl 60 [expr {$xl + 2}] 70
    paint poly
    box [expr {$xr - 2}] 60 $xr 70
    paint poly
    box $xl 70 $xr 75
    paint poly
    box $xl 130 $xr 135
    paint poly
}

# === R2 POLY (10 gates, mirrored) ===
for {set n 0} {$n < 10} {incr n} {
    set xl [gx $n]
    set xr [gxr $n]
    box $xl 270 $xr 275
    paint poly
    box $xl 220 $xr 225
    paint poly
    box $xl 210 [expr {$xl + 2}] 220
    paint poly
    box [expr {$xr - 2}] 210 $xr 220
    paint poly
    box $xl 205 $xr 210
    paint poly
    box $xl 145 $xr 150
    paint poly
}

# === DIFFUSION HELPERS ===
proc r1_nmos {first last lpad rpad} {
    set s [expr {[gx $first] - $lpad}]
    set e [expr {[gxr $last] + $rpad}]
    box $s 10 [gx $first] 55; paint ndiff
    for {set n $first} {$n < $last} {incr n} { box [gxr $n] 10 [gx [expr {$n+1}]] 55; paint ndiff }
    box [gxr $last] 10 $e 55; paint ndiff
    for {set n $first} {$n <= $last} {incr n} { box [gx $n] 10 [gxr $n] 55; paint nfet_slvt }
}
proc r1_pmos {first last lpad rpad} {
    set s [expr {[gx $first] - $lpad}]
    set e [expr {[gxr $last] + $rpad}]
    box $s 85 [gx $first] 130; paint pdiff
    for {set n $first} {$n < $last} {incr n} { box [gxr $n] 85 [gx [expr {$n+1}]] 130; paint pdiff }
    box [gxr $last] 85 $e 130; paint pdiff
    for {set n $first} {$n <= $last} {incr n} { box [gx $n] 85 [gxr $n] 130; paint pfet_slvt }
}
proc r2_nmos {first last lpad rpad} {
    set s [expr {[gx $first] - $lpad}]
    set e [expr {[gxr $last] + $rpad}]
    box $s 225 [gx $first] 270; paint ndiff
    for {set n $first} {$n < $last} {incr n} { box [gxr $n] 225 [gx [expr {$n+1}]] 270; paint ndiff }
    box [gxr $last] 225 $e 270; paint ndiff
    for {set n $first} {$n <= $last} {incr n} { box [gx $n] 225 [gxr $n] 270; paint nfet_slvt }
}
proc r2_pmos {first last lpad rpad} {
    set s [expr {[gx $first] - $lpad}]
    set e [expr {[gxr $last] + $rpad}]
    box $s 150 [gx $first] 195; paint pdiff
    for {set n $first} {$n < $last} {incr n} { box [gxr $n] 150 [gx [expr {$n+1}]] 195; paint pdiff }
    box [gxr $last] 150 $e 195; paint pdiff
    for {set n $first} {$n <= $last} {incr n} { box [gx $n] 150 [gxr $n] 195; paint pfet_slvt }
}

# S/D contact helpers
proc r1_ndc {xl xr} { box [expr {$xl+2}] 20 [expr {$xr-2}] 45; paint ndc }
proc r1_pdc {xl xr} { box [expr {$xl+2}] 95 [expr {$xr-2}] 120; paint pdc }
proc r2_ndc {xl xr} { box [expr {$xl+2}] 235 [expr {$xr-2}] 260; paint ndc }
proc r2_pdc {xl xr} { box [expr {$xl+2}] 160 [expr {$xr-2}] 185; paint pdc }

# Gate contact helpers (cogc + M1 pad)
proc r1_cogc {n} {
    box [expr {[gx $n]+2}] 60 [expr {[gxr $n]-2}] 70; paint cogc
    box [expr {[gx $n]+2}] 60 [expr {[gxr $n]-2}] 70; paint metal1
}
proc r2_cogc {n} {
    box [expr {[gx $n]+2}] 210 [expr {[gxr $n]-2}] 220; paint cogc
    box [expr {[gx $n]+2}] 210 [expr {[gxr $n]-2}] 220; paint metal1
}

# SD boundary helpers
proc sdl {g lp} { return [list [expr {[gx $g]-$lp}] [gx $g]] }
proc sdb {g} { return [list [gxr $g] [gx [expr {$g+1}]]] }
proc sdr {g rp} { return [list [gxr $g] [expr {[gxr $g]+$rp}]] }

# ===============================================================
# ROW 1 BLOCKS
# ===============================================================

# R1 Block A: INV pair G0(ai),G1(bi) — nai-G0-VSS/VDD-G1-nbi
r1_nmos 0 1 14 14; r1_pmos 0 1 14 14
set a0 [sdl 0 14]; r1_ndc [lindex $a0 0] [lindex $a0 1]; r1_pdc [lindex $a0 0] [lindex $a0 1]
set a01 [sdb 0]; r1_ndc [lindex $a01 0] [lindex $a01 1]; r1_pdc [lindex $a01 0] [lindex $a01 1]
set a1 [sdr 1 14]; r1_ndc [lindex $a1 0] [lindex $a1 1]; r1_pdc [lindex $a1 0] [lindex $a1 1]
r1_cogc 0; r1_cogc 1
# nai drain (full M1 strip)
box [expr {[lindex $a0 0]+2}] 20 [expr {[lindex $a0 1]-2}] 120; paint metal1
# VSS/VDD between G0-G1
box [expr {[lindex $a01 0]+2}] 7 [expr {[lindex $a01 1]-2}] 45; paint metal1
box [expr {[lindex $a01 0]+2}] 95 [expr {[lindex $a01 1]-2}] 133; paint metal1
# nbi drain
box [expr {[lindex $a1 0]+2}] 20 [expr {[lindex $a1 1]-2}] 120; paint metal1

# R1 Block B: OAI22_0 sub1 G2(nai),G3(nbi) — VSS-G2-nmid-G3-VSS / x0-G2-pm1-G3-VDD
r1_nmos 2 3 14 14; r1_pmos 2 3 14 14
set b0 [sdl 2 14]; r1_ndc [lindex $b0 0] [lindex $b0 1]; r1_pdc [lindex $b0 0] [lindex $b0 1]
set b01 [sdb 2]; r1_ndc [lindex $b01 0] [lindex $b01 1]; r1_pdc [lindex $b01 0] [lindex $b01 1]
set b1 [sdr 3 14]; r1_ndc [lindex $b1 0] [lindex $b1 1]; r1_pdc [lindex $b1 0] [lindex $b1 1]
r1_cogc 2; r1_cogc 3
# NMOS: VSS-left, nmid-between, VSS-right
box [expr {[lindex $b0 0]+2}] 7 [expr {[lindex $b0 1]-2}] 45; paint metal1
box [expr {[lindex $b1 0]+2}] 7 [expr {[lindex $b1 1]-2}] 45; paint metal1
# nmid NMOS M1 pad
box [expr {[lindex $b01 0]+2}] 20 [expr {[lindex $b01 1]-2}] 45; paint metal1
# PMOS: x0-left, pm1-between(internal), VDD-right
box [expr {[lindex $b0 0]+2}] 95 [expr {[lindex $b0 1]-2}] 120; paint metal1
box [expr {[lindex $b1 0]+2}] 95 [expr {[lindex $b1 1]-2}] 133; paint metal1

# R1 Block C: OAI22_0 sub2 G4(ai),G5(bi) — x0-G4-nmid-G5-x0 / x0-G4-pm2-G5-VDD
r1_nmos 4 5 14 14; r1_pmos 4 5 14 14
set c0 [sdl 4 14]; r1_ndc [lindex $c0 0] [lindex $c0 1]; r1_pdc [lindex $c0 0] [lindex $c0 1]
set c01 [sdb 4]; r1_ndc [lindex $c01 0] [lindex $c01 1]; r1_pdc [lindex $c01 0] [lindex $c01 1]
set c1 [sdr 5 14]; r1_ndc [lindex $c1 0] [lindex $c1 1]; r1_pdc [lindex $c1 0] [lindex $c1 1]
r1_cogc 4; r1_cogc 5
# NMOS: x0-left, nmid-between, x0-right
box [expr {[lindex $c0 0]+2}] 20 [expr {[lindex $c0 1]-2}] 45; paint metal1
box [expr {[lindex $c01 0]+2}] 20 [expr {[lindex $c01 1]-2}] 45; paint metal1
box [expr {[lindex $c1 0]+2}] 20 [expr {[lindex $c1 1]-2}] 45; paint metal1
# PMOS: x0-left, pm2-between(internal), VDD-right
box [expr {[lindex $c0 0]+2}] 95 [expr {[lindex $c0 1]-2}] 120; paint metal1
box [expr {[lindex $c1 0]+2}] 95 [expr {[lindex $c1 1]-2}] 133; paint metal1

# R1 Block D: NOR2_OH2 G6(x0),G7(x1) — VSS-G6-oh2-G7-VSS / VDD-G6-ps-G7-oh2
r1_nmos 6 7 14 14; r1_pmos 6 7 14 14
set d0 [sdl 6 14]; r1_ndc [lindex $d0 0] [lindex $d0 1]; r1_pdc [lindex $d0 0] [lindex $d0 1]
set d01 [sdb 6]; r1_ndc [lindex $d01 0] [lindex $d01 1]; r1_pdc [lindex $d01 0] [lindex $d01 1]
set d1 [sdr 7 14]; r1_ndc [lindex $d1 0] [lindex $d1 1]; r1_pdc [lindex $d1 0] [lindex $d1 1]
r1_cogc 6; r1_cogc 7
# NMOS: VSS-left, oh2-between, VSS-right
box [expr {[lindex $d0 0]+2}] 7 [expr {[lindex $d0 1]-2}] 45; paint metal1
box [expr {[lindex $d1 0]+2}] 7 [expr {[lindex $d1 1]-2}] 45; paint metal1
# oh2 NMOS M1 pad (between G6-G7)
box [expr {[lindex $d01 0]+2}] 20 [expr {[lindex $d01 1]-2}] 45; paint metal1
# PMOS: VDD-left, ps-between(internal), oh2-right
box [expr {[lindex $d0 0]+2}] 95 [expr {[lindex $d0 1]-2}] 133; paint metal1
# oh2 PMOS M1 pad (right of G7)
box [expr {[lindex $d1 0]+2}] 95 [expr {[lindex $d1 1]-2}] 120; paint metal1

# R1 Block E: INV_oh0 G8(no0) — VSS-G8-oh0 / VDD-G8-oh0
r1_nmos 8 8 14 14; r1_pmos 8 8 14 14
set e0 [sdl 8 14]; r1_ndc [lindex $e0 0] [lindex $e0 1]; r1_pdc [lindex $e0 0] [lindex $e0 1]
set e1 [sdr 8 14]; r1_ndc [lindex $e1 0] [lindex $e1 1]; r1_pdc [lindex $e1 0] [lindex $e1 1]
r1_cogc 8
# VSS/VDD left
box [expr {[lindex $e0 0]+2}] 7 [expr {[lindex $e0 1]-2}] 45; paint metal1
box [expr {[lindex $e0 0]+2}] 95 [expr {[lindex $e0 1]-2}] 133; paint metal1
# oh0 drain right (full M1)
box [expr {[lindex $e1 0]+2}] 20 [expr {[lindex $e1 1]-2}] 120; paint metal1

# ===============================================================
# ROW 2 BLOCKS
# ===============================================================

# R2 Block A: INV pair G0(aj),G1(bj)
r2_nmos 0 1 14 14; r2_pmos 0 1 14 14
set r2a0 [sdl 0 14]; r2_ndc [lindex $r2a0 0] [lindex $r2a0 1]; r2_pdc [lindex $r2a0 0] [lindex $r2a0 1]
set r2a01 [sdb 0]; r2_ndc [lindex $r2a01 0] [lindex $r2a01 1]; r2_pdc [lindex $r2a01 0] [lindex $r2a01 1]
set r2a1 [sdr 1 14]; r2_ndc [lindex $r2a1 0] [lindex $r2a1 1]; r2_pdc [lindex $r2a1 0] [lindex $r2a1 1]
r2_cogc 0; r2_cogc 1
# naj drain (full M1)
box [expr {[lindex $r2a0 0]+2}] 160 [expr {[lindex $r2a0 1]-2}] 260; paint metal1
# VSS/VDD between
box [expr {[lindex $r2a01 0]+2}] 235 [expr {[lindex $r2a01 1]-2}] 273; paint metal1
box [expr {[lindex $r2a01 0]+2}] 147 [expr {[lindex $r2a01 1]-2}] 185; paint metal1
# nbj drain
box [expr {[lindex $r2a1 0]+2}] 160 [expr {[lindex $r2a1 1]-2}] 260; paint metal1

# R2 Block B: OAI22_1 sub1 G2(naj),G3(nbj)
r2_nmos 2 3 14 14; r2_pmos 2 3 14 14
set r2b0 [sdl 2 14]; r2_ndc [lindex $r2b0 0] [lindex $r2b0 1]; r2_pdc [lindex $r2b0 0] [lindex $r2b0 1]
set r2b01 [sdb 2]; r2_ndc [lindex $r2b01 0] [lindex $r2b01 1]; r2_pdc [lindex $r2b01 0] [lindex $r2b01 1]
set r2b1 [sdr 3 14]; r2_ndc [lindex $r2b1 0] [lindex $r2b1 1]; r2_pdc [lindex $r2b1 0] [lindex $r2b1 1]
r2_cogc 2; r2_cogc 3
# NMOS: VSS, nmid, VSS
box [expr {[lindex $r2b0 0]+2}] 235 [expr {[lindex $r2b0 1]-2}] 273; paint metal1
box [expr {[lindex $r2b1 0]+2}] 235 [expr {[lindex $r2b1 1]-2}] 273; paint metal1
box [expr {[lindex $r2b01 0]+2}] 235 [expr {[lindex $r2b01 1]-2}] 260; paint metal1
# PMOS: x1, pm1(int), VDD
box [expr {[lindex $r2b0 0]+2}] 160 [expr {[lindex $r2b0 1]-2}] 185; paint metal1
box [expr {[lindex $r2b1 0]+2}] 147 [expr {[lindex $r2b1 1]-2}] 185; paint metal1

# R2 Block C: OAI22_1 sub2 G4(aj),G5(bj)
r2_nmos 4 5 14 14; r2_pmos 4 5 14 14
set r2c0 [sdl 4 14]; r2_ndc [lindex $r2c0 0] [lindex $r2c0 1]; r2_pdc [lindex $r2c0 0] [lindex $r2c0 1]
set r2c01 [sdb 4]; r2_ndc [lindex $r2c01 0] [lindex $r2c01 1]; r2_pdc [lindex $r2c01 0] [lindex $r2c01 1]
set r2c1 [sdr 5 14]; r2_ndc [lindex $r2c1 0] [lindex $r2c1 1]; r2_pdc [lindex $r2c1 0] [lindex $r2c1 1]
r2_cogc 4; r2_cogc 5
# NMOS: x1, nmid, x1
box [expr {[lindex $r2c0 0]+2}] 235 [expr {[lindex $r2c0 1]-2}] 260; paint metal1
box [expr {[lindex $r2c01 0]+2}] 235 [expr {[lindex $r2c01 1]-2}] 260; paint metal1
box [expr {[lindex $r2c1 0]+2}] 235 [expr {[lindex $r2c1 1]-2}] 260; paint metal1
# PMOS: x1, pm2(int), VDD
box [expr {[lindex $r2c0 0]+2}] 160 [expr {[lindex $r2c0 1]-2}] 185; paint metal1
box [expr {[lindex $r2c1 0]+2}] 147 [expr {[lindex $r2c1 1]-2}] 185; paint metal1

# R2 Block D: NAND2_no0 G6(x0),G7(x1) — no0-G6-ns-G7-VSS / no0-G6-VDD-G7-no0
r2_nmos 6 7 14 14; r2_pmos 6 7 14 14
set r2d0 [sdl 6 14]; r2_ndc [lindex $r2d0 0] [lindex $r2d0 1]; r2_pdc [lindex $r2d0 0] [lindex $r2d0 1]
set r2d01 [sdb 6]; r2_ndc [lindex $r2d01 0] [lindex $r2d01 1]; r2_pdc [lindex $r2d01 0] [lindex $r2d01 1]
set r2d1 [sdr 7 14]; r2_ndc [lindex $r2d1 0] [lindex $r2d1 1]; r2_pdc [lindex $r2d1 0] [lindex $r2d1 1]
r2_cogc 6; r2_cogc 7
# NMOS series: no0-left, ns-between(int), VSS-right
box [expr {[lindex $r2d0 0]+2}] 235 [expr {[lindex $r2d0 1]-2}] 260; paint metal1
box [expr {[lindex $r2d1 0]+2}] 235 [expr {[lindex $r2d1 1]-2}] 273; paint metal1
# PMOS parallel: no0-left, VDD-between, no0-right
box [expr {[lindex $r2d0 0]+2}] 160 [expr {[lindex $r2d0 1]-2}] 185; paint metal1
box [expr {[lindex $r2d01 0]+2}] 147 [expr {[lindex $r2d01 1]-2}] 185; paint metal1
box [expr {[lindex $r2d1 0]+2}] 160 [expr {[lindex $r2d1 1]-2}] 185; paint metal1

# R2 Block E: NOR2_OH1 G8(oh0),G9(oh2) — VSS-G8-oh1-G9-VSS / VDD-G8-ps-G9-oh1
r2_nmos 8 9 14 14; r2_pmos 8 9 14 14
set r2e0 [sdl 8 14]; r2_ndc [lindex $r2e0 0] [lindex $r2e0 1]; r2_pdc [lindex $r2e0 0] [lindex $r2e0 1]
set r2e01 [sdb 8]; r2_ndc [lindex $r2e01 0] [lindex $r2e01 1]; r2_pdc [lindex $r2e01 0] [lindex $r2e01 1]
set r2e1 [sdr 9 14]; r2_ndc [lindex $r2e1 0] [lindex $r2e1 1]; r2_pdc [lindex $r2e1 0] [lindex $r2e1 1]
r2_cogc 8; r2_cogc 9
# NMOS: VSS, oh1-between, VSS
box [expr {[lindex $r2e0 0]+2}] 235 [expr {[lindex $r2e0 1]-2}] 273; paint metal1
box [expr {[lindex $r2e1 0]+2}] 235 [expr {[lindex $r2e1 1]-2}] 273; paint metal1
box [expr {[lindex $r2e01 0]+2}] 235 [expr {[lindex $r2e01 1]-2}] 260; paint metal1
# PMOS: VDD, ps-between(int), oh1-right
box [expr {[lindex $r2e0 0]+2}] 147 [expr {[lindex $r2e0 1]-2}] 185; paint metal1
box [expr {[lindex $r2e1 0]+2}] 160 [expr {[lindex $r2e1 1]-2}] 185; paint metal1

# ===============================================================
# M2 ROUTING — Use separate y channels to avoid shorts
# ===============================================================
# M2 channel plan (Row 1):
#   y=16..22 : nmid connection (B→C)
#   y=24..30 : x0 NMOS bus (C left,right)
#   y=34..40 : oh2 NMOS→PMOS M2
#   y=44..50 : nai → G2 gate
#   y=52..58 : nbi → G3 gate
#   y=78..84 : ai → G4 gate (using PMOS region above cogc)
#   y=84..90 : bi → G5 gate
#   y=92..98 : x0 PMOS bus (B_left, C_left)
#   y=100..106: x0 to G6 gate (NOR2 input)
#   y=108..114: cross-row routing (oh2, oh0)
#
# M2 channel plan (Row 2):
#   y=155..161: x1 PMOS bus
#   y=163..169: no0 NMOS↔PMOS
#   y=172..178: oh1 NMOS→PMOS
#   y=182..188: cross-row routing
#   y=192..198: R2 x1 to G7
#   y=198..204: R2 aj→G4, bj→G5
#   y=226..232: naj→G2
#   y=234..240: nbj→G3
#   y=242..248: oh1 via
#   y=250..256: nmid R2
#   y=258..264: x1 NMOS bus

# === R1: nai (left of G0) → G2 gate (OAI22_0 nai) ===
# nai is on M1 drain strip: x=2..12, y=20..120
# G2 cogc is at: x=102..116, y=60..70
# Via on nai M1 drain at y=44..50
box 4 44 10 50; paint via1
# Via on G2 cogc (must overlap M1 on cogc at x=104..114)
box 104 64 110 70; paint via1
# M2 horizontal
box 4 44 110 50; paint metal2

# === R1: nbi (right of G1) → G3 gate ===
# nbi: x=74..84, y=20..120
# G3 cogc: x=146..160, y=60..70
box 76 52 82 58; paint via1
box 148 64 154 70; paint via1
box 76 52 154 58; paint metal2

# === R1: ai (G0 gate) → G4 gate ===
# ai is on G0 cogc: x=16..28, y=60..70 (M1+cogc)
# G4 cogc: x=190..204, y=60..70
# We need to route ai without merging with nai or nbi routes.
# Use a separate M2 track at y=78..84 (above cogc, in PMOS region)
# Via on G0 cogc at edge
box 18 64 24 70; paint via1
# Via on G4 cogc
box 192 64 198 70; paint via1
# But wait — both vias are at y=64..70 overlapping the cogc region.
# If M2 goes from y=64 at x=18 to y=64 at x=192, it crosses nai M2 (y=44..50)
# and nbi M2 (y=52..58) — no overlap, those are at different y.
# But it also crosses the bi→G5 route...
# Actually the problem is that a single via1 on a cogc pad already exists if we place it there.
# The cogc pad at G0 (x=16..28) has M1 on it. Placing via1 at x=18..24 connects M1→M2.
# Then M2 at y=64..70 from G0 to G4 passes through G1 cogc (x=60..72) which also has M1.
# If M2 touches M1 on G1 cogc via a via1, that shorts ai=bi.
#
# CRITICAL FIX: We must NOT run M2 through other cogc pads at the same y.
# Instead, route ai using a different y channel that avoids cogc pads.
# Route: G0 cogc → via1 → M2 at y=78..84 (above cogc) → via1 at G4 → cogc connection
#
# To go from cogc y=60..70 to M2 y=78..84, we need an M1 stub that goes up from cogc.
# Actually, the via1 on cogc connects cogc(M1) to M2. So we can place the via1 on cogc
# and run M2 at the cogc y level. But we must NOT pass M2 over other cogc pads.
#
# Solution: Use M2 + M3 (via2) to jump over obstacles. But let's try simpler approach:
# Place via1 on cogc only at endpoints (G0, G4) and use M2 that DOESN'T cross
# other cogc pads. Since G0 is at x=14..30 and G4 is at x=190..206, M2 must cross
# G1(x=58..74), G2(x=102..118), G3(x=146..162) — all of which have cogc+M1 at y=60..70.
# A horizontal M2 at y=64..70 would intersect via1 stubs at G1/G2/G3 if they have via1.
#
# The trick: only G0 and G4 have via1. G1/G2/G3 cogc pads have M1 but NO via1.
# So M2 at y=64..70 can cross over G1/G2/G3 M1 without shorting, as long as there's
# no via1 at those positions. M2 to M1 connection only happens through via1.
# So this is SAFE as long as we don't place via1 on G1/G2/G3 for this route.

# ai route: G0 cogc → via1 → M2 (y=64..70) → via1 → G4 cogc
box 18 64 24 70; paint via1
box 192 64 198 70; paint via1
box 18 64 198 70; paint metal2

# bi route: G1 cogc → via1 → M2 (y=74..80) → via1 → G5 cogc
# G1 cogc: x=60..72; G5 cogc: x=234..248
# Use M2 at y=74..80 (just above ai M2)
# Via at G1 cogc — place at y=64..70 (on cogc)
# But we need M2 at y=74..80. The via1 at G1 would be at y=64..70, M2 at y=74..80.
# These don't overlap in y, so we need to connect via M2 vertical stub.
# Actually, via1 connects M1 to M2. So via1 at G1 (y=64..70) creates M2 at that location.
# Then we need M2 going from y=70 up to y=74, then horizontal to G5, then down to G5 via1.
#
# Simpler: Use a via1 that spans cogc AND extends into the desired M2 track.
# But via1 has min size constraints. Let's just route bi at y=64..70 also but on a DIFFERENT
# M2 bus... No, that would merge with ai.
#
# OK the real fix: route bi using the NMOS region instead. Use M1 stubs at G1 and G5
# drain/source to go from poly gate contact down to NMOS region, then via1→M2 there.
#
# Actually the simplest approach: since ai M2 at y=64..70 already passes through G1 and
# G2/G3, we can't place via1 at y=64..70 on G1 (that would short bi to ai).
# Instead, for bi: use cogc via1 at G1 at edge of cogc (y=60..66), M2 at y=56..62
# But that overlaps nbi M2 at y=52..58... they'd be different y ranges (56..62 vs 52..58)
# — actually they overlap at y=56..58!
#
# This routing is getting extremely tight. Let me use a completely different strategy:
# DON'T use cogc via1 for inter-gate routing. Instead, use the poly stub regions
# and M1 pads in the drain/source areas.
#
# NEW STRATEGY: Route all inter-gate signals through M1 in drain/source regions + M2.
# The cogc pads only provide labels for the primary inputs (ai, bi, aj, bj).
# All internal routing uses M1 drain pads + via1 + M2.

# ERASE the ai M2 route we just painted (conflict potential)
box 18 64 198 70; paint space
box 18 64 24 70; paint space
box 192 64 198 70; paint space
# Actually we need to be careful about erasing — let me NOT erase via1/M2 already painted
# since that could damage other layers. Let's restart this section.

# ACTUALLY: The ai M2 route at y=64..70 is fine IF we don't place via1 on G1/G2/G3 cogc
# at that y level. Let me re-examine: if we run M2 at y=64..70 from G0 to G4, it crosses
# G1/G2/G3 cogc+M1 pads. But M2 is a DIFFERENT metal layer. M2 crossing M1 without via1
# does NOT create a connection. So ai M2 at y=64..70 is safe.
#
# For bi: we can't use y=64..70 (already taken by ai M2). Use y=60..66 track.
# G1 cogc at y=60..70 has M1. Place via1 on G1 cogc at y=60..66.
# G5 cogc at y=60..70 has M1. Place via1 on G5 cogc at y=60..66.
# M2 at y=60..66 from x=62 to x=236.
# But ai M2 at y=64..70 overlaps with bi M2 at y=60..66 at y=64..66!
# That would merge the two M2 buses. NOT safe.
#
# Use y=56..62 for bi:
# Via1 at G1 cogc bottom edge (y=60..66) overlaps with M2 y=56..62 at y=60..62.
# Hmm, via1 min size is 6x6nm. If via1 is at y=60..66 and M2 is at y=56..62, they overlap
# at y=60..62 (2nm) — not enough for a valid via1.
#
# Better approach: DON'T route through cogc at all. Use the poly stubs at y=5..10 (bottom)
# or y=130..135 (top) for gate signal pickup, then route through M1+via1+M2.
#
# SIMPLEST APPROACH: Accept that ext2spice with cthresh extracts node names from coordinates,
# not labels. We'll fix the Xyce deck to use the correct node mappings.
# The physical layout connectivity is what matters — labels just name nodes for external ports.
# For simulation, we map the extracted poly node names to signal names.

# Let me RE-DO the routing cleanly. Use ONLY M1 + M2 in drain/source regions.
# NO via1 on cogc pads for inter-gate routing (only for labeling external ports).

# First erase all the M2/via1 we already placed:
# (We haven't actually placed them yet in this run — the script was being written.
#  The problematic ones above were in-line with the analysis. Let me just not paint them.)

# === R1: nai (INV G0 drain) → OAI22_0 G2 gate ===
# nai M1 strip is at x=2..12, y=20..120
# G2 poly stub bottom is at x=102..118, y=5..10
# Route via M2 in NMOS drain region (y=20..45)
# Via1 on nai M1 at x=4..10, y=24..30
box 4 24 10 30; paint via1
# Via1 at G2 bottom poly stub: need M1 pad on G2 gate bottom
# The poly at G2 bottom is at gx(2)=102 to gxr(2)=118, y=5..10
# We need a cogc or poly-to-M1 connection at G2 gate bottom.
# Actually we already have cogc at G2 (y=60..70). Let me use that.
# But routing M2 from y=24..30 (nai region) to y=60..70 (cogc) requires vertical M2.
#
# Simpler: Use M2 horizontal in the bottom poly stub region (y=5..10)
# But there's no M1 or via1 there — just poly.
#
# The cleanest approach: Route all gate-to-gate signals using cogc via1 at the endpoints
# only, with careful M2 track separation. Each M2 track must be at a unique y band.

# === CLEAN ROUTING PLAN ===
# Use 6nm-high M2 tracks with 6nm spacing (12nm pitch minimum for M2 on ASAP5)
# Available M2 routing channels (y ranges):
# R1 upper channels (between cogc and PMOS contacts, y=70..95):
#   Track U1: y=74..80
#   Track U2: y=80..86
# R1 lower channels (below NMOS contacts, y=14..20):
#   Track L1: y=14..20  (conflicts with VSS rail at y=0..14)
# R1 drain region channels (y=20..55):
#   Track D1: y=20..26
#   Track D2: y=26..32
#   Track D3: y=32..38
#   Track D4: y=38..44
# R1 cogc region:
#   Track CG1: y=60..66
#   Track CG2: y=66..72

# I'll use the following clean separation:
# nai→G2: M2 at y=20..26 (track D1)
# nbi→G3: M2 at y=26..32 (track D2)
# nmid B↔C: M2 at y=32..38 (track D3)
# x0 NMOS: M2 at y=38..44 (track D4)
# ai→G4: via1 on cogc, M2 at y=62..68 (inside cogc, NO via1 between endpoints)
# bi→G5: via1 on cogc, M2 at y=72..78 (just above cogc, using the poly bridge region)
# x0 PMOS: M2 at y=92..98 (PMOS contact region)
# oh2 N↔P: M2 at y=98..104
# x0→G6: use cogc via1 at y=62..68

# Wait, ai and x0 can't both use y=62..68. Let me use:
# ai→G4: M2 at y=62..68 (cogc level) — via1 at G0 and G4 cogc endpoints only
# x0→G6: M2 at y=80..86 — use PMOS region M1 stubs for via access
# bi→G5: This is the problem one. Can we connect bi (G1 gate) to G5 gate without
#         crossing the ai M2 bus?
# bi M2 must go from x~62 to x~234. ai M2 goes from x~18 to x~192 at y=62..68.
# If bi uses y=72..78, it needs via1 connections that bridge from cogc (y=60..70) to
# the M2 level. A via1 at y=68..74 on G1 would work (overlapping cogc top).
# Then M2 at y=72..78. Via1 at G5 at y=68..74. This doesn't overlap ai M2 (y=62..68).

# === ROUTE ai: G0 cogc → M2(y=62..68) → G4 cogc ===
box 18 62 24 68; paint via1
box 192 62 198 68; paint via1
box 18 62 198 68; paint metal2

# === ROUTE bi: G1 cogc → M2(y=72..78) → G5 cogc ===
# We need via1 at G1 that connects cogc(M1) to M2 at y=72..78.
# cogc+M1 at G1 is at y=60..70. Via1 placed at y=68..74 overlaps M1 at y=68..70.
# Actually via1 needs to sit on M1 (layer below) and touch M2 (layer above).
# If M1 extends to y=70 and via1 is at y=68..74, the M1 portion is y=68..70 (2nm overlap).
# We need full via1 coverage on M1. Minimum via1 = 6x6. M1 must cover entire via1 footprint.
# So we need M1 from y=68 to y=74 — but cogc+M1 only goes to y=70.
# Extend M1 above cogc:
box [expr {[gx 1]+2}] 70 [expr {[gxr 1]-2}] 78; paint metal1
box 62 72 68 78; paint via1
box [expr {[gx 5]+2}] 70 [expr {[gxr 5]-2}] 78; paint metal1
box 236 72 242 78; paint via1
box 62 72 242 78; paint metal2

# === ROUTE nai: INV G0 drain M1 → G2 cogc ===
# nai M1 strip: x=2..12, y=20..120. Via1 at x=4..10, y=24..30 on M1.
# G2 cogc M1: x=104..114, y=60..70. Need to connect via M2.
# Route: via1(nai M1, y=44..50) → M2 horizontal → via1(on G2 cogc, y=60..66)
# But these vias are at different y. Need vertical M2 or dog-leg.
# Simpler: extend G2 cogc M1 downward and place via1 at y=44..50 level.
# G2 cogc M1 is at x=104..114, y=60..70. Extend M1 down to y=48:
box 104 48 114 60; paint metal1
# Via1 on nai M1 at y=48..54
box 4 48 10 54; paint via1
# Via1 on extended G2 M1 at y=48..54
box 106 48 112 54; paint via1
# M2 horizontal connecting the two
box 4 48 112 54; paint metal2

# === ROUTE nbi: INV G1 drain M1 → G3 cogc ===
# nbi M1: x=74..84, y=20..120. G3 cogc M1: x=148..158, y=60..70.
# Extend G3 cogc M1 down:
box 148 42 158 60; paint metal1
box 76 42 82 48; paint via1
box 150 42 156 48; paint via1
box 76 42 156 48; paint metal2

# === ROUTE nmid: B(between G2-G3) → C(between G4-G5) ===
# nmid B at x=[lindex $b01 0]+2..[lindex $b01 1]-2, y=20..45 (NMOS M1 pad)
# nmid C at x=[lindex $c01 0]+2..[lindex $c01 1]-2, y=20..45
set nmb_xl [expr {[lindex $b01 0]+2}]
set nmc_xl [expr {[lindex $c01 0]+2}]
box [expr {$nmb_xl+2}] 32 [expr {$nmb_xl+8}] 38; paint via1
box [expr {$nmc_xl+2}] 32 [expr {$nmc_xl+8}] 38; paint via1
box [expr {$nmb_xl+2}] 32 [expr {$nmc_xl+8}] 38; paint metal2

# === ROUTE x0: connect all x0 nodes ===
# x0 nodes:
#   PMOS B left: x=[lindex $b0 0]+2..+10, y=95..120
#   PMOS C left: x=[lindex $c0 0]+2..+10, y=95..120
#   NMOS C left: x=[lindex $c0 0]+2..+10, y=20..45
#   NMOS C right: x=[lindex $c1 0]+2..+10, y=20..45
# Connect PMOS B_left and C_left via M2 (same y, horizontal)
set xp0_x [expr {[lindex $b0 0]+4}]
set xp1_x [expr {[lindex $c0 0]+4}]
box $xp0_x 95 [expr {$xp0_x+6}] 101; paint via1
box $xp1_x 95 [expr {$xp1_x+6}] 101; paint via1
box $xp0_x 95 [expr {$xp1_x+6}] 101; paint metal2
# Connect NMOS C_left and C_right via M2
set xn0_x [expr {[lindex $c0 0]+4}]
set xn1_x [expr {[lindex $c1 0]+4}]
box $xn0_x 24 [expr {$xn0_x+6}] 30; paint via1
box $xn1_x 24 [expr {$xn1_x+6}] 30; paint via1
box $xn0_x 24 [expr {$xn1_x+6}] 30; paint metal2
# Connect PMOS x0 to NMOS x0: vertical M2 at C_left x position
box $xp1_x 30 [expr {$xp1_x+6}] 95; paint metal2

# === ROUTE x0 → G6 gate (NOR2_OH2 input x0) ===
# G6 cogc: x=gx(6)+2..gxr(6)-2 = 278..292, y=60..70
# x0 is at x0 PMOS B_left (~x=90). Route via M2 from x0 up to G6.
# Use M2 track at y=86..92 (between PMOS contacts and cogc)
# Via1 on x0 PMOS M1 at B_left
box $xp0_x 86 [expr {$xp0_x+6}] 92; paint via1
# Extend G6 cogc M1 upward and place via1
box 280 70 290 92; paint metal1
box 282 86 288 92; paint via1
box $xp0_x 86 288 92; paint metal2

# === ROUTE oh2: connect NMOS drain (between G6-G7) to PMOS drain (right of G7) ===
set oh2n_x [expr {[lindex $d01 0]+4}]
set oh2p_x [expr {[lindex $d1 0]+4}]
box $oh2n_x 24 [expr {$oh2n_x+6}] 30; paint via1
box $oh2p_x 102 [expr {$oh2p_x+6}] 108; paint via1
box $oh2n_x 24 [expr {$oh2p_x+6}] 30; paint metal2
box $oh2p_x 30 [expr {$oh2p_x+6}] 102; paint metal2

# ===============================================================
# ROW 2 ROUTING
# ===============================================================

# === R2: naj (left of G0) → G2 gate ===
# naj M1: x=2..12, y=160..260. G2 cogc M1: x=104..114, y=210..220
# Extend G2 cogc M1 up (toward NMOS):
box 104 220 114 232; paint metal1
box 4 228 10 234; paint via1
box 106 226 112 232; paint via1
box 4 226 112 232; paint metal2

# === R2: nbj (right of G1) → G3 gate ===
box 148 220 158 238; paint metal1
box 76 234 82 240; paint via1
box 150 234 156 240; paint via1
box 76 234 156 240; paint metal2

# === R2: aj → G4 gate; bj → G5 gate ===
# aj: G0 cogc (x=16..28, y=210..220) → G4 cogc (x=190..204, y=210..220)
# M2 at y=212..218 (cogc level, no via1 between endpoints)
box 18 212 24 218; paint via1
box 192 212 198 218; paint via1
box 18 212 198 218; paint metal2

# bj: G1 cogc → G5 cogc at a different y track
# Extend G1 and G5 cogc M1 downward (toward PMOS):
box [expr {[gx 1]+2}] 202 [expr {[gxr 1]-2}] 210; paint metal1
box [expr {[gx 5]+2}] 202 [expr {[gxr 5]-2}] 210; paint metal1
box 62 202 68 208; paint via1
box 236 202 242 208; paint via1
box 62 202 242 208; paint metal2

# === R2: nmid B↔C ===
set r2nmb_xl [expr {[lindex $r2b01 0]+2}]
set r2nmc_xl [expr {[lindex $r2c01 0]+2}]
box [expr {$r2nmb_xl+2}] 244 [expr {$r2nmb_xl+8}] 250; paint via1
box [expr {$r2nmc_xl+2}] 244 [expr {$r2nmc_xl+8}] 250; paint via1
box [expr {$r2nmb_xl+2}] 244 [expr {$r2nmc_xl+8}] 250; paint metal2

# === R2: x1 connections ===
set r2xp0 [expr {[lindex $r2b0 0]+4}]
set r2xp1 [expr {[lindex $r2c0 0]+4}]
box $r2xp0 180 [expr {$r2xp0+6}] 186; paint via1
box $r2xp1 180 [expr {$r2xp1+6}] 186; paint via1
box $r2xp0 180 [expr {$r2xp1+6}] 186; paint metal2
set r2xn0 [expr {[lindex $r2c0 0]+4}]
set r2xn1 [expr {[lindex $r2c1 0]+4}]
box $r2xn0 252 [expr {$r2xn0+6}] 258; paint via1
box $r2xn1 252 [expr {$r2xn1+6}] 258; paint via1
box $r2xn0 252 [expr {$r2xn1+6}] 258; paint metal2
# Vertical P→N
box $r2xp1 186 [expr {$r2xp1+6}] 252; paint metal2

# === R2: x1 → G7 gate (NAND2 input) ===
# G7 cogc: x=gx(7)+2..gxr(7)-2 = 322..336, y=210..220
# Route from x1 area to G7
# Extend G7 cogc M1 down
box 324 190 334 210; paint metal1
box 326 190 332 196; paint via1
box $r2xp0 190 332 196; paint metal2

# === R2: no0 NMOS↔PMOS ===
# no0 NMOS: left of G6, x=[lindex $r2d0 0]+2..[lindex $r2d0 1]-2, y=235..260
# no0 PMOS left: same x, y=160..185
# no0 PMOS right: x=[lindex $r2d1 0]+2..., y=160..185
# Connect NMOS to PMOS via vertical M2
set no0_x [expr {[lindex $r2d0 0]+4}]
box $no0_x 246 [expr {$no0_x+6}] 252; paint via1
box $no0_x 166 [expr {$no0_x+6}] 172; paint via1
box $no0_x 172 [expr {$no0_x+6}] 246; paint metal2
# Connect PMOS right to PMOS left
set no0r_x [expr {[lindex $r2d1 0]+4}]
box $no0r_x 166 [expr {$no0r_x+6}] 172; paint via1
box $no0_x 160 [expr {$no0r_x+6}] 166; paint metal2

# === R2: oh1 NMOS↔PMOS ===
set oh1n_x [expr {[lindex $r2e01 0]+4}]
set oh1p_x [expr {[lindex $r2e1 0]+4}]
box $oh1n_x 240 [expr {$oh1n_x+6}] 246; paint via1
box $oh1p_x 174 [expr {$oh1p_x+6}] 180; paint via1
box $oh1p_x 174 [expr {$oh1n_x+6}] 180; paint metal2
box $oh1n_x 180 [expr {$oh1n_x+6}] 240; paint metal2

# ===============================================================
# CROSS-ROW ROUTING (R1 ↔ R2)
# ===============================================================

# === x0 (R1) → R2 G6 gate (NAND2 input x0) ===
# x0 is at R1 PMOS area. G6 cogc R2: x=280..290, y=210..220
# Extend G6 R2 cogc M1 down:
box 280 198 290 210; paint metal1
box 282 198 288 204; paint via1
# x0 via in R1 at G6 column (reuse the M2 bus from x0→G6 R1 at y=86..92)
# We already have x0 M2 going to x=282..288 at y=86..92.
# Extend M2 vertically from y=92 to y=198 (crossing through VDD rail region)
box 282 92 288 204; paint metal2

# === x1 (R2) → R1 G7 gate (NOR2_OH2 input x1) ===
# x1 is in R2. G7 R1 cogc: x=322..336, y=60..70
# Extend G7 R1 cogc M1 upward:
box 324 70 334 92; paint metal1
box 326 86 332 92; paint via1
# x1 is connected via R2 M2 bus at y=190..196 going to x=326..332
# Extend M2 from that bus down to R1 G7:
box 326 92 332 190; paint metal2

# === no0 (R2) → R1 G8 gate (INV_oh0 input) ===
# no0 is at R2 node. R1 G8 cogc: x=gx(8)+2..gxr(8)-2 = 368..380, y=60..70
# Extend G8 R1 cogc M1 upward:
box 368 70 380 82; paint metal1
box 370 76 376 82; paint via1
# no0 M2 vertical is at x=no0_x..no0_x+6, y=172..246
# Route M2 from no0 vertical to G8:
# Horizontal M2 from no0_x to x=370 at y=152..158 (in VDD rail region)
box $no0_x 152 [expr {$no0_x+6}] 172; paint metal2
box $no0_x 152 376 158; paint metal2
box 370 76 376 158; paint metal2

# === oh0 (R1 drain G8) → R2 G8 gate (NOR2_OH1 input) ===
# oh0 M1: x=[lindex $e1 0]+2..[lindex $e1 1]-2, y=20..120
# R2 G8 cogc: x=gx(8)+2..gxr(8)-2 = 368..380, y=210..220
# Via1 on oh0 M1:
set oh0_x [expr {[lindex $e1 0]+4}]
box $oh0_x 110 [expr {$oh0_x+6}] 116; paint via1
# Extend R2 G8 cogc M1 down:
box 368 200 380 210; paint metal1
box 370 200 376 206; paint via1
# M2 vertical from oh0 (y=110) to R2 G8 (y=200)
box 370 116 [expr {$oh0_x+6}] 122; paint metal2
box 370 116 376 206; paint metal2

# === oh2 (R1) → R2 G9 gate (NOR2_OH1 input) ===
# oh2 is at R1 via M2 connected nodes.
# oh2 M2 vertical segment at oh2p_x, y=30..102
# R2 G9 cogc: x=gx(9)+2..gxr(9)-2 = 412..424, y=210..220
# Extend R2 G9 cogc M1 down:
box 412 196 424 210; paint metal1
box 414 196 420 202; paint via1
# M2 from oh2 to R2 G9: horizontal then vertical
box $oh2p_x 108 [expr {$oh2p_x+6}] 114; paint via1
box $oh2p_x 108 420 114; paint metal2
box 414 114 420 202; paint metal2

# ===============================================================
# LABELS
# ===============================================================
# Primary inputs on cogc (R1)
box [expr {[gx 0]+4}] 65 [expr {[gx 0]+10}] 65
label ai 1 cogc
box [expr {[gx 1]+4}] 65 [expr {[gx 1]+10}] 65
label bi 1 cogc

# Primary inputs on cogc (R2)
box [expr {[gx 0]+4}] 215 [expr {[gx 0]+10}] 215
label aj 1 cogc
box [expr {[gx 1]+4}] 215 [expr {[gx 1]+10}] 215
label bj 1 cogc

# oh0: on M1 drain right of R1 G8
box [expr {[lindex $e1 0]+6}] 70 [expr {[lindex $e1 0]+6}] 70
label oh0 1 metal1

# oh2: on M1 NMOS between R1 G6-G7
box [expr {[lindex $d01 0]+6}] 30 [expr {[lindex $d01 0]+6}] 30
label oh2 1 metal1

# oh1: on M1 NMOS between R2 G8-G9
box [expr {[lindex $r2e01 0]+6}] 248 [expr {[lindex $r2e01 0]+6}] 248
label oh1 1 metal1

# Power
box [expr {$W/2}] 7 [expr {$W/2}] 7
label VSS 1 metal1
box [expr {$W/2}] 140 [expr {$W/2}] 140
label VDD 1 metal1
box [expr {$W/2}] 273 [expr {$W/2}] 273
label VSS 1 metal1

# ===============================================================
# SAVE, DRC, EXTRACT
# ===============================================================
save /Users/bruce/CLAUDE/asap5/stdcells/fused_ppa/FUSED_E

drc catchup
set drc_count [drc count]
puts "FUSED_E DH DRC: $drc_count"

extract all
ext2spice cthresh 0.001
ext2spice -f ngspice -o /Users/bruce/CLAUDE/asap5/stdcells/fused_ppa/FUSED_E_ext.spice

puts "FUSED_E DH: ${W}nm x ${H}nm, aspect [format %.2f [expr {double($W)/$H}]]:1, 38T SLVT"
