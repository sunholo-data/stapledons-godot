#!/usr/bin/env python3
"""Stand-in for `ailang run ... sim/ship.ail` in tools/test_replay.py.

One reply per stdin line until a quit line, like ship.ail. Env knobs:
  FAKE_DIVERGE=1   the interpreter (no --bytecode) changes one digit of its last reply
  FAKE_SKIP=N      no reply to input line N (both runtimes)
  FAKE_PROTO=21    a 2.1 stream (replay-compat): line 1 answers a hello with minor 1,
                   line 2 a full state with the params AI keys last and the ai section last
  FAKE_PROTO=20    the same stream as 2.0 printed it (hello minor 0, no AI keys, no ai section)
  FAKE_EXTRA=1     with FAKE_PROTO=21: a fourth new key in params (must not be stripped)
  FAKE_FMT=1       line 3 prints 0.250 for 0.25 (same JSON value, other bytes)
"""
import os
import sys

if "--version" in sys.argv:
    print("AILANG fake")
    sys.exit(0)
vm = "--bytecode" in sys.argv
skip = int(os.environ.get("FAKE_SKIP", "0"))
proto = os.environ.get("FAKE_PROTO", "")
extra = ',"ai_seed_hint":5' if os.environ.get("FAKE_EXTRA") else ""


def reply(n, line):
    if proto and n == 1:
        return '{"v":2,"type":"hello","proto":{"major":2,"minor":%s},"sim":"fake"}' % ("1" if proto == "21" else "0")
    if proto and n == 2:
        ai_params = '%s,"ai_max_open":8,"ai_ttl_ticks":3600' % extra if proto == "21" else ""
        ai = ',"ai":{"last_req":0,"open":[],"core":""}' if proto == "21" else ""
        return ('{"v":2,"type":"state","tick":0,"status":"ok","changes":{"rng":{"ai":0},"params":{"epoch":2100,"cruise_phi_default":1.5%s}%s},'
                '"events":[],"refused":[],"full":true}' % (ai_params, ai))
    x = "0.250" if os.environ.get("FAKE_FMT") and n == 3 else "0.25"
    return '{"n":%d,"len":%d,"x":%s}' % (n, len(line), x)


out = []
for n, line in enumerate(sys.stdin, start=1):
    if line.strip() in ("", '{"v":2,"type":"quit"}'):
        break
    if n != skip:
        out.append(reply(n, line))
if os.environ.get("FAKE_DIVERGE") and not vm and out:
    out[-1] = out[-1].replace("0.25", "0.26")
sys.stdout.write("".join(l + "\n" for l in out))
