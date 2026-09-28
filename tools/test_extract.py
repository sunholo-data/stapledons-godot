#!/usr/bin/env python3
"""Unit tests for tools/extract.py against REAL-BYTE fixtures.

Run:  python3 tools/test_extract.py
      python3 tools/test_extract.py -v

The fixtures in tools/fixtures/ are raw bytes cut straight out of the
gitignored downloads in data/raw/ - never hand-typed, never edited.  They were
produced by exactly these commands, from the repo root, after:

    bash .claude/skills/starmap-manager/scripts/download_stars.sh quick
    bash .claude/skills/starmap-manager/scripts/download_stars.sh medium

    # cns5.dat (VizieR J/A+A/670/A19, Lrecl 761, 5909 records)
    sed -n '1,20p' data/raw/cns5.dat > tools/fixtures/cns5_head.dat
    # alpha Cen: `grep -n 559 data/raw/cns5.dat | head` returns one row, line
    # 5103, CNS5=3627 GJ=559 Comp=AB - CNS5 carries the AB system, not separate
    # A/B rows (eyeballed against the ReadMe byte columns 1-4/6-11/13-16).
    sed -n '5103p' data/raw/cns5.dat > tools/fixtures/cns5_alpha_cen.dat
    # G present, BP blank, RP present (the one-sided-pair case)
    awk 'substr($0,362,10) ~ /[0-9]/ && substr($0,395,10) ~ /^ *$/ \\
         && substr($0,428,10) ~ /[0-9]/' data/raw/cns5.dat | head -1 \\
        > tools/fixtures/cns5_bp_blank_rp_set.dat
    # the single row with a blank parallax (CNS5=0, a placeholder record)
    awk 'substr($0,130,19) ~ /^ *$/' data/raw/cns5.dat \\
        > tools/fixtures/cns5_null_plx.dat

    # table1c.dat (VizieR J/A+A/649/A6, Lrecl 760, 331312 records)
    sed -n '1,20p' data/raw/table1c.dat > tools/fixtures/gcns_head.dat
    awk 'substr($0,246,5)+0 > 0.5' data/raw/table1c.dat | head -1 \\
        > tools/fixtures/gcns_wd.dat                    # WDprob 0.924 -> wd=1
    awk 'substr($0,246,5) == "1.000"' data/raw/table1c.dat | head -1 \\
        > tools/fixtures/gcns_wd_1p000.dat              # WDprob 1.000 -> wd=1
    awk 'substr($0,246,5)+0 == 0.5' data/raw/table1c.dat | head -1 \\
        > tools/fixtures/gcns_wdprob_050.dat            # WDprob 0.500 -> wd=0
    awk 'substr($0,246,5)+0 > 0.5 && substr($0,246,5)+0 <= 0.509' \\
        data/raw/table1c.dat | head -1 \\
        > tools/fixtures/gcns_wdprob_0506.dat           # WDprob 0.506 -> wd=1
    awk 'substr($0,123,8) ~ /^ *$/' data/raw/table1c.dat | head -1 \\
        > tools/fixtures/gcns_missing_phot.dat          # blank Gmag, blank BP

The awk field numbers above are 1-based byte columns, i.e. the ReadMe's own
byte numbers; tools/extract.py uses the equivalent 0-based half-open Python
slices.

Measured expectations (2026-09-28, planner's task-1 evidence reproduced
byte-for-byte):
  * A19 ReadMe 200 / 10530 B / cns5.dat Lrecl 761 Records 5909
  * A6  ReadMe 200 / 39878 B / table1c.dat Lrecl 760 Records 331312
  * cns5.dat 4502658 B, table1c.dat 252128432 B, both LF-only
  * alpha Cen (CNS5 3627, plx 754.81 mas) -> 4.3210 ly, l=315.74 b=-0.684.
    NOTE: the sprint plan predicted 4.370 ly; that is the popular literature
    figure for the AB system and is NOT what CNS5's own parallax column
    yields (1000/754.81 pc = 1.32484 pc = 4.3210 ly).  The fixture row is
    confirmed by the plan's own direction expectation (l 315.7, b -0.68).
"""

import math
import os
import pathlib
import shutil
import unittest

import extract

HERE = os.path.dirname(os.path.abspath(__file__))
FIX = os.path.join(HERE, "fixtures")

LY_PER_PC = 3.261563777


def read_fixture(name):
    """Read a fixture byte-exactly (no newline translation)."""
    with open(os.path.join(FIX, name), newline="") as fh:
        return fh.read()


def unit_distance_lb(row):
    """(distance_ly, l_deg, b_deg) of a parsed row, from its galactic xyz."""
    x, y, z = row["x"], row["y"], row["z"]
    d = math.sqrt(x * x + y * y + z * z)
    l = math.degrees(math.atan2(y, x)) % 360.0
    b = math.degrees(math.asin(z / d))
    return d, l, b


def rows_by_id(rows):
    return {r["id"]: r for r in rows}


def assert_ids_verbatim(case, csv_text, fixture_text):
    """Every CSV id must come from the raw bytes verbatim, not re-formatted.

    A 19-digit Gaia id does not survive a float64 round-trip (19 of the 39
    numeric ids in these two fixtures change), so formatting the id through a
    float is caught even though the first row's id happens to be exact.
    """
    data_lines = csv_text.splitlines()[1:]
    fixture_lines = fixture_text.splitlines()
    case.assertEqual(len(data_lines), len(fixture_lines))
    for csv_line, raw in zip(data_lines, fixture_lines):
        ident = csv_line.split(",")[0]
        bare = ident[len("CNS5:"):] if ident.startswith("CNS5:") else ident
        case.assertIn(bare, raw, "%r is not verbatim in %r" % (ident, raw))


class AlphaCenTest(unittest.TestCase):
    """The nearest known star pins the rotation matrix and the pc->ly factor."""

    def setUp(self):
        self.rows, self.skipped = extract.parse_cns5(read_fixture("cns5_alpha_cen.dat"))
        self.assertEqual(self.skipped, 0)
        self.assertEqual(len(self.rows), 1)
        self.row = self.rows[0]

    def test_alpha_cen_distance(self):
        # Kills: the pc->ly factor (3.261563777) being dropped (1.3248 instead
        # of 4.3210) or inverted.
        d, _, _ = unit_distance_lb(self.row)
        self.assertAlmostEqual(d, 4.3210, delta=0.02)

    def test_alpha_cen_direction(self):
        # Kills: an x<->y axis permutation, a sign flip in any rotation-matrix
        # row, and a degrees-vs-radians mix-up.
        _, l, b = unit_distance_lb(self.row)
        self.assertAlmostEqual(l, 315.74, delta=0.5)
        self.assertAlmostEqual(b, -0.684, delta=0.5)


class GalacticXyzTest(unittest.TestCase):
    def test_gcns_xyz_crosscheck(self):
        # Kills: using -A instead of A (galactocentric sign error), and a pc/ly
        # unit slip (x1000).  The row carries its own galactic x50/y50/z50 in
        # pc, read here with the ReadMe's bytes 304-315 / 343-354 / 382-393.
        line = read_fixture("gcns_head.dat").splitlines()[0]
        x50 = float(line[303:315])
        y50 = float(line[342:354])
        z50 = float(line[381:393])

        rows, skipped = extract.parse_gcns(line + "\n")
        self.assertEqual(skipped, 0)
        self.assertEqual(len(rows), 1)
        row = rows[0]

        for got, want_pc in ((row["x"], x50), (row["y"], y50), (row["z"], z50)):
            want_ly = want_pc * LY_PER_PC
            self.assertLess(abs(got - want_ly) / abs(want_ly), 0.05,
                            f"{got} vs {want_ly}")


class WhiteDwarfTest(unittest.TestCase):
    def test_gcns_wd_flag(self):
        # Kills: `>` read as `>=` (the 0.500 row would flag), and a WDprob
        # slice shifted by one byte in EITHER direction.  A 5-byte F5.3 field
        # makes the shift nearly invisible: +1 drops the leading digit
        # ("1.000" -> ".000" = 0.0, so only a 1.000 row exposes it) and -1
        # keeps two decimals (0.506 -> 0.50, so only a 0.501..0.509 row
        # exposes it).  Hence the two extra boundary fixtures below: the
        # plan's 0.924 row alone kills neither direction.
        for name, expected in (("gcns_wd.dat", 1),           # 0.924
                               ("gcns_wd_1p000.dat", 1),     # 1.000
                               ("gcns_wdprob_050.dat", 0),   # 0.500 boundary
                               ("gcns_wdprob_0506.dat", 1)):  # 0.506
            with self.subTest(fixture=name):
                rows, skipped = extract.parse_gcns(read_fixture(name))
                self.assertEqual(skipped, 0)
                self.assertEqual(len(rows), 1)
                self.assertEqual(rows[0]["wd"], expected)

    def test_cns5_never_flags_wd(self):
        # CNS5 carries no WD probability column at all.
        rows, _ = extract.parse_cns5(read_fixture("cns5_head.dat"))
        self.assertEqual([r["wd"] for r in rows], [0] * len(rows))


class MissingPhotometryTest(unittest.TestCase):
    def test_missing_phot_cns5(self):
        # Kills: any default (0.0, or the old skill's 10.0) for a missing
        # magnitude.  The alpha Cen row and cns5_head row 3 have no G/BP/RP.
        rows, _ = extract.parse_cns5(
            read_fixture("cns5_alpha_cen.dat") + read_fixture("cns5_head.dat")
        )
        self.assertEqual(rows[0]["G"], None)
        self.assertEqual(rows[0]["BPRP"], None)
        # cns5_head line 3 is the second fixture row (index 3): no Gaia id,
        # no G, no BP, no RP.
        self.assertEqual(rows[3]["G"], None)
        self.assertEqual(rows[3]["BPRP"], None)

        csv_text, _, _ = extract.build_csv(
            "cns5", read_fixture("cns5_alpha_cen.dat")
        )
        fields = csv_text.splitlines()[1].split(",")
        self.assertEqual(fields[4], "")  # G
        self.assertEqual(fields[5], "")  # BPRP

    def test_bprp_needs_both(self):
        # Kills: checking only one side of the pair (BP blank but RP present
        # must still leave BPRP empty - line 431 / CNS5 1421).
        text = read_fixture("cns5_bp_blank_rp_set.dat")
        rows, skipped = extract.parse_cns5(text)
        self.assertEqual(skipped, 0)
        self.assertEqual(len(rows), 1)
        self.assertIsNotNone(rows[0]["G"])
        self.assertIsNone(rows[0]["BPRP"])

        csv_text, _, _ = extract.build_csv("cns5", text)
        self.assertEqual(csv_text.splitlines()[1].split(",")[5], "")

    def test_gcns_missing_phot_has_partial_photometry(self):
        # The fixture has a real RP but no G and no BP: BPRP must still be
        # empty, because BP is absent.
        rows, skipped = extract.parse_gcns(read_fixture("gcns_missing_phot.dat"))
        self.assertEqual(skipped, 0)
        self.assertEqual(len(rows), 1)
        self.assertIsNone(rows[0]["G"])
        self.assertIsNone(rows[0]["BPRP"])


class ParallaxTest(unittest.TestCase):
    def test_plx_skip_count(self):
        # Kills: a silent division by zero / negative distance.  cns5_head has
        # 20 usable rows; cns5_null_plx is the one real row with a blank plx.
        text = read_fixture("cns5_head.dat") + read_fixture("cns5_null_plx.dat")
        rows, skipped = extract.parse_cns5(text)
        self.assertEqual(len(rows), 20)
        self.assertEqual(skipped, 1)
        self.assertEqual(len(rows) + skipped, 21)
        # every kept row is at a sane distance
        for row in rows:
            d, _, _ = unit_distance_lb(row)
            self.assertTrue(0.0 < d < 10000.0, d)

    def test_distance_ly_from_parallax_guard(self):
        # The <=0 / missing branch itself, independent of any fixture.
        self.assertIsNone(extract.distance_ly_from_parallax(None))
        self.assertIsNone(extract.distance_ly_from_parallax(0.0))
        self.assertIsNone(extract.distance_ly_from_parallax(-1.0))
        self.assertIsNone(extract.distance_ly_from_parallax(float("nan")))
        self.assertAlmostEqual(
            extract.distance_ly_from_parallax(754.8099975585938), 4.3210, delta=0.001
        )


class CsvSchemaTest(unittest.TestCase):
    def test_csv_schema(self):
        # Kills: a column reorder, and an id parsed to float and re-formatted
        # (19-digit Gaia ids do not survive float64 round-tripping).
        text = read_fixture("cns5_head.dat")
        csv_text, parsed, skipped = extract.build_csv("cns5", text)
        lines = csv_text.splitlines()

        self.assertEqual(lines[0], "id,x,y,z,G,BPRP,wd")
        self.assertEqual(parsed, 20)
        self.assertEqual(skipped, 0)
        self.assertEqual(len(lines), 21)
        for line in lines[1:]:
            self.assertEqual(len(line.split(",")), 7, line)

        # the id is the fixture's own bytes, verbatim (GaiaDR3 = bytes 28-46)
        raw_id = text.splitlines()[0][27:46].strip()
        self.assertEqual(raw_id, "1871118140493076224")
        self.assertEqual(lines[1].split(",")[0], raw_id)
        assert_ids_verbatim(self, csv_text, text)

        # body column order matches the header: G at field 4, BPRP at field 5
        first = text.splitlines()[0]
        fields = lines[1].split(",")
        self.assertAlmostEqual(float(fields[4]), float(first[361:371]), places=6)
        self.assertAlmostEqual(
            float(fields[5]),
            float(first[394:404]) - float(first[427:437]),
            places=6,
        )

    def test_gcns_csv_schema(self):
        text = read_fixture("gcns_head.dat")
        csv_text, parsed, skipped = extract.build_csv("gcns", text)
        lines = csv_text.splitlines()
        self.assertEqual(lines[0], "id,x,y,z,G,BPRP,wd")
        self.assertEqual(parsed, 20)
        self.assertEqual(skipped, 0)
        for line in lines[1:]:
            self.assertEqual(len(line.split(",")), 7, line)
        self.assertEqual(lines[1].split(",")[0], "2334666126716440064")
        assert_ids_verbatim(self, csv_text, text)

    def test_cns5_id_fallback(self):
        # cns5_head row 3 has no GaiaDR3 id ("-" in the ReadMe's ?=- column),
        # so the id falls back to CNS5:<designation>.
        rows, _ = extract.parse_cns5(read_fixture("cns5_head.dat"))
        self.assertEqual(rows[2]["id"], "CNS5:5240")


class LoudFailureTest(unittest.TestCase):
    def test_empty_parse_raises(self):
        # A non-empty input that yields zero rows must raise, not return an
        # empty CSV.
        text = read_fixture("cns5_null_plx.dat")
        self.assertTrue(text.strip())
        with self.assertRaises(extract.EmptyParseError):
            extract.build_csv("cns5", text)

    def test_main_exits_nonzero_without_writing_csv(self):
        # End-to-end: main() must exit non-zero and must not create the CSV.
        scratch = os.path.join(extract.RAW_DIR, "_test_extract_scratch")
        shutil.rmtree(scratch, ignore_errors=True)
        os.makedirs(scratch)
        try:
            with open(os.path.join(scratch, "cns5.dat"), "w") as fh:
                fh.write(read_fixture("cns5_null_plx.dat"))
            saved = extract.RAW_DIR
            extract.RAW_DIR = pathlib.Path(scratch)
            try:
                rc = extract.main(["cns5"])
            finally:
                extract.RAW_DIR = saved
            self.assertNotEqual(rc, 0)
            self.assertFalse(os.path.exists(os.path.join(scratch, "cns5.csv")))
        finally:
            shutil.rmtree(scratch, ignore_errors=True)


if __name__ == "__main__":
    unittest.main()
