# A reproducible S1 capture, published to a new dated path (row 7w)

**Status:** Planned, mission iteration 66, designer, 2026-11-03; **revised after quorum round 1** (see [Quorum round 1](#quorum-round-1)). **Release:** r1. **Milestone:** M4.6rR3 follow-up, charter queue row **7w** (clause 4 hygiene, S1 evidence) inside the approved sprint `R1-M4-JOURNEY` (D-22/D-66).
**Priority:** P2 (follow-up backlog). Capture tooling, a maintainer-only publish recipe, its headless test and report text.
**Implements:** [charter](../../stapledon-mission.md) row 7w; the follow-up of [m4-7l-capture-followups.md](m4-7l-capture-followups.md) (row 7l(c) wrote the "only the worlds are reproducible" note; 7l(a) made the publish check its 18 files first) and of [m4-6rr3-ship-renders-bench.md](m4-6rr3-ship-renders-bench.md) (the S1 set). The [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) stays untouched: no formula, sim, protocol, shader or scene changes.
**Depends on:** D-88 A (test and audit hygiene inside an approved sprint needs no stop); AILANG v0.56.1 (`runtime/bin`), Godot 4.7.2, the GPU window; the 7l(a) publish test (`tools/test_m4_publish.sh`, landed in iteration 65).
**Estimated LOC:** about **100**. `tools/m4_ship_capture.gd` ~+22/−4; `Makefile` ~+10/−3 (one token in `capture-m4`, the publish recipe); `tools/test_m4_publish.sh` ~+50/−12 (given in full in W4, prototyped green); the M4.6rR3 report, 1 paragraph. The drills live in this doc.
**Evidence:** the Verification log at the end, run first-hand in `/Users/voightkampff/dev/sunholo-data/.stap-iter66-src` at `68796623` (origin/main) on 2026-11-03. Ten GPU runs: two through `make capture-m4` as it is, three with `--fixed-fps 60`, two instrumented, one with the W1 guard and settle compiled in, and two refused runs. Every temporary edit was reverted. W3 and W4 were prototyped in a private copy of `Makefile`, `mk/` and the script: green through make and gmake; RED and all ten publish drills measured (V26, V27).

## Game vision alignment

Scored against [core pillars](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md).

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | The capture issues the same console inputs as today. |
| The Game Doesn't Judge | 0 | 0 | No player-facing copy. |
| Time Has Emotional Weight | 0 | 0 | Sim clocks and journey timing untouched; worlds stay byte-equal (V6). |
| The Ship Is Home | 0 | 0 | The arrival card is shot after its fade-in completes, as in the set Mark has seen; nothing in play changes. |
| Grounded Strangeness | 0 | 0 | No world or visual change in play. `--fixed-fps` is on the capture command line only. |
| We Are Not Built For This | 0 | 0 | No crew or consequence change. |
| Hard sci-fi authenticity (spec) | 0 | 0 | Physics visuals unchanged; only the wall-clock jitter in *when* the capture shoots each frame is removed. |
| **Net** | | **0** | **Go under D-88 A:** S1 evidence hygiene inside the D-66-approved sprint; no pillar is negative. The re-captured set then **parks** for Mark's S1 render review (his sign-off is the gate, not this doc). |

## Problem

Each premise was re-measured at `68796623`; the V-numbers are rows of the Verification log.

1. **The public S1 set no longer matches a fresh capture, and that is expected.** A fresh `make capture-m4` matches the public `refs/m4_ship_s1/` set in **0 of 14** world hashes and **0 of 15** PNG hashes (V4), with identical file names. The worlds changed for real reasons, not noise: the public set was captured at protocol 2.9 and the tree now speaks 2.16 (V5); the journey geometry moved at the 1e-7 level (the Alpha Centauri leg is 4.321052935 ly in the public set and 4.321053396 ly now, after R3-EARTH-LINK made home the Solar System, `002a68d4`), and the home leg arrives at tick 2437, not 2435. The camera poses also changed: the public deck view is tilt 30°, yaw 0.47 rad; today's is 20°, −2.58 rad (D-92, `fb5607bd`, 2026-10-19). Mark's reviewed set (2026-10-16) therefore shows a ship that no longer exists. The fix is a re-capture, not a repair.
2. **The PNGs are not reproducible.** Two `make capture-m4` runs on one tree give a byte-equal `worlds.sha256` and a `manifest.json` equal except `wall_s`, but **0 of 15** equal PNGs (V6). Per image the difference is up to 11.6 % of pixels and up to 94/255 in one channel (V7).
3. **Root cause: the capture runs in real time.** The demo advances every presentation animation by the engine's frame `delta` (`demos/ship_geometry_demo.gd:476–544`). The capture waits a fixed number of *frames* (`tools/m4_ship_capture.gd:145`, 60 at docked; `:172`, 6 per shot), and on a shared rig the wall time per frame varies (load 10 to 190 during these runs, V3). So the animation time at each shot varies. These are the delta-driven terms on the frame path:
   - dust flashes: `interior/interior_sky.gd:249` (`dust_clock += delta`), against a 0.2 s decay and a 1.2 s life (`interior/dust_flash.gd:32–35`);
   - HUD card fades: `ui/ship_hud.gd:26–27` (0.4 s in, 0.6 s out) and `:477–491` (`advance(dt)`), called from the demo at `:1322`;
   - the star light's easing: `demos/ship_star_light.gd:50` (`TAU_S := 0.5`) and `:252` (`1 − exp(−delta/TAU_S)`), called at demo `:536`; the ship rig dims as the star light takes over (`demos/ship_lighting.gd:4`);
   - the captain's animation clock: `interior/captain_anim.gd:106, 144`. At every shot the captain is in `idle` at the same position (V12), so this one was not seen to differ.
4. **Why the docked frames differ (the row's open trace).** The iteration-36 evaluation saw the docked frames match. Now they differ by exactly 1/255 on 2.3–3.9 % of pixels (V7). The diff mask (V11) covers only the lit ship geometry (deck, rail, consoles, captain). The sky and the HUD are untouched. Instrumented, two real-time runs reached the docked deck shot at process frame 135 and 136, with the Sun's StarLight energy at **7059.47** and **6891.67**. It was still easing between the deck and forward shots (7567.12 and 7471.92). The fill, practical and spire rig energies differed with it (V12). **Cause: the docked shot lands mid-ease of the near star's light (`ship_star_light.gd:252`), at a wall-time-dependent point.** Why this did not show at iteration 36 was not traced: StarLight and its easing date from 2026-10-07 (`4692df21`), before iteration 36. The bridge styling pass of 2026-10-22 (D-97: a near star keys the bridge) is the likely reason the residual now crosses a rounding step. That is inference, not measurement, and the fix below removes the cause either way.
5. **The publish would overwrite the reviewed set.** `capture-m4-publish` uploads every file to the flat `gs://stapledons-voyage-assets/refs/m4_ship_s1/<name>` (`Makefile:340`, V14). The public set is those 18 flat objects; no dated sub-path exists (V2). Running it today would replace what Mark reviewed.

**Brief premises re-checked.** The inherited "0 of 14 / 15 of 15" figures hold at `68796623` (V4, V6). Open PRs #371, #373, #379 and #380 touch `Makefile`, but no hunk is within the `capture-m4` or `capture-m4-publish` recipes (lines 322–344). #373's only `capture-m4` mention is the `.PHONY` context line. None touches `tools/m4_ship_capture.gd`, `tools/test_m4_publish.sh` or the M4.6rR3 report (V15). The brief's "#370 is the current bookkeeping issue" holds (V16).

## Goals and non-goals

**Goals.** (1) Make `make capture-m4` byte-reproducible on the rig (Option A below), with a guard that refuses a non-fixed frame step. (2) Make `capture-m4-publish` upload only to a new dated path and only by creating objects (`--if-generation-match=0`, so no object can ever be overwritten). It refuses to run without a valid date, and refuses a destination that already lists objects. The 7l(a) 18-file checks stay intact. (3) Extend `tools/test_m4_publish.sh` so a test kills each new guard. (4) Give the controller an exact post-landing checklist: capture, verify, publish, comment, park.
**Non-goals.** No change to `demos/*`, `ui/*`, `interior/*`, `sky/*`, shaders or the sim. No change to what a player sees: `--fixed-fps` is a command-line flag on the capture recipe only. No upload by the executor (the controller publishes after landing). No overwrite or deletion of the flat reviewed set. No cross-machine pixel identity: the claim is the same rig, GPU and driver (the manifest records the adapter). No pinning of other GPU capture targets.

## Decision: Option A, byte-reproducible capture

**A (chosen): run the capture with a fixed frame step.** Godot's `--fixed-fps 60` makes every process `delta` exactly 1/60 s, whatever the wall time (V8: the probe reads `0.01666666666667`, `== 1.0/60.0` true; without the flag it reads 0.0147, 0.0057, 0.0125). Every animation term in Problem 3 then advances by the same amount between the same frames, on every run. Measured: two `--fixed-fps 60` captures give **15 of 15** byte-equal PNGs, a 0-pixel diff on every image, and the same `worlds.sha256` as the real-time runs (V9), at loads of 75.8→20.0 and 19.0→13.7. The tree already uses this flag for its movie capture (`mk/ai.mk:566`, V13).

**Why not B (a bounded pixel tolerance).** The real-time differences are not small or bounded. They reach 143/255 in one channel and 38 % of pixels between a real-time and a fixed run, and 94/255 between two real-time runs (V7, V10), because whole card fades and flash populations change. Any tolerance loose enough to pass them would also pass a real regression. A is a one-token recipe change plus a guard, and it touches no player-visible behaviour, so the brief's preference for A applies.

**What A changes in the S1 pictures (flagged).** Captured pixels change relative to today's real-time capture: mean 0.07–1.76/255, max up to 143/255 (V10). The arrived frames and the cruise cards change most. No pixel changes in normal play. This is why the set must go to Mark for review, which the row already requires. Two capture-path consequences are designed for:
- **The arrival card is shot fully faded in.** With a 6-frame wait at 1/60 s, the arrived shots came 0.1 s after the pose change and the card was still fading in, visibly faint (V9 contact sheet). Today's real-time capture shot it after the full fade by accident of slow frames. A fixed `ARRIVED_SETTLE_FRAMES := 30` (0.5 s, past `FADE_IN_S` 0.4) before the arrived shots restores the fully-shown card (V17, opened and checked). The rest states have no dust and nothing moving, so the extra wait shows only the settled card. Frames 01–05 are byte-identical with and without it (V17).
- **Moving states keep 6 frames.** The dust flashes are shot at a fixed age: 6 frames (0.1 s) after the pose change for the deck view, 12 (0.2 s) for the forward view, against τ = 0.2 s. They stay visible and identical run to run.
- **Wall-clock bounds become frame bounds.** The walk to the helm (`tools/m4_ship_capture.gd:86–91`) and the dolly wait (`:136–139`) are bounded by 30 s of wall time. Under a fixed step they take a fixed number of frames, so a slow rig (fewer than 30 rendered frames per wall second) would fail them spuriously. They become `WALK_FRAMES_MAX := 1800` (30 s of fixed game time). A 300 s wall-clock hang guard stays.

## Design

### W1. `tools/m4_ship_capture.gd` (the capture)

Edits, anchored on text, not line numbers:

1. Constants, after `const CRUISE_BETA_TOL …`:
   ```gdscript
   const CAPTURE_FPS := 60 # make capture-m4 runs Godot with --fixed-fps 60 (row 7w): every delta is exactly 1/60 s
   const ARRIVED_SETTLE_FRAMES := 30 # 0.5 s at rest before the arrived shots: past the HUD's 0.4 s card fade-in
   const WALK_FRAMES_MAX := 1800 # 30 s of fixed game time for the walk and the dolly; 300 s of wall time is the hang guard
   ```
2. In `_run`, directly after the two cruise-tolerance self-test lines (before the output-directory check):
   ```gdscript
   	await process_frame
   	var step := root.get_process_delta_time()
   	_check(step == 1.0 / CAPTURE_FPS, "process delta %s s is not 1/%d s: run it as make capture-m4 (godot --fixed-fps %d)" % [str(step), CAPTURE_FPS, CAPTURE_FPS])
   ```
   The existing gate `if failures: _finish(); return` (now just below the stale-file cleanup) stops the run before the demo loads, so a refused run renders **0 frames**. Measured with the guard compiled in (V23): without the flag Godot exits **1** in 2 s, printing `FAIL process delta 0.142168 s is not 1/60 s: …`; with `--fixed-fps 30` it also exits 1, printing `0.025 s`. As with today's CC self-test, the stale-file cleanup still runs first, so a refused run leaves `renders/m4/` empty.
3. `_helm`: replace the wall-clock loop with
   ```gdscript
   	var wall := Time.get_ticks_msec() + 300000
   	var frames := 0
   	while frames < WALK_FRAMES_MAX and Time.get_ticks_msec() < wall:
   		if demo.consoles.walking.is_empty():
   			print("capture-m4: walk %d frames" % frames)
   			return true
   		frames += 1
   		await process_frame
   	return _check(false, "walk to navigation exceeded %d frames or 300 s" % WALK_FRAMES_MAX)
   ```
   Update the comment above it: the walk is bounded in fixed frames.
4. `_views`, dolly wait: the same shape (`frames < WALK_FRAMES_MAX and` the 300 s wall guard). The failure text `console dolly did not finish` is unchanged.
5. `_views`, after the docked settle block, add
   ```gdscript
   	elif state.begins_with("arrived"):
   		for i in ARRIVED_SETTLE_FRAMES:
   			await process_frame
   		_check(_card_alpha("arrival") == 1.0, "arrival card alpha %s at %s (want 1, after %d frames)" % [str(_card_alpha("arrival")), state, ARRIVED_SETTLE_FRAMES])
   ```
   and a helper beside `_near`:
   ```gdscript
   func _card_alpha(id: String) -> float:
   	return float(demo.ship_hud.cards[id].panel.modulate.a) if demo.ship_hud.cards.has(id) else -1.0
   ```
   `cards` is the HUD's public dictionary (`ui/ship_hud.gd:52`). The fade-in is a linear clamp, `clampf((now_s - c.born) / FADE_IN_S, 0.0, 1.0)` at `:491` with `FADE_IN_S := 0.4` (`:26`), so exactly `1.0` is reachable and the strict `== 1.0` is sound (V21). Measured with these lines compiled in (V22): the alpha is already `1.0` at frame 24 and at frame 30 for both arrived states; the run printed 14 frames, `capture-m4: OK`, rc 0. Nothing in `ui/` is edited.

### W2. `Makefile`, `capture-m4`: one token

In the `capture-m4` recipe, `$(GODOT_SIM) --path . --script tools/m4_ship_capture.gd` becomes `$(GODOT_SIM) --path . --fixed-fps 60 --script tools/m4_ship_capture.gd`. Nothing else in that recipe changes. The interior-set comment in its `##` help (`godot --path . -- --interior-capture=DIR`) is not this driver and stays.

### W3. `Makefile`, `capture-m4-publish`: a required date, a new path, create-only uploads

Replace the block from `M4_PUBLISH_DIR := renders/m4` to `.PHONY: capture-m4-publish capture-m4-publish-test` with exactly this. It was prototyped byte for byte in a private copy, where the publish test is green through both makes (V26).

```make
M4_PUBLISH_DIR := renders/m4
M4_PUBLISH_DATE :=
test: capture-m4-publish-test
capture-m4-publish: ## maintainers (gcloud): check the date and all 18 files of the 3D-ship S1 set, then create them (create-only) under a NEW dated path refs/m4_ship_s1/<date>/ (M4_PUBLISH_DATE=YYYY-MM-DD required; never the reviewed flat set)
	@set -eu; d='$(M4_PUBLISH_DIR)'; day='$(M4_PUBLISH_DATE)'; \
	  case "$$day" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) echo "capture-m4-publish: FAILED before any upload: M4_PUBLISH_DATE=YYYY-MM-DD is required on the command line (got '$$day')"; exit 1 ;; esac; \
	  dest="gs://stapledons-voyage-assets/refs/m4_ship_s1/$$day/"; \
	  set -- "$$d"/*.png "$$d/manifest.json" "$$d/m4_manifest.sha256" "$$d/worlds.sha256"; \
	  for f; do test -s "$$f" || { echo "capture-m4-publish: FAILED before any upload: $$f missing or empty"; exit 1; }; done; \
	  test $$# = 18 && test "$$(ls "$$d"/*.png | wc -l | tr -d ' ')" = 15 && \
	  test "$$(wc -l < "$$d/m4_manifest.sha256" | tr -d ' ')" = 15 && \
	  test "$$(cut -d' ' -f1 "$$d/m4_manifest.sha256" | sort -u | wc -l | tr -d ' ')" = 15 && \
	  test "$$(wc -l < "$$d/worlds.sha256" | tr -d ' ')" = 14 && \
	  (cd "$$d" && shasum -a 256 -c m4_manifest.sha256 > /dev/null) || { echo "capture-m4-publish: FAILED before any upload: a count or m4_manifest.sha256 check"; exit 1; }; \
	  lrc=0; out=$$(gcloud storage ls "$$dest" 2>&1) || lrc=$$?; \
	  if test $$lrc = 0; then echo "capture-m4-publish: FAILED before any upload: $$dest already holds $$(printf '%s\n' "$$out" | grep -c .) objects"; exit 1; fi; \
	  case "$$out" in *'One or more URLs matched no objects'*) ;; *) echo "capture-m4-publish: FAILED before any upload: cannot prove $$dest is empty (gcloud storage ls exit $$lrc)"; exit 1 ;; esac; \
	  n=0; for f; do gcloud storage cp --if-generation-match=0 --cache-control="public, max-age=300" "$$f" "$$dest$${f##*/}" > /dev/null || { echo "capture-m4-publish: FAILED after $$n uploads: $${f##*/} not created at $$dest (create-only precondition or gcloud error); this dated set is now partial"; exit 1; }; n=$$((n+1)); done; \
	  test $$n = 18; echo "capture-m4-publish: uploaded 18 files to $$dest"
capture-m4-publish-test: ## rows 7l(a), 7w: the publish checks its date, all 18 files and an empty dated destination before its first upload, and only creates objects (private fixture, fake gcloud, every GNU make on PATH; never uploads)
	@sh tools/test_m4_publish.sh "$(CURDIR)"
.PHONY: capture-m4-publish capture-m4-publish-test
```

- **The safety mechanism is create-only, per object.** Every `cp` carries `--if-generation-match=0`. GCS then writes the object only if no live object has that name, and otherwise fails with a 412 precondition error (Google Cloud SDK 583.0.0 `gcloud storage cp --help`: "Execute only if the generation matches the generation of the requested object", V25; generation 0 means "does not exist"). No run of this recipe can overwrite any object, dated or flat, whatever the listing said or whatever happened between the listing and the copy. A refused copy stops the loop at once and names the file and the count so far (`FAILED after <n> uploads: <name> not created at <dest> …; this dated set is now partial`). The run never reaches `uploaded 18 files`.
- **The listing is a diagnostic, not the safety.** `gcloud storage ls` on the dated prefix catches the common mistake, a date that has already been used, before any upload, so no partial set is created. On an empty prefix it exits 1 with `ERROR: (gcloud.storage.ls) One or more URLs matched no objects.`; on a populated one it exits 0 and lists them (V18). Any other failure (auth, network) is refused as "cannot prove … empty", not taken as empty.
- **Order.** The date comes first, then the 7l(a) local checks, then the listing, then the create-only uploads. A local defect makes **no** `gcloud` call; a destination defect makes exactly one, the listing.
- **The date is required and strict.** It must be on the command line, with no default. `:=` (not `?=`) means an exported `M4_PUBLISH_DATE` in a maintainer's shell is ignored, the 7l(a) reasoning for `M4_PUBLISH_DIR`. The shape `NNNN-NN-NN` rules out an empty date (which would give `refs/m4_ship_s1//`), path segments and spaces. It is not a calendar check; the controller passes `$(date -u +%F)`.
- **No reservation object (decided).** A reservation (create-only `refs/m4_ship_s1/<date>.lock` before the first PNG) would also stop two publishers interleaving one dated set. It is not adopted, for four reasons:
  - Create-only on every object already makes any overwrite impossible, and that is the row's requirement.
  - The recipe is maintainer-only, and the loop's controller runs one iteration at a time (`~/.ailang/state/mission-stapledon.pid`).
  - Interleaving two sets would need two simultaneous publishes for the same day. That is detected anyway: the loser stops at its first collision with `FAILED after <n> uploads`, and C7 below downloads the whole dated set and checks it against the local hashes, so a mixed set cannot be announced.
  - A lock would add a permanent extra public object per publish, and a lock that outlived a crashed run would need its own manual clean-up.
- **Unchanged from 7l(a):** the presence-loop line, the five count and hash lines, the upload-loop prefix `n=0; for f; do gcloud storage cp `, `test $$n = 18`, the `@set -eu; d=` opening and the `test:` line. The 7l(a) drills anchor on these, and all of them still apply (V27).
- **A partial set** (a gcloud error mid-loop, or the 412) stays partial: a re-run with the same date is refused by the listing. The controller then uses the next date (or removes that dated prefix by hand) and re-publishes. The flat set can never be touched.

### W4. `tools/test_m4_publish.sh`: six new cases, 13 in all

The script below replaces the 7l(a) script. It was prototyped verbatim: `OK (13 cases on 2 makes: GNU Make 3.81, GNU Make 4.4.1)` through both make and gmake, in 6 s (V26). The header (its comment now names row 7w), the `deadline` copy and the constants are the 7l(a) lines. The make discovery, the fixture and the `deadline`/INFRASTRUCTURE handling are byte-identical.

**How it counts with ONE generic log line per call.** The 7l(a) stub logs every invocation the same way, all arguments `|`-separated, from one line (`tools/test_m4_publish.sh:36`, V24). That line is kept verbatim as the stub's first body line. The behaviour branches below it write nothing to the log, only to stdout or stderr and the exit code. So a listing logs as `storage|ls|<dest>|`, and a copy as `storage|cp|--if-generation-match=0|--cache-control=public, max-age=300|<src>|<dest>|` (7 fields). The counts filter by the second field:
- `all`: every call, `wc -l`;
- `n`: copy attempts, `grep -c '^storage|cp|'` (a refused copy is still an attempt);
- `lists`: `grep -c '^storage|ls|'`;
- `lsok`: exactly the listing of the dated prefix, `grep -cxF "storage|ls|$B|"`;
- `good`: well-formed copies, the 7l(a) awk moved to `NF == 7` with `$3 == "--if-generation-match=0"`;
- `uniq`: distinct copy destinations, `grep '^storage|cp|' | cut -d'|' -f6 | sort -u`.

So the listing line never inflates `n`, `good` or `uniq`, and `complete` expects `all` = 19 (1 listing + 18 copies).

**The stub's three behaviours.**

| Call | Setting | stdout / stderr | exit |
|---|---|---|---|
| `storage ls <url>` | `FAKE_LS=empty` (default) | stderr `ERROR: (gcloud.storage.ls) One or more URLs matched no objects.` | 1 |
| | `FAKE_LS=nonempty` | stdout `<url>x.png` | 0 |
| | `FAKE_LS=error` | stderr `ERROR: (gcloud.storage.ls) HTTPError 403: forbidden` | 1 |
| `storage cp …` | `$3` is `--if-generation-match=0` and the destination's basename equals `FAKE_EXISTS` | stderr `ERROR: (gcloud.storage.cp) HTTPError 412: At least one of the pre-conditions you specified did not hold.` | 1 |
| | otherwise | nothing | 0 |

The copy refuses only when the precondition flag is present, as real GCS does. Dropping the flag therefore lets the "existing" object be overwritten, and the `nogen` drill sees that.

**Cases** (fixture as in 7l(a); `M4_PUBLISH_DATE=2026-11-03` on the command line unless noted):

| Case | Setting | Must see |
|---|---|---|
| `complete` | — | rc 0; `n` 18, `good` 18, `uniq` 18, `all` 19, `lsok` 1; `uploaded 18 files to <dated dest>` once |
| `worlds-missing`, `worlds-empty`, `worlds-short`, `manifest-missing`, `png-missing`, `hash-mismatch` | the 7l(a) fixture defects | rc ≠ 0; `all` 0 (no gcloud call at all); one `FAILED before any upload:` line |
| `date-missing` | no `M4_PUBLISH_DATE` | the same as the row above |
| `date-malformed` | `M4_PUBLISH_DATE=2026-11-3` | the same |
| `date-env` | the date only in the environment | the same (`:=` ignores it) |
| `dest-nonempty` | `FAKE_LS=nonempty` | rc ≠ 0; `n` 0, `all` 1, `lsok` 1; one `FAILED before any upload:` |
| `ls-error` | `FAKE_LS=error` | the same |
| `exists-at-cp` | `FAKE_LS=empty`, `FAKE_EXISTS=05_brake_b05_deck.png` (the listing was empty, but the object exists at copy time) | rc ≠ 0; `n` 9 (8 created, the 9th refused), `all` 10, `lsok` 1; 0 `FAILED before any upload:` lines; exactly one `FAILED after 8 uploads: 05_brake_b05_deck.png not created at <dated dest> (create-only precondition or gcloud error); this dated set is now partial`; no `uploaded 18 files` |

```sh
#!/bin/sh
# Rows 7l(a) and 7w: capture-m4-publish checks its date, all 18 files and an empty dated destination
# before its first upload, and only ever creates objects (--if-generation-match=0).
# Runs the real recipe through every distinct GNU make on PATH against a private fixture
# (M4_PUBLISH_DIR=...), with a fake gcloud that only logs. PATH is narrowed to the fake plus
# /usr/bin:/bin, so no real gcloud is reachable and nothing is ever uploaded.
set -u
# Under `make test` the outer make's flags would reach the fixture makes (iteration 56).
unset MAKELEVEL MAKEFLAGS MFLAGS MAKEOVERRIDES GNUMAKEFLAGS MAKE_TERMOUT MAKE_TERMERR
ROOT=${1:?usage: test_m4_publish.sh ROOT}
cd "$ROOT" || exit 1
ROOT=$(pwd -P)
T=$(mktemp -d "${TMPDIR:-/tmp}/m4-publish-test.XXXXXX") || exit 1
trap 'rm -rf "$T"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
# Every make runs under the 7l drills' deadline (doc body), plus one line: a TERM, INT or HUP to this
# script's group is forwarded as KILL to the child's own group, which the outer signal cannot reach.
# 124 is INFRASTRUCTURE, never a case result.
deadline() { # deadline SECONDS CMD...: CMD's rc; 124 on expiry (TERM to its process group, KILL 5 s later)
  perl -e '
    my $s = shift; my $pid = fork; exit 125 unless defined $pid;
    if ($pid == 0) { setpgrp(0, 0); exec @ARGV; exit 127 }
    setpgrp($pid, $pid); my $hit = 0;
    $SIG{$_} = sub { kill "KILL", -$pid; exit 124 } for qw(TERM INT HUP);
    $SIG{ALRM} = sub { kill(($hit++ ? "KILL" : "TERM"), -$pid); alarm 5 };
    alarm $s; waitpid($pid, 0); my $rc = $?; alarm 0;
    exit($rc & 127 ? 128 + ($rc & 127) : $rc >> 8) unless $hit;
    my $t = time + 5; select(undef, undef, undef, 0.2) while kill(0, -$pid) && time < $t;
    kill "KILL", -$pid; exit 124;' "$@" < /dev/null
}
PROBE_S=10 MAKE_S=20
infra() { echo "capture-m4-publish-test: INFRASTRUCTURE timeout after $1 s: $2"; exit 124; }
mkdir "$T/bin" "$T/fx" || exit 1
# One generic log line per call (every argument, |-separated), then the behaviour: `storage ls` answers
# by FAKE_LS (empty: exit 1 "matched no objects"; nonempty: one object, exit 0; error: exit 1, a 403);
# `storage cp` refuses (exit 1, a 412) only when it carries --if-generation-match=0 and its object's
# name is FAKE_EXISTS, the way GCS refuses a create-only write onto an existing object.
cat > "$T/bin/gcloud" <<STUB || exit 1
#!/bin/sh
for a in "\$@"; do printf '%s|' "\$a"; done >> "$T/log"; printf '\n' >> "$T/log"
case "\$1 \$2" in
  "storage ls")
    case "\${FAKE_LS:-empty}" in
      nonempty) printf '%sx.png\n' "\$3"; exit 0 ;;
      error) echo "ERROR: (gcloud.storage.ls) HTTPError 403: forbidden" >&2; exit 1 ;;
      *) echo "ERROR: (gcloud.storage.ls) One or more URLs matched no objects." >&2; exit 1 ;;
    esac ;;
  "storage cp")
    if [ -n "\${FAKE_EXISTS:-}" ] && [ "\$3" = "--if-generation-match=0" ] && [ "\${6##*/}" = "\$FAKE_EXISTS" ]; then
      echo "ERROR: (gcloud.storage.cp) HTTPError 412: At least one of the pre-conditions you specified did not hold." >&2; exit 1
    fi ;;
esac
exit 0
STUB
chmod +x "$T/bin/gcloud" || exit 1
NP=$T/bin:/usr/bin:/bin
D=2026-11-03
B=gs://stapledons-voyage-assets/refs/m4_ship_s1/$D/
if [ "$(PATH=$NP command -v gcloud)" != "$T/bin/gcloud" ]; then echo "capture-m4-publish-test: FAIL the fake gcloud is not first on PATH"; exit 1; fi
makes=; versions=; nm=0
for candidate in make gmake; do
  path=$(command -v "$candidate" 2>/dev/null) || continue
  prc=0; deadline "$PROBE_S" "$path" --version > "$T/version" 2>/dev/null || prc=$?
  if [ "$prc" = 124 ]; then infra "$PROBE_S" "$path --version"; fi
  version=$(sed -n '1p' "$T/version")
  case "$version" in 'GNU Make '*) ;; *) continue ;; esac
  if printf '%s\n' "$versions" | grep -Fqx "$version"; then continue; fi
  makes="$makes $path"; versions="${versions}${version}
"; nm=$((nm + 1))
done
if [ "$nm" = 0 ]; then echo "capture-m4-publish-test: FAIL no GNU make on PATH"; exit 1; fi
fixture() {
  rm -rf "$T/fx" && mkdir "$T/fx" || return 1
  for s in 01_docked 02_boost_b05 03_boost_b09 04_cruise_099 05_brake_b05 06_arrived_acen 07_arrived_home; do
    for v in deck forward; do printf 'png %s_%s\n' "$s" "$v" > "$T/fx/${s}_$v.png" || return 1; done
  done
  printf 'png contact_sheet\n' > "$T/fx/contact_sheet.png" &&
  (cd "$T/fx" && shasum -a 256 ./*.png | sed 's|  \./|  |' > m4_manifest.sha256) &&
  for f in "$T"/fx/0*.png; do printf '%064d  %s\n' 0 "${f##*/}"; done > "$T/fx/worlds.sha256" &&
  printf '{"frames": []}\n' > "$T/fx/manifest.json"
}
CASES="complete worlds-missing worlds-empty worlds-short manifest-missing png-missing hash-mismatch date-missing date-malformed date-env dest-nonempty ls-error exists-at-cp"
NC=13
fails=0; i=0
for M in $makes; do
  i=$((i + 1)); version=$(printf '%s' "$versions" | sed -n "${i}p")
  for c in $CASES; do
    fixture || { echo "capture-m4-publish-test: FAIL fixture"; exit 1; }
    dated="M4_PUBLISH_DATE=$D"; envdate=; ls=empty; exists=
    case "$c" in
      worlds-missing) rm "$T/fx/worlds.sha256" ;;
      worlds-empty) : > "$T/fx/worlds.sha256" ;;
      worlds-short) sed '$d' "$T/fx/worlds.sha256" > "$T/w13" && mv "$T/w13" "$T/fx/worlds.sha256" ;;
      manifest-missing) rm "$T/fx/manifest.json" ;;
      png-missing) rm "$T/fx/05_brake_b05_deck.png" ;;
      hash-mismatch) printf 'png 05_brake_b05_dexk\n' > "$T/fx/05_brake_b05_deck.png" ;;
      date-missing) dated= ;;
      date-malformed) dated=M4_PUBLISH_DATE=2026-11-3 ;;
      date-env) dated=; envdate=$D ;;
      dest-nonempty) ls=nonempty ;;
      ls-error) ls=error ;;
      exists-at-cp) exists=05_brake_b05_deck.png ;;
    esac || { echo "capture-m4-publish-test: FAIL fixture $c"; exit 1; }
    : > "$T/log" || exit 1
    rc=0; deadline "$MAKE_S" env PATH="$NP" FAKE_LS="$ls" FAKE_EXISTS="$exists" ${envdate:+M4_PUBLISH_DATE="$envdate"} "$M" -s -C "$ROOT" capture-m4-publish M4_PUBLISH_DIR="$T/fx" ${dated:+"$dated"} > "$T/out" 2>&1 || rc=$?
    if [ "$rc" = 124 ]; then sed 's/^/  | /' "$T/out"; infra "$MAKE_S" "make for case $c ($version)"; fi
    all=$(wc -l < "$T/log" | tr -d ' ')
    n=$(grep -c '^storage|cp|' "$T/log")
    lists=$(grep -c '^storage|ls|' "$T/log")
    lsok=$(grep -cxF "storage|ls|$B|" "$T/log")
    good=$(awk -F'|' -v fx="$T/fx/" -v b="$B" 'NF == 7 && $1 == "storage" && $2 == "cp" && $3 == "--if-generation-match=0" && $4 == "--cache-control=public, max-age=300" && index($5, fx) == 1 && index($6, b) == 1 && $7 == "" && substr($5, length(fx) + 1) == substr($6, length(b) + 1) {k++} END {print k + 0}' "$T/log")
    uniq=$(grep '^storage|cp|' "$T/log" | cut -d'|' -f6 | sort -u | grep -c .)
    pre=$(grep -c '^capture-m4-publish: FAILED before any upload: ' "$T/out")
    late=$(grep -cxF "capture-m4-publish: FAILED after 8 uploads: 05_brake_b05_deck.png not created at $B (create-only precondition or gcloud error); this dated set is now partial" "$T/out")
    said=$(grep -cxF "capture-m4-publish: uploaded 18 files to $B" "$T/out")
    ok=0
    case "$c" in
      complete) test "$rc" = 0 && test "$n" = 18 && test "$good" = 18 && test "$uniq" = 18 && test "$all" = 19 && test "$said" = 1 && test "$lsok" = 1 && ok=1 ;;
      dest-nonempty|ls-error) test "$rc" != 0 && test "$n" = 0 && test "$all" = 1 && test "$lsok" = 1 && test "$pre" = 1 && test "$said" = 0 && ok=1 ;;
      exists-at-cp) test "$rc" != 0 && test "$n" = 9 && test "$all" = 10 && test "$lsok" = 1 && test "$pre" = 0 && test "$late" = 1 && test "$said" = 0 && ok=1 ;;
      *) test "$rc" != 0 && test "$all" = 0 && test "$pre" = 1 && test "$said" = 0 && ok=1 ;;
    esac
    if [ "$ok" = 1 ]; then echo "capture-m4-publish-test: ok $c ($version)"
    else fails=$((fails + 1)); echo "capture-m4-publish-test: FAIL $c ($version): rc $rc, uploads $n, lists $lists, well-formed $good, pre-check lines $pre"; sed 's/^/  | /' "$T/out"; fi
  done
done
if [ "$fails" != 0 ]; then echo "capture-m4-publish-test: FAILED ($fails of $((NC * nm)) cases)"; exit 1; fi
echo "capture-m4-publish-test: OK ($NC cases on $nm makes:$(printf '%s' "$versions" | tr '\n' ',' | sed 's/,$//; s/,/, /g; s/^/ /'))"
```

The `complete` verdict still begins with the 7l(a) text `test "$rc" = 0 && test "$n" = 18 && test "$good" = 18 && test "$uniq" = 18 && ` (the `nopositive` drill's anchor). The FAIL line keeps its prefix `rc <rc>, uploads <n>, ` (the `inloop` drill's anchor). The stub's log write stays one line with exactly two `>> "$T/log"` (the `deadcapture` drill's anchor).

### W5. The M4.6rR3 report

In `design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md`, directly after the paragraph that begins `**Reproducibility (row 7l, iteration 59).**`, insert exactly:

> **Reproducible since row 7w (iteration 66).** `make capture-m4` now runs Godot with `--fixed-fps 60`, so the dust flashes, card fades and the near star's light all advance exactly 1/60 s per frame instead of by wall time; two captures on one tree give byte-equal PNGs on the rig (15 of 15). The docked frames had differed because the docked shot landed partway through the Sun's light easing in. The arrived frames now wait 0.5 s so the arrival card has finished fading in. The set at the flat `refs/m4_ship_s1/` path is the one reviewed on 2026-10-16 and stays unchanged; the re-capture is published to a dated `refs/m4_ship_s1/<YYYY-MM-DD>/` path for Mark's S1 review.

## Drills

Two families. Both have the hardened shape of the 7l drills: an explicit ROOT; one parent `mktemp -d` with the trap right after it; a substitution count that must be exactly 1 (else exit 3) and a `cmp` proof that the file changed (else exit 3); make's or Godot's rc captured; every count asserted with `test`; exit 4 = INFRASTRUCTURE (a 124 from `deadline`, or an unexpected rc), never a kill. `deadline` is the perl wrapper from [m4-7l-capture-followups.md, Drills](m4-7l-capture-followups.md#drills-a-function-in-this-doc-not-a-committed-script), copied verbatim.

### Capture drills (GPU; in the checkout, the trap restores the file)

```sh
cdrill() (  # exit 0 expected outcome, 1 unexpected, 2 usage, 3 mutation not applied, 4 INFRASTRUCTURE
  set -eu
  ROOT=${1:?explicit checkout ROOT}; mutant=${2:?nofixed, fps30 or nosettle}
  cd "$ROOT" || exit 2; ROOT=$(pwd -P); F=tools/m4_ship_capture.gd; test -f "$F" || exit 2
  T=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-7w.XXXXXX") || exit 2
  trap 'if test -f "$T/orig.gd"; then cp "$T/orig.gd" "$ROOT/$F"; fi; rm -rf "$T"' EXIT
  trap 'exit 130' INT; trap 'exit 143' TERM HUP
  cp "$F" "$T/orig.gd" || exit 2
  S=${DRILL_S:-900}; G="godot --path . --script $F"
  case "$mutant" in
    nofixed) ;;                                   # the recipe's flag dropped: no file mutation
    fps30) G="godot --path . --fixed-fps 30 --script $F" ;;
    nosettle) perl -i -pe '$n += s/^const ARRIVED_SETTLE_FRAMES := 30 /const ARRIVED_SETTLE_FRAMES := 0 /; END { exit($n == 1 ? 0 : 3) }' "$F" || exit 3
              if cmp -s "$T/orig.gd" "$F"; then exit 3; fi
              G="godot --path . --fixed-fps 60 --script $F" ;;
    *) exit 2 ;;
  esac
  set +e
  PATH="$ROOT/runtime/bin:$PATH" AILANG_BIN="$ROOT/runtime/bin/ailang" deadline "$S" $G > "$T/log" 2>&1
  rc=$?
  set -e
  echo "cdrill $mutant: godot rc $rc"
  case "$rc" in 1) ;; 0) echo "cdrill $mutant: SURVIVED"; exit 1 ;; *) echo "cdrill $mutant: INFRASTRUCTURE rc $rc"; exit 4 ;; esac
  test "$(grep -c 'SCRIPT ERROR:' "$T/log")" -eq 0 || exit 1
  test "$(grep -c '^capture-m4: FAIL$' "$T/log")" -eq 1 || exit 1
  case "$mutant" in
    nofixed|fps30)
      test "$(grep -cE '^capture-m4: FAIL process delta [0-9.e-]+ s is not 1/60 s: run it as make capture-m4 \(godot --fixed-fps 60\)$' "$T/log")" -eq 1 || exit 1
      test "$(grep -c '^capture-m4: FAIL ' "$T/log")" -eq 1 || exit 1
      test "$(grep -c '^capture-m4: ok frame' "$T/log")" -eq 0 || exit 1 ;;
    nosettle)
      test "$(grep -cE '^capture-m4: FAIL arrival card alpha [0-9.]+ at arrived_acen \(want 1, after 0 frames\)$' "$T/log")" -eq 1 || exit 1
      k=$(grep -c '^capture-m4: FAIL arrival card alpha ' "$T/log"); test "$k" -ge 1 && test "$k" -le 2 || exit 1
      test "$(grep -c '^capture-m4: FAIL ' "$T/log")" -eq "$k" || exit 1
      test "$(grep -c '^capture-m4: ok frame' "$T/log")" -eq 14 || exit 1 ;;
  esac
  echo "cdrill $mutant: expected outcome"
)
```

| Drill | Mutation | Expected |
|---|---|---|
| `nofixed` | run the driver without `--fixed-fps` (what the recipe was before W2) | Godot rc 1 (measured, V23: `FAIL process delta 0.142168 s is not 1/60 s: …`, 2 s); exactly 1 `FAIL process delta … is not 1/60 s`; 0 frames |
| `fps30` | `--fixed-fps 30` | the same, rc 1 (measured, V23: `0.025 s`): the guard checks the step, not just the flag's presence |
| `nosettle` | `ARRIVED_SETTLE_FRAMES` 30 → 0 | rc 1; exactly 1 `FAIL arrival card alpha … at arrived_acen (want 1, after 0 frames)`, and 1 or 2 alpha FAILs in all (arrived_home's card also looked faint in the no-settle run, V9; the executor records the count); 14 frames |
| **predicted survivor** `shot6to7` | the per-shot wait 6 → 7 frames | **survives every in-script check**: still reproducible, just different pixels. It is caught only by comparing against a published reference: the post-landing step C3 re-captures and `cmp`s against the dated set's `m4_manifest.sha256`. Recorded, not run. |

Run order: the capture drills first, then AC4 last, so `renders/m4/` ends as a good set (a refused run empties it, see W1.2).

### Publish drills (headless; on a private copy of `Makefile`, `mk/` and the script, as in 7l(a))

Use the 7l(a) `drill()` function from [m4-7l-capture-followups.md, Addendum Drills](m4-7l-capture-followups.md#drills), with three edits:
1. Its mutant list adds `flat nodate nols lsany envdate nogen`.
2. Its `case "$mutant"` gains the mutations below. Each is a perl substitution or line deletion on `$MK` with an exact count (exit 3 otherwise), as prototyped in V27.
3. Its expectation block takes the per-make outcomes below. N is the number of inner makes, 2 on the rig. The 7l(a) mutants keep their mutations, but their `ok`/FAIL counts change to those below, because there are now 13 cases.

Every row was **measured** on the prototype through `make capture-m4-publish-test` (V27). The gmake outer run matched where it was checked (`flat`).

| Drill | Mutation (count) | Measured per outer make, N = 2 |
|---|---|---|
| RED | the unedited `Makefile` (flat recipe) with the new script | rc 2; ok 12, FAIL 14: `complete` (`rc 0, uploads 18, lists 0`), `date-missing`, `date-malformed`, `date-env`, `dest-nonempty`, `ls-error`, `exists-at-cp` (all `rc 0, uploads 18, lists 0`), on each make; the six 7l(a) defects ok |
| `flat` | `dest=".../refs/m4_ship_s1/$$day/"` → `dest=".../refs/m4_ship_s1/"` (1) | rc 2; ok 18, FAIL 8: `complete` (`rc 0, uploads 18`), `dest-nonempty`, `ls-error` (`rc 2, uploads 0`, `lsok` 0), `exists-at-cp` (`rc 2, uploads 9`) |
| `nodate` | delete the `case "$$day" in [0-9]…` line (1) | rc 2; ok 20, FAIL 6: `date-missing`, `date-malformed`, `date-env`, each `rc 0, uploads 18, lists 1` |
| `nols` | delete the `lrc=0; out=…`, `if test $$lrc = 0; …` and `case "$$out" in …` lines (3) | rc 2; ok 18, FAIL 8: `complete` (`rc 0, uploads 18, lists 0`), `dest-nonempty` and `ls-error` (`rc 0, uploads 18, lists 0`), `exists-at-cp` (`rc 2, uploads 9, lists 0`) |
| `lsany` | `*'One or more URLs matched no objects'*) ;;` → `*) ;;` (1) | rc 2; ok 24, FAIL 2: `ls-error` (`rc 0, uploads 18, lists 1`) |
| `envdate` | `M4_PUBLISH_DATE :=` → `M4_PUBLISH_DATE ?=` (1) | rc 2; ok 24, FAIL 2: `date-env` (`rc 0, uploads 18, lists 1`) |
| `nogen` | `gcloud storage cp --if-generation-match=0 ` → `gcloud storage cp ` (1): the create-only precondition dropped | rc 2; ok 22, FAIL 4: `complete` (well-formed 0), `exists-at-cp` (`rc 0, uploads 18`: the existing object was overwritten) |
| 7l(a) `inloop` | unchanged (its three anchors survive W3 byte for byte) | rc 2; ok 18, FAIL 8: `worlds-missing` and `worlds-empty` (`rc 2, uploads 17`), `worlds-short` (`rc 0, uploads 18`), `manifest-missing` (`rc 2, uploads 15`); `png-missing`, `hash-mismatch` and `ok complete` still ok |
| 7l(a) `noupload` | unchanged (`gcloud storage cp ` → `true storage cp `) | rc 2; ok 22, FAIL 4: `complete` and `exists-at-cp` (`rc 0, uploads 0, lists 1`) |
| 7l(a) `deadcapture` | unchanged: both `>> "$T/log"` in the stub's single generic log line → `>> /dev/null` (count 2). The behaviour branches still run and still set the exit codes; only the log goes dark | rc 2; ok 18, FAIL 8: `complete` (`rc 0, uploads 0`), `dest-nonempty`, `ls-error`, `exists-at-cp` (`rc 2, uploads 0, lists 0`); every no-call case stays ok (`all` 0 is still true) |
| 7l(a) `nopositive` | unchanged (`noupload` plus the four 7l(a) counts dropped from `complete`) | **now killed, no longer the survivor:** rc 2; ok 22, FAIL 4. `complete` still sees `all` 1 ≠ 19, and `exists-at-cp` sees rc 0 and `uploads 0` |
| 7l(a) `stall` | unchanged | as in 7l(a): bounded at ≤ 40 s, one `INFRASTRUCTURE timeout after 20 s: make for case complete` line, no case result. **Not re-run on the prototype**; the executor runs it (AC3) |

**Predicted survivors (publish).**
- `nopositive` is no longer one: `noupload` is now killed independently by two cases, so dropping one case's counts is not enough.
- The remaining gap is by design, and no drill is needed for it: the date check is a shape, not a calendar, so `M4_PUBLISH_DATE=2026-13-45` would publish to `refs/m4_ship_s1/2026-13-45/`. That is harmless (a new, empty, dated path; create-only), and the controller always passes `date -u +%F`.

The executor records RED first (the first row) and puts the counts in the sprint JSON.

## Acceptance criteria

Run from the implementation root on the executor's committed tree: `export PATH="$PWD/runtime/bin:$PATH" A="AILANG=$PWD/runtime/bin/ailang"`. Define `deadline`, `cdrill` and the extended `drill` first. GPU rows (AC4–AC6) need the GPU window. Wrapper status 124, a drill exit 4 or an `INFRASTRUCTURE` line is a rig failure: re-run; it is never a pass. A drill exit 1 on the fixed tree halts the row as a doc bug.

| # | Criterion and command | Expected output |
|---|---|---|
| AC1 | `deadline 400 make -s capture-m4-publish-test > .godot/tmp/7w-m.out 2>&1; echo rc=$?; grep -c '^capture-m4-publish-test: ok ' .godot/tmp/7w-m.out; tail -1 .godot/tmp/7w-m.out` | `rc=0`, `26`, `capture-m4-publish-test: OK (13 cases on 2 makes: GNU Make 3.81, GNU Make 4.4.1)` (prototype: V26) |
| AC2 | the same through `gmake` (`.godot/tmp/7w-g.out`) | `rc=0`, `26`, the same footer |
| AC3 | `for m in flat nodate nols lsany envdate nogen inloop noupload deadcapture nopositive stall; do drill "$PWD" $m; echo "exit=$?"; done` | every line `exit=0`, each with `expected outcome on 2 outer makes` and the per-make ok/FAIL counts of the Publish drills table (all ten measured on the prototype, V27; `stall` as in 7l(a)) |
| AC4 | Reproducibility: `S=$(mktemp -d /tmp/stap-7w-ac4.XXXXXX); deadline 900 make capture-m4 $A > $S/1.out 2>&1; echo rc1=$?; cp -R renders/m4 $S/a; deadline 900 make capture-m4 $A > $S/2.out 2>&1; echo rc2=$?; cmp $S/a/m4_manifest.sha256 renders/m4/m4_manifest.sha256 && echo png-15-of-15; cmp $S/a/worlds.sha256 renders/m4/worlds.sha256 && echo worlds-14-of-14; grep -c '^capture-m4: walk [0-9]* frames$' .godot/tmp/capture-m4.log; sysctl -n vm.loadavg` | `rc1=0`, `rc2=0`, `png-15-of-15`, `worlds-14-of-14`, `1`; the load is recorded beside it |
| AC5 | `for m in nofixed fps30 nosettle; do cdrill "$PWD" $m; echo "exit=$?"; done` (before AC4's final run, or re-run `make capture-m4` after) | `cdrill <m>: godot rc 1`, `cdrill <m>: expected outcome`, `exit=0` for each |
| AC6 | Visual: open `renders/m4/contact_sheet.png` and the two `06_arrived_acen_*.png` | the arrival card is fully opaque in both arrived columns (as in V17); every frame lit, not blank; recorded in the sprint JSON as opened |
| AC7 | `grep -c -- '--path . --fixed-fps 60 --script tools/m4_ship_capture.gd' Makefile; grep -cF 'refs/m4_ship_s1/$${f##*/}' Makefile; grep -c '^M4_PUBLISH_DATE :=$' Makefile; grep -cF 'refs/m4_ship_s1/$$day/' Makefile; grep -cF -- 'gcloud storage cp --if-generation-match=0 --cache-control="public, max-age=300" "$$f" "$$dest$${f##*/}"' Makefile; R=$(awk '/^capture-m4-publish:/,/^\.PHONY: capture-m4-publish/' Makefile); echo "$R" \| grep -c 'gcloud storage cp'; echo "$R" \| grep -c 'gcloud storage cp --if-generation-match=0 '` | `1`, `0` (no flat upload left), `1`, `1`, `1`, `1`, `1` (the recipe's only copy is create-only) |
| AC8 | `awk '/^capture-m4-publish:/,/^\.PHONY: capture-m4-publish/' Makefile \| awk '/case "\$\$day"/ && !a {a=NR} /test -s/ && !t {t=NR} /shasum -a 256 -c/ {s=NR} /gcloud storage ls/ {l=NR} /gcloud storage cp/ {g=NR} END {print (a<t && t<s && s<l && l<g) ? "date-files-ls-then-cp" : "ORDER-BAD"}'` | `date-files-ls-then-cp` |
| AC9 | `git diff origin/main -- demos ui interior sky sim bridge '*.gdshader' \| wc -l; git diff --name-only origin/main \| grep -cvxE 'Makefile\|tools/m4_ship_capture\.gd\|tools/test_m4_publish\.sh\|design_docs/planned/r1/m4-6rr3-ship-renders-bench-report\.md\|design_docs/planned/r1/m4-7w-s1-republish\.md\|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json'; git diff --name-only origin/main \| grep -cxE 'Makefile\|tools/m4_ship_capture\.gd\|tools/test_m4_publish\.sh'` | `0` (no player-visible file), `0` (nothing outside the list), `3` (control: all three code files changed) |
| AC10 | `grep -cF 'Reproducible since row 7w (iteration 66)' design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md` | `1` |
| AC11 | `make uid-guard python-guard lint-precision $A && git diff --check origin/main && echo gates-ok` | `gates-ok` |
| AC12 | `rig/full` on the PR head (`tools/rig_check.sh <PR>`, launched detached), then `grep -c '^capture-m4-publish-test: OK (13 cases on 2 makes' "${TMPDIR:-/tmp}/rig-check/<full head sha>.log"`; the PR's fast tier: `gh run view <run> --log \| grep -c 'capture-m4-publish-test: OK (13 cases on 1 makes'` | `success`, `1`; fast tier `success`, `1` |

## Post-landing: the controller's checklist (not the executor's)

Run in a fresh full clone of the landed `main` (`../stapledons-godot-7w-publish`), never the main checkout, with `export PATH="$PWD/runtime/bin:$PATH"`. The project's standing approval covers publishing to `gs://stapledons-voyage-assets`.

| Step | Command | Expect |
|---|---|---|
| C1 setup | `make runtime deps import sky-assets lens-assets` | rc 0; then `git status --porcelain` empty (delete any `*.translation` the import left) |
| C2 capture | `make capture-m4 && (cd renders/m4 && shasum -a 256 -c m4_manifest.sha256)`; `sysctl -n vm.loadavg` | `capture-m4: OK`, 15 `OK` lines; load recorded |
| C3 reproduce | `cp -R renders/m4 /tmp/7w-c3 && make capture-m4 && cmp /tmp/7w-c3/m4_manifest.sha256 renders/m4/m4_manifest.sha256 && cmp /tmp/7w-c3/worlds.sha256 renders/m4/worlds.sha256 && echo repro` | `repro` (if not, stop: the row is not done) |
| C4 look | open `renders/m4/contact_sheet.png` and all 14 frames | every frame lit and posed as in the design; arrival cards fully shown |
| C5 empty | `D=$(date -u +%F); gcloud storage ls gs://stapledons-voyage-assets/refs/m4_ship_s1/$D/` | `ERROR: (gcloud.storage.ls) One or more URLs matched no objects.` |
| C6 publish | `make capture-m4-publish M4_PUBLISH_DATE=$D` | `capture-m4-publish: uploaded 18 files to gs://stapledons-voyage-assets/refs/m4_ship_s1/$D/`. On `FAILED after <n> uploads: … this dated set is now partial` (a 412 or a gcloud error), do not announce. Take the next date, or remove `refs/m4_ship_s1/$D/` by hand after checking it holds only this run's files, and repeat C5–C6 |
| C7 verify new (whole set, catches any mixing) | `V=$(mktemp -d /tmp/7w-c7.XXXXXX); gcloud storage ls gs://stapledons-voyage-assets/refs/m4_ship_s1/$D/ \| wc -l; gcloud storage cp "gs://stapledons-voyage-assets/refs/m4_ship_s1/$D/*" "$V/"; (cd "$V" && shasum -a 256 -c m4_manifest.sha256 \| grep -c ': OK$'); for f in m4_manifest.sha256 worlds.sha256 manifest.json; do cmp "$V/$f" renders/m4/$f && echo "same $f"; done; curl -sI https://storage.googleapis.com/stapledons-voyage-assets/refs/m4_ship_s1/$D/contact_sheet.png \| head -1` | `18`; `15`; `same m4_manifest.sha256`, `same worlds.sha256`, `same manifest.json`; `HTTP/2 200` |
| C8 verify old kept | `gcloud storage ls -l gs://stapledons-voyage-assets/refs/m4_ship_s1/manifest.json; gcloud storage ls gs://stapledons-voyage-assets/refs/m4_ship_s1/ \| grep -vc '/$'` | still `2026-10-16T20:59:44Z`; `18` flat objects |
| C9 tell Mark | `gh issue comment 370 --body-file <file>` (the week's bookkeeping issue; the charter's "issue #1") with the text below | the comment URL |
| C10 park | record in the mission log and the charter row 7w: `PARKED for Mark's S1 render review: refs/m4_ship_s1/$D/`; the loop takes no S1 action until Mark answers | the row reads PARKED |

**The comment (plain language, pictures first):**

> **New pictures of the first voyage, for your S1 review.** Contact sheet: https://storage.googleapis.com/stapledons-voyage-assets/refs/m4_ship_s1/<D>/contact_sheet.png (the 14 single frames are beside it).
> **What you are looking at:** the captain at the helm of the 3D ship, two views per moment (the deck, and straight ahead over the bow): docked at Earth; speeding up through half and nine-tenths of light speed; cruising at 0.99 c with the forward glow; braking; arrived at Alpha Centauri; arrived home.
> **Why new pictures:** the set you have (16 October) shows the old camera angles and an older simulation; the ship has changed since, so those pictures no longer match the game. They stay where they are. These new ones are also repeatable: the same build now makes exactly the same pictures every time.
> **What your sign-off changes:** approving makes this dated set the S1 evidence for the first journey (bar clause 4). If anything looks wrong, say which frame and what. Until you answer, the loop leaves S1 alone.

## Risks and mitigations

- **Reproducibility is measured on one rig.** The two fixed-step runs were at loads 75.8→20.0 and 19.0→13.7. The real-time pairs that differed ran at 119→190 and at 10–18 (V3, V6, V12), so the real-time difference does not need high load. The fixed-step mechanism does not depend on load: the delta is a constant (V8). AC4 and C3 re-measure it under whatever load they meet, and record it. Another GPU or driver may still differ; the manifest names the adapter, and nothing claims cross-machine identity.
- **The walk length under the fixed step was not measured.** In real time the docked shot came at about process frame 135 (V12). At 60 fixed fps the 19.6 m walk is about 900 frames. `WALK_FRAMES_MAX := 1800` is twice that, and the new `capture-m4: walk N frames` line records the real count (AC4). A count above 1500 is a re-measure, not a pass.
- **The flag is on the command line, not in the script.** Godot consumes `--fixed-fps`, so `OS.get_cmdline_args()` does not show it (V8). The guard therefore checks the delta itself, which also catches a wrong rate (`fps30`).
- **A publish can stop part-way and leave a partial dated set** (a 412 from the create-only precondition, or a gcloud error). It never overwrites anything, and its last line names the count and the file. A re-run on the same date is refused by the listing. C6 says what to do, and C7's whole-set hash check means a partial or mixed set is never announced.
- **The fake `gcloud` models GCS's create-only refusal; it is not GCS.** The real 412 behaviour of `--if-generation-match=0` is documented by `gcloud storage cp --help` (V25), not exercised here: the design never writes to the bucket. The first real exercise is C6, whose C5 listing has shown the prefix empty.
- **A refused capture empties `renders/m4/`.** This is pre-existing (the stale-file cleanup runs before the gate). The drills run before AC4, and C2 always re-captures.
- **Line numbers move with open PRs.** #373 adds lines above the recipe. Anchor every edit on text. Pre-flight: re-run `gh pr list --state open` and `gh pr diff <n> | grep -c 'capture-m4'`, and halt on any hit inside the two recipes.
- **`make import` on a fresh clone** can leave `*.translation` files. The `.gitignore` now covers the known three (V19), but delete any others; never commit them.

## Open questions

None. D-88 A covers this row: S1 evidence hygiene inside an approved sprint, with no pillar below 0. A is chosen on measurement (byte-identical, V9), and B is rejected on measurement (unbounded differences, V7, V10). The only call that belongs to Mark is the S1 render review itself, and C10 parks for it.

## Files

| File | Change |
|---|---|
| `tools/m4_ship_capture.gd` | `CAPTURE_FPS` guard, `ARRIVED_SETTLE_FRAMES` with the arrival-card alpha check, `WALK_FRAMES_MAX` frame bounds and the walk-count line, `_card_alpha`. |
| `Makefile` | `--fixed-fps 60` in `capture-m4`; the `capture-m4-publish` block of W3 (`M4_PUBLISH_DATE`, dated destination, the listing diagnostic, create-only `--if-generation-match=0` uploads). |
| `tools/test_m4_publish.sh` | Replaced by the W4 script: the stub answers `ls` and create-only `cp`, dated `B`, six new cases, counts filtered by call type, 13-case footer. |
| `design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md` | The W5 paragraph. |
| `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` | A dated row-7w note: RED counts, AC outputs, drill results, the walk frame count, the loads. |
| `design_docs/planned/r1/m4-7w-s1-republish.md` | This doc. |

## Verification log

Run at `68796623` on 2026-11-03 (about 10:20–11:50Z), Apple M4 Max (Metal 4.0, Forward+), Godot 4.7.2, AILANG v0.56.1 (`runtime/bin`). Scratch files are outside the clone in `/tmp/stap_iter66_design/`. The pixel-diff and mask tools were throwaway headless Godot scripts (`pxdiff.gd`, `mask.gd`) in a scratch project there; no Python was used. The two instrumented runs used a one-line `print` in `_shot`, reverted with `git checkout`; `git status --porcelain` was empty at the end.

| # | Claim | Command | Result |
|---|---|---|---|
| V1 | Clone at origin/main, clean; tools | `git log --oneline -1; git status --porcelain; ailang --version; godot --version` | `68796623 Merge pull request #374 …`; empty; `AILANG v0.56.1`; `4.7.2.stable.official.ed1daf0bf`. A first capture failed with parse errors (`Starfield`, `GalaxyMap`, `SimBridge` undeclared) until `make deps import` (fresh clone); every later run passed. |
| V2 | The public set is 18 flat objects; no dated sub-path | `gcloud storage ls -l gs://stapledons-voyage-assets/refs/m4_ship_s1/` | 15 PNG, `m4_manifest.sha256`, `manifest.json` (2026-10-16T20:59:44Z), `worlds.sha256`; `TOTAL: 18 objects, 27749093 bytes`; lines ending `/`: `0` |
| V3 | Runs, wall time and load (`sysctl -n vm.loadavg` before→after, 1-min) | `runcap.sh` wrapper: `make capture-m4` (run1, run2), or `godot --path . [--fixed-fps 60] --script tools/m4_ship_capture.gd` (run3–run5), instrumented make (run6, run7) | run1 make, rc 0, 168 s, 119.33→190.23; run2 make, rc 0, 149 s, 191.12→85.96; run3 fixed, rc 0, 123 s, 75.82→20.04; run4 fixed, rc 0, 115 s, 18.99→13.72; run5 fixed + settle 30, rc 0, 112 s, 13.75→11.78; run6 make + probe, rc 0, 118 s, 17.78→12.53; run7 make + probe, rc 0, 93 s, 12.53→10.32. Every run printed 14 `ok frame` lines. 16 cores. |
| V4 | Fresh capture vs public | `join` of `r1/worlds.sha256` / `public/worlds.sha256` and of the two `m4_manifest.sha256` on file name, count equal hashes; `diff` of names | worlds `0 of 14 match`; PNGs `0 of 15 match`; names `same-names` |
| V5 | Why the worlds differ | `jq '.ailang.proto'`, `.frames[i].tick`, `.frames[0].tilt/yaw`, `diff <(jq -S '.frames[0].journey' …)`; `git log -S'const DECK := [20.0, -2.58]'` | public proto minor `9.0`, now `16.0`; ticks `[…,2435,2435]` vs `[…,2437,2437]`; deck pose public tilt `30.0` yaw `0.47`, now `20.0` / `-2.58` (`fb5607bd`, 2026-10-19); `distance 4.321052935077453` vs `4.321053395631021`; `ship` equal in 2/14 frames, `journey` in 0/14; `git log --since=2026-10-16T20:00 -- sim/*.ail data/starmap` lists `002a68d4 … home is the Solar System` among its first 15 lines |
| V6 | Real time: worlds reproducible, PNGs not | `cmp r1/worlds.sha256 run2/worlds.sha256`; PNG join; `cmp <(jq -S 'del(.wall_s)' r1/manifest.json) <(… run2 …)`; the same for run6/run7 | `worlds-byte-equal`; `png equal 0 of 15`; `manifest-equal-except-wall_s`. run6 vs run7: `png equal 0 of 15`, `worlds-equal` |
| V7 | How different (real time vs real time) | `godot --headless --path gdproj --script pxdiff.gd -- r1 run2` (per image: differing pixels, max channel diff, mean over all channels); control `-- r1 r1` | control: `diffpx 0 … max 0` on every image. run1 vs run2: docked deck 3.86 % max **1**; docked forward 2.29 % max **1**; boost_b05 1.88 %/1.16 % max 94/93; boost_b09 0.11 %/0.29 % max 82/84; cruise deck 5.42 % max 80, forward 0.06 % max 52; brake 1.85 %/1.56 % max 15/51; arrived_acen 11.55 %/6.10 % max 56/57; arrived_home 2.46 %/1.99 % max 62/65; sheet 4.05 % max 51 |
| V8 | `--fixed-fps 60` fixes the delta exactly; the flag is not in the script's args | `godot --path gdproj --fixed-fps 60 --script dt.gd` and without the flag (prints `delta`, `delta == 1.0/60.0`, `root.get_process_delta_time() == 1.0/60.0`, `"--fixed-fps" in OS.get_cmdline_args()`) | fixed: `dt 0.01666666666667 exact=true root=true args=false` ×3; real time: `dt 0.01471266666667 exact=false …`, `0.00573933333333`, `0.0125` |
| V9 | Fixed step: byte-reproducible | PNG join and `pxdiff.gd -- run3 run4`; `cmp r1/worlds.sha256 run3/worlds.sha256`; contact sheet opened | `png equal 15 of 15`; `diffpx 0 … max 0` on all 15; `worlds-equal-r1`; `worlds-equal`. In run3's sheet the arrived cards are visibly faint (mid fade-in) |
| V10 | How much A changes the capture | `pxdiff.gd -- r1 run3` | docked 23.6 %/16.7 % max 1; boost max 94–105; cruise deck 7.08 % max 80 mean 1.22, forward 7.41 % max 83 mean 1.76; arrived_acen 34.4 %/38.2 % max 143/100; arrived_home max 74/121; sheet 17.5 % max 114 |
| V11 | Where the docked frames differ | `mask.gd -- r1/01_docked_deck.png run2/01_docked_deck.png mask.png`, opened | changed pixels (white) only on the lit ship geometry (deck floor, rail, console bases, captain), as a fine dither; sky, Sun disc and HUD unchanged |
| V12 | Docked cause: the near star's light mid-ease | probe in `_shot` (`demo.star_light.energy/dir_world/colour`, `demo.lighting` light energies, `captain_anim.clip`, `avatar_pos`, `Engine.get_process_frames()`), run6 vs run7 | docked deck: energy `7059.469027306199` vs `6891.6704714979205`; forward `7567.11784874176` vs `7471.9194709030535`; colour `(1, 0.9026126, 0.8562705)` vs `(1, 0.90492743, 0.8596866)`; fill `0.00021095664` vs `0.0002160851`, spire `0.012054665` vs `0.01234772`; `dir` identical; clip `idle`, avatar `Vector3(0, 82, -15)` both; frames `135`/`136`. `ship_star_light.gd:50 TAU_S := 0.5`, `:252 1.0 - exp(-maxf(delta, 0.0) / TAU_S)`; first commit `4692df21 2026-10-07` (`git log -S'TAU_S'`) |
| V13 | The tree already uses the flag; the capture does not | `grep -n 'fixed-fps' Makefile mk/*.mk tools/*.gd` (positive control in mk/) | `mk/ai.mk:566 … --fixed-fps 30 --write-movie …`, `tools/codex_preview.gd:3`; `Makefile`: `0` |
| V14 | The publish overwrites the flat reviewed path; 7l(a) test green | `sed -n 330,344p Makefile`; `make -s capture-m4-publish-test \| tail -1` | `"gs://stapledons-voyage-assets/refs/m4_ship_s1/$${f##*/}"` at line 340; `capture-m4-publish-test: OK (7 cases on 2 makes: GNU Make 3.81, GNU Make 4.4.1)` |
| V15 | Held files in open PRs | `gh pr list --state open`; per PR `gh api …/pulls/<n>/files --jq '.[].filename'` and the `Makefile` patch hunks | open: 371, 373, 379, 380, 382, 383, 384, 385. `Makefile` in 371 (`@@ -33`, `@@ -511`), 373 (`@@ -10,18`, `@@ -225`; `capture-m4` only on the `.PHONY` context line), 379 (`@@ -480`), 380 (`@@ -251`); `mk/m45.mk` in 373; 382–385: 0 matches for `Makefile`, `mk/m45.mk`, `tools/m4_ship_capture.gd`, `tools/test_m4_publish.sh`, `m4-6rr3` |
| V16 | The bookkeeping issue | `gh issue view 370 --json title,state` | `Stapledon mission bookkeeping — week of 2026-11-02 OPEN` |
| V17 | The arrived settle: cards full, earlier frames untouched | run5 (temporary `elif state.begins_with("arrived"): for i in 30: await process_frame`, reverted), contact sheet opened; join run3/run5 hashes | arrival cards fully opaque in both arrived columns; `same` for all 10 PNGs 01–05, `diff` for the 4 arrived PNGs and the sheet |
| V18 | `gcloud storage ls` on empty, populated and failing paths | `gcloud storage ls gs://…/refs/m4_ship_s1/2026-11-03/`; `… /refs/m4_ship_s1/`; `gs://stapledons-voyage-assets-nonexistent-xyz/` | empty: `rc=1`, `ERROR: (gcloud.storage.ls) One or more URLs matched no objects.`; populated: `rc=0`, 18 lines; failing: `ERROR: (gcloud.storage.ls) gs://stapledons-voyage-assets-nonexistent-xyz not found: 404.` (Google Cloud SDK 583.0.0) |
| V19 | Renders and logs are ignored; translation files covered | `git check-ignore -v renders/m4/contact_sheet.png .godot/tmp/capture-m4.log`; `git status --porcelain` after `make import` and all runs | `.gitignore:2:renders/`, `.gitignore:1:.godot/`; empty |
| V20 | Recipe lines | `grep -n 'capture-m4' Makefile` | `capture-m4:` 322, recipe 323–328 (`$(GODOT_SIM) --path . --script tools/m4_ship_capture.gd` at 323); `M4_PUBLISH_DIR` 330; `test: capture-m4-publish-test` 331; `capture-m4-publish:` 332–341; `ci-fast:` 50 includes `capture-m4-publish-test` |
| V21 | HUD card API (verified by the controller; re-read here) | `sed -n '26p;52p;491p' ui/ship_hud.gd` | `const FADE_IN_S := 0.4`; `var cards := {} # id -> {panel, title, body, priority, born, expires, leaving, left_at}`; `c.panel.modulate.a = clampf((now_s - c.born) / FADE_IN_S, 0.0, 1.0)` (inside `advance(dt)`, `:477–491`): a linear clamp, so `1.0` is exact once 0.4 s of fake-clock time has passed |
| V22 | The W1.5 alpha check, compiled in, on a fixed-step capture (quorum: kimi) | temporary edit with the W1.2 guard, `ARRIVED_SETTLE_FRAMES := 30`, `_card_alpha`, the `_check` line and a probe printing the alpha after 24 and 30 settle frames; `godot --path . --fixed-fps 60 --script tools/m4_ship_capture.gd`; reverted with `git checkout` | `probe alpha arrived_acen frame 24 1.0`, `… frame 30 1.0`, `probe alpha arrived_home frame 24 1.0`, `… frame 30 1.0`; 14 `ok frame` lines; `capture-m4: OK`; rc 0; 287 s at load 27.21→26.54 (the GPU was shared at the time) |
| V23 | A refused run's real exit code (quorum: kimi) | the same temporary build: `godot --path . --script tools/m4_ship_capture.gd` (no flag), then `… --fixed-fps 30 …` | no flag: `rc=1` in 2 s; `capture-m4: FAIL process delta 0.142168 s is not 1/60 s: run it as make capture-m4 (godot --fixed-fps 60)`, `capture-m4: 0 renders in 0.0 s …`, `capture-m4: FAIL`; 0 `SCRIPT ERROR`; `renders/m4` left with 0 files. `--fixed-fps 30`: `rc=1` in 2 s, `… process delta 0.025 s is not 1/60 s …` |
| V24 | The 7l(a) stub logs every call with one generic line; the counts read it (quorum: glm) | `sed -n '30,40p;77,82p' tools/test_m4_publish.sh` | `:34–37` `cat > "$T/bin/gcloud" <<STUB` / `#!/bin/sh` / `for a in "\$@"; do printf '%s\|' "\$a"; done >> "$T/log"; printf '\n' >> "$T/log"` / `STUB`; `:40` `B=gs://stapledons-voyage-assets/refs/m4_ship_s1/`; `:77` `: > "$T/log"`; `:78` the make line; `:80` `n=$(wc -l < "$T/log" \| tr -d ' ')`; `:81` the `good` awk with `NF == 6 && $1 == "storage" && $2 == "cp" && $3 == "--cache-control=public, max-age=300" …`; `:82` `uniq=$(cut -d'\|' -f5 "$T/log" \| sort -u \| grep -c .)`. So a listing call would have counted as an upload in `n` and added a `uniq` line; W4 filters both to `^storage\|cp\|` |
| V25 | Create-only is available in this gcloud (quorum: sol) | `gcloud --version \| head -1; gcloud storage cp --help \| grep -n -A3 'if-generation-match'` | `Google Cloud SDK 583.0.0`; `35: [--if-generation-match=GENERATION`; `419: --if-generation-match=GENERATION` / `420: Execute only if the generation matches the generation of the requested` / `421: object.` |
| V26 | W3 + W4 prototype green | private copy `/tmp/stap_iter66_design/proto2/w` (`Makefile` with the W3 block spliced by text, count 1; `mk/`; the W4 script); `make -s capture-m4-publish-test`, `gmake -s capture-m4-publish-test`; the doc's two code blocks `diff`ed against the prototype files | make rc 0 in 6 s, 26 `ok` lines, `capture-m4-publish-test: OK (13 cases on 2 makes: GNU Make 3.81, GNU Make 4.4.1)`; gmake rc 0, the same footer; `script-matches-proto`, `recipe-matches-proto` |
| V27 | RED and the ten publish drills, measured | throwaway runner `proto2/drills.sh` (copy the prototype; apply each mutation with an exact perl count, exit 3 otherwise; run `make -s -C <copy> capture-m4-publish-test`; count `ok` and `FAIL` lines; delete the copy). `flat` also through gmake | `red` rc 2, ok 12, FAIL 14; `flat` rc 2, ok 18, FAIL 8 (gmake: the same); `nodate` rc 2, ok 20, FAIL 6; `nols` rc 2, ok 18, FAIL 8; `lsany` rc 2, ok 24, FAIL 2; `envdate` rc 2, ok 24, FAIL 2; `nogen` rc 2, ok 22, FAIL 4; `inloop` rc 2, ok 18, FAIL 8 (uploads 17, 17, 18 at rc 0, 15); `noupload` rc 2, ok 22, FAIL 4; `deadcapture` rc 2, ok 18, FAIL 8; `nopositive` rc 2, ok 22, FAIL 4. The failing cases are exactly those in the Publish drills table. Every mutation applied with its expected count |

### Quorum round 1

Round 1 BLOCKED 3/3 (oc-glm-5-3, oc-kimi-k3, gpt6-1-sol). None disputed the direction (Option A, a dated path). Each objection and its resolution:

| Reviewer | Objection | Resolution |
|---|---|---|
| glm | W4's counts did not fit the stub: `all = 19`, `lsok = 1` assumed a logged listing, while the old `n`/`uniq` counted every log line | The stub keeps its single generic log line verbatim, so every call, `ls` included, logs once (V24). The behaviour branches write nothing to the log. `n` and `uniq` are now filtered to `^storage\|cp\|`, `lists` and `lsok` to `^storage\|ls\|`, and `good` moved to `NF == 7` for the new flag. The whole script is given and was prototyped green (V26). `deadcapture` still mutates the two `>> "$T/log"` of that one line; its outcome is measured (V27) |
| glm | The stub's `ls` behaviours were unspecified | W4's stub table: empty (exit 1, "matched no objects"), nonempty (one object, exit 0), error (exit 1, a 403) |
| kimi | `_card_alpha == 1.0` might never be exactly reached; unmeasured | The fade-in is a linear clamp to 1.0 (V21). With the real W1.5 lines compiled in, the alpha is `1.0` at frames 24 and 30 for both arrived states; 14 frames, rc 0 (V22) |
| kimi | The capture drills assumed `rc 1` for a refused run | Measured: rc 1, with the exact FAIL line, both without the flag and with `--fixed-fps 30` (V23); the drill table cites it |
| sol | The `ls` emptiness check is a race and not a safety mechanism: an object created between the listing and the copy would be overwritten | Every copy is now create-only (`--if-generation-match=0`, V25), so no object can be overwritten in any order of events. The listing stays as a diagnostic that avoids partial sets. New case `exists-at-cp` (the listing was empty, the object exists at copy time: 8 created, the 9th refused, no `uploaded 18`) and new drill `nogen` (precondition dropped: killed, 4 FAILs) (V27) |
| sol | Proposed a reservation object to stop two publishers mixing one set | Not adopted; the reasons are in W3 ("No reservation object"). Create-only already prevents any overwrite, the publisher is a single maintainer or the single-instance controller, and C7 now downloads the whole dated set and checks every hash and metadata file, so a mixed or partial set is never announced |

### Quorum round 2 and the controller's carve-out revision (iteration 66)

Round 2 (artifact `m4-7w-s1-republish-2026-11-03T11-05-50Z.json`) was **BLOCKED at N−1, `oc-glm-5-3` absent (unreachable)**: `gemini-4-argon` PASS, `oc-kimi-k3` REJECT, `gpt6-1-sol` REJECT. Neither reject disputes the design direction, and each carries a concrete reviewer-authored fix. So the controller applied those fixes under Gate 2's narrow-refinement carve-out, with the measurements kimi asked for, run first-hand. **Where this subsection and an earlier section disagree, this subsection wins**; the executor applies it on top of W1–W4 and the drill and AC tables.

| Reviewer | Objection | Resolution (the reviewer's fix) |
|---|---|---|
| kimi | The whole W1 patch never ran; `WALK_FRAMES_MAX` 1800 is an estimate; the 300 s inner wall guard can trip first under load | **V28** (below): the complete W1 patch (guard, settle 30, `_card_alpha`, the W1.3 walk loop and the W1.4 dolly loop) runs at `--fixed-fps 60`. Measured walk **61 frames** (first walk) and **2 frames** (the second, at home); dolly **0 frames** in all 7 states. **`WALK_FRAMES_MAX` becomes 122** (measured max 61 × 2, kimi's rule; the count does not depend on load under a fixed step). The 300 s wall guard stays as the hang guard. The whole 14-shot capture took **168 s** at 1-min load 66→147, so 122 frames cannot reach 300 s. Comment: `const WALK_FRAMES_MAX := 122 # 2 x the measured 61-frame walk at --fixed-fps 60 (V28); 300 s of wall time is the hang guard`. The failure texts keep `%d frames or 300 s`. |
| kimi | The `nosettle` drill's expectation was inferred, not measured | **V29**: with the real W1.5 lines and `ARRIVED_SETTLE_FRAMES := 0` → rc **1**, exactly **2** lines `capture-m4: FAIL arrival card alpha 0.125 at arrived_acen (want 1, after 0 frames)` and `… at arrived_home …`, **14** `ok frame` lines, `capture-m4: FAIL`. `_check` does not abort, so all 14 frames are still shot. The `nosettle` row is pinned to exactly these: rc 1, exactly 2 alpha FAILs (one per arrived state, alpha `0.125`), and 14 frames. |
| sol | The real publish (listing plus 18 uploads) has no deadline; a stalled auth or network call blocks forever | Bounded by the **existing** deadline mechanism. Its body (`tools/test_m4_publish.sh:19–29`, `deadline SECONDS CMD...`: CMD's rc, **124** on expiry, TERM to the child's process group, then KILL 5 s later) is suitable as is. It moves **verbatim** into a new `tools/deadline.sh` (`sh tools/deadline.sh SECONDS CMD...`), and `tools/test_m4_publish.sh` calls that script instead of its own copy. The recipe's ls-plus-cp section runs as one bounded child: `M4_PUBLISH_S ?= 600`, and `sh tools/deadline.sh $(M4_PUBLISH_S) sh -c '<the ls check and the 18 create-only cp calls>' …`. On rc 124 the recipe prints exactly `capture-m4-publish: publication timed out; destination may be partial; inspect before retry; do not announce` and exits non-zero, with no `uploaded 18` line. The date, file and count checks stay outside the bounded child, before it, unchanged. A planner may move the bounded body into a small `tools/m4_publish_upload.sh` if inlining `sh -c` in the recipe reads badly; the contract is the same either way. |
| sol | C7's remote checks are unbounded too | Every `gcloud` call in the controller's checklist (C6's publish is already bounded by the recipe; C7's `gcloud storage ls` / `cp` / `cat` reads) runs as `sh tools/deadline.sh 300 gcloud …`, and a 124 is reported as a failed check, never as a pass. |
| sol | Tests for the bound | The fake gcloud gains two modes: `FAKE_LS=hang` (the ls call logs its line, then sleeps for 600 s) and `FAKE_CP_HANG=<k>` (the k-th cp call logs, then sleeps). It writes its own pid to `$T/hang.pid` before sleeping. **Two new cases** run with `M4_PUBLISH_S=3`: `hang-ls` and `hang-cp` (k = 5). Each asserts: the make returns non-zero within 15 s of wall time; the output contains the exact timed-out line; there is **no** `uploaded 18` line; for `hang-cp`, exactly 5 cp lines in the log, so no copy was attempted after the hung one; and `kill -0 "$(cat $T/hang.pid)"` fails, so the hung child was cleaned up. Case count: **15 per make**. Drills: `nodeadline` (run the bounded section without `tools/deadline.sh`) must be killed, as an INFRASTRUCTURE timeout of the outer test deadline, by `hang-ls`; `nomsg` (delete the timed-out echo) must be killed by both hang cases. |

**Verification log additions** (run by the controller in `/Users/voightkampff/dev/sunholo-data/.stap-iter66-src` at `68796623` with the doc at `d0525d9e`; the W1 patch was applied by a script and then reverted, and the tree is clean afterwards):

| # | Claim | Command | Observed |
|---|---|---|---|
| V28 | The full W1 patch at a fixed step: walk and dolly frame counts, wall time under load | W1.1–W1.5 applied (settle 30, `WALK_FRAMES_MAX` 1800, a probe print of the dolly frames); `AILANG_BIN=$PWD/runtime/bin/ailang godot --path . --fixed-fps 60 --script tools/m4_ship_capture.gd` | rc 0, 168 s, 1-min load 66.36 before and 147.20 after; `capture-m4: walk 61 frames`, then `walk 2 frames` (arrived_home); `probe dolly 0 frames` in all 7 states; 14 `ok frame` lines; 0 `SCRIPT ERROR`; `capture-m4: OK` |
| V29 | `nosettle` with the real check compiled in | the same patch with `ARRIVED_SETTLE_FRAMES := 0`, same command | rc 1, 101 s; `FAIL arrival card alpha 0.125 at arrived_acen (want 1, after 0 frames)` and the same at arrived_home (2 alpha FAILs); 14 `ok frame` lines; `capture-m4: FAIL` |
| V30 | The deadline mechanism exists and has the semantics sol asks for | `sed -n 16,32p tools/test_m4_publish.sh` | `deadline SECONDS CMD...: CMD's rc; 124 on expiry (TERM to its process group, KILL 5 s later)`; TERM/INT/HUP forwarded as KILL to the child's group |

**AC deltas.** AC1/AC2: `OK (15 cases on 2 makes: GNU Make 3.81, GNU Make 4.4.1)` (30 `ok` lines on the rig, 15 on Linux). AC3 gains `nodeadline` and `nomsg` (killed). AC5's `nosettle` expectation is V29's (exactly 2 alpha FAILs, alpha 0.125, 14 frames, rc 1). AC7 also greps for `tools/deadline.sh` and `M4_PUBLISH_S` in the recipe, and the timed-out line. AC9's allowlist gains `tools/deadline.sh` (and `tools/m4_publish_upload.sh` if the planner uses it). **LOC**: about +35 over round 1's ~100.
