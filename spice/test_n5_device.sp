* =============================================================================
* test_n5_device.sp — TSMC N5 FinFET BSIM-CMG Device Characterization
* =============================================================================
*
* Validates NMOS/PMOS models against targets from hamming_distance_64_n5_floorplan.v:
*   NMOS: Id_on ~65uA @0.75V, ~8uA @0.40V, Id_off ~15nA
*   PMOS: Id_on ~47uA @0.75V, ~5uA @0.40V, Id_off ~10nA
*   Cg ~0.05fF, Cd ~0.02fF, Cs ~0.02fF  (per fin)
*
* Run:  ngspice test_n5_device.sp
* =============================================================================

.lib 'tsmc_n5_bsimcmg.lib' tt

.param vdd = 0.75

* =============================================================================
* TEST 1: NMOS Id-Vgs sweep (Vds=VDD, single fin)
* =============================================================================
.subckt nmos_idvgs
vgs  gate  0  dc 0
vds  drain 0  dc vdd
mn1  drain gate 0 0 nfet_5nm nfin=1
.ends

xn1 nmos_idvgs

.dc vgs 0 0.75 0.005
.print dc i(xn1.vds)

* =============================================================================
* TEST 2: NMOS Id-Vgs at ULV (Vds=0.40V)
* =============================================================================
.alter
.param vdd = 0.40
.dc vgs 0 0.40 0.005

* =============================================================================
* TEST 3: NMOS Id-Vds family (Vgs=0.2..0.75V)
* =============================================================================
.alter
.param vdd = 0.75

.subckt nmos_idvds
vgs  gate  0  dc 0.75
vds  drain 0  dc 0
mn1  drain gate 0 0 nfet_5nm nfin=1
.ends

xn2 nmos_idvds

.dc vds 0 0.75 0.005 vgs 0.2 0.75 0.1
.print dc i(xn2.vds)

.end
