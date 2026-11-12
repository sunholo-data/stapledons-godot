#!/usr/bin/env python3
"""Unit tests for tools/replay.py against a fake ailang (no AILANG needed).

They pin the harness's teeth: a VM-only harness, a loose golden compare, a
dropped reply and a stale digest must each fail. Run: python3 tools/test_replay.py
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FAKE = "%s %s" % (sys.executable, os.path.join(ROOT, "tests", "fixtures", "fake_ailang.py"))
LOG = '{"v":2,"type":"hello"}\n{"v":2,"type":"input","tick":1}\n{"v":2,"type":"input","tick":2}\n{"v":2,"type":"quit"}\n{"v":2,"type":"input","tick":3}\n'
GOOD = '{"n":1,"len":23,"x":0.25}\n{"n":2,"len":32,"x":0.25}\n{"n":3,"len":32,"x":0.25}\n'


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = self.tmp.name
        self.replays = os.path.join(self.dir, "replays")
        os.makedirs(self.replays)
        self.write("c1.ndjson", LOG)

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, name, text):
        with open(os.path.join(self.replays, name), "w") as f:
            f.write(text)

    def replay(self, *args, **env):
        e = dict(os.environ, AILANG=FAKE, **env)
        r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "replay.py"), "--replays", self.replays,
                            "--scratch", os.path.join(self.dir, "scratch"), "--arch", "testarch", *args],
                           capture_output=True, text=True, env=e)
        return r.returncode, r.stdout + r.stderr



class Replay(Base):
    def test_positive_control(self):
        self.write("c1.state.testarch.ndjson", GOOD)
        log = os.path.join(self.dir, "engines.log")
        rc, out = self.replay("--case", "c1", "--positive-control", "--sim-only", FAKE_LOG=log)
        self.assertEqual(rc, 0, out)
        self.assertIn("one-bit golden-copy divergence detected", out)
        self.assertNotIn("  ok  ", out)
        self.assertNotIn("replay sim-only:", out)
        with open(log) as f:
            engines = f.read().splitlines()
        self.assertEqual(sorted(engines), ["interpreter"] * 3 + ["vm"] * 3)

    def test_identical_passes(self):
        self.write("c1.state.testarch.ndjson", GOOD)
        rc, out = self.replay("--case", "c1")
        self.assertEqual(rc, 0, out)
        self.assertIn("AILANG fake", out)  # the version is printed
        self.assertIn("all identical", out)

    def test_interpreter_divergence_fails(self):  # mutation: VM-only run
        self.write("c1.state.testarch.ndjson", GOOD)
        rc, out = self.replay("--case", "c1", FAKE_DIVERGE="1")
        self.assertEqual(rc, 1, out)
        self.assertIn("VM != interpreter", out)

    def test_one_byte_golden_difference_fails(self):  # mutation: golden compared loosely
        self.write("c1.state.testarch.ndjson", GOOD.replace('"x":0.25}\n{"n":3', '"x":0.250}\n{"n":3'))
        rc, out = self.replay("--case", "c1")
        self.assertEqual(rc, 1, out)
        self.assertIn("line 2 differs", out)

    def test_trailing_newline_golden_difference_fails(self):
        self.write("c1.state.testarch.ndjson", GOOD + "\n")
        rc, out = self.replay("--case", "c1")
        self.assertEqual(rc, 1, out)

    def test_dropped_reply_fails_even_with_matching_golden(self):  # mutation: replay ignores a line
        self.write("c1.state.testarch.ndjson", GOOD.replace('{"n":2,"len":32,"x":0.25}\n', ""))
        rc, out = self.replay("--case", "c1", FAKE_SKIP="2")
        self.assertEqual(rc, 1, out)
        self.assertIn("expected 3 replies", out)

    def test_missing_golden_fails(self):
        rc, out = self.replay("--case", "c1")
        self.assertEqual(rc, 1, out)
        self.assertIn("no testarch golden", out)

    def test_other_arch_golden_is_not_used(self):
        self.write("c1.state.otherarch.ndjson", GOOD)
        rc, out = self.replay("--case", "c1")
        self.assertEqual(rc, 1, out)

    def test_digest_golden(self):
        self.write("c1.state.testarch.sha256", hashlib.sha256(GOOD.encode()).hexdigest() + "  c1.state.ndjson\n")
        self.assertEqual(self.replay("--case", "c1")[0], 0)
        self.write("c1.state.testarch.sha256", hashlib.sha256(GOOD.encode() + b"x").hexdigest() + "  c1.state.ndjson\n")
        rc, out = self.replay("--case", "c1")
        self.assertEqual(rc, 1, out)
        self.assertIn("sha256", out)

    def test_session_path_uses_golden_beside_it(self):
        other = os.path.join(self.dir, "m4")
        os.makedirs(other)
        with open(os.path.join(other, "play.ndjson"), "w") as f:
            f.write(LOG)
        with open(os.path.join(other, "play.state.testarch.ndjson"), "w") as f:
            f.write(GOOD)
        rc, out = self.replay("--session", os.path.join(other, "play.ndjson"))
        self.assertEqual(rc, 0, out)

    def test_record_writes_golden_and_refuses_divergence(self):
        rc, out = self.replay("--record", os.path.join(self.replays, "c1.ndjson"), FAKE_DIVERGE="1")
        self.assertNotEqual(rc, 0, out)
        self.assertFalse(os.path.exists(os.path.join(self.replays, "c1.state.testarch.ndjson")))
        rc, out = self.replay("--record", os.path.join(self.replays, "c1.ndjson"))
        self.assertEqual(rc, 0, out)
        with open(os.path.join(self.replays, "c1.state.testarch.ndjson")) as f:
            self.assertEqual(f.read(), GOOD)
        self.assertEqual(self.replay("--case", "c1")[0], 0)


class VmOnly(Base):
    def setUp(self):
        super().setUp()
        self.log = os.path.join(self.dir, "engines.log")

    def engines(self):
        with open(self.log) as f:
            return f.read().splitlines()

    def vm(self, *args, **env):
        return self.replay("--vm-only", "--case", "c1", *args, FAKE_LOG=self.log, **env)

    def test_vm_only_never_interpreter(self):
        self.write("c1.state.testarch.ndjson", GOOD)
        rc, out = self.vm()
        self.assertEqual(self.engines(), ["vm"])
        self.assertEqual(rc, 0, out)
        self.assertIn("vm-only (VM = interpreter proven at record time)\n", out)
        self.assertTrue(os.path.exists(os.path.join(self.dir, "scratch", "c1.vm.ndjson")))
        self.assertFalse(os.path.exists(os.path.join(self.dir, "scratch", "c1.interp.ndjson")))

    def test_arm64_fallback(self):
        self.write("c1.state.arm64.ndjson", GOOD)
        rc, out = self.vm()
        self.assertEqual(rc, 0, out)
        self.assertIn("replay vm-only: no testarch golden for c1; compared with the arm64 golden", out)
        self.assertEqual(self.engines(), ["vm"])

    def test_corrupt_arm64_fallback_fails(self):
        self.write("c1.state.arm64.sha256", "0" * 64 + "  c1.state.ndjson\n")
        rc, out = self.vm()
        self.assertEqual(rc, 1, out)
        self.assertRegex(out, r"golden .*arm64.sha256: sha256 [0-9a-f]+ != 0{64}")
        self.assertEqual(self.engines(), ["vm"])

    def test_missing_golden_fails(self):
        rc, out = self.vm()
        self.assertEqual(rc, 1, out)
        self.assertIn("no testarch golden", out)

    def test_positive_control_reuses_one_run(self):
        for kind, gold in (("ndjson", GOOD), ("sha256", hashlib.sha256(GOOD.encode()).hexdigest() + "  c1.state.ndjson\n")):
            with self.subTest(kind=kind):
                name = "c1.state.arm64." + kind
                self.write(name, gold)
                if os.path.exists(self.log):
                    os.remove(self.log)
                rc, out = self.vm("--sim-only", "--positive-control")
                self.assertEqual(rc, 0, out)
                self.assertEqual(out.count("  ok  "), 1, out)
                self.assertEqual(out.count("replay positive control: one-bit golden-copy divergence detected\n"), 1, out)
                self.assertEqual(out.count("replay sim-only:"), 1, out)
                self.assertLess(out.index("  ok  "), out.index("replay positive control:"))
                self.assertLess(out.index("replay positive control:"), out.index("replay: 1 cases"))
                self.assertEqual(self.engines(), ["vm"])
                with open(os.path.join(self.replays, name)) as f:
                    self.assertEqual(f.read(), gold)
                copy_dir = os.path.join(self.dir, "scratch", "positive-control")
                self.assertEqual(os.listdir(copy_dir), ["c1.state.testarch." + kind])
                os.remove(os.path.join(copy_dir, "c1.state.testarch." + kind))
                os.remove(os.path.join(self.replays, name))

    def test_record_summary(self):
        rc, out = self.replay("--record", "c1", FAKE_LOG=self.log)
        self.assertEqual(rc, 0, out)
        self.assertRegex(out, r"recorded .*c1.state.testarch.ndjson \(3 replies, %d bytes, sha256 %s, VM [0-9.]+ s, interpreter [0-9.]+ s\)\n" % (len(GOOD), hashlib.sha256(GOOD.encode()).hexdigest()))
        self.assertEqual(sorted(self.engines()), ["interpreter", "vm"])

    def test_reply_count_still_checked(self):
        self.write("c1.state.testarch.ndjson", GOOD.replace('{"n":2,"len":32,"x":0.25}\n', ""))
        rc, out = self.vm(FAKE_SKIP="2")
        self.assertEqual(rc, 1, out)
        self.assertIn("expected 3 replies", out)

    def test_reject_record_and_compat(self):
        for args in (("--record", "c1"), ("--compat",)):
            rc, out = self.vm(*args)
            self.assertEqual(rc, 2, out)
            self.assertIn("--vm-only cannot be combined with --record or --compat", out)
            self.assertFalse(os.path.exists(self.log))

    def test_bad_real_golden_fails_before_control(self):
        self.write("c1.state.testarch.sha256", "0" * 64)
        rc, out = self.vm("--positive-control")
        self.assertEqual(rc, 1, out)
        self.assertIn("golden ", out)
        self.assertNotIn("replay positive control:", out)
        self.assertEqual(self.engines(), ["vm"])


# replay-compat (AI.3, design AC13): a 2.1 stream, with exactly the new fields stripped,
# must equal the frozen 2.0 golden byte for byte.
HELLO20 = '{"v":2,"type":"hello","proto":{"major":2,"minor":0},"sim":"fake"}\n'
FULL20 = ('{"v":2,"type":"state","tick":0,"status":"ok","changes":{"rng":{"ai":0},"params":{"epoch":2100,"cruise_phi_default":1.5}},'
          '"events":[],"refused":[],"full":true}\n')
GOOD20 = HELLO20 + FULL20 + '{"n":3,"len":32,"x":0.25}\n'


class Compat(Base):
    def setUp(self):
        super().setUp()
        self.compat = os.path.join(self.replays, "compat-2.0")
        os.makedirs(self.compat)
        self.freeze("c1", GOOD20)

    def freeze(self, name, golden, log=LOG, digest=False):
        if digest:
            with open(os.path.join(self.compat, "%s.state.testarch.sha256" % name), "w") as f:
                f.write(hashlib.sha256(golden.encode()).hexdigest() + "  %s.state.ndjson\n" % name)
        else:
            with open(os.path.join(self.compat, "%s.state.testarch.ndjson" % name), "w") as f:
                f.write(golden)
        with open(os.path.join(self.compat, "inputs.sha256"), "a") as f:
            f.write("%s  %s.ndjson\n" % (hashlib.sha256(log.encode()).hexdigest(), name))

    def test_compat_strips_exactly_the_new_fields(self):
        rc, out = self.replay("--compat", "--case", "c1", FAKE_PROTO="21")
        self.assertEqual(rc, 0, out)
        self.assertIn("1 compared", out)

    def test_compat_fourth_field_fails(self):  # mutation: the harness strips a fourth field
        rc, out = self.replay("--compat", "--case", "c1", FAKE_PROTO="21", FAKE_EXTRA="1")
        self.assertEqual(rc, 1, out)
        self.assertIn("line 2 differs", out)

    def test_compat_compares_bytes_not_parsed_json(self):  # mutation: compare parsed JSON
        rc, out = self.replay("--compat", "--case", "c1", FAKE_PROTO="21", FAKE_FMT="1")
        self.assertEqual(rc, 1, out)
        self.assertIn("line 3 differs", out)

    def test_compat_needs_the_21_fields(self):  # a 2.0 stream is not a 2.1 stream
        rc, out = self.replay("--compat", "--case", "c1", FAKE_PROTO="20")
        self.assertEqual(rc, 1, out)
        self.assertIn("2.1", out)

    def test_compat_changed_input_is_skipped_not_passed(self):  # mutation: pass a log whose input changed
        self.write("c2.ndjson", LOG.replace('"tick":2', '"tick":2,"x":1'))
        self.freeze("c2", GOOD20)  # frozen against the old input
        self.write("c2.ndjson", LOG.replace('"tick":2', '"tick":2,"y":1'))
        rc, out = self.replay("--compat", "--case", "c1", "c2", FAKE_PROTO="21")
        self.assertEqual(rc, 0, out)
        self.assertRegex(out, r"skipped\s+c2\s.*input changed since the freeze")
        self.assertNotRegex(out, r"ok\s+c2\s")
        self.assertIn("1 compared, 1 skipped", out)

    def test_compat_without_a_frozen_golden_is_skipped_and_nothing_compared_fails(self):
        self.write("new.ndjson", LOG)
        rc, out = self.replay("--compat", "--case", "new", FAKE_PROTO="21")
        self.assertEqual(rc, 1, out)
        self.assertRegex(out, r"skipped\s+new\s.*no 2.0 freeze")
        self.assertIn("no case compared", out)

    def test_compat_digest_golden(self):
        self.write("d1.ndjson", LOG)
        self.freeze("d1", GOOD20, digest=True)
        self.assertEqual(self.replay("--compat", "--case", "d1", FAKE_PROTO="21")[0], 0)
        self.freeze("d2", GOOD20 + "x", digest=True)
        self.write("d2.ndjson", LOG)
        rc, out = self.replay("--compat", "--case", "d2", FAKE_PROTO="21")
        self.assertEqual(rc, 1, out)
        self.assertIn("sha256", out)

    def test_compat_interpreter_divergence_fails(self):
        rc, out = self.replay("--compat", "--case", "c1", FAKE_PROTO="21", FAKE_DIVERGE="1")
        self.assertEqual(rc, 1, out)
        self.assertIn("VM != interpreter", out)


# The hand-written design check row (alpha_cen and the protocol logs): a fixed target on an axis at
# 4.37 ly, independent of the catalogue (M1.7 evaluation), so it has no stars.json index.
DESIGN_ROW = "alpha Cen"


def plan_index_mismatches(log_texts, stars):
    """Every plan intent's target index must be the stars.json index of its id."""
    index = {s["id"]: i for i, s in enumerate(stars)}
    bad = []
    for name, text in log_texts:
        for n, line in enumerate(text.splitlines(), 1):
            try:  # some logs carry deliberately malformed lines (refusal tests); they hold no intent
                msg = json.loads(line)
            except ValueError:
                continue
            if not isinstance(msg, dict) or not isinstance(msg.get("intents"), list):
                continue
            for it in msg["intents"]:
                if not isinstance(it, dict):
                    continue
                t = it.get("target")
                if it.get("k") != "plan" or not isinstance(t, dict) or t.get("id") == DESIGN_ROW:
                    continue
                # GalaxyMap.HOME (galaxy_map.gd): Sol is a fixed origin,
                # separate from stars.json, now exercised by M4's return leg.
                if t == {"index": 0, "id": "Sol", "pos": {"x": 0.0, "y": 0.0, "z": 0.0}}:
                    continue
                if index.get(t.get("id")) != t.get("index"):
                    bad.append("%s:%d plan %s index %s, stars.json %s" % (name, n, t.get("id"), t.get("index"), index.get(t.get("id"))))
    return bad


# 7am: a catalogue target written by hand in GDScript or Python carries its stars.json index, as a
# recorded log's must (GalaxyMap.target_name()/subtitle_text() trust the index only when
# catalogue[index].id == id). Both key orders, JSON spacing or none. Ids not in stars.json (Sol, the
# design row, synthetic ports) are not catalogue targets and are skipped. Id literals are decoded first
# (decode_id: \" \\ and \uXXXX); any other escape fails rather than passing as a synthetic id. This file is exempt: its
# controls write wrong pairs on purpose. AILANG sources are out of scope: the sim never reads the
# index (sim/core.ail stores it, sim/protocol.ail echoes it) and its tests number local catalogues.
#  The pair is taken within one dictionary: SOURCE_TOKEN lists each "index" and "id" literal and each
# brace, and other string literals are consumed whole, so a "pos": {...} between the keys does not hide
# the pair, and a nested dictionary's id is never paired with the outer index (both key orders).
SOURCE_TOKEN = re.compile(r'"index"\s*:\s*(-?\d+)|"id"\s*:\s*"((?:[^"\\\n]|\\.)*)"|"(?:[^"\\\n]|\\.)*"|([{}])')
SOURCE_EXEMPT = ("tools/test_replay.py",)
# Pairs left wrong on purpose until Mark rules (7am OQ1): fixing them moves a review capture. Each must
# still be wrong (a stale entry fails), so the list only shrinks.
SOURCE_PENDING = ("tools/earth_link_capture.gd:16",)


def source_files():
    """Tracked *.gd and *.py files, in any directory (git pathspec * crosses /)."""
    out = subprocess.run(["git", "-C", ROOT, "ls-files", "-z", "--", "*.gd", "*.py"], capture_output=True, check=True).stdout
    return sorted(f for f in out.decode().split("\0") if f and f not in SOURCE_EXEMPT)


def decode_id(raw):
    """The id a GDScript or Python string literal spells. Supported escapes, which mean the same in
    GDScript, Python and JSON: \\" \\\\ and \\uXXXX (four hex digits). Any other escape returns None."""
    out, i = [], 0
    while i < len(raw):
        if raw[i] != "\\":
            out.append(raw[i])
            i += 1
        elif raw[i + 1:i + 2] in ('"', "\\"):
            out.append(raw[i + 1])
            i += 2
        elif raw[i + 1:i + 2] == "u" and re.fullmatch(r"[0-9A-Fa-f]{4}", raw[i + 2:i + 6]):
            out.append(chr(int(raw[i + 2:i + 6], 16)))
            i += 6
        else:
            return None
    return "".join(out)


def _level_pairs(level):
    """Every (start, index, raw id) of one dictionary's own level: its index and id literals pair up."""
    idx = [(p, v) for p, k, v in level if k == "index"]
    ids = [(p, v) for p, k, v in level if k == "id"]
    return [(min(p, q), i, raw) for p, i in idx for q, raw in ids]


def source_pairs(text):
    """(start, index, raw id) for each dictionary in text, in source order (dictionary-aware, see SOURCE_TOKEN)."""
    out, frames = [], [[]]
    for m in SOURCE_TOKEN.finditer(text):
        if m.group(3) == "{":
            frames.append([])
        elif m.group(3) == "}":
            if len(frames) > 1:
                out.extend(_level_pairs(frames.pop()))
        elif m.group(1) is not None:
            frames[-1].append((m.start(), "index", m.group(1)))
        elif m.group(2) is not None:
            frames[-1].append((m.start(), "id", m.group(2)))
    for level in frames:  # unclosed braces: the open dictionaries still count
        out.extend(_level_pairs(level))
    return sorted(out)


def source_index_pairs(file_texts, stars):
    """(checked, bad): every hand-written (index, catalogue id) pair, and those whose index is not the id's.
    An id literal with an unsupported escape is reported as bad, never skipped as a synthetic id."""
    index = {s["id"]: i for i, s in enumerate(stars)}
    checked, bad = [], []
    for name, text in file_texts:
        for start, i, raw in source_pairs(text):
            where = "%s:%d" % (name, text.count("\n", 0, start) + 1)
            sid = decode_id(raw)
            if sid is None:
                bad.append('%s unsupported escape in id literal "%s"' % (where, raw))
                continue
            if sid not in index:
                continue
            checked.append(where)
            if int(i) != index[sid]:
                bad.append("%s %s index %s, stars.json %d" % (where, sid, i, index[sid]))
    return checked, bad


class MapIndex(unittest.TestCase):
    """A committed log's plan targets point at the shipped map: index == stars.json index of the id
    (companions round 1: Sirius B moving ahead of Sirius A changed Sirius A's index 8 -> 9)."""

    def logs(self):
        d = os.path.join(ROOT, "tests", "replays")
        return [(f, open(os.path.join(d, f)).read()) for f in sorted(os.listdir(d))
                if f.endswith(".ndjson") and ".state." not in f]

    def stars(self):
        with open(os.path.join(ROOT, "data", "starmap", "stars.json")) as f:
            return json.load(f)["stars"]

    def test_committed_logs_match_the_map(self):
        self.assertEqual(plan_index_mismatches(self.logs(), self.stars()), [])

    def test_a_stale_index_fails(self):  # control: the log as it was before the re-record
        logs = [(n, t.replace('"index":9,"id":"CNS5:1676"', '"index":8,"id":"CNS5:1676"')) for n, t in self.logs()]
        self.assertEqual(len(plan_index_mismatches(logs, self.stars())), 1)

    def test_an_unknown_id_fails(self):
        logs = [(n, t.replace('"id":"CNS5:1676"', '"id":"CNS5:999999"')) for n, t in self.logs()]
        self.assertEqual(len(plan_index_mismatches(logs, self.stars())), 1)
    def test_the_7ai_index_fails(self):  # control: alpha Cen A (CNS5:3627) at HIP 71681's index, as earth_log_voyage had it until 7ai
        stars = self.stars()
        a, b = self.at(stars, "CNS5:3627"), self.at(stars, "HIP 71681")
        good, wrong = '"index":%d,"id":"CNS5:3627"' % a, '"index":%d,"id":"CNS5:3627"' % b
        logs = self.logs()
        n = sum(t.count(good) for _, t in logs)
        bad = plan_index_mismatches([(f, t.replace(good, wrong)) for f, t in logs], stars)
        self.assertGreater(n, 0)
        self.assertEqual(len(bad), n)
        self.assertIn("earth_log_voyage.ndjson:3 plan CNS5:3627 index %d, stars.json %d" % (b, a), bad)

    @staticmethod
    def at(stars, sid):
        return [s["id"] for s in stars].index(sid)

    def sources(self):
        out = []
        for f in source_files():
            with open(os.path.join(ROOT, f), encoding="utf-8") as h:
                out.append((f, h.read()))
        return out

    def test_source_literals_match_the_map(self):  # 7am
        checked, bad = source_index_pairs(self.sources(), self.stars())
        self.assertEqual([b for b in bad if b.split(" ")[0] not in SOURCE_PENDING], [])
        self.assertEqual([p for p in SOURCE_PENDING if p not in [b.split(" ")[0] for b in bad]], [])
        self.assertIn("ui/transit_harness.gd:10", checked)  # known positive: the scan sees a real pair

    def test_source_scan_covers_gd_and_py_in_subdirectories(self):  # 7am: enumeration control
        files = source_files()
        for f in ("ui/transit_harness.gd", "tools/worlds_leak.py", "tests/test_earth_beams.gd"):
            self.assertIn(f, files)
        self.assertNotIn("tools/test_replay.py", files)

    def test_the_7am_literals_fail(self):  # control: each 7am shape, at a wrong index, is caught by name
        stars = self.stars()
        a, b, s9 = self.at(stars, "CNS5:3627"), self.at(stars, "HIP 71681"), self.at(stars, "CNS5:1676")
        texts = [("x.gd", 'const ALPHA := {"index": %d, "id": "CNS5:3627", "pos": {}}\n' % b),
                 ("y.py", 'pass\nt = {"index":%d,"id":"CNS5:1676","pos":{}}\n' % (s9 - 7)),
                 ("z.gd", 'var d:={"id":"CNS5:3627","index":%d,"x":0.}\n' % (a + 1)),
                 ("w.gd", 'const P := {"k": "plan", "target": {"index": 2, "id": "CNS5:1142",\n\t"pos": {}}}\n'),
                 ("ok.gd", 'const A := {"index": %d, "id": "CNS5:3627"}\nconst S := {"index": 0, "id": "Sol"}\n' % a)]
        checked, bad = source_index_pairs(texts, stars)
        self.assertEqual(bad, ["x.gd:1 CNS5:3627 index %d, stars.json %d" % (b, a),
                               "y.py:2 CNS5:1676 index %d, stars.json %d" % (s9 - 7, s9),
                               "z.gd:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
                               "w.gd:1 CNS5:1142 index 2, stars.json %d" % self.at(stars, "CNS5:1142")])
        self.assertEqual(len(checked), 5)  # Sol is not a catalogue id

    def test_the_7am_escaped_ids_fail(self):  # control: an escaped catalogue id is decoded and checked; an unsupported escape fails
        stars = self.stars()
        a, b = self.at(stars, "CNS5:3627"), self.at(stars, "HIP 71681")
        texts = [("e.gd", 'const E := {"index": %d, "id": "\\u0043NS5:3627"}\n' % b),
                 ("q.py", 'Q = {"index": %d, "id": "CNS5\\u003a3627"}\n' % a),
                 ("u.gd", 'const U := {"index": %d, "id": "CNS5\\x3a3627"}\n' % a)]
        checked, bad = source_index_pairs(texts, stars)
        self.assertEqual(checked, ["e.gd:1", "q.py:1"])
        self.assertEqual(bad, ["e.gd:1 CNS5:3627 index %d, stars.json %d" % (b, a),
                               'u.gd:1 unsupported escape in id literal "CNS5\\x3a3627"'])

    def test_the_7am_intervening_fields_fail(self):  # control: a pos field or nested dictionary between the pair does not hide it, either key order
        stars = self.stars()
        a = self.at(stars, "CNS5:3627")
        texts = [("p.gd", 'const P := {"index": 1, "pos": {"x": 1}, "id": "CNS5:3627"}\n'),
                 ("q.gd", 'const Q := {"id": "CNS5:3627", "pos": {}, "index": 1}\n'),
                 ("n.gd", 'const N := {"index": 1, "sub": {"id": "CNS5:3627"}}\n'),
                 ("ok.gd", 'const A := {"index": %d, "pos": {"x": {"y": 1}}, "id": "CNS5:3627"}\n' % a)]
        checked, bad = source_index_pairs(texts, stars)
        self.assertEqual(bad, ["p.gd:1 CNS5:3627 index 1, stars.json %d" % a,
                               "q.gd:1 CNS5:3627 index 1, stars.json %d" % a])
        self.assertEqual(checked, ["p.gd:1", "q.gd:1", "ok.gd:1"])  # n.gd: the nested id is not paired with the outer index


class AiSession(unittest.TestCase):
    """The committed ai_sim_session log is exactly what tools/gen_ai_session.py writes (AI.3)."""

    def test_generator_writes_the_committed_log(self):
        r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "gen_ai_session.py")], capture_output=True, check=True)
        with open(os.path.join(ROOT, "tests", "replays", "ai_sim_session.ndjson"), "rb") as f:
            self.assertEqual(r.stdout, f.read(), "regenerate: python3 tools/gen_ai_session.py tests/replays/ai_sim_session.ndjson")


if __name__ == "__main__":
    unittest.main(verbosity=1)
