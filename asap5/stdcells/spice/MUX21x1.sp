.subckt MUX21x1 D0 D1 S Y VDD VSS
* Select inverter
mn_invs SB S VSS VSS nmos_lvt l=16n w=32n
mp_invs SB S VDD VDD pmos_lvt l=16n w=32n
* TG0: pass D0 when S=0
mn_tg0 int SB D0 VSS nmos_lvt l=16n w=32n
mp_tg0 int S  D0 VDD pmos_lvt l=16n w=32n
* TG1: pass D1 when S=1
mn_tg1 int S  D1 VSS nmos_lvt l=16n w=32n
mp_tg1 int SB D1 VDD pmos_lvt l=16n w=32n
* Output inverter
mn_invy Y int VSS VSS nmos_lvt l=16n w=32n
mp_invy Y int VDD VDD pmos_lvt l=16n w=32n
.ends
