# Level: Bridge (`bridge`), deck layout v2 (DL)

**Tier:** +82 m, radius 22 m, open to the sky (the top of the mast). **Stage of the pipeline:** landed (R2-DECK-LAYOUT DL0–DL3). The intricate pass (a stern gallery, a ring walk around the mast) is a later run, after R2-BRIDGE-STYLE ([sketch](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/intricate/bridge_mast_cruise.png)).
**Concept refs:** `art/ship-tier-concepts-v1/bridge.png`; [deck-layout.md](../planned/r2/deck-layout.md); R2-BRIDGE-STYLE. **Ledger:** D-90, D-94 to D-97, D-100, D-104.

## Purpose
Decisions, navigation and the Archive shrine, with the helm at the bow rail facing the journey.

## As a level
- **The manifest** is `assets/levels/bridge/manifest.json`: one stage, `deck`, measured on the shipped walk. The game still reads the bridge's views from `data/camera/views.json` until R2-LEVELS LP1b.
- **The baseline** is `art/levels/bridge/baseline.json`, which `make levels-regress` checks.

## Rulings
| Date | Ledger | Ruling |
|---|---|---|
| 2026-10-20 | D-95 to D-97 | Layout A; the blockout and the DL2 finish accepted |
| 2026-10-20 | D-104 | Curves, not boxes (R2-BRIDGE-STYLE reshapes the hero props) |

## Change log
| Version | Date | What changed, and why any baseline was re-pinned |
|---|---|---|
| v1 (manifest sha256 fc61ee5e) | 2026-10-20 | R2-LEVELS LP1a: the bridge measured as a one-stage level; first baseline pinned |
| v1 (manifest sha256 fc61ee5e) | 2026-10-21 | Re-pinned after R2-BRIDGE-STYLE (#300) regrew the hero props with curves (D-104): `near_bow` 0.021 -> 0.017 (less of the bow near field taken). Layout unchanged; deck-layout-eval passes on the grown props. |
| v1 (manifest sha256 fc61ee5e) | 2026-10-22 | Re-pinned after R2-BRIDGE-STYLE ST3–ST5 (#322): the rest of the bridge grown (D-104), the rim fronds turned into painted cards (D-106) and the authored lift head: `near_bow` 0.017 -> 0.003 (the bow's near field is now almost clear), the captain's px range [76.9, 81.1] -> [76.9, 76.9]. Layout unchanged; deck-layout-eval bridge ok. |

| v1 (manifest sha256 acb2de37) | 2026-10-29 | VF1/LP1b moves the identical approved camera values, occluders and dressing into the level manifest; source hash updated, measured regression fingerprint unchanged. |
