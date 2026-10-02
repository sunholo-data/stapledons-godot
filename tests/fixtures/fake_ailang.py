#!/usr/bin/env python3
"""Stand-in for `ailang run ... sim/ship.ail` in tools/test_replay.py.

One reply per stdin line until a quit line, like ship.ail. Env knobs:
  FAKE_DIVERGE=1   the interpreter (no --bytecode) changes one digit of its last reply
  FAKE_SKIP=N      no reply to input line N (both runtimes)
"""
import os
import sys

if "--version" in sys.argv:
    print("AILANG fake")
    sys.exit(0)
vm = "--bytecode" in sys.argv
skip = int(os.environ.get("FAKE_SKIP", "0"))
out = []
for n, line in enumerate(sys.stdin, start=1):
    if line.strip() in ("", '{"v":2,"type":"quit"}'):
        break
    if n != skip:
        out.append('{"n":%d,"len":%d,"x":0.25}' % (n, len(line)))
if os.environ.get("FAKE_DIVERGE") and not vm and out:
    out[-1] = out[-1].replace("0.25", "0.26")
sys.stdout.write("".join(l + "\n" for l in out))
