# =============================================================
# MUX21x1 — 8T Transmission-Gate MUX (ASAP5 5nm GAA)
# =============================================================
# Build in Magic interactively with paint commands.
# Cell: 288nm x 140nm
#
# Gate assignments:
#   P0 (x=30-46):  INV_S, full height, gate=S
#   P1 (x=96-112): TG0, split, N-gate=SB, P-gate=S
#   P2 (x=184-200): TG1, split, N-gate=S, P-gate=SB
#   P3 (x=250-266): INV_Y, full height, gate=int
#
# NMOS S/D islands (y=20-50):
#   N1(0-68)=VSS/SB  N2(78-218)=D0/int/D1  N3(228-286)=Y/VSS
# PMOS S/D islands (y=85-120):
#   P1(0-68)=VDD/SB  P2(78-218)=D0/int/D1  P3(228-286)=Y/VDD
# =============================================================

cellname rename (UNNAMED) MUX21x1

# --- NWELL ---
box 0 65 288 140
paint nwell

# --- NDIFF islands ---
# N1: INV_S
box 0 20 68 50
paint ndiff
# N2: TG0+TG1
box 78 20 218 50
paint ndiff
# N3: INV_Y
box 228 20 286 50
paint ndiff

# --- PDIFF islands ---
# P1: INV_S
box 0 85 68 120
paint pdiff
# P2: TG0+TG1
box 78 85 218 120
paint pdiff
# P3: INV_Y
box 228 85 286 120
paint pdiff

# --- POLY gates (painting poly over ndiff/pdiff creates nfet/pfet devices) ---
# P0: INV_S — full height
box 30 5 46 135
paint poly

# P1: TG0 — split (separate N and P gates)
# P1 NMOS half
box 96 5 112 62
paint poly
# P1 PMOS half
box 96 73 112 135
paint poly

# P2: TG1 — split
# P2 NMOS half
box 184 5 200 62
paint poly
# P2 PMOS half
box 184 73 200 135
paint poly

# P3: INV_Y — full height
box 250 5 266 135
paint poly

# --- NDC contacts ---
# N1: VSS (left of P0)
box 8 24 24 44
paint ndc
# N1: SB (right of P0)
box 52 24 66 44
paint ndc
# N2: D0 (left of P1)
box 82 24 94 44
paint ndc
# N2: int (between P1 and P2)
box 140 24 162 44
paint ndc
# N2: D1 (right of P2)
box 204 24 216 44
paint ndc
# N3: Y (left of P3)
box 234 24 248 44
paint ndc
# N3: VSS (right of P3)
box 272 24 284 44
paint ndc

# --- PDC contacts ---
# P1: VDD (left of P0)
box 8 96 24 112
paint pdc
# P1: SB (right of P0)
box 52 96 66 112
paint pdc
# P2: D0 (left of P1)
box 82 96 94 112
paint pdc
# P2: int (between P1 and P2)
box 140 96 162 112
paint pdc
# P2: D1 (right of P2)
box 204 96 216 112
paint pdc
# P3: Y (left of P3)
box 234 96 248 112
paint pdc
# P3: VDD (right of P3)
box 272 96 284 112
paint pdc

# --- COGC (gate contacts) ---
# P0 (S)
box 34 63 44 71
paint cogc
# P1n (SB)
box 100 53 110 61
paint cogc
# P1p (S)
box 100 74 110 82
paint cogc
# P2n (S)
box 188 53 198 61
paint cogc
# P2p (SB)
box 188 74 198 82
paint cogc
# P3 (int)
box 254 63 264 71
paint cogc

# =============================================================
# METAL1 — Power rails
# =============================================================
box 0 126 288 140
paint metal1
box 0 0 288 14
paint metal1

# VDD taps
box 8 112 24 126
paint metal1
box 272 112 284 126
paint metal1

# VSS taps
box 8 14 24 24
paint metal1
box 272 14 284 24
paint metal1

# =============================================================
# METAL1 — N-P connection straps (vertical)
# =============================================================
# SB strap (connects INV_S N-drain and P-drain)
box 54 44 64 92
paint metal1

# D0 strap
box 84 44 92 92
paint metal1

# int strap
box 148 44 158 92
paint metal1

# D1 strap
box 206 44 214 92
paint metal1

# Y strap
box 236 44 246 92
paint metal1

# =============================================================
# METAL1 — cogc pads (M1 over cogc)
# =============================================================
# These are implicitly created by cogc paint

# =============================================================
# METAL2 — S distribution network
# S needs to reach: P0 cogc, P1p cogc, P2n cogc
# Use M2 with via1 at each cogc
# =============================================================

# M2 horizontal lower track (y=53-61, for NMOS cogcs)
# Connects P0 area to P2n
box 34 53 198 61
paint metal2

# M2 horizontal upper track (y=74-82, for PMOS cogcs)
# Connects P0 area to P1p only
box 34 74 110 82
paint metal2

# M2 vertical connector between lower and upper tracks
box 34 61 46 74
paint metal2

# Via1: P0 cogc -> S M2
box 36 63 44 71
paint via1

# Via1: P1p cogc -> S M2 upper
box 100 74 110 82
paint via1

# Via1: P2n cogc -> S M2 lower
box 188 53 198 61
paint via1

# =============================================================
# METAL2/METAL3 — SB distribution network
# SB needs to reach: P1n cogc, P2p cogc
# Use M3 to avoid crossing S on M2
# =============================================================

# M2 stub at SB strap -> via1 -> M2
box 56 63 64 71
paint via1
# Small M2 pad at SB
box 54 61 66 73
paint metal2

# via2 to get SB onto M3
box 56 63 64 71
paint via2

# M3 horizontal lower (to P1n, y=53-61)
box 54 53 112 61
paint metal3

# M3 horizontal upper (to P2p, y=74-82)
box 54 74 200 82
paint metal3

# M3 vertical connector
box 54 61 66 74
paint metal3

# At P1n: M3 -> via2 -> M2 -> via1 -> M1/cogc
box 100 53 110 61
paint metal3
box 100 53 110 61
paint via2
box 98 51 112 63
paint metal2
box 100 53 110 61
paint via1

# At P2p: M3 -> via2 -> M2 -> via1 -> M1/cogc
box 188 74 198 82
paint metal3
box 188 74 198 82
paint via2
box 186 72 200 84
paint metal2
box 188 74 198 82
paint via1

# =============================================================
# METAL2 — int to P3 routing
# =============================================================
# Via1 on int M1 strap
box 150 63 158 71
paint via1
# M2 horizontal from int to P3
box 148 53 266 63
paint metal2
# Via1 at P3 cogc
box 254 55 264 63
paint via1
# M1 vertical from via1 down to P3 cogc
box 254 63 264 71
paint metal1

# =============================================================
# LABELS
# =============================================================
box 39 67 39 67
label S 1 cogc

box 88 68 88 68
label D0 1 metal1

box 210 68 210 68
label D1 1 metal1

box 241 68 241 68
label Y 1 metal1

box 144 0 144 0
label VSS 1 metal1

box 144 140 144 140
label VDD 5 metal1

# =============================================================
# SAVE AND VERIFY
# =============================================================
select top cell
save /Users/bruce/CLAUDE/asap5/stdcells/layouts/MUX21x1
puts "=== MUX21x1 layout saved ==="
