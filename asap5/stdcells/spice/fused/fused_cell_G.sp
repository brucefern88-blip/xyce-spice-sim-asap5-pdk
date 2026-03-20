* Fused Hamming Cell — Variant G (Active-Low, 40T)
* Inputs: ai, bi, aj, bj
* Outputs: noh1 (hd=1, active-low), noh2 (hd=2, active-low)
* VDD=0.5V, ASAP5 LVT
*
* Structure:
*   4x INV (input inversions)
*   2x OAI22 (XOR via OAI)
*   2x INV (XOR output inversions)
*   nOH1: AOI22(d0,x1, x0,d1) — active-low, no output INV (saves 2T vs F)
*   nOH2: NAND2(d0,d1) — active-low

.subckt FUSED_G ai bi aj bj noh1 noh2 VDD VSS
* --- Input inverters (8T) ---
mn_iai nai ai VSS VSS nmos_lvt l=16n w=100n
mp_iai nai ai VDD VDD pmos_lvt l=16n w=100n
mn_ibi nbi bi VSS VSS nmos_lvt l=16n w=100n
mp_ibi nbi bi VDD VDD pmos_lvt l=16n w=100n
mn_iaj naj aj VSS VSS nmos_lvt l=16n w=100n
mp_iaj naj aj VDD VDD pmos_lvt l=16n w=100n
mn_ibj nbj bj VSS VSS nmos_lvt l=16n w=100n
mp_ibj nbj bj VDD VDD pmos_lvt l=16n w=100n
* --- XOR0 via OAI22: x0 = ai^bi (8T) ---
mp_q0_1 x0 nai q0pm1 VDD pmos_lvt l=16n w=100n
mp_q0_2 q0pm1 nbi VDD VDD pmos_lvt l=16n w=100n
mp_q0_3 x0 ai q0pm2 VDD pmos_lvt l=16n w=100n
mp_q0_4 q0pm2 bi VDD VDD pmos_lvt l=16n w=100n
mn_q0_1 q0nmid nai VSS VSS nmos_lvt l=16n w=100n
mn_q0_2 q0nmid nbi VSS VSS nmos_lvt l=16n w=100n
mn_q0_3 x0 ai q0nmid VSS nmos_lvt l=16n w=100n
mn_q0_4 x0 bi q0nmid VSS nmos_lvt l=16n w=100n
* --- XOR1 via OAI22: x1 = aj^bj (8T) ---
mp_q1_1 x1 naj q1pm1 VDD pmos_lvt l=16n w=100n
mp_q1_2 q1pm1 nbj VDD VDD pmos_lvt l=16n w=100n
mp_q1_3 x1 aj q1pm2 VDD pmos_lvt l=16n w=100n
mp_q1_4 q1pm2 bj VDD VDD pmos_lvt l=16n w=100n
mn_q1_1 q1nmid naj VSS VSS nmos_lvt l=16n w=100n
mn_q1_2 q1nmid nbj VSS VSS nmos_lvt l=16n w=100n
mn_q1_3 x1 aj q1nmid VSS nmos_lvt l=16n w=100n
mn_q1_4 x1 bj q1nmid VSS nmos_lvt l=16n w=100n
* --- XOR output inverters (4T) ---
mn_ix0 d0 x0 VSS VSS nmos_lvt l=16n w=100n
mp_ix0 d0 x0 VDD VDD pmos_lvt l=16n w=100n
mn_ix1 d1 x1 VSS VSS nmos_lvt l=16n w=100n
mp_ix1 d1 x1 VDD VDD pmos_lvt l=16n w=100n
* --- nOH1: AOI22(d0,x1, x0,d1) — active-low output (8T, no INV) ---
mp_a1_1 a1pm d0 VDD VDD pmos_lvt l=16n w=100n
mp_a1_2 a1pm x1 VDD VDD pmos_lvt l=16n w=100n
mp_a1_3 noh1 x0 a1pm VDD pmos_lvt l=16n w=100n
mp_a1_4 noh1 d1 a1pm VDD pmos_lvt l=16n w=100n
mn_a1_1 noh1 d0 a1nm1 VSS nmos_lvt l=16n w=100n
mn_a1_2 a1nm1 x1 VSS VSS nmos_lvt l=16n w=100n
mn_a1_3 noh1 x0 a1nm2 VSS nmos_lvt l=16n w=100n
mn_a1_4 a1nm2 d1 VSS VSS nmos_lvt l=16n w=100n
* --- nOH2: NAND2(d0,d1) — active-low output (4T) ---
mp_n2_1 noh2 d0 VDD VDD pmos_lvt l=16n w=100n
mp_n2_2 noh2 d1 VDD VDD pmos_lvt l=16n w=100n
mn_n2_1 noh2 d0 n2ns VSS nmos_lvt l=16n w=100n
mn_n2_2 n2ns d1 VSS VSS nmos_lvt l=16n w=100n
.ends
