# Original-desk operator placement correction (VFB)

Mark rejected the extension silhouette and clarified the intended correction:
"I think just the captain avatar is misplaced? they should be leaning on the
console? just make it look non surprising". The previous fixed operator-position
constraint is released for this contact correction. **No furniture extensions
are loaded.** Original desks and painted sprite textures remain.

The original low-console use points stand two metres stern of the desk centre,
about 1.17 m behind the nearest desk bound. The accepted flat held-pose paintings
put their palms near the feet's billboard plane. That combination leaves the
captain gesturing over an obvious empty gap.

A read-only probe advances the actual foot point toward each original desk in
2.5 cm steps, checking the actual WALK and a full 0.35 m-radius / 1.8 m capsule
against the enabled collision world. WALK alone permits 0.925 m for Voyage and
0.975 m for Crew, but the original desk colliders first intersect the body at
0.825 m at both consoles. The corrected real working points advance **0.775 m**,
leaving a 2.5 cm reserve from the last sampled safe point (0.8 m).

| Station | Original ship XY | Corrected ship XY |
|---|---|---|
| Voyage | −7.829, 10.207 | −7.829, 10.982 |
| Crew | 8.479, 12.169 | 8.479, 12.944 |

The captain stays on the original bridge floor at +82 m. Corrected movement and
Walk-to destinations must be these same feet; the renderer receives no separate
position offset. The standing-only trial closed much of the gap but retained front-facing hand
separation. The final study keeps the accepted held-pose textures and adds a
bounded 15-degree work lean toward the bow about the physical foot anchor. The
render origin stays on the corrected real feet; head reach is at most 0.455 m.
Both destinations are installed in the runtime manifest and layout metadata.
Independent screen anchors preserve the idle labels in their original housings:
the old screen-placement rule depended on the operator's distance and would
otherwise bury the labels when the captain approached.

## Verification

`godot --headless --path . --script tools/bridge_operator_probe.gd` writes the
full approach/capsule sample log under `build/bridge-operator-probe.json`.
The probe freezes `_process`, never `process_mode`, because disabling the scene's
process mode removes its collision objects from physics and would falsely report
clearance. The independent negative control catches the real desk 5 cm deeper
than the proposed foot point.

`make bridge-operator-test`: 44 passed, zero failures. It checks actual WALK support, continuous 0.025 m
stepping, the real Walk-to path ending at the corrected point, full-capsule
clearance and the deeper-collision negative, and rendered feet equaling physical
feet. It also checks original screen anchors, working/reduced-motion poses,
reset on leaving, and that no proposed support mesh is loaded.
The real E/open entry is also exercised from the former in-reach point: no
teleport or distant contact pose, ordinary 1.3 m/s walking, WASD cancellation,
Esc cancellation and panel opening only after arrival at the corrected physical destination.

`tools/bridge_operator_review.gd` prepares matched actual Bow/Astern current and
corrected frames, with 320px native crops enlarged to 640px to show both feet and
hands. Eight matched 1280x720 engine frames, detail crops and contact_sheet.png are
recorded under renders/view-finish/operator-placement/. Voyage/Crew front and
back crops were opened and inspected: the palms now meet the original console
edge and the feet remain grounded. The standing-only diagnostic is retained
under ignored build/operator-standing-only. The final comparison has no custom
furniture. It retains +2-stop/4x sky display aid, frozen rest world and no HUD.
The corrected frames use the installed shared runtime shader and destinations;
the previous position and flat pose are reconstructed only for before frames.

## Runtime implementation

Corrected real use points drive movement/Walk-to as well as the renderer.
The shared interior/captain_fx.gdshader adds a default-zero working lean to
the existing fixed-Y billboard: its local up column rotates toward world bow,
while the model origin is unchanged. CaptainAvatar drives it only for
Voyage/Crew low-console use/leave poses, with the existing reach/leave timing.
Other clips keep the zero default.
The 15-degree posture is static under reduced motion; no new sway is proposed.

GPU harness exited 0 with 8 frames, no script errors. Existing image-import and
shutdown RID warnings remain. Tests preserve collision processing while frozen
and reject a deeper body intersection; they also hold lean direction/angle and
maximum head reach. No Blender models, textures or furniture pins changed.

The guard requires the actual station working destination to equal the corrected
physical point by default (`-- --installed` is also accepted). The historical
`-- --source-study` mode is for the pre-installation revision only.
The earlier loops, desk leaves and custom
study shader are historical review artifacts; none is loaded by gameplay.
