### Added

- Showcase website in `website/` (Docusaurus 3.10.2, AILANG family theme), for
  https://www.sunholo.com/stapledons-godot/: landing page with real captures, gallery, and pages on
  the game, the physics, the Higgs bubble, the AILANG architecture, the roadmap, trying it and
  credits. `make site`, `make site-serve`, `make site-deploy` (temporary clone of `gh-pages`, no
  worktree; `DRY=1` stops before the push). Publishing and the Pages setting are the owner's call.
- Website clips are frame-exact captures: `tools/site_movie.gd` behind `main.gd --movie=CLIP`
  (`hero`, `voyage`, `lookaround`, `cmb`) and `--map --movie=map`; `tools/site_media.sh` renders,
  encodes (MP4 + WebM + posters) and publishes them content-addressed to
  `gs://stapledons-voyage-assets/site/` (`make site-media`, `make site-media-publish`).
  `--movie` is an automation flag, so a clip never starts live AI.
