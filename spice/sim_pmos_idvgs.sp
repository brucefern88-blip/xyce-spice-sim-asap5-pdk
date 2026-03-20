PMOS Id-Vgs Characteristics

.control
pre_osdi /tmp/bsimcmg.osdi
.endc

.include pmos_model.inc

VGS gate 0 dc 0
VDS drain 0 dc -0.75
N1 drain gate 0 0 pfet_5nm NF=1

.control
set filetype=ascii
dc VGS 0 -0.75 -0.005
wrdata /tmp/sim_pmos_idvgs_075.dat i(VDS)
alter VDS dc=-0.40
dc VGS 0 -0.40 -0.005
wrdata /tmp/sim_pmos_idvgs_040.dat i(VDS)
.endc

.end
