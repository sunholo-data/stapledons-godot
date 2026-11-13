# Painted bridge and Commons playable review

The native material layer covers 141 bridge and 1,000 Commons mesh instances, retaining the source triangle geometry and existing routes, colliders, cameras, physical sky, star/spire lighting and functional screen content. Main's normal game entry installs both resource closures after civic assets and physics are ready. Failed deck/NPC installation rolls back; source and compiled face/resource hashes are checked. The candidate is based on current main (36f4ab4c), including the previously shipped dev commit 2c84f2c2.

D-158 is the shared attended approval for this review. Source-art scripts and generation receipts retain session-local prototype labels D-164/D-165; those labels are provenance from the earlier authoring checkout, not renumbered shared mission decisions.

Static painted residents replace the visible procedural crowd: 42 residents, including two portrait-bound crew identities, from the existing accepted five-identity catalog. The decorative proxy walking loops pause while hidden; painted figures stay anchored and choose existing direction/seat poses. No new population/crew simulation or walk animation is claimed. The captain retains the image-based presentation.

Native production indexing reduces the paint meshes to 854,316 vertices across the two decks, retaining all 981,694 source triangles and their surface counts. Four shared textures total 61,510,040 bytes including mipmaps; this is the additional texture payload, not peak process memory. GPU frame cost and native appearance are not certified.

Rebuild source assets with tools/bridge_painted_finish_build.gd, tools/commons_painted_finish_build.gd, then tools/painted_levels_stage.gd. Source paints, exact built-in image-generation prompts and accepted style references remain under art/environment-painted-pilot; authoring assets are explicitly excluded from the app. Production meshes/materials and manifests are under assets/levels/painted.

Validation: 450 bridge and 3,025 Commons authoring checks pass, preserving exact triangle geometry and bounded normal packing. Current-main combined headless tests pass, including late-NPC rollback, source restoration, disjoint deck ownership, camera/WALK/body invariants and a painted bridge-to-Commons lift round trip. The headless normal-entry smoke loads both resource closures and 42 residents. Dependency audit finds no art-folder dependencies. The independent internal preflight scores 86/100, with no blocking correctness findings; full sprint and cross-family merge evaluation remain open.

No local GPU work is authorized during training (D-151). The app is exported and smoke-tested headlessly; native lighting, reduced-motion presentation and FPS remain Mark's laptop review. This is a review candidate, not a merge, completed S3/S5 or final visual acceptance.
