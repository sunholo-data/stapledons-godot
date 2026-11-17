#!/bin/sh
# Negative controls use the real scene and sim; a parser error cannot satisfy them.
set -eu
scratch=.godot/tmp/playthrough/negative
mkdir -p "$scratch"
run_bad() {
    name=$1
    reason=$2
    log="$scratch/$name.log"
    if ! sh tools/script_gate.sh "playthrough-negative-$name" "$log" 1200 \
        '^playthrough: [0-9]+ passed, [1-9][0-9]* failures$' 1 -- \
        "$GODOT" --headless --path . --log-file "$scratch/$name.engine.log" --script tests/m4_playthrough_ship.gd -- \
        "tests/fixtures/playthrough/$name.json" "$scratch/$name"; then
        cat "$log"
        echo "playthrough-negative: FAIL $name (missing bounded expected failure)"
        exit 1
    fi
    if ! grep -Fq "FAIL $reason" "$log"; then
        cat "$log"
        echo "playthrough-negative: FAIL $name (wrong reason: $reason)"
        exit 1
    fi
    echo "playthrough-negative: $name rejected (exit=1): $reason"
}
run_bad unknown_station 'walk has a path: missing_station'
run_bad unfocused 'unscripted refusal: Use the Archive terminal first.'
run_bad unscripted 'unscripted refusal: No news from home has reached the ship yet.'
run_bad missing_return 'completion missing return to Sol at rest'
run_bad missing_home_news 'completion missing home news'
run_bad missing_final_log 'completion missing final home log'
echo 'playthrough-negative: 6 passed, 0 failures'
