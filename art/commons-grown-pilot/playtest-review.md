# Native civic playtest readiness — 755cd4b1

Reviewed 2026-10-29. **No additional blocker to giving the requested native build to the user for play was found.** This is a native installation and image-readability check, not S3 acceptance, finished-art certification or full performance clearance.

The reviewer authored the resident helper and scene regression test earlier, but did not build this app or produce these native captures. This inspection independently checks their packaged integration; it does not independently grade the reviewer's resident artwork.

## Evidence inspected

Opened all three full-size native HUD captures:

- [Bridge](../../renders/view-finish/civic-playtest-native/bridge.png).
- [Commons Bow](../../renders/view-finish/civic-playtest-native/commons_bow.png).
- [Commons Astern](../../renders/view-finish/civic-playtest-native/commons_astern.png).

Read [the native smoke log](../../build/view-finish-civic-native-smoke.log) and `/private/tmp/civic-native-verified.log`, and checked the smoke implementation in `demos/ship_geometry_demo.gd`. No commands were rerun and no GPU session was started for this review.

The export's staged metadata identifies commit `755cd4b11bc99648a74fefb81f9c3b89ed315ba1`, version `v0.4.0-dev.37-living-bridge-99-g755cd4b1`, and AILANG `v0.54.18`. The executor separately verified the native app against that commit.

## Findings

The native Commons captures contain the actual civic composition: painted cream ground and paths, teal/ochre/violet structures, planted islands and arcades, furniture and ordinary civilian figures. They are not the earlier bare S3 native build. The bridge retains its established styling and sky.

The captain's complete figure remains visible in each image. The top clock/status strip and Tab help affordance are readable, with no clipping or overlay covering the captain. Both Commons views retain a substantial live-sky opening. Bow's large foreground canopy occupies much of the right side, but leaves the captain and central route readable in this capture.

Static images establish resident presence, not motion quality. The logs contain `commons-civic-playtest: ready`, `current-ship-startup: OK`, and `civic-playtest-smoke: OK packed-art live-activity walk lift-roundtrip`. The inspected smoke checks the packed config path and resident count, actual walking, resident-clock advance and reduced-motion pause, return walking and a lift round-trip. These support readiness to play; they do not replace an attended input/usability assessment.

The longer smoke log retains renderer/RID/resource teardown diagnostics. The separate verified log contains the successful startup/smoke markers without script errors. This review did not resolve those teardown diagnostics.

## Remaining review limits

Upper magenta find markers and unfinished greybox elements remain visible. Civilian figures remain a visual activity study, not finished character art or an autonomous population model. Close navigation around foreground canopies, extended play, full-resolution performance, the remaining S3 checklist and exact-head landing gates remain separate work.

**Recommendation:** offer this explicitly labelled civic playtest build now and collect the user's walking/lift/view feedback. Do not label it a finished or fully certified level.
