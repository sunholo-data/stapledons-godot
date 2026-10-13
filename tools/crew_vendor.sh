#!/bin/sh
# R2-CREW C0 (design crew-integration.md §CI-1): vendor sunholo/crew_core until
# ailang#1811 lets the registry take it. The engine is changed upstream only
# (ailang-packages, crew lab); this copy is never edited in place.
#   tools/crew_vendor.sh vendor <ailang-packages clone> <rev>   copy packages/crew-core at <rev>
#   tools/crew_vendor.sh check                                   recompute the tree hash, fail on drift
set -eu
DEST=vendor/crew-core
MANIFEST=$DEST/VENDORED

# sha256 over "<sha256>  <path>" lines for every file but VENDORED, sorted by path (LC_ALL=C).
tree_hash() {
  (cd "$DEST" && find . -type f ! -name VENDORED | LC_ALL=C sort | while read -r f; do shasum -a 256 "$f"; done) | shasum -a 256 | cut -d' ' -f1
}

case "${1:-}" in
vendor)
  src=${2:?usage: vendor <ailang-packages clone> <rev>}; rev=${3:?usage: vendor <clone> <rev>}
  full=$(git -C "$src" rev-parse "$rev^{commit}")
  rm -rf "$DEST"; mkdir -p "$DEST"
  git -C "$src" archive "$full" packages/crew-core | tar -x -C "$DEST" --strip-components=2
  version=$(sed -n 's/^version = "\(.*\)"/\1/p' "$DEST/ailang.toml" | head -1)
  {
    echo "package: sunholo/crew_core"
    echo "version: $version"
    echo "repo: https://github.com/sunholo-data/ailang-packages"
    echo "path: packages/crew-core"
    echo "commit: $full"
    echo "tree_sha256: $(tree_hash)"
    echo "note: vendored until ailang#1811; change the engine upstream and re-vendor, never edit here (make crew-vendor-check)"
  } > "$MANIFEST"
  cat "$MANIFEST" ;;
check)
  test -f "$MANIFEST" || { echo "crew-vendor-check: $MANIFEST missing"; exit 1; }
  want=$(sed -n 's/^tree_sha256: //p' "$MANIFEST"); got=$(tree_hash)
  if [ "$want" = "$got" ]; then echo "crew-vendor-check: ok ($(sed -n 's/^version: //p' "$MANIFEST") @ $(sed -n 's/^commit: //p' "$MANIFEST" | cut -c1-7))"
  else echo "crew-vendor-check: FAIL: $DEST was edited (tree $got, VENDORED says $want); re-vendor from upstream instead"; exit 1; fi ;;
*) echo "usage: $0 vendor <ailang-packages clone> <rev> | check"; exit 2 ;;
esac
