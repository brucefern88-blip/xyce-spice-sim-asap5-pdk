* =============================================================================
* test_n5_inverter.sp — CMOS Inverter (TSMC N5 FinFET, single fin)
* =============================================================================
*
* Transient simulation: ring oscillator style, measures propagation delay.
* Also runs DC sweep for VTC (voltage transfer characteristic).
*
* Run:  ngspice test_n5_inverter.sp
* =============================================================================

.lib 'tsmc_n5_bsimcmg.lib' tt

.param vdd_val = 0.75

* ── Supply ──
vdd  vdd  0  dc vdd_val
vss  vss  0  dc 0

* =============================================================================
* PART A: Inverter VTC (DC sweep)
* =============================================================================

* Single-fin inverter: 1 NMOS fin + 1 PMOS fin
vin  in  0  dc 0

mp1  out in  vdd vdd pfet_5nm nfin=1
mn1  out in  vss vss nfet_5nm nfin=1

.dc vin 0 0.75 0.001
.print dc v(out)
.meas dc v_trip find v(in) when v(out)=0.375
.meas dc v_oh   find v(out) at=0.0
.meas dc v_ol   find v(out) at=0.75

* =============================================================================
* PART B: Inverter transient — propagation delay
* =============================================================================

.alter
.param vdd_val = 0.75

* Input pulse: 0→VDD, 10ps rise/fall, 200ps period
vin  in  0  pulse(0 vdd_val 50p 5p 5p 95p 200p)

* Inverter under test
mp1  out in  vdd vdd pfet_5nm nfin=1
mn1  out in  vss vss nfet_5nm nfin=1

* Load: FO1 — one inverter gate load (~0.05 fF Cg per fin × 2 fins = ~0.1 fF)
* Plus wire load ~0.05 fF (short M2 wire)
cload out 0 0.15f

.tran 0.5p 400p

.print tran v(in) v(out)

* Measure propagation delays
.meas tran tphl trig v(in)  val='vdd_val/2' rise=1
+                    targ v(out) val='vdd_val/2' fall=1
.meas tran tplh trig v(in)  val='vdd_val/2' fall=1
+                    targ v(out) val='vdd_val/2' rise=1
.meas tran tpd  param='(tphl+tplh)/2'

* =============================================================================
* PART C: Inverter at 0.40V (near-threshold)
* =============================================================================

.alter
.param vdd_val = 0.40

vin  in  0  pulse(0 vdd_val 100p 10p 10p 190p 400p)

mp1  out in  vdd vdd pfet_5nm nfin=1
mn1  out in  vss vss nfet_5nm nfin=1

cload out 0 0.15f

.tran 1p 800p

.print tran v(in) v(out)

.meas tran tphl_ulv trig v(in)  val='vdd_val/2' rise=1
+                       targ v(out) val='vdd_val/2' fall=1
.meas tran tplh_ulv trig v(in)  val='vdd_val/2' fall=1
+                       targ v(out) val='vdd_val/2' rise=1
.meas tran tpd_ulv  param='(tphl_ulv+tplh_ulv)/2'

.end
