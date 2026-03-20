#!/usr/bin/env python3
"""Generate via-grid crosspoint macros: LEF, Liberty, Verilog, Magic layout.

Each crosspoint is a passive metal crossbar:
  - M_v vertical wires (input v[])
  - M_h horizontal wires (input h[])
  - Vias at intersections where i+j=k connect to output s[k]
  - Output collection wires carry the wired-OR of each anti-diagonal
"""

import os

BASE = "/Users/bruce/CLAUDE/asap5/stdcells/n5_integration/via_macros"

# Crosspoint macro definitions: (name, M, N, v_layer, h_layer, via_layer, pitch_nm)
MACROS = [
    ("XP_3x3_M2M3", 3, 3, "M2", "M3", "V2", 28),
    ("XP_5x5_M2M3", 5, 5, "M2", "M3", "V2", 28),
    ("XP_4x4_M4M5", 4, 4, "M4", "M5", "V4", 40),
    ("XP_3x3_M4M5", 3, 3, "M4", "M5", "V4", 40),
]

def gen_lef(macros):
    """Generate LEF file with all crosspoint macros."""
    lines = [
        'VERSION 5.8 ;',
        'BUSBITCHARS "[]" ;',
        'DIVIDERCHAR "/" ;',
        '',
        '# Via-Grid Crosspoint Macros — Passive Metal Crossbar',
        '# Zero transistors, pure metal + via structures',
        '',
    ]

    for name, m, n, vl, hl, via, pitch in macros:
        outs = m + n - 1
        # Macro width: m wires * pitch, with margin
        w_nm = (m + 1) * pitch
        # Macro height: n input wires + outs output wires + margins
        h_nm = (n + outs + 2) * pitch
        w_um = w_nm / 1000.0
        h_um = h_nm / 1000.0

        # Snap to site grid (44nm x 140nm)
        w_sites = max(2, int(w_um / 0.044) + 1)
        h_sites = max(1, int(h_um / 0.140) + 1)
        w_um = w_sites * 0.044
        h_um = h_sites * 0.140

        lines.append(f'MACRO {name}')
        lines.append(f'  CLASS BLOCK ;')
        lines.append(f'  ORIGIN 0 0 ;')
        lines.append(f'  SIZE {w_um:.3f} BY {h_um:.3f} ;')
        lines.append(f'  SYMMETRY X Y ;')
        lines.append(f'')

        # VDD/VSS pins (required by OpenROAD)
        lines.append(f'  PIN VDD')
        lines.append(f'    DIRECTION INOUT ;')
        lines.append(f'    USE POWER ;')
        lines.append(f'    PORT')
        lines.append(f'      LAYER M1 ;')
        lines.append(f'        RECT 0.000 {h_um-0.014:.3f} {w_um:.3f} {h_um:.3f} ;')
        lines.append(f'    END')
        lines.append(f'  END VDD')
        lines.append(f'')
        lines.append(f'  PIN VSS')
        lines.append(f'    DIRECTION INOUT ;')
        lines.append(f'    USE GROUND ;')
        lines.append(f'    PORT')
        lines.append(f'      LAYER M1 ;')
        lines.append(f'        RECT 0.000 0.000 {w_um:.3f} 0.014 ;')
        lines.append(f'    END')
        lines.append(f'  END VSS')
        lines.append(f'')

        # Vertical input pins v[0..M-1] on v_layer (left edge)
        for i in range(m):
            pin_y = 0.028 + i * (pitch / 1000.0)
            lines.append(f'  PIN v[{i}]')
            lines.append(f'    DIRECTION INPUT ;')
            lines.append(f'    USE SIGNAL ;')
            lines.append(f'    PORT')
            lines.append(f'      LAYER {vl} ;')
            lines.append(f'        RECT 0.000 {pin_y:.3f} {pitch/2000.0:.3f} {pin_y + pitch/1000.0:.3f} ;')
            lines.append(f'    END')
            lines.append(f'  END v[{i}]')
            lines.append(f'')

        # Horizontal input pins h[0..N-1] on h_layer (bottom edge)
        for j in range(n):
            pin_x = 0.028 + j * (pitch / 1000.0)
            lines.append(f'  PIN h[{j}]')
            lines.append(f'    DIRECTION INPUT ;')
            lines.append(f'    USE SIGNAL ;')
            lines.append(f'    PORT')
            lines.append(f'      LAYER {hl} ;')
            lines.append(f'        RECT {pin_x:.3f} 0.014 {pin_x + pitch/1000.0:.3f} {0.014 + pitch/2000.0:.3f} ;')
            lines.append(f'    END')
            lines.append(f'  END h[{j}]')
            lines.append(f'')

        # Output pins s[0..M+N-2] on h_layer (right edge)
        for k in range(outs):
            pin_y = 0.028 + (m + k) * (pitch / 1000.0)
            if pin_y + pitch/1000.0 > h_um:
                pin_y = h_um - 0.028 - (outs - k) * (pitch / 1000.0)
            lines.append(f'  PIN s[{k}]')
            lines.append(f'    DIRECTION OUTPUT ;')
            lines.append(f'    USE SIGNAL ;')
            lines.append(f'    PORT')
            lines.append(f'      LAYER {hl} ;')
            lines.append(f'        RECT {w_um - pitch/2000.0:.3f} {pin_y:.3f} {w_um:.3f} {pin_y + pitch/1000.0:.3f} ;')
            lines.append(f'    END')
            lines.append(f'  END s[{k}]')
            lines.append(f'')

        # Obstruction (block routing through the macro)
        lines.append(f'  OBS')
        lines.append(f'    LAYER {vl} ;')
        lines.append(f'      RECT 0.000 0.014 {w_um:.3f} {h_um-0.014:.3f} ;')
        if vl != hl:
            lines.append(f'    LAYER {hl} ;')
            lines.append(f'      RECT 0.000 0.014 {w_um:.3f} {h_um-0.014:.3f} ;')
        lines.append(f'  END')
        lines.append(f'END {name}')
        lines.append(f'')

    lines.append('END LIBRARY')
    return '\n'.join(lines)


def gen_liberty(macros):
    """Generate Liberty file with timing for via-grid macros."""
    lines = [
        'library (xp_via_macros_tt_0p5v_25c) {',
        '  delay_model : table_lookup ;',
        '  time_unit : "1ns" ;',
        '  voltage_unit : "1V" ;',
        '  current_unit : "1mA" ;',
        '  pulling_resistance_unit : "1kohm" ;',
        '  leakage_power_unit : "1nW" ;',
        '  capacitive_load_unit (1, pf) ;',
        '  nom_voltage : 0.500 ;',
        '  nom_temperature : 25.000 ;',
        '  nom_process : 1.0 ;',
        '  default_max_transition : 0.500 ;',
        '  operating_conditions (tt_0p5v_25c) {',
        '    process : 1.0 ; voltage : 0.500 ; temperature : 25.000 ;',
        '  }',
        '  default_operating_conditions : tt_0p5v_25c ;',
        '',
    ]

    for name, m, n, vl, hl, via, pitch in macros:
        outs = m + n - 1
        # Area in lambda^2 (pitch^2 * m * n)
        area = m * n * pitch * pitch

        # RC delay for worst-case output wire (ps)
        r_per_um = {"M2": 225, "M3": 99, "M4": 117, "M5": 52}.get(hl, 11)
        c_per_um = {"M2": 0.27, "M3": 0.22, "M4": 0.20, "M5": 0.26}.get(hl, 0.17)
        wire_um = max(m, n) * pitch / 1000.0
        delay_ns = 0.5 * r_per_um * wire_um * c_per_um * wire_um / 1000.0
        delay_ns = max(delay_ns, 0.001)  # minimum 1ps

        lines.append(f'  cell ({name}) {{')
        lines.append(f'    area : {area} ;')
        lines.append(f'    cell_leakage_power : 0.00 ;')
        lines.append(f'    dont_touch : true ;')
        lines.append(f'    pg_pin (VDD) {{ voltage_name : VDD ; pg_type : primary_power ; }}')
        lines.append(f'    pg_pin (VSS) {{ voltage_name : VSS ; pg_type : primary_ground ; }}')
        lines.append(f'')

        # Input pins
        for i in range(m):
            cap = c_per_um * n * pitch / 1000.0  # load = wire length
            lines.append(f'    pin (v[{i}]) {{')
            lines.append(f'      direction : input ;')
            lines.append(f'      capacitance : {cap:.6f} ;')
            lines.append(f'    }}')

        for j in range(n):
            cap = c_per_um * m * pitch / 1000.0
            lines.append(f'    pin (h[{j}]) {{')
            lines.append(f'      direction : input ;')
            lines.append(f'      capacitance : {cap:.6f} ;')
            lines.append(f'    }}')

        # Output pins with timing arcs
        for k in range(outs):
            lines.append(f'    pin (s[{k}]) {{')
            lines.append(f'      direction : output ;')
            lines.append(f'      function : "(')

            # Build function: OR of all v[i] & h[k-i]
            terms = []
            for i in range(m):
                j = k - i
                if 0 <= j < n:
                    terms.append(f'v[{i}] & h[{j}]')
            lines.append(f'        {" | ".join(terms)}')
            lines.append(f'      )" ;')
            lines.append(f'      max_capacitance : 0.100 ;')

            # Timing from each input to this output
            for i in range(m):
                j = k - i
                if 0 <= j < n:
                    lines.append(f'      timing () {{')
                    lines.append(f'        related_pin : "v[{i}]" ;')
                    lines.append(f'        timing_sense : positive_unate ;')
                    lines.append(f'        cell_rise (scalar) {{ values ("{delay_ns:.4f}") ; }}')
                    lines.append(f'        cell_fall (scalar) {{ values ("{delay_ns:.4f}") ; }}')
                    lines.append(f'        rise_transition (scalar) {{ values ("{delay_ns*2:.4f}") ; }}')
                    lines.append(f'        fall_transition (scalar) {{ values ("{delay_ns*2:.4f}") ; }}')
                    lines.append(f'      }}')
                    lines.append(f'      timing () {{')
                    lines.append(f'        related_pin : "h[{j}]" ;')
                    lines.append(f'        timing_sense : positive_unate ;')
                    lines.append(f'        cell_rise (scalar) {{ values ("{delay_ns:.4f}") ; }}')
                    lines.append(f'        cell_fall (scalar) {{ values ("{delay_ns:.4f}") ; }}')
                    lines.append(f'        rise_transition (scalar) {{ values ("{delay_ns*2:.4f}") ; }}')
                    lines.append(f'        fall_transition (scalar) {{ values ("{delay_ns*2:.4f}") ; }}')
                    lines.append(f'      }}')

            lines.append(f'    }}')

        lines.append(f'  }}')
        lines.append(f'')

    lines.append('}')
    return '\n'.join(lines)


def gen_verilog(macros):
    """Generate behavioral Verilog for via-grid macros."""
    lines = [
        '// Via-Grid Crosspoint Macros — Behavioral Verilog',
        '// Zero transistors: pure passive metal crossbar',
        '',
    ]

    for name, m, n, vl, hl, via, pitch in macros:
        outs = m + n - 1
        lines.append(f'(* keep_hierarchy *)')
        lines.append(f'module {name} (')
        lines.append(f'    input  wire [{m-1}:0] v,')
        lines.append(f'    input  wire [{n-1}:0] h,')
        lines.append(f'    output wire [{outs-1}:0] s')
        lines.append(f');')

        for k in range(outs):
            terms = []
            for i in range(m):
                j = k - i
                if 0 <= j < n:
                    terms.append(f'(v[{i}] & h[{j}])')
            lines.append(f'    assign s[{k}] = {" | ".join(terms)};')

        lines.append(f'endmodule')
        lines.append(f'')

    return '\n'.join(lines)


def gen_top_rtl(macros):
    """Generate top-level RTL using via-grid macros for small crosspoints."""
    # Map crosspoint sizes to macro names
    macro_map = {}
    for name, m, n, vl, hl, via, pitch in macros:
        macro_map[(m, n, vl, hl)] = name

    lines = []
    lines.append('// ============================================================================')
    lines.append('// 64-BIT HAMMING DISTANCE — Via-Grid Crosspoint Implementation')
    lines.append('// Small crosspoints (3x3, 4x4, 5x5) use via-grid hard macros (0 transistors)')
    lines.append('// Large crosspoints (7x7+) use crosspoint_sum standard-cell modules')
    lines.append('// ============================================================================')
    lines.append('')
    lines.append('`timescale 1ps / 1fs')
    lines.append('')
    lines.append('module hamming_64b_cuboid_r4_via (')
    lines.append('    input  wire [63:0] A,')
    lines.append('    input  wire [63:0] B,')
    lines.append('    output wire [6:0]  hd')
    lines.append(');')
    lines.append('')
    lines.append('    // Stage 1A: XOR / XNOR')
    lines.append('    wire [63:0] d, dn;')
    lines.append('    genvar gi;')
    lines.append('    generate')
    lines.append('        for (gi = 0; gi < 64; gi = gi + 1) begin : xor_stage')
    lines.append('            assign d[gi]  = A[gi] ^ B[gi];')
    lines.append('            assign dn[gi] = ~d[gi];')
    lines.append('        end')
    lines.append('    endgenerate')
    lines.append('')
    lines.append('    // Stage 1B: 32 Fused Cells')
    lines.append('    wire [95:0] cell_oh_flat;')
    lines.append('    generate')
    lines.append('        for (gi = 0; gi < 32; gi = gi + 1) begin : fused_cell')
    lines.append('            assign cell_oh_flat[3*gi+0] = dn[2*gi] & dn[2*gi+1];')
    lines.append('            assign cell_oh_flat[3*gi+1] = d[2*gi]  ^ d[2*gi+1];')
    lines.append('            assign cell_oh_flat[3*gi+2] = d[2*gi]  & d[2*gi+1];')
    lines.append('        end')
    lines.append('    endgenerate')
    lines.append('')

    # Stage 2 L1: 16x 3x3 via-grid macros (M2/M3)
    lines.append('    // Stage 2 L1: 16x XP_3x3_M2M3 via-grid macros')
    lines.append('    wire [79:0] ps_flat;')
    lines.append('    generate')
    lines.append('        for (gi = 0; gi < 16; gi = gi + 1) begin : xp3_s2l1')
    lines.append('            XP_3x3_M2M3 u_xp3 (')
    lines.append('                .v(cell_oh_flat[6*gi+2 : 6*gi]),')
    lines.append('                .h(cell_oh_flat[6*gi+5 : 6*gi+3]),')
    lines.append('                .s(ps_flat[5*gi+4 : 5*gi])')
    lines.append('            );')
    lines.append('        end')
    lines.append('    endgenerate')
    lines.append('')

    # Stage 2 L2: 8x 5x5 via-grid macros (M2/M3)
    lines.append('    // Stage 2 L2: 8x XP_5x5_M2M3 via-grid macros')
    lines.append('    wire [71:0] byte_oh_flat;')
    lines.append('    generate')
    lines.append('        for (gi = 0; gi < 8; gi = gi + 1) begin : xp5_s2l2')
    lines.append('            XP_5x5_M2M3 u_xp5 (')
    lines.append('                .v(ps_flat[10*gi+4 : 10*gi]),')
    lines.append('                .h(ps_flat[10*gi+9 : 10*gi+5]),')
    lines.append('                .s(byte_oh_flat[9*gi+8 : 9*gi])')
    lines.append('            );')
    lines.append('        end')
    lines.append('    endgenerate')
    lines.append('')

    # Stage 3: Radix-4 split (same as before)
    lines.append('    // Stage 3: Radix-4 Digit Split')
    lines.append('    wire [31:0] lo_flat;')
    lines.append('    wire [23:0] hi_flat;')
    lines.append('    generate')
    lines.append('        for (gi = 0; gi < 8; gi = gi + 1) begin : r4_split')
    lines.append('            wire [8:0] boh = byte_oh_flat[9*gi+8 : 9*gi];')
    lines.append('            assign lo_flat[4*gi+0] = boh[0] | boh[4] | boh[8];')
    lines.append('            assign lo_flat[4*gi+1] = boh[1] | boh[5];')
    lines.append('            assign lo_flat[4*gi+2] = boh[2] | boh[6];')
    lines.append('            assign lo_flat[4*gi+3] = boh[3] | boh[7];')
    lines.append('            assign hi_flat[3*gi+0] = boh[0] | boh[1] | boh[2] | boh[3];')
    lines.append('            assign hi_flat[3*gi+1] = boh[4] | boh[5] | boh[6] | boh[7];')
    lines.append('            assign hi_flat[3*gi+2] = boh[8];')
    lines.append('        end')
    lines.append('    endgenerate')
    lines.append('')

    # Stage 4 Lo L1: 4x 4x4 via-grid macros (M4/M5)
    lines.append('    // Stage 4 Lo L1: 4x XP_4x4_M4M5 via-grid macros')
    lines.append('    wire [27:0] ll1_flat;')
    lines.append('    generate')
    lines.append('        for (gi = 0; gi < 4; gi = gi + 1) begin : xp4_lo_l1')
    lines.append('            XP_4x4_M4M5 u_xp4 (')
    lines.append('                .v(lo_flat[8*gi+3 : 8*gi]),')
    lines.append('                .h(lo_flat[8*gi+7 : 8*gi+4]),')
    lines.append('                .s(ll1_flat[7*gi+6 : 7*gi])')
    lines.append('            );')
    lines.append('        end')
    lines.append('    endgenerate')
    lines.append('')

    # Stage 4 Hi L1: 4x 3x3 via-grid macros (M4/M5)
    lines.append('    // Stage 4 Hi L1: 4x XP_3x3_M4M5 via-grid macros')
    lines.append('    wire [19:0] hl1_flat;')
    lines.append('    generate')
    lines.append('        for (gi = 0; gi < 4; gi = gi + 1) begin : xp3_hi_l1')
    lines.append('            XP_3x3_M4M5 u_xp3 (')
    lines.append('                .v(hi_flat[6*gi+2 : 6*gi]),')
    lines.append('                .h(hi_flat[6*gi+5 : 6*gi+3]),')
    lines.append('                .s(hl1_flat[5*gi+4 : 5*gi])')
    lines.append('            );')
    lines.append('        end')
    lines.append('    endgenerate')
    lines.append('')

    # Stage 4 Lo L2+: use crosspoint_sum (std cell) for large crosspoints
    lines.append('    // Stage 4 Lo L2: 2x 7x7 crosspoint_sum (std-cell, too large for via macro)')
    lines.append('    wire [25:0] ll2_flat;')
    lines.append('    generate')
    lines.append('        for (gi = 0; gi < 2; gi = gi + 1) begin : xp7_lo_l2')
    lines.append('            crosspoint_sum #(.M(7), .N(7)) u_xp7 (')
    lines.append('                .v(ll1_flat[14*gi+6 : 14*gi]),')
    lines.append('                .h(ll1_flat[14*gi+13 : 14*gi+7]),')
    lines.append('                .s(ll2_flat[13*gi+12 : 13*gi])')
    lines.append('            );')
    lines.append('        end')
    lines.append('    endgenerate')
    lines.append('')
    lines.append('    wire [24:0] low_sum;')
    lines.append('    crosspoint_sum #(.M(13), .N(13)) u_xp13_lo_l3 (.v(ll2_flat[12:0]), .h(ll2_flat[25:13]), .s(low_sum));')
    lines.append('')

    # Stage 4 Hi L2+
    lines.append('    // Stage 4 Hi L2: 2x 5x5 crosspoint_sum (std-cell)')
    lines.append('    wire [17:0] hl2_flat;')
    lines.append('    generate')
    lines.append('        for (gi = 0; gi < 2; gi = gi + 1) begin : xp5_hi_l2')
    lines.append('            crosspoint_sum #(.M(5), .N(5)) u_xp5 (')
    lines.append('                .v(hl1_flat[10*gi+4 : 10*gi]),')
    lines.append('                .h(hl1_flat[10*gi+9 : 10*gi+5]),')
    lines.append('                .s(hl2_flat[9*gi+8 : 9*gi])')
    lines.append('            );')
    lines.append('        end')
    lines.append('    endgenerate')
    lines.append('')
    lines.append('    wire [16:0] high_sum;')
    lines.append('    crosspoint_sum #(.M(9), .N(9)) u_xp9_hi_l3 (.v(hl2_flat[8:0]), .h(hl2_flat[17:9]), .s(high_sum));')
    lines.append('')

    # Carry split + carry addition + binary convert (same as before)
    lines.append('    // Stage 4C: Carry Split')
    lines.append('    wire [3:0] final_lo; wire [6:0] carry;')
    for i in range(4):
        terms = [f'low_sum[{i+4*k}]' for k in range(7) if i+4*k <= 24]
        lines.append(f'    assign final_lo[{i}] = {" | ".join(terms)};')
    for i in range(7):
        terms = [f'low_sum[{4*i+j}]' for j in range(4) if 4*i+j <= 24]
        lines.append(f'    assign carry[{i}] = {" | ".join(terms)};')
    lines.append('')
    lines.append('    // Stage 4D: 17x7 Carry Addition (std-cell)')
    lines.append('    wire [22:0] upper;')
    lines.append('    crosspoint_sum #(.M(17), .N(7)) u_xp17x7_carry (.v(high_sum), .h(carry), .s(upper));')
    lines.append('')
    lines.append('    // Stage 5: Binary Conversion')
    lines.append('    assign hd[0] = final_lo[1] | final_lo[3];')
    lines.append('    assign hd[1] = final_lo[2] | final_lo[3];')
    lines.append('    assign hd[2] = upper[1]|upper[3]|upper[5]|upper[7]|upper[9]|upper[11]|upper[13]|upper[15]|upper[17]|upper[19]|upper[21];')
    lines.append('    assign hd[3] = upper[2]|upper[3]|upper[6]|upper[7]|upper[10]|upper[11]|upper[14]|upper[15]|upper[18]|upper[19]|upper[22];')
    lines.append('    assign hd[4] = upper[4]|upper[5]|upper[6]|upper[7]|upper[12]|upper[13]|upper[14]|upper[15]|upper[20]|upper[21]|upper[22];')
    lines.append('    assign hd[5] = upper[8]|upper[9]|upper[10]|upper[11]|upper[12]|upper[13]|upper[14]|upper[15];')
    lines.append('    assign hd[6] = upper[16]|upper[17]|upper[18]|upper[19]|upper[20]|upper[21]|upper[22];')
    lines.append('')
    lines.append('endmodule')

    return '\n'.join(lines)


if __name__ == '__main__':
    # Generate all files
    lef = gen_lef(MACROS)
    with open(os.path.join(BASE, 'lef', 'xp_via_macros.lef'), 'w') as f:
        f.write(lef)
    print(f"LEF: {len(MACROS)} macros written")

    lib = gen_liberty(MACROS)
    with open(os.path.join(BASE, 'lib', 'xp_via_macros_tt_0p5v_25c.lib'), 'w') as f:
        f.write(lib)
    print(f"Liberty: {len(MACROS)} cells written")

    vlog = gen_verilog(MACROS)
    with open(os.path.join(BASE, 'verilog', 'xp_via_macros.v'), 'w') as f:
        f.write(vlog)
    print(f"Verilog: {len(MACROS)} modules written")

    top = gen_top_rtl(MACROS)
    with open(os.path.join(BASE, 'verilog', 'hamming_64b_cuboid_r4_via.v'), 'w') as f:
        f.write(top)
    print(f"Top RTL: hamming_64b_cuboid_r4_via written")

    print("\nFiles generated:")
    print(f"  {BASE}/lef/xp_via_macros.lef")
    print(f"  {BASE}/lib/xp_via_macros_tt_0p5v_25c.lib")
    print(f"  {BASE}/verilog/xp_via_macros.v")
    print(f"  {BASE}/verilog/hamming_64b_cuboid_r4_via.v")
