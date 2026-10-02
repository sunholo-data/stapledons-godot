#!/usr/bin/env python3
"""Unit tests for tools/replay.py against a fake ailang (no AILANG needed).

They pin the harness's teeth: a VM-only harness, a loose golden compare, a
dropped reply and a stale digest must each fail. Run: python3 tools/test_replay.py
"""
import hashlib
import os
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


class AiSession(unittest.TestCase):
    """The committed ai_sim_session log is exactly what tools/gen_ai_session.py writes (AI.3)."""

    def test_generator_writes_the_committed_log(self):
        r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "gen_ai_session.py")], capture_output=True, check=True)
        with open(os.path.join(ROOT, "tests", "replays", "ai_sim_session.ndjson"), "rb") as f:
            self.assertEqual(r.stdout, f.read(), "regenerate: python3 tools/gen_ai_session.py tests/replays/ai_sim_session.ndjson")


if __name__ == "__main__":
    unittest.main(verbosity=1)
