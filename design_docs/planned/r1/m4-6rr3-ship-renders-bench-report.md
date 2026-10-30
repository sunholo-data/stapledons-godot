# M4.6rR3 executor report: S1 renders and the ship bench

**Iteration 36, executor.** Base `da44d59` (design `7b4bee0` + plan). Rig: Apple M4 Max, Metal, Forward+, Godot 4.7.2, AILANG v0.54.11. Every command below ran outside any sandbox, from the unattended session with the GPU window. S1 is **pending Mark's sign-off**; this PR parks unmerged.

## Public set

Base URL: `https://storage.googleapis.com/stapledons-voyage-assets/refs/m4_ship_s1/`. It holds 18 files: 15 PNGs, `manifest.json`, `m4_manifest.sha256` and `worlds.sha256`. AC6 fetched all 18 and found every one byte-equal to the local set.

**Reproducibility (row 7l, iteration 59).** Only the worlds are reproducible, not the pixels: a second `make capture-m4` on the same tree gives a byte-equal `worlds.sha256`, but the PNG hashes differ between runs (12 of 15 in the iteration-36 evaluation, which traced dust-impact flashes and HUD card fades; 15 of 15 at `e94ed9b7`, where even the docked frames differ, cause not traced). The AC5 table below describes one run, the published set. At `e94ed9b7` a fresh capture matches the public set in none of its 14 world hashes and none of its 15 PNG hashes, so S1 review should use a fresh capture.

## AC5: each PNG, opened and looked at

Captain eye at the helm, seed 424242, medium tier (60,883 stars), 1600×900, HUD visible. The deck view is tilt 30°, yaw 0.47; the forward view is tilt 89.99°, the travel pole.

| file | what I saw |
|---|---|
| renders/m4/01_docked_deck.png | Bridge deck at rest near Earth: rail, stanchions, helm chair and dome. The Milky Way runs dimly up the middle. The clock card reads Ship +0 s / Earth +0 s, "Near Earth · at rest, from Earth 50,000 km". A beige hull spire fills the left edge. No transit cards. |
| renders/m4/01_docked_forward.png | The travel pole at rest: a large, featureless white disc with a soft halo at the centre. It is Earth on the heading, saturated white with no visible phase. Around it are a star field and a red nebula on the right. A spire tip intrudes from the lower left. |
| renders/m4/02_boost_b05_deck.png | Boost at 0.5049c, γ 1.16, ACCELERATING towards Alpha Centauri A. The Milky Way is brighter and bluer overhead than at rest. The Transit card (LIC, 0.2474 cm⁻³, ISM load 3.9 suns, Glow on) and a "New in the Archive" card cover the right third. |
| renders/m4/02_boost_b05_forward.png | Forward at 0.5c: a dense blue-white band of aberrated Milky Way through the pole. The stars are visibly crowded forward; there is no ring yet. The same two cards are on the right, and the spire tip is lower left. |
| renders/m4/03_boost_b09_deck.png | Boost at 0.9006c, γ 2.30. The deck sky is darker at the sides and the stars are thinning towards the horizon. Transit card: ISM load 49.4 suns, dust 10.57/ship-s. The Archive card is gone (aged out). |
| renders/m4/03_boost_b09_forward.png | Forward at 0.9c: a bright, washed-out white-blue band concentrated through the pole. The background is blue-shifted and denser than at 0.5c; this is the start of the starbow concentration. The spire tip is lower left. |
| renders/m4/04_cruise_099_deck.png | Cruise at 0.9900c, γ 7.09, CRUISE. The deck sky is almost black (the stars have crowded forward), with faint stars only near the top. Several small orange-brown ellipses (dust-impact flashes) are scattered over the sky. ISM load 566.9 suns. The Archive card ("The Medium and the Glow…") is half-faded at bottom right. |
| renders/m4/04_cruise_099_forward.png | Forward at 0.99c: the starbow, a compact oval of bright blue-white stars and a white core at the pole, with dark sky all around. There is no separate glow disc. The sim's glow_pole is 3.35e-5 W/m², which reads as part of the central whiteness, not a distinct feature. The cards are on the right, the spire lower left. |
| renders/m4/05_brake_b05_deck.png | Braking at 0.4999c, +224.9 d ship / +4.36 yr Earth, 0.013 AU from α Cen A. The Milky Way is back overhead. There are a few orange dust flashes. Transit card: Local Bubble hot gas, Gap 3.7490 yr. |
| renders/m4/05_brake_b05_forward.png | Forward while braking (no flip): α Cen A is a small bright white disc with a halo at the pole, set in a blue-shifted Milky Way band. A few faint orange dust flashes; the spire tip is lower left. |
| renders/m4/06_arrived_acen_deck.png | Arrived and at rest at α Cen A, 0.059 AU. The Arrived card shows 4.321 ly, ship 0.616 yr, Earth 4.365 yr, Gap 3.749 yr, Dismiss [Enter]. Below it, the Transit card is half-faded. The Milky Way is warm-toned overhead. |
| renders/m4/06_arrived_acen_forward.png | α Cen A as a large white disc with a halo at the pole, the Milky Way behind it. Arrived card; the Transit card is a faint ghost below it. The spire tip is lower left. |
| renders/m4/07_arrived_home_deck.png | Home: +449.8 d ship / +8.73 yr Earth, "At Earth 24,642 km". The Moon is a small crescent at upper left. There are **orange dust-impact ellipses on the sky although the ship is at rest** (see Findings). Arrived card with Gap 7.498 yr; the Transit card is faded below it. |
| renders/m4/07_arrived_home_forward.png | Earth fills the centre as a gibbous disc, clipped to solid white with a dark terminator on the right; no surface detail. Two orange dust flashes; Arrived card; the spire tip is lower left. |
| renders/m4/contact_sheet.png | 2276×366: 7 columns × 2 rows (deck on top, forward below), in state order docked → home. Every thumbnail matches its full frame. The sequence reads correctly: the sky darkens on deck as β rises, the starbow tightens forward at 0.99c, and the arrival discs appear. |

### Findings from the look (for S1, not fixed here)

1. **Saturated discs.** Earth (docked, home) and α Cen A (arrival) are clipped to flat white with no limb or surface detail.
2. **Dust flashes at rest.** Orange dust-impact ellipses still show in `07_arrived_home_*` while the ship is at rest near Earth. They are probably flashes from the end of the leg that have not yet aged out under the capture's tick loop, but they look wrong at rest.
3. **Fading card ghosts.** A half-faded Transit card sits under the Arrived card in 06 and 07, and the Archive card is half-faded in `04_cruise_099_deck`. This is the real HUD in mid-fade.
4. **Spire in the forward view.** A hull spire tip intrudes from the lower left in every forward frame.
5. **HUD coverage.** The Transit and Archive cards cover about 30 % of the transit frames on the right.
6. **The cruise glow is not a distinct feature** at the sim's 3.35e-5 W/m² (Contradictions 3). It reads as part of the starbow's white core.

## Gates

| gate | command | rc | asserted counts |
|---|---|---|---|
| AC1 | `m capture-m4` + count block | 0 | 14 ok frame, 1 OK, 0 FAIL, 0 SCRIPT ERROR, 15 PNG, 15/15 distinct hashes, 14 worlds, `shasum -c` ok |
| AC2 | per-file + cruise + rest-glow counts | 0 | 14 named files × 1; cruise `beta 0.99` = 2; zero-glow 01/06/07 = 6 |
| AC3 | plan `jq -e` (and design grep form) | 0 / 0 | 14 frames, 7 unique worlds shared per pair, 2 α Cen + 2 Sol targets |
| AC4 | second capture, `cmp worlds.sha256` | 0 | 14 rows both runs, byte-equal |
| AC5 | this table | 0 | 15 rows, names = `m4_manifest.sha256` |
| AC6 | `m capture-m4-publish` + curl loop (and design form) | 0 / 0 | `uploaded 18 files` ×1; 18/18 public byte-equal (design form 15/15) |
| AC7 | `m bench SCENE=bridge` block | 0 (raw make 2, driver 2) | OK 1, FAIL 0, frame-ms 1, MISS 1, footer `FAILED (exit 2:` 1 |
| AC8 | p99 < 16.7 | **1 (expected red)** | MISS, p99 219.3 ms |
| AC9 | default bench dry run vs `7b4bee0`, SCENE=nope, SCENE=bridge -n | 0 | sha `2bd542c8…a465` both; nope rc 2, 1 message; bridge 1 driver line |
| AC10–13 | drills, below | 0 each | as below |
| AC14 | `git diff --quiet 7b4bee0 -- demos interior ui sky bridge sim physics assets data main.gd export_presets.cfg tools/interior_capture.gd tools/bench.gd .github mk` | 0 | 0 files |
| golden | `m golden` | 0 | 373 ok, 0 FAIL, `golden: 0 failures` ×1 |
| guards | `make lint-precision python-guard ai-live-guard` | 0 | no new `*.py` |
| deps | `make deps` | 0 | lock unchanged |
| lore | `make lore-import CHECK=1 D=/Users/voightkampff/dev/sunholo-data/stapledons-design` | 0 | 15 files hash-equal both sides; design repo at `c170604` equals the vendored copy (D read-only; `/tmp/stapledons-design` absent) |
| make test | not run by the executor | n/a | the controller runs it separately |

## Bench (AC7/AC8)

The run that passed AC7 (host load 9.20 / 5.42 / 6.08; another clone's `ailang` was at 308 % CPU):

```
bench-bridge: docked control 300 frames p50 17.81 p95 54.90 p99 61.83 ms (no journey ticks; not gated)
bench-bridge: live transit 367 frames in 30.0 s (boosting 188, cruising 179), end beta 0.9900, sim wait p50 1.39 ms/frame
bench-bridge: frame ms p50 73.032  p95 160.893  p99 219.267  max 323.85; 367 of 367 frames over 16.7 ms (target p99 < 16.7: MISS)
```

Two earlier runs, under host load of 6.4–13, were rejected as **structurally invalid**: 264 and 194 frames, against the 300-frame minimum (`FAIL measured 264 frames`). The minimum did its job. DB3's run measured 364 frames with a docked control of p50 8.89 / p99 14.59, and live transit at p50 73.0 / p99 185.4. AC8 stays red until M4.6pR3, as the design expected. These live-transit numbers are worse than the spike's (p50 41), because the rig was loaded throughout. Take AC8 on a quiet rig.

## Drills (temp copies, plan wrapper)

| drill | wrapper rc | make rc | count / want | result |
|---|---|---|---|---|
| DC0 positive control | 0 | 0 | OK 1/1 | green |
| DC1 blank | 0 | 2 | 14/14 | killed |
| DC2 forward = deck | 0 | 2 | 1/1 | killed (after the settle fix; see hand edits) |
| DC3 β 1.5 unreachable | 0 | 2 | 1/1 | killed |
| DC4 views overwrite | 0 | 2 | 7/7 | killed |
| DC5 stale set, early quit | 0 | 2 | 0/0 | killed |
| DB1 BENCH_S 0 | 0 | 2 | 1/1 | killed |
| DB2 half-size viewport | 0 | 2 | 1/1 | killed |
| DB3 target 1000.0 (green control) | 0 | 0 | 1/1 | green |
| no-op, errexit on / off | 3 / 3 | n/a | message 1 each | harness error, as required |
| bad ROOT | 2 | n/a | n/a | as required |

Integrity: `git status --porcelain`, `git diff --stat` and the `git diff` sha were identical before and after both drill passes. No `/tmp/m46r-copy.*` was left behind.

## Hand edits after codex (executor, all in `tools/`)

1. **Cruise β tolerance** (`m4_ship_capture.gd`). The sim's cruise β is `0.9900000000000004`, so the design's exact `β == 0.99` failed the first capture (`FAIL cruise_099 values`). The check is now `absf(beta - 0.99) < 1e-12`.
2. **Walk and dolly bounds in wall time** (both drivers). The design's 600-frame walk bound flaked on the second capture (`FAIL walk to navigation exceeded 600 frames`): walking is real-time at 3.5 m/s, and a fast frame rate exhausts 600 frames too early. Both walk waits and both dolly waits are now bounded at 30 s of wall time.
3. **Docked settle** (`m4_ship_capture.gd`). DC2 first **survived** (make rc 0, 0 duplicate lines). The first frame after the walk-to-DECK pose change differs from later frames at the same pose; a probe measured 53k differing pixels, then 0 thereafter. So a stuck forward view escaped the duplicate rule. The docked state now poses DECK and waits 60 frames before its shots. DC2 is then killed (1/1), and the whole drill pass was re-run on the final driver.
