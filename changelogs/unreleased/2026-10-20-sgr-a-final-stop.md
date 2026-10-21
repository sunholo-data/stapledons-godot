### Fixed

- **Sgr A* sat behind the ship after the guided voyage.** The Sgr A* visit set the ship's heading on
  the hole but kept the guided tour's last attitude, and the sky is oriented by that attitude when
  one is set. After the tour (heading for Aldebaran, almost opposite the galactic centre) the hole
  rendered 170° astern. The attitude now belongs to the session that set it: leaving a session
  clears it, and the Sgr A* visit sets its own, nose on the hole. Free navigation after the tour had
  the same stale attitude and is fixed too.
- `make camera-forward-test` AC-V13 checks the hole on the rendered sky (the sky camera the player
  sees through) after a guided voyage, at every stop. AC-V6 had recorded Sgr A* only in a fresh
  session with no tour, so it never met the stale attitude.

### Changed

- **Sgr A* is the guided voyage's last stop** (Mark, attended 2026-10-20). After the Aldebaran stop
  dwells like every other (12 s of tour time, or Skip dwell [N]), the tour hands over to the Sgr A*
  visit, announced as a demonstration jump with the hole ahead in the Bow view. The HUD reads
  "GUIDED VOYAGE · FINAL STOP · SGR A*". The navigation station's entry still opens it directly.
  `make guided-finale-test` (21 checks) drives the tour's final leg the honest way. The tour card's Skip dwell stays offered at the final stop.
- `make bh-ahead-capture` (GPU window): the final stop and every Sgr A* stop after flying the last leg, Bow view with the HUD, with the hole's angle off the sky camera's axis in the manifest.
