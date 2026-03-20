.subckt XNOR2x1 A B Y VDD VSS
mn_invb BB B VSS VSS nmos_lvt l=16n w=32n
mp_invb BB B VDD VDD pmos_lvt l=16n w=32n
mn_inva AB A VSS VSS nmos_lvt l=16n w=32n
mp_inva AB A VDD VDD pmos_lvt l=16n w=32n
mn_tg1 AB B Y VSS nmos_lvt l=16n w=32n
mp_tg1 AB BB Y VDD pmos_lvt l=16n w=32n
mn_tg2 A BB Y VSS nmos_lvt l=16n w=32n
mp_tg2 A B Y VDD pmos_lvt l=16n w=32n
.ends
