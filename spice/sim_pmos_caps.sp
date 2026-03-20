PMOS Capacitance vs Vgs

.control
pre_osdi /tmp/bsimcmg.osdi
.endc

.include pmos_model.inc

VGS gate 0 dc -0.375 ac 1
VDS drain 0 dc 0
N1 drain gate 0 0 pfet_5nm NF=1

.control
set filetype=ascii
dc VGS 0 -0.75 -0.025
wrdata /tmp/sim_pmos_cg.dat @n1[cgg]
wrdata /tmp/sim_pmos_cgs.dat @n1[cgs]
wrdata /tmp/sim_pmos_cgd.dat @n1[cgd]
.endc

.end
