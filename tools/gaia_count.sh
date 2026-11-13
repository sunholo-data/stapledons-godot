#!/bin/sh
# R3-REACH RE0b: how many Gaia DR3 stars lie beyond 100 pc, out to 1,000 and 3,000 ly.
# One ADQL COUNT per band and cut, against the public ESA Gaia archive TAP service
# (anonymous, synchronous; a generic client string and nothing else is sent).
#
#   tools/gaia_count.sh > data/reach/gaia_counts.json      (make gaia-counts)
#
# Distance is 1000/parallax pc with no prior, the same rule as sim/tools/extract.ail:
#   100 pc    = parallax 10 mas
#   1,000 ly  = 306.601394 pc = parallax 3.261563777 mas
#   3,000 ly  = 919.804181 pc = parallax 1.087187926 mas
# A count that fails or is not a plain integer aborts the script: nothing is estimated here.
set -eu

TAP="${GAIA_TAP:-https://gea.esac.esa.int/tap-server/tap/sync}"
TABLE=gaiadr3.gaia_source
P1000=3.261563777
P3000=1.087187926

count() {
    out=$(curl -sS --fail -m "${GAIA_TIMEOUT:-600}" -A "curl" "$TAP" \
        --data-urlencode "REQUEST=doQuery" --data-urlencode "LANG=ADQL" \
        --data-urlencode "FORMAT=csv" --data-urlencode "QUERY=$1" | tr -d '\r' | sed -n 2p)
    case "$out" in ''|*[!0-9]*) echo "gaia_count: no integer from the archive for: $1" >&2; exit 1 ;; esac
    printf '%s' "$out"
}

first=1
row() { # row <label> <what> <where clause>
    q="SELECT COUNT(*) AS n FROM $TABLE WHERE $3"
    n=$(count "$q")
    [ "$first" = 1 ] || printf ',\n'
    first=0
    printf '  {"label": "%s", "what": "%s", "adql": "%s", "count": %s}' "$1" "$2" "$q" "$n"
    echo "gaia_count: $1 = $n" >&2
}

printf '{\n "service": "%s",\n "catalogue": "%s",\n "date": "%s",\n "counted": true,\n' "$TAP" "$TABLE" "$(date -u +%Y-%m-%d)"
printf ' "distance": "1000/parallax pc, no prior; 1 pc = 3.261563777 ly",\n "queries": [\n'
row control_100pc_poe5   "inside 100 pc, parallax/error >= 5 (control: GCNS keeps 302,239 of these after its own cleaning)" \
    "parallax >= 10 AND parallax_over_error >= 5"
row shell_1000ly_any     "100 pc to 1,000 ly, any parallax quality" \
    "parallax >= $P1000 AND parallax < 10"
row shell_1000ly_poe5    "100 pc to 1,000 ly, parallax/error >= 5" \
    "parallax >= $P1000 AND parallax < 10 AND parallax_over_error >= 5"
row shell_1000ly_poe5_g14 "100 pc to 1,000 ly, parallax/error >= 5 and G < 14" \
    "parallax >= $P1000 AND parallax < 10 AND parallax_over_error >= 5 AND phot_g_mean_mag < 14"
for g in 15 16 17; do
    row "shell_1000ly_poe5_g$g" "100 pc to 1,000 ly, parallax/error >= 5 and G < $g" \
        "parallax >= $P1000 AND parallax < 10 AND parallax_over_error >= 5 AND phot_g_mean_mag < $g"
done
row shell_3000ly_any     "100 pc to 3,000 ly, any parallax quality" \
    "parallax >= $P3000 AND parallax < 10"
row shell_3000ly_poe5    "100 pc to 3,000 ly, parallax/error >= 5" \
    "parallax >= $P3000 AND parallax < 10 AND parallax_over_error >= 5"
row shell_3000ly_poe5_g14 "100 pc to 3,000 ly, parallax/error >= 5 and G < 14" \
    "parallax >= $P3000 AND parallax < 10 AND parallax_over_error >= 5 AND phot_g_mean_mag < 14"
printf '\n ]\n}\n'
