.subckt AOI21x1 A0 A1 B Y VDD VSS
mn_a0 Y    A0 mid_n VSS nmos_lvt l=16n w=32n
mn_a1 mid_n A1 VSS   VSS nmos_lvt l=16n w=32n
mn_b  Y    B  VSS   VSS nmos_lvt l=16n w=32n
mp_a0 mid_p A0 VDD   VDD pmos_lvt l=16n w=32n
mp_a1 mid_p A1 VDD   VDD pmos_lvt l=16n w=32n
mp_b  Y    B  mid_p VDD pmos_lvt l=16n w=32n
.ends
