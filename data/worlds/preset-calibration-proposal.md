# Preset calibration with the photon-budget detector: measurement and proposal (R3-WORLDS W1.4)

**Status: a proposal for an attended ruling.** `sim/data/presets.ail` is unchanged, no preset is marked calibrated, and `calibrate_main.main` still stops for the ruling. Nothing here is on the wire. Only the four dial offsets were varied; no physical number was tuned.

**Measured 2026-11-12** with `sim/tools/calibrate_budget.ail` and `sim/tools/evidence_probe.ail` at commit `604b22d0` (branch `feat/r3-reasons-rt2a`, draft PR #435), AILANG v0.56.1 (`runtime/bin/ailang`, bytecode VM), `sunholo/observe` 0.2.0 from ailang-packages main `a95aabe` through the development overlay, `sunholo/worlds` 0.1.0, `sunholo/relativity` 0.12.0. Doom clock 16,000 years (Standard). Detector `observe-0.2.0:coronagraph-10m+dish-100m`.

## Summary

- **About 5 orders of magnitude of luck meet the signal and contact targets**, not the 2 to 3 the design expected. The medians of signals (5-10) and contacts (5 or more) are in band for both binding strategies at life +0, minds +1.5, technology +1.0, lifetime +2.5 (luck 5.0), in two batches of 8 seeds. Single voyages vary widely: 2 to 15 signals.
- **Minds and technology cannot give more than +2.5 between them.** The fractions saturate at 1 (minds at +1.5, technology at +1.0); every further order of magnitude has to come from the lifetime of a civilisation, which reaches 32 million years at the proposed cell.
- **Two targets are not met at any cell tried: "40-80 biospheres detected" and "3-6 remnants".** Both are properties of how the calibration counts, described below, not of the dial.
- At the proposed Stapledon cell the play-area registry (81.5 ly) holds about 5 technological worlds, and the ship's dish hears about 1 of them from Sol. About 790 are expected within 500 ly, where the map has no stars yet.

## Commands

```sh
export PATH=$PWD/runtime/bin:$PATH
O=$(tools/observe_dev.sh path)
# one dial cell (offsets in orders of magnitude), seeds firstSeed..firstSeed+seeds-1; "all": add pilgrim and waiter
ailang run --quiet --bytecode --caps IO --package-dir $O --entry cell --args-json \
  '{"life":0,"minds":1.5,"tech":1,"lifetime":2.5,"firstSeed":0,"seeds":8,"doom":16000,"all":false}' $O/tools/calibrate_budget.ail
# the bioSupportLy optimisation changes no row (printed: cautious true, wanderer true; 38 s)
ailang run --quiet --bytecode --caps IO --package-dir $O --entry equivalence --args-json \
  '{"life":0,"minds":1.5,"tech":1,"lifetime":2.5,"seed":0,"doom":16000}' $O/tools/calibrate_budget.ail
# the Sol funnel at candidate dials (82 s)
ailang run --quiet --bytecode --caps IO,FS --package-dir $O --entry funnelAt --args-json \
  '{"registry":"data/starmap/stars.json","planets":"data/planets/exoplanets.json","firstSeed":0,"seeds":5,"x":0,"y":0,"z":0,"year":0,"apertureM":10,"shellLy":60,"dials":[...]}' $O/tools/evidence_probe.ail
```

The grid is 24 cells, 8 seeds (0-7), the two binding strategies: 2023 s in all (34 minutes; 15 s to 386 s per cell, slower as civilisations multiply). The grid was chosen by hand, not by `searchGrid`'s full product: minds and technology saturate, so cells above their caps repeat each other (see "What limits the dial"). Each cell's fit and conflicts are `calibrate_search.assessRows` against the Stapledon bands, the search's own score. Eight seeds is a reduction from the planned 256; the spread is given as min-max in every cell.

## What the calibration simulates, as coded (`sim/calibrate.ail`)

- **Its galaxy is statistical and has no stars.** It does not use the 81.5 ly registry. Technological lineages are a marked Poisson process over an exponential disc (0.079 stars per cubic parsec, 300 pc scale height, 0.20 habitable worlds per star), out to the strategy's range: 1,000 ly for the cautious explorer, 3,000 ly for the wanderer and the waiter, 5,000 ly for the pilgrim. Other living worlds are generated in 10 ly cells around each stop, as far as a biosphere can respond (59.4 ly).
- **The ship observes only at stops**: at Sol and after each arrival. It sees each world at the time its light left (`lightcone.seenAt`).
- **detected**: distinct worlds seen, at any stop, in a living state (Microbial, Complex, PreTech, Technological or Remnant) with a non-zero biosphere response.
- **signals**: distinct worlds seen Technological with a non-zero technology response.
- **visited**: arrivals at a world that is in a living state on arrival. **remnants**: arrivals at a world that is a Remnant on arrival. **contacts**: arrivals at a world that is Technological on arrival.
- The ship goes only to worlds it has detected, signals first. A voyage ends at 100 ship-years or the doom clock.

## How its detection differs from the evidence ledger (`sim/evidence.ail`)

| | Calibration (`Detect.response`) | Evidence ledger |
|---|---|---|
| The planet | every living world is the registry's Earth twin at 1 AU from a Sun twin | each planet's own host, orbit and radius |
| Inner working angle | passes for every world within 59.4 ly | about 88 % of living worlds that show oxygen fail it (mostly M-dwarf planets) |
| Noise floor | always passes (the twin's contrast is above it) | about a quarter of the remainder fail |
| What "detected" needs | a living state | an oxygen or red-edge signal by the emission draw (a microbial world shows oxygen 3 times in 10) |
| False positives | none | abiotic oxygen and mineral edges on sterile worlds |
| Integration | the same `imagingSnr`, 30-day look, zodi on, SNR 5 | the same |
| Transits | none | census record only |
| Radio | the same `leakSnr`: radar class for a rank below 0.10 (reach 168.3 ly), TV class otherwise (0.42 ly) | the same |
| Silences, catalogue knowledge | none | recorded for known worlds |
| Cruise census | none | coarse census |

The radio side is the same physics. The optical side is not: the calibration's "detected" is "a living world came within 59.4 ly of a stop", which is about seven times what the ledger reads (from Sol the ledger reads 34 of the 236 living worlds within 60 ly under the development Stapledon dial).

## The grid (8 seeds; cells are median (min-max) of detected / visited / remnants / signals / contacts)

Bands for Stapledon's Voyage: 40-80 / 5-10 / 3-6 / 5-10 / at least 5. Offsets are life / minds / technology / lifetime in orders of magnitude.

| Offsets | Luck | Cautious explorer | Wanderer | Bands missed | s |
|---|---|---|---|---|---|
| +0 / +0 / +0 / +0 | 0.00 | 418 (409-516) / 10 (10-11) / 0 (0-0) / 0 (0-0) / 0 (0-0) | 367 (355-399) / 7 (7-7) / 0 (0-0) / 0 (0-0) / 0 (0-0) | cautious:detected, cautious:remnants, cautious:signals, cautious:contacts, wanderer:detected, wanderer:remnants, wanderer:signals, wanderer:contacts | 15 |
| +0 / +0.75 / +0.75 / +0.25 | 1.75 | 414 (404-510) / 10 (10-11) / 0 (0-0) / 0 (0-0) / 0 (0-0) | 363 (350-391) / 7 (7-7) / 0 (0-0) / 0 (0-0) / 0 (0-0) | cautious:detected, cautious:remnants, cautious:signals, cautious:contacts, wanderer:detected, wanderer:remnants, wanderer:signals, wanderer:contacts | 21 |
| +0 / +1.25 / +1.25 / +0.25 | 2.50 | 401 (376-476) / 10 (10-11) / 0 (0-0) / 0 (0-0) / 0 (0-0) | 342 (332-364) / 7 (7-7) / 0 (0-0) / 0 (0-0) / 0 (0-0) | cautious:detected, cautious:remnants, cautious:signals, cautious:contacts, wanderer:detected, wanderer:remnants, wanderer:signals, wanderer:contacts | 23 |
| +0.25 / +1.5 / +1.5 / +0.5 | 3.20 | 590 (533-820) / 10 (10-11) / 0 (0-0) / 0 (0-1) / 0 (0-1) | 510 (488-762) / 7 (6-7) / 0 (0-0) / 0 (0-1) / 0 (0-1) | cautious:detected, cautious:remnants, cautious:signals, cautious:contacts, wanderer:detected, wanderer:remnants, wanderer:signals, wanderer:contacts | 50 |
| +0 / +1.5 / +1 / +1 | 3.50 | 381 (366-449) / 10 (10-11) / 0 (0-0) / 0 (0-0) / 0 (0-0) | 322 (312-348) / 7 (7-7) / 0 (0-0) / 0 (0-0) / 0 (0-0) | cautious:detected, cautious:remnants, cautious:signals, cautious:contacts, wanderer:detected, wanderer:remnants, wanderer:signals, wanderer:contacts | 29 |
| +0 / +1.5 / +1 / +1.5 | 4.00 | 435 (366-783) / 10 (9-11) / 0 (0-0) / 0 (0-2) / 0 (0-2) | 334 (315-514) / 7 (6-7) / 0 (0-0) / 0 (0-1) / 0 (0-1) | cautious:detected, cautious:remnants, cautious:signals, cautious:contacts, wanderer:detected, wanderer:remnants, wanderer:signals, wanderer:contacts | 35 |
| +0 / +1.5 / +1 / +2 | 4.50 | 574 (366-1192) / 9 (5-11) / 0 (0-0) / 1 (0-6) / 1 (0-6) | 527 (333-1192) / 6 (5-7) / 0 (0-0) / 1 (0-6) / 1 (0-5) | cautious:detected, cautious:remnants, cautious:signals, cautious:contacts, wanderer:detected, wanderer:remnants, wanderer:signals, wanderer:contacts | 50 |
| +0 / +1.5 / +1 / +2.25 | 4.75 | 1166 (546-1413) / 6 (5-10) / 0 (0-0) / 6 (1-8) / 5 (1-6) | 1007 (422-1236) / 5 (5-6) / 0 (0-0) / 6 (1-8) / 5 (1-5) | cautious:detected, cautious:remnants, wanderer:detected, wanderer:remnants | 80 |
| +0 / +1.5 / +1 / +2.5 | 5.00 | 1240 (731-1474) / 6 (6-9) / 0 (0-0) / 10 (2-15) / 6 (2-7) | 1047 (708-1288) / 5 (5-6) / 0 (0-0) / 9 (2-14) / 5 (2-5) | cautious:detected, cautious:remnants, wanderer:detected, wanderer:remnants | 146 |
| +0 / +1.5 / +1 / +2.75 | 5.25 | 1252 (1105-1367) / 7 (6-7) / 0 (0-0) / 14 (8-24) / 7 (6-7) | 1069 (895-1163) / 5 (5-6) / 0 (0-0) / 13 (8-20) / 5 (5-6) | cautious:detected, cautious:remnants, cautious:signals, wanderer:detected, wanderer:remnants, wanderer:signals | 227 |
| +0 / +1.5 / +1 / +3 | 5.50 | 1284 (1166-1414) / 7 (7-7) / 0 (0-0) / 29 (25-35) / 7 (7-7) | 1014 (777-1196) / 6 (5-6) / 0 (0-0) / 23 (20-29) / 6 (5-6) | cautious:detected, cautious:remnants, cautious:signals, wanderer:detected, wanderer:remnants, wanderer:signals | 386 |
| +0 / +1 / +1 / +2.5 | 4.50 | 591 (400-1455) / 10 (6-11) / 0 (0-0) / 1 (0-6) / 1 (0-6) | 560 (363-1303) / 6 (5-7) / 0 (0-0) / 1 (0-6) / 1 (0-5) | cautious:detected, cautious:remnants, cautious:signals, cautious:contacts, wanderer:detected, wanderer:remnants, wanderer:signals, wanderer:contacts | 75 |
| +0 / +1.5 / +0.5 / +2.5 | 4.50 | 615 (399-1458) / 9 (6-11) / 0 (0-0) / 1 (0-6) / 1 (0-6) | 550 (361-1305) / 6 (5-7) / 0 (0-0) / 1 (0-6) / 1 (0-5) | cautious:detected, cautious:remnants, cautious:signals, cautious:contacts, wanderer:detected, wanderer:remnants, wanderer:signals, wanderer:contacts | 78 |
| -0.5 / +1.5 / +1 / +2.5 | 4.50 | 184 (138-438) / 9 (6-10) / 0 (0-0) / 1 (0-6) / 1 (0-6) | 162 (125-392) / 6 (5-7) / 0 (0-0) / 1 (0-6) / 1 (0-5) | cautious:detected, cautious:remnants, cautious:signals, cautious:contacts, wanderer:detected, wanderer:remnants, wanderer:signals, wanderer:contacts | 36 |
| -0.5 / +1.5 / +1 / +2.75 | 4.75 | 266 (137-450) / 7 (5-10) / 0 (0-0) / 3 (0-8) / 3 (0-6) | 297 (127-396) / 5 (5-7) / 0 (0-0) / 4 (0-8) / 3 (0-5) | cautious:detected, cautious:remnants, cautious:signals, cautious:contacts, wanderer:detected, wanderer:remnants, wanderer:signals, wanderer:contacts | 71 |
| -0.5 / +1.5 / +1 / +3 | 5.00 | 415 (350-466) / 6 (6-6) / 0 (0-0) / 10 (8-15) / 6 (6-6) | 371 (319-396) / 5 (5-5) / 0 (0-0) / 9 (7-14) / 5 (5-5) | cautious:detected, cautious:remnants, wanderer:detected, wanderer:remnants | 71 |
| -0.5 / +1.5 / +1 / +3.25 | 5.25 | 403 (393-424) / 7 (6-7) / 0 (0-0) / 17 (13-23) / 7 (6-7) | 341 (326-378) / 5 (5-6) / 0 (0-0) / 15 (11-21) / 5 (5-6) | cautious:detected, cautious:remnants, cautious:signals, wanderer:detected, wanderer:remnants, wanderer:signals | 136 |
| -0.75 / +1.5 / +1 / +2.75 | 4.50 | 105 (82-244) / 8 (6-9) / 0 (0-0) / 1 (0-6) / 1 (0-6) | 93 (61-216) / 6 (5-7) / 0 (0-0) / 1 (0-6) / 1 (0-5) | cautious:detected, cautious:remnants, cautious:signals, cautious:contacts, wanderer:detected, wanderer:remnants, wanderer:signals, wanderer:contacts | 26 |
| -0.75 / +1.5 / +1 / +3 | 4.75 | 171 (94-247) / 7 (5-9) / 0 (0-0) / 4 (1-9) / 4 (1-6) | 136 (95-217) / 5 (5-6) / 0 (0-0) / 4 (1-7) / 3 (1-5) | cautious:detected, cautious:remnants, cautious:signals, cautious:contacts, wanderer:detected, wanderer:remnants, wanderer:signals, wanderer:contacts | 35 |
| -0.75 / +1.5 / +1 / +3.25 | 5.00 | 234 (95-280) / 6 (6-9) / 0 (0-0) / 9 (2-15) / 6 (2-6) | 200 (95-235) / 5 (5-6) / 0 (0-0) / 7 (2-13) / 5 (2-5) | cautious:detected, cautious:remnants, wanderer:detected, wanderer:remnants | 62 |
| -0.75 / +1.5 / +1 / +3.5 | 5.25 | 238 (202-250) / 7 (6-7) / 0 (0-0) / 18 (13-22) / 7 (6-7) | 207 (176-221) / 5 (5-6) / 0 (0-0) / 16 (11-21) / 5 (5-6) | cautious:detected, cautious:remnants, cautious:signals, wanderer:detected, wanderer:remnants, wanderer:signals | 205 |
| -1 / +1.5 / +1 / +3 | 4.50 | 64 (54-142) / 9 (6-9) / 0 (0-0) / 1 (0-6) / 1 (0-6) | 48 (45-119) / 6 (5-6) / 0 (0-0) / 0 (0-6) / 0 (0-5) | cautious:remnants, cautious:signals, cautious:contacts, wanderer:remnants, wanderer:signals, wanderer:contacts | 57 |
| -1 / +1.5 / +1 / +3.25 | 4.75 | 108 (53-143) / 6 (5-9) / 0 (0-0) / 6 (0-10) / 5 (0-6) | 108 (44-133) / 5 (5-6) / 0 (0-0) / 5 (0-9) / 5 (0-5) | cautious:detected, cautious:remnants, wanderer:detected, wanderer:remnants | 44 |
| -1 / +1.5 / +1 / +3.5 | 5.00 | 134 (63-165) / 6 (6-9) / 0 (0-0) / 9 (2-16) / 6 (2-7) | 112 (63-140) / 5 (5-6) / 0 (0-0) / 7 (2-14) / 5 (2-5) | cautious:detected, cautious:remnants, wanderer:detected, wanderer:remnants | 65 |

The first four rows are the presets as they stand in `presets.ail` (Lonely, and the three development candidates).

## The cells that miss fewest bands

Every cell misses "detected" and "remnants" for both strategies. These miss nothing else. Means over 8 seeds with min-max; expected worlds at year 0 are the worlds package's closed forms (`starsWithin` x 0.20 x `historyProbabilities`), within 81.5 / 500 / 1,000 / 3,000 ly.

| Offsets | Luck | Civilisation lifetime | Strategy | detected | visited | remnants | signals | contacts | Technological worlds expected within 81.5 / 500 / 1,000 / 3,000 ly | Remnants expected, same radii |
|---|---|---|---|---|---|---|---|---|---|---|
| +0 / +1.5 / +1 / +2.25 | 4.75 | 1.78e+07 yr | cautious | 1042.6 (546-1413) | 7.0 (5-10) | 0.0 (0-0) | 5.1 (1-8) | 4.4 (1-6) | 2.25 / 446 / 3,012 / 46,879 | 0.10 / 20 / 138 / 2,146 |
| +0 / +1.5 / +1 / +2.25 | 4.75 | 1.78e+07 yr | wanderer | 966.5 (422-1236) | 5.2 (5-6) | 0.0 (0-0) | 5.4 (1-8) | 4.1 (1-5) | 2.25 / 446 / 3,012 / 46,879 | 0.10 / 20 / 138 / 2,146 |
| +0 / +1.5 / +1 / +2.5 | 5.00 | 3.16e+07 yr | cautious | 1218.9 (731-1474) | 6.5 (6-9) | 0.0 (0-0) | 9.5 (2-15) | 5.6 (2-7) | 4.00 / 793 / 5,356 / 83,364 | 0.10 / 20 / 138 / 2,146 |
| +0 / +1.5 / +1 / +2.5 | 5.00 | 3.16e+07 yr | wanderer | 1069.6 (708-1288) | 5.1 (5-6) | 0.0 (0-0) | 8.8 (2-14) | 4.6 (2-5) | 4.00 / 793 / 5,356 / 83,364 | 0.10 / 20 / 138 / 2,146 |
| -0.5 / +1.5 / +1 / +3 | 5.00 | 1e+08 yr | cautious | 415.1 (350-466) | 6.0 (6-6) | 0.0 (0-0) | 11.1 (8-15) | 6.0 (6-6) | 4.00 / 793 / 5,356 / 83,364 | 0.03 / 6.46 / 44 / 679 |
| -0.5 / +1.5 / +1 / +3 | 5.00 | 1e+08 yr | wanderer | 365.0 (319-396) | 5.0 (5-5) | 0.0 (0-0) | 9.5 (7-14) | 5.0 (5-5) | 4.00 / 793 / 5,356 / 83,364 | 0.03 / 6.46 / 44 / 679 |
| -0.75 / +1.5 / +1 / +3.25 | 5.00 | 1.78e+08 yr | cautious | 220.8 (95-280) | 6.4 (6-9) | 0.0 (0-0) | 9.6 (2-15) | 5.5 (2-6) | 4.00 / 793 / 5,356 / 83,364 | 0.02 / 3.63 / 25 / 382 |
| -0.75 / +1.5 / +1 / +3.25 | 5.00 | 1.78e+08 yr | wanderer | 194.1 (95-235) | 5.1 (5-6) | 0.0 (0-0) | 8.5 (2-13) | 4.6 (2-5) | 4.00 / 793 / 5,356 / 83,364 | 0.02 / 3.63 / 25 / 382 |
| -1 / +1.5 / +1 / +3.25 | 4.75 | 1.78e+08 yr | cautious | 105.0 (53-143) | 6.9 (5-9) | 0.0 (0-0) | 5.6 (0-10) | 4.1 (0-6) | 2.25 / 446 / 3,012 / 46,879 | 0.01 / 2.04 / 14 / 215 |
| -1 / +1.5 / +1 / +3.25 | 4.75 | 1.78e+08 yr | wanderer | 98.1 (44-133) | 5.4 (5-6) | 0.0 (0-0) | 4.9 (0-9) | 3.5 (0-5) | 2.25 / 446 / 3,012 / 46,879 | 0.01 / 2.04 / 14 / 215 |
| -1 / +1.5 / +1 / +3.5 | 5.00 | 3.16e+08 yr | cautious | 128.2 (63-165) | 6.5 (6-9) | 0.0 (0-0) | 10.0 (2-16) | 5.6 (2-7) | 4.00 / 793 / 5,356 / 83,364 | 0.01 / 2.04 / 14 / 215 |
| -1 / +1.5 / +1 / +3.5 | 5.00 | 3.16e+08 yr | wanderer | 114.0 (63-140) | 5.1 (5-6) | 0.0 (0-0) | 8.8 (2-14) | 4.6 (2-5) | 4.00 / 793 / 5,356 / 83,364 | 0.01 / 2.04 / 14 / 215 |

All of them sit at luck 4.75 to 5.0. A negative life offset trades living worlds for longer-lived civilisations at the same luck; lifetime offsets above +3.0 put the lifetime past the baseline prior's upper bound of 100 million years (D-144).

## What limits the dial

- **Minds and technology saturate.** The baseline medians are 0.032 (minds, given life) and 0.10 (technology, given minds). At +1.5 and +1.0 both are 1: every living world eventually has a technological civilisation. Larger offsets change nothing, so the search is one-dimensional beyond that point: lifetime.
- **The design expected 10^2 to 10^3 over the defaults.** The fully saturated minds and technology dials are 10^2.5, and at that luck with a short lifetime (row +0 / +1.5 / +1 / +1) the binding strategies hear no signal at all. The remaining 2.5 orders come from lifetime.
- **Contacts stop rising.** No cell or seed gave more than 8 contacts, however many signals there were: a 100-ship-year voyage has room for only so many arrivals.

## The two bands that are not met, and why

- **Biospheres detected (40-80).** The count is 444 (cautious) and 371 (wanderer) at the zero-offset baseline, before any dialling, and grows with luck because the ship makes more stops. It is the number of living worlds that came within 59.4 ly of a stop, each treated as an Earth twin of a Sun twin. A life offset of -1.0 with a lifetime of 316 million years still leaves it at 134 and 112. This band and the calibration's counter do not measure the same thing: the ledger, with each planet's own star and orbit, reads 20 to 52 living worlds from Sol depending on the dial (`evidence-candidate-counts.md`).
- **Remnants (3-6).** Zero in every cell and seed. Two causes, both structural. A Remnant has no signature of its own in the detector: it is seen only as one more living world, so no strategy can seek one out. And remnants are rare beside living civilisations once lifetimes are long: at the proposed cell about 0.10 remnant is expected within 81.5 ly against 4.0 technological worlds (traces last at most 10 million years; civilisations last 32 million).

Meeting either band needs a ruling on the model, not a different dial: what "detected" should count, and whether remnants are detectable.

## The proposed Stapledon cell with all four strategies (seeds 8-15, a second batch)

Offsets +0 / +1.5 / +1 / +2.5, luck 5.00; 500 s. Bands missed by the binding strategies in this batch: cautious:detected, cautious:remnants, wanderer:detected, wanderer:remnants.

| Strategy | detected | visited | remnants | signals | contacts | ship years | Earth years |
|---|---|---|---|---|---|---|---|
| cautious | 1333.9 (1266-1412) | 6.0 (5-7) | 0.0 (0-0) | 9.9 (7-13) | 6.0 (5-7) | 95.1 | 770 |
| wanderer | 1195.2 (1079-1274) | 5.0 (5-5) | 0.0 (0-0) | 9.4 (7-12) | 5.0 (5-5) | 96.5 | 686 |
| pilgrim | 560.4 (467-747) | 9.9 (9-10) | 0.0 (0-0) | 5.0 (4-7) | 0.4 (0-1) | 99.8 | 245 |
| waiter | 225.5 (198-244) | 1.0 (1-1) | 0.0 (0-0) | 3.5 (2-6) | 1.0 (1-1) | 100.0 | 245 |

The pilgrim's median is 0 contacts and the waiter's 1: the living-contact floor that D-144 asks to be reported is not met by either at this cell.

For comparison, seeds 0-7 gave the binding strategies (medians) cautious 1240 (731-1474) / 6 (6-9) / 0 (0-0) / 10 (2-15) / 6 (2-7) and wanderer 1047 (708-1288) / 5 (5-6) / 0 (0-0) / 9 (2-14) / 5 (2-5).

## The map at the candidate dials (the Sol funnel, 5 seeds, whole registry)

The evidence probe's funnel from Sol at year 0, with the ship's suite, at the proposed cells (mean (min-max) over seeds 0-4). Full output at the end.

| stage | lonely 0/0/0/0 | scattered 0/1.5/1/2.0 | stapledon 0/1.5/1/2.5 | stapledon-alt 0/1.5/1/2.75 | teeming 0.25/1.5/1/3.0 |
|---|---|---|---|---|---|
| truth: living (Microbial or better) | 630.8 (587-704) | 555.8 (519-622) | 556.4 (519-623) | 557.2 (519-623) | 891.8 (847-953) |
| truth: Technological | 0.0 (0-0) | 1.8 (1-4) | 5.0 (3-7) | 7.8 (5-11) | 21.4 (19-23) |
| truth: Remnant | 0.0 (0-0) | 0.2 (0-1) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Ecocide or Transcended | 0.2 (0-1) | 75.2 (68-85) | 74.6 (68-85) | 73.8 (67-84) | 115.4 (104-132) |
| living + oxygen: imaged at SNR >= 5 (an oxygen record) | 19.8 (16-24) | 31.6 (29-34) | 31.6 (29-34) | 31.6 (29-34) | 51.6 (43-60) |
| Technological: radar class (beam crosses the ship) | 0.0 (0-0) | 0.4 (0-2) | 0.8 (0-3) | 1.2 (0-4) | 2.6 (0-7) |
| Technological, radar class, inside the dish's hint reach | 0.0 (0-0) | 0.4 (0-2) | 0.8 (0-3) | 1.2 (0-4) | 2.6 (0-7) |
| Technological, inside the dish's TV-carrier hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: oxygen detections, all worlds | 22.4 (20-26) | 36.4 (31-40) | 36.4 (31-40) | 36.4 (31-40) | 56.8 (49-62) |
| record: leakage detections | 0.0 (0-0) | 0.4 (0-2) | 0.8 (0-3) | 1.2 (0-4) | 2.6 (0-7) |
| record: worlds with a biosignature or leakage detection | 26.8 (23-31) | 42.0 (36-47) | 42.4 (36-48) | 42.8 (36-49) | 65.0 (53-74) |

- At the proposed Stapledon cell about 5 technological worlds (3 to 7) lie inside the 81.5 ly registry; the nearest is 28 to 51 ly from Sol. About one of them (0 to 3) is radar class, and the dish hears every radar-class world in the registry. None is inside the TV carrier's 0.42 ly reach.
- So a player at Sol sees about 42 worlds with a biosignature and, zero to three radio signals (0.8 on average).
- About 75 worlds within 81.5 ly are Ecocide or Transcended at every saturated cell: with minds and technology at 1, about one living world in eight has already had its civilisation and lost it that way.

## The structural gap

- **Most of the calibrated universe's minds are beyond the map.** At the proposed cell the closed forms give about 4 technological worlds within 81.5 ly, 790 within 500 ly, 5,400 within 1,000 ly and 83,000 within 3,000 ly. The calibration's voyages meet their 5 to 7 contacts by ranging hundreds of light-years (about 700 to 800 Earth years per voyage for the binding strategies). The game's worlds exist only where `data/starmap/stars.json` has a star: 5,685 systems within 25 pc.
- **What the sim has beyond the registry today:** nothing that can hold a world. The sky tiers (GCNS to 100 pc, the bright Hipparcos stars) are rendered, but `worlds_model` populates planets only for registry rows, and a signal needs a host. The calibration's own disc is a count model with no stars and is not connected to the map.
- **What the finder would need:** hosts out to at least the dish's 168 ly radar reach, and for the wanderer's play to 500 ly or more. That is the planned large tier (`design_docs/planned/r1/starmap-large-tier-and-reach.md`, destinations to 100 pc / 326 ly, L3 still open) and, past the measured core, the synthesised remainder of the design repo's `galaxy-beyond-measurement.md`. Until then a radar heard from 100 ly has no star to attach to.
- The two models also disagree on what the ship can read optically (the table above), so encounter counts from the calibration will not match what the map shows even inside 81.5 ly.

## Proposed offsets (for the ruling; nothing is written to `presets.ail`)

| Preset | life | minds | technology | lifetime | Luck | Evidence |
|---|---|---|---|---|---|---|
| Lonely Universe | 0 | 0 | 0 | 0 | 0 | the fixed baseline: no signals or contacts in 8 seeds; cautious 418 (409-516) / 10 (10-11) / 0 (0-0) / 0 (0-0) / 0 (0-0) |
| Scattered Few | 0 | +1.5 | +1.0 | +2.0 | 4.50 | cautious 574 (366-1192) / 9 (5-11) / 0 (0-0) / 1 (0-6) / 1 (0-6); wanderer 527 (333-1192) / 6 (5-7) / 0 (0-0) / 1 (0-6) / 1 (0-5); about 1.3 technological worlds expected within 81.5 ly |
| Stapledon's Voyage | 0 | +1.5 | +1.0 | +2.5 | 5.00 | signals and contacts in band for both binding strategies in two seed batches (above); about 4.0 technological worlds expected within 81.5 ly, 5,356 within 1,000 ly |
| Teeming Galaxy | +0.25 | +1.5 | +1.0 | +3.0 | 5.70 | cautious 1900 (1564-2109) / 7 (7-8) / 0 (0-0) / 44 (34-56) / 7 (7-8); wanderer 1459 (1262-1677) / 6 (5-6) / 0 (0-0) / 38 (30-47) / 6 (5-6) (675 s); lifetime at the prior's upper bound, 100 million years; life saturates at +0.2 |

- "Civilisations alive within 1,000 ly" at the proposed default (Decision 4's one figure): **about 5,356** expected at year 0 (closed form; the calibration's own runs are consistent with it through the signal counts, but it was not counted directly).
- The luck the Archive would reveal for the default is 10^5.0, not 10^3.
- Alternatives at the same luck that keep signals and contacts in band: -0.5 / +1.5 / +1.0 / +3.0, and -1.0 / +1.5 / +1.0 / +3.25 (lifetime past the prior's bound). They bring "detected" down without reaching the band.
- **The spread is wide.** At the proposed cell single seeds give 2 to 15 signals and 2 to 7 contacts; the wanderer's mean contacts are 4.6 with a median of 5. The -0.5 / +1.5 / +1.0 / +3.0 cell is steadier (8 to 15 signals, contacts 6 and 5 in every seed).
- These offsets are evidence from 8 seeds per cell on two strategies. The planned 256-seed, four-strategy matrix, Gentle and Hard clocks, and the slice-seed search remain to be run after the ruling.

## Things that look wrong or need a decision (nothing was changed)

- "Detected" in the calibration is not what the ledger records (above). One of the two should change before the 40-80 band can mean anything.
- No remnant can be detected or sought, so the remnant band is unreachable.
- Minds and technology saturating at 1 makes every living world a past, present or future civilisation, and fills the neighbourhood with Ecocide and Transcended worlds. Reaching the targets through lifetime alone gives civilisations 32 million years old on average.
- The design's "10^2 to 10^3" expectation and Decision 2's example "10^3" do not match the measured 10^5.
- `calibrate.simulate` populated background biospheres out to the detector's whole support (168 ly with the real detector), 23 times the volume a biosphere can respond in. `Detect.bioSupportLy` removes that; the `equivalence` entry shows identical rows for seed 0 at the proposed cell. This is a performance change to `sim/calibrate.ail`, the only edit to it.

## Gates re-run on this branch (development overlay, 2026-11-12)

| Command | Result |
|---|---|
| `ailang check --package $O` | `167 files checked, all passed!` |
| `make evidence-test AILANG=tools/observe_ailang.sh` | `20 tests: 20 passed, 0 failed` |
| `make evidence-parity AILANG=tools/observe_ailang.sh` | `evidenceVm 12 bytes`, `ledgerVm 6794 bytes (strict VM = interpreter)` |
| `ailang test --strict-bytecode` on `calibrate_test`, `calibrate_search_test` | `19 tests: 19 passed` |
| `make strict AILANG=tools/observe_ailang.sh` | exit 0 (worlds-parity including `calibVm 2 development seeds byte-identical`, rng-keyed, evidence-parity) |
| `make parity AILANG=tools/observe_ailang.sh` | exit 0, `replay: 1 cases, all identical` |

The measurement itself ran on the bytecode VM only.

## Raw funnel output at the candidate dials

evidence-probe: telescope coronagraph-10m (10.0 m), receiver dish-100m, look 30.0 days; from (0.0, 0.0, 0.0) ly at year 0.0; 5685 registry systems; seeds 0..4; cells are mean (min-max) over seeds

**Within 60.0 ly of the ship**

| stage | lonely 0/0/0/0 | scattered 0/1.5/1/2.0 | stapledon 0/1.5/1/2.5 | stapledon-alt 0/1.5/1/2.75 | teeming 0.25/1.5/1/3.0 |
|---|---|---|---|---|---|
| planets populated (outside the ship's own system) | 4641.8 (4582-4708) | 4641.8 (4582-4708) | 4641.8 (4582-4708) | 4641.8 (4582-4708) | 4641.8 (4582-4708) |
| planets habitable or debated | 400.8 (385-435) | 400.8 (385-435) | 400.8 (385-435) | 400.8 (385-435) | 400.8 (385-435) |
| truth: living (Microbial or better) | 250.6 (230-278) | 219.6 (205-244) | 220.0 (206-245) | 220.2 (206-245) | 353.0 (336-386) |
| truth: Complex or better | 75.8 (69-94) | 219.6 (205-244) | 220.0 (206-245) | 220.2 (206-245) | 353.0 (336-386) |
| truth: PreTech | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Technological | 0.0 (0-0) | 1.0 (0-3) | 2.4 (1-4) | 3.6 (2-6) | 8.2 (5-10) |
| truth: Remnant | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Ecocide or Transcended | 0.2 (0-1) | 31.2 (22-40) | 30.8 (22-40) | 30.6 (22-39) | 47.8 (33-56) |
| living, shows oxygen (O2, with or without CH4) | 124.6 (118-130) | 198.6 (187-217) | 198.8 (187-218) | 198.8 (187-218) | 318.2 (304-340) |
| living, shows O2 + CH4 | 88.6 (76-97) | 151.4 (140-166) | 151.4 (140-166) | 151.4 (140-166) | 238.8 (223-256) |
| living, shows the red edge | 37.2 (32-50) | 93.2 (83-98) | 93.2 (83-98) | 93.2 (83-98) | 150.8 (140-162) |
| living + oxygen: star and planet sizes known | 124.6 (118-130) | 198.6 (187-217) | 198.8 (187-218) | 198.8 (187-218) | 318.2 (304-340) |
| living + oxygen: outside the inner working angle | 21.6 (17-25) | 33.6 (30-36) | 33.6 (30-36) | 33.6 (30-36) | 55.6 (50-62) |
| living + oxygen: outside it and above the noise floor | 18.2 (13-20) | 28.2 (25-32) | 28.2 (25-32) | 28.2 (25-32) | 45.4 (39-52) |
| living + oxygen: imaged at SNR >= 5 (an oxygen record) | 16.4 (13-18) | 26.6 (25-29) | 26.6 (25-29) | 26.6 (25-29) | 42.8 (37-49) |
| living + oxygen: imaged at SNR >= 10 | 11.0 (10-13) | 18.2 (15-22) | 18.2 (15-22) | 18.2 (15-22) | 27.6 (25-31) |
| living + oxygen: orbit transits as seen from here | 1.8 (1-2) | 2.8 (2-4) | 2.8 (2-4) | 2.8 (2-4) | 4.8 (3-6) |
| living + oxygen: transit seen (census record only) | 1.4 (1-2) | 2.6 (1-4) | 2.6 (1-4) | 2.6 (1-4) | 4.0 (3-5) |
| WHAT-IF transit spectrum: living + oxygen, transit seen, continuum SNR >= 5 with the working angle and noise floor ignored | 0.2 (0-1) | 0.2 (0-1) | 0.2 (0-1) | 0.2 (0-1) | 1.0 (0-2) |
| living (any): outside the inner working angle | 43.0 (39-47) | 37.4 (34-41) | 37.4 (34-41) | 37.4 (34-41) | 62.0 (57-68) |
| living (any): imaged at SNR >= 5 | 33.8 (29-40) | 29.8 (26-35) | 29.8 (26-35) | 29.8 (26-35) | 48.4 (43-54) |
| Technological: radar class (beam crosses the ship) | 0.0 (0-0) | 0.0 (0-0) | 0.4 (0-1) | 0.4 (0-1) | 1.0 (0-3) |
| Technological, radar class, inside the dish's hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.4 (0-1) | 0.4 (0-1) | 1.0 (0-3) |
| Technological, inside the dish's TV-carrier hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: planets imaged | 289.6 (265-303) | 289.6 (265-303) | 289.6 (265-303) | 289.6 (265-303) | 289.6 (265-303) |
| record: planets seen in transit | 124.6 (113-141) | 124.6 (113-141) | 124.6 (113-141) | 124.6 (113-141) | 124.6 (113-141) |
| record: oxygen detections, all worlds | 18.8 (17-22) | 31.2 (27-34) | 31.2 (27-34) | 31.2 (27-34) | 47.4 (43-51) |
| record: oxygen detections on sterile worlds (false positives) | 2.4 (0-4) | 2.4 (0-4) | 2.4 (0-4) | 2.4 (0-4) | 2.2 (0-4) |
| record: red-edge detections, all worlds | 9.0 (6-11) | 22.0 (20-24) | 22.0 (20-24) | 22.0 (20-24) | 33.2 (31-38) |
| record: red-edge detections on sterile worlds (false positives) | 2.4 (1-5) | 2.4 (1-5) | 2.4 (1-5) | 2.4 (1-5) | 1.4 (0-4) |
| record: leakage detections | 0.0 (0-0) | 0.0 (0-0) | 0.4 (0-1) | 0.4 (0-1) | 1.0 (0-3) |
| record: worlds with a biosignature or leakage detection | 22.8 (19-27) | 35.6 (32-40) | 36.0 (32-41) | 36.0 (32-41) | 52.8 (45-58) |

**Whole registry (25 pc, 81.5 ly, around Sol)**

| stage | lonely 0/0/0/0 | scattered 0/1.5/1/2.0 | stapledon 0/1.5/1/2.5 | stapledon-alt 0/1.5/1/2.75 | teeming 0.25/1.5/1/3.0 |
|---|---|---|---|---|---|
| planets populated (outside the ship's own system) | 11647.2 (11515-11800) | 11647.2 (11515-11800) | 11647.2 (11515-11800) | 11647.2 (11515-11800) | 11647.2 (11515-11800) |
| planets habitable or debated | 1007.2 (951-1085) | 1007.2 (951-1085) | 1007.2 (951-1085) | 1007.2 (951-1085) | 1007.2 (951-1085) |
| truth: living (Microbial or better) | 630.8 (587-704) | 555.8 (519-622) | 556.4 (519-623) | 557.2 (519-623) | 891.8 (847-953) |
| truth: Complex or better | 197.4 (178-222) | 555.8 (519-622) | 556.4 (519-623) | 557.2 (519-623) | 891.8 (847-953) |
| truth: PreTech | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Technological | 0.0 (0-0) | 1.8 (1-4) | 5.0 (3-7) | 7.8 (5-11) | 21.4 (19-23) |
| truth: Remnant | 0.0 (0-0) | 0.2 (0-1) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Ecocide or Transcended | 0.2 (0-1) | 75.2 (68-85) | 74.6 (68-85) | 73.8 (67-84) | 115.4 (104-132) |
| living, shows oxygen (O2, with or without CH4) | 309.4 (273-343) | 501.6 (467-555) | 502.0 (467-556) | 502.6 (467-556) | 802.2 (760-850) |
| living, shows O2 + CH4 | 229.0 (209-267) | 387.8 (357-437) | 387.8 (357-437) | 388.4 (357-437) | 614.0 (581-657) |
| living, shows the red edge | 97.8 (88-114) | 239.8 (217-262) | 239.4 (217-260) | 239.2 (217-260) | 385.0 (367-412) |
| living + oxygen: star and planet sizes known | 309.4 (273-343) | 501.6 (467-555) | 502.0 (467-556) | 502.6 (467-556) | 802.2 (760-850) |
| living + oxygen: outside the inner working angle | 37.2 (30-43) | 58.4 (51-62) | 58.4 (51-62) | 58.4 (51-62) | 97.2 (89-109) |
| living + oxygen: outside it and above the noise floor | 27.4 (20-32) | 43.2 (35-47) | 43.2 (35-47) | 43.2 (35-47) | 69.8 (61-82) |
| living + oxygen: imaged at SNR >= 5 (an oxygen record) | 19.8 (16-24) | 31.6 (29-34) | 31.6 (29-34) | 31.6 (29-34) | 51.6 (43-60) |
| living + oxygen: imaged at SNR >= 10 | 11.0 (10-13) | 18.2 (15-22) | 18.2 (15-22) | 18.2 (15-22) | 27.6 (25-31) |
| living + oxygen: orbit transits as seen from here | 3.2 (2-5) | 5.0 (2-7) | 5.0 (2-7) | 5.0 (2-7) | 8.8 (7-11) |
| living + oxygen: transit seen (census record only) | 2.0 (1-4) | 3.6 (1-6) | 3.6 (1-6) | 3.6 (1-6) | 5.8 (3-8) |
| WHAT-IF transit spectrum: living + oxygen, transit seen, continuum SNR >= 5 with the working angle and noise floor ignored | 0.2 (0-1) | 0.2 (0-1) | 0.2 (0-1) | 0.2 (0-1) | 1.0 (0-2) |
| living (any): outside the inner working angle | 74.8 (65-81) | 65.2 (57-71) | 65.2 (57-71) | 65.2 (57-71) | 109.0 (98-121) |
| living (any): imaged at SNR >= 5 | 41.4 (34-47) | 35.8 (30-40) | 35.8 (30-40) | 35.8 (30-40) | 59.0 (51-66) |
| Technological: radar class (beam crosses the ship) | 0.0 (0-0) | 0.4 (0-2) | 0.8 (0-3) | 1.2 (0-4) | 2.6 (0-7) |
| Technological, radar class, inside the dish's hint reach | 0.0 (0-0) | 0.4 (0-2) | 0.8 (0-3) | 1.2 (0-4) | 2.6 (0-7) |
| Technological, inside the dish's TV-carrier hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: planets imaged | 356.2 (328-377) | 356.2 (328-377) | 356.2 (328-377) | 356.2 (328-377) | 356.2 (328-377) |
| record: planets seen in transit | 282.6 (263-294) | 282.6 (263-294) | 282.6 (263-294) | 282.6 (263-294) | 282.6 (263-294) |
| record: oxygen detections, all worlds | 22.4 (20-26) | 36.4 (31-40) | 36.4 (31-40) | 36.4 (31-40) | 56.8 (49-62) |
| record: oxygen detections on sterile worlds (false positives) | 2.6 (0-4) | 2.6 (0-4) | 2.6 (0-4) | 2.6 (0-4) | 2.2 (0-4) |
| record: red-edge detections, all worlds | 10.8 (8-16) | 26.2 (24-28) | 26.2 (24-28) | 26.2 (24-28) | 40.4 (35-45) |
| record: red-edge detections on sterile worlds (false positives) | 2.4 (1-5) | 2.4 (1-5) | 2.4 (1-5) | 2.4 (1-5) | 1.4 (0-4) |
| record: leakage detections | 0.0 (0-0) | 0.4 (0-2) | 0.8 (0-3) | 1.2 (0-4) | 2.6 (0-7) |
| record: worlds with a biosignature or leakage detection | 26.8 (23-31) | 42.0 (36-47) | 42.4 (36-48) | 42.8 (36-49) | 65.0 (53-74) |

**Nearest, light-years from the ship, per seed**

| preset | nearest living world | nearest living world showing oxygen | nearest Technological world | planets in the ship's own system (not observed remotely) |
|---|---|---|---|---|
| lonely 0/0/0/0 | 8.3, 4.2, 9.7, 7.9, 4.2 | 8.3, 4.2, 10.3, 7.9, 11.4 | none, none, none, none, none | 0, 0, 0, 0, 0 |
| scattered 0/1.5/1/2.0 | 8.3, 4.2, 10.3, 7.9, 4.2 | 8.3, 4.2, 10.3, 7.9, 7.9 | 51.1, 63.1, 28.1, 69.5, 58.2 | 0, 0, 0, 0, 0 |
| stapledon 0/1.5/1/2.5 | 8.3, 4.2, 10.3, 7.9, 4.2 | 8.3, 4.2, 10.3, 7.9, 7.9 | 50.9, 48.8, 28.1, 48.9, 48.1 | 0, 0, 0, 0, 0 |
| stapledon-alt 0/1.5/1/2.75 | 8.3, 4.2, 10.3, 7.9, 4.2 | 8.3, 4.2, 10.3, 7.9, 7.9 | 22.3, 48.8, 28.1, 29.0, 48.1 | 0, 0, 0, 0, 0 |
| teeming 0.25/1.5/1/3.0 | 4.2, 4.2, 4.2, 4.2, 4.2 | 4.2, 4.2, 4.2, 4.2, 7.9 | 22.3, 16.3, 28.1, 29.0, 34.2 | 0, 0, 0, 0, 0 |
