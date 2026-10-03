---
title: Credits
sidebar_position: 7
description: Data sources, imagery and software behind Stapledon's Voyage.
---

# Credits

Stapledon's Voyage is made by [Sunholo](https://www.sunholo.com).

## Data

- **Milky Way panorama:** NOIRLab `noirlab2430b`, by E. Slawik, licensed
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The game uses it with the
  catalogue stars removed and a fitted colour-temperature model.
- **CNS5**, the fifth Catalogue of Nearby Stars (Golovin et al. 2023), via VizieR.
- **GCNS**, the Gaia Catalogue of Nearby Stars (Gaia Collaboration, Smart et al. 2021). This
  work uses data from the European Space Agency mission
  [Gaia](https://www.cosmos.esa.int/gaia), processed by the Gaia Data Processing and Analysis
  Consortium (DPAC).
- **Hipparcos** (ESA 1997; van Leeuwen 2007 new reduction) for the bright stars.
- **Sgr A\*** mass and distance from the GRAVITY Collaboration (2022), used in the bubble canon.

## Software

- [Godot Engine](https://godotengine.org) 4.7
- [AILANG](https://ailang.sunholo.com) and the
  [`sunholo/relativity`](https://github.com/sunholo-data/ailang-packages/tree/main/packages/relativity)
  package
- This site: [Docusaurus](https://docusaurus.io), with the AILANG family theme

## Media on this site

The videos are frame-exact captures made with `make site-media`, which drives the game's own
renderer and simulation (`tools/site_movie.gd`). They are served from the project's public asset
bucket. The stills come from the same captures and from the reference renders committed with each
milestone.
