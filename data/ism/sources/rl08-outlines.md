# RL08 angular outlines: source and transcription audit

These numerical coordinates transcribe the **black outlines**, independently of the member-star positions, in Redfield & Linsky (2008), *ApJ* 673, 283, [arXiv:0709.4480v1](https://arxiv.org/pdf/0709.4480), Figures 2–15 (PDF pages 32–45). They replace equal-area circles for **all fourteen non-LIC clouds**. The LIC keeps the existing Linsky (2019) surface. Radial depths, neutral/total gas densities, dust fractions, and the separate RL08 member fixture are unchanged.

Original arXiv source archive SHA-256: `2ceaf663043de0c0f0077519cc71e906ab754b213d9dc7c454edecdd4b6c14b8` ([source archive](https://arxiv.org/src/0709.4480)). Each `fNsmall.ps` contains a palette-indexed raster. Reading the raster and turning its page orientation upright gives the pixel frame recorded in `rl08_outline_vertices.tsv`. No copied figure assets are required by the production pipeline.

Each vertex records its original pixel, figure, projection, calibration, and converted Galactic longitude/latitude. `H` is the upper-left Hammer projection about longitude 0; `A` the lower-left Hammer projection about longitude 180; `N` the upper-right Lambert azimuthal projection from the north pole, showing the entire sphere; `S` is the lower-right south Lambert chart, also the full sphere, with longitude 0 at bottom, 90 at right, 180 at top and 270 at left. Hammer calibration records the ellipse's centre and horizontal/vertical semiaxes. Lambert calibration records its centre and circular radius. Coordinates follow the printed graticule: longitude increases leftward in Hammer; the north Lambert circle has longitude 0 at its bottom and 90 at its left. Sparse vertices follow changes in the published black boundary; edges are approximated by great-circle arcs. Raster occlusion and resolution leave angular uncertainty of roughly a few degrees.

`rl08_outline_triangles.tsv` records a spherical ear triangulation of each outline (zero-based vertex indices). Triangulation is transcription metadata, not an observation or a fit to membership. Using ordinary planar Hammer ears creates long great-circle diagonals that overfill some clouds; these are rejected by the independent solid-angle audit. The AILANG generator reads the numeric tables and computes inward unit-plane normals using the published `sunholo/celestial/kepler` cross, dot, and norm operations. Runtime classification intersects those angular half-spaces with the existing radial shell. The Python oracle independently reconstructs the same geometric data and checks the Table18 areas, inward orientation, actual route membership, and alpha-Cen column.

| Cloud | Digitised area (sq deg) | RL08 Table18 (sq deg) |
|---|---:|---:|
| G | 8327 | 8230 |
| Blue | 2594 | 2310 |
| Aql | 3099 | 2960 |
| Eri | 1993 | 1970 |
| Aur | 1837 | 1640 |
| Hyades | 2132 | 1810 |
| Mic | 3413 | 3550 |
| Oph | 1591 | 1360 |
| Gem | 3393 | 3300 |
| NGP | 4168 | 4020 |
| Leo | 2551 | 2400 |
| Dor | 1552 | 1550 |
| Vel | 2493 | 2190 |
| Cet | 2157 | 2270 |

The maximum discrepancy is 17.79% (Hyades). Every area is within 20% of the independent summary table. That check validates the projection scale and guards against accidental enlargement; it does not claim the digitisation is exact. Under the unchanged first-match precedence and radial depths, **56/59 (94.9%)** observed member sight lines cross their assigned named medium. The remaining misses are LIC/gamma Ser, Oph/gamma Ser, and NGP/alpha Oph. The alpha-Cen neutral column remains **log10 N(H I) = 17.70**, inside the independent Linsky (2019) interval 17.6 ± 0.15. The sky outlines are observational; their placement/depth in three dimensions remains a labelled game approximation.

AILANG prompt version loaded: v0.16.6 from the pinned v0.52.0 runtime. Builder seam tests: three failures before implementing the new exports, then three passes. Contracts/effects: all geometric helpers are pure; only existing generator file I/O is effectful. Source/shape assertions are in the independent oracle; no new package formulas or releases are needed.

Pinned-runtime issues encountered and reported canonically: fold-callback package resolution (`inbox_1791657061847_c02abfea`), direct named-test interpreter panic (`inbox_1791657712041_685a564d`), and generated nested-record cache overflow (`inbox_1791657712992_10fd0486`). In-tree workarounds preserve pure geometry and strict VM execution; the compact scalar representation also stays below the existing 256-register block limit (#1737).

Independent forward-projection review caught five near-seam/polar pixels outside their calibrated Hammer ellipse. G vertices 27/28 were retraced on the opposite Hammer chart; Mic23 and Cet22/23 on the south Lambert chart. They are stored with those alternate source pixels and calibration, rather than clamping an invalid inverse. Polar markers partly occlude the black contour; the few-pixel transcription uncertainty is retained. The corrected G/Mic/Cet areas are 8327/3413/2157 square degrees.
