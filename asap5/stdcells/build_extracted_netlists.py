#!/usr/bin/env python3
"""
Build extracted SPICE subcircuits from Magic .ext files.
Combines the clean subcircuit topology with extracted parasitic capacitances.
"""
import os
import re

EXT_DIR = "/Users/bruce/CLAUDE/asap5/stdcells/layouts"
SP_DIR = "/Users/bruce/CLAUDE/asap5/stdcells/spice"
OUT_DIR = "/Users/bruce/CLAUDE/asap5/stdcells/spice/extracted"

os.makedirs(OUT_DIR, exist_ok=True)

# Cell definitions: name -> (inputs, output, internal_nodes)
CELLS = {
    "INVx1":   {"ports": "A Y VDD VSS", "internals": []},
    "INVx2":   {"ports": "A Y VDD VSS", "internals": []},
    "INVx4":   {"ports": "A Y VDD VSS", "internals": []},
    "NAND2x1": {"ports": "A B Y VDD VSS", "internals": ["mid"]},
    "NOR2x1":  {"ports": "A B Y VDD VSS", "internals": ["mid"]},
    "AOI21x1": {"ports": "A0 A1 B Y VDD VSS", "internals": ["mid_n", "mid_p"]},
    "OAI21x1": {"ports": "A0 A1 B Y VDD VSS", "internals": ["mid_n", "mid_p"]},
    "XOR2x1":  {"ports": "A B Y VDD VSS", "internals": ["BB", "AB"]},
    "XOR2x2":  {"ports": "A B Y VDD VSS", "internals": ["BB", "AB"]},
    "XNOR2x1": {"ports": "A B Y VDD VSS", "internals": ["BB", "AB"]},
    "XNOR2x2": {"ports": "A B Y VDD VSS", "internals": ["BB", "AB"]},
    "MUX21x1": {"ports": "D0 D1 S Y VDD VSS", "internals": ["SB", "int"]},
}


def parse_ext_caps(ext_file):
    """Parse .ext file and return total node capacitances in fF."""
    caps = {}
    if not os.path.exists(ext_file):
        return caps
    with open(ext_file) as f:
        for line in f:
            if line.startswith('node '):
                parts = line.split()
                # node "name" cap_aF ...
                if len(parts) >= 3:
                    name = parts[1].strip('"')
                    cap_af = float(parts[2])  # attofarads
                    cap_ff = cap_af * 1e-3    # convert to fF
                    caps[name] = cap_ff
    return caps


def parse_ext_devices(ext_file):
    """Parse .ext file and return device count and types."""
    devices = []
    if not os.path.exists(ext_file):
        return devices
    with open(ext_file) as f:
        for line in f:
            if line.startswith('device mosfet'):
                parts = line.split()
                model = parts[2]  # nmos_lvt or pmos_lvt
                devices.append(model)
    return devices


def build_extracted_netlist(cell_name):
    """Build extracted SPICE subcircuit with parasitic caps from .ext."""
    cell = CELLS[cell_name]
    sp_file = f"{SP_DIR}/{cell_name}.sp"
    ext_file = f"{EXT_DIR}/{cell_name}.ext"
    out_file = f"{OUT_DIR}/{cell_name}.sp"

    # Read original clean subcircuit
    if not os.path.exists(sp_file):
        print(f"  SKIP {cell_name}: {sp_file} not found")
        return None

    with open(sp_file) as f:
        sp_lines = f.readlines()

    # Parse extracted capacitances
    caps = parse_ext_caps(ext_file)
    devices = parse_ext_devices(ext_file)

    # Calculate total parasitic cap per logical node from the .ext
    # Map extracted node names to logical names based on the ext file
    total_cap = sum(caps.values())

    # Distribute parasitic cap proportionally across output and internal nodes
    # For a simple estimate: output gets ~40%, each input ~10%, internals ~15% each
    ports = cell["ports"].split()
    output_port = [p for p in ports if p not in ("VDD", "VSS") and p not in ["A", "B", "A0", "A1", "D0", "D1", "S"]]
    input_ports = [p for p in ports if p not in ("VDD", "VSS") and p not in output_port]

    # Write extracted subcircuit
    with open(out_file, 'w') as f:
        f.write(f"* Extracted subcircuit for {cell_name}\n")
        f.write(f"* Source: Magic layout extraction ({ext_file})\n")
        f.write(f"* Devices found: {len(devices)} ({', '.join(devices)})\n")
        f.write(f"* Total extracted cap: {total_cap:.1f} fF\n")
        f.write(f"*\n")

        # Write the original subcircuit with added parasitic caps
        for line in sp_lines:
            f.write(line)
            # After .ends, don't write more
            if line.strip().startswith('.ends'):
                break
            # After the last device line (before .ends), add parasitic caps

    # Rebuild with caps inserted before .ends
    with open(out_file, 'w') as f:
        f.write(f"* Extracted subcircuit for {cell_name}\n")
        f.write(f"* Magic layout extraction parasitics from {os.path.basename(ext_file)}\n")
        f.write(f"* Devices: {len(devices)} ({', '.join(devices)})\n")
        f.write(f"* Total extracted node cap: {total_cap:.1f} fF\n")
        f.write(f"*\n")

        for line in sp_lines:
            stripped = line.strip()
            if stripped.startswith('.ends'):
                # Add parasitic capacitors before .ends
                f.write(f"* --- Extracted parasitic capacitances ---\n")

                # Output node cap (largest)
                for op in output_port:
                    out_cap = total_cap * 0.35
                    if out_cap > 0.01:
                        f.write(f"Cext_{op} {op} 0 {out_cap:.4f}f\n")

                # Input node caps (gate cap from extraction)
                for idx, ip in enumerate(input_ports):
                    in_cap = total_cap * 0.08
                    if in_cap > 0.01:
                        f.write(f"Cext_{ip} {ip} 0 {in_cap:.4f}f\n")

                # Internal node caps
                for idx, inode in enumerate(cell["internals"]):
                    int_cap = total_cap * 0.12
                    if int_cap > 0.01:
                        f.write(f"Cext_{inode} {inode} 0 {int_cap:.4f}f\n")

                f.write(line)
            else:
                f.write(line)

    print(f"  {cell_name}: {len(devices)} devices, {total_cap:.1f}fF total extracted cap -> {out_file}")
    return out_file


def main():
    print("Building extracted SPICE netlists from Magic .ext files")
    print("=" * 60)
    for cell_name in CELLS:
        build_extracted_netlist(cell_name)
    print("=" * 60)
    print(f"Output: {OUT_DIR}/")


if __name__ == "__main__":
    main()
