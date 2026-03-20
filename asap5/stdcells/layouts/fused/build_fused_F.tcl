# Build FUSED_F layout — Variant F (Hybrid, 42T, 21 gate pitches)
# Width: 21 * 44 = 924nm, Height: 140nm

proc gx {n} { return [expr {14 + $n * 44}] }
proc gxr {n} { return [expr {14 + $n * 44 + 16}] }

set W 924
set H 140
set NG 21

cellname rename (UNNAMED) FUSED_F
box 0 0 $W $H

box 0 65 $W $H
paint nwell
box 0 126 $W $H
paint metal1
box 0 0 $W 14
paint metal1

for {set n 0} {$n < $NG} {incr n} {
    box [gx $n] 5 [gxr $n] 10
    paint poly
    box [gx $n] 55 [gxr $n] 58
    paint poly
    box [gx $n] 72 [gxr $n] 75
    paint poly
    box [gx $n] 130 [gxr $n] 135
    paint poly
}

proc nmos_block {first last} {
    set s [expr {[gx $first] - 14}]
    set e [expr {[gxr $last] + 14}]
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
        paint nfet_lvt
    }
}
proc pmos_block {first last} {
    set s [expr {[gx $first] - 14}]
    set e [expr {[gxr $last] + 14}]
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
        paint pfet_lvt
    }
}
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
proc cogc_block {first last} {
    for {set n $first} {$n <= $last} {incr n} {
        box [expr {[gx $n] + 2}] 60 [expr {[gxr $n] - 2}] 70
        paint cogc
        box [expr {[gx $n] + 2}] 60 [expr {[gxr $n] - 2}] 70
        paint metal1
    }
}
proc build_block {first last} {
    nmos_block $first $last
    pmos_block $first $last
    ndc_block $first $last
    pdc_block $first $last
    cogc_block $first $last
}
proc drain_m1 {gl gr} {
    box $gl 20 $gr 120
    paint metal1
}

build_block 0 3
build_block 4 7
build_block 8 11
build_block 12 13
build_block 14 15
build_block 16 17
build_block 18 19
build_block 20 20

# M1 drains
drain_m1 [expr {[gxr 0] + 2}] [expr {[gx 1] - 2}]
drain_m1 [expr {[gxr 1] + 2}] [expr {[gx 2] - 2}]
drain_m1 [expr {[gxr 2] + 2}] [expr {[gx 3] - 2}]
drain_m1 [expr {[gxr 3] + 2}] [expr {[gxr 3] + 12}]

set x0_nl [expr {[gxr 5] + 2}]
box $x0_nl 20 [expr {[gx 6] - 2}] 45
paint metal1
box [expr {[gx 4] - 12}] 95 [expr {[gx 4] - 2}] 120
paint metal1

set x1_nl [expr {[gxr 9] + 2}]
box $x1_nl 20 [expr {[gx 10] - 2}] 45
paint metal1
box [expr {[gx 8] - 12}] 95 [expr {[gx 8] - 2}] 120
paint metal1

set d0_dl [expr {[gxr 12] + 2}]
drain_m1 $d0_dl [expr {[gx 13] - 2}]
set d1_dl [expr {[gxr 13] + 2}]
drain_m1 $d1_dl [expr {[gxr 13] + 12}]

set oh2_l [expr {[gx 14] - 12}]
drain_m1 $oh2_l [expr {[gx 14] - 2}]
box [expr {[gxr 15] + 2}] 95 [expr {[gxr 15] + 12}] 120
paint metal1

set no1_a_l [expr {[gx 16] - 12}]
drain_m1 $no1_a_l [expr {[gx 16] - 2}]
set no1_b_l [expr {[gx 18] - 12}]
drain_m1 $no1_b_l [expr {[gx 18] - 2}]

set oh1_dl [expr {[gxr 20] + 2}]
drain_m1 $oh1_dl [expr {[gxr 20] + 12}]

# M2 routing
set x0v [expr {$x0_nl + 2}]
box $x0v 30 [expr {$x0v + 6}] 36
paint via1
set g12v [expr {[gx 12] + 4}]
set g14v [expr {[gx 14] + 4}]
set g18v [expr {[gx 18] + 4}]
box $x0v 62 [expr {$g18v + 6}] 68
paint metal2
box $x0v 62 [expr {$x0v + 6}] 68
paint via1
box $g12v 62 [expr {$g12v + 6}] 68
paint via1
box $g14v 62 [expr {$g14v + 6}] 68
paint via1
box $g18v 62 [expr {$g18v + 6}] 68
paint via1

set x1v [expr {$x1_nl + 2}]
box $x1v 30 [expr {$x1v + 6}] 36
paint via1
set g13v [expr {[gx 13] + 4}]
set g15v [expr {[gx 15] + 4}]
set g17v [expr {[gx 17] + 4}]
box $x1v 52 [expr {$g17v + 6}] 58
paint metal2
box $x1v 52 [expr {$x1v + 6}] 58
paint via1
box $g13v 52 [expr {$g13v + 6}] 58
paint via1
box $g15v 52 [expr {$g15v + 6}] 58
paint via1
box $g17v 52 [expr {$g17v + 6}] 58
paint via1

set d0v [expr {$d0_dl + 2}]
set g16v [expr {[gx 16] + 4}]
box $d0v 72 [expr {$g16v + 6}] 78
paint metal2
box $d0v 72 [expr {$d0v + 6}] 78
paint via1
box $g16v 72 [expr {$g16v + 6}] 78
paint via1

set d1v [expr {$d1_dl + 2}]
set g19v [expr {[gx 19] + 4}]
box $d1v 82 [expr {$g19v + 6}] 88
paint metal2
box $d1v 82 [expr {$d1v + 6}] 88
paint via1
box $g19v 82 [expr {$g19v + 6}] 88
paint via1

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

set naiv [expr {[gxr 0] + 4}]
set g4v [expr {[gx 4] + 4}]
box $naiv 100 [expr {$g4v + 6}] 106
paint metal2
box $naiv 100 [expr {$naiv + 6}] 106
paint via1
box $g4v 100 [expr {$g4v + 6}] 106
paint via1

set nbiv [expr {[gxr 1] + 4}]
set g5v [expr {[gx 5] + 4}]
box $nbiv 92 [expr {$g5v + 6}] 98
paint metal2
box $nbiv 92 [expr {$nbiv + 6}] 98
paint via1
box $g5v 92 [expr {$g5v + 6}] 98
paint via1

set najv [expr {[gxr 2] + 4}]
set g8v [expr {[gx 8] + 4}]
box $najv 100 [expr {$g8v + 6}] 106
paint metal2
box $najv 100 [expr {$najv + 6}] 106
paint via1
box $g8v 100 [expr {$g8v + 6}] 106
paint via1

set nbjv [expr {[gxr 3] + 4}]
set g9v [expr {[gx 9] + 4}]
box $nbjv 92 [expr {$g9v + 6}] 98
paint metal2
box $nbjv 92 [expr {$nbjv + 6}] 98
paint via1
box $g9v 92 [expr {$g9v + 6}] 98
paint via1

# Labels
box [expr {[gx 0] + 4}] 65 [expr {[gx 0] + 10}] 65
label ai 1 cogc
box [expr {[gx 1] + 4}] 65 [expr {[gx 1] + 10}] 65
label bi 1 cogc
box [expr {[gx 2] + 4}] 65 [expr {[gx 2] + 10}] 65
label aj 1 cogc
box [expr {[gx 3] + 4}] 65 [expr {[gx 3] + 10}] 65
label bj 1 cogc
box [expr {$oh1_dl + 4}] 70 [expr {$oh1_dl + 4}] 70
label oh1 1 metal1
box [expr {$oh2_l + 4}] 70 [expr {$oh2_l + 4}] 70
label oh2 1 metal1
box [expr {$W / 2}] 133 [expr {$W / 2}] 133
label VDD 5 metal1
box [expr {$W / 2}] 7 [expr {$W / 2}] 7
label VSS 1 metal1

save /Users/bruce/CLAUDE/asap5/stdcells/layouts/fused/FUSED_F

drc catchup
set drc_count [drc count]
puts "FUSED_F DRC violations: $drc_count"

extract all
ext2spice lvs
ext2spice -f ngspice -o /Users/bruce/CLAUDE/asap5/stdcells/layouts/fused/FUSED_F_ext.spice

puts "FUSED_F layout complete: ${W}nm x ${H}nm, $NG gate pitches, 42T"
