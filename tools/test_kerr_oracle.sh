#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd) || exit 1
fail() {
    echo "kerr-oracle: $*" >&2
    exit 1
}
[ -f "$root/tools/kerr_ref.py" ] || fail "missing oracle tools/kerr_ref.py"
check() {
    python3 -I - "$root" <<'PY'
import copy, json, runpy, subprocess, sys, tempfile
from pathlib import Path
root = Path(sys.argv[1])
oracle = root / 'tools/kerr_ref.py'
def run(*args):
    return subprocess.run([sys.executable, '-I', str(oracle), *map(str, args)], capture_output=True)
ref = runpy.run_path(str(oracle))
anchors = {'0': ('2', '0', '1'),
           '0.5': ('1.8660254037844386', '0.13397459621556135', '0.93301270189221932'),
           '0.9': ('1.4358898943540674', '0.56411010564593264', '0.71794494717703368'),
           '0.998': ('1.0632139225171164', '0.93678607748288357', '0.53160696125855822')}
generated = run()
assert generated.returncode == 0, 'stdout generation failed'
data = json.loads(generated.stdout)
for spin, (outer, inner, radius) in anchors.items():
    values = ref['horizons'](spin)
    assert tuple(format(v, '.17g') for v in values) == (outer, inner), f'horizon branch/V31: {spin}'
    rows = [r for r in data['records'] if r['spin'] == spin and r['id'] in ('RK-1', 'RK-2')]
    assert [r['precise'] for r in rows] == [outer, inner], f'precise17/V31: {spin}'
    assert rows[0]['package_R'] == radius, f'factor2 R=u/2: {spin}'
    assert rows[0]['display'] == format(values[0], '.6f'), f'separate display: {spin}'
from decimal import Decimal
# Literal reviewed anchors: design doc lines 86-94 and 336-349 (never copied from oracle output).
NEW = {('RK-4', '0.9', 'photon-pro'): '1.5578546274233828', ('RK-4', '0.9', 'photon-retro'): '3.9102679391030367',
       ('RK-5', '0.998', 'photon-pro'): '1.0739092576799517', ('RK-5', '0.998', 'photon-retro'): '3.9982218928479460',
       ('RK-6', '0.5', 'isco-pro'): '4.2330025295308257', ('RK-6', '0.5', 'isco-retro'): '7.5545847145123584',
       ('RK-7', '0.9', 'isco-pro'): '2.3208830417618872', ('RK-7', '0.9', 'isco-retro'): '8.7173522796064893',
       ('RK-8', '0.9', 'clock-pro'): '0.37086794439864592', ('RK-8', '0.9', 'clock-retro'): '0.79319251811829484',
       ('RK-8b', '0.998', 'clock-pro'): '0.092670308365368573'}
rows = {(r['id'], r['spin'], r['quantity']): r for r in data['records']}
assert len(NEW) == 11 and all(key in rows for key in NEW), 'identity: missing RK-4..RK-8b record'
for key, anchor in NEW.items():
    assert Decimal(rows[key]['precise']) == Decimal(anchor), f'precise17 anchor: {key}'
    if key[2].startswith('clock'):
        assert rows[key]['package_R'] is None, f'clock package_R not null: {key}'
    else:
        assert abs(Decimal(rows[key]['package_R']) - Decimal(anchor) / 2) < Decimal('1e-16'), f'factor2 R=u/2: {key}'
for key, anchor in NEW.items():
    if key[2].startswith(('photon', 'isco')) and key[2].endswith('-pro'):
        retro = rows[(key[0], key[1], key[2].replace('-pro', '-retro'))]['precise']
        assert Decimal(rows[key]['precise']) < Decimal(retro), f'prograde not below retrograde (pro/retro swap): {key}'
for spin in ('-0.1', '1', '1.1', 'NaN', 'Infinity', '-Infinity'):
    for name, call in (('horizons', lambda s: ref['horizons'](s)), ('photon_orbits', lambda s: ref['photon_orbits'](s)),
                       ('isco_radii', lambda s: ref['isco_radii'](s)), ('orbit_clock', lambda s: ref['orbit_clock'](s, 1))):
        try:
            call(spin)
        except ValueError as error:
            assert 'finite 0 <= spin < 1' in str(error), f'validation before sqrt: {name} {spin}'
        else:
            raise AssertionError(f'invalid spin accepted by {name}: {spin}')
fixture = root / 'tests/fixtures/kerr/rk.json'
before = fixture.read_bytes()
for command in ('--check', 'check'):
    assert run(command, fixture).returncode == 0, f'{command} valid fixture rejected'
    assert fixture.read_bytes() == before, f'{command} rewrote fixture'
assert json.loads(before) == data, 'fixture differs from stdout'
with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / 'bad.json'
    assert run('--check', path).returncode == 1, 'missing fixture accepted'
    def rejected(raw, label):
        path.write_bytes(raw)
        assert run('--check', path).returncode == 1, f'{label} accepted'
        assert path.read_bytes() == raw, f'{label} rewritten'
    for raw in (b'', b'{}', b'[]', b'{', b'{"records": []}'):
        rejected(raw, 'empty/schema')
    rejected(before.replace(b'{', b'{"schema":"kerr-rk-seed-v1",', 1), 'duplicate JSON key')
    for key, wrong in (('unit', 'wrongunit'), ('source', 'wrongsource'), ('schema', 1)):
        bad = dict(data, **{key: wrong})
        rejected(json.dumps(bad).encode(), key)
    for key in data['records'][0]:
        for wrong in (None, 'wrong', data['records'][0]['display']):
            if wrong == data['records'][0][key]:
                continue
            bad = copy.deepcopy(data)
            bad['records'][0][key] = wrong
            rejected(json.dumps(bad).encode(), f'record {key}')
        del bad['records'][0][key]
        rejected(json.dumps(bad).encode(), f'missing {key}')
    data['records'].append(data['records'][0])
    rejected(json.dumps(data).encode(), 'duplicate composite identity')
PY
}
check || fail "assertions failed"
echo "kerr-oracle: RK-1/2 and RK-4..RK-8, RK-8b assertions satisfied (RK-3, RK-9 and the rest deferred)"
