#!/usr/bin/env python3
"""AC16 harness: real 2.17 sidecar, 10k ticks, catalogue + synthetic arrivals.

Six travel ticks expose both planet serializers. The remaining accepted ticks
exercise idle clocks and the galaxy RNG stream at that system. Complete outputs
must match across all four presets and both engines, with an exact field schema.
"""
import concurrent.futures
import hashlib
import json
import os
import re
from pathlib import Path
import shlex
import subprocess
import threading
import time

ROOT = Path(__file__).resolve().parents[1]
PRESETS = ("lonely", "scattered", "stapledon", "teeming")
FORBIDDEN_IMPORTS = ("worlds/dial", "worlds/history", "./census", "data/presets")
PLANET_KEYS = {"id", "name", "prov", "cite", "a_au", "period_d", "radius_earth", "mass_earth", "minimum_mass", "teq_k", "insolation", "hab"}


def requests(preset, ticks):
    assert ticks >= 6
    messages = [{"v": 2, "type": "hello", "want": {"major": 2, "minor": 17}}]
    targets = (
        {"index": 2, "id": "CNS5:3627", "pos": {"x": 3.094521, "y": -3.015404, "z": -0.051608}, "star": {"name": "alpha Centauri A", "v": -0.01, "teff": 5795}},
        {"index": 2, "id": "synthetic-only", "pos": {"x": 5.0, "y": 0.0, "z": 0.0}, "star": {"name": "Synthetic test star", "v": 0.7, "teff": 5780}},
    )
    for raw in targets:
        target = dict(raw)
        star = target.pop("star")
        messages += [
            {"v": 2, "type": "new_game", "seed": 41, "preset": preset, "scenario": "free_nav", "diag": True,
             "params": {"ism_model": 0, "ism_n_cm3": 0, "stop_rule": 54, "standoff_au": 1000}},
            {"v": 2, "type": "input", "tick": 1, "dtau": 0, "intents": [{"k": "plan", "target": target, "star": star, "cruise_phi": 2.6466524123622457}]},
            {"v": 2, "type": "input", "tick": 2, "dtau": 0, "intents": [{"k": "commit", "plan_id": 1}]},
            {"v": 2, "type": "input", "tick": 3, "dtau": 1, "intents": []},
        ]
    for tick in range(4, ticks - 2):
        messages.append({"v": 2, "type": "input", "tick": tick,
                         "dtau": 1 if tick % 1000 == 0 else 0,
                         "intents": [{"k": "draw", "stream": "galaxy"}] if tick % 137 == 0 else []})
    messages.append({"v": 2, "type": "quit"})
    return ("\n".join(json.dumps(msg, separators=(",", ":")) for msg in messages) + "\n").encode()


def audit(data, ticks):
    accepted = 0
    saw_worlds = saw_catalogue_target = saw_synthesised_local = False
    for line in data.splitlines():
        obj = json.loads(line)
        if obj.get("status") == "ok" and obj.get("full") is False:
            accepted += 1
        worlds = obj.get("changes", {}).get("worlds")
        if worlds is None:
            continue
        saw_worlds = True
        expected = {"meta", "hosts", "target", "system"} if obj.get("full") else {"target", "system"}
        assert set(worlds) == expected, set(worlds)
        directory = obj.get("changes", {}).get("system", {}).get("worlds_planet_ids")
        if "system" in obj.get("changes", {}):
            assert directory is not None, "2.17 system directory is missing"
            assert directory == [p["id"] for p in worlds["system"]], "system/worlds planet identities disagree"
        if "hosts" in worlds:
            assert len(worlds["hosts"]) == 241
            assert len({h["star_id"] for h in worlds["hosts"]}) == 241
            assert set(worlds["meta"]) == {"model", "baseline", "data"}
            for host in worlds["hosts"]:
                assert set(host) == {"star_id", "planets", "hz", "debated"}
        for key in ("target", "system"):
            for planet in worlds[key]:
                assert set(planet) == PLANET_KEYS, set(planet)
                if key == "target":
                    assert planet["prov"] != "synthesised"
                    saw_catalogue_target |= planet["id"] == "acen-a-b"
                else:
                    saw_synthesised_local |= planet["prov"] == "synthesised"
    assert saw_worlds, "no worlds projection exercised"
    assert saw_catalogue_target, "canonical catalogue target was never projected"
    assert saw_synthesised_local, "local synthesized planets were never projected"
    assert accepted == ticks, (accepted, ticks)


def main():
    ticks = int(os.environ.get("WORLDS_LEAK_TICKS", "10000"))
    source = (ROOT / "sim/protocol_worlds.ail").read_text()
    imports = "\n".join(line for line in source.splitlines() if line.startswith("import "))
    assert not any(bad in imports for bad in FORBIDDEN_IMPORTS), imports
    code = "\n".join(line.split("--", 1)[0] for line in source.splitlines())
    assert not re.search(r"\.\s*(history|mind|biosphere|preset|dial|luckDex)\b", code), "hidden-state field read in public encoder"
    out = ROOT / ".godot/tmp/worlds/leak"
    out.mkdir(parents=True, exist_ok=True)
    binary = shlex.split(os.environ.get("AILANG", str(ROOT / "runtime/bin/ailang")))
    running, lock = set(), threading.Lock()
    reference = None
    start = time.monotonic()

    def run_case(case):
        engine, preset = case
        command = binary + ["run", "--quiet", "--caps", "IO", "--package-dir", "sim", "--entry", "main"]
        if engine == "vm":
            command += ["--strict-bytecode"]
        command += ["sim/ship.ail"]
        process = subprocess.Popen(command, cwd=ROOT, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        with lock:
            running.add(process)
        try:
            data, error = process.communicate(requests(preset, ticks), timeout=1200)
        except BaseException:
            process.kill()
            process.wait()
            raise
        finally:
            with lock:
                running.remove(process)
        assert process.returncode == 0, error.decode(errors="replace")
        (out / f"{engine}-{preset}.ndjson").write_bytes(data)
        audit(data, ticks)
        digest = hashlib.sha256(data).hexdigest()
        print(f"worlds-leak {engine}/{preset}: {ticks} accepted ticks; {len(data)} bytes; sha256 {digest}", flush=True)
        return engine, preset, data

    cases = [(engine, preset) for engine in ("vm", "interpreter") for preset in PRESETS]
    pool = concurrent.futures.ThreadPoolExecutor(max_workers=4)
    futures = [pool.submit(run_case, case) for case in cases]
    try:
        for future in concurrent.futures.as_completed(futures):
            engine, preset, data = future.result()
            if reference is None:
                reference = data
            assert data == reference, f"wire differs: {engine}/{preset}"
    except BaseException:
        for future in futures:
            future.cancel()
        with lock:
            for process in running:
                process.terminate()
        pool.shutdown(wait=True, cancel_futures=True)
        raise
    pool.shutdown()
    print(f"worlds-leak: four presets × two engines byte-identical; schema/import audit passed ({time.monotonic()-start:.1f}s)")


if __name__ == "__main__":
    main()
