* Extracted subcircuit for NOR2x1
* Magic layout extraction parasitics from NOR2x1.ext
* Devices: 4 (nmos_lvt, nmos_lvt, pmos_lvt, pmos_lvt)
* Total extracted node cap: 2.8 fF
*
.subckt NOR2x1 A B Y VDD VSS
mn1 Y A VSS VSS nmos_lvt l=16n w=32n
mn2 Y B VSS VSS nmos_lvt l=16n w=32n
mp1 Y A mid VDD pmos_lvt l=16n w=32n
mp2 mid B VDD VDD pmos_lvt l=16n w=32n
* --- Extracted parasitic capacitances ---
Cext_Y Y 0 0.9856f
Cext_A A 0 0.2253f
Cext_B B 0 0.2253f
Cext_mid mid 0 0.3379f
.ends
