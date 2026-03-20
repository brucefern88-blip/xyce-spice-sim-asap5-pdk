* =============================================================================
* test_asap5_inverter.sp — ASAP5 CMOS Inverter (Nanosheet GAA, single sheet)
* =============================================================================
*
* DC VTC sweep and transient propagation delay measurement.
* Tests LVT devices at VDD=0.7V (nominal) and 0.4V (near-threshold).
*
* Run:  ngspice test_asap5_inverter.sp
* =============================================================================

.lib '/Users/bruce/CLAUDE/asap5/spice/asap5_ngspice.lib' tt

.param vdd_val = 0.7

* ── Supply ──
vdd  vdd  0  dc vdd_val
vss  vss  0  dc 0

* =============================================================================
* PART A: Inverter VTC — LVT devices (DC sweep)
* =============================================================================
vin  in  0  dc 0

mp1  out in  vdd vdd pmos_lvt
mn1  out in  vss vss nmos_lvt

.control

* --- VTC at 0.7V ---
dc vin 0 0.7 0.001
plot v(out) vs v(in) title 'ASAP5 LVT Inverter VTC @0.7V' ylabel 'Vout [V]' xlabel 'Vin [V]'
meas dc v_trip find v(in) when v(out)=0.35

echo ""
echo "============================================="
echo "ASAP5 Inverter VTC Summary"
echo "============================================="
echo "VDD = 0.7V"
print v_trip
echo "============================================="

* --- Transient at 0.7V ---
reset
alter vin pulse(0 0.7 50p 5p 5p 95p 200p)

* Load: ~1.1 fF gate + ~0.5 fF wire
* ASAP5 Cgso=0.1088 fF/um * 2 sides * 2 devices ~ comparable to TSMC per-fin
option cload=1.6f

tran 0.5p 400p
plot v(in) v(out) title 'ASAP5 LVT Inverter Transient @0.7V' ylabel 'V [V]' xlabel 'time [s]'

meas tran tphl trig v(in) val=0.35 rise=1 targ v(out) val=0.35 fall=1
meas tran tplh trig v(in) val=0.35 fall=1 targ v(out) val=0.35 rise=1
let tpd = (tphl + tplh) / 2

echo ""
echo "============================================="
echo "ASAP5 Inverter Delay Summary @0.7V"
echo "============================================="
print tphl tplh tpd
echo "============================================="

* --- Transient at 0.4V (near-threshold) ---
reset
alterparam vdd_val = 0.4
alter vin pulse(0 0.4 100p 10p 10p 190p 400p)
alter vdd dc = 0.4

tran 1p 800p
plot v(in) v(out) title 'ASAP5 LVT Inverter Transient @0.4V' ylabel 'V [V]' xlabel 'time [s]'

meas tran tphl_ulv trig v(in) val=0.2 rise=1 targ v(out) val=0.2 fall=1
meas tran tplh_ulv trig v(in) val=0.2 fall=1 targ v(out) val=0.2 rise=1
let tpd_ulv = (tphl_ulv + tplh_ulv) / 2

echo ""
echo "============================================="
echo "ASAP5 Inverter Delay Summary @0.4V"
echo "============================================="
print tphl_ulv tplh_ulv tpd_ulv
echo "============================================="

.endc

* Load capacitor
cload out 0 1.6f

.end
