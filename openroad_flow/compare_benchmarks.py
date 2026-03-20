#!/usr/bin/env python3
"""Compare two OpenROAD benchmark CSV files (before/after).

Usage:
    python3 compare_benchmarks.py <before.csv> <after.csv> [--output comparison.txt]

Reads benchmark_results.csv files produced by benchmark_suite.tcl,
computes speedup ratios per stage, and highlights improvements/regressions.
"""

import argparse
import csv
import sys
from collections import defaultdict


def read_benchmark(path):
    """Read benchmark CSV into dict keyed by (design, stage)."""
    data = {}
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            key = (row["design"], row["stage"])
            data[key] = row
    return data


def safe_float(val, default=None):
    """Convert to float, returning default for N/A or invalid values."""
    if val is None or val.strip() in ("N/A", "see_report", ""):
        return default
    try:
        return float(val)
    except ValueError:
        return default


def compute_speedup(before_ms, after_ms):
    """Compute speedup ratio. >1.0 means faster (improvement)."""
    if before_ms is None or after_ms is None:
        return None
    if after_ms == 0:
        return float("inf") if before_ms > 0 else 1.0
    return before_ms / after_ms


def format_speedup(ratio):
    """Format speedup with improvement/regression indicator."""
    if ratio is None:
        return "N/A"
    if ratio > 1.05:
        return f"{ratio:.2f}x FASTER"
    elif ratio < 0.95:
        return f"{1/ratio:.2f}x SLOWER"
    else:
        return f"{ratio:.2f}x (same)"


def format_delta(before_val, after_val, lower_is_better=True):
    """Format a numeric delta with direction indicator."""
    if before_val is None or after_val is None:
        return "N/A"
    delta = after_val - before_val
    pct = (delta / abs(before_val) * 100) if before_val != 0 else 0
    if lower_is_better:
        tag = "BETTER" if delta < -0.01 else ("WORSE" if delta > 0.01 else "same")
    else:
        tag = "BETTER" if delta > 0.01 else ("WORSE" if delta < -0.01 else "same")
    return f"{delta:+.3f} ({pct:+.1f}%) {tag}"


def compare(before_path, after_path, output=None):
    before = read_benchmark(before_path)
    after = read_benchmark(after_path)

    # Collect all keys, preserving order
    all_keys = list(dict.fromkeys(list(before.keys()) + list(after.keys())))

    # Group by design
    designs = defaultdict(list)
    for key in all_keys:
        designs[key[0]].append(key[1])

    lines = []

    def emit(line=""):
        lines.append(line)

    emit("=" * 90)
    emit("  OpenROAD Benchmark Comparison")
    emit(f"  Before: {before_path}")
    emit(f"  After:  {after_path}")
    emit("=" * 90)

    for design, stages in designs.items():
        emit(f"\n  Design: {design}")
        emit("-" * 90)
        emit(f"  {'Stage':<22} {'Before(ms)':>10} {'After(ms)':>10} {'Speedup':>18}"
             f"  {'WNS delta':>22}")
        emit("-" * 90)

        total_before = 0
        total_after = 0
        improvements = 0
        regressions = 0

        for stage in stages:
            key = (design, stage)
            b = before.get(key, {})
            a = after.get(key, {})

            b_rt = safe_float(b.get("runtime_ms"))
            a_rt = safe_float(a.get("runtime_ms"))
            speedup = compute_speedup(b_rt, a_rt)

            b_wns = safe_float(b.get("WNS"))
            a_wns = safe_float(a.get("WNS"))
            wns_delta = format_delta(b_wns, a_wns, lower_is_better=False)

            if b_rt is not None:
                total_before += b_rt
            if a_rt is not None:
                total_after += a_rt

            if speedup is not None:
                if speedup > 1.05:
                    improvements += 1
                elif speedup < 0.95:
                    regressions += 1

            b_str = f"{b_rt:.0f}" if b_rt is not None else "N/A"
            a_str = f"{a_rt:.0f}" if a_rt is not None else "N/A"
            sp_str = format_speedup(speedup)

            # Highlight regressions with *** markers
            marker = ""
            if speedup is not None and speedup < 0.95:
                marker = " ***"
            elif speedup is not None and speedup > 1.05:
                marker = " +++"

            emit(f"  {stage:<22} {b_str:>10} {a_str:>10} {sp_str:>18}{marker}"
                 f"  {wns_delta:>22}")

        emit("-" * 90)
        overall = compute_speedup(total_before, total_after)
        emit(f"  {'TOTAL':<22} {total_before:>10.0f} {total_after:>10.0f}"
             f" {format_speedup(overall):>18}")

        emit(f"\n  Stages improved (>5% faster): {improvements}")
        emit(f"  Stages regressed (>5% slower): {regressions}")

        # Instance count comparison
        # Find final_sta row for this design
        final_key = (design, "final_sta")
        b_final = before.get(final_key, {})
        a_final = after.get(final_key, {})
        b_inst = safe_float(b_final.get("instances"))
        a_inst = safe_float(a_final.get("instances"))
        if b_inst and a_inst:
            emit(f"  Instance count: {b_inst:.0f} -> {a_inst:.0f}"
                 f" ({a_inst - b_inst:+.0f})")

        b_drc = safe_float(b_final.get("DRC"))
        a_drc = safe_float(a_final.get("DRC"))
        if b_drc is not None and a_drc is not None:
            emit(f"  DRC violations: {b_drc:.0f} -> {a_drc:.0f}"
                 f" ({a_drc - b_drc:+.0f})")

        b_area = safe_float(b_final.get("area"))
        a_area = safe_float(a_final.get("area"))
        if b_area is not None and a_area is not None:
            emit(f"  Area: {b_area:.1f} -> {a_area:.1f}"
                 f" ({(a_area - b_area) / b_area * 100:+.1f}%)")

        b_mem = safe_float(b_final.get("peak_mem_mb"))
        a_mem = safe_float(a_final.get("peak_mem_mb"))
        if b_mem is not None and a_mem is not None:
            emit(f"  Peak memory: {b_mem:.1f} MB -> {a_mem:.1f} MB"
                 f" ({(a_mem - b_mem) / b_mem * 100:+.1f}%)")

    emit("\n" + "=" * 90)
    emit("  Legend: +++ improvement  *** regression  (threshold: 5%)")
    emit("=" * 90)

    report = "\n".join(lines)
    print(report)

    if output:
        with open(output, "w") as f:
            f.write(report + "\n")
        print(f"\nComparison written to: {output}")


def main():
    parser = argparse.ArgumentParser(
        description="Compare two OpenROAD benchmark CSV files")
    parser.add_argument("before", help="Path to baseline benchmark CSV")
    parser.add_argument("after", help="Path to new benchmark CSV")
    parser.add_argument("-o", "--output",
                        help="Write comparison report to this file")
    args = parser.parse_args()

    try:
        compare(args.before, args.after, args.output)
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
