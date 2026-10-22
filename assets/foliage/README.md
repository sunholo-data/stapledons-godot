# Foliage cards (D-106 painted foliage, R2-BRIDGE-STYLE S5)

| File | Kind | Source | Pin |
|---|---|---|---|
| `frond.png` | frond (a potted palm frond with bromeliads; the bridge's ten rim fronds) | The plants spike (PR #299, `design_docs/planned/r2/stylised-plants-spike.md`): painted by the art pipeline, `codex exec -m gpt-6.1-sol` built-in image_gen, subscription lane, 2026-10-20; master 1024² at `gs://stapledons-voyage-assets/refs/plants/spike/cards/frond.png` (sha256 fbff80f10a890e71caa69c52ac94dddcc9cb4d1202a76a982e085e31b3701d6b), resized here to 512² (Lanczos, macOS sips) | `ui/theme/pins.json` |

Painted evenly lit (no baked light direction), transparent background, base anchored at the bottom centre.
The game draws them as cards in the shared toon material's card mode (`shaders/stapledon_toon.gdshader`):
alpha-cut, lit through a rounded normal, turned toward the camera within ±25° of their authored facing.
