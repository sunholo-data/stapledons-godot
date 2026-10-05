# Seven-tier geometry review demo

Open **Ship geometry demo** from the normal bridge. It opens a separate review window; the active voyage keeps running. Escape closes that review window. `make run-ship-demo` or launch the app with `--ship-demo` opens it directly.

One perspective observer drives finite geometry and the infinite star/sky viewport, matching attitude, vertical FOV and aspect. The sky is composited behind opaque ship geometry, so its depth-disabled catalogue shader cannot put stars through decks. Eye offsets stay in local metres, separate from astronomical positions. The demo starts at rest and reuses existing SR code. **GR is not implemented**; shared rays are a future integration seam, not a GR physics result. Exterior overview cameras disable the inside-bubble wall overlay.

- 1 / Bridge: player view. WASD walks at2.2m/s on the active bridge or lower landing.
- 2 / Overlook: reachable bridge overlook. Actual rail/frond/floor occlusion stays visible.
- 3 / Whole ship: external inspection camera, with bubble guides.
- 4 / Reference rim: measured diagnostic camera outside the certified walk region.
- Right mouse drag: look; wheel: bounded pullback. Pullback is locked during the lift.
- E at the arrival landing: board, descend25m from+82 to+57, disembark onto a bounded12m landing, and return. Initial spawn is at the bridge lift landing. Guards close during departure and protect absent platforms. Walking locks during boarding/travel/disembarking.
- G toggles sphere guides. R resets this isolated demo.
- B / Benchmark: four stationary views at1920×1080; close other game windows before measuring. Keyboard/mouse and HUD buttons lock during the sample.

Benchmark JSON saves to `~/Library/Application Support/Godot/app_userdata/Stapledon's Voyage/ship_demo_benchmark.json`; the exact path also appears in the HUD/log. Share that file after running on the **MacBook Air M2(2022),24GB**. Reports record actual model/CPU/GPU/RAM, warm-up/sample counts, frame-time distribution, draw calls, primitives and memory. Wall-frame timings include presentation/vsync, not GPU-only time. Target identity requires confirmation; Studio results never establish Air performance. The proposed60fps budget is a test target, not a current laptop claim.

Native bridge materials and the current billboard captain are diagnostic, not finished arbitrary-angle paint. Lower tiers have no buildings, forests or final structural supports. Their opaque floor slabs fit the accepted95m inner envelope; architecture needs separate volume/occlusion checks. Production bridge art is unchanged. The editable demo master is in `art/ship-demo-v1` and embeds its Blender generator.

Verification: `make validate-ship-demo ship-demo-assets-test ship-demo-geometry-negative-test ship-demo-test ship-demo-lift-test ship-demo-launch-test ship-demo-benchmark-test ship-demo-optics`; GPU captures: `make ship-demo-capture`. `make ship-demo-bench` measures the current machine. `make export-macos ship-demo-export-smoke` checks the packaged assets and lift roundtrip. Existing compatibility/physics tests and independent evaluation remain required for landing.

`make ship-demo-movie` produces deterministic24fps PNG route frames, then uses an available ffmpeg encoder. A native one-off AVFoundation encoder can also encode these review frames; no video encoder is bundled in the game.
