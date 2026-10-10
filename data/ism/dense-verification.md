# Dense ISM reduction and scientific gates

This is implemented PR B data and reproducible tooling, **not scientific acceptance**.
The approved AC5(a), AC5(b), and AC6(c) remain blocked by the measurements below.
Do not mark I3b complete or land it as an accepted dust reconstruction.

## Source and independent checks

- Edenhofer et al. 2024, A&A 685 A82, [paper](https://arxiv.org/html/2308.01295v2),
  [Zenodo 8187943](https://zenodo.org/records/8187943), CC BY 4.0.
  `mean_and_std_healpix.fits`: SHA256 in `SHA256SUMS`, publisher MD5
  `10c823a5fcf81b47b6e15530bcdf54dc`, 3,252,715,200 bytes.
  Source MEAN is float32 big endian, shape 516 radial shells × 786432 pixels,
  NSIDE256 **NEST**, following an empty primary HDU. The crop preserves NEST;
  the package's RING helper must not index it. Authoritative radial tables give
  151 shell centres below160pc, beginning at68.6187286pc boundary.
- Leike et al. 2020, [Zenodo 3993082](https://zenodo.org/records/3993082), CC BY 4.0.
  `mean_std.h5`: publisher MD5 `1ea998fdaef58f53da639356362223ba`, independently
  verified after downloading. Mean shape740×740×540; original README specifies
  one-parsec Galactic Cartesian cells and **natural-log G-band optical depth/pc**.
- Independent Astropy decode agrees exactly with120 predetermined source/crop
  pixels across radial/pixel axes; cropped radial boundaries also agree.
  Synthetic Godot FITS tests cover both axis orders, empty primary HDU,
  endian conversion, crop boundary and malformed inputs:60pass/0fail.
- NEST direction lookup checks10 independently generated healpy pixel-centre
  references, including polar/equatorial faces and interleaved bits.

## Explicit reduction assumptions

AILANG maps NEST/radial samples to a fixed2pc Cartesian grid, converts
`A_V=2.8 E_ZGR23` (Edenhofer section7.1) using Bohlin1978
`N_H/E(B-V)=5.8e21 cm^-2/mag` and fixed`R_V=3.1`, and selects`n_H>1 cm^-3`.
201737 selected voxels are joined by six-connected adjacency with no axis wrapping.
Each connected component is divided into fixed8pc tiles before bounding it with
axis-aligned ellipsoids whose radii contain the complete voxel cell boxes.
The result is5601clumps; all radii are at most6.928pc. Mean voxel density is adopted
within each envelope. This geometric approximation expands the occupied volume.
An unpartitioned connected Bubble-wall ellipsoid would fill Sol; it was rejected.
The committed reduction leaves Sol outside every dense clump.

The game JSON and generated AILANG module are rendered from the same reduction;
all positions, radii, vertices and plane distances in the final records are **ly**.
`delta=0.01` is the adopted dense dust assumption, not a measured per-cell ratio.

## AC5 distance and column audit: fails

The three sightlines were transcribed from independent Zucker2020 TableA.1
([paper](https://arxiv.org/pdf/2001.00591)) before querying the reconstruction.

| Cloud | Galactic l,b (deg) | Published distance(pc) | First raw threshold(pc) | First ellipsoid(pc) | Within15pc |
| --- | --- | ---: | ---: | ---: | --- |
| Taurus |173.5,-14.2|147|119.72|114.79|no|
| Ophiuchus |352.7,15.4|139|107.59|105.03|no|
| Lupus |339.0,16.3|151|144.12|138.15|yes|

Published dust-screen distances and the first`>1 cm^-3` voxel are different
observables. These results must not be repaired by tuning the threshold or
choosing favourable sightlines after seeing their answers.

The20directions were fixed as a Fibonacci sphere before querying either map.
The raw Edenhofer full column includes its integrated inner68.8pc extension
and the authoritative outer radial widths to150pc. Leike is integrated along
exact ray intersections with its1pc Cartesian cells. Conversion is
`A_G=2.5/ln(10)*tau_G`, `A_G/A_V=0.789` from Wang & Chen2019 Table3
([paper](https://arxiv.org/pdf/1904.04575)), and the same fixed`R_V=3.1`.

Raw-map comparison: **19/20** within a factor2, with direction13 at0.428×.
Thresholded ellipsoid column with a hot`n_H=0.0039 cm^-3` background:
**1/20** within a factor2; direction9 is5.30×. This second number isolates the
dense reduction, not the parent simulation's complete local-cloud profile.
The threshold removes most diffuse dust; envelope expansion can overestimate
columns where selected regions overlap. A diffuse field/full-column treatment
and an independently justified approximation are needed. A successful raw FITS
check does not establish successful modeled extinction.

Every direction, conversion and result is recorded in
`sources/dense-verification.json`. `tools/ism_dense_ref.py --sources FITS LEIKE_H5
CROP_PREFIX` reruns these independent measurements; it is an oracle, never a
production generator.

## LLCC source geometry and AC6(c): partial, not accepted

The two outlines in`sources/llcc_outline.tsv` are independently traced from
Peek2011 Figure2, PDFp5, [paper](https://arxiv.org/pdf/1104.5232). They represent
the21cm emission footprint at about0.25deg digitisation precision; Figure3's
stricter contour is a different observable. Ear clipping produces23 finite
triangular sheets, each represented by three angular halfspaces and a finite
depth slab. The midpoint17.8pc and thickness200AU are adopted representative
approximations from Meyer2012 abstract/Figure14, PDFp38,
[paper](https://arxiv.org/pdf/1204.5980);`n_H=3000 cm^-3` is adopted.
CDS/SIMBAD ICRS coordinates and source tracer flags are in`llcc_members.tsv`.

Independent oracle finite chords cross HD83023, HD85259 and HD84722. HIP47513
lies angularly on the emission footprint but is foreground at11.26pc, so its
finite route does not cross. Regulus lies outside the footprint and has no NaI;
it **does have weak CaII**, so it is not a gas nondetection.

**HD84937 has observed NaI absorption but no21cm emission and falls outside the
independently traced21cm outline.** Thus all-NaI intersection acceptance fails.
Do not expand the radio outline to fit this anchor; an independently sourced
optical absorption envelope or a scientifically reviewed model extension is
required. The root integration must additionally verify the finite LLCC route's
drive-hold refusal at0.999999c and acceptance at0.998c, plus map shape rendering.

## Reproduction and remaining review

`make ism-raw ism-crop ism-dense-data` executes the actual shell/Godot/AILANG
pipeline (raw maps and intermediates remain ignored). `make fits-slice-test
ism-dense-test` runs the small functional checks without multi-GB downloads.
Interpreter/VM component parity avoids the pinned v0.52.0 named-test callback
resolver defect reported as`inbox_1791655250615_88f6e234`; the check is executed,
not skipped. The P2/P3 visual/scientific review gates and parent integration
acceptance remain outstanding. These scientific failures are not waived.
