# Tour continuity and close-view review

| Pillar | Alignment | Reason |
|---|---:|---|
| The Ship Is Home | +2 | Keep one measured observer while approaching and turning at stops. |
| Grounded Strangeness | +2 | Close views use measured radii and authoritative intercepts, never oversized sprites. |
| Time Has Emotional Weight | +1 | Continuous clocks and readable transitions preserve journey scale. |
| Choices Are Final | +1 | No position reset or in-flight turn/skip. |

Approved scope: Mark's attended 5 October request to investigate laptop performance,
smooth rest/motion and LOD transitions, put planets alongside the ship at stops,
and fill much more sky at closest approach. This amends the approved Solar review
sprint; the whole ship-lighting/art/Air sprint remains in progress.

Independent work: rendering cache, texture preparation and point/disc handoff;
closer authoritative stop metadata and bounded measured Sun target;
stationary attitude/presentation turns and runtime integration. Integrate and
independently evaluate together before publishing another review build.

- Measure CPU update and transition discontinuities; distinguish frame stalls,
  exposure steps, discrete simulation samples and ship-frame/heading changes.
- Cache prepared system state separately from exposure, avoid repeated texture
  decoding and redundant point-source uploads, keep all physical inputs unchanged.
- Preserve point/disc flux through a bounded handoff; GPU/CPU goldens still apply.
- Start Earth near two equatorial radii, request Jupiter near two radii subject to
  existing ring/collision checks, retain Saturn clearance outside its ring envelope.
- A resolved Sun close stop uses its measured radius and existing intercept math,
  with explicit kinematic/inertial, thermal and gravity limitations. Alpha Centauri
  remains a catalogue point at the existing safe stand-off until resolved stellar
  properties and system rendering are available; do not invent surface detail.
- Smooth stationary ship-attitude turns independently of velocity. Travel retains
  the existing forward-pole rule and no turnover flip. Replan at the actual epoch
  before commitment after any stationary presentation turn.
- Keep the camera free and demonstrate the close body beside the bridge. Floors,
  rails and lower decks may occlude the lower part of the true disc; no sky cutout.

Acceptance: focused continuity/cache/LOD/stop/attitude tests; native close-view and
phase-boundary captures actually opened; existing relevant physics GPU goldens;
packaged startup and full tour; independent review; explicit aggregate performance
and target M2 Air pending until a laptop report is available. Publish selected
captures to the existing gallery/reference with the verified review app.

## Public audit upload (attended authorization)

Mark explicitly requested automatic upload to the public bucket in this session.
Completed in-app B audits upload a filtered summary to the existing
`stapledons-voyage-assets/benchmarks/ship/` prefix using the laptop's authenticated
Cloud CLI, on a worker thread. Include target hardware type, aggregate timings
and indexed stalls; exclude local paths, dynamic free-memory values and full raw
frame arrays. Show the confirmed public link, preserve the complete local JSON
when the CLI/auth/network is unavailable, and never embed credentials. Headless
fixtures must exercise both successful and failed upload without cloud writes.
The original forward-dome benchmark was blocked by its own running guard; fix
the actual camera pose and label counter statistics without millisecond units.
