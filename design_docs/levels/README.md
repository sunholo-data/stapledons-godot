# Levels: how we build them

**This is the living process doc for the ship's levels.** The design and rationale are in [R2-LEVELS](../planned/r2/levels.md) (Part A). Where every level stands is in [backlog.md](backlog.md), and each level has a one-page doc made from [TEMPLATE.md](TEMPLATE.md).

Mark, 2026-10-20: "ongoing we have a lot of levels to work on - I can see that being just a continuous job that evolves over time so we need a good working process for it".

## The model in one paragraph

The ship has seven tiers on the generator mast, and travel runs toward the bow. Each tier is a **level**, and a level is a set of **stages**: bounded walkable areas with several heights (floors, terraces, catwalks, crawlspaces) joined by **routes** (stairs, ladders, hatches, exits, the lift). Each stage is seen through fixed **views** that slide with the captain and never turn: Bow and Astern, a ceiling clamp under overhangs, and a low, close view for crawlspaces. Beyond the stage, the rest of the tier is visible at its true depth for parallax. The sky is always the live render.

## The lifecycle (⏸ = Mark)

| # | Stage | Who | Output | Done when |
|---|---|---|---|---|
| S0 | Brief | attended | `design_docs/levels/<id>.md` from the template | ⏸ Mark approves |
| S1 | Greybox | agent or loop | `art/levels/<id>/layout.json` (vN), built in-engine by `LevelGreybox` | `make level-eval LEVEL=<id>` runs |
| S2 | Evaluate | **loop** | metrics against `art/levels/<id>/thresholds.json`; iterate the layout | `level-eval: <id> ok` |
| S3 | Playtest | attended | dev build, contact sheet, per-file URLs, the checklist | ⏸ Mark plays; ruling recorded |
| S4 | Dress | agent (renders park) | Blender export from the same layout: hero, coarse, walk, cards, manifest | `level-assets-check`, `level-eval` on the export |
| S5 | Style | attended | style frames on the R2-BRIDGE-STYLE finish; the shape language checked (curves, no boxy silhouettes, D-104) | ⏸ Mark approves |
| S6 | Land | loop mechanics, Mark merges | `rig/full`, goldens, `art/levels/<id>/baseline.json` pinned | merged; backlog `landed vN` |
| S7 | Revisit | either | layout vN+1 re-enters at S1 (or S4) | every other level's baseline still green |

**Cadence:**
- **Two levels in flight:** one in S1–S3 while another is in S4–S5.
- **Batched pauses:** one attended session can approve a brief, play a greybox and approve a style.
- **Big tiers land stage by stage.**

## Commands (every level uses the same ones)

```sh
make level-eval LEVEL=<id>                  # S2: traversal, readability, sightlines, sky band, budgets
make level-eval LEVEL=<id> LAYOUT=<json>    # score a candidate layout in-engine (search only)
make level-capture LEVEL=<id> TAG=<stage>   # Bow/Astern per stage and surface, 0.99c, a stop, set pieces, sheet
make level-assets-check LEVEL=<id>          # S4+: pins, budgets, opaque, no painted emission
make levels-regress                         # every landed level against its baseline (in make test)
sh tools/levels_backlog.sh --check          # the backlog parses; statuses valid
```

Upload the frames to `gs://stapledons-voyage-assets/refs/levels/<id>/<tag>/`, and give Mark **per-file URLs** (the bucket has no folder listing) plus the contact sheet.

## The loop and attended sessions

- **The loop may:**
  - run S2 against thresholds Mark approved;
  - run `level-assets-check` and `levels-regress`;
  - make regression captures, which it uploads and **parks** for Mark (`[LOOP+RENDER]`);
  - do backlog bookkeeping and upstream repros.
- **Attended only:** S0 briefs, layout feel, S3 playtests, S5 style and art direction, finds or set pieces that touch story or lore, changes to thresholds.
- **A level in S0, S3 or S5 is on the charter's do-not-touch line.**

## Feedback and rulings

- **Each pause gets:** a contact sheet, per-file URLs, and the level doc's 5–8-line playtest checklist. Mark answers one line per item.
- **Attended rulings** go straight into the ledger (`mission_answer.sh`) with the level id, and into the level doc's **Rulings** section with the ledger id. **Remote rulings** come in on issue #1.
- **Then update `backlog.md`:** stage, version, last ruling and next pause.

## Revisiting without breaking other levels

- `layout.json` carries `version`, and the manifest pins the layout's sha256. Blender masters are in the bucket by sha256.
- `art/levels/<id>/baseline.json` pins the level's evaluator numbers. `make levels-regress` runs every landed level, so a shared-code change that moves another level fails.
- **Re-pinning a level's own baseline** is a deliberate change: same commit, with the reason in the level doc's change log.

## The design vocabulary (what "intricate" means, D-100)

| Element | Examples |
|---|---|
| Heights and routes | mezzanines, terraces, catwalks, stairs, ramps, ladders, hatches, crawlspaces |
| Alcoves and thresholds | stalls, doorways, arcade bays, niches at the spire |
| Layers | foreground beams and planters; the stage; midground structure; far landmarks; the roof's underside; the sky band |
| Things to find | each with a `cue` if it can't be seen from the stage's first view |
| Reasons to traverse | finds, crew anchors, use points, set pieces worth the climb |
| Reveals | the starbow over a roof edge once you climb; the spire through a gap |
| Set pieces | a bow balcony at a stop; an eclipse through the sky band (D-96) |

**Shape language (D-104):**
- **From S4 dressing on, structures follow the art bible:** flowing curves, grown-looking technology, no boxy silhouettes (platforms, catwalks, rails, stalls, stairs, supports, roofs). Mark checks it at the S5 style pause.
- **The greybox may stay blocky,** because S1 is about routes. Use `arc` pieces for platforms and catwalks the brief means to curve, because a curved route changes the feel.
- **Plants:** the stylised-plants spike owns them. A level only places them through `layers.foliage[]` in its manifest.

**Placement rules:**
- **Keep landmarks off the pole line.** The evaluator's `pole-ray` catches them.
- **Journey stages sit within about 30 m of a bow or stern rim,** so they get a tall sky band.
- **Inward stages are the enclosed ones.**
- **The spire is beside the pole line, never on it.**
