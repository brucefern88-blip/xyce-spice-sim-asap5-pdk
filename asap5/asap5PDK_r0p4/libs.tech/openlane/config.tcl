# ============================================================================
# ASAP5 PDK — OpenLane2 PDK-level configuration
# Process: 5nm GAA Nanosheet (BSIM-CMG level=72, geomod=3)
# VDD: 0.5V nominal
# ============================================================================

set ::env(STD_CELL_LIBRARY) "asap5_stdcells"

set ::env(VDD_PIN) "VDD"
set ::env(GND_PIN) "VSS"
set ::env(VDD_PIN_VOLTAGE) "0.5"

# Technology LEF — single corner (TT)
set ::env(TECH_LEF) "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/lef/n5_tech.lef"
