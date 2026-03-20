# Build FUSED_A layout — Variant A (Canonical, 48T, 24 gate pitches)
# Width: 24 * 44 = 1056nm, Height: 140nm

proc gx {n} { return [expr {14 + $n * 44}] }
proc gxr {n} { return [expr {14 + $n * 44 + 16}] }

set W 1056
set H 140
set NG 24

cellname rename (UNNAMED) FUSED_A
box 0 0 $W $H

# === NWELL ===
box 0 65 $W $H
paint nwell

# === VDD/VSS rails ===
box 0 126 $W $H
paint metal1
box 0 0 $W 14
paint metal1

# === POLY (only in non-diffusion regions: cogc gap and above/below active) ===
for {set n 0} {$n < $NG} {incr n} {
    set xl [gx $n]
    set xr [gxr $n]
    # Below NMOS active
    box $xl 5 $xr 10
    paint poly
    # Above NMOS active, below cogc (gap between NMOS and PMOS)
    box $xl 55 $xr 58
    paint poly
    # Above cogc, below PMOS active
    box $xl 72 $xr 75
    paint poly
    # Above PMOS active
    box $xl 130 $xr 135
    paint poly
}

# === Diffusion and FET helper procs ===
# Paint NMOS block: ndiff in S/D regions, nfet_lvt in gate channels
proc nmos_block {first last} {
    set s [expr {[gx $first] - 14}]
    set e [expr {[gxr $last] + 14}]
    # S/D regions (between and outside gates)
    # Left of first gate
    box $s 10 [gx $first] 55
    paint ndiff
    # Between gates
    for {set n $first} {$n < $last} {incr n} {
        box [gxr $n] 10 [gx [expr {$n+1}]] 55
        paint ndiff
    }
    # Right of last gate
    box [gxr $last] 10 $e 55
    paint ndiff
    # Gate channel regions: nfet_lvt
    for {set n $first} {$n <= $last} {incr n} {
        box [gx $n] 10 [gxr $n] 55
        paint nfet_lvt
    }
}

# Paint PMOS block
proc pmos_block {first last} {
    set s [expr {[gx $first] - 14}]
    set e [expr {[gxr $last] + 14}]
    # S/D regions
    box $s 85 [gx $first] 130
    paint pdiff
    for {set n $first} {$n < $last} {incr n} {
        box [gxr $n] 85 [gx [expr {$n+1}]] 130
        paint pdiff
    }
    box [gxr $last] 85 $e 130
    paint pdiff
    # Gate channel regions: pfet_lvt
    for {set n $first} {$n <= $last} {incr n} {
        box [gx $n] 85 [gxr $n] 130
        paint pfet_lvt
    }
}

# S/D contacts
proc ndc_block {first last} {
    set s [expr {[gx $first] - 14}]
    set e [expr {[gxr $last] + 14}]
    box [expr {$s + 2}] 20 [expr {[gx $first] - 2}] 45
    paint ndc
    for {set n $first} {$n < $last} {incr n} {
        box [expr {[gxr $n] + 2}] 20 [expr {[gx [expr {$n+1}]] - 2}] 45
        paint ndc
    }
    box [expr {[gxr $last] + 2}] 20 [expr {$e - 2}] 45
    paint ndc
}
proc pdc_block {first last} {
    set s [expr {[gx $first] - 14}]
    set e [expr {[gxr $last] + 14}]
    box [expr {$s + 2}] 95 [expr {[gx $first] - 2}] 120
    paint pdc
    for {set n $first} {$n < $last} {incr n} {
        box [expr {[gxr $n] + 2}] 95 [expr {[gx [expr {$n+1}]] - 2}] 120
        paint pdc
    }
    box [expr {[gxr $last] + 2}] 95 [expr {$e - 2}] 120
    paint pdc
}

# Gate contacts
proc cogc_block {first last} {
    for {set n $first} {$n <= $last} {incr n} {
        set xl [expr {[gx $n] + 2}]
        set xr [expr {[gxr $n] - 2}]
        box $xl 60 $xr 70
        paint cogc
        box $xl 60 $xr 70
        paint metal1
    }
}

# Full block helper
proc build_block {first last} {
    nmos_block $first $last
    pmos_block $first $last
    ndc_block $first $last
    pdc_block $first $last
    cogc_block $first $last
}

# Drain M1 (vertical, NMOS to PMOS)
proc drain_m1 {gl gr} {
    box $gl 20 $gr 120
    paint metal1
}

# === BUILD ALL DIFFUSION BLOCKS ===
# Input INVs: gates 0-3
build_block 0 3
# XOR0 stack A: gates 4-5
build_block 4 5
# XOR0 stack B: gates 6-7
build_block 6 7
# XOR1 stack A: gates 8-9
build_block 8 9
# XOR1 stack B: gates 10-11
build_block 10 11
# Buffer INVs: gates 12-13
build_block 12 13
# OH0 NOR2: gates 14-15
build_block 14 15
# OH1 AOI22 stack A: gates 16-17
build_block 16 17
# OH1 AOI22 stack B: gates 18-19
build_block 18 19
# OH1 output INV: gate 20
build_block 20 20
# OH2 NAND2: gates 21-22
build_block 21 22
# OH2 output INV: gate 23
build_block 23 23

# === M1 DRAIN CONNECTIONS ===
# INV drains (connect NMOS drain to PMOS drain vertically)
drain_m1 [expr {[gxr 0] + 2}] [expr {[gx 1] - 2}]
drain_m1 [expr {[gxr 1] + 2}] [expr {[gx 2] - 2}]
drain_m1 [expr {[gxr 2] + 2}] [expr {[gx 3] - 2}]
drain_m1 [expr {[gxr 3] + 2}] [expr {[gxr 3] + 12}]

# XOR0 d0 output: left S/D of gates 4 and 6
drain_m1 [expr {[gx 4] - 12}] [expr {[gx 4] - 2}]
drain_m1 [expr {[gx 6] - 12}] [expr {[gx 6] - 2}]

# XOR1 d1 output: left S/D of gates 8 and 10
drain_m1 [expr {[gx 8] - 12}] [expr {[gx 8] - 2}]
drain_m1 [expr {[gx 10] - 12}] [expr {[gx 10] - 2}]

# Buffer INV outputs
set xn0_dl [expr {[gxr 12] + 2}]
drain_m1 $xn0_dl [expr {[gx 13] - 2}]
set xn1_dl [expr {[gxr 13] + 2}]
drain_m1 $xn1_dl [expr {[gxr 13] + 12}]

# OH0: NOR2 output at left S/D of gate 14
set oh0_dl [expr {[gx 14] - 12}]
drain_m1 $oh0_dl [expr {[gx 14] - 2}]
# PMOS series output
box [expr {[gxr 15] + 2}] 95 [expr {[gxr 15] + 12}] 120
paint metal1

# OH1 INV drain
set oh1_dl [expr {[gxr 20] + 2}]
drain_m1 $oh1_dl [expr {[gxr 20] + 12}]

# OH2 INV drain
set oh2_dl [expr {[gxr 23] + 2}]
drain_m1 $oh2_dl [expr {[gxr 23] + 12}]

# AOI22 outputs (no1): left S/D of gates 16,18
set no1_a_l [expr {[gx 16] - 12}]
drain_m1 $no1_a_l [expr {[gx 16] - 2}]
set no1_b_l [expr {[gx 18] - 12}]
drain_m1 $no1_b_l [expr {[gx 18] - 2}]

# NAND2 output (no2): left S/D of gate 21
set no2_l [expr {[gx 21] - 12}]
drain_m1 $no2_l [expr {[gx 21] - 2}]

# === M2 SIGNAL ROUTING ===
# d0 bus at y=62-68: XOR0 outputs → gates 12, 14, 16, 21
set d0_start [expr {[gx 4] - 10}]
set d0_end [expr {[gx 21] + 10}]
box $d0_start 62 $d0_end 68
paint metal2
# Via1 drops
foreach gn {4 6 12 14 16 21} {
    set vx [expr {[gx $gn] - ($gn < 8 ? 10 : -4)}]
}
# Simpler: via at each gate cogc connection point
set d0_via1 [expr {[gx 4] - 10}]
box $d0_via1 62 [expr {$d0_via1 + 6}] 68
paint via1
set d0_via2 [expr {[gx 6] - 10}]
box $d0_via2 62 [expr {$d0_via2 + 6}] 68
paint via1
set g12v [expr {[gx 12] + 4}]
box $g12v 62 [expr {$g12v + 6}] 68
paint via1
set g14v [expr {[gx 14] + 4}]
box $g14v 62 [expr {$g14v + 6}] 68
paint via1
set g16v [expr {[gx 16] + 4}]
box $g16v 62 [expr {$g16v + 6}] 68
paint via1
set g21v [expr {[gx 21] + 4}]
box $g21v 62 [expr {$g21v + 6}] 68
paint via1

# d1 bus at y=52-58: XOR1 outputs → gates 13, 15, 19, 22
set d1_start [expr {[gx 8] - 10}]
set d1_end [expr {[gx 22] + 10}]
box $d1_start 52 $d1_end 58
paint metal2
set d1_via1 [expr {[gx 8] - 10}]
box $d1_via1 52 [expr {$d1_via1 + 6}] 58
paint via1
set d1_via2 [expr {[gx 10] - 10}]
box $d1_via2 52 [expr {$d1_via2 + 6}] 58
paint via1
set g13v [expr {[gx 13] + 4}]
box $g13v 52 [expr {$g13v + 6}] 58
paint via1
set g15v [expr {[gx 15] + 4}]
box $g15v 52 [expr {$g15v + 6}] 58
paint via1
set g19v [expr {[gx 19] + 4}]
box $g19v 52 [expr {$g19v + 6}] 58
paint via1
set g22v [expr {[gx 22] + 4}]
box $g22v 52 [expr {$g22v + 6}] 58
paint via1

# xn0 bus at y=72-78: buffer output gate 12 → AOI22 gate 18
set xn0v [expr {$xn0_dl + 2}]
set g18v [expr {[gx 18] + 4}]
box $xn0v 72 [expr {$g18v + 6}] 78
paint metal2
box $xn0v 72 [expr {$xn0v + 6}] 78
paint via1
box $g18v 72 [expr {$g18v + 6}] 78
paint via1

# xn1 bus at y=82-88: buffer output gate 13 → AOI22 gate 17
set xn1v [expr {$xn1_dl + 2}]
set g17v [expr {[gx 17] + 4}]
box $xn1v 82 [expr {$g17v + 6}] 88
paint metal2
box $xn1v 82 [expr {$xn1v + 6}] 88
paint via1
box $g17v 82 [expr {$g17v + 6}] 88
paint via1

# nai bus at y=92-98: INV0 drain → XOR0 gate 6
set naiv [expr {[gxr 0] + 4}]
set g6v [expr {[gx 6] + 4}]
box $naiv 92 [expr {$g6v + 6}] 98
paint metal2
box $naiv 92 [expr {$naiv + 6}] 98
paint via1
box $g6v 92 [expr {$g6v + 6}] 98
paint via1

# nbi bus at y=102-108: INV1 drain → XOR0 gate 7
set nbiv [expr {[gxr 1] + 4}]
set g7v [expr {[gx 7] + 4}]
box $nbiv 102 [expr {$g7v + 6}] 108
paint metal2
box $nbiv 102 [expr {$nbiv + 6}] 108
paint via1
box $g7v 102 [expr {$g7v + 6}] 108
paint via1

# naj bus: INV2 drain → XOR1 gate 10
set najv [expr {[gxr 2] + 4}]
set g10v [expr {[gx 10] + 4}]
box $najv 92 [expr {$g10v + 6}] 98
paint metal2
box $najv 92 [expr {$najv + 6}] 98
paint via1
box $g10v 92 [expr {$g10v + 6}] 98
paint via1

# nbj bus: INV3 drain → XOR1 gate 11
set nbjv [expr {[gxr 3] + 4}]
set g11v [expr {[gx 11] + 4}]
box $nbjv 102 [expr {$g11v + 6}] 108
paint metal2
box $nbjv 102 [expr {$nbjv + 6}] 108
paint via1
box $g11v 102 [expr {$g11v + 6}] 108
paint via1

# no1 bus: connect AOI22 stacks A and B → OH1 INV gate 20
set no1av [expr {$no1_a_l + 2}]
set no1bv [expr {$no1_b_l + 2}]
set g20v [expr {[gx 20] + 4}]
box $no1av 32 [expr {$g20v + 6}] 38
paint metal2
box $no1av 32 [expr {$no1av + 6}] 38
paint via1
box $no1bv 32 [expr {$no1bv + 6}] 38
paint via1
box $g20v 32 [expr {$g20v + 6}] 38
paint via1

# no2 bus: NAND2 output → OH2 INV gate 23
set no2v [expr {$no2_l + 2}]
set g23v [expr {[gx 23] + 4}]
box $no2v 42 [expr {$g23v + 6}] 48
paint metal2
box $no2v 42 [expr {$no2v + 6}] 48
paint via1
box $g23v 42 [expr {$g23v + 6}] 48
paint via1

# OH0: connect NMOS output to PMOS output via M2
set oh0_nv [expr {$oh0_dl + 2}]
set oh0_pv [expr {[gxr 15] + 4}]
box $oh0_nv 40 [expr {$oh0_pv + 6}] 46
paint metal2
box $oh0_nv 40 [expr {$oh0_nv + 6}] 46
paint via1
box $oh0_pv 100 [expr {$oh0_pv + 6}] 106
paint via1
box $oh0_pv 46 [expr {$oh0_pv + 6}] 106
paint metal2

# === LABELS ===
box [expr {[gx 0] + 4}] 65 [expr {[gx 0] + 10}] 65
label ai 1 cogc
box [expr {[gx 1] + 4}] 65 [expr {[gx 1] + 10}] 65
label bi 1 cogc
box [expr {[gx 2] + 4}] 65 [expr {[gx 2] + 10}] 65
label aj 1 cogc
box [expr {[gx 3] + 4}] 65 [expr {[gx 3] + 10}] 65
label bj 1 cogc

box [expr {$oh0_dl + 4}] 70 [expr {$oh0_dl + 4}] 70
label oh0 1 metal1
box [expr {$oh1_dl + 4}] 70 [expr {$oh1_dl + 4}] 70
label oh1 1 metal1
box [expr {$oh2_dl + 4}] 70 [expr {$oh2_dl + 4}] 70
label oh2 1 metal1

box [expr {$W / 2}] 133 [expr {$W / 2}] 133
label VDD 5 metal1
box [expr {$W / 2}] 7 [expr {$W / 2}] 7
label VSS 1 metal1

save /Users/bruce/CLAUDE/asap5/stdcells/layouts/fused/FUSED_A

drc catchup
set drc_count [drc count]
puts "FUSED_A DRC violations: $drc_count"

extract all
ext2spice lvs
ext2spice -f ngspice -o /Users/bruce/CLAUDE/asap5/stdcells/layouts/fused/FUSED_A_ext.spice

puts "FUSED_A layout complete: ${W}nm x ${H}nm, $NG gate pitches, 48T"
