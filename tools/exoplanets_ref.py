"""Independent W2.0 test oracle; never generates or changes catalogue data.

Use Python's independent CSV/JSON/decimal parsers to compare every nonmissing
NASA scalar with the output as IEEE-754 binary64, including signed zero. This
catches shared AILANG parser/codegen bugs that VM/interpreter parity cannot.
Run from the repo root: python3 tools/exoplanets_ref.py
"""
import csv
import json
import struct
from pathlib import Path
root = Path.cwd()
raw = root / 'data/raw/exoplanets_ps_100pc_20261102.csv'
planets = json.loads((root / 'data/planets/exoplanets.json').read_text())['planets']
by_id = {p['id']: p for p in planets}
columns = {
 'ra':'ra_deg', 'dec':'dec_deg', 'sy_dist':'distance_pc', 'pl_orbper':'period_d',
 'pl_orbsmax':'a_au', 'pl_orbeccen':'e', 'pl_rade':'radius_earth',
 'pl_masse':'mass_earth','pl_msinie':'msini_earth','pl_bmasse':'best_mass_earth',
 'pl_insol':'insolation_earth','pl_eqt':'equilibrium_k','pl_orbincl':'incl_deg',
 'st_teff':'host_teff_k','st_rad':'host_radius_sun','st_mass':'host_mass_sun',
 'st_lum':'host_log_luminosity_sun'
}
rows = list(csv.DictReader(raw.open()))
checked = 0
for r in rows:
    ident = {'Proxima Cen b':'proxima-b', 'Proxima Cen d':'proxima-d'}.get(r['pl_name'], 'nasa-ps:'+r['pl_name'])
    p = by_id[ident]
    fields = {f['key']:f for f in p['archiveFields']}
    assert len(fields) == sum(r[c] != '' for c in columns), ident
    for source, target in columns.items():
        if r[source] == '':
            assert target not in fields, (ident, target)
            continue
        f = fields[target]
        assert struct.pack('>d', float(r[source])) == struct.pack('>d', float(f['value'])), (ident, target)
        if target in ('equilibrium_k','insolation_earth'):
            assert f['provenance'] == 'inferred', (ident, target)
        if target == 'best_mass_earth' and r['pl_bmassprov'] == 'M-R relationship':
            assert f['provenance'] == 'inferred', (ident, target)
        checked += 1
print(f'exoplanets independent oracle: {len(rows)} snapshot planets, {checked} nonmissing scalars bit-identical (IEEE754 binary64); missingness and derived provenance correct')
