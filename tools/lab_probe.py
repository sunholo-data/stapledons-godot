#!/usr/bin/env python3
"""R3-UNIVERSE-LAB UL0a: time the lab's detector-free probes on the pinned runtime.

Role: harness (tools/python-allowlist.txt). It runs the pure entries of
sim/tools/lab_probe.ail as child processes, times them from outside (the sim has
no clock), checks that every repeat prints the same line, and writes
data/lab/probe.json. No probe logic lives here.

Method. Each probe is run at a base size and at a full size, `--runs` times,
one process at a time. The reported cost is full minus base, so process start
and compilation are not counted. CPU seconds are the child's user + system time
from wait4; wall seconds are also kept. The 1-minute load average is recorded
before every timing, because the host is shared. Budgets are judged on CPU
time (design: "budgets use CPU time and record the load"), except shard
scaling, which is wall-clock throughput by definition.

A failed budget does not fail this command: it is a stop for the owner (sprint
plan, pause 1), printed on the last line and recorded in the file. Differing
values, a VM/interpreter mismatch or a wrong quadrature value do fail it.
"""
import argparse
import json
import math
import os
import platform
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODULE = "sim/tools/lab_probe.ail"


def ailang():
    a = os.environ.get("AILANG", "ailang")
    return os.path.abspath(a) if "/" in a else a


def command(entry, size, vm=True):
    flags = ["--bytecode", "--strict-bytecode"] if vm else []
    return [ailang(), "run", "--quiet", *flags, "--package-dir", "sim", "--entry", entry, "--args-json", str(size), MODULE]


def start(entry, size, vm=True):
    return subprocess.Popen(command(entry, size, vm), cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def finish(proc):
    """Wait for one child: its output, CPU seconds and peak resident memory."""
    out, err = proc.stdout.read(), proc.stderr.read()
    _, status, ru = os.wait4(proc.pid, 0)
    proc.returncode = os.waitstatus_to_exitcode(status)
    if proc.returncode != 0:
        sys.exit("lab-probe: FAIL %s exited %d: %s" % (" ".join(proc.args), proc.returncode, err.decode()[-400:]))
    rss = ru.ru_maxrss / (1024.0 * 1024.0) if sys.platform == "darwin" else ru.ru_maxrss / 1024.0
    return out.decode().strip(), ru.ru_utime + ru.ru_stime, rss


def timed(entry, size, vm=True):
    load = os.getloadavg()[0]
    t0 = time.perf_counter()
    out, cpu, rss = finish(start(entry, size, vm))
    return {"value": out, "wall_s": time.perf_counter() - t0, "cpu_s": cpu, "peak_rss_mb": rss, "load1": load}


def stats(xs):
    return {"mean": sum(xs) / len(xs), "min": min(xs), "max": max(xs)}


def same(values, what):
    if len(set(values)) != 1:
        sys.exit("lab-probe: FAIL %s: values differ across runs: %s" % (what, sorted(set(values))))
    return values[0]


def probe(entry, base, full, runs):
    """Full size minus base size, `runs` times, sequentially."""
    rows = []
    for _ in range(runs):
        b, f = timed(entry, base), timed(entry, full)
        rows.append({"load1": f["load1"], "base_wall_s": b["wall_s"], "base_cpu_s": b["cpu_s"], "wall_s": f["wall_s"],
                     "cpu_s": f["cpu_s"], "peak_rss_mb": f["peak_rss_mb"], "value": f["value"], "base_value": b["value"]})
    same([r["base_value"] for r in rows], "%s(%s)" % (entry, base))
    value = same([r["value"] for r in rows], "%s(%s)" % (entry, full))
    for r in rows:
        del r["value"], r["base_value"]
    return {"entry": entry, "base_size": base, "size": full, "value": value, "runs": rows,
            "work_cpu_s": stats([r["cpu_s"] - r["base_cpu_s"] for r in rows]),
            "work_wall_s": stats([r["wall_s"] - r["base_wall_s"] for r in rows]),
            "load1": stats([r["load1"] for r in rows])}


def scaling(size, counts, runs):
    """k processes of the draw loop at once; throughput is k / wall, relative to one process."""
    rows = []
    for k in counts:
        for _ in range(runs):
            load = os.getloadavg()[0]
            t0 = time.perf_counter()
            procs = [start("draws", size) for _ in range(k)]
            done = [finish(p) for p in procs]
            wall = time.perf_counter() - t0
            same([d[0] for d in done], "draws(%d) x %d processes" % (size, k))
            rows.append({"processes": k, "wall_s": wall, "cpu_s_per_process": sum(d[1] for d in done) / k, "load1": load})
    out = []
    one = stats([r["wall_s"] for r in rows if r["processes"] == 1])
    for k in counts:
        mine = [r for r in rows if r["processes"] == k]
        wall = stats([r["wall_s"] for r in mine])
        out.append({"processes": k, "runs": mine, "wall_s": wall, "load1": stats([r["load1"] for r in mine]),
                    "cpu_s_per_process": stats([r["cpu_s_per_process"] for r in mine]),
                    # mean against mean, and the spread from the best and worst pairings
                    "throughput_x": {"mean": k * one["mean"] / wall["mean"], "min": k * one["min"] / wall["max"],
                                     "max": k * one["max"] / wall["min"]}})
    return {"entry": "draws", "size": size, "by_processes": out}


def field(line, key):
    for part in line.split():
        if part.startswith(key + "="):
            return part[len(key) + 1:]
    sys.exit("lab-probe: FAIL no %s= in %r" % (key, line))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="data/lab/probe.json")
    ap.add_argument("--runs", type=int, default=3)
    a = ap.parse_args()
    if a.runs < 3:
        sys.exit("lab-probe: --runs must be at least 3")
    version = subprocess.run([ailang(), "--version"], cwd=ROOT, capture_output=True, text=True).stdout.split("\n")[0].strip()
    load_start = os.getloadavg()

    # VM = interpreter on the draw loop (and, cheaply, on the other two float probes).
    parity = {}
    for entry, size in (("draws", 2000), ("quadrature", 64), ("intervals", 2)):
        vm, interp = timed(entry, size, True)["value"], timed(entry, size, False)["value"]
        if vm != interp:
            sys.exit("lab-probe: FAIL %s(%d): strict VM %r != interpreter %r" % (entry, size, vm, interp))
        parity["%s(%d)" % (entry, size)] = "strict VM = interpreter, %d bytes" % len(vm)

    draws_n, reps, passes = 100000, 400, 8
    draws = probe("draws", 0, draws_n, a.runs)
    quads = [probe("quadrature", 1, n, a.runs) for n in (256, 512, 1024)]
    intervals = probe("intervals", 0, reps, a.runs)
    filt = probe("filter", 0, passes, a.runs)
    shards = scaling(draws_n, (1, 4, 8, 12), a.runs)

    # The quadrature is checked, not only timed: it must approach the closed form as h^2.
    errs = [abs(float(field(q["value"], "err"))) for q in quads]
    exact = float(field(quads[0]["value"], "exact"))
    if not (math.isclose(exact, (1.3 ** 4 - 4 * 0.3 ** 4) / 24.0, rel_tol=1e-12) and errs[0] < 1e-6 and errs[2] < errs[1] < errs[0]):
        sys.exit("lab-probe: FAIL quadrature: errors %s against the closed form %r" % (errs, exact))

    us = lambda s: {k: 1e6 * v / draws_n for k, v in s.items()}
    per_draw_cpu, per_draw_wall = us(draws["work_cpu_s"]), us(draws["work_wall_s"])
    draws["derived"] = {"cpu_us_per_draw": per_draw_cpu, "wall_us_per_draw": per_draw_wall,
                        "draws_per_cpu_second": 1e6 / per_draw_cpu["mean"],
                        "cpu_s_for_10000_draws": {k: v / 100.0 for k, v in per_draw_cpu.items()},
                        "wall_s_for_10000_draws": {k: v / 100.0 for k, v in per_draw_wall.items()}}
    for q in quads:
        q["derived"] = {"evaluations": q["size"] ** 2, "abs_error": abs(float(field(q["value"], "err")))}
    intervals["derived"] = {"cpu_ms_per_1024_rows_3_intervals": {k: 1e3 * v / reps for k, v in intervals["work_cpu_s"].items()}}
    filt["derived"] = {"rows": 500000, "build_cpu_s": stats([r["base_cpu_s"] for r in filt["runs"]]),
                       "cpu_s_per_pass": {k: v / passes for k, v in filt["work_cpu_s"].items()},
                       "peak_rss_mb": stats([r["peak_rss_mb"] for r in filt["runs"]])}

    t12 = [s for s in shards["by_processes"] if s["processes"] == 12][0]["throughput_x"]
    budgets = [
        {"name": "new-game draw loop at p = 1e-4", "design": "above 1 s is a stop (sprint plan, pause 1); 1/p = 10,000 draws",
         "measured_cpu_s": draws["derived"]["cpu_s_for_10000_draws"]["mean"], "worst_run_cpu_s": draws["derived"]["cpu_s_for_10000_draws"]["max"],
         "measured_wall_s": draws["derived"]["wall_s_for_10000_draws"]["mean"], "limit_s": 1.0,
         "pass": draws["derived"]["cpu_s_for_10000_draws"]["max"] <= 1.0},
        {"name": "12 shards against one", "design": "less than 6 times one is a stop (sprint plan, pause 1)",
         "measured_x": t12["mean"], "worst_pairing_x": t12["min"], "limit_x": 6.0, "pass": t12["mean"] >= 6.0},
    ]
    doc = {"schema": "lab-probe-1", "run": "R3-UNIVERSE-LAB UL0a", "ailang": version,
           "host": {"logical_cpus": os.cpu_count(), "machine": platform.machine(), "system": platform.system()},
           "runs_each": a.runs, "load_average_at_start": list(load_start), "load_average_at_end": list(os.getloadavg()),
           "method": "full size minus base size per run, one process at a time; CPU = child user + system (wait4); "
                     "every probe is a stand-in for a module not yet written (see sim/tools/lab_probe.ail)",
           "parity": parity, "probes": {"draws": draws, "quadrature": quads, "intervals": intervals, "filter": filt},
           "scaling": shards, "budgets": budgets}
    out = os.path.join(ROOT, a.out)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w") as f:
        json.dump(doc, f, indent=1, sort_keys=True)
        f.write("\n")

    print("lab-probe: %s; load average %.1f at start, %.1f at end; %d runs each" % (version, load_start[0], os.getloadavg()[0], a.runs))
    print("lab-probe: draws %.1f us CPU per draw (%.1f to %.1f), %.0f draws per CPU second; 10,000 draws %.3f s CPU, %.3f s wall" % (
        per_draw_cpu["mean"], per_draw_cpu["min"], per_draw_cpu["max"], draws["derived"]["draws_per_cpu_second"],
        budgets[0]["measured_cpu_s"], budgets[0]["measured_wall_s"]))
    for q in quads:
        print("lab-probe: quadrature %4d x %-4d %.3f s CPU (%.3f to %.3f), |error| %.2e" % (
            q["size"], q["size"], q["work_cpu_s"]["mean"], q["work_cpu_s"]["min"], q["work_cpu_s"]["max"], q["derived"]["abs_error"]))
    iv = intervals["derived"]["cpu_ms_per_1024_rows_3_intervals"]
    print("lab-probe: intervals %.3f ms CPU per 1,024-row sample, three intervals (%.3f to %.3f)" % (iv["mean"], iv["min"], iv["max"]))
    fd = filt["derived"]
    print("lab-probe: filter 500,000 rows: %.3f s CPU per pass (%.3f to %.3f); build %.2f s CPU; peak %.0f MB" % (
        fd["cpu_s_per_pass"]["mean"], fd["cpu_s_per_pass"]["min"], fd["cpu_s_per_pass"]["max"], fd["build_cpu_s"]["mean"], fd["peak_rss_mb"]["max"]))
    for s in shards["by_processes"]:
        print("lab-probe: %2d processes: wall %.2f s (%.2f to %.2f), %.2f CPU s each, throughput %.2fx one (load %.1f)" % (
            s["processes"], s["wall_s"]["mean"], s["wall_s"]["min"], s["wall_s"]["max"], s["cpu_s_per_process"]["mean"],
            s["throughput_x"]["mean"], s["load1"]["mean"]))
    print("lab-probe: values identical across runs; %s" % "; ".join("%s %s" % kv for kv in sorted(parity.items())))
    print("lab-probe: wrote %s; budgets: %s" % (a.out, "; ".join("%s %s" % (b["name"], "PASS" if b["pass"] else "FAIL (a stop for the owner)") for b in budgets)))


if __name__ == "__main__":
    main()
