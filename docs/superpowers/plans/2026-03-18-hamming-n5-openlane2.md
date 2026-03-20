# Hamming N5 OpenLane2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run full RTL-to-GDSII OpenLane2 flow for hamming_64b_cuboid_r4 on ASAP5/N5 PDK with two-pass synthesis comparison (structure-preserving vs Yosys-optimized).

**Architecture:** Create an OpenLane2-compatible PDK wrapper around ASAP5, extending the metal stack to 12 layers with TSMC N5 RC calibration. The design is purely combinational (no clock/CTS needed). Synthesis maps Verilog primitives to ASAP5 standard cells (12 basic cells). Two passes: Pass A preserves the hand-crafted crosspoint topology, Pass B lets Yosys freely optimize. Compare PPA after both complete.

**Tech Stack:** OpenLane2 v2.3.10 (Nix), Yosys 0.63, OpenROAD (via Nix devshell), ASAP5 5nm GAA PDK, ngspice (characterization)

---

## File Structure

### Files Already Created (by prior session)

| File | Purpose |
|------|---------|
| `asap5/stdcells/n5_integration/lef/n5_tech.lef` | 12-metal tech LEF with N5 RC |
| `asap5/stdcells/n5_integration/lef/n5_utility_cells.lef` | FILL/TAP/TIE/ENDCAP/DECAP LEF macros |
| `asap5/stdcells/n5_integration/lib/n5_utility_cells_tt_0p5v_25c.lib` | Liberty for utility cells |
| `asap5/stdcells/n5_integration/verilog/n5_utility_cells.v` | Behavioral Verilog for utility cells |
| `asap5/stdcells/n5_integration/cdl/n5_utility_cells.cdl` | CDL for LVS |
| `asap5/stdcells/n5_integration/sdc/hamming_cuboid_r4.sdc` | Combinational SDC |
| `asap5/stdcells/n5_integration/openlane2/config_pass_a.json` | Pass A config (structure-preserving) |
| `asap5/stdcells/n5_integration/openlane2/config_pass_b.json` | Pass B config (Yosys-optimized) |
| `asap5/stdcells/lef/asap5_tech.lef` | Updated original tech LEF (12 metals) |

### Files to Create in This Plan

| File | Purpose |
|------|---------|
| `asap5/asap5PDK_r0p4/libs.tech/openlane/config.tcl` | OpenLane2 PDK-level config |
| `asap5/asap5PDK_r0p4/libs.tech/openlane/asap5_stdcells/config.tcl` | OpenLane2 SCL-level config |
| `asap5/stdcells/n5_integration/openlane2/config_pass_a.json` | Updated Pass A config with PDK vars |
| `asap5/stdcells/n5_integration/openlane2/config_pass_b.json` | Updated Pass B config with PDK vars |

### Files to Modify

| File | Change |
|------|--------|
| `asap5/stdcells/n5_integration/sdc/hamming_cuboid_r4.sdc` | Remove false_path (conflicts with timing analysis), fix operating_conditions |

---

## Task 1: Create OpenLane2 PDK Wrapper for ASAP5

OpenLane2 requires a PDK directory structure with `libs.tech/openlane/config.tcl`. Without this, the flow cannot start. This task creates the minimal wrapper that points to our existing ASAP5 files.

**Files:**
- Create: `asap5/asap5PDK_r0p4/libs.tech/openlane/config.tcl`
- Create: `asap5/asap5PDK_r0p4/libs.tech/openlane/asap5_stdcells/config.tcl`

- [ ] **Step 1: Create the directory structure**

```bash
mkdir -p /Users/bruce/CLAUDE/asap5/asap5PDK_r0p4/libs.tech/openlane/asap5_stdcells
```

- [ ] **Step 2: Write PDK-level config.tcl**

Create `/Users/bruce/CLAUDE/asap5/asap5PDK_r0p4/libs.tech/openlane/config.tcl`:

```tcl
# ASAP5 PDK — OpenLane2 PDK-level configuration
# Process: 5nm GAA Nanosheet (BSIM-CMG level=72, geomod=3)
# VDD: 0.5V nominal

set STD_CELL_LIBRARY "asap5_stdcells"
set VDD_PIN "VDD"
set GND_PIN "VSS"
set VDD_PIN_VOLTAGE 0.5

# Technology LEF (12 metals, N5 RC calibrated)
set TECH_LEFS [dict create \
    nom_tt_025C_1v80 "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/lef/n5_tech.lef" \
]

# SPICE models
set CELL_SPICE_MODELS [glob -nocomplain /Users/bruce/CLAUDE/asap5/stdcells/spice/*.spice]
```

- [ ] **Step 3: Write SCL-level config.tcl**

Create `/Users/bruce/CLAUDE/asap5/asap5PDK_r0p4/libs.tech/openlane/asap5_stdcells/config.tcl`:

```tcl
# ASAP5 Standard Cell Library — OpenLane2 SCL configuration

# Liberty timing
set LIB_SYNTH "/Users/bruce/CLAUDE/asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib"
set LIB_FASTEST "/Users/bruce/CLAUDE/asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib"
set LIB_SLOWEST "/Users/bruce/CLAUDE/asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib"

# Cell LEF
set CELL_LEFS [list \
    "/Users/bruce/CLAUDE/asap5/stdcells/lef/asap5_stdcells.lef" \
    "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/lef/n5_utility_cells.lef" \
]

# Behavioral Verilog for verification
set CELL_VERILOG_MODELS [list \
    "/Users/bruce/CLAUDE/asap5/stdcells/verilog/asap5_stdcells.v" \
    "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/verilog/n5_utility_cells.v" \
]

# CDL for LVS
set CELL_SPICE_MODELS [list \
    "/Users/bruce/CLAUDE/asap5/stdcells/gds/asap5_stdcells.cdl" \
    "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/cdl/n5_utility_cells.cdl" \
]

# GDS for streamout
set CELL_GDS [list \
    "/Users/bruce/CLAUDE/asap5/stdcells/gds/asap5_stdcells.gds" \
]

# Fill cells
set FILL_CELL "FILLx1"
set DECAP_CELL "DECAPx2"
set FP_WELLTAP_CELL "TAPx1"
set FP_ENDCAP_CELL "ENDCAP_L"

# Tie cells
set SYNTH_TIEHI_CELL "TIE_HI"
set SYNTH_TIEHI_PORT "Y"
set SYNTH_TIELO_CELL "TIE_LO"
set SYNTH_TIELO_PORT "Y"

# No diode cell available
set DIODE_CELL ""
set DIODE_CELL_PIN ""
```

- [ ] **Step 4: Verify directory structure**

```bash
find /Users/bruce/CLAUDE/asap5/asap5PDK_r0p4/libs.tech -type f
```

Expected output:
```
/Users/bruce/CLAUDE/asap5/asap5PDK_r0p4/libs.tech/openlane/config.tcl
/Users/bruce/CLAUDE/asap5/asap5PDK_r0p4/libs.tech/openlane/asap5_stdcells/config.tcl
```

---

## Task 2: Fix SDC and Update OpenLane2 Configs

The SDC has a `set_false_path` that conflicts with timing analysis (makes all paths unconstrained). The OpenLane2 configs need PDK/SCL variables and step-skip flags for combinational design.

**Files:**
- Modify: `asap5/stdcells/n5_integration/sdc/hamming_cuboid_r4.sdc`
- Modify: `asap5/stdcells/n5_integration/openlane2/config_pass_a.json`
- Modify: `asap5/stdcells/n5_integration/openlane2/config_pass_b.json`

- [ ] **Step 1: Fix SDC — remove false_path, keep virtual clock**

Replace the SDC with this corrected version (the `set_false_path` would make all timing unconstrained, defeating STA):

```sdc
# Combinational design: hamming_64b_cuboid_r4
# Virtual clock for timing analysis (200 ps period)
create_clock -name vclk -period 0.200

# Input/output constraints
set_input_delay -clock vclk 0.050 [all_inputs]
set_output_delay -clock vclk 0.050 [all_outputs]
set_input_transition 0.100 [all_inputs]

# Design constraints
set_max_fanout 8 [current_design]
set_max_transition 0.500 [current_design]
```

- [ ] **Step 2: Update Pass A config**

Key changes to `config_pass_a.json`:
- Add `PDK` and `STD_CELL_LIBRARY` references (not strictly needed if using CLI args, but good for documentation)
- Disable steps that won't work: CTS (no clock), Magic DRC/LVS (incomplete GDS), KLayout DRC
- Set `SYNTH_NO_FLAT` to preserve structure
- Use absolute paths for all file references

```json
{
    "meta": { "version": 2 },
    "DESIGN_NAME": "hamming_64b_cuboid_r4",
    "VERILOG_FILES": [
        "/Users/bruce/Desktop/hamming_64b_cuboid_r4.v"
    ],

    "TECH_LEF": "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/lef/n5_tech.lef",
    "CELL_LEF": [
        "/Users/bruce/CLAUDE/asap5/stdcells/lef/asap5_stdcells.lef",
        "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/lef/n5_utility_cells.lef"
    ],
    "LIB_SYNTH": "/Users/bruce/CLAUDE/asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib",
    "LIB_FASTEST": "/Users/bruce/CLAUDE/asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib",
    "LIB_SLOWEST": "/Users/bruce/CLAUDE/asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib",

    "CLOCK_PORT": "",
    "CLOCK_PERIOD": 0.200,
    "BASE_SDC_FILE": "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/sdc/hamming_cuboid_r4.sdc",

    "FP_SIZING": "absolute",
    "DIE_AREA": "0 0 10 10",
    "FP_CORE_UTIL": 40,
    "PL_TARGET_DENSITY_PCT": 40,
    "CELL_PAD_IN_SITES_GLOBAL_PLACEMENT": 2,

    "RT_MIN_LAYER": "M1",
    "RT_MAX_LAYER": "M10",

    "SYNTH_STRATEGY": "AREA 0",
    "SYNTH_MAX_FANOUT": 8,
    "SYNTH_NO_FLAT": true,

    "FILL_CELL": ["FILLx1", "FILLx2", "FILLx4"],
    "FP_WELLTAP_CELL": "TAPx1",
    "FP_ENDCAP_CELL": "ENDCAP_L",
    "DECAP_CELL": "DECAPx2",
    "DIODE_CELL": "",

    "SYNTH_TIEHI_CELL": "TIE_HI",
    "SYNTH_TIEHI_PORT": "Y",
    "SYNTH_TIELO_CELL": "TIE_LO",
    "SYNTH_TIELO_PORT": "Y",

    "RUN_CTS": false,
    "RUN_MAGIC_DRC": false,
    "RUN_KLAYOUT_DRC": false,
    "RUN_LVS": false,
    "RUN_MAGIC_STREAMOUT": false,
    "RUN_KLAYOUT_STREAMOUT": false,
    "RUN_LINTER": false,

    "STA_REPORT_POWER": true,
    "GRT_ALLOW_CONGESTION": true
}
```

- [ ] **Step 3: Update Pass B config**

Same as Pass A but with these synthesis differences:

```json
{
    "SYNTH_STRATEGY": "DELAY 3",
    "SYNTH_NO_FLAT": false,
    "SYNTH_BUFFERING": true,
    "SYNTH_SIZING": true
}
```

All other fields identical to Pass A.

- [ ] **Step 4: Verify JSON syntax**

```bash
python3 -c "import json; json.load(open('/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/openlane2/config_pass_a.json')); print('Pass A: OK')"
python3 -c "import json; json.load(open('/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/openlane2/config_pass_b.json')); print('Pass B: OK')"
```

Expected: Both print OK.

---

## Task 3: Verify Yosys Synthesis Standalone

Before running the full OpenLane2 flow, verify that Yosys can synthesize the design with the ASAP5 Liberty. This catches cell-mapping issues early.

**Files:**
- Create: `asap5/stdcells/n5_integration/scripts/synth_test.ys`

- [ ] **Step 1: Write Yosys test synthesis script**

Create `/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/scripts/synth_test.ys`:

```
# Test synthesis: hamming_64b_cuboid_r4 → ASAP5 stdcells
read_verilog /Users/bruce/Desktop/hamming_64b_cuboid_r4.v
hierarchy -check -top hamming_64b_cuboid_r4

# Standard optimization passes
proc; opt; fsm; opt; memory; opt

# Technology mapping to ASAP5 cells
techmap
abc -liberty /Users/bruce/CLAUDE/asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib

# Clean up
opt_clean

# Report statistics
stat -liberty /Users/bruce/CLAUDE/asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib

# Write output
write_verilog -noattr /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/scripts/synth_out.v
```

- [ ] **Step 2: Create scripts directory and run Yosys**

```bash
mkdir -p /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/scripts
yosys /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/scripts/synth_test.ys 2>&1 | tee /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/scripts/synth_test.log
```

Expected output includes:
- `Printing statistics.` with cell counts (XOR2x1, NAND2x1, NOR2x1, INVx1, etc.)
- No errors or warnings about unmapped cells
- `synth_out.v` written successfully

- [ ] **Step 3: Check synthesis results**

```bash
grep -A 30 "Printing statistics" /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/scripts/synth_test.log
```

Record the cell count breakdown. Expected ~3000-5000 cells total.

- [ ] **Step 4: Verify the synthesized netlist instantiates only ASAP5 cells**

```bash
grep "^\s*\(INVx\|NAND2x\|NOR2x\|XOR2x\|XNOR2x\|AOI21x\|OAI21x\|MUX21x\)" /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/scripts/synth_out.v | sort | uniq -c | sort -rn
```

Expected: Only ASAP5 cell names appear. No unmapped gates.

---

## Task 4: Enter Nix Environment and Run OpenLane2 Pass A

This is the main event — running the OpenLane2 Classic flow with structure-preserving synthesis on ASAP5.

**Files:**
- No new files created
- Output: `asap5/stdcells/n5_integration/runs/pass_a/` (created by OpenLane2)

- [ ] **Step 1: Verify Nix is available**

```bash
nix --version
```

Expected: `nix (Nix) 2.34.1` or similar.

- [ ] **Step 2: Enter the OpenLane2 Nix environment and run Pass A**

```bash
cd /Users/bruce/openlane2
nix develop --command bash -c "
  cd /Users/bruce/CLAUDE/asap5/stdcells/n5_integration
  python3 -m openlane \
    --pdk-root /Users/bruce/CLAUDE/asap5 \
    --pdk asap5PDK_r0p4 \
    --scl asap5_stdcells \
    --run-tag pass_a \
    openlane2/config_pass_a.json \
    2>&1 | tee runs/pass_a.log
"
```

**If PDK config.tcl loading fails:** The error will mention `STD_CELL_LIBRARY` not found or config.tcl not readable. Check Task 1 outputs.

**If synthesis fails:** Check that `hamming_64b_cuboid_r4.v` path is correct and the Liberty file is readable.

**If placement fails:** The die area (10×10 μm) may be too small or too large. Adjust `DIE_AREA` based on the synthesis cell count.

- [ ] **Step 3: Check flow completion status**

```bash
tail -50 /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/runs/pass_a.log
```

Look for:
- Flow completion message or final step name
- Any FATAL or ERROR messages
- Timing summary (WNS, TNS)

- [ ] **Step 4: Collect Pass A metrics**

```bash
# Find the run directory
RUN_DIR=$(ls -td /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/runs/pass_a* 2>/dev/null | head -1)

# Check resolved config
cat "$RUN_DIR/resolved.json" | python3 -m json.tool | head -50

# Check synthesis stats
find "$RUN_DIR" -name "*.stat.rpt" -exec cat {} \;

# Check timing
find "$RUN_DIR" -name "*timing*" -o -name "*sta*" | head -10
```

- [ ] **Step 5: If flow errors — diagnose and fix**

Common failure modes and fixes:

| Error | Fix |
|-------|-----|
| `STD_CELL_LIBRARY not set` | Check `libs.tech/openlane/config.tcl` exists and is valid Tcl |
| `Cannot find cell FILLx1` | Verify utility cell LEF is loaded in config |
| `No routing tracks for M6-M10` | Check tech LEF has `make_tracks` compatible layer definitions |
| `Die area too small` | Increase `DIE_AREA` to `"0 0 20 20"` or larger |
| `Placement density violation` | Lower `PL_TARGET_DENSITY_PCT` to 30 |
| `Unresolved module` | Check Verilog file path is correct |
| `pdk_compat` assertion | May need to patch pdk_compat.py — see Task 6 |

---

## Task 5: Run OpenLane2 Pass B (Yosys-Optimized)

Same flow but with free Yosys optimization — no structure preservation.

**Files:**
- Output: `asap5/stdcells/n5_integration/runs/pass_b/` (created by OpenLane2)

- [ ] **Step 1: Run Pass B**

```bash
cd /Users/bruce/openlane2
nix develop --command bash -c "
  cd /Users/bruce/CLAUDE/asap5/stdcells/n5_integration
  python3 -m openlane \
    --pdk-root /Users/bruce/CLAUDE/asap5 \
    --pdk asap5PDK_r0p4 \
    --scl asap5_stdcells \
    --run-tag pass_b \
    openlane2/config_pass_b.json \
    2>&1 | tee runs/pass_b.log
"
```

- [ ] **Step 2: Check flow completion**

```bash
tail -50 /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/runs/pass_b.log
```

- [ ] **Step 3: Collect Pass B metrics**

Same as Task 4 Step 4 but for pass_b run directory.

---

## Task 6: Patch pdk_compat.py (If Needed)

Only execute this task if Tasks 4 or 5 fail due to PDK detection issues in `pdk_compat.py`.

**Files:**
- Modify: `/Users/bruce/openlane2/openlane/config/pdk_compat.py`

- [ ] **Step 1: Add ASAP5 recognition to pdk_compat.py**

Find the section in `pdk_compat.py` where sky130/gf180mcu are detected (around line 20-256). Add an ASAP5 handler:

```python
# After the gf180mcu block, add:
elif pdk.startswith("asap5"):
    # ASAP5 5nm GAA Nanosheet — minimal PDK-specific overrides
    # No special variable deletions or antenna rules needed
    pass
```

This prevents the function from falling through to error or undefined behavior.

- [ ] **Step 2: Re-run the failed pass**

Re-execute the OpenLane2 command from Task 4 or Task 5.

---

## Task 7: Compare PPA Results

After both passes complete, compare the results.

**Files:**
- Create: `asap5/stdcells/n5_integration/docs/ppa_comparison.md`

- [ ] **Step 1: Extract metrics from both runs**

```bash
echo "=== PASS A (Structure-Preserving) ==="
PASS_A_DIR=$(ls -td /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/runs/pass_a* 2>/dev/null | head -1)
echo "--- Synthesis ---"
find "$PASS_A_DIR" -name "*.stat.rpt" -exec cat {} \;
echo "--- Area ---"
find "$PASS_A_DIR" -name "*area*" -exec cat {} \;
echo "--- Timing ---"
find "$PASS_A_DIR" -name "*checks*" -exec tail -20 {} \;

echo ""
echo "=== PASS B (Yosys-Optimized) ==="
PASS_B_DIR=$(ls -td /Users/bruce/CLAUDE/asap5/stdcells/n5_integration/runs/pass_b* 2>/dev/null | head -1)
echo "--- Synthesis ---"
find "$PASS_B_DIR" -name "*.stat.rpt" -exec cat {} \;
echo "--- Area ---"
find "$PASS_B_DIR" -name "*area*" -exec cat {} \;
echo "--- Timing ---"
find "$PASS_B_DIR" -name "*checks*" -exec tail -20 {} \;
```

- [ ] **Step 2: Write PPA comparison document**

Create `asap5/stdcells/n5_integration/docs/ppa_comparison.md` with:

```markdown
# PPA Comparison: Pass A vs Pass B

| Metric | Pass A (Preserved) | Pass B (Yosys) | Delta |
|--------|-------------------|----------------|-------|
| Cell count | X | Y | Y-X |
| Area (μm²) | X | Y | % |
| WNS (ps) | X | Y | |
| TNS (ps) | X | Y | |
| Power (μW) | X | Y | % |

## Analysis
[Which pass wins on each axis and why]
```

- [ ] **Step 3: Review and summarize findings**

Compare against the docx physical analysis estimates:
- Critical path target: 52-106 ps (typical 75 ps)
- Area target: ~1.8 μm² (transistor layer only)
- Power target: ~31 μW @ 1 GHz
- Cell count target: ~1,248 transistors

---

## Task 8: Fallback — Standalone OpenROAD Flow (If OpenLane2 Fails)

Only execute if OpenLane2 integration proves too brittle after Task 6. Uses the existing OpenROAD scripts directly.

**Files:**
- Modify: `asap5/stdcells/openroad/flow.tcl` (extend to 10 metals)
- Modify: `asap5/stdcells/openroad/synth.ys` (point to hamming design)

- [ ] **Step 1: Update synth.ys for hamming design**

```
read_verilog /Users/bruce/Desktop/hamming_64b_cuboid_r4.v
hierarchy -check -top hamming_64b_cuboid_r4
proc; opt; fsm; opt; memory; opt
techmap
abc -liberty /Users/bruce/CLAUDE/asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib
opt_clean
write_verilog -noattr synth.v
stat -liberty /Users/bruce/CLAUDE/asap5/stdcells/lib/asap5_stdcells_tt_0p5v_25c.lib
```

- [ ] **Step 2: Update flow.tcl for 12-metal tech LEF**

Update `read_lef` to use the new n5_tech.lef, update `make_tracks` for all 12 metals, update `global_route -layers` to M1-M10.

- [ ] **Step 3: Run standalone flow**

```bash
cd /Users/bruce/CLAUDE/asap5/stdcells/openroad
yosys synth.ys 2>&1 | tee synth.log
openroad flow.tcl 2>&1 | tee flow.log
```

- [ ] **Step 4: Collect and compare results**

Same metric extraction as Task 7.

---

## Execution Order

```
Task 1 (PDK wrapper)          REQUIRED — creates the PDK structure
    ↓
Task 2 (Fix SDC + configs)    REQUIRED — corrects timing constraints
    ↓
Task 3 (Yosys standalone)     REQUIRED — validates synthesis mapping
    ↓
Task 4 (Pass A)               MAIN — structure-preserving RTL-to-GDSII
    ↓ (if fails)
Task 6 (Patch pdk_compat)     CONDITIONAL — only if PDK detection fails
    ↓
Task 5 (Pass B)               MAIN — Yosys-optimized RTL-to-GDSII
    ↓
Task 7 (Compare PPA)          FINAL — two-pass comparison

Task 8 (Fallback)             ONLY if OpenLane2 integration fails entirely
```
