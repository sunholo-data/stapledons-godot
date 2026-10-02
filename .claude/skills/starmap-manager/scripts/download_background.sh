#!/bin/bash
# Download galactic background imagery from NOIRLab
# Source: NOIRLab all-sky panorama by Eckhard Slawik (noirlab2430b)
# Usage: download_background.sh [resolution]
#   resolution: 4k (default), 10k, raw
#   raw: the untouched 10k TIF into data/raw/background/noirlab_10k.tif, the
#        input of the sky pipeline (destar -> make sky-model; `make sky-assets`).
#        No conversion; prints size + sha256 and records it in data/raw/SHA256SUMS.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/data/starmap/background"

RESOLUTION="${1:-4k}"

mkdir -p "$OUTPUT_DIR"

echo "=== NOIRLab All-Sky Panorama Downloader ==="
echo "Source: NOIRLab / Eckhard Slawik (noirlab2430b)"
echo "License: CC BY 4.0"
echo "Credit: NOIRLab/NOIRLab/Eckhard Slawik"
echo "URL: https://noirlab.edu/public/images/noirlab2430b/"
echo ""

case "$RESOLUTION" in
    4k)
        echo "Downloading 4K resolution (4000x2000)..."
        echo "  Size: ~3.5 MB"
        URL="https://noirlab.edu/public/media/archives/images/publicationjpg/noirlab2430b.jpg"
        OUTPUT="$OUTPUT_DIR/galaxy_4k.jpg"
        ;;
    10k)
        echo "Downloading 10K resolution (10000x5000)..."
        echo "  Size: ~91 MB (TIF, will convert to JPEG)"
        URL="https://noirlab.edu/public/media/archives/images/publicationtiff10k/noirlab2430b.tif"
        OUTPUT_TIF="$OUTPUT_DIR/galaxy_10k.tif"
        OUTPUT="$OUTPUT_DIR/galaxy_10k.jpg"
        ;;
    raw)
        URL="https://noirlab.edu/public/media/archives/images/publicationtiff10k/noirlab2430b.tif"
        RAW_DIR="$PROJECT_ROOT/data/raw"
        mkdir -p "$RAW_DIR/background"
        touch "$RAW_DIR/.gdignore"
        echo "Downloading the 10K TIF unconverted (10000x5000, ~96 MB) for the sky pipeline..."
        echo "  GET $URL"
        curl -L --fail --silent --show-error --max-time "${CURL_MAX_TIME:-900}" \
            -o "$RAW_DIR/background/noirlab_10k.tif" "$URL"
        name="background/noirlab_10k.tif"
        sum="$(cd "$RAW_DIR" && shasum -a 256 "$name" | awk '{print $1}')"
        echo "  size:   $(wc -c < "$RAW_DIR/$name" | tr -d ' ') bytes"
        echo "  sha256: $sum"
        if [ -f "$RAW_DIR/SHA256SUMS" ]; then
            grep -v "  $name\$" "$RAW_DIR/SHA256SUMS" > "$RAW_DIR/SHA256SUMS.tmp" || true
            mv "$RAW_DIR/SHA256SUMS.tmp" "$RAW_DIR/SHA256SUMS"
        fi
        echo "$sum  $name" >> "$RAW_DIR/SHA256SUMS"
        echo ""
        echo "IMPORTANT: Add credit to game:"
        echo '  "All-sky panorama: NOIRLab/Eckhard Slawik (CC BY 4.0)"'
        exit 0
        ;;
    *)
        echo "ERROR: Unknown resolution '$RESOLUTION'"
        echo "Usage: $0 [4k|10k|raw]"
        echo ""
        echo "Resolutions:"
        echo "  4k  - 4000x2000, ~3.5 MB JPEG (default, recommended)"
        echo "  10k - 10000x5000, ~27 MB JPEG (HD/4K displays, downloaded as TIF and converted)"
        echo ""
        echo "Higher resolutions available manually from:"
        echo "  https://noirlab.edu/public/images/noirlab2430b/"
        exit 1
        ;;
esac

echo ""

if [ "$RESOLUTION" = "10k" ]; then
    # Download TIF and convert to JPEG
    if curl -L --fail -o "$OUTPUT_TIF" "$URL" 2>/dev/null; then
        echo "  Downloaded TIF, converting to JPEG..."
        if command -v sips &>/dev/null; then
            sips -s format jpeg -s formatOptions 90 "$OUTPUT_TIF" --out "$OUTPUT" 2>/dev/null
        elif command -v convert &>/dev/null; then
            convert "$OUTPUT_TIF" -quality 90 "$OUTPUT"
        else
            echo "  ERROR: Need 'sips' (macOS) or 'convert' (ImageMagick) to convert TIF to JPEG"
            echo "  TIF saved at: $OUTPUT_TIF"
            exit 1
        fi
        rm -f "$OUTPUT_TIF"
        echo "  Converted: $(basename "$OUTPUT")"
        echo "  Size: $(du -h "$OUTPUT" | cut -f1)"
    else
        echo "  ERROR: Could not download 10K background"
        exit 1
    fi
else
    if curl -L --fail -o "$OUTPUT" "$URL" 2>/dev/null; then
        echo "  Downloaded: $(basename "$OUTPUT")"
        echo "  Size: $(du -h "$OUTPUT" | cut -f1)"
    else
        echo "  ERROR: Could not download background"
        echo ""
        echo "  Manual download: https://noirlab.edu/public/images/noirlab2430b/"
        exit 1
    fi
fi

echo ""
echo "Background download complete!"
echo ""
echo "Files in $OUTPUT_DIR:"
ls -lh "$OUTPUT_DIR"/ 2>/dev/null || echo "  (empty)"
echo ""
echo "IMPORTANT: Add credit to game:"
echo '  "All-sky panorama: NOIRLab/Eckhard Slawik (CC BY 4.0)"'
