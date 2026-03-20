NMOS Capacitance Extraction Cg Cd Cs vs Vgs

.control
pre_osdi /tmp/bsimcmg.osdi
.endc

.include tsmc_n5_osdi_nmos.inc

* Cgg: AC on gate, D=S=B=0
VGS gate 0 dc 0.375 ac 1
N1 0 gate 0 0 nfet_5nm NF=1

.control
set filetype=ascii

* Sweep Vgs for Cg
let vg_list = 0
let idx = 0
compose vgvals values 0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.375 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75

* Single freq extraction at 1GHz
foreach vg 0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.375 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75
  alter VGS dc=$vg
  ac lin 1 1e9 1e9
  let cg_val = imag(i(VGS))/(2*3.14159265*1e9)
  print $vg cg_val
end

.endc

.end
