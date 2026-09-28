#!/usr/bin/env python3
import json, sys, time
mode = sys.argv[1]
state = {"tick": 0, "beta": 0, "gamma": 1, "tau": 0, "t": 0, "x": 0, "heading": {"x": 0, "y": 0, "z": -1}, "pos": {"x": 0, "y": 0, "z": 0}, "status": "ok"}
if mode != "silent_start":
    print(json.dumps(state), flush=True)
for line in sys.stdin:
    cmd = json.loads(line).get("cmd")
    if cmd == "hello":
        if mode == "silent_start":
            time.sleep(30)
        elif mode == "old_proto":
            print(json.dumps({**state, "proto": "1.0"}), flush=True)
        else:
            print(json.dumps({**state, "proto": "1.1"}), flush=True)
    elif cmd == "step":
        if mode == "truncated":
            sys.stdout.write('{"tick":')
            sys.stdout.flush()
        elif mode in ("silent_step", "ignore_quit"):
            pass
        else:
            state["tick"] += 1
            print(json.dumps(state), flush=True)
    elif cmd == "quit":
        if mode == "ignore_quit":
            time.sleep(30)
        else:
            break
