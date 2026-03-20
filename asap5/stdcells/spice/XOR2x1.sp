.subckt XOR2x1 A B Y VDD VSS
* B inverter
mn_invb BB B VSS VSS nmos_lvt l=16n w=32n
mp_invb BB B VDD VDD pmos_lvt l=16n w=32n
* A inverter
mn_inva AB A VSS VSS nmos_lvt l=16n w=32n
mp_inva AB A VDD VDD pmos_lvt l=16n w=32n
* TG1: pass A when B=1 (N-gate=B, P-gate=BB)
mn_tg1 A B Y VSS nmos_lvt l=16n w=32n
mp_tg1 A BB Y VDD pmos_lvt l=16n w=32n
* TG2: pass ~A when B=0 (N-gate=BB, P-gate=B)
mn_tg2 AB BB Y VSS nmos_lvt l=16n w=32n
mp_tg2 AB B Y VDD pmos_lvt l=16n w=32n
.ends
