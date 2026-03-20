# Build MUX21x1 from scratch using paint commands
cellname rename (UNNAMED) MUX21x1

# ============ WELLS ============
box 0 65 288 140
paint nwell
# PWELL for NMOS region (p-substrate)
box 0 0 288 65
paint pwell

# ============ NDIFF ============
# N1 (INV_S): x=0..66 (VSS, SB) — stops before D0
box 0 10 66 55
paint ndiff
# N2 (TG0+TG1): x=78..218 (D0, int, D1) — extends under P1 gate
box 78 10 218 55
paint ndiff
# N3 (INV_Y): x=228..286 (Y, VSS)
box 228 10 286 55
paint ndiff

# ============ PDIFF ============
# P1 (INV_S): x=0..66
box 0 75 66 130
paint pdiff
# P2 (TG0+TG1): x=78..218 — extends under P1 gate
box 78 75 218 130
paint pdiff
# P3 (INV_Y): x=228..286
box 228 75 286 130
paint pdiff

# ============ NFET_LVT (NMOS gate channels) ============
box 30 10 46 55
paint nfet_lvt
box 96 10 112 55
paint nfet_lvt
box 184 10 200 55
paint nfet_lvt
box 250 10 266 55
paint nfet_lvt

# ============ PFET_LVT (PMOS gate channels) ============
box 30 75 46 130
paint pfet_lvt
box 96 75 112 130
paint pfet_lvt
box 184 75 200 130
paint pfet_lvt
box 250 75 266 130
paint pfet_lvt

# ============ POLY (gate extensions outside diffusion) ============
# P0: INV_S — full height connections
box 30 5 46 10
paint poly
box 30 55 46 75
paint poly
box 30 130 46 135
paint poly
# P1: TG0 NMOS half extension + gap (split)
box 96 5 112 10
paint poly
box 96 55 112 62
paint poly
# P1: TG0 PMOS half extension
box 96 72 112 75
paint poly
box 96 130 112 135
paint poly
# P2: TG1 NMOS half extension
box 184 5 200 10
paint poly
box 184 55 200 62
paint poly
# P2: TG1 PMOS half extension
box 184 72 200 75
paint poly
box 184 130 200 135
paint poly
# P3: INV_Y — full height
box 250 5 266 10
paint poly
box 250 55 266 75
paint poly
box 250 130 266 135
paint poly

# ============ NDC ============
box 4 20 26 45
paint ndc
box 50 20 66 45
paint ndc
box 82 20 94 45
paint ndc
box 138 20 162 45
paint ndc
box 204 20 216 45
paint ndc
box 232 20 248 45
paint ndc
box 270 20 284 45
paint ndc

# ============ PDC ============
box 4 85 26 120
paint pdc
box 50 85 66 120
paint pdc
box 82 85 94 120
paint pdc
box 138 85 162 120
paint pdc
box 204 85 216 120
paint pdc
box 232 85 248 120
paint pdc
box 270 85 284 120
paint pdc

# ============ COGC ============
box 34 62 42 70
paint cogc
box 97 52 103 58
paint cogc
box 105 72 111 78
paint cogc
box 185 52 191 58
paint cogc
box 193 72 199 78
paint cogc
box 254 62 262 70
paint cogc

# ============ METAL1 — Power rails ============
box 0 126 288 140
paint metal1
box 0 0 288 14
paint metal1

# VDD taps
box 4 120 26 126
paint metal1
box 270 120 284 126
paint metal1

# VSS taps
box 4 14 26 20
paint metal1
box 270 14 284 20
paint metal1

# ============ METAL1 — N-P vertical straps ============
# SB strap
box 54 44 64 85
paint metal1
# D0 strap
box 84 44 92 85
paint metal1
# int strap
box 148 44 158 85
paint metal1
# D1 strap
box 206 44 214 85
paint metal1
# Y strap
box 236 44 246 85
paint metal1

# ============ METAL1 — Gate routing M1 pads ============
# P0 cogc M1 pad + S routing stem
box 34 50 44 72
paint metal1
# P1 left column (SB gate of TG0 NMOS)
box 96 50 103 80
paint metal1
# P1 right column (S gate of TG0 PMOS)
box 105 50 112 80
paint metal1
# P2 left column (S gate of TG1 NMOS)
box 184 50 191 80
paint metal1
# P2 right column (SB gate of TG1 PMOS)
box 193 50 200 80
paint metal1
# P3 cogc M1 pad
box 254 50 264 72
paint metal1

# ============ VIA1 — S distribution ============
# S via1 at P0 (cogc -> M2)
box 36 52 42 58
paint via1
# S via1 at P1 right (M2 -> P1p cogc)
box 106 52 112 58
paint via1
# S via1 at P2 left (M2 -> P2n cogc)
box 185 52 191 58
paint via1

# ============ VIA1 — SB distribution ============
# SB via1 at SB strap (M1 -> M2)
box 56 74 62 80
paint via1
# SB via1 at P1 left (M2 -> P1n cogc)
box 97 74 103 80
paint via1
# SB via1 at P2 right (M2 -> P2p cogc)
box 194 74 200 80
paint via1

# ============ VIA1 — int to P3 via M2 ============
# int via1 on int strap
box 150 44 158 50
paint via1
# int via1 at P3
box 256 44 262 50
paint via1
# M1 stub from int via1 at P3 up to P3 cogc
box 256 50 262 62
paint metal1

# ============ METAL2 — S track (y=50-60) ============
box 35 50 192 60
paint metal2

# ============ METAL2 — SB track (y=74-84) ============
box 55 74 201 84
paint metal2

# ============ METAL2 — int track (y=38-48, below S track) ============
box 148 38 264 48
paint metal2

# ============ LABELS ============
box 38 66 38 66
label S 1 cogc
box 88 65 88 65
label D0 1 metal1
box 210 65 210 65
label D1 1 metal1
box 241 65 241 65
label Y 1 metal1
box 144 0 144 0
label VSS 1 metal1
box 144 140 144 140
label VDD 5 metal1

# ============ SAVE ============
save /Users/bruce/CLAUDE/asap5/stdcells/layouts/MUX21x1
puts "=== MUX21x1 built and saved ==="

# ============ DRC ============
drc catchup
drc check
puts "DRC count: [drc count total]"

# ============ EXTRACT ============
extract all
puts "=== Extraction complete ==="

# ============ EXT2SPICE ============
ext2spice lvs
ext2spice cthresh 0.01
ext2spice
puts "=== SPICE netlist generated ==="

quit -noprompt
