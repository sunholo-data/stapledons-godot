#!/usr/bin/env python3
"""Parse the raw VizieR star catalogues into a compact CSV. No physics.

Usage:
    python3 tools/extract.py cns5     # data/raw/cns5.dat     -> data/raw/cns5.csv
    python3 tools/extract.py gcns     # data/raw/table1c.dat  -> data/raw/gcns.csv

Output CSV columns: id,x,y,z,G,BPRP,wd
    id    Gaia DR3 source id, verbatim as a string (CNS5 falls back to
          "CNS5:<designation>" for the rows with no Gaia id); never a float.
    x,y,z galactic Cartesian position in light years, Sun at the origin,
          +x towards the galactic centre (IAU ICRS -> galactic matrix below).
          Distance = 1000/plx pc x 3.261563777, plx in mas.  No proper-motion
          propagation: positions are at the catalogue epoch (deep-time motion
          is M2).
    G     Gaia G magnitude, blank when the catalogue has none.
    BPRP  BP - RP, blank unless BOTH BP and RP are present (the quorum rule:
          a missing magnitude is never defaulted).
    wd    1 for a GCNS white-dwarf candidate (WDprob > 0.5), else 0.  CNS5 has
          no WD probability column, so it is always 0.

Rows whose parallax is missing, non-finite or <= 0 are skipped and counted;
missing right ascension or declination skips a row too.  Inputs and outputs
live in the gitignored data/raw/.  If a non-empty input yields zero rows the
program exits non-zero and writes nothing.

Sources (byte column numbers verified against the ReadMe files, 2026-09-28):
  J/A+A/670/A19 cns5.dat   Lrecl 761, 5909 records
  J/A+A/649/A6  table1c.dat Lrecl 760, 331312 records
"""

import math
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = REPO_ROOT / "data" / "raw"

LY_PER_PC = 3.261563777

# IAU ICRS -> galactic rotation matrix (rows: x_gal, y_gal, z_gal).
ICRS_TO_GALACTIC = (
    (-0.0548755604, -0.8734370902, -0.4838350155),
    (+0.4941094279, -0.4448296300, +0.7469822445),
    (-0.8676661490, -0.1980763734, +0.4559837762),
)

CSV_COLUMNS = ("id", "x", "y", "z", "G", "BPRP", "wd")

SOURCES = {"cns5": "cns5.dat", "gcns": "table1c.dat"}
USAGE = "usage: python3 tools/extract.py cns5|gcns"


class EmptyParseError(RuntimeError):
    """A non-empty input produced zero rows."""


def _number(field):
    """A magnitude/angle/parallax field: None for blank, '-' or unparseable."""
    text = field.strip()
    if not text or text == "-":
        return None
    try:
        value = float(text)
    except ValueError:
        return None
    if not math.isfinite(value):
        return None
    return value


def icrs_to_galactic(ra_deg, dec_deg):
    """Unit ICRS direction -> unit galactic direction (x, y, z)."""
    ra = math.radians(ra_deg)
    dec = math.radians(dec_deg)
    v = (math.cos(dec) * math.cos(ra),
         math.cos(dec) * math.sin(ra),
         math.sin(dec))
    return tuple(sum(row[i] * v[i] for i in range(3))
                 for row in ICRS_TO_GALACTIC)


def distance_ly_from_parallax(plx_mas):
    """Light years from a parallax in mas; None when unusable (<= 0/NaN)."""
    if plx_mas is None or not math.isfinite(plx_mas) or plx_mas <= 0.0:
        return None
    return (1000.0 / plx_mas) * LY_PER_PC


def _row(ident, ra, dec, plx, g_mag, bp_mag, rp_mag, wd):
    """One CSV row dict, or None when the row cannot be placed."""
    if ra is None or dec is None:
        return None
    distance_ly = distance_ly_from_parallax(plx)
    if distance_ly is None:
        return None
    unit_x, unit_y, unit_z = icrs_to_galactic(ra, dec)
    # BPRP needs BOTH bands: never derived from one side of the pair.
    bprp = None
    if bp_mag is not None and rp_mag is not None:
        bprp = bp_mag - rp_mag
    return {
        "id": ident,
        "x": unit_x * distance_ly,
        "y": unit_y * distance_ly,
        "z": unit_z * distance_ly,
        "G": g_mag,
        "BPRP": bprp,
        "wd": wd,
    }


def parse_cns5(text):
    """cns5.dat -> (rows, skipped). Byte columns per J/A+A/670/A19 ReadMe."""
    rows = []
    skipped = 0
    for line in text.splitlines():
        if not line.strip():
            continue
        gaia_id = line[27:46].strip()
        designation = line[0:4].strip()
        if gaia_id and gaia_id != "-":
            ident = gaia_id
        elif designation:
            ident = "CNS5:" + designation
        else:
            ident = ""
        row = _row(
            ident,
            _number(line[54:74]),    # RAdeg      bytes  55- 74
            _number(line[75:98]),    # DEdeg      bytes  76- 98
            _number(line[129:148]),  # plx  mas   bytes 130-148
            _number(line[361:371]),  # Gmag       bytes 362-371
            _number(line[394:404]),  # BPmag      bytes 395-404
            _number(line[427:437]),  # RPmag      bytes 428-437
            0,                       # CNS5 has no WD probability column
        )
        if row is None:
            skipped += 1
        else:
            rows.append(row)
    return rows, skipped


def parse_gcns(text):
    """table1c.dat -> (rows, skipped). Byte columns per J/A+A/649/A6 ReadMe."""
    rows = []
    skipped = 0
    for line in text.splitlines():
        if not line.strip():
            continue
        wd_prob = _number(line[245:250])  # WDprob  bytes 246-250
        row = _row(
            line[2:21].strip(),      # GaiaEDR3   bytes   3- 21
            _number(line[22:36]),    # RAdeg      bytes  23- 36
            _number(line[45:59]),    # DEdeg      bytes  46- 59
            _number(line[68:77]),    # Plx  mas   bytes  69- 77
            _number(line[122:130]),  # Gmag       bytes 123-130
            _number(line[141:149]),  # BPmag      bytes 142-149
            _number(line[160:168]),  # RPmag      bytes 161-168
            1 if (wd_prob is not None and wd_prob > 0.5) else 0,
        )
        if row is None:
            skipped += 1
        else:
            rows.append(row)
    return rows, skipped


PARSERS = {"cns5": parse_cns5, "gcns": parse_gcns}


def _format(value):
    return "" if value is None else "%.6f" % value


def format_csv(rows):
    """rows -> CSV text with the fixed header and seven fields per line."""
    lines = [",".join(CSV_COLUMNS)]
    for row in rows:
        lines.append(",".join((row["id"], _format(row["x"]), _format(row["y"]),
                               _format(row["z"]), _format(row["G"]),
                               _format(row["BPRP"]), str(row["wd"]))))
    return "\n".join(lines) + "\n"


def build_csv(kind, text):
    """(csv_text, parsed, skipped); raises if a non-empty input parses to 0."""
    rows, skipped = PARSERS[kind](text)
    if not rows and text.strip():
        raise EmptyParseError(
            "%s: 0 of %d input rows parsed; refusing to write an empty CSV"
            % (kind, len(text.splitlines())))
    return format_csv(rows), len(rows), skipped


def main(argv):
    if len(argv) != 1 or argv[0] not in PARSERS:
        print(USAGE, file=sys.stderr)
        return 2
    kind = argv[0]
    source = RAW_DIR / SOURCES[kind]
    target = RAW_DIR / (kind + ".csv")
    if not source.is_file():
        print("ERROR: missing %s - run "
              ".claude/skills/starmap-manager/scripts/download_stars.sh %s"
              % (source, kind), file=sys.stderr)
        return 2
    try:
        csv_text, parsed, skipped = build_csv(kind, source.read_text())
    except EmptyParseError as exc:
        print("ERROR: %s" % exc, file=sys.stderr)
        return 3
    target.write_text(csv_text)
    print("%s: %s -> %s: parsed %d rows, skipped %d rows (input %d)"
          % (kind, source.name, target.name, parsed, skipped, parsed + skipped))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
