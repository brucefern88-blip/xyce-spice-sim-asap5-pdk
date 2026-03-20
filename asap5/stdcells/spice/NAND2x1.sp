.subckt NAND2x1 A B Y VDD VSS
mn1 Y A mid VSS nmos_lvt l=16n w=32n
mn2 mid B VSS VSS nmos_lvt l=16n w=32n
mp1 Y A VDD VDD pmos_lvt l=16n w=32n
mp2 Y B VDD VDD pmos_lvt l=16n w=32n
.ends
