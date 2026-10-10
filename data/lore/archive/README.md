# The Archive: physics entries

Player-facing explanations the ship's Archive gives about the physics the crew
lives inside. They're canon (Mark, 2026-10-01, ledger D-11): "physics education
… available in-game lore". The game should be interesting *and* teach.

**Rule:** the bubble is the one invented thing, and the entries say so.
Everything else is real physics, and every number comes from a check value.

## Format

One markdown file per entry, named after its id without the `archive.`
prefix (`archive.photon-drive` → `photon-drive.md`), with YAML front matter:

```yaml
---
id: archive.photon-drive        # stable; the game refers to entries by id
title: The Photon Drive         # shown in the Archive index
unlock: first_boost             # when the entry becomes available (hint vocabulary below)
checks: [HB-7, HB-35, HB-36]    # every check-value ID whose number appears in the text
---
```

The body follows: plain prose of about 120–250 words, in the Archive's voice.
That voice is calm and precise, with a little wonder. It speaks to the crew,
not to a physicist. It gives no formulas unless one fits in a sentence.

### Unlock hints

The hints are game events. The game repo maps them to simulation state.

| Hint | When |
|---|---|
| `always` | From the start |
| `first_commit` | The first journey is committed |
| `first_boost` | The first boost begins |
| `cruise_above_0.9c` | The first cruise above 0.9c |
| `cruise_above_gamma_275` | The first cruise at γ ≥ 275, when the forward CMB glow is plainly visible |
| `first_black_hole` | The first arrival near a black hole |

## Numbers must not drift

- Check-value IDs are defined in [physics/higgs-bubble.md](../../physics/higgs-bubble.md)
  (HB-n) and [physics/relativity-spec.md §7](../../physics/relativity-spec.md)
  (RS-n). Each registry row there has one number, in the columns
  `ID | Quantity | Value | Unit`.
- **Every number in an entry's prose (and title) must match a value under one
  of the IDs in its `checks:` list**, at the significant figures shown, and
  with the unit. This includes the inputs and labels (a radius of 100 m is
  HB-1, 0.99c is HB-7, 1 g is HB-6), which are registry rows too.
- **The game repo (`stapledons-godot`) checks this by test** (`make
  lore-check`). The test parses each entry, extracts its numbers and units, and
  compares them with the registry, whose values the package and the CPU
  reference also compute.
- **Spell out counts and labels that aren't check values**: "three
  properties", "one hand-wave", "ten horizon radii". Write big numbers in the
  registry's form, `1.14 × 10⁶ g`, not "1.14 million g". Avoid digits inside
  names (say "the nearest known black hole", not its catalogue name).
- Put citation years and paper references inside `[cite: …]`, so they are not
  read as values.
- A rounded number in prose (for example "about 227 days" for 227.4 days) must
  round from the check value, never approximate it independently.
- If a check value changes, update the entries that cite it in the same change.

### Unit aliases

Prose may use the readable form; the checker treats each pair as the same unit.

| Registry | Prose |
|---|---|
| yr | years |
| min | minutes |
| deg | ° |
| sun | suns |
| M☉ | solar masses |
| r_s | horizon radii |
| K | kelvin |
| m, kg, N, J, GeV, g, % | as written |
| c (speed) | written attached: 0.99c |
| — (dimensionless) | no unit, or "a factor of" |

## Entries

| id | Topic | unlock |
|---|---|---|
| `archive.bubble` | What the bubble is, and what is invented | `always` |
| `archive.one-g` | Why you feel 1 g | `always` |
| `archive.nothing-crosses` | Why nothing can cross, and what can | `always` |
| `archive.two-clocks` | Time dilation and the two clocks | `first_commit` |
| `archive.photon-drive` | The photon drive and the cost of speed | `first_boost` |
| `archive.ism-glow` | The interstellar medium and the glow | `cruise_above_0.9c` |
| `archive.starbow` | Why the sky crowds forward | `cruise_above_0.9c` |
| `archive.weather-between-the-stars` | Clouds, dust and the drive-hold limit | `cruise_above_0.9c` |
| `archive.cmb-forward` | The blueshifted cosmic background | `cruise_above_gamma_275` |
| `archive.tides` | Tides near black holes, and why Sgr A* is safe | `first_black_hole` |
| `archive.shadow-ring` | The black hole's shadow and the Einstein ring | `first_black_hole` |
