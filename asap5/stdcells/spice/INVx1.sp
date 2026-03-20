* INVx1 - ASAP5 5nm GAA Nanosheet Inverter, 1x drive strength
* Cell: 44nm x 140nm (1 CPP)
* Process: ASAP5 GAA, Lg=16nm, CPP=44nm, VDD=0.7V
* Model: BSIM-CMG level=72 version=107

.subckt INVx1 A Y VDD VSS
mn1 Y A VSS VSS nmos_lvt l=16n w=32n
mp1 Y A VDD VDD pmos_lvt l=16n w=32n
.ends INVx1
