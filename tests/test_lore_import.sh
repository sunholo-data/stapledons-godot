#!/bin/sh
# M4.7 AC17 positive controls for `make lore-import CHECK=1`: every way the vendored lore can
# disagree with its manifest, or with the design repo at the manifest's sha, must fail.
# Harness glue (shell): it drives the real tools on scratch copies and checks exit codes.
#   tests/test_lore_import.sh        (make lore-import-test; needs AILANG and git)
set -u
AILANG=${AILANG:-ailang}
SCR=${SCRATCH:-.godot/tmp}/lore-import-test
rm -rf "$SCR"; mkdir -p "$SCR"
fails=0
run() { # name expected-rc command...
  n=$1; want=$2; shift 2
  out=$("$@" 2>&1); rc=$?
  if { [ "$want" = 0 ] && [ $rc = 0 ]; } || { [ "$want" != 0 ] && [ $rc != 0 ]; }; then echo "  ok    $n"
  else echo "  FAIL  $n (rc $rc, wanted $want): $out" | head -5; fails=$((fails+1)); fi
}
chk() { LORE_DATA=$1 D=${2:-/nonexistent} AILANG=$AILANG sh tools/lore_import.sh check; }

# 0. the real vendored copy is consistent (control for everything below)
run "vendored lore matches its manifest" 0 chk data/lore

# 1. manifest hash mismatch: one byte changed in a vendored file
cp -R data/lore "$SCR/edit"; echo "x" >> "$SCR/edit/archive/bubble.md"
run "a changed vendored file fails (manifest hash mismatch)" 1 chk "$SCR/edit"

# 2. a missing file and an extra file
cp -R data/lore "$SCR/miss"; rm "$SCR/miss/archive/one-g.md"
run "a missing vendored file fails" 1 chk "$SCR/miss"
cp -R data/lore "$SCR/extra"; echo "new" > "$SCR/extra/archive/stowaway.md"
run "an extra vendored file fails" 1 chk "$SCR/extra"

# 3. cross-repo: a fake design repo whose commit differs from the vendored bytes
FD="$SCR/design"; mkdir -p "$FD"; (cd "$FD" && git init -q . && mkdir -p lore physics)
cp -R data/lore/archive "$FD/lore/archive"; cp data/lore/physics/*.md "$FD/physics/"
(cd "$FD" && git add -A && git -c user.name=t -c user.email=t@t commit -q -m fake)
FSHA=$(git -C "$FD" rev-parse HEAD)
cp -R data/lore "$SCR/cross"
sed -i.bak "s/\"design_sha\": \"[0-9a-f]*\"/\"design_sha\": \"$FSHA\"/" "$SCR/cross/manifest.json"; rm -f "$SCR/cross/manifest.json.bak"
run "cross-repo: design repo at the manifest sha equals the vendored copy" 0 chk "$SCR/cross" "$FD"
echo "drift" >> "$FD/lore/archive/starbow.md"; (cd "$FD" && git add -A && git -c user.name=t -c user.email=t@t commit -q -m drift)
sed -i.bak "s/\"design_sha\": \"[0-9a-f]*\"/\"design_sha\": \"$(git -C "$FD" rev-parse HEAD)\"/" "$SCR/cross/manifest.json"; rm -f "$SCR/cross/manifest.json.bak"
run "cross-repo: a design file that differs at the manifest sha fails" 1 chk "$SCR/cross" "$FD"
# the sibling's working tree is never read: a dirty working file at the right sha still passes
sed -i.bak "s/\"design_sha\": \"[0-9a-f]*\"/\"design_sha\": \"$FSHA\"/" "$SCR/cross/manifest.json"; rm -f "$SCR/cross/manifest.json.bak"
run "cross-repo reads git objects, not the working tree" 0 chk "$SCR/cross" "$FD"
# a new entry upstream (not in the manifest) is drift too
git -C "$FD" checkout -q "$FSHA" 2>/dev/null; echo "n" > "$FD/lore/archive/newentry.md"; (cd "$FD" && git add -A && git -c user.name=t -c user.email=t@t commit -q -m newentry)
sed -i.bak "s/\"design_sha\": \"[0-9a-f]*\"/\"design_sha\": \"$(git -C "$FD" rev-parse HEAD)\"/" "$SCR/cross/manifest.json"; rm -f "$SCR/cross/manifest.json.bak"
run "cross-repo: an upstream entry the manifest lacks fails" 1 chk "$SCR/cross" "$FD"
# a sibling without the sha object is skipped with a notice (shallow or behind), not a failure
run "cross-repo: unknown sha is skipped with a notice" 0 sh -c "LORE_DATA=data/lore D=$FD AILANG=$AILANG sh tools/lore_import.sh check | grep -q 'cross-repo: skipped'"

if [ $fails = 0 ]; then echo "lore-import-test: ok"; else echo "lore-import-test: $fails FAILED"; exit 1; fi
