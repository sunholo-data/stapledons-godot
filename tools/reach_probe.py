#!/usr/bin/env python3
"""R3-REACH RE0: time sim/tools/reach_probe.ail from outside and record the evidence.

Harness only (tools/python-allowlist.txt): every number under test is computed by AILANG.
This script starts the processes one at a time, reads each child's wall time, CPU time
(user + system, which includes the runtime's GC threads) and peak RSS from wait4, notes
the load average when each starts, and checks that counts repeat exactly.

  tools/reach_probe.py vm --out data/reach/probe.json        (make reach-probe)
  tools/reach_probe.py io --out data/reach/probe_io.json     (make reach-probe-io)

One pass of a probe costs (cost at K passes - cost at 0 passes) / K, both taken in the
same run, so start-up, compilation and input parsing cancel.
"""
import argparse, hashlib, json, os, platform, statistics, subprocess, sys, time

PROBE = "sim/tools/reach_probe.ail"
PLANETS = "data/planets/exoplanets.json"
EXPECT_ROWS = {"rows59": 1900, "rows168": 43887, "rows100pc": 302239}


def child(cmd):
    """Run one process; return its stdout and what the kernel says it cost."""
    load = os.getloadavg()[0]
    t0 = time.monotonic()
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    out = p.stdout.read().decode()
    _, status, ru = os.wait4(p.pid, 0)
    wall = time.monotonic() - t0
    p.returncode = os.waitstatus_to_exitcode(status)
    if p.returncode != 0 or "FAIL" in out:
        sys.exit(f"reach-probe: FAIL {' '.join(cmd[:12])} ...\n{out[-2000:]}")
    rss = ru.ru_maxrss if sys.platform == "darwin" else ru.ru_maxrss * 1024  # bytes on macOS, kB on Linux
    return out.strip(), {"wall_s": round(wall, 3), "cpu_s": round(ru.ru_utime + ru.ru_stime, 3),
                         "peak_rss_mb": round(rss / 1e6, 1), "load1": round(load, 1)}


def ail(a, entry, args, bytecode=True):
    vm = ["--bytecode"] if bytecode else []
    # env -u AI_LIVE: the entry is a variable, so make ai-live-guard wants AI_LIVE cleared here.
    cmd = ["env", "-u", "AI_LIVE", a.ailang, "run", "--quiet", *vm, "--caps", "IO,FS", "--package-dir", "sim", "--entry", entry, "--args-json", json.dumps(args), PROBE]
    return child(cmd)


def spread(xs):
    return {"mean": round(statistics.mean(xs), 9), "min": round(min(xs), 9), "max": round(max(xs), 9)}


def per_pass(base, more, k, unit=1.0):
    """Cost of one pass in each run, and its spread, from paired (K=0, K=k) processes."""
    return {"passes": k, "runs": len(base),
            "cpu_s": spread([(m["cpu_s"] - b["cpu_s"]) / k * unit for b, m in zip(base, more)]),
            "wall_s": spread([(m["wall_s"] - b["wall_s"]) / k * unit for b, m in zip(base, more)]),
            "load1": [m["load1"] for m in more],
            "peak_rss_mb": max(m["peak_rss_mb"] for m in more),
            "raw": [{"base": b, "probe": m} for b, m in zip(base, more)]}


def machine(a):
    version = subprocess.run([a.ailang, "--version"], capture_output=True, text=True).stdout.splitlines()[0]
    prompt = subprocess.run([a.ailang, "prompt", "--version-active"], capture_output=True, text=True).stdout.strip()
    return {"ailang": version, "ailang_prompt": prompt, "cores": os.cpu_count(), "platform": platform.platform(),
            "machine": platform.machine(), "date_utc": time.strftime("%Y-%m-%dT%H:%MZ", time.gmtime()),
            "load_at_start": [round(x, 1) for x in os.getloadavg()]}


def prepare(a):
    s = a.scratch
    paths = {"csv168": f"{s}/gcns168.csv", "csv100": f"{s}/gcns100pc.csv",
             "packed168": f"{s}/gate168.f64", "packed100": f"{s}/gate100pc.f64"}
    cost = None
    if not all(os.path.exists(p) for p in paths.values()):
        os.makedirs(s, exist_ok=True)
        out, cost = ail(a, "prepareMain", {"csv": a.csv, "planets": PLANETS, **paths})
        print(f"reach-probe: prepared slices {out} cpu {cost['cpu_s']} s", flush=True)
    return paths, cost


def vm(a):
    paths, prep = prepare(a)
    seed = a.seed
    zero = {"kSystem": 0, "kGate168": 0, "kGate100": 0, "kRare1": 0, "kRare10": 0, "check": False}
    main = lambda csv, **k: ail(a, "main", {"csv": csv, "planets": PLANETS, "seed": seed, **zero, **k})
    # (name, base call, probe call, passes): every process runs alone, in this order, in every run.
    K = {"draw": 4000000, "system59": 3, "gate168": 20, "rare1x": 5, "rare10x": 5, "gate100pc": 5, "packed168": 50, "packed100pc": 10}
    plan = [
        ("draw", lambda: ail(a, "drawMain", {"seed": seed, "n": 0}), lambda: ail(a, "drawMain", {"seed": seed, "n": K["draw"]})),
        ("system59", "base168", lambda: main(paths["csv168"], kSystem=K["system59"])),
        ("gate168", "base168", lambda: main(paths["csv168"], kGate168=K["gate168"])),
        ("rare1x", "base168", lambda: main(paths["csv168"], kRare1=K["rare1x"])),
        ("rare10x", "base168", lambda: main(paths["csv168"], kRare10=K["rare10x"])),
        ("gate100pc", "base100", lambda: main(paths["csv100"], kGate100=K["gate100pc"])),
        ("packed168", lambda: ail(a, "packedMain", {"packed": paths["packed168"], "seed": seed, "k": 0}),
         lambda: ail(a, "packedMain", {"packed": paths["packed168"], "seed": seed, "k": K["packed168"]})),
        ("packed100pc", lambda: ail(a, "packedMain", {"packed": paths["packed100"], "seed": seed, "k": 0}),
         lambda: ail(a, "packedMain", {"packed": paths["packed100"], "seed": seed, "k": K["packed100pc"]})),
    ]
    shared = {"base168": lambda: main(paths["csv168"]), "base100": lambda: main(paths["csv100"])}
    ail(a, "drawMain", {"seed": seed, "n": 0})  # warm the compile cache, so no run's base pays a cold start
    base, more, outputs = {}, {}, []
    for run in range(a.runs):
        bases, texts = {}, {}
        for name, b, probe in plan:
            if isinstance(b, str):
                if b not in bases:
                    bases[b] = shared[b]()
                    texts[b] = bases[b][0]
                bcost = bases[b][1]
            else:
                btext, bcost = b()
                texts[name + ".base"] = btext
            text, cost = probe()
            texts[name] = text
            base.setdefault(name, []).append(bcost)
            more.setdefault(name, []).append(cost)
            print(f"reach-probe: run {run + 1}/{a.runs} {name}: cpu {cost['cpu_s']} s (base {bcost['cpu_s']} s), load {cost['load1']}", flush=True)
        outputs.append(texts)
    if any(o != outputs[0] for o in outputs):
        sys.exit("reach-probe: FAIL outputs differ between runs")
    counts = {k: (json.loads(v) if v.startswith("{") else v) for k, v in outputs[0].items()}
    rows = {**{k: counts["base168"][k] for k in ("rows59", "rows168")}, "rows100pc": counts["base100"]["rows100pc"]}
    if rows != EXPECT_ROWS:
        sys.exit(f"reach-probe: FAIL row counts {rows}, expected {EXPECT_ROWS}")
    if counts["packed168"]["rows"] > rows["rows168"] or counts["packed100pc"]["rows"] > rows["rows100pc"]:
        sys.exit("reach-probe: FAIL a packed array has more rows than its slice")

    # VM = interpreter on a 5,000-row subset (the first 5,000 rows of the 168 ly slice), every probe once.
    sub = f"{a.scratch}/gcns-subset.csv"
    with open(paths["csv168"]) as f, open(sub, "w") as g:
        g.writelines(f.readlines()[:5001])
    one = {"kSystem": 1, "kGate168": 1, "kGate100": 1, "kRare1": 1, "kRare10": 1, "check": True}
    vm_text, vm_cost = ail(a, "main", {"csv": sub, "planets": PLANETS, "seed": seed, **one})
    in_text, in_cost = ail(a, "main", {"csv": sub, "planets": PLANETS, "seed": seed, **one}, bytecode=False)
    parity = json.loads(vm_text)
    if vm_text != in_text or parity["gateAgrees"] is not True or parity["rows168"] != 5000:
        sys.exit(f"reach-probe: FAIL VM and interpreter differ on the subset, or the gate mirror disagrees\n{vm_text}\n{in_text}")

    t = {name: per_pass(base[name], more[name], K[name]) for name in K}
    draw_us = t["draw"]["cpu_s"]["mean"] * 1e6
    one_pass = lambda n: t[n]["cpu_s"]["mean"]
    worst = lambda n: t[n]["cpu_s"]["max"]
    budget = lambda label, value, worst_v, limit, basis: {
        "query": label, "cpu_s_mean": round(value, 4), "cpu_s_worst_run": round(worst_v, 4), "budget_s": limit,
        "pass": None if limit is None else bool(worst_v <= limit), "basis": basis}
    report = {
        "sprint": "R3-REACH RE0a", "machine": machine(a), "runs": a.runs, "seed": seed,
        "method": "each process alone; one pass = (cost at K passes - cost at 0 passes) / K within a run; CPU = user + system from wait4 (includes GC threads); load1 = 1-minute load average when the process started",
        "rows": rows,
        "counts": {"planets59": counts["system59"]["planets59"], "gate168": counts["gate168"]["gate168"],
                   "gate100pc": counts["gate100pc"]["gate100pc"], "rare1x": counts["rare1x"]["rare1x"],
                   "rare10x": counts["rare10x"]["rare10x"], "rare1xSha": counts["rare1x"]["rare1xSha"],
                   "rare10xSha": counts["rare10x"]["rare10xSha"], "packed168": counts["packed168"],
                   "packed100pc": counts["packed100pc"], "drawSum": counts["draw"],
                   "fixtureLifetimeYr1x": counts["base168"]["fixtureLifetimeYr1x"],
                   "fixtureLifetimeYr10x": counts["base168"]["fixtureLifetimeYr10x"],
                   "expectedHz168": counts["base168"]["expectedHz168"]},
        "counts_identical_across_runs": True,
        "parity_subset": {"rows": 5000, "vm_equals_interpreter": True, "gate_mirror_agrees": True,
                          "sha256": hashlib.sha256(vm_text.encode()).hexdigest(), "vm": vm_cost, "interpreter": in_cost},
        "keyed_draw_us": {"cpu": {k: round(v * 1e6, 4) for k, v in t["draw"]["cpu_s"].items()},
                          "wall": {k: round(v * 1e6, 4) for k, v in t["draw"]["wall_s"].items()}},
        "timings": t,
        "load_from_text_cpu_s": {"base168_csv_and_snapshot": spread([b["cpu_s"] for b in base["gate168"]]),
                                 "base100pc_csv_and_snapshot": spread([b["cpu_s"] for b in base["gate100pc"]]),
                                 "prepare_slices_once": prep},
        "budgets": [
            budget("imaging: systemFrom over 1,900 rows (59 ly)", one_pass("system59"), worst("system59"), 2.0, "measured"),
            budget("radio at 1x: rare query over 43,887 rows, about 35 worlds returned", one_pass("rare1x"), worst("rare1x"), 1.0, "measured"),
            budget("radio at 10x: the same, about 351 worlds returned", one_pass("rare10x"), worst("rare10x"), 1.0, "measured"),
            budget("one-draw gate over 43,887 rows (list of plans)", one_pass("gate168"), worst("gate168"), None, "measured; the design estimated 0.2 s"),
            budget("one-draw gate over 302,239 rows (list of plans)", one_pass("gate100pc"), worst("gate100pc"), None, "measured; the design estimated 1.3 s"),
            budget("one-draw gate over 43,887 rows (packed float64 array)", one_pass("packed168"), worst("packed168"), None, "measured"),
            budget("one-draw gate over 302,239 rows (packed float64 array)", one_pass("packed100pc"), worst("packed100pc"), None, "measured"),
            budget("one synthesised star from its id: 146 stars x 6 draws", 876 * draw_us / 1e6, 876 * t["draw"]["cpu_s"]["max"], 0.020,
                   "ESTIMATE from the draw rate only; no leaf generator exists yet"),
        ],
    }
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    with open(a.out, "w") as f:
        json.dump(report, f, indent=1)
        f.write("\n")
    for b in report["budgets"]:
        print(f"reach-probe: {b['query']}: {b['cpu_s_mean']} s CPU (worst run {b['cpu_s_worst_run']}), budget {b['budget_s']}, pass {b['pass']}")
    print(f"reach-probe: keyed draw {draw_us:.3f} us CPU; counts identical over {a.runs} runs; VM = interpreter on 5,000 rows; report {a.out}")


def io(a):
    paths, _ = prepare(a)
    ail(a, "ioReadMain", {"path": "", "mode": "none", "leaves": 0, "leafRows": 0})  # warm the compile cache
    path = f"{a.scratch}/registry-standin.f64"
    rows = EXPECT_ROWS["rows100pc"]
    wrote, wcost = ail(a, "ioWriteMain", {"out": path, "rows": rows})
    size = os.path.getsize(path)
    modes = {"none": {}, "raw": {}, "whole": {}, "mixed": {}, "leaves": {"leaves": 500, "leafRows": 146}, "one_leaf": {"leaves": 1, "leafRows": 146}}
    costs, texts = {m: [] for m in modes}, []
    for run in range(a.runs):
        text = {}
        for m, extra in modes.items():
            args = {"path": path, "mode": "leaves" if m == "one_leaf" else m, "leaves": 0, "leafRows": 0, **extra}
            text[m], c = ail(a, "ioReadMain", args)
            costs[m].append(c)
            print(f"reach-probe-io: run {run + 1}/{a.runs} {m}: cpu {c['cpu_s']} s, peak RSS {c['peak_rss_mb']} MB, load {c['load1']}", flush=True)
        texts.append(text)
    if any(x != texts[0] for x in texts):
        sys.exit("reach-probe-io: FAIL outputs differ between runs")
    over = lambda m: {"runs": a.runs,
                      "cpu_s_over_startup": spread([c["cpu_s"] - n["cpu_s"] for c, n in zip(costs[m], costs["none"])]),
                      "wall_s_over_startup": spread([c["wall_s"] - n["wall_s"] for c, n in zip(costs[m], costs["none"])]),
                      "peak_rss_mb": spread([c["peak_rss_mb"] for c in costs[m]]),
                      "load1": [c["load1"] for c in costs[m]], "raw": costs[m], "output": json.loads(texts[0][m])}
    leaves_text, leaf_cost = ail(a, "leafMain", {"csv": paths["csv100"]})
    leaves = json.loads(leaves_text)
    if leaves["rows"] != rows:
        sys.exit(f"reach-probe-io: FAIL leaf statistics saw {leaves['rows']} rows, expected {rows}")
    gaia = json.load(open(a.gaia))
    need = {"control_100pc_poe5", "shell_1000ly_poe5", "shell_1000ly_poe5_g14", "shell_3000ly_poe5", "shell_3000ly_poe5_g14"}
    got = {q["label"]: q["count"] for q in gaia["queries"]}
    if not need <= set(got) or not gaia.get("date") or not all(q.get("adql") for q in gaia["queries"]):
        sys.exit(f"reach-probe-io: FAIL {a.gaia} lacks a required count, its query text or its date")
    report = {
        "sprint": "R3-REACH RE0b", "machine": machine(a), "runs": a.runs,
        "method": "each process alone; cost over start-up = cost of the mode - cost of mode none in the same run; peak RSS is the whole process",
        "file": {"rows": rows, "bytes": size, "layout": "float64 x 6 a row (48 bytes; the design's row is 44)", "write": wcost},
        "startup_only": {"cpu_s": spread([c["cpu_s"] for c in costs["none"]]), "peak_rss_mb": spread([c["peak_rss_mb"] for c in costs["none"]])},
        "read_raw_bytes": over("raw"), "read_and_decode_whole": over("whole"),
        "read_then_decode_row_by_row": over("mixed"),
        "read_then_decode_500_leaves": over("leaves"), "read_then_decode_1_leaf": over("one_leaf"),
        "leaves": {"cost": leaf_cost, **leaves},
        "gaia": {"source": a.gaia, "date": gaia["date"], "counts": got,
                 "size_mb_at_44_bytes_a_row": {k: round(v * 44 / 1e6, 1) for k, v in got.items()}},
    }
    with open(a.out, "w") as f:
        json.dump(report, f, indent=1)
        f.write("\n")
    w = report["read_and_decode_whole"]
    print(f"reach-probe-io: {size} bytes read and decoded in {w['cpu_s_over_startup']['mean']} s CPU over start-up, peak RSS {w['peak_rss_mb']['max']} MB; "
          f"leaf statistics over {rows} rows; Gaia counts pinned {gaia['date']}; report {a.out}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["vm", "io"])
    ap.add_argument("--ailang", default=os.environ.get("AILANG", "ailang"))
    ap.add_argument("--csv", default="data/raw/gcns.csv")
    ap.add_argument("--scratch", default=".godot/tmp/reach")
    ap.add_argument("--gaia", default="data/reach/gaia_counts.json")
    ap.add_argument("--out", required=True)
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--seed", type=int, default=7)
    a = ap.parse_args()
    if a.runs < 3:
        sys.exit("reach-probe: at least 3 runs")
    {"vm": vm, "io": io}[a.mode](a)
