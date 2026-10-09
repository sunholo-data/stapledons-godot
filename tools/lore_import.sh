#!/bin/sh
# M4.7 lore import: shell glue around sim/tools/lore_import.ail (the manifest and every hash are AILANG).
#   sh tools/lore_import.sh import   copy the design repo's lore at $D's HEAD (git objects, never the
#                                    working tree) into $LORE_DATA, then write manifest.json
#   sh tools/lore_import.sh check    AC17: (i) the vendored files hash-equal manifest.json, nothing
#                                    missing or extra (fail-closed, no network); (ii) where $D has the
#                                    manifest's sha, the design repo at that sha equals the vendored
#                                    copy (git objects; skipped with a notice where it does not)
# Env: D (design repo checkout, default ../stapledons-design), LORE_DATA (default data/lore), AILANG,
# SCRATCH, LORE_REF (revision to import, default HEAD).
set -u
D=${D:-../stapledons-design}
LORE_DATA=${LORE_DATA:-data/lore}
AILANG=${AILANG:-ailang}
SCRATCH=${SCRATCH:-.godot/tmp}
REPO=sunholo-data/stapledons-design
TOOL=sim/tools/lore_import.ail
RUN="$AILANG run --quiet --bytecode --caps IO,FS --package-dir sim"

files_json() { # dir -> JSON array of the files under dir (relative), manifest.json excluded
  (cd "$1" && find archive physics -type f | sort) | awk 'BEGIN{printf "["} {printf "%s\"%s\"", (NR>1?",":""), $0} END{printf "]"}'
}

# The design-repo files that make up the lore: lore/archive/*.md -> archive/, plus three physics docs.
list_at() { # sha -> "<design path> <vendored path>" lines
  git -C "$D" ls-tree -r --name-only "$1" -- lore/archive | grep '\.md$' | sed 's#^lore/archive/\(.*\)$#lore/archive/\1 archive/\1#'
  echo "physics/higgs-bubble.md physics/higgs-bubble.md"
  echo "physics/relativity-spec.md physics/relativity-spec.md"
  echo "physics/ism-structure.md physics/ism-structure.md"
  echo "physics/ism-structure.md physics/ism-structure.md"
}
export_at() { # sha dest-dir
  list_at "$1" | while read -r src dst; do
    mkdir -p "$2/$(dirname "$dst")"
    git -C "$D" show "$1:$src" > "$2/$dst" || exit 1
  done
}

case "${1:-}" in
import)
  sha=$(git -C "$D" rev-parse "${LORE_REF:-HEAD}") || { echo "lore-import: $D is not a git checkout (set D=)"; exit 1; }
  rm -rf "$LORE_DATA/archive" "$LORE_DATA/physics"; mkdir -p "$LORE_DATA"
  export_at "$sha" "$LORE_DATA" || exit 1
  $RUN --entry manifest --args-json "{\"dir\":\"$LORE_DATA\",\"repo\":\"$REPO\",\"sha\":\"$sha\",\"files\":$(files_json "$LORE_DATA")}" $TOOL
  ;;
check)
  $RUN --entry verify --args-json "{\"dir\":\"$LORE_DATA\",\"manifest\":\"$LORE_DATA/manifest.json\",\"files\":$(files_json "$LORE_DATA")}" $TOOL || exit 1
  sha=$(sed -n 's/.*"design_sha": "\([0-9a-f]*\)".*/\1/p' "$LORE_DATA/manifest.json")
  if [ -n "$sha" ] && git -C "$D" cat-file -e "$sha^{commit}" 2>/dev/null; then
    X="$SCRATCH/lore-design-$$"; rm -rf "$X"; mkdir -p "$X"
    export_at "$sha" "$X" || { rm -rf "$X"; exit 1; }
    cp "$LORE_DATA/manifest.json" "$X/manifest.json"
    $RUN --entry verify --args-json "{\"dir\":\"$X\",\"manifest\":\"$X/manifest.json\",\"files\":$(files_json "$X")}" $TOOL; rc=$?
    rm -rf "$X"
    [ $rc = 0 ] && echo "lore-import: cross-repo: $D at ${sha%"${sha#???????}"} equals the vendored copy" || { echo "lore-import: cross-repo: design repo at $sha DIFFERS from the vendored lore"; exit 1; }
  else
    echo "lore-import: cross-repo: skipped (no design checkout with commit ${sha:-?} at D=$D; clone $REPO and pass D=)"
  fi
  ;;
*) echo "usage: lore_import.sh import|check"; exit 2;;
esac
