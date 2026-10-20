# Level backlog

**One row per level, in ship order.** Mark and the mission loop read this table. `tools/levels_backlog.sh --check` (R2-LEVELS LP0) validates it.

- **Stage** is one of: `S0-brief`, `S1-greybox`, `S2-evaluate`, `S3-playtest`, `S4-dress`, `S5-style`, `S6-land`, `landed`, `S7-revisit`, `not-started`.
- **Who** is `attended`, `loop` or `none`.
- **Next pause** names Mark's next pause (S0, S3 or S5), or `—`.

| Order | Level | Id | Tier (floor / radius) | Stage | Layout | Who | Next pause | Last ruling | Doc |
|---|---|---|---|---|---|---|---|---|---|
| 0 | Bridge | `bridge` | +82 m / 22 m | landed | DL v2 | attended | — (intricate pass after R2-BRIDGE-STYLE) | D-97 | [deck-layout.md](../planned/r2/deck-layout.md) |
| 1 | Commons | `commons` | +57 m / 75.9 m | S1-greybox | — | attended | S3: play the greybox (after R2-LEVELS LP2) | D-103 | [commons.md](commons.md) |
| 2 | Garden (the forest) | `garden` | +7 m / 94.7 m | not-started | — | none | S0 after the Commons' S3 | — | — |
| 3 | Homes | `homes` | +32 m / 89.4 m | not-started | — | none | — | — | — |
| 4 | Workshops | `workshops` | −18 m / 93.0 m | not-started | — | none | — | — | — |
| 5 | Farms | `farms` | −43 m / 84.1 m | not-started | — | none | — | — | — |
| 6 | Engineering | `engineering` | −68 m / 65.2 m | not-started | — | none | — | — | — |

**Cadence:** two levels in flight. The Garden's S0 brief is drafted while the Commons is in S4–S5.
