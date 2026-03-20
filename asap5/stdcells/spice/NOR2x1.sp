.subckt NOR2x1 A B Y VDD VSS
mn1 Y A VSS VSS nmos_lvt l=16n w=32n
mn2 Y B VSS VSS nmos_lvt l=16n w=32n
mp1 Y A mid VDD pmos_lvt l=16n w=32n
mp2 mid B VDD VDD pmos_lvt l=16n w=32n
.ends
