# Stapledon's Voyage: Godot + AILANG spike

A proof of the architecture for rebuilding
[Stapledon's Voyage](https://github.com/sunholo-data/stapledons_voyage) from its
design docs:

- **AILANG owns the simulation.** `sim/ship.ail` runs as a child process
  (`ailang run --bytecode`) and keeps the world state.
- **Godot owns everything visible.** The two talk newline-delimited JSON over
  stdin/stdout, one request and one reply per tick.
- **Relativity is rendered accurately and tested.** Aberration, Doppler colour
  and beaming are checked against closed-form values on the CPU, and the GPU
  shader is checked against the CPU reference to sub-pixel accuracy.

![Relativistic sky at 0, 0.5, 0.9 and 0.99c, looking forward, starboard and astern](docs/contact_sheet.png)

Rows show 0, 0.5, 0.9 and 0.99c while accelerating at 1 g. Columns show the
view forward, to starboard and astern. The 3,802 CNS5 stars within about 40
light-years crowd forward and turn blue-white. Astern they are redshifted below
the visible band and disappear.

## Run it

Requires Godot 4.7+ and AILANG 0.45+ on `PATH`, or set `AILANG_BIN`.

```sh
make test      # physics reference, AILANG sim vs closed form, VM/interpreter parity (headless)
make golden    # GPU shader vs CPU reference star positions (opens a window)
make capture   # 1 g voyage driven by the AILANG sim, PNGs to renders/
make run       # interactive: W/S thrust, arrows look, 1-4 fwd/stbd/astern/up, +/- time warp
```

## Layout

| Path | What |
|---|---|
| `sim/ship.ail` | Ship kinematics in AILANG: exact constant proper acceleration via rapidity; NDJSON loop |
| `bridge/sim_bridge.gd` | Spawns the sim and exchanges one JSON line per tick |
| `physics/relativity.gd` | Reference SR maths (float64): aberration, Doppler, point-source beaming |
| `physics/blackbody.gd` | Planck spectrum × CIE 1931 → linear sRGB; temperature LUT for the shader |
| `sky/starfield.gdshader` | GPU mirror of the reference: per-star aberration, D·T colour, (Y(DT)/Y(T))/D² flux |
| `tests/` | `test_physics.gd` (27 checks), `test_sim_bridge.gd` (bridge + sim integration) |
| `main.gd` | Scene, HUD, interactive loop, `--capture` and `--golden` modes |

## Physics notes

- **Aberration.** A source at galaxy-frame angle θ from the direction of motion
  appears at cos θ' = (cos θ + β)/(1 + β cos θ). At 0.9c a star at 90° appears
  25.84° off the bow.
- **Doppler.** D = γ(1 + β cos θ). A blackbody at T is seen as a blackbody at
  D·T.
- **Point-source brightness.** I_ν/ν³ is invariant and the solid angle scales by
  1/D², so the visual-band flux scales by (Y(D·T)/Y(T))/D². Bolometrically that
  is D².
- **Precision near c.** γ and 1 − β come from the float64 sim, and the shader
  rewrites 1 + β cos θ to avoid cancellation.
- **Known simplifications (spike).**
  - Star temperatures come from the spectral-class letter only.
  - There is no Milky Way background yet.
  - The ship moves on a single axis toward the galactic centre.

Findings and the roadmap live in the design repo.
