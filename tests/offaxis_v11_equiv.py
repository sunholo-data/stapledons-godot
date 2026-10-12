#!/usr/bin/env python3
"""AC13 (interim): the v2 off-axis log reproduces v1.1's kinematics.

usage: offaxis_v11_equiv.py V11_GOLDEN V2_OUTPUT

The v2 output is mirrored the way the Godot bridge mirrors it (a full state,
then section change-sets). After every request, the mirrored beta, gamma, tau,
t, x and pos must equal the v1.1 line for the same request as float64 bit
patterns. The outcome must match too: v1.1's reject status equals v2's status,
and v1.1's `moving` is v2's refusal reason (v2 refuses the intent and the tick
proceeds; v1.1 rejected the whole step). Pairing: v1.1's startup line has no
v2 counterpart, v1.1's hello reply pairs with v2's new_game state, and the v2
hello reply (no kinematics) is checked for proto 2 and skipped.
"""
import json
import struct
import sys


def bits(x):
    return struct.pack(">d", float(x))


def main(golden_path, v2_path):
    v11 = [json.loads(l) for l in open(golden_path) if l.strip() and not l.startswith("#")]
    v2 = [json.loads(l) for l in open(v2_path) if l.strip()]
    if v2[0].get("type") != "hello" or v2[0].get("proto", {}).get("major") != 2:
        sys.exit("v2 log must open with a proto-2 hello reply")
    v11, v2 = v11[1:], v2[1:]
    if len(v11) != len(v2):
        sys.exit("line count differs: v1.1 %d, v2 %d" % (len(v11), len(v2)))
    world = {}
    fails = 0
    for n, (old, new) in enumerate(zip(v11, v2), start=1):
        ch = new["changes"]
        world = dict(ch) if new["full"] else {**world, **ch}
        ship, clock = world["ship"], world["clock"]
        got = {"beta": ship["beta"], "gamma": ship["gamma"], "tau": clock["tau"], "t": clock["t"], "x": ship["x"],
               "pos.x": ship["pos"]["x"], "pos.y": ship["pos"]["y"], "pos.z": ship["pos"]["z"]}
        want = {"beta": old["beta"], "gamma": old["gamma"], "tau": old["tau"], "t": old["t"], "x": old["x"],
                "pos.x": old["pos"]["x"], "pos.y": old["pos"]["y"], "pos.z": old["pos"]["z"]}
        outcome = new["refused"][0]["reason"] if new["status"] == "ok" and new["refused"] else new["status"]
        for k in want:
            if bits(got[k]) != bits(want[k]):
                fails += 1
                print("FAIL line %d %s: v2 %r != v1.1 %r" % (n, k, got[k], want[k]))
        if outcome != old["status"]:
            fails += 1
            print("FAIL line %d outcome: v2 %s != v1.1 %s" % (n, outcome, old["status"]))
    print("offaxis-v11-equiv: %d requests, %s" % (len(v11), "beta gamma tau t x pos bit-identical, outcomes equal" if fails == 0 else "%d mismatches" % fails))
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
