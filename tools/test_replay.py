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


class Replay(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main(verbosity=1)
