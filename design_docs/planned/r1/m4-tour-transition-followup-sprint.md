# Close tour and continuity amendment

Parent: [Solar departure sprint](m4-ship-lighting-and-solar-departure-sprint.md).
Approved in the attended 5 October session: closer side views, continuous
transitions, laptop performance investigation, automatic public audit upload,
and repair of detached ship/captain shadows.

| Milestone | Acceptance commands and evidence |
|---|---|
| Rendering preparation and handoff | `make planet-presentation-test planet-meter-test`; `tools/planet_transition_golden.gd`; existing inverse-disc/ring GPU goldens; bounded-vs-fullscreen native cases |
| Authoritative close stops | `make solar-departure-test`; pinned AILANG Solar/navigation tests, strict VM and interpreter parity; real collision-refused direct Jupiter-to-Saturn and accepted Callisto clearance leg |
| Shared observer and stationary turns | `make ship-attitude-test tour-attitude-test`; `make solar-departure-capture`, opened standing-eye close and phase captures |
| Floor and captain contact | `make bridge-floor-test shadow-contacts-test`; native `tools/ship_contact_capture.gd`, opened images; unchanged WALK hashes and pinned editable masters |
| Public B audit and laptop evidence | `make benchmark-upload-test`; native asynchronous success/failure fixtures; verified aggregate baseline public URL; corrected counter units and forward-dome camera pose |
| Delivery | Full `make test`, CI; separate evaluator; packaged startup/identification/Solar checks; verified private dev12 artifact and latest pointer; selected gallery/reference captures |

The parent sprint remains in progress: external stellar illumination of the ship,
remaining art and actual M2 Air measurements of the new build remain open. This
amendment does not assert a stable 60 FPS result from Studio measurements.

Sun stopping is a bounded kinematic review at three measured solar radii. Thermal
loads, orbital gravity and GR are not implemented. Alpha Centauri has no resolved
surface asset; it remains a catalogue point at the existing 1000 AU stand-off.
At stops the ship turns over three wall seconds while both simulation clocks
are held; commitment replans at the current ephemeris epoch. During travel the
existing forward-pole frame is exact, with no turnover flip.
