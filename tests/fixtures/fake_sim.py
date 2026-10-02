#!/usr/bin/env python3
"""Protocol v2 stand-in for the bridge's failure-path tests.

usage: fake_sim.py MODE [DUMP_PATH]
DUMP_PATH, if given, receives every stdin line byte for byte (tee test).
"""
import json, sys, time

mode = sys.argv[1]
dump = open(sys.argv[2], "wb") if len(sys.argv) > 2 else None
tick = 0
ship = {"phase": "rest", "beta": 0, "one_minus_beta": 1, "gamma": 1, "heading": {"x": 0, "y": 0, "z": -1}, "pos": {"x": 0, "y": 0, "z": 0}, "x": 0}
clock = {"tau": 0, "t": 0, "year": 0, "age": 30}
protos = {"proto_v1": {"major": 1, "minor": 1}, "proto_v3": {"major": 3, "minor": 0}, "proto_v31": {"major": 3, "minor": 1}, "proto_21": {"major": 2, "minor": 1},
          "proto_frac": {"major": 2.5, "minor": 0}, "proto_string": "2.0"}


def out(msg):
    print(json.dumps(msg, separators=(",", ":")), flush=True)


def state(full=False, changes=None):
    return {"v": 2, "type": "state", "tick": tick, "status": "ok", "changes": changes or {}, "events": [], "refused": [], "full": full}


if mode == "v11":  # the retired v1.1 sim: unsolicited state line, then proto "1.1"
    out({"tick": 0, "beta": 0, "status": "ok"})
for raw in sys.stdin.buffer:
    if dump:
        dump.write(raw)
        dump.flush()
    msg = json.loads(raw)
    kind = msg.get("type")
    if kind == "hello":
        if mode == "silent_start":
            time.sleep(30)
        elif mode == "v11":
            out({"proto": "1.1", "tick": 0, "status": "ok"})
        else:
            out({"v": 2, "type": "hello", "proto": protos.get(mode, {"major": 2, "minor": 0}), "sim": "fake", "relativity": "0", "rng": "none-0"})
    elif kind == "new_game":
        out(state(True, {"clock": clock, "ship": ship}))
    elif kind == "input":
        if mode == "truncated":
            sys.stdout.write('{"v":2,"type":"state","tick":')
            sys.stdout.flush()
        elif mode in ("silent_step", "ignore_quit"):
            pass
        elif mode == "skip_tick":
            tick += 2
            out(state())
        else:
            tick += 1
            out(state())
    elif kind == "quit":
        if mode == "ignore_quit":
            time.sleep(30)
        else:
            break
