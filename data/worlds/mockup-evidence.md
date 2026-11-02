# W2.4 review mock-ups — 2026-11-02

**Awaiting Mark. These are mock-up artefacts, not a landed UI or an approval.**
No runtime scenes, player flows, lore or production protocol fields were changed.
The four 1600×1000 PNGs are actual Godot 4.7.2 window/viewport captures using
Compatibility on the Studio's Apple M4 Max. They reuse StapledonTheme's
Josefin Sans/Nunito fonts, cream/ochre/night/mint palette and ink panel.

All four final PNGs were opened with `view_image` and inspected. Iteration fixed
a crowded temperature row, unsupported axis formatting, overlapping annotations
and the candidate/HZ-label spacing. The final captures contain no script or
formatting errors. The existing theme builder emits its image-loading/export
warnings; this review tool is not exported and no theme code was changed.
A second capture, and a capture after the final metadata correction, are
byte-identical to the inspected/uploaded images. All four public URLs were
fetched anonymously over HTTPS and compared byte-for-byte to the local PNGs.

| Frame | What it shows | Public PNG | SHA256 |
|---|---|---|---|
| `map_25ly.png` | Galactic XY projection of a true 25-ly catalogue sphere: 182 stars, 38 known hosts, 82 known planets | [25-ly host map](https://storage.googleapis.com/stapledons-voyage-assets/refs/worlds_v1/20261102T200654Z/map_25ly.png) | `f8e68ae411e0fd0040a3e44c0912325b3e37689b2e91c9ff82e02f223501106a` |
| `map_81ly.png` | Same projection at 81 ly: 5,591 stars, all 241 registry hosts and 412 known planets; no coordinate jitter or synthetic population | [81-ly host map](https://storage.googleapis.com/stapledons-voyage-assets/refs/worlds_v1/20261102T200654Z/map_81ly.png) | `775a6b81a4f93329010c7c6bd3e2ddbd5d898c5c9e3a523be1ed6b1b9e50bbc8` |
| `trappist1_strip.png` | Seven measured planets on a logarithmic AU strip; e/f/g debated; inferred conservative band and explicit 2,566→2,600 K temperature clamp | [TRAPPIST-1 strip](https://storage.googleapis.com/stapledons-voyage-assets/refs/worlds_v1/20261102T200654Z/trappist1_strip.png) | `253836ed1c46e6592569c4d63f24655cadbe0a3c04d110c2a1c529a29ced9edf` |
| `alpha_cen_a_strip.png` | α Cen A b remains a dashed candidate; fitted 1.66-AU orbit and inferred 11.77-Earth-radius atmosphere/photometry estimate are labelled | [α Cen A strip](https://storage.googleapis.com/stapledons-voyage-assets/refs/worlds_v1/20261102T200654Z/alpha_cen_a_strip.png) | `8bc9301c270f7268bc96940041e756c4197e4ab3941b745c48d47b7b84b667de` |

[Public SHA256SUMS](https://storage.googleapis.com/stapledons-voyage-assets/refs/worlds_v1/20261102T200654Z/SHA256SUMS).
The dated prefix was new; no previous public reference was overwritten.
PNG files and the local manifest remain under ignored `renders/worlds_v1/`;
the public bucket and this evidence record hold the review artefacts.

## Public-data boundary and qualifiers

`sim/tools/worlds_mock_data.ail` emits only the physical projection from
`data/exoplanets.planets`, `data/world_hosts.knownHostRows`,
`worlds_catalogue.rowOf` and `protocol_worlds.encodeWorlds`. It never reads a
planet's history, life state, dial or census. Every emitted planet has exactly
the public DTO's 12 keys, and all 412 have provenance measured or candidate.
No synthesised planet is drawn. All 241 host positions compare exactly to the
read-only navigation catalogue. Star dots and names come from public
`data/starmap/stars.json` and `names.json`; selection uses true 3D distance,
then projects XY. Height is flattened explicitly; dots are not repositioned.

Solid ochre rings denote known measured planets; candidates are dashed.
Green rings follow the public rocky-HZ eligibility label, and `?` follows
`habitability_debated`, rather than asserting life. The maps disclose HZ model
clamping and M-dwarf debate. Current catalogue distances are retained exactly
before display rounding, including α Cen A's 4.32103979249451 ly navigation
position; a literature/reference distance is not substituted into the map.

The strips disclose that radii are measured for TRAPPIST-1, while α Cen A b's
orbit and radius are model-dependent inferences (one fitted orbit family).
Teq and its colour encoding are inferred, using the existing projection's
assumed Bond albedo 0.3. Planet sizes are proportional to radius within each
strip; the star icon is explicitly off scale. Orbital position uses a labelled
logarithmic AU axis. These are schematic data views, not planet photographs.

Numerical green-band edges come directly from celestial 0.6.0's
`hzFluxes`/`hzDistanceAu`; no HZ physics formula was copied into GDScript:

- TRAPPIST-1: 0.024612248967323336–0.04982436788368655 AU. Actual stellar Teff
  2,566 K; model clamped to 2,600 K, visibly disclosed. Habitability remains
  debated and the view does not establish an atmosphere.
- α Cen A: 1.1711122802105474–2.0643127817868554 AU at the curated 5,795 K,
  no clamp. The candidate is gas-giant-sized and its public habitability label
  remains `not_habitable` even though the fitted orbit lies in the band.

**Follow-up contract:** protocol 2.17 currently has no numerical HZ edge or
clamp fields. `offline_inferred_zone` is separate mock-data metadata, not a
production ABI extension. A real W2.4 system card needs a reviewed rendering
contract for those inferred values. The 81-ly ring density and overlap also
remain a visual choice for Mark; these mock-ups do not resolve decluttering
or approve the product copy.

## Reproduction and verification

The released AILANG v0.56.0 teaching prompt v0.16.11 was loaded. Local package
directories are used through an ignored overlay; no unpublished path pin was
added to the game manifest. Register the new tool export as
`stapledons/sim/tools/worlds_mock_data` when integrating.

```sh
mkdir -p .godot/worlds_mock
AILANG=runtime/bin/ailang tools/worlds_dev.sh run --quiet --strict-bytecode \
  --caps IO --entry main sim/tools/worlds_mock_data.ail \
  > .godot/worlds_mock/public-data.json
godot --path . --rendering-method gl_compatibility \
  --script tools/worlds_mockup.gd
```

```text
worlds-mock-data: strict VM repeat byte-identical; 241 hosts, 412 public planets
worlds-mock: map_25ly 1600x1000
worlds-mock: map_81ly 1600x1000
worlds-mock: trappist1_strip 1600x1000
worlds-mock: alpha_cen_a_strip 1600x1000
worlds-mock: 4 public-data review frames; awaiting Mark
worlds-mock-public: 4 anonymous HTTPS downloads byte-identical to inspected PNG
worlds-mock-repeat: 4 GPU captures byte-identical to inspected/uploaded PNG
worlds-mock-final: public data repeat exact; all 4 captures unchanged
```

Final ignored public-data JSON SHA256:
`840cad2302a9736f66b78d1fdc83241579432ccce60b600198524cf5ea15cac6`.
Final source SHA256:

| Source | SHA256 |
|---|---|
| `sim/tools/worlds_mock_data.ail` | `68ae933e12a6a85808b531b1c5f9721f6229d1f24da3fa9ca4381ea89e2a1ca9` |
| `tools/worlds_mockup.gd` | `8dc13b0b700e0593d805adebcad909e729acd0e467fa5322734900bb35dd10e7` |
| `data/starmap/stars.json` | `128dfc7348de0a5dab04c903c18fe41526b78cf1ef017361a1dc88eaa004ef19` |
| `data/starmap/names.json` | `34ba90f8973870a2451d7fa192b28d98e8ea695903ef5ec5f699faeaa28dd824` |
| `ui/stapledon_theme.gd` | `9663ede97a4e51e757b866dbcea721526ae5f8824a4887db6fa36f4655a6c2c1` |

Commit `tools/worlds_mockup.gd.uid` with the tool. No standalone rendered PNG
is staged in git, and no Mark render approval or complete W2.4 acceptance is
claimed. Stop here for the attended review before implementing the UI.
