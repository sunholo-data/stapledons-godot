#!/bin/bash
# Install a macOS build of Stapledon's Voyage: download, verify, unzip to
# ~/Applications, clear the Gatekeeper quarantine flag and open it.
#
#   tools/install_review_build.sh --dev          # latest dev build (private GCS bucket; needs gcloud auth)
#   tools/install_review_build.sh                # latest GitHub release (needs `gh auth login`)
#   tools/install_review_build.sh v0.3.2-m2-journey   # a named GitHub release
#
# Without a checkout:
#   gh api repos/sunholo-data/stapledons-godot/contents/tools/install_review_build.sh --jq .content | base64 -d | bash -s -- --dev
set -euo pipefail

REPO="sunholo-data/stapledons-godot"
DEV_BUCKET="${DEV_BUCKET:-stapledons-voyage-dev-builds}"
DEST="${DEST:-$HOME/Applications}"
APP="Stapledons Voyage.app"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if [ "${1:-}" = "--dev" ]; then
  command -v gcloud >/dev/null || { echo "Install the Google Cloud CLI and run: gcloud auth login" >&2; exit 1; }
  gcloud storage cp "gs://$DEV_BUCKET/macos/latest.json" "$TMP/latest.json" --quiet
  # plutil is bundled with macOS. Parse JSON rather than relying on the
  # publisher's whitespace or key order (compact and pretty manifests work).
  zip_path=$(plutil -extract zip raw -expect string -o - "$TMP/latest.json")
  want=$(plutil -extract sha256 raw -expect string -o - "$TMP/latest.json")
  ver=$(plutil -extract version raw -expect string -o - "$TMP/latest.json")
  [[ "$zip_path" == macos/builds/*macos.zip && "$zip_path" != *..* ]] || { echo "Invalid dev archive path" >&2; exit 1; }
  [[ "$want" =~ ^[a-f0-9]{64}$ ]] || { echo "Invalid dev archive checksum" >&2; exit 1; }
  [ -n "$ver" ] || { echo "Missing dev build version" >&2; exit 1; }
  echo "Installing dev build $ver into $DEST"
  gcloud storage cp "gs://$DEV_BUCKET/$zip_path" "$TMP/" --quiet
  ZIP="$TMP/$(basename "$zip_path")"
  got=$(shasum -a 256 "$ZIP" | cut -d' ' -f1)
  [ "$got" = "$want" ] || { echo "sha256 mismatch: got $got, want $want" >&2; exit 1; }
else
  command -v gh >/dev/null || { echo "Install the GitHub CLI first: brew install gh && gh auth login" >&2; exit 1; }
  TAG="${1:-}"
  [ -n "$TAG" ] || TAG=$(gh release list -R "$REPO" -L 20 --json tagName,isDraft --jq '[.[] | select(.isDraft | not)][0].tagName')
  echo "Installing release $TAG into $DEST"
  gh release download "$TAG" -R "$REPO" -p '*macos.zip' -D "$TMP"
  ZIP=$(ls "$TMP"/*macos.zip)
fi
echo "sha256 $(shasum -a 256 "$ZIP" | cut -d' ' -f1)  $(basename "$ZIP")"

mkdir -p "$DEST"
pkill -f "$APP/Contents/MacOS" 2>/dev/null || true
rm -rf "$DEST/$APP"
ditto -x -k "$ZIP" "$DEST"
xattr -dr com.apple.quarantine "$DEST/$APP"
echo "Installed $DEST/$APP"
[ -n "${NO_OPEN:-}" ] || open "$DEST/$APP"
