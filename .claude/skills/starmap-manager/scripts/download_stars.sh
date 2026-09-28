#!/bin/bash
# Download raw star catalogue data for Stapledon's Voyage.
#
# Usage: download_stars.sh <tier>
#   quick  - CNS5 (VizieR J/A+A/670/A19, cns5.dat), 5,909 records, fixed width 761 B
#   medium - GCNS selected objects (VizieR J/A+A/649/A6, table1c.dat.gz),
#            331,312 records, 760 B uncompressed
#   large  - the same GCNS bytes as medium; the tier difference is made by
#            tools/extract.py + sim/tools/catalogue.ail, not by the download
#
# Everything lands in data/raw/ (gitignored). For every artifact this script
# prints its byte size and sha256, and appends "<sha256>  <name>" to
# data/raw/SHA256SUMS (one line per artifact, re-running replaces the line).
#
# Sources are the CDS/VizieR FTP mirrors only. Two former sources are gone
# entirely: the Gaia Sky CNS5 host (its catalog URL now answers 404, recorded
# as evidence in the sprint JSON) and the V/70A votable fallback, which
# resolved to an unrelated catalogue.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
RAW_DIR="$PROJECT_ROOT/data/raw"
SUMS="$RAW_DIR/SHA256SUMS"
CURL_MAX_TIME="${CURL_MAX_TIME:-900}"

TIER="${1:-quick}"

mkdir -p "$RAW_DIR"

# Godot treats every .csv under the project as a translations source: without
# this, `godot --import` (i.e. `make test` -> `make import`) turns the 24 MB
# data/raw/gcns.csv into ~70 MB of *.translation sidecars in data/raw.  The
# catalogues are read as plain files by Python and AILANG, never as Godot
# resources, so the directory must not be scanned.
touch "$RAW_DIR/.gdignore"

# record <name-in-raw>: log size + sha256, and keep exactly one SUMS line for it
record() {
    local name="$1"
    local file="$RAW_DIR/$name"
    local size sum

    size="$(wc -c < "$file" | tr -d ' ')"
    sum="$(cd "$RAW_DIR" && shasum -a 256 "$name" | awk '{print $1}')"

    echo "  size:   $size bytes"
    echo "  sha256: $sum"

    if [ -f "$SUMS" ]; then
        grep -v "  $name\$" "$SUMS" > "$SUMS.tmp" || true
        mv "$SUMS.tmp" "$SUMS"
    fi
    echo "$sum  $name" >> "$SUMS"
}

# fetch <url> <name-in-raw>: download with --fail, then record it
fetch() {
    local url="$1"
    local name="$2"

    echo "  GET $url"
    if ! curl -L --fail --silent --show-error --max-time "$CURL_MAX_TIME" \
            -o "$RAW_DIR/$name" "$url"; then
        echo "  ERROR: download failed: $url" >&2
        echo "  (manual fallback: https://cdsarc.cds.unistra.fr/viz-bin/cat/...)" >&2
        exit 1
    fi
    record "$name"
}

A19_BASE="https://cdsarc.cds.unistra.fr/ftp/J/A+A/670/A19"
A6_BASE="https://cdsarc.cds.unistra.fr/ftp/J/A+A/649/A6"

echo "=== Starmap Data Downloader ==="
echo "Tier:   $TIER"
echo "Output: $RAW_DIR"
echo ""

case "$TIER" in
    quick)
        echo "CNS5 (Catalogue of Nearby Stars, 5th edition)"
        echo "  Records: 5,909   Lrecl: 761"
        echo ""
        fetch "$A19_BASE/cns5.dat"  "cns5.dat"
        fetch "$A19_BASE/ReadMe"    "cns5_readme.txt"
        echo ""
        echo "Quick tier complete!"
        ;;

    medium)
        echo "GCNS (Gaia Catalogue of Nearby Stars) - selected objects"
        echo "  Records: 331,312   Lrecl: 760"
        echo "  Selection to ~50,000 nearest complete-photometry rows happens in"
        echo "  sim/tools/catalogue.ail (tier=medium), not here."
        echo ""
        fetch "$A6_BASE/table1c.dat.gz" "table1c.dat.gz"
        echo "  gunzip -> table1c.dat"
        gunzip -kf "$RAW_DIR/table1c.dat.gz"
        fetch "$A6_BASE/ReadMe" "gcns_readme.txt"
        echo ""
        echo "Medium tier complete!"
        ;;

    large)
        echo "GCNS (Gaia Catalogue of Nearby Stars) - full table1c"
        echo "  Records: 331,312 (same bytes as medium)"
        echo ""
        fetch "$A6_BASE/table1c.dat.gz" "table1c.dat.gz"
        echo "  gunzip -> table1c.dat"
        gunzip -kf "$RAW_DIR/table1c.dat.gz"
        fetch "$A6_BASE/ReadMe" "gcns_readme.txt"
        echo ""
        echo "Large tier complete!"
        ;;

    *)
        echo "ERROR: Unknown tier '$TIER'" >&2
        echo "Usage: $0 <quick|medium|large>" >&2
        exit 1
        ;;
esac

echo ""
echo "SHA256SUMS ($(wc -l < "$SUMS" | tr -d ' ') artifacts):"
cat "$SUMS"
