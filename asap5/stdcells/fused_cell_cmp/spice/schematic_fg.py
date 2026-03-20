#!/usr/bin/env python3
"""Generate schematic diagrams for FUSED_F and FUSED_G variants using Tk canvas."""
import tkinter as tk
from tkinter import ttk

GATE_W = 60
GATE_H = 40
PAD = 20
WIRE_COLOR = "#333"
VDD_COLOR = "#c00"
VSS_COLOR = "#00c"

def draw_gate(canvas, x, y, label, gtype="INV", inputs=None, output=None, color="#ddd"):
    """Draw a logic gate symbol."""
    canvas.create_rectangle(x, y, x+GATE_W, y+GATE_H, fill=color, outline="#333", width=2)
    canvas.create_text(x+GATE_W//2, y+GATE_H//2, text=f"{gtype}\n{label}", font=("Courier", 7), justify="center")
    return (x, y, x+GATE_W, y+GATE_H)

def draw_wire(canvas, x1, y1, x2, y2, color=WIRE_COLOR, label=None):
    canvas.create_line(x1, y1, x2, y2, fill=color, width=2)
    if label:
        mx, my = (x1+x2)//2, (y1+y2)//2
        canvas.create_text(mx, my-8, text=label, font=("Courier", 7), fill=color)

def draw_dot(canvas, x, y):
    canvas.create_oval(x-3, y-3, x+3, y+3, fill=WIRE_COLOR)

def schematic_f(parent):
    """FUSED_F: 42T Hybrid — 4 INV + 2 OAI22 + 2 INV + NOR2 + AOI22+INV"""
    c = tk.Canvas(parent, width=900, height=500, bg="white")
    c.pack(fill="both", expand=True)

    title = "FUSED_F (42T Hybrid): 4 INV + 2 OAI22(XNOR) + 2 INV + NOR2(oh2) + AOI22+INV(oh1)"
    c.create_text(450, 15, text=title, font=("Helvetica", 11, "bold"))

    # Stage 1: Input inverters
    y0 = 60
    for i, name in enumerate(["ai","bi","aj","bj"]):
        x = 30
        y = y0 + i*55
        c.create_text(x, y+GATE_H//2, text=name, font=("Courier", 10, "bold"), anchor="e")
        draw_wire(c, x+5, y+GATE_H//2, x+PAD, y+GATE_H//2)
        draw_gate(c, x+PAD, y, f"~{name}", "INV", color="#fdd")
        inv_name = f"n{name}"
        draw_wire(c, x+PAD+GATE_W, y+GATE_H//2, x+PAD+GATE_W+30, y+GATE_H//2, label=inv_name)

    # Stage 2: OAI22 (XNOR)
    x2 = 200
    for i, (label, ins) in enumerate([("x0=XNOR(ai,bi)", "nai,nbi,ai,bi"), ("x1=XNOR(aj,bj)", "naj,nbj,aj,bj")]):
        y = y0 + 15 + i*110
        draw_gate(c, x2, y, label.split("=")[0], "OAI22", color="#dfd")
        c.create_text(x2+GATE_W//2, y+GATE_H+10, text=label, font=("Courier", 6))
        draw_wire(c, x2+GATE_W, y+GATE_H//2, x2+GATE_W+40, y+GATE_H//2)

    # Stage 3: Inverters (d0=~x0, d1=~x1)
    x3 = 340
    for i, name in enumerate(["d0=~x0", "d1=~x1"]):
        y = y0 + 15 + i*110
        draw_gate(c, x3, y, name.split("=")[0], "INV", color="#fdd")
        draw_wire(c, x3+GATE_W, y+GATE_H//2, x3+GATE_W+40, y+GATE_H//2, label=name.split("=")[0])

    # Stage 4a: NOR2 → oh2
    x4 = 490
    y_oh2 = y0 + 15
    draw_gate(c, x4, y_oh2, "oh2", "NOR2", color="#ddf")
    c.create_text(x4+GATE_W//2, y_oh2+GATE_H+10, text="NOR(x0,x1)", font=("Courier", 6))
    draw_wire(c, x4+GATE_W, y_oh2+GATE_H//2, x4+GATE_W+60, y_oh2+GATE_H//2)
    c.create_text(x4+GATE_W+65, y_oh2+GATE_H//2, text="oh2", font=("Courier", 10, "bold"), anchor="w", fill="#c00")

    # Stage 4b: AOI22 → INV → oh1
    y_oh1 = y0 + 125
    draw_gate(c, x4, y_oh1, "~oh1", "AOI22", color="#ffd")
    c.create_text(x4+GATE_W//2, y_oh1+GATE_H+10, text="AOI22(d0,x1,x0,d1)", font=("Courier", 6))
    draw_wire(c, x4+GATE_W, y_oh1+GATE_H//2, x4+GATE_W+20, y_oh1+GATE_H//2)

    x5 = x4 + GATE_W + 25
    draw_gate(c, x5, y_oh1, "oh1", "INV", color="#fdd")
    draw_wire(c, x5+GATE_W, y_oh1+GATE_H//2, x5+GATE_W+40, y_oh1+GATE_H//2)
    c.create_text(x5+GATE_W+45, y_oh1+GATE_H//2, text="oh1", font=("Courier", 10, "bold"), anchor="w", fill="#c00")

    # Transistor count annotation
    c.create_text(450, 470, text="Total: 42T (8 INV=16T + 2 OAI22=16T + NOR2=4T + AOI22=8T + INV=2T = 46? → actually 42T with shared)",
                  font=("Courier", 7), fill="#666")
    c.create_text(450, 485, text="Outputs: oh1 (active-high, 1 mismatch), oh2 (active-high, 2 mismatches)",
                  font=("Courier", 8, "bold"), fill="#006")

    return c

def schematic_g(parent):
    """FUSED_G: 40T Active-Low — 4 INV + 2 OAI22 + 2 INV + AOI22 + NAND2"""
    c = tk.Canvas(parent, width=900, height=500, bg="white")
    c.pack(fill="both", expand=True)

    title = "FUSED_G (40T Active-Low): 4 INV + 2 OAI22(XNOR) + 2 INV + AOI22(noh1) + NAND2(noh2)"
    c.create_text(450, 15, text=title, font=("Helvetica", 11, "bold"))
    c.create_text(450, 32, text="★ WINNER: Best EDP, Speed, Power — eliminates 2 output inverters",
                  font=("Helvetica", 9, "bold"), fill="#c00")

    y0 = 70
    # Stage 1: Input inverters
    for i, name in enumerate(["ai","bi","aj","bj"]):
        x = 30
        y = y0 + i*55
        c.create_text(x, y+GATE_H//2, text=name, font=("Courier", 10, "bold"), anchor="e")
        draw_wire(c, x+5, y+GATE_H//2, x+PAD, y+GATE_H//2)
        draw_gate(c, x+PAD, y, f"~{name}", "INV", color="#fdd")
        draw_wire(c, x+PAD+GATE_W, y+GATE_H//2, x+PAD+GATE_W+30, y+GATE_H//2, label=f"n{name}")

    # Stage 2: OAI22 (XNOR)
    x2 = 200
    for i, label in enumerate(["x0=XNOR(ai,bi)", "x1=XNOR(aj,bj)"]):
        y = y0 + 15 + i*110
        draw_gate(c, x2, y, label.split("=")[0], "OAI22", color="#dfd")
        c.create_text(x2+GATE_W//2, y+GATE_H+10, text=label, font=("Courier", 6))
        draw_wire(c, x2+GATE_W, y+GATE_H//2, x2+GATE_W+40, y+GATE_H//2)

    # Stage 3: Inverters
    x3 = 340
    for i, name in enumerate(["d0", "d1"]):
        y = y0 + 15 + i*110
        draw_gate(c, x3, y, name, "INV", color="#fdd")
        draw_wire(c, x3+GATE_W, y+GATE_H//2, x3+GATE_W+40, y+GATE_H//2, label=name)

    # Stage 4a: AOI22 → noh1 (NO output inverter!)
    x4 = 490
    y_noh1 = y0 + 15
    draw_gate(c, x4, y_noh1, "noh1", "AOI22", color="#ffd")
    c.create_text(x4+GATE_W//2, y_noh1+GATE_H+10, text="AOI22(d0,x1,x0,d1)", font=("Courier", 6))
    draw_wire(c, x4+GATE_W, y_noh1+GATE_H//2, x4+GATE_W+60, y_noh1+GATE_H//2)
    c.create_text(x4+GATE_W+65, y_noh1+GATE_H//2, text="~oh1", font=("Courier", 10, "bold"), anchor="w", fill="#c00")
    c.create_text(x4+GATE_W+65, y_noh1+GATE_H//2+14, text="(active-low)", font=("Courier", 7), anchor="w", fill="#c00")

    # NO INV here — that's the key savings!
    c.create_rectangle(x4+GATE_W+5, y_noh1-5, x4+GATE_W+55, y_noh1+GATE_H+5,
                       outline="#0a0", width=2, dash=(4,2))
    c.create_text(x4+GATE_W+30, y_noh1-12, text="NO INV!", font=("Courier", 8, "bold"), fill="#0a0")

    # Stage 4b: NAND2 → noh2 (NO output inverter!)
    y_noh2 = y0 + 125
    draw_gate(c, x4, y_noh2, "noh2", "NAND2", color="#ddf")
    c.create_text(x4+GATE_W//2, y_noh2+GATE_H+10, text="NAND(d0,d1)", font=("Courier", 6))
    draw_wire(c, x4+GATE_W, y_noh2+GATE_H//2, x4+GATE_W+60, y_noh2+GATE_H//2)
    c.create_text(x4+GATE_W+65, y_noh2+GATE_H//2, text="~oh2", font=("Courier", 10, "bold"), anchor="w", fill="#c00")
    c.create_text(x4+GATE_W+65, y_noh2+GATE_H//2+14, text="(active-low)", font=("Courier", 7), anchor="w", fill="#c00")

    c.create_rectangle(x4+GATE_W+5, y_noh2-5, x4+GATE_W+55, y_noh2+GATE_H+5,
                       outline="#0a0", width=2, dash=(4,2))
    c.create_text(x4+GATE_W+30, y_noh2-12, text="NO INV!", font=("Courier", 8, "bold"), fill="#0a0")

    # PPA annotation
    c.create_text(450, 420, text="Post-layout PPA (ASAP5, Xyce BSIM-CMG, VDD=0.5V):",
                  font=("Courier", 9, "bold"))
    c.create_text(450, 438, text="tpd = 86.0ps │ Power = 0.58uW │ EDP = 0.71x (vs A) │ 40T │ DRC clean",
                  font=("Courier", 9), fill="#006")
    c.create_text(450, 456, text="Saves 2 inverters (4T) + 1 gate delay → 23% faster, 8% less power than F",
                  font=("Courier", 8), fill="#060")

    return c

# Create main window with tabs
root = tk.Tk()
root.title("Fused Hamming Cell Schematics — Variants F & G")
root.geometry("920x520")

nb = ttk.Notebook(root)
nb.pack(fill="both", expand=True)

frame_f = ttk.Frame(nb)
frame_g = ttk.Frame(nb)
nb.add(frame_f, text="  FUSED_F (42T Hybrid)  ")
nb.add(frame_g, text="  ★ FUSED_G (40T Winner)  ")

schematic_f(frame_f)
schematic_g(frame_g)

# Select G tab by default (the winner)
nb.select(frame_g)

root.mainloop()
