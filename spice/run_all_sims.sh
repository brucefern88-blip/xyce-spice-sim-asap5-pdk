#!/bin/bash
# Run all BSIM-CMG FinFET simulations and generate PDF
NGSPICE=$HOME/local/ngspice/bin/ngspice
SPDIR=/Users/bruce/CLAUDE/spice
OSDI=/tmp/bsimcmg.osdi

echo "=== Running NMOS Id-Vgs ==="
$NGSPICE -b $SPDIR/sim_nmos_idvgs.sp 2>&1 | grep -E "Error|abort|No\. of"
echo "=== Running NMOS Id-Vds ==="
$NGSPICE -b $SPDIR/sim_nmos_idvds.sp 2>&1 | grep -E "Error|abort|No\. of"
echo "=== Running PMOS Id-Vgs ==="
$NGSPICE -b $SPDIR/sim_pmos_idvgs.sp 2>&1 | grep -E "Error|abort|No\. of"
echo "=== Running PMOS Id-Vds ==="
$NGSPICE -b $SPDIR/sim_pmos_idvds.sp 2>&1 | grep -E "Error|abort|No\. of"
echo "=== Running NMOS Caps ==="
$NGSPICE -b $SPDIR/sim_nmos_caps.sp 2>&1 | grep -E "Error|abort|No\. of"
echo "=== Running PMOS Caps ==="
$NGSPICE -b $SPDIR/sim_pmos_caps.sp 2>&1 | grep -E "Error|abort|No\. of"
echo "=== Done ==="
ls -la /tmp/sim_*.dat 2>/dev/null
