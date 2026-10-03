#!/bin/sh
# Website media (website/, make site-media / site-media-publish). Glue only:
# Godot renders the frames (tools/site_movie.gd), ffmpeg encodes them, gcloud
# uploads them content-addressed to the public asset bucket.
#
#   tools/site_media.sh render [CLIP...]   PNG frames -> renders/site/frames/CLIP/ (needs a GPU window)
#   tools/site_media.sh encode [CLIP...]   frames -> renders/site/CLIP.mp4 (H.264) + .webm (VP9) + poster
#   tools/site_media.sh asset FILE...      upload any file (full-size art) content-addressed to the same
#                                          bucket folder; prints "FILE URL" per line
#   tools/site_media.sh publish [CLIP...]  upload to gs://stapledons-voyage-assets/site/<sha256>.<ext>
#                                          (--no-clobber, immutable) and rewrite website/src/data/media.json
#
# Clips: hero voyage lookaround map cmb (default: all). The cmb clip needs a build
# with the forward CMB disc (M1.8, PR #79); on a tree without it the clip shows
# the starfield alone, so check its frames before publishing.
# Env: GODOT (godot), AILANG (ailang), FFMPEG (ffmpeg; `npx ffmpeg-static` works too).
set -eu

cmd=${1:-}; [ $# -gt 0 ] && shift
clips=${*:-hero voyage lookaround map cmb}
GODOT=${GODOT:-godot}
AILANG=${AILANG:-ailang}
FFMPEG=${FFMPEG:-ffmpeg}
OUT=renders/site
BUCKET=gs://stapledons-voyage-assets/site
PUBLIC=https://storage.googleapis.com/stapledons-voyage-assets/site
MANIFEST=website/src/data/media.json
POSTERS=website/static/img/posters

alarm() { perl -e 'alarm shift; exec @ARGV' "$@"; }

render() {
    for c in $clips; do
        rm -rf "$OUT/frames/$c"
        if [ "$c" = map ]; then set -- --map --movie=map; else set -- --movie="$c"; fi
        AILANG_BIN="$(command -v "$AILANG")" alarm 900 "$GODOT" --path . -- "$@" --movie-out="$PWD/$OUT/frames/$c"
        n=$(ls "$OUT/frames/$c" | wc -l | tr -d ' ')
        [ "$n" -gt 0 ] || { echo "site-media: $c rendered no frames" >&2; exit 1; }
        echo "site-media: $c: $n frames"
    done
}

encode() {
    command -v "$FFMPEG" >/dev/null || { echo "site-media: needs ffmpeg (brew install ffmpeg, or FFMPEG=\$(npx -y ffmpeg-static))" >&2; exit 1; }
    mkdir -p "$POSTERS"
    for c in $clips; do
        f="$OUT/frames/$c/f%05d.png"
        crf=21; vcrf=33
        [ "$c" = map ] && { crf=24; vcrf=37; } # the map's many small labels and stars: keep it under ~8 MB
        "$FFMPEG" -hide_banner -loglevel error -y -framerate 30 -i "$f" -c:v libx264 -preset slow -crf $crf \
            -pix_fmt yuv420p -movflags +faststart -an "$OUT/$c.mp4"
        "$FFMPEG" -hide_banner -loglevel error -y -framerate 30 -i "$f" -c:v libvpx-vp9 -crf $vcrf -b:v 0 \
            -row-mt 1 -deadline good -cpu-used 2 -pix_fmt yuv420p -an "$OUT/$c.webm"
        "$FFMPEG" -hide_banner -loglevel error -y -i "$OUT/frames/$c/f00000.png" -vf "scale='min(1600,iw)':-2" -q:v 3 "$POSTERS/$c.jpg"
        ls -l "$OUT/$c.mp4" "$OUT/$c.webm" "$POSTERS/$c.jpg"
    done
}

publish() {
    command -v gcloud >/dev/null || { echo "site-media-publish: needs gcloud (maintainers only)" >&2; exit 1; }
    tmp=$(mktemp)
    [ -f "$MANIFEST" ] && cp "$MANIFEST" "$tmp" || echo '{}' > "$tmp"
    for c in $clips; do
        for ext in mp4 webm; do
            src="$OUT/$c.$ext"
            sha=$(shasum -a 256 "$src" | cut -d' ' -f1)
            obj="$BUCKET/$sha.$ext"
            if gcloud storage objects describe "$obj" >/dev/null 2>&1; then echo "  exists    $obj"
            else
                gcloud storage cp --no-clobber --content-type="video/$ext" \
                    --cache-control="public, max-age=31536000, immutable" "$src" "$obj"
                echo "  uploaded  $obj"
            fi
            bytes=$(wc -c < "$src" | tr -d ' ')
            # one key per clip and format: {"voyage": {"mp4": {"url": ..., "bytes": ...}, ...}}
            # jq keeps the other clips' entries
            jq --arg c "$c" --arg e "$ext" --arg u "$PUBLIC/$sha.$ext" --argjson b "$bytes" \
                '.[$c][$e] = {url: $u, bytes: $b}' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
        done
    done
    mv "$tmp" "$MANIFEST"
    echo "site-media-publish: wrote $MANIFEST"
}

asset() {
    command -v gcloud >/dev/null || { echo "site-media asset: needs gcloud (maintainers only)" >&2; exit 1; }
    for src in $clips; do
        ext=${src##*.}
        case "$ext" in jpg|jpeg) type=image/jpeg ;; png) type=image/png ;; webp) type=image/webp ;; *) type=application/octet-stream ;; esac
        sha=$(shasum -a 256 "$src" | cut -d' ' -f1)
        obj="$BUCKET/$sha.$ext"
        gcloud storage objects describe "$obj" >/dev/null 2>&1 || \
            gcloud storage cp --quiet --no-clobber --content-type="$type" \
                --cache-control="public, max-age=31536000, immutable" "$src" "$obj" >&2
        echo "$src $PUBLIC/$sha.$ext"
    done
}

case "$cmd" in
    asset) asset ;;
    render) render ;;
    encode) encode ;;
    publish) publish ;;
    *) sed -n '2,15p' "$0"; exit 2 ;;
esac
