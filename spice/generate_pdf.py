#!/usr/bin/env python3
"""Generate PDF of TSMC N5 FinFET BSIM-CMG device characteristics."""

import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages

def load_dat(path):
    """Load ngspice wrdata output (2-column: sweep, value)."""
    data = np.loadtxt(path)
    return data[:, 0], data[:, 1]

def load_family(path, n_curves):
    """Load ngspice wrdata multi-sweep output."""
    data = np.loadtxt(path)
    x = data[:, 0]
    y = data[:, 1]
    # Find where x resets (new curve)
    splits = [0]
    for i in range(1, len(x)):
        if abs(x[i]) < abs(x[i-1]) - 0.003:
            splits.append(i)
    splits.append(len(x))
    curves = []
    for i in range(len(splits)-1):
        curves.append((x[splits[i]:splits[i+1]], y[splits[i]:splits[i+1]]))
    return curves

pdf_path = '/Users/bruce/CLAUDE/spice/tsmc_n5_finfet_characteristics.pdf'

with PdfPages(pdf_path) as pdf:
    # =========================================================================
    # Page 1: Title
    # =========================================================================
    fig = plt.figure(figsize=(11, 8.5))
    fig.text(0.5, 0.6, 'TSMC N5 FinFET Device Characteristics',
             ha='center', va='center', fontsize=24, fontweight='bold')
    fig.text(0.5, 0.48, 'BSIM-CMG Compact Model (OSDI / OpenVAF-Reloaded)',
             ha='center', va='center', fontsize=16, color='#444444')
    fig.text(0.5, 0.38, 'ngspice-45.2 + BSIM-CMG vacode110',
             ha='center', va='center', fontsize=14, color='#666666')
    fig.text(0.5, 0.28, 'Single-fin (NF=1), TT corner, T=25\u00b0C',
             ha='center', va='center', fontsize=13, color='#666666')
    fig.text(0.5, 0.15, 'March 2026',
             ha='center', va='center', fontsize=12, color='#888888')
    pdf.savefig(fig)
    plt.close()

    # =========================================================================
    # Page 2: NMOS Id vs Vgs (linear + log)
    # =========================================================================
    fig, axes = plt.subplots(1, 2, figsize=(11, 5.5))
    fig.suptitle('NMOS Id vs Vgs (Single Fin)', fontsize=14, fontweight='bold')

    vgs_075, ids_075 = load_dat('/tmp/sim_nmos_idvgs_075.dat')
    vgs_040, ids_040 = load_dat('/tmp/sim_nmos_idvgs_040.dat')

    # Linear scale
    ax = axes[0]
    ax.plot(vgs_075, ids_075 * 1e6, 'b-', linewidth=1.5, label='Vds=0.75V')
    ax.plot(vgs_040, ids_040 * 1e6, 'r--', linewidth=1.5, label='Vds=0.40V')
    ax.set_xlabel('Vgs (V)')
    ax.set_ylabel('Id (\u00b5A/fin)')
    ax.set_title('Linear Scale')
    ax.legend()
    ax.grid(True, alpha=0.3)

    # Log scale
    ax = axes[1]
    ax.semilogy(vgs_075, np.abs(ids_075), 'b-', linewidth=1.5, label='Vds=0.75V')
    ax.semilogy(vgs_040, np.abs(ids_040), 'r--', linewidth=1.5, label='Vds=0.40V')
    ax.set_xlabel('Vgs (V)')
    ax.set_ylabel('|Id| (A/fin)')
    ax.set_title('Log Scale')
    ax.legend()
    ax.grid(True, alpha=0.3, which='both')
    ax.set_ylim(bottom=1e-14)

    plt.tight_layout()
    pdf.savefig(fig)
    plt.close()

    # =========================================================================
    # Page 3: NMOS Id vs Vds (family curves)
    # =========================================================================
    fig, ax = plt.subplots(1, 1, figsize=(8, 5.5))
    fig.suptitle('NMOS Id vs Vds Family Curves (Single Fin)', fontsize=14, fontweight='bold')

    curves = load_family('/tmp/sim_nmos_idvds.dat', 10)
    vgs_vals = np.arange(0.3, 0.76, 0.05)
    colors = plt.cm.viridis(np.linspace(0.2, 0.9, len(curves)))
    for i, (vds, ids) in enumerate(curves):
        vg = vgs_vals[i] if i < len(vgs_vals) else 0.75
        ax.plot(vds, ids * 1e6, color=colors[i], linewidth=1.2,
                label=f'Vgs={vg:.2f}V')

    ax.set_xlabel('Vds (V)')
    ax.set_ylabel('Id (\u00b5A/fin)')
    ax.legend(fontsize=8, ncol=2)
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    pdf.savefig(fig)
    plt.close()

    # =========================================================================
    # Page 4: PMOS Id vs Vgs (linear + log)
    # =========================================================================
    fig, axes = plt.subplots(1, 2, figsize=(11, 5.5))
    fig.suptitle('PMOS Id vs Vgs (Single Fin)', fontsize=14, fontweight='bold')

    vgs_075, ids_075 = load_dat('/tmp/sim_pmos_idvgs_075.dat')
    vgs_040, ids_040 = load_dat('/tmp/sim_pmos_idvgs_040.dat')

    # Linear scale
    ax = axes[0]
    ax.plot(vgs_075, np.abs(ids_075) * 1e6, 'b-', linewidth=1.5, label='|Vds|=0.75V')
    ax.plot(vgs_040, np.abs(ids_040) * 1e6, 'r--', linewidth=1.5, label='|Vds|=0.40V')
    ax.set_xlabel('Vgs (V)')
    ax.set_ylabel('|Id| (\u00b5A/fin)')
    ax.set_title('Linear Scale')
    ax.legend()
    ax.grid(True, alpha=0.3)

    # Log scale
    ax = axes[1]
    ids_075_abs = np.maximum(np.abs(ids_075), 1e-15)
    ids_040_abs = np.maximum(np.abs(ids_040), 1e-15)
    ax.semilogy(vgs_075, ids_075_abs, 'b-', linewidth=1.5, label='|Vds|=0.75V')
    ax.semilogy(vgs_040, ids_040_abs, 'r--', linewidth=1.5, label='|Vds|=0.40V')
    ax.set_xlabel('Vgs (V)')
    ax.set_ylabel('|Id| (A/fin)')
    ax.set_title('Log Scale')
    ax.legend()
    ax.grid(True, alpha=0.3, which='both')
    ax.set_ylim(bottom=1e-14)

    plt.tight_layout()
    pdf.savefig(fig)
    plt.close()

    # =========================================================================
    # Page 5: PMOS Id vs Vds (family curves)
    # =========================================================================
    fig, ax = plt.subplots(1, 1, figsize=(8, 5.5))
    fig.suptitle('PMOS Id vs Vds Family Curves (Single Fin)', fontsize=14, fontweight='bold')

    curves = load_family('/tmp/sim_pmos_idvds.dat', 10)
    vgs_vals = np.arange(-0.3, -0.76, -0.05)
    colors = plt.cm.magma(np.linspace(0.2, 0.9, len(curves)))
    for i, (vds, ids) in enumerate(curves):
        vg = vgs_vals[i] if i < len(vgs_vals) else -0.75
        ax.plot(vds, np.abs(ids) * 1e6, color=colors[i], linewidth=1.2,
                label=f'Vgs={vg:.2f}V')

    ax.set_xlabel('Vds (V)')
    ax.set_ylabel('|Id| (\u00b5A/fin)')
    ax.legend(fontsize=8, ncol=2)
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    pdf.savefig(fig)
    plt.close()

    # =========================================================================
    # Page 6: NMOS Capacitances vs Vgs
    # =========================================================================
    fig, ax = plt.subplots(1, 1, figsize=(8, 5.5))
    fig.suptitle('NMOS Capacitance vs Vgs (Single Fin)', fontsize=14, fontweight='bold')

    vgs_cg, cg = load_dat('/tmp/sim_nmos_cg.dat')
    vgs_cgs, cgs = load_dat('/tmp/sim_nmos_cgs.dat')
    vgs_cgd, cgd = load_dat('/tmp/sim_nmos_cgd.dat')

    ax.plot(vgs_cg, np.abs(cg) * 1e15, 'b-o', linewidth=1.5, markersize=3, label='Cgg')
    ax.plot(vgs_cgs, np.abs(cgs) * 1e15, 'r-s', linewidth=1.5, markersize=3, label='Cgs')
    ax.plot(vgs_cgd, np.abs(cgd) * 1e15, 'g-^', linewidth=1.5, markersize=3, label='Cgd')
    ax.set_xlabel('Vgs (V)')
    ax.set_ylabel('Capacitance (fF/fin)')
    ax.legend()
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    pdf.savefig(fig)
    plt.close()

    # =========================================================================
    # Page 7: PMOS Capacitances vs Vgs
    # =========================================================================
    fig, ax = plt.subplots(1, 1, figsize=(8, 5.5))
    fig.suptitle('PMOS Capacitance vs Vgs (Single Fin)', fontsize=14, fontweight='bold')

    vgs_cg, cg = load_dat('/tmp/sim_pmos_cg.dat')
    vgs_cgs, cgs = load_dat('/tmp/sim_pmos_cgs.dat')
    vgs_cgd, cgd = load_dat('/tmp/sim_pmos_cgd.dat')

    ax.plot(vgs_cg, np.abs(cg) * 1e15, 'b-o', linewidth=1.5, markersize=3, label='Cgg')
    ax.plot(vgs_cgs, np.abs(cgs) * 1e15, 'r-s', linewidth=1.5, markersize=3, label='Cgs')
    ax.plot(vgs_cgd, np.abs(cgd) * 1e15, 'g-^', linewidth=1.5, markersize=3, label='Cgd')
    ax.set_xlabel('Vgs (V)')
    ax.set_ylabel('Capacitance (fF/fin)')
    ax.legend()
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    pdf.savefig(fig)
    plt.close()

    # =========================================================================
    # Page 8: Summary table
    # =========================================================================
    fig = plt.figure(figsize=(11, 8.5))
    fig.text(0.5, 0.92, 'TSMC N5 FinFET -- Key Metrics Summary',
             ha='center', fontsize=16, fontweight='bold')

    # Extract key metrics from data
    vgs_n, ids_n = load_dat('/tmp/sim_nmos_idvgs_075.dat')
    id_on_n = ids_n[-1]  # at Vgs=Vdd
    id_off_n = ids_n[0]  # at Vgs=0

    vgs_n40, ids_n40 = load_dat('/tmp/sim_nmos_idvgs_040.dat')
    id_on_n40 = ids_n40[-1]

    vgs_p, ids_p = load_dat('/tmp/sim_pmos_idvgs_075.dat')
    id_on_p = abs(ids_p[-1])
    id_off_p = abs(ids_p[0])

    vgs_p40, ids_p40 = load_dat('/tmp/sim_pmos_idvgs_040.dat')
    id_on_p40 = abs(ids_p40[-1])

    _, cg_n = load_dat('/tmp/sim_nmos_cg.dat')
    _, cgs_n = load_dat('/tmp/sim_nmos_cgs.dat')
    _, cgd_n = load_dat('/tmp/sim_nmos_cgd.dat')
    mid = len(cg_n) // 2

    _, cg_p = load_dat('/tmp/sim_pmos_cg.dat')
    _, cgs_p = load_dat('/tmp/sim_pmos_cgs.dat')
    _, cgd_p = load_dat('/tmp/sim_pmos_cgd.dat')

    table_data = [
        ['Parameter', 'NMOS', 'PMOS', 'Unit'],
        ['Id_on @0.75V', f'{id_on_n*1e6:.1f}', f'{id_on_p*1e6:.1f}', '\u00b5A/fin'],
        ['Id_on @0.40V', f'{id_on_n40*1e6:.1f}', f'{id_on_p40*1e6:.1f}', '\u00b5A/fin'],
        ['Id_off @0.75V', f'{id_off_n*1e9:.1f}', f'{id_off_p*1e9:.1f}', 'nA/fin'],
        ['Ion/Ioff @0.75V', f'{id_on_n/id_off_n:.0f}', f'{id_on_p/id_off_p:.0f}', ''],
        ['Cgg (mid-bias)', f'{abs(cg_n[mid])*1e15:.3f}', f'{abs(cg_p[mid])*1e15:.3f}', 'fF/fin'],
        ['Cgs (mid-bias)', f'{abs(cgs_n[mid])*1e15:.3f}', f'{abs(cgs_p[mid])*1e15:.3f}', 'fF/fin'],
        ['Cgd (mid-bias)', f'{abs(cgd_n[mid])*1e15:.3f}', f'{abs(cgd_p[mid])*1e15:.3f}', 'fF/fin'],
    ]

    ax = fig.add_subplot(111)
    ax.axis('off')
    table = ax.table(cellText=table_data[1:], colLabels=table_data[0],
                     cellLoc='center', loc='center')
    table.auto_set_font_size(False)
    table.set_fontsize(12)
    table.scale(1.0, 2.0)
    for (row, col), cell in table.get_celld().items():
        if row == 0:
            cell.set_facecolor('#4472C4')
            cell.set_text_props(color='white', fontweight='bold')
        elif row % 2 == 0:
            cell.set_facecolor('#D9E2F3')

    fig.text(0.5, 0.12, 'Model: BSIM-CMG vacode110 | Process: TSMC N5 5nm FinFET | Corner: TT | T=25\u00b0C',
             ha='center', fontsize=10, color='#666666')
    pdf.savefig(fig)
    plt.close()

print(f'PDF saved to: {pdf_path}')
