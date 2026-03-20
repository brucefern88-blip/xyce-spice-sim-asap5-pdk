* TSMC N5 NMOS FinFET — OSDI BSIM-CMG (vacode110)
* Parameters calibrated for N5 FinFET, single fin

.model nfet_5nm bsimcmg
+ TYPE = 1
+ JTWEFF = 1e-9
+ BULKMOD = 1
+ TFIN = 6.5e-9
+ HFIN = 46e-9
+ FPITCH = 26e-9
+ NBODY = 1e23
+ NSD = 2e26
+ PHIG = 4.55
+ U0 = 0.030
+ UA = 0.4
+ EU = 1.2
+ ETAMOB = 2.0
+ VSAT = 1.1e5
+ DELTAVSAT = 0.7
+ KSATIV = 1.0
+ EOT = 8.25e-9
+ EPSROX = 12.0
+ CGSO = 3.6e-12
+ CGDO = 3.6e-12
+ CJS = 4.4e-4
+ CJD = 4.4e-4
+ PBS = 0.95
+ PBD = 0.95
+ RDSW = 150
+ SHMOD = 0
+ TNOM = 25
