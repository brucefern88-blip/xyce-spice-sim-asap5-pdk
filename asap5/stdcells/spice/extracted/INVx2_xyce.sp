* INVx2_xyce.sp — Xyce-compatible extracted netlist with parasitics
* Source: Magic VLSI extraction of INVx2.mag (ASAP5 5nm GAA nanosheet)
* Tech: asap5.tech, style asap5_nom
* Extraction: ext2spice with cthresh=0 (all parasitic caps included)
*
* INVx2 - ASAP5 5nm GAA Nanosheet Inverter, 2x drive strength
* Cell: 44nm x 140nm (1 CPP)
* Process: ASAP5 GAA, Lg=16nm, CPP=44nm, VDD=0.7V
* Model: BSIM-CMG level=107 version=107 (Xyce)
*
* Node mapping (Magic → schematic):
*   a_14_14# / a_14_78# → A (gate input)
*   a_30_14#             → Y (drain output)
*   a_0_14#              → VSS (NMOS source)
*   a_0_78#              → VDD (PMOS source)
*   w_0_65#              → VDD (n-well tie)
*
* Device count: 2 (1x nmos_lvt + 1x pmos_lvt), each nfin=2
* Total extracted parasitic capacitance: ~0.538 fF
*   C(Y)   = 0.2241 fF  (output node — largest, dominates delay)
*   C(VSS) = 0.1476 fF  (NMOS source/diffusion)
*   C(VDD) = 0.1463 fF  (PMOS source/diffusion)
*   C(gate_internal) = 0.0233 fF  (gate poly routing)

.subckt INVx2 A Y VDD VSS

* --- Devices (BSIM-CMG level=107 for Xyce) ---
* PMOS: drain=Y, gate=A, source=VDD, body=VDD
mp1 Y A VDD VDD pmos_lvt l=16n nfin=2
mp2 Y A VDD VDD pmos_lvt l=16n nfin=2

* NMOS: drain=Y, gate=A, source=VSS, body=VSS
mn1 Y A VSS VSS nmos_lvt l=16n nfin=2
mn2 Y A VSS VSS nmos_lvt l=16n nfin=2

* --- Extracted parasitic capacitances ---
* From Magic ext2spice, cthresh=0, technology asap5_nom
Cext_Y   Y   0  0.2241f
Cext_VSS VSS 0  0.1476f
Cext_VDD VDD 0  0.1463f
Cext_A   A   0  0.0233f

.ends INVx2
