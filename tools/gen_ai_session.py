#!/usr/bin/env python3
"""Write the deterministic AI replay session (design ai-service-foundation AC12 part, AI.3).

usage: gen_ai_session.py [OUT]      (default: stdout)

A protocol 2.1 input log for replay case `ai_sim_session`
(tests/replays/ai_sim_session.ndjson, committed; tools/test_replay.py checks
that this script still writes it byte for byte). Nothing here is random: the
record bodies are fixed strings and their sha256 is hashlib's, so the log
is the same on every machine. The sim, not this script, decides every
outcome; the goldens hold what it answered.

Coverage (in order):
  game A  play mode, seed 20261003, ai_core set, ai_max_open 12, ai_ttl_ticks 40:
          ai_open of every kind and purpose; text (line, news, archive),
          portrait and avatar records accepted; a voice line for an accepted
          line, accepted; every ai_open refusal (ai_kind, diag_only, ai_bad_key
          x4, ai_stale, ai_too_many); every record refusal (ai_source,
          ai_unknown_req, ai_kind, ai_hash text and media, ai_length,
          ai_numeral, ai_markup incl. an invisible-only segment, ai_emotion,
          ai_descriptor for an image and a voice line), each closing its
          request; a second record on a closed request; cancels with every
          reason and one unknown; an expiry at expires_tick; 66 accepted lines
          (ids past 64), then a voice line for an evicted line (ai_stale) and
          for a kept one (accepted)
  game B  play mode, seed 7: the alpha Cen voyage at 0.99c with AI intents
          while committed (opens, records accepted and refused, a cancel),
          journey intents refused `committed` beside them, through arrival
  quit
"""
import hashlib
import json
import sys

HEX = "ab" * 32
CORE = hashlib.sha256(b"ai_sim_session core index").hexdigest()
ALPHA_CEN = {"index": 1, "id": "alpha Cen", "pos": {"x": 0, "y": 0, "z": -4.37}}
PHI_099 = 2.6466524123622457
MEDIC = ["neutral", "loving", "grieving"]


def j(msg):
    return json.dumps(msg, separators=(",", ":"), ensure_ascii=False)


def sha(body):
    return hashlib.sha256(body.encode("utf-8")).hexdigest()


def key(kind, emotion="-", age=0, variant="0"):
    return {"kind": kind, "entity_id": "medic", "emotion": emotion, "age_stage": age, "variant": variant}


def portrait_desc(**over):
    d = {"key": key("portrait", "grieving", 50), "mime": "image/png", "bytes": 2287104, "width": 1024, "height": 1536}
    d.update(over)
    return j(d)


def voice_desc(segs, dur=5300, variant="3f2a9c0d1e4b5a6c"):
    return j({"key": key("voice", variant=variant), "mime": "audio/ogg", "bytes": 84211, "duration_ms": dur, "segments_ms": segs})


def text_open(purpose="line", entity="medic", emotions=None):
    o = {"k": "ai_open", "kind": "text", "purpose": purpose, "entity_id": entity}
    if emotions is not None:
        o["emotions"] = emotions
    return o


def voice_open(line):
    return {"k": "ai_open", "kind": "voice", "purpose": "line", "entity_id": "medic", "line_req": str(line)}


PORTRAIT_OPEN = {"k": "ai_open", "kind": "portrait", "purpose": "line", "entity_id": "medic", "emotion": "grieving", "age_stage": 50,
                 "context": {"topic": "first_night_aboard", "canon": ["archive.two-clocks"]}}
AVATAR_OPEN = {"k": "ai_open", "kind": "avatar", "purpose": "news", "entity_id": "medic"}


def rec(req, kind, body, digest=None, source="ai"):
    return {"k": "record", "source": source, "req": str(req), "kind": kind, "sha256": sha(body) if digest is None and kind == "text" else (digest or HEX), "body": body}


class Log:
    def __init__(self):
        self.lines, self.tick, self.req = [], 0, 0

    def msg(self, m):
        self.lines.append(j({"v": 2, **m}))

    def new_game(self, seed, **extra):
        self.msg({"type": "new_game", "seed": seed, "scenario": "sol", "diag": False, **extra})
        self.tick, self.req = 0, 0

    def step(self, intents=(), dtau=0.0):
        self.tick += 1
        self.msg({"type": "input", "tick": self.tick, "dtau": dtau, "intents": list(intents)})

    def opens(self, n):
        """The ids the next n accepted opens will take (the sim assigns them; refusals take none)."""
        ids = list(range(self.req + 1, self.req + n + 1))
        self.req += n
        return ids


def game_a(log):
    log.new_game(20261003, params={"ai_max_open": 12, "ai_ttl_ticks": 40}, ai_core=CORE)
    line, news, archive, por, ava = log.opens(5)
    log.step([text_open(emotions=MEDIC), text_open("news"), text_open("archive", "archive"), PORTRAIT_OPEN, AVATAR_OPEN])
    log.step([rec(line, "text", "{loving}We made it. {grieving}She did not."),
              rec(news, "text", "A new star rose over the bow tonight, and the crew watched it in silence."),
              rec(archive, "text", "The two clocks disagree because each measures its own path. " * 9 + "Both are right."),
              rec(por, "portrait", portrait_desc()), rec(ava, "avatar", j({"key": key("avatar"), "mime": "image/webp", "bytes": 4096, "width": 256, "height": 256}))])
    (voice,) = log.opens(1)
    log.step([voice_open(line), rec(voice, "voice", voice_desc([0, 2100])),
              # every ai_open refusal (no id taken)
              {"k": "ai_open", "kind": "warp", "purpose": "line", "entity_id": "medic"},
              text_open("probe"),
              text_open(entity="Medic"),
              {"k": "ai_open", "kind": "portrait", "purpose": "line", "entity_id": "medic", "emotion": "joyful"},
              {"k": "ai_open", "kind": "portrait", "purpose": "line", "entity_id": "medic", "emotion": "sad", "age_stage": 1.5},
              text_open(emotions=[]),
              voice_open(99)])
    # every record refusal, each on a request opened in the same tick
    ids = log.opens(11)
    log.step([text_open(emotions=MEDIC)] * 9 + [PORTRAIT_OPEN, voice_open(line)] + [
        rec(ids[0], "text", "Hello.", source="player"),                       # ai_source
        rec(999, "text", "Hello."),                                            # ai_unknown_req (closes nothing)
        rec(ids[1], "portrait", "Hello."),                                     # ai_kind
        rec(ids[2], "text", "Hello.", digest=sha("Hullo.")),                   # ai_hash (text)
        rec(ids[3], "text", "a" * 281),                                        # ai_length
        rec(ids[4], "text", "{loving}In 2041 we left."),                       # ai_numeral
        rec(ids[5], "text", "[sigh] {loving}Home."),                           # ai_markup
        rec(ids[6], "text", "{grieving}Gone. {loving}​"),                # ai_markup (invisible-only segment)
        rec(ids[7], "text", "{happy}Hooray."),                                 # ai_emotion
        rec(ids[8], "text", "{loving}Still here.", digest=None),               # accepted
        rec(ids[9], "portrait", portrait_desc(key=key("portrait", "grieving", 50, "1"))),  # ai_descriptor (variant)
        rec(ids[10], "voice", voice_desc([0, 2100, 4000])),                    # ai_descriptor (segment count)
        rec(ids[8], "text", "{loving}Again."),                                 # closed: ai_unknown_req
    ])
    # ai_hash for media, and ai_too_many: 12 open, the 13th refused
    full = log.opens(12)
    log.step([PORTRAIT_OPEN] * 12 + [text_open(), rec(full[0], "portrait", portrait_desc(), digest="AB" * 32)])
    reasons = ["offline", "no_key", "text_only", "timeout", "service_down", "budget", "provider_error"]
    log.step([{"k": "ai_cancel", "req": str(r), "reason": why} for r, why in zip(full[1:8], reasons)] +
             [{"k": "ai_cancel", "req": "999", "reason": "offline"}])
    # the rest (full[8:12]) expire 40 ticks after their open; a cancel on an expired id is unknown
    opened_at = log.tick - 1
    while log.tick < opened_at + 40:
        log.step([])
    log.step([{"k": "ai_cancel", "req": str(full[8]), "reason": "timeout"}])
    # 66 accepted lines: ids past 64; the first of them leaves ai.lines
    first = None
    for i in range(66):
        (r,) = log.opens(1)
        first = first or r
        log.step([text_open(emotions=MEDIC), rec(r, "text", "{neutral}Line number %s. {loving}Kept." % words(i))])
    (kept,) = log.opens(1)
    log.step([voice_open(first), voice_open(first + 2), rec(kept, "voice", voice_desc([0, 900], dur=1800, variant="0123456789abcdef"))])


def words(i):
    ones = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
    return " ".join(ones[int(d)] for d in str(i))


def game_b(log):
    log.new_game(7)
    log.step([{"k": "plan", "target": ALPHA_CEN, "cruise_phi": PHI_099}])
    a, b = log.opens(2)
    log.step([{"k": "commit", "plan_id": 1}, text_open(emotions=MEDIC), PORTRAIT_OPEN], dtau=0.01)
    log.step([rec(a, "text", "{grieving}Earth is behind us now."), {"k": "cancel"}, {"k": "plan", "target": ALPHA_CEN, "cruise_phi": 2.0}], dtau=0.01)
    c, d = log.opens(2)
    log.step([text_open("news"), {"k": "ai_cancel", "req": str(b), "reason": "timeout"}, AVATAR_OPEN], dtau=0.01)
    log.step([rec(c, "text", "Day 3 aboard."), rec(d, "avatar", "{}"), {"k": "commit", "plan_id": 1}], dtau=0.01)
    while log.tick < 66:
        log.step([], dtau=0.01)


def main():
    log = Log()
    log.msg({"type": "hello", "want": {"major": 2, "minor": 1}})
    game_a(log)
    game_b(log)
    log.msg({"type": "quit"})
    text = "".join(l + "\n" for l in log.lines)
    if len(sys.argv) > 1:
        with open(sys.argv[1], "w", encoding="utf-8") as f:
            f.write(text)
    else:
        sys.stdout.write(text)


if __name__ == "__main__":
    main()
