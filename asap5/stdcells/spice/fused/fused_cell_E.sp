* Fused Hamming Cell — Variant E (OAI22+NOR, 38T)
* Inputs: ai, bi, aj, bj
* Outputs: OH0 (hd=0), OH1 (hd=1), OH2 (hd=2) — one-hot
* VDD=0.5V, ASAP5 LVT
*
* Structure:
*   4x INV (input inversions)
*   2x OAI22 (XOR via OAI topology, saves 2T per XOR vs canonical)
*   OH2: NOR2(x0,x1) = AND of complements
*   OH0: NOR2(x0,x1) + INV
*   OH1: NOR2(oh0,oh2)

.subckt FUSED_E ai bi aj bj oh0 oh1 oh2 VDD VSS
* --- Input inverters (8T) ---
mn_iai nai ai VSS VSS nmos_lvt l=16n w=100n
mp_iai nai ai VDD VDD pmos_lvt l=16n w=100n
mn_ibi nbi bi VSS VSS nmos_lvt l=16n w=100n
mp_ibi nbi bi VDD VDD pmos_lvt l=16n w=100n
mn_iaj naj aj VSS VSS nmos_lvt l=16n w=100n
mp_iaj naj aj VDD VDD pmos_lvt l=16n w=100n
mn_ibj nbj bj VSS VSS nmos_lvt l=16n w=100n
mp_ibj nbj bj VDD VDD pmos_lvt l=16n w=100n
* --- XOR0 via OAI22: x0 = ~((nai|nbi) & (ai|bi)) = ai^bi (8T OAI22) ---
mp_q0_1 x0 nai q0pm1 VDD pmos_lvt l=16n w=100n
mp_q0_2 q0pm1 nbi VDD VDD pmos_lvt l=16n w=100n
mp_q0_3 x0 ai q0pm2 VDD pmos_lvt l=16n w=100n
mp_q0_4 q0pm2 bi VDD VDD pmos_lvt l=16n w=100n
mn_q0_1 q0nmid nai VSS VSS nmos_lvt l=16n w=100n
mn_q0_2 q0nmid nbi VSS VSS nmos_lvt l=16n w=100n
mn_q0_3 x0 ai q0nmid VSS nmos_lvt l=16n w=100n
mn_q0_4 x0 bi q0nmid VSS nmos_lvt l=16n w=100n
* --- XOR1 via OAI22: x1 = aj^bj (8T OAI22) ---
mp_q1_1 x1 naj q1pm1 VDD pmos_lvt l=16n w=100n
mp_q1_2 q1pm1 nbj VDD VDD pmos_lvt l=16n w=100n
mp_q1_3 x1 aj q1pm2 VDD pmos_lvt l=16n w=100n
mp_q1_4 q1pm2 bj VDD VDD pmos_lvt l=16n w=100n
mn_q1_1 q1nmid naj VSS VSS nmos_lvt l=16n w=100n
mn_q1_2 q1nmid nbj VSS VSS nmos_lvt l=16n w=100n
mn_q1_3 x1 aj q1nmid VSS nmos_lvt l=16n w=100n
mn_q1_4 x1 bj q1nmid VSS nmos_lvt l=16n w=100n
* --- OH2: NOR2(x0,x1) (4T) ---
mp_o2_1 o2ps x0 VDD VDD pmos_lvt l=16n w=100n
mp_o2_2 oh2 x1 o2ps VDD pmos_lvt l=16n w=100n
mn_o2_1 oh2 x0 VSS VSS nmos_lvt l=16n w=100n
mn_o2_2 oh2 x1 VSS VSS nmos_lvt l=16n w=100n
* --- OH0 path: NAND2(x0,x1) via NOR+INV ---
mp_n0_1 no0 x0 VDD VDD pmos_lvt l=16n w=100n
mp_n0_2 no0 x1 VDD VDD pmos_lvt l=16n w=100n
mn_n0_1 no0 x0 n0ns VSS nmos_lvt l=16n w=100n
mn_n0_2 n0ns x1 VSS VSS nmos_lvt l=16n w=100n
mn_io0 oh0 no0 VSS VSS nmos_lvt l=16n w=100n
mp_io0 oh0 no0 VDD VDD pmos_lvt l=16n w=100n
* --- OH1: NOR2(oh0,oh2) (4T) ---
mp_o1_1 o1ps oh0 VDD VDD pmos_lvt l=16n w=100n
mp_o1_2 oh1 oh2 o1ps VDD pmos_lvt l=16n w=100n
mn_o1_1 oh1 oh0 VSS VSS nmos_lvt l=16n w=100n
mn_o1_2 oh1 oh2 VSS VSS nmos_lvt l=16n w=100n
.ends
