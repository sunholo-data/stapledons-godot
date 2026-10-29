# Painted Commons characters: first asset pilot

**Direction:** D-139. **Execution authorization:** D-140, attended 2026-10-29.
**State:** assets and opt-in static preview ready for appearance review. Normal game setup and the published dev channel do not install this pilot.

Three civilian identities (grove resident, older reader, gardener) and two named crew identities (Medic, Chief Engineer) share the captain's hand-painted comic treatment. The crew figures derive from the exact portraits currently used on the Crew console. Each identity has five poses: standing front/back/profile and seated front/back. This is departure-age art, without new dialogue, expressions, ageing or walk cycles.

## Files and reproduction

- `sources/`: five original four-pose RGBA sheets and the seated-back atlas, plus its preserved pre-cleanup candidate. Preserve these source masters. `provenance.json` links every native output, prompt and reference input.
- `prompts/`: full verbatim built-in ImageGen prompts, including the seated atlas's background-only follow-up. Exact model ID/version and seeds are not exposed by the tool. No CLI fallback was used.
- `roster.json`: identity, height and portrait references; each raw generation uses the captain's stage-zero front image as its style reference. Crew generations additionally use their own neutral portrait. The seated-back generation uses all five four-pose sheets as identity references.
- `../../assets/characters/npcs/`: 25 normalised RGBA PNGs and `manifest.json`, with per-pose file hashes, original crop/grid/cell provenance, source hashes, portrait hashes and the captain-reference hash.
- `../../renders/npc-painted-v1/`: generated matching-scale lineup, complete pose sheet, six actual player-camera Commons frames and `review.json`. The render directory is a reproducible local artifact, excluded from Git/export.
- `review/`: preserved copies of the lineup, full pose sheet and closer Bow/Astern frames, for review directly from a checkout.

```sh
make npc-painted-ingest           # image I/O in Godot; regenerate the 25 assets
make npc-painted-assets-check     # canvas, transparency, sole anchor, height, hash closure
make npc-painted-test             # real floor fixture, unique crew identities, view/negative controls
make npc-painted-capture          # GPU: inspect lineup.png, poses.png and all six Commons frames
```

Ingestion performs only quadrant/cell extraction, uniform Lanczos downscale, transparent padding and low-alpha cleanup (alpha <= 0.04 becomes transparent black). It never paints a character or scales a source up. Runtime cells are 192×288 at 144 px/m with a (96,272) foot anchor. Standing height is recorded per identity. Seated images are normalised to 75% of standing height for this first comparison; that is an art convention, not a physical seat-contact measurement.

The opt-in `demos/painted_npc_pilot.gd` replaces the 42 proxy figures only in the review capture. It reuses their existing floor positions, assigns only the three civilian identities to ordinary residents, and reserves two existing court-conversation slots for the Medic and Engineer exactly once each. The names are explicit preview identities, not newly simulated people or schedules. It creates painted Sprite3Ds without gameplay colliders. Fixed player cameras select front/back/profile paintings; seated figures have front/back views. The normal scene never calls this helper.

## Review and remaining work

The lineup and all pose/Commons frames were opened. The new figures share the captain's palette family, cloth texture and ink treatment; crew hair/scarf/workwear remain recognisable from the console portraits. All 25 images pass the mechanical asset checks, and the opt-in helper passes its identity/floor/pose and rejection tests. Capture manifests record the actual resident count, crew IDs and image hashes. Space/stars are disabled in these stationary character-inspection captures; no sky, physics, camera rules or layout were changed.

Independent review: **92/100 PASS** for NPC1/NPC2 only, with no blocking defects. The evaluator independently ran the asset/behavior checks and inspected all eight images. Report: `../../.ailang/state/evaluations/eval_R2-NPC-PAINTED-PILOT_round_1.json`. This does not provide Mark's appearance approval or production/landing certification.

Before production replacement:

- Mark reviews this first character appearance. Three background identities repeat across 40 civilian slots; more variation is needed for the full crowd.
- Calibrate a **seat anchor per painted pose** against each bench's actual seat height. Feet are aligned, but `seat_height_m` currently selects a seated image only; butt/seat contact is not certified. Full seated side views are also absent.
- Add a contact-shadow treatment consistent with the captain. This first Sprite3D pilot has no ground shadows and can read as cutouts against sunlit paving.
- Add painted gait frames before a resident moves. This preview keeps the figures still, including the former short-stroll rows, and introduces no decorative bob under reduced motion.
- Bind named presence, age and availability to the real crew snapshot before using these placements in normal play. In-world crew interaction remains separate work.
- Run the actual export/rig/performance/visual landing gates on the final production implementation. These pilot checks do not certify the full level, S3/S5 or release readiness.

The asset source PNGs and prompts are excluded from the game export; only the prepared runtime image/catalog directory is included. No existing captain or crew portrait image was overwritten.
