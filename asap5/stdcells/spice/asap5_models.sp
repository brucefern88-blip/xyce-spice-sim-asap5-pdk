* =============================================================================
* ASAP5 BSIM4-calibrated models for Liberty characterization
* TT corner, VDD=0.5V, T=25C (near-threshold)
* =============================================================================
* Calibrated to ASAP5 LVT GAA nanosheet targets at VDD=0.5V:
*   NMOS: Vt~0.25V, overdrive~0.25V, Ion~15uA/sheet @0.5V
*   PMOS: |Vt|~0.27V, overdrive~0.23V, Ion~10uA/sheet @0.5V
* =============================================================================

.param vdd_val = 0.5
.param temp_val = 25

* NMOS LVT — calibrated for near-threshold at 0.5V
* Ion = Kp/2 * (W/L) * (Vgs-Vt)^2 => Kp = 2*15u/(2*0.25^2) = 240u
.model nmos_lvt nmos level=1 vto=0.25 kp=240u
+ lambda=0.08 tox=1.0n cgso=6.9e-11 cgdo=6.9e-11
+ cbd=0.02f cbs=0.02f

* PMOS LVT
* Ion = Kp/2 * (W/L) * (Vgs-Vt)^2 => Kp = 2*10u/(2*0.23^2) = 189u
.model pmos_lvt pmos level=1 vto=-0.27 kp=189u
+ lambda=0.08 tox=1.0n cgso=6.9e-11 cgdo=6.9e-11
+ cbd=0.02f cbs=0.02f
