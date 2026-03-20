# OAI21x1: Y = ~((A0 | A1) & B)
# Cell: 260nm x 140nm
# Gates: A0 x=36-52, A1 x=124-140, B x=212-228 (2*CPP spacing for contact clearance)
#
# NMOS: A0,A1 parallel (drain=mid_n, source=VSS) + B series (drain=Y, source=mid_n)
#   Arrangement on ndiff: VSS--[A0]--mid_n--[A1]--VSS  ...  mid_n--[B]--Y
#   But with continuous ndiff: mid_n--[A0]--VSS--[A1]--mid_n--[B]--Y
#
# PMOS: A0,A1 series (Y--[A0]--mid_p--[A1]--VDD) + B parallel (Y--[B]--VDD)
#   Arrangement on pdiff: Y--[A0]--mid_p--[A1]--VDD--[B]--Y
#   But VDD between A1 and B can't be contacted at 44nm CPP.
#   With 2*CPP spacing: Y--[A0]--mid_p--[A1]--VDD--[B]--Y (contacts fit in 72nm gaps)

tech load asap5
cellname rename (UNNAMED) OAI21x1
box 0 0 260 140

# === NWELL ===
box 0 65 260 140
paint nwell

# === NDIFF (continuous, y=10-55, x=2-258) ===
box 2 10 258 55
paint ndiff

# === PDIFF (continuous, y=75-130, x=2-258) ===
box 2 75 258 130
paint pdiff

# === POLY GATES ===
# A0
box 36 5 52 58
paint poly
box 36 72 52 135
paint poly
# A1
box 124 5 140 58
paint poly
box 124 72 140 135
paint poly
# B
box 212 5 228 58
paint poly
box 212 72 228 135
paint poly

# === NMOS TOPOLOGY ===
# OAI21 NMOS: A0,A1 parallel (source=VSS, drain=mid_n) + B (source=mid_n, drain=Y)
# Continuous ndiff arrangement: mid_n--[A0]--VSS--[A1]--mid_n--[B]--Y
#   x=2-36:    mid_n (A0 drain)
#   x=36-52:   gate A0
#   x=52-124:  VSS (A0 source, A1 source) — parallel pair shares VSS
#   x=124-140: gate A1
#   x=140-212: mid_n (A1 drain, B source) — continuous diffusion!
#   x=212-228: gate B
#   x=228-258: Y (B drain)

# NDC CONTACTS
# mid_n left: x=4-26, y=22-46 (connects to mid_n via M1 to center mid_n)
box 4 22 26 46
paint ndc
# VSS: x=62-88, y=22-46
box 62 22 88 46
paint ndc
# mid_n center: x=150-176, y=22-46
box 150 22 176 46
paint ndc
# Y right: x=238-256, y=22-46
box 238 22 256 46
paint ndc

# === PMOS TOPOLOGY ===
# OAI21 PMOS: A0,A1 series (drain=Y, mid_p internal) + B parallel (drain=Y, source=VDD)
# Series: Y--[A0]--mid_p--[A1]--VDD
# Parallel B: Y--[B]--VDD
# Arrangement: Y--[A0]--mid_p--[A1]--VDD--[B]--Y
#   x=2-36:    Y (A0 drain, B drain via M1)
#   x=36-52:   gate A0
#   x=52-124:  mid_p (A0 source, A1 drain) — no contact needed (internal node)
#   x=124-140: gate A1
#   x=140-212: VDD (A1 source, B source)
#   x=212-228: gate B
#   x=228-258: Y (B drain)

# PDC CONTACTS
# Y left: x=4-26, y=84-116
box 4 84 26 116
paint pdc
# VDD: x=150-176, y=84-116
box 150 84 176 116
paint pdc
# Y right: x=238-256, y=84-116
box 238 84 256 116
paint pdc

# === COGC (gate contacts) ===
box 38 60 50 70
paint cogc
box 126 60 138 70
paint cogc
box 214 60 226 70
paint cogc

# === METAL1 ROUTING ===
# VDD rail
box 0 126 260 140
paint metal1
# VSS rail
box 0 0 260 14
paint metal1

# VSS strap: ndc VSS (x=62-88) down to VSS rail
box 64 14 86 46
paint metal1

# VDD strap: pdc VDD (x=150-176) up to VDD rail
box 152 84 174 126
paint metal1

# Y right: vertical M1 connecting ndc Y right to pdc Y right
box 240 22 254 116
paint metal1

# Y left: vertical M1 connecting pdc Y left
box 2 82 28 118
paint metal1

# mid_n left ndc M1 pad
box 6 22 24 50
paint metal1

# mid_n center ndc M1 pad
box 148 22 178 48
paint metal1

# Gate M1 pads over cogc
box 36 58 52 72
paint metal1
box 124 58 140 72
paint metal1
box 212 58 228 72
paint metal1

# === VIA1 + METAL2 ROUTING ===
# mid_n route (M2): connect left mid_n to center mid_n
box 6 28 20 42
paint via1
box 152 28 166 42
paint via1
box 4 26 178 44
paint metal2

# Y route (M2): connect left Y (PMOS) to right Y (NMOS+PMOS)
# Y left PMOS (pdc at x=4-26, y=84-116): via1 on M1 pad
box 6 90 20 104
paint via1
# Y right (already connected vertically in M1): via1
box 240 90 254 104
paint via1
# M2 horizontal
box 4 88 256 106
paint metal2

# === LABELS ===
box 15 100 15 100
label Y metal1
box 247 70 247 70
label Y metal1
box 44 65 44 65
label A0 cogc
box 132 65 132 65
label A1 cogc
box 220 65 220 65
label B cogc
box 75 7 75 7
label VSS metal1
box 163 133 163 133
label VDD metal1

# Save
save /Users/bruce/CLAUDE/asap5/stdcells/layouts/OAI21x1
drc catchup
drc count
extract all
ext2spice hierarchy on
ext2spice
puts "OAI21x1 complete"
