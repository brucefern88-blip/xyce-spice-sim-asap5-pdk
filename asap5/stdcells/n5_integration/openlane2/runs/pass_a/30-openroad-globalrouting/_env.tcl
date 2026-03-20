set ::env(STEP_ID) OpenROAD.GlobalRouting
set ::env(TECH_LEF) /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/lef/n5_tech.lef
set ::env(MACRO_LEFS) ""
set ::env(STD_CELL_LIBRARY) asap5_stdcells
set ::env(VDD_PIN) VDD
set ::env(VDD_PIN_VOLTAGE) 0.5
set ::env(GND_PIN) VSS
set ::env(TECH_LEFS) "\"nom_*\" /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/lef/n5_tech.lef"
set ::env(PRIMARY_GDSII_STREAMOUT_TOOL) magic
set ::env(DEFAULT_CORNER) nom_tt_025C_0v50
set ::env(STA_CORNERS) nom_tt_025C_0v50
set ::env(FP_TRACKS_INFO) /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/tracks/n5_tracks.info
set ::env(FP_TAPCELL_DIST) 5
set ::env(FP_IO_HLAYER) M3
set ::env(FP_IO_VLAYER) M4
set ::env(RT_MIN_LAYER) M1
set ::env(RT_MAX_LAYER) M10
set ::env(SCL_GROUND_PINS) VSS
set ::env(SCL_POWER_PINS) VDD
set ::env(FILL_CELL) FILLx1
set ::env(DECAP_CELL) DECAPx2
set ::env(LIB) "nom_tt_025C_0v50 \"/Users/bruce/CLAUDE/asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/lib/n5_utility_cells_tt_0p5v_25c.lib\""
set ::env(CELL_LEFS) "/Users/bruce/CLAUDE/asap5/stdcells/lef/asap5_stdcells.lef /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/lef/n5_utility_cells.lef"
set ::env(CELL_GDS) /Users/bruce/CLAUDE/asap5/stdcells/gds/asap5_stdcells.gds
set ::env(CELL_VERILOG_MODELS) "/Users/bruce/CLAUDE/asap5/stdcells/verilog/asap5_stdcells.v /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/verilog/n5_utility_cells.v"
set ::env(CELL_SPICE_MODELS) "/Users/bruce/CLAUDE/asap5/stdcells/gds/asap5_stdcells.cdl /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/cdl/n5_utility_cells.cdl"
set ::env(SYNTH_EXCLUDED_CELL_FILE) /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/dummy/excluded_cells.txt
set ::env(PNR_EXCLUDED_CELL_FILE) /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/dummy/excluded_cells.txt
set ::env(OUTPUT_CAP_LOAD) 1.0
set ::env(MAX_FANOUT_CONSTRAINT) 8
set ::env(CLOCK_UNCERTAINTY_CONSTRAINT) 0.010
set ::env(CLOCK_TRANSITION_CONSTRAINT) 0.100
set ::env(TIME_DERATING_CONSTRAINT) 5
set ::env(IO_DELAY_CONSTRAINT) 20
set ::env(SYNTH_DRIVING_CELL) INVx2/Y
set ::env(SYNTH_TIEHI_CELL) TIE_HI/Y
set ::env(SYNTH_TIELO_CELL) TIE_LO/Y
set ::env(SYNTH_BUFFER_CELL) BUFx1/A/Y
set ::env(WELLTAP_CELL) TAPx1
set ::env(ENDCAP_CELL) ENDCAP_L
set ::env(PLACE_SITE) asap5_site
set ::env(CELL_PAD_EXCLUDE) ""
set ::env(DIODE_CELL) /
set ::env(DESIGN_NAME) hamming_64b_cuboid_r4_xp
set ::env(CLOCK_PERIOD) 10.0
set ::env(CLOCK_PORT) ""
set ::env(DIE_AREA) "0 0 10 10"
set ::env(FALLBACK_SDC_FILE) /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/sdc/hamming_cuboid_r4.sdc
set ::env(PDN_CONNECT_MACROS_TO_GRID) 1
set ::env(PDN_ENABLE_GLOBAL_CONNECTIONS) 1
set ::env(GRT_ADJUSTMENT) 0.299999999999999988897769753748434595763683319091796875
set ::env(GRT_MACRO_EXTENSION) 0
set ::env(GRT_LAYER_ADJUSTMENTS) "0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5"
set ::env(GRT_ALLOW_CONGESTION) 1
set ::env(GRT_ANTENNA_ITERS) 3
set ::env(GRT_OVERFLOW_ITERS) 50
set ::env(GRT_ANTENNA_MARGIN) 10
set ::env(PL_OPTIMIZE_MIRRORING) 1
set ::env(PL_MAX_DISPLACEMENT_X) 500
set ::env(PL_MAX_DISPLACEMENT_Y) 100
set ::env(DPL_CELL_PADDING) 0
set ::env(CURRENT_ODB) /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/openlane2/runs/pass_a/27-openroad-detailedplacement/hamming_64b_cuboid_r4_xp.odb
set ::env(SAVE_ODB) /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/openlane2/runs/pass_a/30-openroad-globalrouting/hamming_64b_cuboid_r4_xp.odb
set ::env(SAVE_DEF) /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/openlane2/runs/pass_a/30-openroad-globalrouting/hamming_64b_cuboid_r4_xp.def
