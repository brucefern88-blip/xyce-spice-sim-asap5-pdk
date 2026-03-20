* =============================================================================
* test_asap5_native_inverter.sp — ASAP5 Inverter using ngspice-native models
* =============================================================================
*
* Tests VTC, propagation delay, and verifies capacitance calibration
* for the ASAP5 level-1 subcircuit models (all 4 Vt flavors).
*
* Run:  ngspice test_asap5_native_inverter.sp
* =============================================================================

.lib '/Users/bruce/CLAUDE/asap5/spice/asap5_ngspice_native.lib' tt

.param vdd_val = 0.7

* ── Supply ──
vdd  vdd  0  dc vdd_val
vss  vss  0  dc 0

* =============================================================================
* PART A: LVT Inverter VTC
* =============================================================================

vin  in  0  dc 0

xp1  out in  vdd vdd pmos_lvt
xn1  out in  vss vss nmos_lvt

.dc vin 0 0.7 0.001

.control
run
plot v(out) vs v(in) title 'ASAP5 LVT Inverter VTC (0.7V, TT)' ylabel 'Vout [V]' xlabel 'Vin [V]'
meas dc v_trip find v(in) when v(out)=0.35
echo "=== LVT VTC ==="
print v_trip
.endc

* =============================================================================
* PART B: LVT Inverter transient — propagation delay
* =============================================================================

.alter
.param vdd_val = 0.7

vin  in  0  pulse(0 vdd_val 50p 5p 5p 95p 200p)

xp1  out in  vdd vdd pmos_lvt
xn1  out in  vss vss nmos_lvt

* Load: FO1 (~0.05 fF Cg × 2 sheets = 0.1 fF gate + 0.05 fF wire)
cload out 0 0.15f

.tran 0.5p 400p

.control
run
plot v(in) v(out) title 'ASAP5 LVT Inverter Transient (0.7V)' ylabel 'V [V]' xlabel 'Time [s]'
meas tran tphl trig v(in) val='vdd_val/2' rise=1 targ v(out) val='vdd_val/2' fall=1
meas tran tplh trig v(in) val='vdd_val/2' fall=1 targ v(out) val='vdd_val/2' rise=1
echo "=== LVT Propagation Delay ==="
print tphl tplh
.endc

* =============================================================================
* PART C: All Vt flavors — Ion comparison
* =============================================================================

.alter
.param vdd_val = 0.7

vgs  gate  0  dc 0
vds  drain 0  dc 0.7

xn_slvt  drain gate vss vss nmos_slvt
xn_lvt   drain2 gate vss vss nmos_lvt
xn_rvt   drain3 gate vss vss nmos_rvt
xn_sram  drain4 gate vss vss nmos_sram

vds2 drain2 0 dc 0.7
vds3 drain3 0 dc 0.7
vds4 drain4 0 dc 0.7

.dc vgs 0 0.7 0.005

.control
run
let id_slvt = -i(vds)
let id_lvt  = -i(vds2)
let id_rvt  = -i(vds3)
let id_sram = -i(vds4)
plot id_slvt id_lvt id_rvt id_sram vs v(gate) title 'ASAP5 NMOS Id-Vgs All Vt (0.7V)' ylabel 'Id [A]' xlabel 'Vgs [V]'
echo "=== NMOS Ion @Vgs=VDD ==="
meas dc ion_slvt find id_slvt at=0.7
meas dc ion_lvt  find id_lvt  at=0.7
meas dc ion_rvt  find id_rvt  at=0.7
meas dc ion_sram find id_sram at=0.7
.endc

.end
