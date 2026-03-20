* ===========================================================================
* Characterization Testbench — Fused Hamming Cells A, E, F, G
* VDD=0.5V, T=25C, 50ps input slew, 1fF output load
* 16 input vectors (0000..1111), 1ns per vector, 16ns total
* ===========================================================================

.include ../asap5_models.sp
.include fused_cell_A.sp
.include fused_cell_E.sp
.include fused_cell_F.sp
.include fused_cell_G.sp

.temp 25

* ===========================================================================
* Supply rails — separate ammeter per variant for per-variant current
* ===========================================================================
Vvdd  vdd_top 0 DC 0.5

* Ammeters: 0V sources in series to measure per-variant current
* Convention: i(Vam_x) > 0 means current flows from supply into circuit
Vam_a vdd_top vdd_a DC 0
Vam_e vdd_top vdd_e DC 0
Vam_f vdd_top vdd_f DC 0
Vam_g vdd_top vdd_g DC 0

* ===========================================================================
* Input stimulus: cycle through all 16 vectors (ai,bi,aj,bj) = 0000..1111
* Each vector held for 1ns with 50ps rise/fall transitions
* Vector encoding: ai=bit3, bi=bit2, aj=bit1, bj=bit0
*
* Vec   ai bi aj bj   d0=ai^bi  d1=aj^bj  hd  OH0 OH1 OH2
*  0:    0  0  0  0     0         0        0    1   0   0
*  1:    0  0  0  1     0         1        1    0   1   0
*  2:    0  0  1  0     0         1        1    0   1   0
*  3:    0  0  1  1     0         0        0    1   0   0
*  4:    0  1  0  0     1         0        1    0   1   0
*  5:    0  1  0  1     1         1        2    0   0   1
*  6:    0  1  1  0     1         1        2    0   0   1
*  7:    0  1  1  1     1         0        1    0   1   0
*  8:    1  0  0  0     1         0        1    0   1   0
*  9:    1  0  0  1     1         1        2    0   0   1
* 10:    1  0  1  0     1         1        2    0   0   1
* 11:    1  0  1  1     1         0        1    0   1   0
* 12:    1  1  0  0     0         0        0    1   0   0
* 13:    1  1  0  1     0         1        1    0   1   0
* 14:    1  1  1  0     0         1        1    0   1   0
* 15:    1  1  1  1     0         0        0    1   0   0
* ===========================================================================

* bj = bit 0: toggles every 1ns
Vbj bj 0 PWL(
+ 0.0n 0.0
+ 1.0n 0.0   1.05n 0.5
+ 2.0n 0.5   2.05n 0.0
+ 3.0n 0.0   3.05n 0.5
+ 4.0n 0.5   4.05n 0.0
+ 5.0n 0.0   5.05n 0.5
+ 6.0n 0.5   6.05n 0.0
+ 7.0n 0.0   7.05n 0.5
+ 8.0n 0.5   8.05n 0.0
+ 9.0n 0.0   9.05n 0.5
+ 10.0n 0.5  10.05n 0.0
+ 11.0n 0.0  11.05n 0.5
+ 12.0n 0.5  12.05n 0.0
+ 13.0n 0.0  13.05n 0.5
+ 14.0n 0.5  14.05n 0.0
+ 15.0n 0.0  15.05n 0.5
+ 16.0n 0.5 )

* aj = bit 1: toggles every 2ns
Vaj aj 0 PWL(
+ 0.0n 0.0
+ 2.0n 0.0   2.05n 0.5
+ 4.0n 0.5   4.05n 0.0
+ 6.0n 0.0   6.05n 0.5
+ 8.0n 0.5   8.05n 0.0
+ 10.0n 0.0  10.05n 0.5
+ 12.0n 0.5  12.05n 0.0
+ 14.0n 0.0  14.05n 0.5
+ 16.0n 0.5 )

* bi = bit 2: toggles every 4ns
Vbi bi 0 PWL(
+ 0.0n 0.0
+ 4.0n 0.0   4.05n 0.5
+ 8.0n 0.5   8.05n 0.0
+ 12.0n 0.0  12.05n 0.5
+ 16.0n 0.5 )

* ai = bit 3: toggles every 8ns
Vai ai 0 PWL(
+ 0.0n 0.0
+ 8.0n 0.0   8.05n 0.5
+ 16.0n 0.5 )

* ===========================================================================
* DUT instantiations — each variant gets its own VDD ammeter node
* ===========================================================================

* --- Variant A (48T): oh0, oh1, oh2 ---
Xa ai bi aj bj a_oh0 a_oh1 a_oh2 vdd_a 0 FUSED_A
Ca0 a_oh0 0 1f
Ca1 a_oh1 0 1f
Ca2 a_oh2 0 1f

* --- Variant E (38T): oh0, oh1, oh2 ---
Xe ai bi aj bj e_oh0 e_oh1 e_oh2 vdd_e 0 FUSED_E
Ce0 e_oh0 0 1f
Ce1 e_oh1 0 1f
Ce2 e_oh2 0 1f

* --- Variant F (42T): oh1, oh2 (no oh0) ---
Xf ai bi aj bj f_oh1 f_oh2 vdd_f 0 FUSED_F
Cf1 f_oh1 0 1f
Cf2 f_oh2 0 1f

* --- Variant G (40T): noh1, noh2 (active-low, no oh0) ---
Xg ai bi aj bj g_noh1 g_noh2 vdd_g 0 FUSED_G
Cg1 g_noh1 0 1f
Cg2 g_noh2 0 1f

* ===========================================================================
* Analysis — 5ps max timestep for good accuracy on 50ps slews
* ===========================================================================
.tran 5p 16.5n UIC

* ===========================================================================
* Per-variant average current (over active simulation)
* ===========================================================================
.meas tran ia_avg AVG i(Vam_a) FROM=0.2n TO=16.0n
.meas tran ie_avg AVG i(Vam_e) FROM=0.2n TO=16.0n
.meas tran if_avg AVG i(Vam_f) FROM=0.2n TO=16.0n
.meas tran ig_avg AVG i(Vam_g) FROM=0.2n TO=16.0n

* ===========================================================================
* Leakage current — vector 0000 (0.2ns to 0.9ns, after settling)
* ===========================================================================
.meas tran ia_leak AVG i(Vam_a) FROM=0.3n TO=0.9n
.meas tran ie_leak AVG i(Vam_e) FROM=0.3n TO=0.9n
.meas tran if_leak AVG i(Vam_f) FROM=0.3n TO=0.9n
.meas tran ig_leak AVG i(Vam_g) FROM=0.3n TO=0.9n

* ===========================================================================
* Propagation delay measurements (50% VDD = 0.25V threshold)
*
* Transition @t=1ns: bj rises, vec 0->1 (0000->0001)
*   hd: 0->1.  OH0 falls, OH1 rises, OH2 stays low
*   For A,E: OH0 FALL=1, OH1 RISE=1
*   For E: OH1=NOR2(OH0,OH2), depends on OH0/OH2
*   For G: nOH1 FALL=1 (goes active)
*
* Transition @t=4ns: bi rises, vec 3->4 (0011->0100)
*   hd: 0->1.  OH0 falls(2nd time), OH1 rises
*
* Transition @t=5ns: bj rises, vec 4->5 (0100->0101)
*   hd: 1->2.  OH1 falls, OH2 rises
* ===========================================================================

* --- Variant A ---
* OH1 sequence: L,H,H,L,H,L,L,H,H,L,L,H,L,H,H,L
*   Rise edges: @1n(1), @4n(2), @7n(3), @8n(4), @11n(5), @13n(6), @14n(7)
*   Fall edges: @3n(1), @5n(2), @7n... wait, let me be precise:
*   transitions: 0->1(r1 @1n), 2->3(f1 @3n), 3->4(r2 @4n), 4->5(f2 @5n),
*                5->6(stays L), 6->7(r3 @7n), 7->8(stays H), 8->9(f3 @9n)...
*
* OH2 sequence: L,L,L,L,L,H,H,L,L,H,H,L,H,L,L,L
*   Rise edges: @5n(1), @9n(2), @12n(3)
*   Fall edges: @7n(1), @11n(2), @13n(3)
*
* OH0 sequence: H,L,L,H,L,L,L,L,L,L,L,L,H,L,L,H
*   Fall edges: @1n(1), @4n(2), @13n(3)
*   Rise edges: @3n(1), @12n(2), @15n(3)

* bj@1n: 0000->0001, hd 0->1: OH0 falls(1), OH1 rises(1)
.meas tran tpd_a_oh0_f_bj TRIG v(bj) VAL=0.25 RISE=1
+                          TARG v(a_oh0) VAL=0.25 FALL=1

.meas tran tpd_a_oh1_r_bj TRIG v(bj) VAL=0.25 RISE=1
+                          TARG v(a_oh1) VAL=0.25 RISE=1

* bi@4n: 0011->0100, hd 0->1: OH1 rises(2)
.meas tran tpd_a_oh1_r_bi TRIG v(bi) VAL=0.25 RISE=1
+                          TARG v(a_oh1) VAL=0.25 RISE=2

* bj@5n (RISE=3): 0100->0101, hd 1->2: OH1 falls(2), OH2 rises(1)
.meas tran tpd_a_oh2_r_bj TRIG v(bj) VAL=0.25 RISE=3
+                          TARG v(a_oh2) VAL=0.25 RISE=1

.meas tran tpd_a_oh1_f_bj TRIG v(bj) VAL=0.25 RISE=3
+                          TARG v(a_oh1) VAL=0.25 FALL=2

* --- Variant E ---
* E's OH1 = NOR2(OH0, OH2), so it depends on OH0/OH2 settling.
* OH1 sequence same as A: L,H,H,L,H,L,L,H,H,L,L,H,L,H,H,L
* But edge numbering may differ due to startup glitch with UIC.
* Use bi@4n transition for reliable measurement.

.meas tran tpd_e_oh0_f_bj TRIG v(bj) VAL=0.25 RISE=1
+                          TARG v(e_oh0) VAL=0.25 FALL=1

* bi@4n: 0011->0100, hd 0->1: OH1 rises. Need correct edge number.
* E OH1 may have a startup glitch giving an extra rise near t=0.
* Use TD=3.5n to start searching after t=3.5n
.meas tran tpd_e_oh1_r_bi TRIG v(bi) VAL=0.25 TD=3.5n RISE=1
+                          TARG v(e_oh1) VAL=0.25 TD=3.5n RISE=1

* bj@5n: 0100->0101, hd 1->2: OH2 rises(1)
.meas tran tpd_e_oh2_r_bj TRIG v(bj) VAL=0.25 RISE=3
+                          TARG v(e_oh2) VAL=0.25 RISE=1

* bj@7n (RISE=4): 0110->0111, hd 2->1: OH1 rises.
* Use TD=6.5n to skip past startup issues
.meas tran tpd_e_oh1_r_bj TRIG v(bj) VAL=0.25 TD=6.5n RISE=1
+                          TARG v(e_oh1) VAL=0.25 TD=6.5n RISE=1

* --- Variant F (oh1, oh2 only) ---
* bj@1n: 0000->0001, hd 0->1: OH1 rises(1)
.meas tran tpd_f_oh1_r_bj TRIG v(bj) VAL=0.25 RISE=1
+                          TARG v(f_oh1) VAL=0.25 RISE=1

* bi@4n: 0011->0100, hd 0->1: OH1 rises(2)
.meas tran tpd_f_oh1_r_bi TRIG v(bi) VAL=0.25 RISE=1
+                          TARG v(f_oh1) VAL=0.25 RISE=2

* bj@5n (RISE=3): 0100->0101, hd 1->2: OH2 rises(1), OH1 falls(2)
.meas tran tpd_f_oh2_r_bj TRIG v(bj) VAL=0.25 RISE=3
+                          TARG v(f_oh2) VAL=0.25 RISE=1

.meas tran tpd_f_oh1_f_bj TRIG v(bj) VAL=0.25 RISE=3
+                          TARG v(f_oh1) VAL=0.25 FALL=2

* --- Variant G (active-low: noh1, noh2) ---
* nOH1 sequence (active-low of OH1): H,L,L,H,L,H,H,L,L,H,H,L,H,L,L,H
*   Fall edges: @1n(1), @4n(2), @7n(3)...
*   Rise edges: @3n(1), @5n(2), @7n... same as OH1 inverted
*
* nOH2 sequence (active-low of OH2): H,H,H,H,H,L,L,H,H,L,L,H,L,H,H,H
*   Fall edges: @5n(1), @9n(2), @12n(3)
*   Rise edges: @7n(1), @11n(2), @13n(3)

* bj@1n: 0000->0001, hd 0->1: nOH1 falls(1)
.meas tran tpd_g_noh1_f_bj TRIG v(bj) VAL=0.25 RISE=1
+                           TARG v(g_noh1) VAL=0.25 FALL=1

* bi@4n: 0011->0100, hd 0->1: nOH1 falls(2)
.meas tran tpd_g_noh1_f_bi TRIG v(bi) VAL=0.25 RISE=1
+                           TARG v(g_noh1) VAL=0.25 FALL=2

* bj@5n (RISE=3): 0100->0101, hd 1->2: nOH2 falls(1), nOH1 rises(2)
.meas tran tpd_g_noh2_f_bj TRIG v(bj) VAL=0.25 RISE=3
+                           TARG v(g_noh2) VAL=0.25 FALL=1

* Use TD=4.5n to skip past startup and earlier transitions
.meas tran tpd_g_noh1_r_bj TRIG v(bj) VAL=0.25 TD=4.5n RISE=1
+                           TARG v(g_noh1) VAL=0.25 TD=4.5n RISE=1

* ===========================================================================
* Output transition times (10%-90% of VDD = 0.05V to 0.45V)
* Use the first clean rise/fall after initial settling
* ===========================================================================
.meas tran trise_a_oh1 TRIG v(a_oh1) VAL=0.05 RISE=1
+                      TARG v(a_oh1) VAL=0.45 RISE=1

.meas tran trise_e_oh1 TRIG v(e_oh1) VAL=0.05 RISE=1
+                      TARG v(e_oh1) VAL=0.45 RISE=1

.meas tran trise_f_oh1 TRIG v(f_oh1) VAL=0.05 RISE=1
+                      TARG v(f_oh1) VAL=0.45 RISE=1

.meas tran tfall_g_noh1 TRIG v(g_noh1) VAL=0.45 FALL=1
+                       TARG v(g_noh1) VAL=0.05 FALL=1

* ===========================================================================
* Energy: integrate supply current * dt for each variant (gives charge Q)
* Energy = Q * VDD (computed in Python)
* ===========================================================================
.meas tran qa_total INTEG i(Vam_a) FROM=0.2n TO=16.0n
.meas tran qe_total INTEG i(Vam_e) FROM=0.2n TO=16.0n
.meas tran qf_total INTEG i(Vam_f) FROM=0.2n TO=16.0n
.meas tran qg_total INTEG i(Vam_g) FROM=0.2n TO=16.0n

* Leakage charge in 0.6ns window
.meas tran qa_leak_q INTEG i(Vam_a) FROM=0.3n TO=0.9n
.meas tran qe_leak_q INTEG i(Vam_e) FROM=0.3n TO=0.9n
.meas tran qf_leak_q INTEG i(Vam_f) FROM=0.3n TO=0.9n
.meas tran qg_leak_q INTEG i(Vam_g) FROM=0.3n TO=0.9n

* ===========================================================================
* Sanity check — output values at key time points
* ===========================================================================
* Vec 0 (0000, hd=0): OH0=H, OH1=L, OH2=L
.meas tran a_oh0_v0 FIND v(a_oh0) AT=0.9n
.meas tran a_oh1_v0 FIND v(a_oh1) AT=0.9n
.meas tran a_oh2_v0 FIND v(a_oh2) AT=0.9n

* Vec 1 (0001, hd=1): OH0=L, OH1=H, OH2=L
.meas tran a_oh0_v1 FIND v(a_oh0) AT=1.9n
.meas tran a_oh1_v1 FIND v(a_oh1) AT=1.9n
.meas tran a_oh2_v1 FIND v(a_oh2) AT=1.9n

* Vec 5 (0101, hd=2): OH0=L, OH1=L, OH2=H
.meas tran a_oh0_v5 FIND v(a_oh0) AT=5.9n
.meas tran a_oh1_v5 FIND v(a_oh1) AT=5.9n
.meas tran a_oh2_v5 FIND v(a_oh2) AT=5.9n

* Variant E sanity
.meas tran e_oh0_v0 FIND v(e_oh0) AT=0.9n
.meas tran e_oh1_v0 FIND v(e_oh1) AT=0.9n
.meas tran e_oh1_v1 FIND v(e_oh1) AT=1.9n
.meas tran e_oh2_v5 FIND v(e_oh2) AT=5.9n

* Variant F sanity
.meas tran f_oh1_v1 FIND v(f_oh1) AT=1.9n
.meas tran f_oh2_v5 FIND v(f_oh2) AT=5.9n

* Variant G sanity (active-low)
.meas tran g_noh1_v0 FIND v(g_noh1) AT=0.9n
.meas tran g_noh1_v1 FIND v(g_noh1) AT=1.9n
.meas tran g_noh2_v1 FIND v(g_noh2) AT=1.9n
.meas tran g_noh2_v5 FIND v(g_noh2) AT=5.9n

.control
run
.endc

.end
