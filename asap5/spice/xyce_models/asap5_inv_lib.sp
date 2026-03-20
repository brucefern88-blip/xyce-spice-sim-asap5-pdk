* =============================================================================
* asap5_inv_lib.sp — ASAP5 Inverter Subcircuits with M Multiplier Support
* =============================================================================
* Xyce BSIM-CMG does not support M= instance parameter.
* M (multiplier) is implemented as M parallel device instances,
* each with nfin_base=2 (ASAP5 minimum).
*
* Weff = M × nfin × (2 × Hfin + Wfin)
*      = M × 2 × (2 × 32nm + 8nm) = M × 144nm
*
* Cells:
*   INVx1  — M=1, nfin=2 (1 NMOS + 1 PMOS)
*   INVx2  — M=2, nfin=2 (2 parallel NMOS + 2 parallel PMOS)
*   INVx4  — M=4, nfin=2 (4 parallel NMOS + 4 parallel PMOS)
*
* Usage:
*   xinv in out vdd vss INVx1
*   xinv in out vdd vss INVx2
* =============================================================================

* --- INVx1: M=1, nfin=2 ---
.subckt INVx1 A Y VDD VSS
mn1 Y A VSS VSS nmos_slvt l=16n nfin=2
mp1 Y A VDD VDD pmos_slvt l=16n nfin=2
.ends INVx1

* --- INVx2: M=2, nfin=2 (2 parallel minimum-size devices) ---
.subckt INVx2 A Y VDD VSS
mn1 Y A VSS VSS nmos_slvt l=16n nfin=2
mn2 Y A VSS VSS nmos_slvt l=16n nfin=2
mp1 Y A VDD VDD pmos_slvt l=16n nfin=2
mp2 Y A VDD VDD pmos_slvt l=16n nfin=2
.ends INVx2

* --- INVx2_nfin4: M=1, nfin=4 (equivalent drive, single device) ---
* For comparison: same total Weff as INVx2 but single device
.subckt INVx2_nfin4 A Y VDD VSS
mn1 Y A VSS VSS nmos_slvt l=16n nfin=4
mp1 Y A VDD VDD pmos_slvt l=16n nfin=4
.ends INVx2_nfin4

* --- INVx4: M=4, nfin=2 (4 parallel minimum-size devices) ---
.subckt INVx4 A Y VDD VSS
mn1 Y A VSS VSS nmos_slvt l=16n nfin=2
mn2 Y A VSS VSS nmos_slvt l=16n nfin=2
mn3 Y A VSS VSS nmos_slvt l=16n nfin=2
mn4 Y A VSS VSS nmos_slvt l=16n nfin=2
mp1 Y A VDD VDD pmos_slvt l=16n nfin=2
mp2 Y A VDD VDD pmos_slvt l=16n nfin=2
mp3 Y A VDD VDD pmos_slvt l=16n nfin=2
mp4 Y A VDD VDD pmos_slvt l=16n nfin=2
.ends INVx4
