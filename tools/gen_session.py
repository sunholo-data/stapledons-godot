#!/usr/bin/env python3
"""Write the deterministic replay session (design m2-journey-core §M2.5).

usage: gen_session.py [--ticks N] [OUT]      (default: 10000 ticks, stdout)

The session is a protocol v2 input log: exactly N accepted `input` lines
(ticks summed over its games), plus control lines and one line of every
malformed kind. Nothing here is random and nothing reads the catalogue:
targets are named by index, id and position, so the log replays without
any data file. Its golden output is ~3 MB, so only its sha256 is committed
(tests/replays/session10k.state.<arch>.sha256).

Coverage (in order):
  preamble    no_hello (input and new_game before hello), bad_json, bad_v,
              bad_cmd, hello, no_game, bad_game, bad_params, m_eff_too_small
  game A      play mode, seed 20261002:
              plan alpha Cen at 0.964c, replan at 0.99c (id 2), commit the
              stale id 1 (stale_plan) and id 2 in one line; the voyage
              (~63 ticks) with cancel, thrust, replan, draw, heading and
              commit attempts in transit (all refused `committed`); bad_tick,
              bad_step, bad_intent, bad_heading mid-voyage (the tick does not
              advance); arrival; out-of-range phi both sides, thrust, draw
              and flip_g outside diag (diag_only); a voyage at the cap
              speed; a voyage to a target 100 ly from Sol (109 ly from
              Sirius) in 0.1-yr ticks; idle ticks
  game B      diag, seed 2^53 - 1:
              draw on every stream; a 1 g flip-and-burn voyage to alpha Cen
              (~359 ticks) with commit-while-moving refused first; draws in
              transit (committed); after arrival 1 g burns out and back with
              periodic draws on every stream until N ticks
  quit
N < 10000 truncates game B's filler (the PR-sized case); N must leave room
for the scripted part.
"""
import json
import sys

PHI_099 = 2.6466524123622457     # atanh(0.99)
PHI_0964 = 2.0
PHI_MIN = 1.4722194895832204     # atanh(0.9), the default cruise floor
PHI_CAP = 7.254328619262047      # rapidityOfOneMinusBeta(1e-6), the default cap
ALPHA_CEN = {"index": 1, "id": "alpha Cen", "pos": {"x": 0, "y": 0, "z": -4.37}}
SIRIUS_FROM_ALPHA = {"index": 7, "id": "Sirius", "pos": {"x": -1.61, "y": 8.08, "z": -6.85}}
FAR = {"index": 42, "id": "HD 100ly", "pos": {"x": 60.0, "y": -48.0, "z": 64.0}}  # 100 ly from the origin
STREAMS = ["journey", "crew", "events", "galaxy", "ai", "news"]


def j(msg):
    return json.dumps(msg, separators=(",", ":"), ensure_ascii=False)


class Log:
    def __init__(self, budget):
        self.lines, self.tick, self.accepted, self.budget = [], 0, 0, budget

    def raw(self, line):
        self.lines.append(line)

    def msg(self, m):
        self.raw(j({"v": 2, **m}))

    def new_game(self, seed, diag, **extra):
        self.msg({"type": "new_game", "seed": seed, "scenario": "sol", "diag": diag, **extra})
        self.tick = 0

    def step(self, intents=(), dtau=0.01):
        if self.accepted >= self.budget:
            raise SystemExit("gen_session: tick budget %d too small for the scripted part" % self.budget)
        self.tick += 1
        self.accepted += 1
        self.msg({"type": "input", "tick": self.tick, "dtau": dtau, "intents": list(intents)})

    def bad_input(self, intents, dtau=0.01, tick=None):
        """A malformed input line: the sim answers its status, the tick does not advance."""
        self.msg({"type": "input", "tick": self.tick + 1 if tick is None else tick, "dtau": dtau, "intents": intents})

    def idle(self, n, dtau=0.01):
        for _ in range(n):
            self.step([], dtau)


def plan(target, phi, **extra):
    return {"k": "plan", "target": target, "cruise_phi": phi, **extra}


def session(ticks):
    log = Log(ticks)
    # preamble: every session-level malformed kind once
    log.msg({"type": "input", "tick": 1, "dtau": 0, "intents": []})          # no_hello
    log.new_game(1, False)                                                    # no_hello
    log.raw("{not json")                                                      # bad_json
    log.raw(j({"v": 1, "type": "hello", "want": {"major": 2, "minor": 0}}))   # bad_v
    log.msg({"type": "warp"})                                                 # bad_cmd
    log.msg({"type": "hello", "want": {"major": 2, "minor": 0}})
    log.msg({"type": "input", "tick": 1, "dtau": 0, "intents": []})          # no_game
    log.msg({"type": "new_game", "seed": 1, "scenario": "andromeda", "diag": False})  # bad_game
    log.new_game(1, False, params={"glow_eps": 2.0})                          # bad_params
    log.new_game(1, False, params={"m_eff_kg": 1e-30})                        # m_eff_too_small

    # game A: play mode
    log.new_game(20261002, False)
    log.step([plan(ALPHA_CEN, PHI_0964)], 0)
    log.step([plan(ALPHA_CEN, PHI_099)])
    log.step([{"k": "commit", "plan_id": 1}, {"k": "commit", "plan_id": 2}])
    transit = [
        [{"k": "cancel"}],
        [{"k": "thrust", "thrust": 0.5}],
        [plan(ALPHA_CEN, PHI_0964)],
        [{"k": "draw", "stream": "crew"}],
        [{"k": "heading", "heading": {"x": 1, "y": 0, "z": 0}}],
        [{"k": "commit", "plan_id": 2}, {"k": "cancel"}],
        [{"k": "echo", "target": ALPHA_CEN, "cruise_phi": PHI_099}],
    ]
    for i in range(70):
        if i == 10:
            log.bad_input([], tick=log.tick + 5)                                 # bad_tick
            log.bad_input([], dtau=1.5)                                          # bad_step
            log.bad_input([{"k": "warp"}])                                       # bad_intent
            log.bad_input([{"k": "heading", "heading": {"x": 1, "y": 1, "z": 0}}])  # bad_heading
        log.step(transit[i % len(transit)] if i % 5 == 0 else [])
    log.idle(10)
    log.step([plan(SIRIUS_FROM_ALPHA, PHI_MIN - 1e-9), plan(SIRIUS_FROM_ALPHA, PHI_CAP + 1e-9),
              plan(SIRIUS_FROM_ALPHA, PHI_CAP, flip_g=1), {"k": "thrust", "thrust": 1}, {"k": "draw", "stream": "news"}], 0)
    log.step([plan(SIRIUS_FROM_ALPHA, PHI_MIN)], 0)                             # the floor is inclusive
    log.step([plan(SIRIUS_FROM_ALPHA, PHI_CAP)], 0)                             # so is the cap
    log.step([{"k": "commit", "plan_id": 4}])
    log.idle(30)
    log.step([plan(FAR, PHI_099)], 0)
    log.step([{"k": "commit", "plan_id": 5}], 0.1)
    log.idle(200, 0.1)
    log.step([plan(ALPHA_CEN, PHI_099), {"k": "cancel"}], 0)
    log.idle(200)

    # game B: diag
    log.new_game(9007199254740991, True)
    log.step([{"k": "draw", "stream": s} for s in STREAMS], 0)
    log.step([{"k": "draw", "stream": s} for s in reversed(STREAMS)])
    log.step([{"k": "thrust", "thrust": 1}])
    log.step([plan(ALPHA_CEN, PHI_099, flip_g=1), {"k": "commit", "plan_id": 1}])  # moving
    log.step([{"k": "thrust", "thrust": -1}])
    log.step([{"k": "thrust", "thrust": 0}])
    log.step([plan(ALPHA_CEN, PHI_099, flip_g=1)], 0)   # from where the ship now is
    log.step([{"k": "commit", "plan_id": 2}], 0)
    for i in range(400):
        log.step([{"k": "draw", "stream": STREAMS[i % 6]}] if i % 50 == 0 else [])
    heading = [{"x": 0, "y": 1, "z": 0}, {"x": 0, "y": 0, "z": 1}]
    n = 0
    while log.accepted < ticks:
        phase = n % 600
        intents = []
        if phase == 0:
            intents = [{"k": "heading", "heading": heading[(n // 600) % 2]}, {"k": "thrust", "thrust": 1}]
        elif phase == 300:
            intents = [{"k": "thrust", "thrust": -1}]
        elif phase == 599:
            intents = [{"k": "thrust", "thrust": 0}]
        if n % 7 == 0:
            intents.append({"k": "draw", "stream": STREAMS[(n // 7) % 6]})
        log.step(intents)
        n += 1
    log.msg({"type": "quit"})
    return log


def main(argv):
    ticks = 10000
    if argv[:1] == ["--ticks"]:
        ticks, argv = int(argv[1]), argv[2:]
    log = session(ticks)
    assert log.accepted == ticks
    text = "\n".join(log.lines) + "\n"
    if argv:
        with open(argv[0], "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
    else:
        sys.stdout.write(text)


if __name__ == "__main__":
    main(sys.argv[1:])
