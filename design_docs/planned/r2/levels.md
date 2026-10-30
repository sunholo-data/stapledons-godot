# R2-LEVELS: a repeatable level pipeline for intricate 2.5D levels, first run on the Commons

**Status:** **Approved** by Mark on 2026-10-20 (ledger D-103, "ok yes good"), with every recommendation (OQ1–OQ10) and the proposed charter rows, which are on main. D-104 adds the shape-language rule (§B8). LP0/LP1a landed. On 2026-10-29, D-130 approved resuming LP1b–LP4 through [R2-VIEW-FINISH](bridge-commons-finish-sprint.md); old bridge-style/DL3 merge holds are cleared (D-125). S3/S5 approvals remain required.
**Release:** R2, then ongoing: every level of the ship goes through this pipeline, one after another.
**Priority:** P1 for R2. It is one of the three tracks Mark named after playing the bridge (D-98); captain animation and sound have their own plans.

**Mark's direction** (verbatim):
> 2026-10-19 (D-91): "we are just on the bridge for now, but as we go down through the levels we will have similar fixed caemra views as we explore them - more like a 2d/2.5d platform game? able to explore the layers"
> 2026-10-19 (D-91): "this way we dont have to dress full on 3d environemtns and can get a sense of style and taste for each level that is in keeeping with the concept art, relying on paralax etc. to help give sense of scale"
> 2026-10-20 (D-98): "obviously we need animation on the captain a bit and sound effects and the level design but such good potential"
> 2026-10-20 (D-100): "we need more intricate level design now we have fixed position sorted"
> 2026-10-20: "we will have bridge but the next level as well needs a lot of filling out, but ongoing we have a lot of levels to work on - I can see that being just a continuous job that evolves over time so we need a good working process for it"

**So the main deliverable is a process, not a level.** The plan has three parts:
- **Part A:** a level pipeline that repeats for every level, with named stages, pause points, a template, a manifest schema, shared tools, a split between the loop and attended sessions, a backlog and cheap feedback;
- **Part B:** the design language for *intricate* 2.5D levels, and how the fixed camera handles height;
- **Part C:** the ship's seven tiers, and the first full run on the **Commons**, the level below the bridge.

The intricate bridge is a later run of the same pipeline, after R2-BRIDGE-STYLE (approved as D-100 and executing). This plan never edits the bridge's art, lighting rig or HUD. Some shared camera and lift files are held by that sprint and DL3, so the work that touches them waits for those merges (§Depends on).

The living process doc is [design_docs/levels/README.md](../../levels/README.md). The per-level template is [design_docs/levels/TEMPLATE.md](../../levels/TEMPLATE.md), and the backlog is [design_docs/levels/backlog.md](../../levels/backlog.md).

**Implements** (design repo):
- [features/phase1-data-models/ship-structure.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase1-data-models/ship-structure.md): zones, the spire through every level, terminals at the spire, lifts, ramps, stairs and ladders ("no single correct route; getting lost is possible and interesting"). Its 15–20 levels became **seven tiers** (D-34).
- [art/ship-interior-blender-brief.md](https://github.com/sunholo-data/stapledons-design/blob/main/art/ship-interior-blender-brief.md):
  - §2–§3: travel toward the bow (D-92); levels stack on the mast; lower levels are roofed by the slab above;
  - §2: five parallax layers;
  - §4: the Moebius / *Métal Hurlant* style, tiny humans in cathedral spaces;
  - §5: never paint space;
  - §6: the `WALK_` / `SPAWN_` / `INTERACT_` kit.
- [art/README.md](https://github.com/sunholo-data/stapledons-design/blob/main/art/README.md): style frames first, then stop for Mark; large binaries by sha256 in the public bucket.
- [vision/design-decisions.md](https://github.com/sunholo-data/stapledons-design/blob/main/vision/design-decisions.md):
  - 2026-10-03 "Bridge v2 Follow-up": the open question on the sky from enclosed levels, answered by measurement in §B4;
  - D-92: every open level's bow edge sees the forward sky.
- This repo:
  - `art/ship-dimensions-v2/layout.json` and `art/ship-tier-concepts-v1/` (D-34, D-35);
  - [camera-forward.md](../../implemented/r2/camera-forward.md) §D0: levels as stages;
  - [deck-layout.md](deck-layout.md): the evaluator-first method (DL0), the Blender generator (DL1), and the spire as light (§D5a, D-96);
  - [m4-ship-commons-build.md](../../implemented/r1/m4-ship-commons-build.md): the existing Commons;
  - the charter's "How to use the loop": the routing used in §A6.

**Depends on:**
- R2-CAMERA-FORWARD (landed): `views.json` v2 keyed by level, the slide rig and the occluder fades.
- R2-DECK-LAYOUT (bridge layout/hero assets landed): `DeckBowMetrics`, the Blender generator pattern, the asset check and the pinned masters.
- **R2-BRIDGE-STYLE** (landed, including #322): the finish and graphic language that each level's style stage (A1 S5) applies.
  - This plan never edits the bridge's art (`assets/ship_demo/*`), its lighting rig (`demos/ship_lighting.gd`, `demos/ship_star_light.gd`) or the HUD.
  - Former shared-file holds are cleared per D-125. R2-VIEW-FINISH now gives a single runtime owner `data/camera/views.json`, `demos/camera_director.gd`, `tests/test_camera_director.gd`, `demos/ship_demo_lift.gd`, and per-level lighting integration; bounded bridge/UI work remains separate.
  - **LP0 and LP1a are complete.** LP1b may resume after the source/baseline stage, with active PR/file ownership rechecked at execution.
  - Readers of `views.json` levels that LP1b updates: `demos/camera_director.gd`, `demos/ship_geometry_demo.gd`, `tests/test_camera_director.gd` and `tools/deck_bow_metrics.gd`.
- Sibling plans (D-98): captain animation (climb, ride and sit clips; §B3) and sound (each stage names an ambience; §A4).
- No physics change. `sunholo/relativity`, `sim/`, the protocol and the replays are untouched.

**Estimated LOC:** about 2,350 in the game repo:
- LP0 process, schema and the bridge baseline: 300;
- LP1a and LP1b tooling: 1,400;
- LP2–LP4 for the Commons: 650.

There are also about 600 lines of `bpy` (a shared level library plus the Commons script) in `~/dev/blender/scripts`. These are authoring tools in the Blender workspace, like a DCC application, not a step of this repo's pipeline: the game loads committed GLBs and checks their pins. This is the precedent of deck-layout §D6, which Mark confirmed (D-90 OQ8). If one were ever tracked here, its role would be `harness`.

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md`, D-34, D-92 and the 2026-10-03 level decisions), 2026-10-20. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | 0 | Neutral. Levels are places; no decision moves |
| The Game Doesn't Judge | 0 | Neutral. No status by deck (the Commons doc already rules out an upper/lower caste) |
| Time Has Emotional Weight | +1 | Every level frames the journey (the sky band, §B4); a bow balcony on each level is where you watch a stop or an eclipse |
| The Ship Is Home | +3 | The ship becomes a town of layers to explore: catwalks, alcoves, crawlspaces and terraces where the crew live and work. Inner space framed against the vast outer one |
| Grounded Strangeness | +1 | Measured architecture inside the 95 m envelope; the sky is live and only framed |
| We Are Not Built For This | +1 | A 1.75 m figure on a 190 m floor under a 24 m ceiling; crawlspaces with no sky at all |
| **Net** | **+6** | **Go.** No pillar is negative |

**Risk to watch:** "intricate" could become clutter that hides the captain and the sky. The pipeline's evaluator measures exactly that (head and pole rays, finds in sight) before Mark plays anything (§A1 S2, §B5).

---

# Part A: the level pipeline

## A1. The lifecycle of a level

Each level (or a stage within a level, for big tiers) moves through eight stages. Each stage has an owner, an artifact and an exit test. ⏸ marks Mark's pauses: three per level, each a few minutes with a contact sheet or a dev build.

| # | Stage | Owner | Artifact | Exit |
|---|---|---|---|---|
| S0 | **Brief** | attended (agent drafts, Mark reads) | `design_docs/levels/<id>.md` from the [template](../../levels/TEMPLATE.md): purpose, concept refs, mood and light, stages, routes, finds, set pieces, sky band | ⏸ **Mark approves the brief** (or it waits in the backlog) |
| S1 | **Greybox** | agent; the loop may regenerate | `art/levels/<id>/layout.json` (vN), built in-engine as role-coloured primitives by `LevelGreybox` (§A5). No Blender yet | `make level-eval LEVEL=<id>` runs |
| S2 | **Evaluate** | **loop-suitable** (headless) | `level-eval` numbers against `art/levels/<id>/thresholds.json`: traversal, readability, sightlines, fades, budgets (§B5). The layout is iterated until it passes | `level-eval: <id> ok` |
| S3 | **Playtest** | attended | A dev build with the greybox, the contact sheet, per-file frame URLs and the brief's checklist | ⏸ **Mark plays it**; the ruling is recorded (§A8) |
| S4 | **Dress** | agent (renders park for Mark: `[LOOP+RENDER]`) | The Blender generator turns the layout into hero, coarse, walk and card GLBs (§A5); budgets and pins checked | `level-assets-check`, `level-eval` on the export |
| S5 | **Style** | attended | Style frames on R2-BRIDGE-STYLE's finish (palette, ink, light) | ⏸ **Mark approves the finish** |
| S6 | **Land** | loop does the mechanics; Mark merges | `rig/full` green, goldens, the level's **regression baseline** pinned (§A7), backlog status `landed vN` | merged |
| S7 | **Revisit** | either | A new layout version `vN+1` re-enters at S1 (or S4 for dressing only); every other level's baseline must stay green | as S2–S6 |

**Why greybox in the engine first:** the mock tool on this branch builds a whole intricate level from a list of boxes in under two minutes, measures it, and renders it through the real views with the live sky. Layout iteration needs no Blender, so the loop can run it. Blender comes in at S4, when the layout is settled.

## A2. Cadence: a production line

- **Two levels in flight:** one in greybox (S1–S3) while another is dressed (S4–S5). A third may have a brief (S0) waiting.
- **The pauses are batched.** One attended session can approve a brief, play a greybox and approve a style frame, each for a different level.
- **Big tiers ship in stage-sized pieces.** The Garden's first piece might be "the bow grove and its canopy walk". A level is landed when its first stage is, and later stages are revisits (S7) that add to it.
- **A level is never finished.** S7 is normal work: a new layout version, re-evaluated, with every other level's baseline protecting the rest of the ship.

## A3. The level template (one page plus checkable ACs)

The template is [design_docs/levels/TEMPLATE.md](../../levels/TEMPLATE.md). A level doc is short: purpose, refs, mood and light, the stage list, routes, finds, set pieces, the sky band, its thresholds, and a checklist for Mark's playtest. Its acceptance criteria are the shared commands with the level id, so a level doc never invents new tests:
- `make level-eval LEVEL=<id>`
- `make level-assets-check LEVEL=<id>`
- `make level-capture LEVEL=<id> TAG=<stage>`
- `make levels-regress`

## A4. The level manifest (`stapledons.level/1`)

One manifest per level, `assets/levels/<id>/manifest.json`. It is generated from the layout (S1 from the in-engine greybox, S4 from Blender) and read by the game, the evaluator and the capture tool. Fields:

| Field | What |
|---|---|
| `id`, `version`, `deck_z_m`, `roof` | the tier (slab top, roof underside and radius), the layout version |
| `stages[]` | `id`, `bounds_ship_m`, `surfaces[]` (each walkable height), `spawn`, `default_view`, `journey` (does it frame the sky band), `ambience` (for sound) |
| `views` | per stage: Bow and Astern parameters (yaw fixed, pitch, back, rise), `captain_px` band, `ceiling_clamp` (§B3), `occluders[]` |
| `routes[]` | stairs, ramps, ladders, hatches, gantries and exits: `from`, `to`, `kind`, `at`, `width_m`, and `clip` (the captain-animation clip it needs, if any) |
| `use_points[]` | consoles, terminals and benches: where the captain stands and what opens |
| `finds[]` | things to discover: `id`, `stage`, `at`, `cue` (light, sound or motion), `reveal` (which view shows it) |
| `set_pieces[]` | authored framings: `id`, `at`, `view`, `when` (`stop`, `eclipse`, `arrival`, `cruise`), what it frames |
| `layers` | `hero`, `coarse` (true-depth far geometry), `cards[]` (painted, true depth), `foreground[]`, and `foliage[]`: painted foliage cards (D-106), each `{card, at, scale, layer: fore\|stage\|far, sway}`, from a foliage library with sha256 pins and provenance (`make foliage-check`, built after the stylised-plants spike, PR #299). Cards are painted per level at S4, about one image per plant kind approved in the brief; trunks, planters and grown-tech fixtures are smooth stylised 3D; big plants get proxy shadow casters |
| `lights` | the spire segment (height, range bounded by the ceiling), `practicals[]` |
| `lift_stop` | the level's z, gate, landing stage |
| `crew_anchors[]` | named stand points with a facing, for the crew systems |
| `budgets` | per-view ceilings (§B6) |

`views.json` keeps the camera's global settings and moves to schema v3. A level's views come from its manifest, so adding a level never edits `views.json`.

## A5. Shared tooling (generalised from the bridge)

| Tool | From | Does |
|---|---|---|
| `LevelGreybox` (`demos/level_greybox.gd`) | `tools/levels_intricate_mock.gd` (this branch) | Builds a layout JSON in the engine as role-coloured primitives with colliders, for S1–S3 (dev builds can ship a greybox level) |
| `LevelMetrics` + `make level-eval LEVEL=` | `DeckBowMetrics` (DL0) and the mock's `_surface` and `_graph` | Every §B5 metric over every stage and surface, through the real views and the ceiling clamp |
| `make level-capture LEVEL= TAG=` | `deck_bow_probe --capture`, the mock tools | Bow and Astern per stage and surface, at rest, 0.99c and a stop; set pieces; a diagnostic overview; contact sheet; `metrics.json` |
| `make level-assets-check LEVEL=` | `deck_assets_check.gd` | Pins, budgets, opaque, no painted emission, clean reimport |
| `make levels-regress` | new | Re-runs every landed level's `level-eval` against its pinned baseline (§A7) |
| `stapledon_level_lib.py` + `stapledon_level_<id>_vN.py` | DL1's `stapledon_deck_layout_v2.py` | Reads the same layout JSON and exports hero, coarse, walk, cards and the manifest. Two runs are byte-identical; masters are pinned in the bucket |
| `tools/levels_backlog.sh` | new | Parses and validates `design_docs/levels/backlog.md` (statuses are from a fixed set), so the loop and CI can read it |

## A6. What the loop can do, and what stays attended

The same split as the charter's "How to use the loop" (2026-10-09), applied to levels:

| Work | Route | Why |
|---|---|---|
| S2 evaluator runs; iterating a greybox layout to pass thresholds that Mark has approved | `[LOOP]` | Headless and verifiable |
| `level-assets-check`, budgets, pins, `levels-regress` after any change | `[LOOP]` | Headless |
| Regression captures of landed levels, uploaded to `refs/levels/<id>/regress/` and linked on issue #1 | `[LOOP+RENDER]`: builds, uploads, **parks for Mark** | A visual change never lands without his eye |
| Upstream repros (AILANG, Godot import, Blender export) | `[LOOP]` | As today |
| Backlog bookkeeping (statuses, links) | `[LOOP]` | Data |
| S0 brief, layout *feel*, S3 playtest, S5 style and art direction | `[ATTENDED]` | Taste and feel judgements (D-56/D-57) |
| New set pieces, finds that touch story or lore | `[ATTENDED]` | Canon and lore stay attended |

The loop never starts a level's S0, never changes thresholds, and never lands a dressed or styled visual. Its do-not-touch line holds any level in an attended stage.

**After S3, layout changes are attended.** Once Mark has played a greybox, any `layout.json` change that adds, removes or moves an approved stage, route, find or set piece parks for him. The loop may only tune within the tolerances set in the file (a find's cue, a fade list, a rail height). `levels-regress` enforces it: a landed level whose layout sha256 changes without a matching change-log row in its level doc fails.

**What the loop reads:**
- `sh tools/levels_backlog.sh --next` prints the items it may take now: S2 runs on levels whose brief is approved, `levels-regress`, and regression captures.
- A level in S0, S3 or S5 is never listed.

**Proposed charter rows** (part of this plan's approval; Mark records them in the attended session that approves it):
- **Queue L10:** "Levels: take the next item from `sh tools/levels_backlog.sh --next` (S2 evaluation, asset checks, `levels-regress`, regression captures parked for Mark); never S0, S3 or S5; never thresholds" `[LOOP]` / `[LOOP+RENDER]`.
- **Do-not-touch:** "levels in an attended stage per `design_docs/levels/backlog.md`".
- **How to use the loop:** a one-line pointer to `design_docs/levels/README.md`.

## A7. Revisiting a landed level without breaking the others

- **Versioned layouts:** `art/levels/<id>/layout.json` carries `version`, and every export pins the layout's sha256 in the manifest. Old versions stay in git history, and the masters are in the bucket by sha256.
- **A regression baseline per level:** `art/levels/<id>/baseline.json` holds that level's `level-eval` numbers (per stage and surface) and its capture poses. `make levels-regress` runs all of them and joins `make test`.
  - A change that moves another level's numbers fails.
  - A deliberate change to this level's numbers re-pins its baseline in the same commit, with the reason in the level doc's change log.
- **Shared code is guarded twice:** the camera, walk and lift tests plus `levels-regress` over every landed level. A tweak to the ceiling clamp for the Garden can't quietly break the Commons.
- **The bridge has a baseline from day one.** LP0 writes `assets/levels/bridge/manifest.json` (one stage, `deck`) and pins `art/levels/bridge/baseline.json` from today's bridge numbers, so `levels-regress` guards the bridge before any lower level lands.
- **Greybox and export use the same evaluator.** `LevelMetrics` reads a level either from `layout.json` through `LevelGreybox` (S1–S3) or from the exported GLBs and manifest through the demo's `asset_dir` hook, as DL0 does for the pinned bridge (S4 on). A fixture tests each path.
- **Manifests are committed** (`assets/levels/<id>/manifest.json`), and they and their GLBs are in the export filter (`make export-filter-audit`, part of `make test`). Layouts (`art/levels/<id>/`) are source and are not exported.
- **Goldens:** the physics goldens stay as they are, and the new poses get their own cases (§C6).

## A8. Feedback and rulings, cheaply

- **Every pause gets three things:**
  - a contact sheet;
  - per-file frame URLs (the bucket has no folder listing);
  - a **checklist of five to eight lines** from the level doc ("the spawn shows the court and the starbow", "find the telescope without being told", …).

  Mark answers in one line per item.
- **Rulings:**
  - An attended ruling is recorded straight into the ledger (`mission_answer.sh`, as for every D-row), with the level id in the row, and mirrored in the level doc's **Rulings** section with the ledger id.
  - Remote rulings go through issue #1, as today.
- **The backlog shows where every level stands:** stage, version, last ruling and next pause. Mark and the loop read the same file.

---

# Part B: the design language for intricate 2.5D levels

## B1. What "intricate" means (D-100)

A level is not a flat deck with props. Each stage is built from:

| Element | Examples | Measured by |
|---|---|---|
| **Heights and routes** | Mezzanines, terraces, catwalks, gantries, stairs, ramps, ladders, hatches, crawlspaces under the floor | `surfaces`, `heights`, `routes`, `unreached` (§B5) |
| **Alcoves and thresholds** | Market stalls, doorways, arcade bays, niches at the spire | head rays inside them |
| **Layers for depth** | Foreground (beams, planters and fronds close to the camera); the stage; midground structure; background landmarks on the far floor; the roof's underside; the sky | `near-field`, pole rays |
| **Things to find** | A notice board, a telescope on a balcony, a service panel in the crawlspace, a crew bench | `finds`: reachable, hops, metres, in frame from the stage's first view |
| **Reasons to traverse** | Finds; crew anchors; use points (terminals, consoles); set pieces worth climbing to | `route_m` to each find |
| **Reveals** | Sightlines that open at chosen moments: the starbow over a roof edge once you reach the catwalk, the spire through a gap | per-surface pole rays and the sky band |
| **Set pieces** | A bow balcony framing a stop's body (30° off the bow, at the horizon); an eclipse seen through a tier's sky band (D-96) | `set_pieces` captured at `when` |

**The greybox mock shows this concretely** on the Commons (§Evidence). Over the real Commons it adds:
- a mezzanine terrace 4 m up on the starboard side, with stairs;
- three market alcoves on the port side;
- a catwalk 9 m up spanning the frame from the lift gantry to a bow balcony with a telescope;
- a hatch to a service gallery hung under the slab (in the Homes tier's ceiling);
- a banner beam and planters in the foreground;
- a civic tower and a market canopy on the far floor.

The result has **7 surfaces on 4 heights (+53, +57, +61 and +66 m)**, all reachable from the lift. Finds sit 1–4 hops and 17–64 m of route from the landing.

**A re-imagined bridge sketch shows the same vocabulary on the deck** (a later run): a stern gallery 3 m up with stairs, a ring walk around the mast 6 m up reached by a ladder, a scope on it, and a lamp beam in the foreground. From the mast ring the needle splits the starbow, a set piece in its own right.

## B2. Height inside a stage

- **Walkable surfaces are listed per stage.** The captain stands on one surface at a time.
- **The walk uses the surface nearest the current height within a step (0.45 m).** Today `WalkArea.height_at` takes the highest hit, which would teleport the captain up onto any surface overhead.
- **Routes join surfaces:**
  - **Stairs and ramps** are walkable slopes.
  - **Ladders and hatches** are use points. Interacting moves the captain to the other end (a short cut, like the lift's transfer) until the captain-animation plan delivers climb clips. The route's `clip` field then switches it to a climb. Each end of a transfer is a use point placed on walkable ground, clear of `is_walkable`'s ring probe at slab edges. A test fixture puts a hatch at an overhang's edge.
- **Crawlspaces are stages of their own** (enclosed, with their own view), entered by a hatch route.

## B3. The camera with vertical movement (it still never turns)

| Situation | What the camera does | Measured on the greybox |
|---|---|---|
| Walking on one surface | The slide, as on the bridge: fixed yaw and pitch, 9 m back and 5.5 m up from the captain's floor | captain 77 px at 720p on every surface |
| Climbing to another surface | The slide follows the floor height with F1's vertical dead zone and ease. On a catwalk 9 m up, the same pose sees more sky and less floor | catwalk: head never hidden; the pole hidden only where a landmark stands on the pole line (7 of 31) |
| **Under an overhang** (a mezzanine or a catwalk overhead) | **The ceiling clamp:** while a surface is overhead within 8 m, the pose eases to a lower framing at the same distance (pitch −3°, 9.5 m back, 2.2 m up). It's a slide, not a turn, and it eases back when the captain steps out | floor samples with the captain's head hidden behind greybox: **163 of 621 (26%) without the clamp, 59 (9.5%) with it**, with the captain kept at 77–81 px. The first clamp tried (pitch −4°, 6 m back) cleared about as many but put the captain at 127 px, outside the band. The mock first printed 135 and 49 because the engine renamed its duplicate piece names, so some greybox hits weren't recognised. The evaluator (LP1a) uses unique names |
| A crawlspace or enclosed room | The stage's own view, low and close (pitch −4°, 6 m back, 1.9 m up, as in the mock). Enclosed rooms see no sky | the captain's head hidden at 10 of 195 samples (the hangers; the mock's 5 had the same naming fault); the pole hidden from 102, as intended. At 6 m the captain is 127 px, outside the band, so the S2 run moves the enclosed view back too |
| Changing stage (exit, ladder, hatch, lift) | Cut, or a single ease under full motion (R2-CAMERA D6). Keys stay screen-relative: W is toward the bow; on a ladder W is up | — |

The clamp's thresholds (9.5% still hidden is too many) are the evaluator's job. S2 iterates the layout until `head` passes, for example by trimming the mezzanine's overhang or adding the stall roofs to the fade list.

## B4. The sky on every tier: the band (measured)

The forward pole sits at the horizon (D-92), so a roofed tier sees the forward sky through the band between its floor rim and the roof edge above it. From a stage 20 m inside the bow rim:

| Tier | Roof edge, stage pose (16 m back, 3 m up) | Roof edge, Bow pose (9 m back, 5.5 m up) | The half-sky fits under the roof from |
|---|---|---|---|
| Commons | open above the outer ring | open | — |
| Homes | 43.0° | 49.9° | 0.73c |
| Garden | 34.4° | 38.0° | 0.83c |
| Workshops | 29.1° | 31.1° | 0.87c |
| Farms | 25.1° | 26.0° | 0.91c |
| Engineering | 20.9° | 21.1° | 0.93c |

At 0.99c the half-sky gathers within 8.1° of the pole (cos θ′ = β), so **the starbow forms inside the band on every tier**. Sixty metres in from the Garden's rim the band is a slit, with the roof edge 15.7° up, measured and computed alike. The placement rule: stages that should feel the journey sit within about 30 m of a bow or stern rim, and inward stages are the enclosed ones.

## B5. The evaluator's metrics (traversal, readability, sightlines)

`LevelMetrics` runs headless over every stage's surfaces (0.5 m grid) through the real poses, including the ceiling clamp.
- **Thresholds are per level in data.** A level's `thresholds.json` is approved together with its brief (S0).
- **Who may change them:** only Mark, in an attended session. The loop never does.

| ID | Metric | Default threshold |
|---|---|---|
| `unreached` | Surfaces not reachable from the lift landing over `routes` | none |
| `heights` | Distinct walkable heights per stage | ≥ 2 on stages marked `intricate` |
| `find-route` | Route metres and hops from the spawn to each find | ≤ 4 hops and ≤ 80 m on an intricate stage (a level may set its own, approved with its brief) |
| `find-sight` | Finds in frame and unobstructed from the stage's first view, or flagged with a `cue` | every find visible **or** cued |
| `head` | Captain's head hidden after fades and the clamp, per surface | ≤ 2% per surface; 0 at spawns, use points and route ends |
| `pole-ray` | Forward pole hidden from samples on `journey` stages | ≤ 2% (a landmark on the pole line fails it, as the mock's civic tower does: 81 of 621) |
| `band-top` | Roof-edge elevation along the pole ray vs the slab model | within 0.5° |
| `captain-px` | Captain's height at 720p | inside the level's band (45–82 px) |
| `near-field` | Rays hitting geometry nearer than the captain, at the spawn | Bow ≤ 5%, Astern ≤ 10% |
| `body-both` | Stop body 30° off the bow hidden on both sides | ≤ 2% |
| `budget` | §B6 ceilings | all |

**What the mock's first greybox already teaches:**
- **The civic tower is on the pole line.** It hides the pole from 81 floor and 7 catwalk samples, so it moves off-centre.
- **The mezzanine's underside hides the captain.** The clamp fixes most of it, and the layout has to fix the rest.
- **From the court's first view, only one of the four finds is clear:** the notice board. The bench, the telescope and the ladder are hidden behind rails and the mezzanine, so they need cues (a lamp, a crew member, a glint) or better placement.

This is exactly the S2 loop the pipeline runs before Mark plays anything.

## B6. Layers and budgets per stage view

| Layer | What | How | Ceiling |
|---|---|---|---|
| 1–2 | Galaxy and stars | the engine, live | — |
| Far | The rest of the tier, the roof's underside, landmarks | coarse geometry at true depth; painted cards at true depth only where geometry costs too much | coarse < 4 MB, 60k tris, 4 materials; 4 × 2K WebP cards |
| Stage | The walkable surfaces, routes and finds | hero GLB | < 10 MB, 220k tris, 18 materials, 16 images |
| Fore | Beams, planters, fronds near the camera | small GLBs or cards; faded by the occluder rule | 10k tris |
| Frame | — | one hot level; neighbours coarse | p99 < 16.7 ms at 2560×1440 on the Studio |

The camera only slides, so anything at its true depth has correct parallax with no extra code.

## B8. Shape language (D-104)

Mark, 2026-10-20: "everything looks quite boxy with edges, isn't the style more rounded curves?"
- **From S4 (dressing) on, structures follow the art bible's shape language:** flowing curves, grown-looking technology, no boxy silhouettes. That covers platforms, catwalks, rails, stalls, stairs, supports and roofs.
- **It is checked at the S5 style pause.**
- **The greybox may stay blocky,** because S1 is about routes. But curved routes change how a layout feels, so `LevelGreybox` also builds **arc** pieces: an annular sector with inner and outer radius, start and end angle, and top height and thickness, walkable when it's a surface. Platforms and catwalks are drawn as arcs where the brief intends a curve.

## B7. Light, the spire and the lift (shared by every level)

- **Light:** each tier's spire segment is its key light (D-96, extended), with a range bounded by the ceiling, plus the level's practicals:
  - cultivation lights in the Garden and Farms;
  - lamps in Homes;
  - work lights in Workshops.

  The star at a stop enters flat through the band from the rim, like a low sun, and the existing handover dims the spire segment. Contact shading and ink are baked; nothing that depends on speed or the star is.
- **The spire** is visible from every stage, beside the pole line, never on it. An Archive terminal sits at the spire on every level (ship-structure).
- **The lift** serves a list of stops (data). Its `ride` view is fixed beside the shaft facing the bow and slides vertically, so the levels pass as layers ([mid-shaft mock](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/mock/lift_mid_cruise.png)). - **Speed:** today's fixed 11 s ride for one tier (`RIDE_SECONDS`) becomes a constant 6 m/s plus the existing 0.8 s transfers at each end. That is about 5 s per tier, or about 25 s from the bridge to Engineering.
- **Controls:** a key skips to arrival, and reduced motion cuts.

---

# Part C: the ship's levels, and the first run

## C1. The seven tiers, in build order

| Tier | Floor / radius | Roof | Purpose in play | Spire (ship-structure) | Order |
|---|---|---|---|---|---|
| Bridge | +82 m / 22 m | open | Decisions, navigation, the Archive shrine | the light source | landed (DL); **intricate pass later** (gallery, mast ring), after R2-BRIDGE-STYLE |
| **Commons** | +57 m / 75.9 m | the bridge's disc only; open beyond | Civic life: market, conversation courts, news; where the crew meet | faint patterns | **1: the first full run (this sprint)** |
| Garden (the forest) | +7 m / 94.7 m | the Homes slab | Canopy walks, water, remembrance paths; the emotional heart | organic veins | 2 |
| Homes | +32 m / 89.4 m | the Commons slab | Courtyard homes, clinic, school | — | 3 |
| Workshops | −18 m / 93.0 m | the Garden slab | Making quarter, academy; the tech tree made physical | geometric patterns | 4 |
| Farms | −43 m / 84.1 m | the Workshops slab | Beds, racks, algae and water | — | 5 |
| Engineering | −68 m / 65.2 m | the Farms slab | Repair, reclamation, robots, the spire's base | brightest at its base | 6 |

The Commons comes first because it is the level below the bridge (Mark: "the next level as well needs a lot of filling out"), the lift already reaches it, and it is still legacy (sector views, Z1–Z3). The Garden comes second, as the forest level Mark asked for on 2026-09-28.

## C2. The Commons brief (S0 draft, for Mark at plan approval)

The draft lives in `design_docs/levels/commons.md` (the template, filled in). In short:
- **Purpose:** the civic heart, where news from home arrives and the crew meet; intricate, busy and warm.
- **Stages:**
  - `landing` (the lift);
  - `court` (the floor, with alcove stalls to port);
  - `terrace` (the mezzanine 4 m up, to starboard);
  - `gantry` (the catwalk 9 m up, from the lift to the bow balcony);
  - `service` (the gallery under the slab, through a hatch).
- **Finds:** the notice board (news), the terrace bench (a crew anchor), the telescope on the bow balcony, and the service panel. The panel ties into crew-work's ship systems later.
- **Set pieces:**
  - the bow balcony at a stop (the body 30° off the bow, framed by the balcony rail);
  - the gantry at 0.99c (the starbow over the arcade roof);
  - the lift's ride down into the court.
- **Light:** a spire segment at about +69 m (range to the bridge's underside), stall lamps and gantry lamps.
- **Sky:** open above the outer ring; the court sees the starbow over the far rim.
- **Playtest checklist:**
  - the lift arrival shows the court and the starbow;
  - find the telescope without being told;
  - the climb to the gantry is obvious from the court;
  - the captain never vanishes under the terrace;
  - the service gallery feels enclosed.

## C3. The first full run on the Commons

The sprint covers building the pipeline and running the Commons through **S0–S6**:
- S1–S3 on the in-engine greybox, with Mark playing it;
- S4–S5 dressing it with the existing Commons kit plus new modules, on R2-BRIDGE-STYLE's finish, with Mark approving the style;
- S6 landing with its regression baseline.

The legacy Commons views and its Z1–Z3 player keys are retired in S3's dev build.

## C4. Interfaces with the sibling plans

- **Captain animation:** each route's `clip` field names what it needs:
  - `climb_ladder`;
  - `stairs` (the walk cycle on a slope);
  - `ride_idle` (the lift);
  - `sit` (benches);
  - `crouch` (crawlspaces).

  Until the clips exist, ladders and hatches are use-point transfers.
- **Sound:** each stage's `ambience` id and each practical's light type (a spire segment hum, cultivation lights, workshop noise) are in the manifest.

## C5. What still holds from the isometric-era multi-level plan

| Holds | Superseded |
|---|---|
| The spire as the anchor on every level, with a character per zone | Isometric tiles and the tilted ortho camera (D-91 to D-93) |
| Knowing there are levels above and below: the lift ride and the roof's underside in the band | Transparent cut-aways and see-through floors (floors are opaque, D-36) |
| Distinct identity per zone | 15–20 levels (now 7 tiers, D-34) |
| Terminals on every level; several ways between levels | "Up = travel" (D-92); the Go engine plan |

## C6. The physics guard

- **No painted space:** the asset check's emissive scan, as in deck-layout §D8.
- **New poses that frame the sky get the full physics gate (CLAUDE.md gate 2).** The ceiling clamp (pitch −3°, per §B3), a raised surface (the catwalk at +9 m) and the enclosed view are new camera poses, and the plan relies on where the pole and the band fall in them. They get:
  - **check values in `tests/test_physics.gd`:** the forward pole's screen position for each pose (from `ShipCamera.ship_vector`, the same mapping as F1's AC-B2), and the band's roof edge against the slab model (`atan((24 − rise)/D)`, within 0.5°);
  - **`make golden` cases G-LVL-1 (the clamp pose) and G-LVL-2 (the raised pose):** GPU vs CPU for the starbow at 0.99c, with the forward pole in frame, through each pose;
  - **reference renders that are opened**, which `level-capture` makes.
- **The existing goldens** keep their count with 0 failures, plus the two new cases.
- **Every capture is opened before a pause.**

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | The process docs exist and validate: the README, the template, and the backlog (statuses from the fixed set, one row per tier). `--next` lists only loop-eligible items, never a level in S0, S3 or S5 | `sh tools/levels_backlog.sh --check && sh tools/levels_backlog.sh --next` (a fixture with a level in S3 must not be listed) |
| AC2 | The manifest schema validates; a stage view with a turning yaw, an exit to an unknown stage and a route without both ends are each rejected | `make level-test` |
| AC3 | `LevelGreybox` builds a layout JSON with colliders; the multi-height walk keeps the captain on the nearest surface; ladders and hatches transfer | `make level-test` |
| AC4 | The camera: the slide follows the floor height without turning (yaw spread 0.0000°); the ceiling clamp eases in under an overhang and out after it; reduced motion cuts | `make camera-test camera-forward-test level-test` |
| AC5 | The evaluator reads both a greybox layout and an exported level (GLBs plus manifest, through `asset_dir`), and it reproduces the mock greybox's numbers (the positive control: 7 surfaces, 4 heights, 0 unreached, floor head behind greybox 163 → 59 with the clamp, the tower's 81 first-hit pole blocks), and seeded defects fail by name: a route removed (`unreached`), a box on the pole line (`pole-ray`), a roof lowered 5 m (`band-top`), a find walled off with no cue (`find-sight`) | `make level-eval-test` |
| AC6 | The lift serves a list of stops; the ride view slides only vertically; skip and reduced motion work; arrival selects the default stage | `make ship-demo-lift-test level-test` |
| AC7 | Per-level light: a spire segment's range ends at its ceiling; the star handover dims it; practicals load | `make ship-star-light-test level-test` |
| AC8 | The Commons greybox passes its thresholds (S2) | `make level-eval LEVEL=commons` prints `level-eval: commons ok` |
| AC9 | The dressed Commons passes the same thresholds on its export, within budgets | `make level-eval LEVEL=commons level-assets-check LEVEL=commons` |
| AC10 | The regression net: the bridge's baseline is pinned in LP0; `levels-regress` passes; it fails when another level's numbers move (a seeded change to the bridge) and when a landed level's layout sha256 changes without a change-log row | `make levels-regress` (and its two negative controls) |
| AC11 | The bridge as a one-stage level is unchanged | `make deck-layout-eval` (`deck-layout: bridge ok`) |
| AC12 | Physics goldens: the existing cases unchanged, plus G-LVL-1 (the clamp pose) and G-LVL-2 (the raised pose), 0 failures; check values for the new poses' pole position and band edge | `make golden` and `make physics` (§C6) |
| AC13 | Performance at the Commons (LP1a adds the `SCENE=level` branch to `make bench`) | `make bench SCENE=level LEVEL=commons` p99 < 16.7 ms at 2560×1440 (load logged) |
| AC14 | Captures for every pause: `level-capture` writes `metrics.json` and the listed PNGs, each with non-zero pixel variance, plus `frames.sha256`. Opening every frame and posting the per-file URLs is a stated manual gate | `make level-capture LEVEL=commons TAG=<s3\|s5\|after>` (exits non-zero on a missing or blank frame) |
| AC15 | Full suite green, including `level-test`, `level-eval-test` and `levels-regress` (wired from `mk/levels.mk`); level manifests and GLBs exported; no new Python | `make test python-guard export-filter-audit` |

Whether the Commons *feels* intricate and alive is not command-checkable: Mark judges it at S3 and S5.

## Open questions for Mark (with recommendations)

| # | Question | Recommendation |
|---|---|---|
| OQ1 | The pipeline's pauses: brief, greybox playtest and style (three per level) | **Yes, three**, batched across levels in one session |
| OQ2 | Greybox in the engine (no Blender) for S1–S3 | **Yes.** It is fast, the loop can run it, and Blender starts at S4 |
| OQ3 | Stages within a level (bounded walkable areas joined by routes) rather than the whole floor | **Stages**; big tiers land stage by stage |
| OQ4 | The camera under overhangs | **The ceiling clamp** (lower and closer, never a turn), with the evaluator holding `head` ≤ 2% |
| OQ5 | Ladders and hatches before climb animation exists | **Use-point transfers now**, switched to climbs when the clips land |
| OQ6 | What the loop may do on levels | **As §A6:** S2 evaluation, asset checks, regression and its captures (parked for you); never briefs, feel or style |
| OQ7 | First full run | **The Commons**, with the stages and finds in §C2. The intricate bridge is a later run after R2-BRIDGE-STYLE |
| OQ8 | Order after the Commons | **Garden → Homes → Workshops → Farms → Engineering** |
| OQ9 | The backlog's home | **`design_docs/levels/backlog.md`** in this repo (a table the loop parses), linked from issue #1 |
| OQ10 | Do levels open with the voyage (generations moving down the ship) or as they're built? | **As built for now**; gating by generation is a later design with crew-population |

## Evidence

**Intricate greybox mocks** (`tools/levels_intricate_mock.gd`; role colours: sand = surfaces, teal = structure, orange = routes, magenta = finds, violet = foreground, grey = landmarks). Numbers are in `metrics.json`.
- [Contact sheet](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/intricate/contact_sheet.png)
- **Commons, at 0.99c:**
  - [court floor](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/intricate/commons_floor_cruise.png)
  - [terrace](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/intricate/commons_mezzanine_cruise.png)
  - [gantry catwalk](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/intricate/commons_catwalk_cruise.png)
  - [bow balcony](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/intricate/commons_balcony_cruise.png)
- **Commons, at rest:**
  - [service gallery under the slab](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/intricate/commons_service_rest.png)
  - [court floor](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/intricate/commons_floor_rest.png)
- **Commons structure:** [diagnostic overview](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/intricate/commons_diagnostic.png) (not a game view)
- **Bridge sketch:**
  - [at the spawn](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/intricate/bridge_sketch_cruise.png) (the gallery is astern, behind the camera)
  - [on the stern gallery](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/intricate/bridge_gallery_cruise.png)
  - [on the mast ring](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/intricate/bridge_mast_cruise.png) (the needle splits the starbow)
  - [diagnostic overview](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/intricate/bridge_diagnostic.png)
- [metrics.json](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/intricate/metrics.json)

**View and sky mocks** (`tools/levels_mock_capture.gd`):
- [Contact sheet](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/mock/contact_sheet.png)
- Commons today through the Bow pose at 0.99c: [frame](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/mock/commons_bow_cruise.png)
- Garden, 60 m in from the rim: [the slit](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/mock/garden_stage_cruise.png)
- Garden, 20 m from the rim: [a proscenium](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/mock/garden_rim_stage_cruise.png)
- Homes, 20 m from the rim: [frame](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/mock/homes_rim_stage_cruise.png)
- The lift, mid-shaft: [frame](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/mock/lift_mid_cruise.png)
- [poses.json](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/mock/poses.json)

**Geometry:**
- The band table comes from `art/ship-dimensions-v2/layout.json` (slab tops every 25 m, radii by the 95 m envelope rule, a 24 m clear gap).
- The roof edge is `atan((24 − rise) / D)`, with `D` the horizontal distance from the eye to the slab rim above. The 15.7° slit matches the rendered frame.
- The captain measures 77 px at 720p in the mock (80.6 px on the bridge with the game's own camera; the mock's probe camera differs slightly).

**Independent plan review** (2026-10-20, `claude -p --model sonnet`, read-only): **74/100, PASS**, with 5 blocking findings, all fixed in this version:
- the physics gate for the new poses (§C6, AC12);
- the shared-file claim corrected, with the sprint split so LP0 and LP1a start on approval;
- the bridge baseline pinned in LP0, and the evaluator reads exported levels;
- the loop rule after S3, `levels_backlog.sh --next`, and the charter rows in the approval package (§A6);
- the `SCENE=level` bench and `mk/levels.mk` scheduled.

Its smaller suggestions are folded in too: a 16-day estimate with a cut list, a hatch fixture, the lift speed rule, checkable captures, a default `find-route` ceiling, an export-filter AC, the `bpy` note and the list of `views.json` readers.

## Deliverables

- `design_docs/planned/r2/levels.md` (this), `levels-sprint.md`, and `.ailang/state/sprints/sprint_R2-LEVELS.json` (`awaiting_approval`).
- `design_docs/levels/README.md` (the living process), `TEMPLATE.md`, `backlog.md`, and `commons.md` (the S0 brief draft).
- `tools/levels_mock_capture.gd` and `tools/levels_intricate_mock.gd` (the evidence tools; LP1 folds them into `LevelGreybox`, `level-eval` and `level-capture`).
