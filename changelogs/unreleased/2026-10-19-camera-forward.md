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
  Bow; a guided stop now turns the ship so the body sits 30° off the bow, inside the frame. Zoom
  levels are developer presets on the bridge; the Commons keeps its views for now.
- Braking notice: "Braking. The bow is still the way we are travelling."
