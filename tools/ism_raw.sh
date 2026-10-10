#!/bin/sh
# I3b: immutable Zenodo source; verified before installation, never tracked in git.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
dest="$root/data/raw/edenhofer2024"
name=mean_and_std_healpix.fits
pin=$(awk -v name="$name" '$2 == name {print $1}' "$root/data/ism/SHA256SUMS")
[ ${#pin} -eq 64 ] || { echo 'ism-raw: missing SHA256 pin' >&2; exit 1; }
mkdir -p "$dest"
check() { [ "$(shasum -a 256 "$1" | awk '{print $1}')" = "$pin" ]; }
if [ -f "$dest/$name" ] && check "$dest/$name"; then
  echo "ism-raw: verified $name ($pin)"
  exit 0
fi
part="$dest/$name.part"
curl --fail --location --retry 3 --continue-at - "https://zenodo.org/records/8187943/files/$name?download=1" --output "$part"
check "$part" || { echo 'ism-raw: checksum mismatch; source not installed' >&2; exit 1; }
mv "$part" "$dest/$name"
echo "ism-raw: installed and verified $name ($pin)"
