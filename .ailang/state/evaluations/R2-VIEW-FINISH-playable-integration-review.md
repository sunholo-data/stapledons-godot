# Independent audit: playable bridge/Commons integration

**Date:** 2026-10-29. **Scope:** PR #351 as a completed playable development slice, not completion of R2-VIEW-FINISH. This reviewer did not author the runtime, export staging or native build. Earlier work by this reviewer consisted of independent reviews. No GPU sessions or full suite were run for this audit. This is an unscored integration audit, not a formal whole-sprint evaluator result.

## Reviewed evidence

- Reviewed runtime/export changes through `758614bb`, including normal-entry civic installation, async readiness, the resident/floor composition helper, raw-byte staging, transitive pack/hash audits and the actual-scene playtest test.
- Observed the subsequent `cbeca5be` merge of current main. That merge changes Crew UI, tooling, package cleanup and suite instrumentation; it does not change the reviewed civic runtime, main entry or console/lift integration files. It nevertheless changes the head requiring final checks.
- Read CLAUDE.md's definition of done, D-136, the native playtest review, source/staging documentation and publish-dev prerequisites.
- Opened all three packaged native HUD captures: bridge, Commons Bow and Commons Astern. Read `build/view-finish-civic-native-smoke.log` and `/private/tmp/civic-native-verified.log`.
- Read PR #351 via `gh`: at `758614bb`, draft/open, merge state CLEAN; fast tier succeeded in run `40899533512`. No rig/full status appeared in that rollup. This result does not certify the later merged head.

The inspected native artifact identifies commit `755cd4b11bc99648a74fefb81f9c3b89ed315ba1`, version `v0.4.0-dev.37-living-bridge-99-g755cd4b1`, bundled AILANG v0.54.18, ZIP SHA-256 `00d473c0692100d5761325ddd5610c7dda47b1a6685bba05c336cbf03ad678a8`. It is the civic build, not the earlier bare S3 artifact.

## Findings

**No new concrete code or packaging blocker was identified in the reviewed integration.** Normal ship entry explicitly enables the treatment and awaits installation. Source configs/assets are pinned before staging; generated configs rewrite authoring references into the exported bundle; raw GLB/PNG bytes avoid importer loss; pack auditing checks transitive closure and byte hashes with missing/corrupt/path-leak controls. Failed installation is observable rather than silently reported as a successful normal entry.

The packaged images contain the reviewed civic art and resident figures with a visible captain, readable HUD and open live sky. Native logs report civic readiness, normal startup and `civic-playtest-smoke: OK packed-art live-activity walk lift-roundtrip`. The smoke implementation checks packed config selection, residents, actual movement, activity advance/reduced-motion pause, return walking and lift travel. These support the requested playable handoff; static images alone do not establish motion or usability quality.

Renderer/RID teardown diagnostics remain in the longer native log. This audit did not resolve them or establish long-session performance. It found no reason to treat unfinished art, S3 observations or S5 acceptance as a blanket prohibition on the explicitly authorized development playtest.

## Minimum remaining publish gates

The older `755cd4b1` ZIP must not be presented as an exact-head build after integrating main/PR #346. On the chosen clean integrated commit:

1. Rebuild and pass the existing `make publish-dev` prerequisites, including civic staging, **strict pack zero-skips/zero-failures** and all exported smoke dependencies. Keep build version/commit equal to the checkout; the existing recipe enforces this.
2. Repeat the civic-specific packed-art/activity/walk/lift smoke on that same exported app, because the older native result cannot certify the integrated artifact. The dedicated civic diagnostic is not itself a named publish-dev prerequisite; existing normal-start smoke verifies installation readiness but has narrower behavioral coverage.
3. Publish the new version/hash/commit to the dev latest manifest and verify the downloaded artifact. A successful private preview URL or an older signed ZIP is not proof that latest points to the new integrated build.

## Minimum remaining merge gates

- Finish integration against current main, resolve any subsequent changes and push the selected final PR head.
- Obtain **fast-tier success and exact-head rig/full success**. Under CLAUDE.md and `tools/rig_check.sh`, this visual PR requires the whole `make test` **plus `make golden`** (`--golden`), not only targeted civic checks. Earlier fast/targeted/native results do not replace those gates.
- Retain the changed-view spec assertions and opened reference renders. No new simulation/physics formula was introduced by the civic integration reviewed here; existing physics golden obligations remain.
- Complete the project's independent scored evaluation for the explicitly scoped landing unit. Do not substitute this unscored audit or the earlier pilot appearance reviews for the required evaluator result. Describe the completed playable slice and its validation in the PR/changelog while leaving the unfinished wider sprint open.

S3 manual observations, S5 final appearance approval, full Commons finish/propagation and production performance remain open sprint work. They must not be falsely marked complete to merge the narrower playable slice or publish its development build. Conversely, this audit does not waive any exact-head merge or publish prerequisite above.
