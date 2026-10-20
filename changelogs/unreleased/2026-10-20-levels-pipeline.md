### R2-LEVELS: the level pipeline's tools (LP0, LP1a)
- **The level pipeline has its tools** (design_docs/levels/README.md; ledger D-103). These are the shared commands every level of the ship goes through, from greybox to landing:
  - `make level-eval LEVEL=<id>` (traversal, readability, sightlines, the sky band, captain size, finds);
  - `make level-capture LEVEL=<id> TAG=<tag>`;
  - `make levels-regress` (every landed level against its pinned baseline);
  - `make bench SCENE=level LEVEL=<id>`;
  - `sh tools/levels_backlog.sh --check|--next` (the backlog that Mark and the mission loop share).
- **Greybox in the engine:** a level's layout builds as role-coloured boxes, arcs and ramps with colliders and walk surfaces. Curved platforms and catwalks are arcs (D-104).
- **Walking on several heights:** the captain stays on the surface within a step of where they stand, so a terrace overhead is ignored, a ramp is climbed, and a raised edge stops you. The bridge walk is unchanged.
- **The bridge is measured as a one-stage level,** with a regression baseline.
