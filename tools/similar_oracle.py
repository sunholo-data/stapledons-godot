#!/usr/bin/env python3
"""Independent stdlib oracle for S0 vectors, all distances and nearest order.

Inputs below are typed from cited tables, never read from the AILANG encoder.
The --strip-similar mode is compatibility-test harness glue in this oracle:
it removes only the raw new_game similar field and comma, with no reserialization.
It is never a game or data pipeline step.
"""

import json
import math
from pathlib import Path
import sys

TOL = 1e-12
EARTH_RADIUS = 6378.1366
EARTH_GM = 398600.43550702266
# Archinal 2018 equatorial radius (km), Park 2021 DE440 GM (km^3/s^2),
# Standish 1992 Table 2a semi-major axis (AU). sim/data/sol.ail citations.
SOL = [
    ("mercury", "Mercury", 2440.53, 22031.868551400003, 0.38709843),
    ("venus", "Venus", 6051.8, 324858.592, 0.72332102),
    ("earth", "Earth", 6378.1366, 398600.43550702266, 1.00000018),
    ("mars", "Mars", 3396.19, 42828.37362069909, 1.52371243),
    ("jupiter", "Jupiter", 71492.0, 126686531.9003704, 5.20248019),
    ("saturn", "Saturn", 60268.0, 37931206.23436167, 9.54149883),
    ("uranus", "Uranus", 25559.0, 5793951.256527211, 19.18797948),
    ("neptune", "Neptune", 24764.0, 6835103.145462294, 30.06952752),
]
# Agol 2021, NASA Exoplanet Archive ps snapshot 2026-10-07:
# radius (nominal Earth units), mass (Earth units), a (AU).
# IAU 2015 B3: nominal equatorial Earth radius 6378.1 km.
# Agol 2021 host L = 0.000553 L_sun. sim/data/{trappist1,stars}.ail.
TRAPPIST = [
    ("b", 1.116, 1.374, 0.01154),
    ("c", 1.097, 1.308, 0.0158),
    ("d", 0.788, 0.388, 0.02227),
    ("e", 0.92, 0.692, 0.02925),
    ("f", 1.045, 1.039, 0.03849),
    ("g", 1.129, 1.321, 0.04683),
    ("h", 0.755, 0.326, 0.06189),
]
CITE = "stapledons-design/features/next/semantic-memory.md S0"
FEATURES = [dict(key=k, divisor=d, cite=CITE) for k, d in
            [("ln_radius", 1), ("ln_mass", 3), ("ln_insolation", 2)]]


def close(actual, expected):
    assert math.isfinite(actual) and abs(actual - expected) <= TOL, (actual, expected)


def reference():
    rows = [(i, n, r / EARTH_RADIUS, gm / EARTH_GM, 1.0 / (a * a))
            for i, n, r, gm, a in SOL]
    rows += [("trappist-1" + letter, "TRAPPIST-1 " + letter,
              r * 6378.1 / EARTH_RADIUS, m, 0.000553 / (a * a))
             for letter, r, m, a in TRAPPIST]
    return {i: dict(name=n, s=s, vector=[math.log(r), math.log(m) / 3.0, math.log(s) / 2.0])
            for i, n, r, m, s in rows}


def check(path):
    replies = [json.loads(line) for line in Path(path).read_text().splitlines()]
    assert len(replies) == 3
    assert replies[0]["proto"]["minor"] in (14, 15)
    section = replies[1]["changes"]["similar"]
    assert all("similar" not in r.get("changes", {}) for r in (replies[0], replies[2]))
    assert list(section) == ["model", "k", "features", "excluded", "worlds"]
    assert section["model"] == "s0-v1" and section["k"] == 3
    assert section["features"] == FEATURES and section["excluded"] == []
    ref = reference()
    assert [w["id"] for w in section["worlds"]] == list(ref)
    worlds = {w["id"]: w for w in section["worlds"]}
    for i, w in worlds.items():
        assert list(w) == ["id", "name", "s_earth", "vector", "near"]
        assert w["name"] == ref[i]["name"] and len(w["vector"]) == 3
        close(w["s_earth"], ref[i]["s"])
        for actual, expected in zip(w["vector"], ref[i]["vector"]):
            close(actual, expected)
        # Compare all 14 directed distances, including the 11 not transmitted.
        # Sort both complete orders before checking the transmitted first three.
        expected = []
        measured = []
        for j, other in worlds.items():
            if i == j:
                continue
            d = math.dist(ref[i]["vector"], ref[j]["vector"])
            actual = math.dist(w["vector"], other["vector"])
            close(actual, d)
            expected.append((d, ref[j]["name"], j))
            measured.append((actual, other["name"], j))
        expected.sort()
        measured.sort()
        assert [x[2] for x in measured] == [x[2] for x in expected]
        assert [n["id"] for n in w["near"]] == [x[2] for x in expected[:3]]
        for near, (distance, _, _) in zip(w["near"], expected[:3]):
            assert list(near) == ["id", "d"]
            close(near["d"], distance)
    print(f"{path}: oracle ok, 15 typed vectors, 210 directed distances, full orders (1e-12)")


def strip_similar(source, output):
    lines = Path(source).read_bytes().splitlines(keepends=True)
    assert len(lines) == 3
    token = b'"similar":'
    assert lines[1].count(token) == 1
    assert token not in lines[0] and token not in lines[2]
    start = lines[1].index(token)
    assert lines[1][start - 1:start] == b','
    tail = lines[1][start + len(token):].decode("utf-8")
    section, end = json.JSONDecoder().raw_decode(tail)
    assert isinstance(section, dict)
    stop = start + len(token) + len(tail[:end].encode("utf-8"))
    if json.loads(lines[0])["proto"]["minor"] == 15:
        assert lines[1][stop:stop + 1] == b','
        assert lines[1][stop + 1:].startswith(b'"archive":')
        lines[1] = lines[1][:start] + lines[1][stop + 1:]
    else:
        assert lines[1][stop:stop + 1] == b'}'
        lines[1] = lines[1][:start - 1] + lines[1][stop:]
    Path(output).write_bytes(b"".join(lines))


if __name__ == "__main__":
    if len(sys.argv) == 4 and sys.argv[1] == "--strip-similar":
        strip_similar(sys.argv[2], sys.argv[3])
    elif len(sys.argv) == 2:
        check(sys.argv[1])
    else:
        sys.exit("usage: similar_oracle.py FIXTURE | --strip-similar INPUT OUTPUT")
