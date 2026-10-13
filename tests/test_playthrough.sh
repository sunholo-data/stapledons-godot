#!/bin/sh
# Negative controls use the real scene and sim; a parser error cannot satisfy them.
set -eu
scratch=.godot/tmp/playthrough/negative
mkdir -p "$scratch"
run_bad() {
    name=$1
    reason=$2
    log="$scratch/$name.log"
    rc=0
    "$GODOT" --headless --path . --script tests/m4_playthrough_ship.gd -- \
        "tests/fixtures/playthrough/$name.json" "$scratch/$name" > "$log" 2>&1 || rc=$?
    if [ "$rc" != 1 ] || ! grep -Fq "FAIL $reason" "$log" || \
        grep -q 'SCRIPT ERROR:' "$log" || \
        grep -q '^playthrough: [0-9]* passed, 0 failures$' "$log"; then
        cat "$log"
        echo "playthrough-negative: FAIL $name (exit=$rc)"
        exit 1
    fi
    echo "playthrough-negative: $name rejected (exit=$rc): $reason"
}
run_bad unknown_station 'walk has a path: missing_station'
run_bad unfocused 'unscripted refusal: Use the Archive terminal first.'
run_bad unscripted 'unscripted refusal: No news from home has reached the ship yet.'
echo 'playthrough-negative: 3 passed, 0 failures'
