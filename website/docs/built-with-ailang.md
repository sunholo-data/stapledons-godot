---
title: Built with AILANG
sidebar_position: 4
description: How Stapledon's Voyage is built - a Godot 4 renderer and an AILANG simulation on the bytecode VM, talking NDJSON, with deterministic replay.
---

# Built with AILANG

**Godot 4 renders the game. An AILANG simulation runs as a child process and talks
newline-delimited JSON over stdin and stdout.** The decision and its reasons are in
[ADR 0001](https://github.com/sunholo-data/stapledons-design/blob/main/decisions/0001-engine-and-architecture.md).

```text
┌─────────────────────────────┐   one NDJSON line per tick   ┌──────────────────────────────┐
│ Godot 4.7 (Forward+, Metal) │ ───── input: intents ──────▶ │ AILANG simulation            │
│  starfield + sky shaders    │                              │  sim/ship.ail   I/O shell    │
│  galaxy map, HUD, input     │ ◀──── state: changes ─────── │  sim/core.ail   pure core    │
│  draws what the sim says    │                              │  sunholo/relativity (pinned) │
└─────────────────────────────┘                              └──────────────────────────────┘
```

## The simulation

- **The world state lives in AILANG.** Ship, the two clocks, journeys, the commit rule, the energy
  ledger and the random streams are all simulation state. Godot sends player intents and draws
  the state it gets back.
- **A pure core on the bytecode VM.** `sim/core.ail` passes `--strict-bytecode`: it runs entirely
  on the AILANG VM with no interpreter fallback. I/O lives only in the thin `sim/ship.ail` shell.
- **Physics from one package.** The formulas come from
  [`sunholo/relativity`](https://github.com/sunholo-data/ailang-packages/tree/main/packages/relativity),
  a published AILANG package with its own tests and check values. The simulation pins a version;
  GDScript and the shaders mirror it.
- **The rules are the simulation's.** A committed journey cannot be cancelled because the
  simulation refuses the intent, not because a button is greyed out.

## Determinism

The simulation has no hidden state. Given the same seed and inputs it produces byte-identical
output.

- Randomness is SplitMix64 with six named streams, checked against published vectors.
- `make replay` re-runs recorded input logs and diffs the state. A **10,000-tick session is
  byte-identical on the VM and the interpreter**, and matches its recorded golden.
- When the VM and the interpreter disagree, that is an AILANG bug: it gets shrunk to a minimal
  repro and reported upstream. The game is meant to stress-test the VM: thirteen AILANG issues were
  filed or tracked during the journey-core milestone alone.

## A real exchange

Trimmed from `tests/replays/alpha_cen.ndjson` and its recorded state log (`…` marks elided
fields). Godot plans a trip to α Centauri at rapidity 2.6466 (0.99c), and the simulation answers
with the plan:

```json
{"v":2,"type":"input","tick":1,"dtau":0,"intents":[{"k":"plan","target":{"index":1,"id":"alpha Cen","pos":{"x":0,"y":0,"z":-4.37}},"cruise_phi":2.6466524123622457}]}
{"v":2,"type":"state","tick":1,"status":"ok","changes":{"journey":{"state":"planned","plan_id":1,"plan":{"cruise_beta":0.99,"cruise_one_minus_beta":0.01000000000000001,"cruise_gamma":7.088812050083356,"ship_years":0.6226958707592057,"earth_years":4.414143655383168, …}}}}
```

Note `cruise_one_minus_beta`: near c the simulation carries 1 − β itself instead of letting anyone
subtract.

## Pipelines in AILANG too

The offline tools are AILANG, with Godot headless doing image I/O:

- the **catalogue builder** turns CNS5, Gaia GCNS and Hipparcos into binary tiers (the 331,312-row
  large tier builds in under a minute on the VM);
- the **destar** pass removes catalogue stars from the Milky Way panorama;
- the **sky-model fitter** gives each panorama texel a colour temperature on the Planckian locus.

Python is allowed only as an independent oracle, a test harness or a throwaway spike, and a
guard in `make test` enforces it.

## Tested before it merges

`make test` runs headless in CI: the physics reference checks, the simulation against closed
forms, VM/interpreter parity, the strict-VM core and the replay goldens. `make golden` checks the
GPU shaders against the CPU reference to sub-pixel accuracy, and `make capture` renders the
reference images that get looked at by eye.

## Links

- [AILANG](https://ailang.sunholo.com), the language
- [stapledons-godot](https://github.com/sunholo-data/stapledons-godot), this game's code
- [stapledons-design](https://github.com/sunholo-data/stapledons-design), the design and physics specs
