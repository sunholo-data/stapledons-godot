#!/usr/bin/env python3
"""Independent Decimal60 RK-1/2 seed; u=r/(GM/c^2), package R=u/2 in r_s."""
import json
import sys
from decimal import Decimal, getcontext
from pathlib import Path

getcontext().prec = 60

def horizons(spin):
    s = Decimal(spin)
    if not s.is_finite() or not 0 <= s < 1:
        raise ValueError("spin must be finite 0 <= spin < 1")
    delta = (1 - s * s).sqrt()
    return 1 + delta, 1 - delta

def fixture():
    records = []
    for spin in ("0", "0.5", "0.9", "0.998"):
        outer, inner = horizons(spin)
        for number, (quantity, u, sign) in enumerate((("outer", outer, "+"), ("inner", inner, "-")), 1):
            records.append({"id": f"RK-{number}", "spin": spin, "quantity": quantity,
                            "precise": format(u, ".17g"), "display": format(u, ".6f"),
                            "package_R": format(u / 2, ".17g"), "formula": f"u=1{sign}sqrt(1-spin^2)"})
    return {"schema": "kerr-rk-seed-v1", "unit": "GM/c^2",
            "source": "BPT72 ApJ178,347 §II; design_docs/planned/r2/kerr-black-holes.md V31",
            "records": records}

def unique_keys(pairs):
    result = dict(pairs)
    if len(result) != len(pairs):
        raise ValueError("duplicate JSON key")
    return result

def main():
    expected = fixture()
    if len(sys.argv) == 1:
        print("{")
        for key, value in expected.items():
            if key != "records":
                print(f"  {json.dumps(key)}: {json.dumps(value)},")
        print('  "records": [')
        print(",\n".join("    " + json.dumps(row) for row in expected["records"]))
        print("  ]\n}")
    elif len(sys.argv) == 3 and sys.argv[1] in ("--check", "check"):
        actual = json.loads(Path(sys.argv[2]).read_text(), object_pairs_hook=unique_keys)
        if actual != expected:
            raise ValueError("fixture schema/metadata/records mismatch")
    else:
        raise ValueError("usage: kerr_ref.py [--check|check <path>]")

if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError) as error:
        print(f"kerr-oracle: {error}", file=sys.stderr)
        sys.exit(1)
