* Fused Hamming Cell — Variant A (Canonical, 48T)
* Inputs: ai, bi, aj, bj
* Outputs: OH0 (hd=0), OH1 (hd=1), OH2 (hd=2) — one-hot
* VDD=0.5V, ASAP5 LVT, W=100n L=16n
*
* Structure:
*   4x INV (input inversions)
*   2x XOR (8T CMOS, ai^bi and aj^bj)
*   2x INV (XOR output inversions)
*   OH0: NOR2(d0,d1) + INV = distance 0
*   OH1: XOR(d0,d1) via AOI = distance 1
*   OH2: AND2(d0,d1) via NAND+INV = distance 2

.subckt FUSED_A ai bi aj bj oh0 oh1 oh2 VDD VSS
* --- Input inverters ---
mn_iai nai ai VSS VSS nmos_lvt l=16n w=100n
mp_iai nai ai VDD VDD pmos_lvt l=16n w=100n
mn_ibi nbi bi VSS VSS nmos_lvt l=16n w=100n
mp_ibi nbi bi VDD VDD pmos_lvt l=16n w=100n
mn_iaj naj aj VSS VSS nmos_lvt l=16n w=100n
mp_iaj naj aj VDD VDD pmos_lvt l=16n w=100n
mn_ibj nbj bj VSS VSS nmos_lvt l=16n w=100n
mp_ibj nbj bj VDD VDD pmos_lvt l=16n w=100n
* --- XOR0: d0 = ai ^ bi (8T CMOS XOR) ---
mp_x0_1 x0pm ai VDD VDD pmos_lvt l=16n w=100n
mp_x0_2 x0pm bi VDD VDD pmos_lvt l=16n w=100n
mp_x0_3 d0 nai x0pm VDD pmos_lvt l=16n w=100n
mp_x0_4 d0 nbi x0pm VDD pmos_lvt l=16n w=100n
mn_x0_1 d0 ai x0nm1 VSS nmos_lvt l=16n w=100n
mn_x0_2 x0nm1 bi VSS VSS nmos_lvt l=16n w=100n
mn_x0_3 d0 nai x0nm2 VSS nmos_lvt l=16n w=100n
mn_x0_4 x0nm2 nbi VSS VSS nmos_lvt l=16n w=100n
* --- XOR1: d1 = aj ^ bj (8T CMOS XOR) ---
mp_x1_1 x1pm aj VDD VDD pmos_lvt l=16n w=100n
mp_x1_2 x1pm bj VDD VDD pmos_lvt l=16n w=100n
mp_x1_3 d1 naj x1pm VDD pmos_lvt l=16n w=100n
mp_x1_4 d1 nbj x1pm VDD pmos_lvt l=16n w=100n
mn_x1_1 d1 aj x1nm1 VSS nmos_lvt l=16n w=100n
mn_x1_2 x1nm1 bj VSS VSS nmos_lvt l=16n w=100n
mn_x1_3 d1 naj x1nm2 VSS nmos_lvt l=16n w=100n
mn_x1_4 x1nm2 nbj VSS VSS nmos_lvt l=16n w=100n
* --- XOR output inverters ---
mn_id0 xn0 d0 VSS VSS nmos_lvt l=16n w=100n
mp_id0 xn0 d0 VDD VDD pmos_lvt l=16n w=100n
mn_id1 xn1 d1 VSS VSS nmos_lvt l=16n w=100n
mp_id1 xn1 d1 VDD VDD pmos_lvt l=16n w=100n
* --- OH0: NOR2(d0,d1) + INV = ~(d0|d1) inverted = (d0 NOR d1 inverted) ---
mp_o0_1 o0ps d0 VDD VDD pmos_lvt l=16n w=100n
mp_o0_2 oh0 d1 o0ps VDD pmos_lvt l=16n w=100n
mn_o0_1 oh0 d0 VSS VSS nmos_lvt l=16n w=100n
mn_o0_2 oh0 d1 VSS VSS nmos_lvt l=16n w=100n
* --- OH1: XOR(d0,d1) = (d0 ^ xn1) | (xn0 ^ d1) via AOI ---
mp_a1_1 a1pm d0 VDD VDD pmos_lvt l=16n w=100n
mp_a1_2 a1pm xn1 VDD VDD pmos_lvt l=16n w=100n
mp_a1_3 no1 xn0 a1pm VDD pmos_lvt l=16n w=100n
mp_a1_4 no1 d1 a1pm VDD pmos_lvt l=16n w=100n
mn_a1_1 no1 d0 a1nm1 VSS nmos_lvt l=16n w=100n
mn_a1_2 a1nm1 xn1 VSS VSS nmos_lvt l=16n w=100n
mn_a1_3 no1 xn0 a1nm2 VSS nmos_lvt l=16n w=100n
mn_a1_4 a1nm2 d1 VSS VSS nmos_lvt l=16n w=100n
mn_io1 oh1 no1 VSS VSS nmos_lvt l=16n w=100n
mp_io1 oh1 no1 VDD VDD pmos_lvt l=16n w=100n
* --- OH2: NAND2(d0,d1) + INV ---
mp_n2_1 no2 d0 VDD VDD pmos_lvt l=16n w=100n
mp_n2_2 no2 d1 VDD VDD pmos_lvt l=16n w=100n
mn_n2_1 no2 d0 n2ns VSS nmos_lvt l=16n w=100n
mn_n2_2 n2ns d1 VSS VSS nmos_lvt l=16n w=100n
mn_io2 oh2 no2 VSS VSS nmos_lvt l=16n w=100n
mp_io2 oh2 no2 VDD VDD pmos_lvt l=16n w=100n
.ends
