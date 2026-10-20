### Changed

- **Travel runs along the deck, toward the bow** (D-92, amends D-14). The ship's direction of travel
  is now a horizontal axis in the deck plane, so the journey and the deck share one frame. One named
  map per frame: `ShipCamera.ship_vector` / `gltf_from_ship` (kinematic) and
  `ShipFrame.gltf_from_structure` (Blender structure); `make basis-gate` fails on any inline copy.
  No physics formula, sim, protocol or replay changed; the GPU goldens re-posed one for one (393).
- **A fixed bow camera** (R2-CAMERA-FORWARD F1, D-91, D-93). On the bridge the camera looks over the
  captain toward the bow and slides with the captain without ever turning: W is always up the
  screen. 7 Bow (default), 9 Astern, R back to Bow; 8 reserved. The spire and the lift fade while
  they hide the captain or the journey. Every cue (departure, braking, a stop, Sgr A*) returns to
  Bow; a guided stop now turns the ship so the body sits 30° off the bow, inside the frame, and at
  Sgr A* the hole sits on the bow at every stop. Zoom levels are developer presets on the bridge;
  the Commons keeps its views for now. The old sky views (Sky ahead, to the side, astern) are gone
  as player views; they remain only as tool and golden poses.
- Braking notice: "Braking. The bow is still the way we are travelling."
- Developer tooling: `make camera-views-capture` renders Bow, Astern, the Commons and the lift at
  rest, 0.99c, a guided stop and Sgr A* (plus a forced-fade frame and a real voyage at 0.9/0.99/
  0.999c), gated on the pole, the stop body or the hole being in frame. `make camera-forward-targets`
  records the live stop and Sgr A* targets the camera test checks. A fresh clone now gets
  `data/raw/.gdignore` from `make sky-assets`, and `make publish-dev` fails with the fix
  (`make ai-core-assets`) instead of publishing a build without the core layer.
