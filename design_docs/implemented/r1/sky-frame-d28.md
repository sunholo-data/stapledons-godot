# Sky frame fix: the M1 sky was a mirror image (D-28)

- **Status:** Implemented 2026-10-03 (PR `fix/sky-mirror`; merge waits for Mark's review of
  the regenerated renders, gate 2).
- **Release / milestone:** R1, a fix across M1 (sky), M2.6 (galaxy map) and M4.2 (interior).
- **Ruling:** D-28 (Mark, attended 2026-10-03): fix the mirror at the source, one map, no
  local flips.
- **Found by:** the M4.2 evaluation
  (`.ailang/state/evaluations/eval_R1-M4-JOURNEY-M4.2_round_1.json`), confirmed four ways.
- **Implements:** `stapledons-design/physics/relativity-spec.md` §2 (aberration, Doppler,
  beaming). The angles it specifies are unchanged; only the handedness of the
  galactic → engine map was wrong. The spec does not state the frame today; see
  "Design-repo note" below.

## Game vision alignment

Scored with the `game-vision-designer` skill's pillars. This is a correctness fix with no
gameplay change, so only one pillar is touched. Verdict: **ALIGNED** (net +2), go.

| Pillar | Relevance | Score | Notes |
|---|---|---|---|
| Hard sci-fi authenticity (physics truth) | ++ | +2 | The sky you see is the real sky, not its mirror image: Antares and α Cen right of the galactic centre, the LMC where it is, starboard really is l 270. Checked by an independent real-sky oracle, not only by GPU = CPU |
| All other pillars | 0 | 0 | No change to choices, time, the ship or the story |

## Problem

`Starfield.galactic_to_world` mapped galactic `(x, y, z)` to Godot `(y, z, −x)`. That matrix
has determinant −1: a reflection. Every M1 view (catalogue stars, the NOIRLab panorama, the
sky model, the forward CMB) and the galaxy map rendered as the mirror image of the real sky.
For example, facing the galactic centre with the north galactic pole up, Antares and α Cen
appeared on the left and Vega on the right; the "port" capture showed l 270 (Vela, the LMC),
which is a real ship's starboard side.

The GPU-vs-CPU goldens could not see it, because the shader and the CPU reference used the
same map. Also, the map was hand-copied in about ten places (GDScript, the background shader,
the interior, tools and tests), and M4.2 compensated locally with `Interior.SKY_FLIP_H`.

## Design

**One map, defined once.**

| | |
|---|---|
| galactic | IAU: x toward the galactic centre, y toward l 90, z to the north galactic pole (NGP) |
| world | Godot: Y up, cameras look down −Z, screen right = forward × up = +X |
| galactic → world | `(x, y, z) → (−y, z, −x)`, R = [[0, −1, 0], [0, 0, 1], [−1, 0, 0]], det R = +1 |
| world → galactic | `(x, y, z) → (−z, −x, y)` = Rᵀ |
| GDScript | `sky/sky_frame.gd` (`SkyFrame.to_world`, `to_galactic`, float64 `to_world64`, `to_galactic64`, `world_dir_lb`, `lb_of_world`) |
| shaders | `sky/sky_frame.gdshaderinc` (`sky_galactic_to_world`, `sky_world_to_galactic`), included by `background.gdshader` |
| public API | `Starfield.galactic_to_world` keeps its name and calls `SkyFrame.to_world`; `Starfield.world_to_galactic` is new |

The galactic centre stays at world −Z (Godot's forward) and the NGP at +Y. Only the sign of
world X changes: l 270 is now +X (right), l 90 is −X (left). The panorama's own texture
convention (u = 0.5 − l/360, l growing leftward, D-10) is unchanged, and so is
`SkyModel.equirect_uv ∘ SkyFrame.to_world`, which is the identity in (l, b). That is why the
destar pipeline and the panorama registration are unaffected, and why stars and panorama stay
aligned.

**Removed copies.** `sky/starfield.gd` (the function and the catalogue loader),
`sky/sky_model.gd` (both directions), `sky/background.gdshader`, `interior/interior_sky.gd`
(ship position, the glow's world → galactic, `_to_world`), `interior/interior_smoke.gd`,
`tools/interior_golden.gd` (both directions), `main.gd` (the stand-off golden) and
`tests/test_physics.gd` (two). A test now fails if any copy comes back.

**Interior.** `Interior.SKY_FLIP_H` is deleted and the sky texture is composited as rendered.
`tools/interior_golden.gd` no longer flips the SubViewport image (G-M4-2) or mirrors the pixel
column (G-M4-4(c)). The ship frame (`ShipFrame`) was already right-handed, so with a rotation
in between, the panorama camera sees what `cam_<area>.json` describes.

**Views and labels.** `FreeLookCamera` yaw is positive to the left, and the key bindings were
already consistent with Godot's camera (KEY_1 forward, KEY_2 starboard at yaw −90°, KEY_3
astern, KEY_4 up; the left arrow turns left). What was wrong was the sky behind them. The
named yaws now live in `main.gd` `VIEW_YAW`, and the tests read them from there:

| View | Yaw | Looks at (before D-28) | Looks at (now) |
|---|---|---|---|
| forward (KEY_1) | 0 | l 0 | l 0 |
| starboard (KEY_2) | −90° | l 90 (Cygnus) | **l 270** (Vela, Canopus, α Cen, the LMC) |
| port (captures) | +90° | l 270 | **l 90** (Cygnus) |
| astern (KEY_3) | 180° | l 180 | l 180 |

**Galaxy map.** Its stars, ship marker and scale rings all go through
`Starfield.galactic_to_world`, so the map is now the real neighbourhood. The default orbit
camera sits on the NGP side (pitch −0.45), where longitude must turn counter-clockwise on
screen. Drag and zoom are unchanged.

## Tests (written first)

| Check | Command |
|---|---|
| det [to_world(x̂) to_world(ŷ) to_world(ẑ)] = +1, det R = +1, x̂ × ŷ → ẑ kept, round trips exact (Vector3 and float64) | `make physics` (`test_sky_frame`) |
| The shader include's two return expressions, evaluated with Godot's `Expression`, equal `SkyFrame`; `background.gdshader` includes and calls it | `make physics` |
| No hand copy of the map in any `.gd` / `.gdshader` / `.gdshaderinc` outside `sky/sky_frame.*` (backreference regexes) | `make physics` |
| Oracle (SIMBAD l, b through the real `FreeLookCamera`): facing the centre with the NGP up, Antares (l 352) and α Cen A (l 316) are right of centre, Vega (l 67) and the Scutum cloud (l 27) left, and Antares is above the plane | `make physics` |
| Catalogue path: α Cen A and Vega from `stars.json` through `Starfield.append_catalogue` land right and left of centre | `make physics` |
| `VIEW_YAW`: starboard looks at l 270, port at l 90, astern at l 180 | `make physics` |
| Orion's belt, facing Alnilam with the NGP up: Alnitak, Alnilam, Mintaka from left to right | `make physics` |
| Facing l 290, b −16: the LMC is right of and below Acrux | `make physics` |
| Panorama (u, v) at each oracle object's world direction equals its (l, b); in the NOIRLab panorama the LMC and SMC are 9.4× and 6.9× brighter than their mirror positions (this check is skipped without `make sky-assets`, as in CI) | `make physics` |
| Galaxy map: the default camera is on the NGP side, l 90 is counter-clockwise of l 0 on screen, and α Cen's l 316 is clockwise | `make ui` (`test_handedness`) |
| Interior: the sky is unflipped, `SkyFrame` det = +1, and `SKY_FLIP_H` no longer exists | `make interior-test` |
| GPU vs CPU: the M1.6b 144 off-axis cases + 16 background markers, the stand-off, WD, cull, exposure, CMB, and G-M4-1..4 without the flip | `make golden` |

Mutation check: with the old map restored in `SkyFrame`, 21 physics checks and both map
handedness checks fail. With one hand copy planted in a test file, the guard names it.

## Renders

Every reference render is regenerated and opened (gate 2). The `docs/` copies are committed;
`docs/d28-sky-frame/` holds before/after sheets for review (before on the left):

- `sky_rest_before_after.jpg` (at rest, gain 4): forward, starboard, port, astern. Facing the
  centre, the ζ Oph HII region (Sh 2-27, l 6, b +24) is now up and to the LEFT of centre.
  Starboard shows Vela and Carina with the LMC below and just left of centre (l 280 is left of
  l 270). Port shows Cygnus and the Great Rift. Astern, Barnard's Loop is on Orion's east (left)
  side.
- `exposure_starboard_before_after.jpg`: the M1.5a sheet. At 0.99c the blueshifted forward sky
  enters the starboard view from the left edge, where the bow is, both before and after: the
  camera geometry was always right. What changed is which part of the sky (and which stars)
  appear there: at rest the view now shows l 270 (Vela, Carina, the LMC below centre) instead
  of l 90.
- `galaxy_map_before_after.jpg`: the neighbourhood un-mirrored, with the same panel numbers.
- `interior_before_after.jpg`: the M4.2 bridge at rest, in the 0.99c cruise and on arrival. It
  is visually identical, as it should be: the old local flip had already produced the true
  view, and now the source does.

`renders/m4` (the interior captures) and `renders/exposure_sheet.png` are not tracked; both
were regenerated and inspected. `docs/m1.4a`, `docs/m1.4d`, `docs/catalogue-longitude-fix`
and `docs/m1.7/destar_before_after.png` are in panorama texture space and are unchanged. The
M2.6 panel JSON dumps are left as they were: the frame does not touch them, and today's panel
has more rows than the M2.6 one.

The stand-off golden (`main.gd` `_golden_standoff`) uses the mirror image of its old
side-offset and 8° look-aside. Its 0.4 AU case must keep "float32 from Sol" at 1.5 px or more
(the power requirement), and it now reads 8.17 / 1.90 px.

Website media that needs re-rendering (`make site-media`, not deployed by this PR): every
clip (hero, voyage, lookaround, map, cmb) and its poster, the gallery stills taken from sky
and map captures (`website/static/img/gallery/sky-*.jpg`, `cmb-gamma-*.jpg`, `map-*.jpg`), and
`website/static/img/decisions/exposure-sheet.jpg`. `milky-way-destarred.jpg` is the panorama
in its own texture space and is unaffected. Older news posts keep their dated images.

## Design-repo note (proposed, not edited here)

`physics/relativity-spec.md` does not state the coordinate frame, so the mirror was not a
spec violation and no spec check value changes. Proposed addition (a short "Frames" note in
§2, or the notation list):

> Directions are galactic Cartesian (IAU: x to the galactic centre, y to l 90, z to the north
> galactic pole). Any map into an engine frame must be a proper rotation (det +1). Check:
> facing the galactic centre with the NGP up, Antares (l 352) and α Cen (l 316) appear to the
> right and Vega (l 67) to the left; galactic longitude grows to the left.
