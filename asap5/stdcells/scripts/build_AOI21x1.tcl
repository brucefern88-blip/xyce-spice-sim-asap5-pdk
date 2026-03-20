# AOI21x1: Y = ~((A0 & A1) | B)
# Cell: 260nm x 140nm
# Gates: A0 x=36-52, A1 x=124-140, B x=212-228 (2*CPP spacing for contact clearance)
#
# NMOS (continuous ndiff): Y--[A0]--mid_n--[A1]--VSS--[B]--Y
# PMOS (continuous pdiff): mid_p--[A0]--VDD--[A1]--mid_p--[B]--Y

tech load asap5
cellname rename (UNNAMED) AOI21x1
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

# === POLY GATES (16nm wide, spanning NMOS y=5-58 and PMOS y=72-135) ===
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

# === NDC CONTACTS (ndiff to M1) ===
# Y left: x=4-26, y=22-46
box 4 22 26 46
paint ndc
# VSS: x=150-176, y=22-46
box 150 22 176 46
paint ndc
# Y right: x=238-256, y=22-46
box 238 22 256 46
paint ndc

# === PDC CONTACTS (pdiff to M1) ===
# mid_p left: x=4-26, y=84-116
box 4 84 26 116
paint pdc
# VDD: x=62-88, y=84-116
box 62 84 88 116
paint pdc
# mid_p center: x=150-176, y=84-116
box 150 84 176 116
paint pdc
# Y right: x=238-256, y=84-116
box 238 84 256 116
paint pdc

# === COGC (contact-on-gate, poly to M1) ===
# A0: x=38-50, y=60-70
box 38 60 50 70
paint cogc
# A1: x=126-138, y=60-70
box 126 60 138 70
paint cogc
# B: x=214-226, y=60-70
box 214 60 226 70
paint cogc

# === METAL1 ROUTING ===
# VDD rail
box 0 126 260 140
paint metal1
# VSS rail
box 0 0 260 14
paint metal1

# VDD strap: pdc VDD (x=62-88) up to VDD rail
box 64 84 86 126
paint metal1

# VSS strap: ndc VSS (x=150-176) down to VSS rail
box 152 14 174 46
paint metal1

# Y right: vertical M1 connecting ndc Y right to pdc Y right
box 240 22 254 116
paint metal1

# Y left ndc M1 pad
box 6 22 24 50
paint metal1

# mid_p left pdc M1 pad
box 2 82 28 118
paint metal1

# mid_p center pdc M1 pad
box 148 82 178 118
paint metal1

# Gate M1 pads over cogc
box 36 58 52 72
paint metal1
box 124 58 140 72
paint metal1
box 212 58 228 72
paint metal1

# === VIA1 + METAL2 ROUTING ===
# mid_p route (M2): connect left mid_p to center mid_p
box 6 90 20 104
paint via1
box 152 90 166 104
paint via1
box 4 88 178 106
paint metal2

# Y route (M2): connect left Y to right Y
box 6 28 20 42
paint via1
box 240 28 254 42
paint via1
box 4 26 256 44
paint metal2

# === LABELS ===
box 15 34 15 34
label Y metal1
box 247 100 247 100
label Y metal1
box 44 65 44 65
label A0 cogc
box 132 65 132 65
label A1 cogc
box 220 65 220 65
label B cogc
box 163 7 163 7
label VSS metal1
box 130 133 130 133
label VDD metal1

# Save
save /Users/bruce/CLAUDE/asap5/stdcells/layouts/AOI21x1
drc catchup
drc count
extract all
ext2spice hierarchy on
ext2spice
puts "AOI21x1 complete"
