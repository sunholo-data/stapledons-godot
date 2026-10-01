"""Independent IEEE bytes and whole-output refusal oracle; no catalogue files written."""
import json
import os
from pathlib import Path
import struct
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
AILANG = os.environ.get("AILANG", str(ROOT / "runtime/bin/ailang"))
FIELDS = ("x", "y", "z", "teff", "v")
BOUNDARY = [0.0, -0.0, 2**-149, -2**-149, 2**-150, -2**-150,
            3*2**-150, -3*2**-150, 2**-126-2**-149, 2**-126,
            1+2**-24, 1+3*2**-24, 2-2**-24,
            3.4028234663852886e38, -3.4028234663852886e38, 99.0, -99.0]

def row(value=1.0, flags=0):
    return dict(id="oracle", x=value, y=2.5, z=-3.25, teff=5202.556030832587,
                v=20.89920219434688, flags=flags)

def expected(rows):
    return list(b"".join(struct.pack("<6f", *(r[k] for k in FIELDS), r["flags"])
                         for r in rows))

def run(entry, args, vm):
    if entry == "oracle":
        args = [[[float(r[k]) for k in (*FIELDS, "flags")] for r in rows] for rows in args]
    cmd = [AILANG, "run", "--quiet", "--package-dir", "sim", "--entry", entry,
           "--args-json", json.dumps(args), "sim/tools/catalogue_bytes_test.ail"]
    if vm:
        cmd.insert(2, "--bytecode")
    result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=60)
    if result.returncode:
        raise AssertionError(result.stderr + result.stdout)
    return json.loads(result.stdout)

class BytesOracle(unittest.TestCase):
    def test_exact_bytes_and_refusals(self):
        cases, wants, names = [], [], []
        def add(name, rows, want=None):
            names.append(name)
            cases.append(rows)
            wants.append(expected(rows) if want is None else want)
        for i, v in enumerate(BOUNDARY):
            add(f"boundary_{i}_{v}", [row(v)])
        for flag in range(32):
            add(f"flag_{flag}", [row(flags=flag)])
        missing = dict(id="missing", x=-0.0, y=2**-149, z=-3.0, teff=0.0, v=99.0, flags=3)
        add("two_records_source_order", [missing, row(flags=5)])
        add("empty", [])
        for field in FIELDS:
            for v in (1e39, -1e39):
                bad = row()
                bad[field] = v
                add(f"reject_{field}_{v}", [bad], [-1])
                add(f"no_prefix_{field}_{v}", [missing, bad], [-1])
                add(f"sticky_error_{field}_{v}", [bad, missing], [-1])
        for flag in (-1, 32):
            add(f"reject_flag_{flag}", [row(flags=flag)], [-1])
            add(f"no_prefix_flag_{flag}", [missing, row(flags=flag)], [-1])
        outputs = [run("oracle", cases, False)] + [run("oracle", cases, True) for _ in range(5)]
        for mode, output in enumerate(outputs):
            self.assertEqual(len(output), len(wants))
            for name, got, want in zip(names, output, wants):
                with self.subTest(mode=mode, case=name):
                    self.assertEqual(got, want)

    def test_nonfinite_each_field(self):
        for vm in (False, True):
            with self.subTest(vm=vm):
                self.assertEqual(run("nonfinite", 0, vm), [[-1]] * 15)

if __name__ == "__main__":
    unittest.main()
