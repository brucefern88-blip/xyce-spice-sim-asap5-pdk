* =============================================================================
* test_n5_caps.sp — Extract Cg, Cd, Cs from BSIM-CMG model
* =============================================================================
*
* Targets (per fin, LVT):
*   Cg  ~ 0.05 fF    Cd  ~ 0.02 fF    Cs  ~ 0.02 fF
*
* Method: AC small-signal analysis, measure Ig/omega at Vgs=VDD/2.
*
* Run:  ngspice test_n5_caps.sp
* =============================================================================

.lib 'tsmc_n5_bsimcmg.lib' tt

.param vdd = 0.75

* =============================================================================
* Cgg extraction: ground S,D,B; apply AC to gate
* =============================================================================
vgs  gate   0  dc 0.375  ac 1
mn1  0 gate 0 0 nfet_5nm nfin=1

.ac dec 10 1e6 1e12
.print ac i(vgs)

* Cg = Im(Ig) / (2*pi*f)
* At f=1GHz: Cg = Im(Ig)/(2*pi*1e9)
* Expected: ~0.05e-15 F

* =============================================================================
* Cgd extraction: S=B=0, D=AC, gate biased
* =============================================================================

.alter

vgs  gate   0  dc 0.375
vds  drain  0  dc 0.375  ac 1
mn2  drain gate 0 0 nfet_5nm nfin=1

.ac dec 10 1e6 1e12
.print ac i(vds)

* =============================================================================
* PMOS Cgg extraction
* =============================================================================

.alter

vgs  gate   0  dc -0.375  ac 1
mp1  0 gate 0 0 pfet_5nm nfin=1

.ac dec 10 1e6 1e12
.print ac i(vgs)

.end
