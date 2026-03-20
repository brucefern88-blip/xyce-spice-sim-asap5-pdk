# Build XOR2x1 standard cell for ASAP5 5nm GAA nanosheet
# 8T transmission-gate XOR: 2 inverters + 2 transmission gates
# 4 gate columns at CPP=44nm
#
# Gate layout (left to right):
#   Col1 (x=22-38): B inverter - gate=B
#   Col2 (x=66-82): A inverter - gate=A
#   Col3 (x=110-126): TG1 - N:gate=B, P:gate=BB
#   Col4 (x=154-170): TG2 - N:gate=BB, P:gate=B
#
# NMOS row (y=14-65):
#   Col1 N: MN_invb - drain=BB, source=VSS
#   Col2 N: MN_inva - drain=AB, source shared with Col1 (VSS)
#   Col3 N: MN_tg1 - source=A, drain=Y
#   Col4 N: MN_tg2 - source=AB, drain=Y
#
# PMOS row (y=75-126):
#   Col1 P: MP_invb - drain=BB, source=VDD
#   Col2 P: MP_inva - drain=AB, source shared with Col1 (VDD)
#   Col3 P: MP_tg1 - source=A, drain=Y
#   Col4 P: MP_tg2 - source=AB, drain=Y
#
# Diffusion sharing plan (NMOS continuous strip):
#   |--S1(VSS)--|G1(B)|--D1/S2(BB)--|G2(A)|--D2/S3(AB)--|G3(B)|--S3(A)--|G4(BB)|--D4--|
#   Wait - this won't work because TG sources are A and AB, not contiguous.
#
# Better NMOS arrangement - 2 separate strips:
#   Strip 1 (inverters): VSS - G1(B) - BB - G2(A) - AB
#   Strip 2 (TGs): A_src - G3(B) - Y - G4(BB) - AB_src
#
# Actually let's use a single continuous ndiff strip and accept the routing:
#   NMOS: s0 | G1(B) | d1 | G2(A) | d2 | G3(?) | d3 | G4(?) | s4
#   For inverters, sources go to VSS; for TGs, need careful assignment.
#
# Revised approach - use continuous diffusion and route signals with metal:
#   NMOS diffusion regions between gates:
#     Region 0 (x=0 to x=22): Left S/D - connect to VSS (MN_invb source)
#     Region 1 (x=38 to x=66): Between G1-G2 - BB node (MN_invb drain, could be MN_inva source...
#       but MN_inva source=VSS, not BB. So we need a break or accept non-sharing)
#
# Let me reconsider. With shared diffusion, adjacent transistors share a S/D node.
# The 4 NMOS transistors in order:
#   MN_invb: S=VSS, D=BB (gate=B)
#   MN_inva: S=VSS, D=AB (gate=A) -- S=VSS, but the shared node with MN_invb.D would be BB, not VSS
#   MN_tg1:  S=A,   D=Y  (gate=B)
#   MN_tg2:  S=AB,  D=Y  (gate=BB)
#
# Shared diffusion between MN_invb and MN_inva: that shared S/D can be BB(drain of invb)
# But MN_inva.source needs to be VSS. So shared node is BB, but MN_inva needs VSS on its left.
# This means we need: VSS | G(B) | BB | G(A) | AB  -- but MN_inva source should be on left=BB? No.
#
# Reorder: swap MN_inva to have drain on left:
#   If MN_inva: drain=AB, source=VSS, then with gate=A:
#   Nodes: (left)AB | G(A) | VSS(right)   or   (left)VSS | G(A) | AB(right)
#
# With 4 gates, NMOS left to right:
#   Let's pick a good ordering. For TGs, shared drain (Y) in middle is good.
#
#   Arrangement: INV_B, INV_A, TG1, TG2
#   NMOS: VSS | B | BB | A | AB | B_gate | A_node | BB_gate | Y
#   Hmm, TG1 and TG2 share Y at their junction:
#   ... | TG1_source(A) | G3(B) | TG1_drain=TG2_drain(Y) | G4(BB) | TG2_source(AB)
#   That's good! TG1 and TG2 share the Y node between them.
#
# So NMOS continuous strip nodes (left to right):
#   n0(VSS) | G1(B) | n1(BB) | G2(A) | n2(AB) | G3(B) | n3(A_input) ...
#   Wait, n2=AB is MN_inva.drain, but then G3 left side=AB, G3=B for TG1,
#   TG1: gate=B, source=A, drain=Y. So n2(left of G3)=A? But n2 is also MN_inva.drain=AB.
#   Conflict! A != AB.
#
# We need n2 to serve as both MN_inva's right S/D and MN_tg1's left S/D.
# MN_inva: drain=AB, MN_tg1: source=A. AB != A, so no sharing here.
#
# Options:
# 1. Break the diffusion between INV and TG sections
# 2. Reorder gates so compatible nodes are adjacent
# 3. Use 2 ndiff strips
#
# Best approach: break diffusion. Two separate ndiff strips.
# Strip 1 (inverters): x=0..82: VSS | G1(B) | BB | G2(A) | AB
# Strip 2 (TGs):       x=88..192: A_src | G3(B) | Y | G4(BB) | AB_src
#
# Actually even simpler: just use individual S/D contacts for each transistor.
# With the existing inverter as reference, each gate has its own S/D regions on each side.
# The ndiff strip can still be continuous - it just means adjacent S/D regions are
# electrically connected through the diffusion. But if they're on different nets, that's a short.
#
# So we MUST break the diffusion where nets differ. Let me use separate strips per functional group.
# Group 1: inverters (col1, col2) - continuous ndiff/pdiff
# Group 2: TGs (col3, col4) - continuous ndiff/pdiff (Y node shared between TG1.drain and TG2.drain)
#
# For Group 1 (inverters), shared node between col1 and col2:
#   NMOS: VSS | G(B) | BB ... AB | G(A) | VSS  -- but shared node would be BB=AB? No, different.
#   So even inv_B and inv_A can't share diffusion in middle either (BB != AB for general case).
#   Hmm actually in a circuit they ARE different nets.
#
# OK, simplest correct approach: 4 separate transistor pairs, each with their own diffusion islands.
# Each gate column has its own ndiff and pdiff regions that don't merge with neighbors.
#
# Actually, looking at the inverter again: it has ndiff from x=0 to x=92 and x=108 to x=200,
# with a gap at the poly gate (x=92-108). The S/D regions are separated by the gate.
# There is NO diffusion continuity between the two inverter halves - they're on opposite sides of
# the single gate.
#
# For multi-gate cells, typically the diffusion IS continuous across all gates in the row,
# with each gate creating channel regions. But the catch is that adjacent S/D regions in the
# continuous strip are electrically connected.
#
# Standard cell practice: use continuous diffusion where possible, route with metal.
# So I'll use continuous strips and accept the node assignments:
#
# NMOS continuous from x=0 to x=192:
#   n0 | G1 | n1 | G2 | n2 | G3 | n3 | G4 | n4
#   where n0-n4 are the 5 S/D nodes
#
# Assign transistors:
#   G1(B): MN_invb - left=n0, right=n1
#   G2(A): MN_inva - left=n1, right=n2
#   G3: MN_tg1 or MN_tg2
#   G4: MN_tg2 or MN_tg1
#
# For MN_invb: S=VSS(n0), D=BB(n1)
# For MN_inva: needs S=VSS, D=AB. If S is on left, then n1=VSS. But n1=BB from MN_invb.
# So MN_inva source can't be on the left (BB != VSS).
# If MN_inva: D=AB(left=n1), S=VSS(right=n2), then n1 must be both BB and AB. That's wrong too.
#
# The only way to share diffusion between inverters: if the shared node is the same net.
# MN_invb.drain = BB, MN_inva.source = VSS. These are different, so NO sharing between inv_B and inv_A.
#
# Unless we reorder: put both sources together.
#   n0(BB) | G1(B) | n1(VSS) | G2(A) | n2(AB)
#   MN_invb: D=BB(n0), S=VSS(n1). MN_inva: S=VSS(n1), D=AB(n2).
#   YES! n1=VSS is shared between the two inverters. This works.
#
# For TGs:
#   MN_tg1: gate=B, S=A, D=Y
#   MN_tg2: gate=BB, S=AB, D=Y
#   If we put TG1 left of TG2:
#     n2(AB) | G3(B) | n3 | G4(BB) | n4
#     n2 is AB from inverter, but TG1 needs S=A on left. n2=AB != A. No sharing.
#
#   If we put a gap between inverters and TGs (separate diffusion strips):
#     TG strip: n3(A) | G3(B) | n4(Y) | G4(BB) | n5(AB)
#     TG1: S=A(n3), D=Y(n4), gate=B. TG2: S=Y(n4)... wait, TG2: S=AB, D=Y.
#     If we swap D and S (they're symmetric for pass transistors):
#     TG2: D=Y(n4), S=AB(n5), gate=BB. YES! n4=Y is shared.
#
# Final NMOS plan:
#   Strip 1 (x=0..82): BB | G1(B) | VSS | G2(A) | AB  (inverters)
#   Gap at x=82..110 (no diffusion)
#   Strip 2 (x=110..192): A | G3(B) | Y | G4(BB) | AB  (TGs)
#
# Wait, that has AB in both strips... AB from strip1 right end and AB from strip2 right end
# are separate diffusion islands. We'd need to connect them with metal. That's fine.
#
# Hmm, but we can also just keep one continuous strip if we accept routing:
#   BB | G1(B) | VSS | G2(A) | AB/A???
# AB and A are different nets, so we can't share n2 between inv_A drain and TG1 source.
#
# OK final decision: TWO diffusion strips, connected by metal where needed.
# Strip 1: inverters (col1+col2), continuous diffusion, shared VSS between them
# Strip 2: TGs (col3+col4), continuous diffusion, shared Y between them
#
# Same for PMOS:
# Strip 1: BB | G1(B) | VDD | G2(A) | AB  (inverters, shared VDD)
# Strip 2: A | G3(BB) | Y | G4(B) | AB   (TGs, shared Y, note PMOS gates are complementary)
#
# PMOS TG gates: MP_tg1: gate=BB, MP_tg2: gate=B
# So for PMOS TG strip: A | G3(BB) | Y | G4(B) | AB
#
# Geometry:
# Cell width = 192nm (4*44 + 8 left margin + 8 right margin? Let's see)
# Actually: with gates at x=22,66,110,154 and gate width=16:
#   G1: 22-38, G2: 66-82, G3: 110-126, G4: 154-170
#   Left margin: 0-22 (22nm), Right margin: 170-192 (22nm)
#   S/D region between G1-G2: 38-66 (28nm for contact)
#   S/D region between G2-G3: 82-110 (28nm -- this is where we break diffusion)
#   S/D region between G3-G4: 126-154 (28nm for Y contact)

# Following inverter geometry conventions:
# ndiff channel: y=45-55 (10nm), S/D: y=20-45 (25nm tall), rails: y=10-20
# pdiff channel: y=75-85 (10nm), S/D: y=85-120 (35nm tall), rails: y=120-130
# ndc: y=20-45, pdc: y=85-120, contacts 20nm wide
# poly: y=5-58 (N), y=72-135 (P)
# cogc: y=58-72

# Let me define precise coordinates:
# Cell boundary: 0,0 to 192,140

set cellname XOR2x1

cellname rename (UNNAMED) $cellname
box 0 0 192 140

# ===== NWELL =====
paint nwell
box 0 65 192 140
paint nwell

# ===== NDIFF - Strip 1 (inverters, col1+col2) =====
# Continuous ndiff from x=0 to x=82
# Channel regions at poly gates, S/D between/outside
# Bottom rail (thin): y=10-20
box 0 10 82 20
paint ndiff
# S/D regions: y=20-45
# n0: BB (left of G1): x=0-22
box 0 20 22 45
paint ndiff
# n1: VSS (between G1-G2): x=38-66 (shared VSS)
box 38 20 66 45
paint ndiff
# n2: AB (right of G2): x=82-88 -- actually this needs to end where strip1 ends
# With G2 at 66-82, right S/D is x=82 onward. Let's go to x=98 (16nm of S/D space)
# Wait, I need to be more careful. Let me reconsider the diffusion.
#
# ndiff needs to be continuous across the gates to form proper transistors.
# channel is where poly crosses ndiff (at y=45-55 height, poly spans the full width)
#
# For strip 1: ndiff continuous from x=0 to x=98 (covering G1 x=22-38 and G2 x=66-82)
# That's a big region. Actually:
# The ndiff "strip" is the region y=45-55 that runs continuously.
# Plus S/D regions y=20-45 where contacts land.
# Plus bottom extension y=10-20.
#
# Looking at the inverter: ndiff goes from x=0 to x=92 on left side (before gate) and x=108 to x=200
# on right side. But the gate region x=92-108 has POLY, and the poly crossing ndiff creates the FET channel.
# Wait, actually in the inverter, there IS ndiff at y=45-55 from x=0-92 and x=108-200 but NOT
# at y=45-55 through the gate region. Let me re-examine:
#
# Inverter ndiff:
#   rect 0 45 92 55     -- left channel region
#   rect 0 20 30 45     -- left S/D (VSS side, narrow 30nm)
#   rect 50 20 92 45    -- left S/D (right part)
#   rect 0 10 92 20     -- bottom rail
#   rect 108 45 200 55  -- right channel region
#   rect 108 20 150 45  -- right S/D
#   rect 170 20 200 45
#   rect 108 10 200 20  -- bottom rail
#
# So ndiff at y=45-55 goes from x=0-92 and x=108-200. The gate poly is at x=92-108.
# When poly overlaps ndiff, it forms the transistor channel.
# The ndiff IS continuous through the gate: x=0-92 (left) then gate at 92-108 creates channel,
# then x=108-200 (right). But in the .mag file they're listed as separate rects because
# the gate region has different layers (poly+ndiff = nfet).
#
# Actually I think ndiff and poly overlap to compose into nfet_lvt. So ndiff DOES exist under
# the gate -- it just becomes part of the transistor. In the .mag file, those are separate rectangles
# but ndiff extends through.
#
# Re-reading the tech file: "compose nfet_lvt poly nsd" -- so poly + nsd = nfet_lvt.
# And "paint nsd nselect ndiff" -- nsd = ndiff + nselect.
# So ndiff under poly gate becomes nfet_lvt channel (via composition with nselect).
#
# For the .mag file representation: ndiff at y=45-55 IS drawn from 0 to 92 continuously.
# The poly at x=92-108 overlaps it. Magic composes them into nfet_lvt internally.
# Similarly ndiff 108-200 is the right side.
# But wait: 0-92 and 108-200 with poly 92-108... the ndiff IS drawn there?
# Looking at the inverter .mag: no, ndiff at y=45-55 is:
#   rect 0 45 92 55   and  rect 108 45 200 55
# That's a gap at x=92-108. But poly is at x=92-108, y=5-58 and y=72-135.
# So poly at x=92-108, y=45-55 sits WITHOUT ndiff beneath. That doesn't form a transistor!
#
# Hmm, maybe the channel IS formed differently. Let me look at the compose section again.
# "compose nfet_lvt poly nsd" means when you paint nsd on top of poly, you get nfet_lvt.
# But in the .mag file, there's no nfet_lvt rectangle drawn -- it's formed by composition.
# Actually for the inverter, maybe the transistor is formed by ndiff abutting poly?
#
# Looking again: the inverter only has ndiff and poly as separate non-overlapping regions.
# The ndiff regions y=45-55 DON'T extend through x=92-108. So how is the transistor formed?
#
# Ah, I see: in Magic with this tech file, ndiff touching poly at the boundary creates
# the transistor channel. The ndiff regions ABUT the poly region. Magic treats abutting
# ndiff-poly boundaries as creating the FET. This is different from overlap-based composition.
#
# Actually wait: looking at it more carefully, the compose rules are:
#   compose nfet_lvt poly nsd  (poly + nsd = nfet_lvt in the database)
#   paint nsd nselect ndiff
# And connect rules show: ndiff connects to ndc, etc.
#
# I think the .mag file just shows the decomposed layers. When loaded, Magic knows that
# ndiff regions adjacent to poly on the active plane form the FET geometry.
# The key is: ndiff goes up to the poly edge, not through it. The channel is implicit.
#
# So for my layout, I'll follow the same convention: ndiff regions ABUT poly gates but don't overlap.
#
# Let me now define the exact geometry. Cell width = 192nm.

# Actually, let me just write this directly as a .mag file. It'll be cleaner and more precise
# than trying to use paint commands with complex routing.

puts "Building XOR2x1..."
puts "This script will create the layout by painting geometry."
puts "Use 'source build_xor2x1.tcl' in Magic."

# Just quit - we'll build the .mag file directly instead
quit -noprompt
