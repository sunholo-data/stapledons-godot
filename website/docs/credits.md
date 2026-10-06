---
title: Credits
sidebar_position: 7
description: Data sources, imagery and software behind Stapledon's Voyage.
---

# Credits

Stapledon's Voyage is made by [Sunholo](https://www.sunholo.com).

## Licence

- **Code:** the game's code and this site's code are licensed under the
  [Apache License 2.0](https://github.com/sunholo-data/stapledons-godot/blob/main/LICENSE),
  Copyright 2026 Sunholo / Mark Edmondson.
- **AI-generated art** (the captain, the crew portraits, the bridge, the concept art): labelled
  AI-generated, **no copyright claimed**. See [Art](#art).
- **Third-party assets** keep their own licences, listed below; the Apache licence does not cover
  them:

| Asset | Licence or terms |
|---|---|
| Milky Way panorama, NOIRLab `noirlab2430b` (E. Slawik / NOIRLab / NSF / AURA), and the sky textures derived from it | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |
| Planet textures, [Solar System Scope](https://www.solarsystemscope.com/textures/) 2k (shown in game as "Planet textures: Solar System Scope (solarsystemscope.com), CC BY 4.0") | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |
| Star catalogues: CNS5 (via CDS VizieR), Gaia GCNS (ESA/Gaia/DPAC), Hipparcos (ESA) | The providers' terms; cite the sources listed below |
| Godot Engine | [MIT](https://godotengine.org/license/) |
| Fonts on this site (Montserrat, Inter, JetBrains Mono, via Google Fonts) and Montserrat Bold on the game's boot splash (`ui/splash/`, licence alongside) | [SIL Open Font License 1.1](https://openfontlicense.org) |
| AILANG logo and favicon, here and on the boot splash | AILANG's (Sunholo), used unaltered |

## Art

The concept and game art (the captain, the crew portraits, the bridge) is **AI-generated**, made
with image models and Blender under Sunholo's art direction. **No copyright is claimed** in it.

## Data

- **Milky Way panorama:** NOIRLab `noirlab2430b` (E. Slawik / NOIRLab / NSF / AURA), licensed
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The game uses it with the
  catalogue stars removed and a fitted colour-temperature model.
- **Planet textures:** [Solar System Scope](https://www.solarsystemscope.com/textures/) 2k maps
  (based on NASA imagery; unmapped regions filled in, colours slightly saturated), licensed
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The game keeps the files unchanged and
  rescales their brightness to each body's measured albedo. In game, press **C** for the credits.
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
