# Independent review response

Round 1: Claude Opus (`claude-opus-5-5`), public-code snapshot `dc15f91e`, **62/100, changes requested**. The executor is OpenAI GPT/Codex. The review had no tools or local/private context; its complete report is in `.ailang/state/evaluations/eval_R3-TELESCOPE_round_1.json`. It did not run tests. This response records fixes and evidence, not a replacement independent verdict.

| Finding | Disposition and check |
|---|---|
| F1 half-pixel drawing/picking | Fixed at the canvas boundary: zero-based centre indices gain 0.5 before both drawing and picking. A high-zoom real-source click fails before the fix and passes afterwards. Projection API and FITS conventions remain unchanged. |
| F2 observation/destination ring conflict | Destination stays cyan and tied to navigation selection; observation is amber, dashed and labelled Inspecting. Route and inspection indices are separately tested. |
| F3 inspection-to-plot flow | Information entry stays read-only under the approved ruling. At the helm, Plot inspected star is a separate explicit action for an exact local catalogue reference. Chart/survey/committed contexts cannot invoke it. Real-sim tests cover chart → helm → explicit plot. |
| F4 sticky survey context | Closing Navigation and entering helm mode restore local context/camera. Tests exercise this boundary and a survey field cannot fall back to an old planned star. |
| F5 weak pack pin | Exact manifest/object byte hashes plus ID are retained in host metadata and a recording sidecar, outside NDJSON. Panels hold deep private snapshots. Same-ID content changes, mutation and restored expected-pin mismatch are tested; incompatible archive data becomes unavailable while live/map functions remain usable. No save/load subsystem exists or was added. Index pin tests: 27/0. |
| F6 asset prerequisites | Real-image UI/benchmark/verification and oracle targets explicitly require the bounded asset fetch. Their dependency graph is acyclic; fast CI keeps only pure tracked-input work. |
| F7 prepared PNG portability | Fetch hash-pinned prepared levels first; deterministic local processing is a fallback. Transport tests: 14/0. |
| F8 reproducible independent oracle | Tracked stdlib-only Python oracle, explicitly allowlisted as oracle, reads pinned FITS/CSV bytes and uses an independent scalar derivation. 51 cases / 246 checks, max projection error 6.36e-10 source px; five remeasured anchors max 0.368168 px. A full-gate half-pixel fault fails. No Astropy/WCSLIB claim. |
| F9 FITS WCS trust | Source hash/header must match manifest CTYPE, frame, dimensions and all CRPIX/CRVAL/CD coefficients. Unsupported SIP/PV/lookup distortion is rejected. FITS tests: 46/0. |
| F10 hardcoded association | Import requires explicit plateId; the verifier checks all forty source rows against actual physical image bounds. No out-of-field association is accepted. Native import: 21/0 and strict parity. |
| F11 minimal-PCK limitation | Minimal PCK remains a focused cache test (2/0). A separate full-app production CLI probe, mandatory network-denying sandbox, fresh HOME and bundled runtime test was added. Its real exported-app positive is pending the new checkpoint/re-export. No full-app pass is claimed from the minimal PCK. Shell launchers use sh/grep. |
| F12 mixed provenance | Additive per-fact value/unit/method/source/epoch metadata is validated. Classifier/quality/derived fields are distinct from measured coordinates; unknown epochs remain null. The UI uses those methods instead of a blanket measured caption. Hardcoded J2000 epoch removed. |
| F13 silent unavailable entry | Missing valid identities open explicit unavailable cards, map action is disabled, and body focus uses the same observer snapshot as the renderer. Unsupported chart views show the existing refusal. T is typing-guarded and contained by the active observation view; opening it closes the legacy renderer. |

The first read-only entry is also tested from a ship with no existing map: all recorded input intents are empty through observation, with default consent crew present; the exact Sun and host/panel/sidecar pins agree. Only later explicit star selection sends a plan. Entering the helm applies the normal critical-only crew orders exactly once, including after read-only entry. Captain position is unchanged. **48 checks pass.**

The required behavioural mutants were run against actual temporary source changes and restored byte-for-byte afterwards: calling preselect from focus gives 13 passes/5 failures; removing the survey planning guard gives 17 passes/1 failure. Both controls exit 1 without SCRIPT ERROR.

Some round-1 observations were input omissions, not repository defects: `.uid` files and the existing changelog fragment were excluded from that selected public-text payload. Both are tracked, and policy gates verify them. Current main's worlds API is preserved by worlds 0.2.1: all nineteen AILANG files and 78 signatures match 0.2.0; the dependency-only patch passed 65 native tests.

Credits now include the exact Data from ESA wording; BY-SA display resizing/re-encoding/tiling is disclosed in both manifest and credits. The default M81 gallery and separate Inspect action are deliberate: Inspect opens Details, Telescope favours the image/live view. IDs preserve exact producer text, including possible leading zeros, rather than coercing identity through numbers.

## Round 2

Claude Opus scored the public `2ddd7516` snapshot **75/100**, conditional on N1. The complete report is in `.ailang/state/evaluations/eval_R3-TELESCOPE_round_2.json`; it ran no tools or tests.

| Finding | Disposition |
|---|---|
| N1 first-entry crew setup | Fixed with a pending setup flag: information entry queues no orders, and the first helm entry queues the existing preset once. Actual recorded-wire regression fails before the fix (47/1), then passes (48/0), including repeated helm entry. |
| N2 shared publish workflow | Removed the telescope-specific dependency from publish-dev. The full-app smoke remains an explicit sprint check. |
| N3 release diagnostic | Deliberate, documented headless diagnostic entry, required because official templates refuse external --script overrides. It requires the isolated environment before starting a session and remains distinct from interactive play. |
| N4 CSV importer | Both tracked observation CSV import settings explicitly use importer="keep". They are not translation resources. |
| N5 unnecessary fetches | Removed observation-assets dependencies from the tracked/synthetic coordinate and cache tests. Real-image checks still fetch their prerequisites. |
| N6 stale evidence | Updated measured counts, integrated main, bundle size and initial-field wording. |
| N7 header acceptance | Oracle/Godot now agree on optional celestial degree units and rejected alternate/distorted conventions. Twenty-eight same-header controls compare both readers directly; independent oracle 275/0, FITS 53/0. |
| N8 stale inspection marker | A failed open clears the old amber marker and plot action. Regression fails before the fix and passes afterwards; focus_object alone still preserves state when rejecting invalid input. |
| P3 outside survey view | Label now explicitly states outside view (sky mirrored). It remains a direction diagram with no assigned depth. |
| P3 fixture writes in project | Cache test writes a one-file fixture PCK under user:// and mounts its virtual bundle entry, exercising unchanged production mapping. It passes 38/0 with project-directory writes denied. |

The row-level legacy provenance field remains for format compatibility; per-fact methods are authoritative, and the UI never describes the mixed record as wholly measured. This is explicitly a deprecated aggregate label. The recording sidecar is write-only audit metadata: no save/load subsystem exists, and restoration is not claimed.

## Round 3

Claude Opus reviewed public 581cb165 and scored **80/100, code pass, no remaining P1/P2 defects**. Full report: `.ailang/state/evaluations/eval_R3-TELESCOPE_round_3.json`. It ran no tests and correctly left landing_ready false. Its statement that the exported-app positive was pending predates the actual 32/0 full-app run at the same checkpoint, with all 176 hashes verified and exact live Sun material exercised.

The read-only-first behaviour is deliberate: it starts with the simulation's default consent-crew orders and no implicit Alpha Centauri plan. Entering the helm applies the normal critical-only preset exactly once, while plotting remains an explicit action. Browsing does not pause clocks or suppress default crew consequences. Normal helm-first startup retains its existing default. The first-entry test covers direct helm entry; chart-to-chair coverage is a non-blocking follow-up alongside the existing chair interaction tests.

The package's initial scalar oracle maximum (6.86e-10 pixel) and the tracked game-mirror oracle maximum (6.36e-10) are separate measurements. The empirical source registration maximum is 0.368168 pixel. The export audit subsequently classified the probe's extensionless runtime binary and canonical directory spelling; 152 literals pass, with no export-filter widening.

The normal publication exposed a stale assertion in the existing finder export probe: it expected Open in map to mutate the plotted destination. The actual pick/card/release stages passed, while that old plan-selection assertion failed. The probe now asserts the exact read-only observation reference, chart mode, empty navigation queues and no simulation plan. This changes diagnostic expectations to the approved behaviour; player code is unchanged by the probe correction.

Final-head CI, current combined review-build publication and Mark's visual acceptance remain separate gates. The GPU was busy at the final source freeze, so new composed-UI cases defer to nightly/dev-build review under CLAUDE.md. No landing or completion is claimed here.
