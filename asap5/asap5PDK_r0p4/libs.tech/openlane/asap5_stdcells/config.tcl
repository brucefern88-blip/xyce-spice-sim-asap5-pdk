# ============================================================================
# ASAP5 Standard Cell Library — OpenLane2 SCL-level configuration
# Corner: TT / 0.5V / 25C
# Cells: 12 basic + 9 utility (FILL, TAP, TIE, ENDCAP, DECAP)
# ============================================================================

# === Liberty timing — single corner ===
set ::env(LIB_SYNTH) "/Users/bruce/CLAUDE/asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib"
set ::env(LIB_SLOWEST) "/Users/bruce/CLAUDE/asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib"
set ::env(LIB_FASTEST) "/Users/bruce/CLAUDE/asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib"
set ::env(LIB_TYPICAL) "/Users/bruce/CLAUDE/asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib"

# === Cell LEF ===
set ::env(CELL_LEFS) "/Users/bruce/CLAUDE/asap5/stdcells/lef/asap5_stdcells.lef /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/lef/n5_utility_cells.lef"

# === Behavioral Verilog ===
set ::env(CELL_VERILOG_MODELS) "/Users/bruce/CLAUDE/asap5/stdcells/verilog/asap5_stdcells.v /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/verilog/n5_utility_cells.v"

# === CDL for LVS ===
set ::env(CELL_SPICE_MODELS) "/Users/bruce/CLAUDE/asap5/stdcells/gds/asap5_stdcells.cdl /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/cdl/n5_utility_cells.cdl"

# === GDS ===
set ::env(CELL_GDS) "/Users/bruce/CLAUDE/asap5/stdcells/gds/asap5_stdcells.gds"

# === Power/Ground pins ===
set ::env(SCL_POWER_PINS) "VDD"
set ::env(SCL_GROUND_PINS) "VSS"

# === Placement ===
set ::env(PLACE_SITE) "asap5_site"
set ::env(GPL_CELL_PADDING) "0"
set ::env(DPL_CELL_PADDING) "0"
set ::env(CELL_PAD_EXCLUDE) ""

# === Fill / Tap / Endcap / Decap ===
set ::env(FILL_CELL) "FILLx1"
set ::env(FP_WELLTAP_CELL) "TAPx1"
set ::env(FP_ENDCAP_CELL) "ENDCAP_L"
set ::env(DECAP_CELL) "DECAPx2"
set ::env(FP_TAPCELL_DIST) "5"

# === Tie cells (pdk_compat splits on space then joins with /) ===
# Format: "CELL PORT" → pdk_compat → "CELL/PORT"
set ::env(SYNTH_TIEHI_PORT) "TIE_HI Y"
set ::env(SYNTH_TIELO_PORT) "TIE_LO Y"

# === Driving / Buffer cells ===
# pdk_compat: SYNTH_DRIVING_CELL + PIN → "CELL/PIN"
set ::env(SYNTH_DRIVING_CELL) "INVx2"
set ::env(SYNTH_DRIVING_CELL_PIN) "Y"
# pdk_compat: SYNTH_MIN_BUF_PORT "CELL IN OUT" → "CELL/IN/OUT"
set ::env(SYNTH_MIN_BUF_PORT) "BUFx1 A Y"
set ::env(OUTPUT_CAP_LOAD) "1.0"

# === Synthesis exclusions ===
set ::env(SYNTH_EXCLUDED_CELL_FILE) "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/dummy/excluded_cells.txt"
set ::env(PNR_EXCLUDED_CELL_FILE) "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/dummy/excluded_cells.txt"

# === CTS (disabled for combinational, but vars still needed) ===
set ::env(CTS_ROOT_BUFFER) "INVx4"
set ::env(CTS_CLK_BUFFERS) "INVx1 INVx2 INVx4"

# === Routing layers ===
set ::env(RT_MIN_LAYER) "M1"
set ::env(RT_MAX_LAYER) "M10"
set ::env(FP_IO_HLAYER) "M3"
set ::env(FP_IO_VLAYER) "M4"

# === PDN (Power Distribution Network) ===
set ::env(FP_PDN_RAIL_LAYER) "M1"
set ::env(FP_PDN_RAIL_WIDTH) "0.014"
set ::env(FP_PDN_RAIL_OFFSET) "0"
set ::env(FP_PDN_HORIZONTAL_LAYER) "M5"
set ::env(FP_PDN_VERTICAL_LAYER) "M6"
set ::env(FP_PDN_HWIDTH) "0.020"
set ::env(FP_PDN_VWIDTH) "0.020"
set ::env(FP_PDN_HSPACING) "0.500"
set ::env(FP_PDN_VSPACING) "0.500"
set ::env(FP_PDN_HPITCH) "2.000"
set ::env(FP_PDN_VPITCH) "2.000"
set ::env(FP_PDN_HOFFSET) "0.500"
set ::env(FP_PDN_VOFFSET) "0.500"
set ::env(FP_PDN_CORE_RING_HWIDTH) "0.040"
set ::env(FP_PDN_CORE_RING_VWIDTH) "0.040"
set ::env(FP_PDN_CORE_RING_HSPACING) "0.040"
set ::env(FP_PDN_CORE_RING_VSPACING) "0.040"
set ::env(FP_PDN_CORE_RING_HOFFSET) "0.200"
set ::env(FP_PDN_CORE_RING_VOFFSET) "0.200"

# === Routing layer adjustments (reduction factors, 0-1) ===
set ::env(GRT_LAYER_ADJUSTMENTS) "0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5"

# === Antenna ===
set ::env(HEURISTIC_ANTENNA_THRESHOLD) "90"
set ::env(DIODE_CELL) ""
set ::env(DIODE_CELL_PIN) ""

# === Tracks info ===
set ::env(FP_TRACKS_INFO) "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/tracks/n5_tracks.info"

# === STA corners / timing ===
set ::env(DEFAULT_CORNER) "nom_tt_025C_0v50"
set ::env(STA_CORNERS) "nom_tt_025C_0v50"
set ::env(TIMING_VIOLATION_CORNERS) "nom_tt_025C_0v50"

# === Timing constraints ===
set ::env(CLOCK_UNCERTAINTY_CONSTRAINT) "0.010"
set ::env(CLOCK_TRANSITION_CONSTRAINT) "0.100"
set ::env(TIME_DERATING_CONSTRAINT) "5"
set ::env(IO_DELAY_CONSTRAINT) "20"
set ::env(MAX_FANOUT_CONSTRAINT) "8"

# === RCX / Extraction (disabled steps, but vars needed) ===
set ::env(RCX_RULESETS) ""

# === GDSII streamout tool ===
set ::env(PRIMARY_GDSII_STREAMOUT_TOOL) "magic"

# === Magic (disabled, but vars needed for config validation) ===
set ::env(MAGICRC) "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/dummy/magicrc"
set ::env(MAGIC_TECH) "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/dummy/magic.tech"
set ::env(MAGIC_PDK_SETUP) "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/dummy/magic_pdk_setup.tcl"

# === KLayout (disabled, but vars needed for config validation) ===
set ::env(KLAYOUT_TECH) "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/dummy/klayout.lyt"
set ::env(KLAYOUT_PROPERTIES) "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/dummy/klayout.lyp"
set ::env(KLAYOUT_DEF_LAYER_MAP) "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/dummy/klayout_def_layer_map.map"

# === Netgen LVS (disabled, but vars needed for config validation) ===
set ::env(NETGEN_SETUP) "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/dummy/netgen_setup.tcl"
