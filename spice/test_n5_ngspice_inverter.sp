* =============================================================================
* test_n5_ngspice_inverter.sp — CMOS Inverter using ngspice-native models
* =============================================================================
*
* Parallel to test_n5_inverter.sp — uses level=1 subcircuit models.
* Tests VTC, propagation delay, and verifies capacitance calibration.
*
* Run:  ngspice test_n5_ngspice_inverter.sp
* =============================================================================

.lib 'tsmc_n5_ngspice.lib' tt

.param vdd_val = 0.75

* ── Supply ──
vdd  vdd  0  dc vdd_val
vss  vss  0  dc 0

* =============================================================================
* PART A: Inverter VTC (DC sweep)
* =============================================================================

vin  in  0  dc 0

xp1  out in  vdd vdd pfet_5nm
xn1  out in  vss vss nfet_5nm

.dc vin 0 0.75 0.001

.control
run

* Plot VTC
plot v(out) vs v(in) title 'N5 ngspice-native Inverter VTC (0.75V, TT)' ylabel 'Vout [V]' xlabel 'Vin [V]'

* Find trip point
meas dc v_trip find v(in) when v(out)=0.375

echo "=== VTC Results ==="
echo "Trip point:"
print v_trip

.endc

* =============================================================================
* PART B: Inverter transient — propagation delay
* =============================================================================

.alter
.param vdd_val = 0.75

vin  in  0  pulse(0 vdd_val 50p 5p 5p 95p 200p)

xp1  out in  vdd vdd pfet_5nm
xn1  out in  vss vss nfet_5nm

* Load: FO1 — one inverter gate load (~0.05 fF Cg per fin × 2 fins = ~0.1 fF)
* Plus wire load ~0.05 fF (short M2 wire)
cload out 0 0.15f

.tran 0.5p 400p

.control
run
plot v(in) v(out) title 'N5 ngspice-native Inverter Transient (0.75V)' ylabel 'V [V]' xlabel 'Time [s]'

meas tran tphl trig v(in) val='vdd_val/2' rise=1 targ v(out) val='vdd_val/2' fall=1
meas tran tplh trig v(in) val='vdd_val/2' fall=1 targ v(out) val='vdd_val/2' rise=1

echo "=== Propagation Delay ==="
print tphl tplh

.endc

.end
