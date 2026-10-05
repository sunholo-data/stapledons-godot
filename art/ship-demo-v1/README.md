# Seven-tier geometry demo master

Metres, ship +Z up. Derived from the chosen v2 master and actual bridge, with separate demo-only lift openings at ship XY (8,8), bridge Z82 and lower Z57. Generator embedded as `ship_demo_generator.py` in the Blender text datablocks; run with the Blender workspace's launcher/configure skill.

`assets/ship_demo` contains visual GLB and two separate WALK-only GLBs. Lower floor slabs fit the 95m inner envelope. Guards, guide rails and a bounded lower landing are diagnostic geometry. Production bridge files are unchanged. This is not finished paint, architecture or a structural engineering certification.

## Frozen journey sky review

The review demo now opens on an actual simulation snapshot halfway Sol → Alpha
Centauri at0.99c. `assets/ship_demo/sky_review.json` is reproduced with
`make ship-demo-sky-states AILANG=runtime/bin/ailang`; the independent evaluator
reproduced it byte-for-byte. State fields own heading, position, beta and gamma.
5/6 select rest/cruise;7/8/9 look forward(up)/side/aft(down);H hides opaque ship
geometry only for a labeled sky diagnostic. Tab expands controls. Normal journey
clocks are unaffected. Snapshot protocol has no glow_pole field; no glow value or
new epsilon is fabricated. GR remains unimplemented.

12captures at `https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_demo_journey_v1/`
were inspected: forward field concentrates during cruise, side/aft are much darker,
and opaque decks mask the real aft view. `journey-capture-manifest.json` records
actual eye/FOV/direction and simulation values. `journey-optics-audit.json` records
81GPUcases at0,0.9,0.99c: worst0.170052px,0failures, opaque occlusion and an incorrect
FOV negative control. These captures remain native-material previews.
