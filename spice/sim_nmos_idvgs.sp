NMOS Id-Vgs Characteristics

.control
pre_osdi /tmp/bsimcmg.osdi
.endc

.include nmos_model.inc

VGS gate 0 dc 0
VDS drain 0 dc 0.75
N1 drain gate 0 0 nfet_5nm NF=1

.control
set filetype=ascii
dc VGS 0 0.75 0.005
wrdata /tmp/sim_nmos_idvgs_075.dat -i(VDS)
alter VDS dc=0.40
dc VGS 0 0.40 0.005
wrdata /tmp/sim_nmos_idvgs_040.dat -i(VDS)
.endc

.end
