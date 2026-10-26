# Foliage cards (D-106 painted foliage, R2-BRIDGE-STYLE S5)

The bridge's ten rim plants mix three kinds in a ring where no two neighbours match, with a seeded height,
mirror and palette tint each (manifest `style.foliage`). The final per-kind painted set comes with the R2-LEVELS
foliage library (D-106); vines (the spike's fourth card) hang from rails and wait for it.

| File | Kind | Source | Pin |
|---|---|---|---|
| `frond.png` | frond (a potted palm frond with bromeliads; the bridge's ten rim fronds) | The plants spike (PR #299, `design_docs/planned/r2/stylised-plants-spike.md`): painted by the art pipeline, `codex exec -m gpt-6.1-sol` built-in image_gen, subscription lane, 2026-10-20; master 1024² at `gs://stapledons-voyage-assets/refs/plants/spike/cards/frond.png` (sha256 fbff80f10a890e71caa69c52ac94dddcc9cb4d1202a76a982e085e31b3701d6b), resized here to 512² (Lanczos, macOS sips) | `ui/theme/pins.json` |
| `shrub.png` | shrub (a flowering shrub, no pot: it stands on the deck) | the plants spike, as frond.png; master sha256 a7f3ed7a15d0407ce6cac3c64dee3765bb18b720acb9b6b014eaf3efe8c08ceb, resized to 512² | `ui/theme/pins.json` |
| `grown_planter.png` | grown planter (a lily in a grown, ribbed vessel) | the plants spike, as frond.png; master sha256 22057e777d3efe3b51f944ad2b33554541a278b3ce293fdd8cf6977d3e7d0697, resized to 512² | `ui/theme/pins.json` |

Painted evenly lit (no baked light direction), transparent background, base anchored at the bottom centre.
The game draws them as cards in the shared toon material's card mode (`shaders/stapledon_toon.gdshader`):
alpha-cut, lit through a rounded normal, turned toward the camera within ±25° of their authored facing.
