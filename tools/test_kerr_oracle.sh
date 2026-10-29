#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd) || exit 1
fail() {
    echo "kerr-oracle: $*" >&2
    exit 1
}
[ -f "$root/tools/kerr_ref.py" ] || fail "missing oracle tools/kerr_ref.py"
check() {
    python3 -I - "$1" <<'PY'
import copy, json, runpy, subprocess, sys, tempfile
from pathlib import Path
root = Path(sys.argv[1])
oracle = root / 'tools/kerr_ref.py'
def run(*args):
    return subprocess.run([sys.executable, '-I', str(oracle), *map(str, args)], capture_output=True)
ref = runpy.run_path(str(oracle))
assert ref['getcontext']().prec == 60, 'Decimal60 precision'
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
# Doc literals: design lines 86-105 and V31/V34 (never copied from oracle output); rows must exist first.
DOC = {('RK-10', '0.9', 'frame-drag-static-limit'): '0.16014234875444840',
       ('RK-11', '0.9', 'lapse-static-limit'): '0.37964208654863802',
       ('RK-12', '0.9', 'zamo-speed-isco-pro'): '0.62454869546086524',
       ('RK-12', '0.5', 'zamo-speed-isco-pro'): '0.56164924228192780',
       ('RK-13', '0.9', 'static-clock-static-limit'): '0',
       ('RK-18', '0.9', 'rs-km'): '29.532500761002495', ('RK-18', '0.9', 'static-limit-km'): '29.532500761002495',
       ('RK-18', '0.9', 'horizon-km'): '21.202709698863643', ('RK-18', '0.9', 'isco-pro-km'): '34.270740098515360',
       ('RK-18', '0.9', 'period-ms'): '1.3727616115380832', ('RK-18', '0.9', 'omega-h-rad-s'): '6362.7059001439946',
       ('RK-3', '0.5', 'static-limit'): '2', ('RK-3', '0.9', 'static-limit'): '2', ('RK-3', '0.998', 'static-limit'): '2',
       ('RK-9', '0.9', 'horizon-omega'): '0.31339450313662925',
       ('RK-Q1', '0', 'photon-pro'): '3', ('RK-Q1', '0', 'photon-retro'): '3', ('RK-Q1', '0', 'isco-pro'): '6',
       ('RK-Q1', '0', 'isco-retro'): '6', ('RK-Q1', '0', 'frame-drag'): '0', ('RK-Q1', '0', 'shadow'): '5.1961524227066319'}
for key, anchor in DOC.items():
    assert key in rows, f'missing record: {key}'
    assert Decimal(rows[key]['precise']) == Decimal(anchor), f'doc literal: {key}'
# Exactness reads the oracle's outputs; s=0 members are exact Decimal values, not rounded approximations.
assert ref['photon_orbits']('0') == (Decimal(3), Decimal(3)), 'RK-Q1 s=0 photon orbits not exact'
assert ref['isco_radii']('0') == (Decimal(6), Decimal(6)), 'RK-Q1 s=0 ISCO not exact'
assert ref['static_limit']('0') == ref['horizons']('0')[0] == Decimal(2), 'RK-Q1 s=0 static limit != horizon'
assert abs(Decimal(rows[('RK-Q1', '0', 'shadow')]['precise']) - 3 * Decimal(3).sqrt()) < Decimal('1e-16'), 'RK-Q1 shadow != 3 sqrt(3)'
assert ref['static_clock']('2', '0.9') == 0, 'RK-13 not exactly 0 at the static limit'
try:
    ref['static_clock']('1.9', '0.9')
except Exception as error:
    assert type(error) is ValueError and 'no static observer' in str(error), f'RK-13 u<2 not refused: {error!r}'
else:
    raise AssertionError('RK-13 u<2 accepted')
for u, anchor in (('4.1', 0.71567808542054678), ('6', 0.81649658092772603), ('20', 0.94868329805051377)):
    # V34 anchors are binary64 numbers: 1e-15 relative tolerance, not Decimal equality.
    assert abs(float(ref['static_clock'](u, '0')) - anchor) <= 1e-15 * anchor, f'V34 static clock s=0: {u}'
near = 1 - 2.0 ** -53  # exact binary64 spin; finiteness only, no accuracy claim near 1
probe = [*ref['horizons'](near), *ref['photon_orbits'](near), *ref['isco_radii'](near),
         ref['orbit_clock'](near, 1), ref['orbit_clock'](near, -1)]
assert all(value.is_finite() for value in probe), 'near-extremal s=1-2^-53 not finite'
for spin in ('-0.1', '1', '1.1', 'NaN', 'Infinity', '-Infinity'):
    for name, call in (('horizons', lambda s: ref['horizons'](s)), ('photon_orbits', lambda s: ref['photon_orbits'](s)),
                       ('isco_radii', lambda s: ref['isco_radii'](s)), ('orbit_clock', lambda s: ref['orbit_clock'](s, 1)),
                       ('frame_drag', lambda s: ref['frame_drag']('2', s)), ('zamo_lapse', lambda s: ref['zamo_lapse']('2', s)),
                       ('zamo_speed', lambda s: ref['zamo_speed'](s)), ('static_clock', lambda s: ref['static_clock']('2', s)),
                       ('horizon_omega', lambda s: ref['horizon_omega'](s)), ('static_limit', lambda s: ref['static_limit'](s))):
        try:
            call(spin)
        except (ValueError, ArithmeticError) as error:
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
mutate() {
    python3 -I - "$1" "$2" <<'PY'
import sys
name, path = sys.argv[1], sys.argv[2]
old, new = {
    'factor2': ('format(u / 2, ".17g"), "formula": formula}', 'format(u, ".17g"), "formula": formula}'),
    'sqrt-branch': ('return 1 + delta, 1 - delta', 'return 1 - delta, 1 + delta'),
    'domain': ('if not s.is_finite() or not 0 <= s < 1:', 'if not s.is_finite():'),
    'nan': ('if not s.is_finite() or not 0 <= s < 1:', 'if not 0 <= s < 1:'),
    'six-decimal': ('format(value, ".17g"),\n            "display": format(value, ".6f"), "package_R": None, "formula": formula}',
                    'format(value, ".6f"),\n            "display": format(value, ".6f"), "package_R": None, "formula": formula}'),
    'empty-fixture': ('if actual != expected:', 'if actual != expected and actual.get("records"):'),
    'wrong-unit': ('if actual != expected:', 'if actual["records"] != expected["records"]:'),
    'precision': ('getcontext().prec = 60', 'getcontext().prec = 20'),
}[name]
text = open(path).read()
assert text.count(old) == 1, f'mutant {name}: old text not found exactly once'
open(path, 'w').write(text.replace(old, new))
PY
}
n=0
drill() {
    n=$((n + 1))
    tmp=$(mktemp -d) || exit 1
    trap 'rm -rf "$tmp"' EXIT
    mkdir -p "$tmp/tools" "$tmp/tests/fixtures/kerr" || exit 1
    cp "$root/tools/kerr_ref.py" "$tmp/tools/" || exit 1
    cp "$root/tests/fixtures/kerr/rk.json" "$tmp/tests/fixtures/kerr/" || exit 1
    mutate "$1" "$tmp/tools/kerr_ref.py" || exit 1
    if cmp -s "$root/tools/kerr_ref.py" "$tmp/tools/kerr_ref.py"; then
        echo "kerr-oracle drill $1: instrument failure, mutation changed nothing" >&2
        exit 3
    fi
    if check "$tmp" 2>"$tmp/err"; then
        echo "kerr-oracle drill $1: survived" >&2
        exit 1
    fi
    grep -F -q -- "$2" "$tmp/err" || { echo "kerr-oracle drill $1: wrong reason" >&2; cat "$tmp/err" >&2; exit 1; }
    echo "kerr-oracle drill $1: killed ($2)"
    rm -rf "$tmp"
}
check "$root" || fail "assertions failed"
drill factor2 'factor2 R=u/2' || exit 1
drill sqrt-branch 'horizon branch/V31' || exit 1
drill domain 'invalid spin accepted' || exit 1
drill nan 'validation before sqrt: horizons NaN' || exit 1
drill six-decimal "doc literal: ('RK-10'" || exit 1
drill empty-fixture 'empty/schema accepted' || exit 1
drill wrong-unit 'unit accepted' || exit 1
drill precision 'Decimal60 precision' || exit 1
test "$n" -eq 8 || fail "drill count is not 8"
echo "kerr-oracle: RK-1/2/3/9, RK-4..RK-8b, RK-10..RK-13, RK-18, RK-Q1 assertions satisfied (RK-14..RK-17 deferred)"
