PMOS Id-Vds Family Curves

.control
pre_osdi /tmp/bsimcmg.osdi
.endc

.include pmos_model.inc

VGS gate 0 dc -0.75
VDS drain 0 dc 0
N1 drain gate 0 0 pfet_5nm NF=1

.control
set filetype=ascii
dc VDS 0 -0.75 -0.005 VGS -0.3 -0.75 -0.05
wrdata /tmp/sim_pmos_idvds.dat i(VDS)
.endc

.end
