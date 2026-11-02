# R3-WORLDS W2.0 measured exoplanet snapshot

Retrieved 2026-11-02 from the [NASA Exoplanet Archive TAP service](https://exoplanetarchive.ipac.caltech.edu/docs/TAP/usingTAP.html).
The [PS column definitions](https://exoplanetarchive.ipac.caltech.edu/docs/API_PS_columns.html)
explain `default_flag` (one default published parameter set per planet), missing
values and `pl_bmassprov`. The query selects a self-contained PS row rather than
mixing measurements from the composite table.

```sql
select pl_name,hostname,gaia_dr3_id,ra,dec,sy_dist,pl_orbper,pl_orbsmax,
       pl_orbeccen,pl_rade,pl_masse,pl_msinie,pl_bmasse,pl_bmassprov,
       pl_insol,pl_eqt,pl_orbincl,st_teff,st_rad,st_mass,st_lum,
       st_spectype,pl_refname
from ps
where default_flag=1 and sy_dist<=100
order by hostname,pl_name
```

The HTTP request is GET `/TAP/sync`, query as above, `format=csv`. Raw file:
[exoplanets_ps_100pc_20261102.csv](https://storage.googleapis.com/stapledons-voyage-assets/planets/exoplanets_ps_100pc_20261102.csv).
SHA256: `ce6345482ca387dd6a8fca73d909d25b78c3ce24eea5efab1afdbda279ea335b`.
The corresponding pin is appended to `EXOPLANETS.SHA256`; older alpha Cen and
TRAPPIST-1 pins remain untouched.

The snapshot has **1590 confirmed planets in 1077 hosts**, including **412
planets whose archive distance is <=25 pc**. TRAPPIST-1's default PS rows do
not pass this distance predicate (the default distance is absent); the seven
hand-cited curated planets restore them explicitly. This is not a claim that
the snapshot includes every known nearby planet regardless of missing data.

`sim/tools/exoplanets.ail` parses the CSV and cross-matches exact Gaia DR3 ids
first, then unique positions within one arcsecond. It retains unmatched rows
with `inRegistry=false`, original `archiveHostId`, spectral class, mass
provenance and publication reference. It never guesses a radius or promotes a
minimum mass. Each non-missing numeric scalar becomes a Field; unknown scalars
are omitted. `host_log_luminosity_sun` is the archive's logarithm, not linear
luminosity. Best mass carries its `Mass`, `Msini` or `M-R relationship` label;
the last is `inferred`. Equilibrium temperature and insolation carry `inferred`
provenance: the NASA column definitions describe the former as a blackbody
model quantity. They are retained exactly as published, not promoted to a
measured surface climate. Bulk appearance is unknown, rather than measured.

The output contains **1599 planets (including 2 curated candidates), 1079
hosts**, and **412 planets on 241 registry hosts**. The 11 alpha Cen/TRAPPIST-1
curated planet rows keep every existing Field, including notes, citations and
assumptions. The two Proxima archive rows are retained in `archiveFields`.
No overlapping curated numeric values differ in this snapshot; differences
are written to `exoplanets_curated_differences.txt` during regeneration.
Curated top-level distance comes from the navigation catalogue and is labelled
in the source string; it does not alter any curated Field.

Commands: `tools/exoplanets.sh fetch|build|check`. `check` regenerates to a
scratch directory and compares JSON, AILANG and difference report byte for byte.

`make exoplanets-check` also runs the independent read-only Python oracle
(`tools/exoplanets_ref.py`) to compare every raw scalar with JSON by IEEE-754
binary64 bits. The AILANG compiled-table witness compares every record scalar
and provenance string explicitly and hashes full JSON; human `show()` output
is truncated and is never used for whole-data equality or digests.
The generator writes the source module from parsed float64 values with
round-trip formatting, split into chunks; the simulation can import it without
runtime file I/O. Tests cover CSV quoting, exact float64 values, minimum mass,
unique positional matching, unmatched retention and curated equality.

The one-arcsecond fallback does not invent an astrometric epoch or propagate
proper motions without a stated input epoch. Rows which do not match remain
unmatched. Exact Gaia identity handles proper-motion offsets where available.
A future catalogue expansion can re-run the match from the retained identity
and coordinates. NASA/IPAC Exoplanet Archive attribution is required.
