#!/bin/sh
# Row 7l(a): capture-m4-publish checks all 18 files before its first upload.
# Runs the real recipe through every distinct GNU make on PATH against a private fixture
# (M4_PUBLISH_DIR=...), with a fake gcloud that only logs. PATH is narrowed to the fake plus
# /usr/bin:/bin, so no real gcloud is reachable and nothing is ever uploaded.
set -u
# Under `make test` the outer make's flags would reach the fixture makes (iteration 56).
unset MAKELEVEL MAKEFLAGS MFLAGS MAKEOVERRIDES GNUMAKEFLAGS MAKE_TERMOUT MAKE_TERMERR
ROOT=${1:?usage: test_m4_publish.sh ROOT}
cd "$ROOT" || exit 1
ROOT=$(pwd -P)
T=$(mktemp -d "${TMPDIR:-/tmp}/m4-publish-test.XXXXXX") || exit 1
trap 'rm -rf "$T"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
# Every make runs under the 7l drills' deadline (doc body), plus one line: a TERM, INT or HUP to this
# script's group is forwarded as KILL to the child's own group, which the outer signal cannot reach.
# 124 is INFRASTRUCTURE, never a case result.
deadline() { # deadline SECONDS CMD...: CMD's rc; 124 on expiry (TERM to its process group, KILL 5 s later)
  perl -e '
    my $s = shift; my $pid = fork; exit 125 unless defined $pid;
    if ($pid == 0) { setpgrp(0, 0); exec @ARGV; exit 127 }
    setpgrp($pid, $pid); my $hit = 0;
    $SIG{$_} = sub { kill "KILL", -$pid; exit 124 } for qw(TERM INT HUP);
    $SIG{ALRM} = sub { kill(($hit++ ? "KILL" : "TERM"), -$pid); alarm 5 };
    alarm $s; waitpid($pid, 0); my $rc = $?; alarm 0;
    exit($rc & 127 ? 128 + ($rc & 127) : $rc >> 8) unless $hit;
    my $t = time + 5; select(undef, undef, undef, 0.2) while kill(0, -$pid) && time < $t;
    kill "KILL", -$pid; exit 124;' "$@" < /dev/null
}
PROBE_S=10 MAKE_S=20
infra() { echo "capture-m4-publish-test: INFRASTRUCTURE timeout after $1 s: $2"; exit 124; }
mkdir "$T/bin" "$T/fx" || exit 1
cat > "$T/bin/gcloud" <<STUB || exit 1
#!/bin/sh
for a in "\$@"; do printf '%s|' "\$a"; done >> "$T/log"; printf '\n' >> "$T/log"
STUB
chmod +x "$T/bin/gcloud" || exit 1
NP=$T/bin:/usr/bin:/bin
B=gs://stapledons-voyage-assets/refs/m4_ship_s1/
if [ "$(PATH=$NP command -v gcloud)" != "$T/bin/gcloud" ]; then echo "capture-m4-publish-test: FAIL the fake gcloud is not first on PATH"; exit 1; fi
makes=; versions=; nm=0
for candidate in make gmake; do
  path=$(command -v "$candidate" 2>/dev/null) || continue
  prc=0; deadline "$PROBE_S" "$path" --version > "$T/version" 2>/dev/null || prc=$?
  if [ "$prc" = 124 ]; then infra "$PROBE_S" "$path --version"; fi
  version=$(sed -n '1p' "$T/version")
  case "$version" in 'GNU Make '*) ;; *) continue ;; esac
  if printf '%s\n' "$versions" | grep -Fqx "$version"; then continue; fi
  makes="$makes $path"; versions="${versions}${version}
"; nm=$((nm + 1))
done
if [ "$nm" = 0 ]; then echo "capture-m4-publish-test: FAIL no GNU make on PATH"; exit 1; fi
fixture() {
  rm -rf "$T/fx" && mkdir "$T/fx" || return 1
  for s in 01_docked 02_boost_b05 03_boost_b09 04_cruise_099 05_brake_b05 06_arrived_acen 07_arrived_home; do
    for v in deck forward; do printf 'png %s_%s\n' "$s" "$v" > "$T/fx/${s}_$v.png" || return 1; done
  done
  printf 'png contact_sheet\n' > "$T/fx/contact_sheet.png" &&
  (cd "$T/fx" && shasum -a 256 ./*.png | sed 's|  \./|  |' > m4_manifest.sha256) &&
  for f in "$T"/fx/0*.png; do printf '%064d  %s\n' 0 "${f##*/}"; done > "$T/fx/worlds.sha256" &&
  printf '{"frames": []}\n' > "$T/fx/manifest.json"
}
fails=0; i=0
for M in $makes; do
  i=$((i + 1)); version=$(printf '%s' "$versions" | sed -n "${i}p")
  for c in complete worlds-missing worlds-empty worlds-short manifest-missing png-missing hash-mismatch; do
    fixture || { echo "capture-m4-publish-test: FAIL fixture"; exit 1; }
    case "$c" in
      worlds-missing) rm "$T/fx/worlds.sha256" ;;
      worlds-empty) : > "$T/fx/worlds.sha256" ;;
      worlds-short) sed '$d' "$T/fx/worlds.sha256" > "$T/w13" && mv "$T/w13" "$T/fx/worlds.sha256" ;;
      manifest-missing) rm "$T/fx/manifest.json" ;;
      png-missing) rm "$T/fx/05_brake_b05_deck.png" ;;
      hash-mismatch) printf 'png 05_brake_b05_dexk\n' > "$T/fx/05_brake_b05_deck.png" ;;
    esac || { echo "capture-m4-publish-test: FAIL fixture $c"; exit 1; }
    : > "$T/log" || exit 1
    rc=0; deadline "$MAKE_S" env PATH="$NP" "$M" -s -C "$ROOT" capture-m4-publish M4_PUBLISH_DIR="$T/fx" > "$T/out" 2>&1 || rc=$?
    if [ "$rc" = 124 ]; then sed 's/^/  | /' "$T/out"; infra "$MAKE_S" "make for case $c ($version)"; fi
    n=$(wc -l < "$T/log" | tr -d ' ')
    good=$(awk -F'|' -v fx="$T/fx/" -v b="$B" 'NF == 6 && $1 == "storage" && $2 == "cp" && $3 == "--cache-control=public, max-age=300" && index($4, fx) == 1 && index($5, b) == 1 && $6 == "" && substr($4, length(fx) + 1) == substr($5, length(b) + 1) {k++} END {print k + 0}' "$T/log")
    uniq=$(cut -d'|' -f5 "$T/log" | sort -u | grep -c .)
    pre=$(grep -c '^capture-m4-publish: FAILED before any upload: ' "$T/out")
    said=$(grep -c '^capture-m4-publish: uploaded 18 files$' "$T/out")
    ok=0
    case "$c" in
      complete) test "$rc" = 0 && test "$n" = 18 && test "$good" = 18 && test "$uniq" = 18 && test "$said" = 1 && ok=1 ;;
      *) test "$rc" != 0 && test "$n" = 0 && test "$pre" = 1 && test "$said" = 0 && ok=1 ;;
    esac
    if [ "$ok" = 1 ]; then echo "capture-m4-publish-test: ok $c ($version)"
    else fails=$((fails + 1)); echo "capture-m4-publish-test: FAIL $c ($version): rc $rc, uploads $n, well-formed $good, pre-check lines $pre"; sed 's/^/  | /' "$T/out"; fi
  done
done
if [ "$fails" != 0 ]; then echo "capture-m4-publish-test: FAILED ($fails of $((7 * nm)) cases)"; exit 1; fi
echo "capture-m4-publish-test: OK (7 cases on $nm makes:$(printf '%s' "$versions" | tr '\n' ',' | sed 's/,$//; s/,/, /g; s/^/ /'))"
