### Fixed

- **The M1 sky was a mirror image of the real sky (D-28, Mark, attended 2026-10-03).** The
  galactic → Godot map `(x, y, z) → (y, z, −x)` had determinant −1, a reflection. Stars, the
  NOIRLab panorama, the sky model, the forward CMB and the galaxy map all rendered left-right
  reversed. The GPU-vs-CPU goldens could not see it because both sides shared the map; the
  M4.2 evaluation found it, and M4.2 had undone it locally with `SKY_FLIP_H`.
  - One right-handed map, `(x, y, z) → (−y, z, −x)` (det +1), and its inverse
    `(x, y, z) → (−z, −x, y)`, are now defined once: `sky/sky_frame.gd` (`SkyFrame`, Vector3
    and float64 forms) and `sky/sky_frame.gdshaderinc` for shaders. The hand copies in
    `starfield.gd`, `sky_model.gd`, `background.gdshader`, `interior_sky.gd` (three),
    `interior_smoke.gd`, `interior_golden.gd` (two), `main.gd` and `test_physics.gd` (two)
    are gone. `Starfield.galactic_to_world` keeps its name and now calls `SkyFrame.to_world`;
    `Starfield.world_to_galactic` is new.
  - The interior's local flip is removed: no `Interior.SKY_FLIP_H`, the sky texture is shown
    as rendered, and G-M4-2 / G-M4-4(c) no longer mirror columns. G-M4-1..4 pass without it.
  - Views: facing the galactic centre with the north galactic pole up, **starboard (KEY_2,
    yaw −90°) now looks at l 270** (Vela, Canopus, α Cen, the LMC) and **port (yaw +90°) at
    l 90** (Cygnus), as on a real ship. The yaw sign and the KEY_1–4 bindings were already
    right; only what the sky put there was mirrored. The named yaws are `main.gd`
    `VIEW_YAW`.
  - The galaxy map is now the real neighbourhood, not its reflection: seen from the NGP side,
    longitude turns counter-clockwise.
- New tests: `make physics` `test_sky_frame` (det +1, round trips, the shader include
  evaluated against `SkyFrame`, a guard that fails on any hand copy of the map, and an oracle
  of real objects through the free-look camera: Antares and α Cen right of the centre, Vega
  and the Scutum cloud left, Orion's belt Alnitak–Alnilam–Mintaka left to right, the LMC
  right of and below Acrux, the starboard/port/astern longitudes, and the LMC and SMC bright in
  the NOIRLab panorama where the frame puts them, 9.4x and 6.9x their mirror positions);
  `make ui` `test_handedness` (galaxy map); `make interior-test` (no flip, det +1).
- `bridge/sim_bridge.gd` declared `want_minor` twice after merging #101 and #102, so `main.gd`
  failed to parse on main; the second declaration is removed.
- Regenerated reference renders: `docs/m1.3`, `docs/m1.6b`, `docs/m1.8`, `docs/m1.7`,
  `docs/m2.6a`, `docs/m2.6b` (images), `docs/contact_sheet.png`, `docs/sky_b099_forward.png`;
  before/after sheets in `docs/d28-sky-frame/`. The stand-off golden uses the mirror of its old
  geometry, which keeps the 0.4 AU case's power (float32 from Sol: 8.17 / 1.90 px, ≥ 1.5 px).
