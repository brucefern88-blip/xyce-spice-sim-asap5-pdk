* =============================================================================
* test_asap5_device.sp — ASAP5 Nanosheet (GAA) BSIM-CMG Device Characterization
* =============================================================================
*
* Sweeps Id-Vgs and Id-Vds for NMOS/PMOS across all Vt flavors (LVT, RVT,
* SLVT, SRAM) using the ngspice wrapper library.
*
* ASAP5 geometry: geomod=3, Lg=16nm, hfin=32nm, d=8nm, VDD=0.7V
*
* Run:  ngspice test_asap5_device.sp
* =============================================================================

.lib '/Users/bruce/CLAUDE/asap5/spice/asap5_ngspice.lib' tt

.param vdd = 0.7

* =============================================================================
* NMOS LVT — Id-Vgs sweep (Vds=VDD, single sheet)
* =============================================================================
vgs_n  gate_n  0  dc 0
vds_n  drain_n 0  dc vdd

mn_lvt  drain_n gate_n 0 0 nmos_lvt
mn_rvt  drain_nr gate_n 0 0 nmos_rvt
mn_slvt drain_ns gate_n 0 0 nmos_slvt
mn_sram drain_nm gate_n 0 0 nmos_sram

vds_nr drain_nr 0 dc vdd
vds_ns drain_ns 0 dc vdd
vds_nm drain_nm 0 dc vdd

.dc vgs_n 0 0.7 0.005

.control
run
set hcopypscolor = 1
set color0 = white
set color1 = black

* Extract Ion/Ioff for all NMOS Vt flavors
let id_lvt  = -i(vds_n)
let id_rvt  = -i(vds_nr)
let id_slvt = -i(vds_ns)
let id_sram = -i(vds_nm)

* NMOS Id-Vgs plot
plot id_lvt id_rvt id_slvt id_sram vs v(gate_n) title 'ASAP5 NMOS Id-Vgs @Vds=0.7V' ylabel 'Id [A]' xlabel 'Vgs [V]'

* Log-scale for subthreshold
plot log10(abs(id_lvt)) log10(abs(id_rvt)) log10(abs(id_slvt)) log10(abs(id_sram)) vs v(gate_n) title 'ASAP5 NMOS log(Id)-Vgs @Vds=0.7V' ylabel 'log10(Id) [A]' xlabel 'Vgs [V]'

* Report Ion (at Vgs=Vdd) and Ioff (at Vgs=0)
echo "============================================="
echo "ASAP5 NMOS Device Summary (TT, Vds=0.7V)"
echo "============================================="
meas dc ion_lvt  find id_lvt  at=0.7
meas dc ion_rvt  find id_rvt  at=0.7
meas dc ion_slvt find id_slvt at=0.7
meas dc ion_sram find id_sram at=0.7
meas dc ioff_lvt  find id_lvt  at=0.0
meas dc ioff_rvt  find id_rvt  at=0.0
meas dc ioff_slvt find id_slvt at=0.0
meas dc ioff_sram find id_sram at=0.0
echo "============================================="

.endc

* =============================================================================
* PMOS LVT — Id-Vgs sweep (Vds=-VDD, single sheet)
* =============================================================================
vgs_p  gate_p  vdd_node  dc 0
vds_p  drain_p vdd_node  dc 'vdd'
vdd_src vdd_node 0 dc vdd

mp_lvt  drain_p gate_p vdd_node vdd_node pmos_lvt
mp_rvt  drain_pr gate_p vdd_node vdd_node pmos_rvt
mp_slvt drain_ps gate_p vdd_node vdd_node pmos_slvt
mp_sram drain_pm gate_p vdd_node vdd_node pmos_sram

vds_pr drain_pr vdd_node dc 'vdd'
vds_ps drain_ps vdd_node dc 'vdd'
vds_pm drain_pm vdd_node dc 'vdd'

.end
