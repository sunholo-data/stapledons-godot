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
    rows = [r for r in data['records'] if r['spin'] == spin]
    assert [r['precise'] for r in rows] == [outer, inner], f'precise17/V31: {spin}'
    assert rows[0]['package_R'] == radius, f'factor2 R=u/2: {spin}'
    assert rows[0]['display'] == format(values[0], '.6f'), f'separate display: {spin}'
for spin in ('-0.1', '1', '1.1', 'NaN', 'Infinity', '-Infinity'):
    try:
        ref['horizons'](spin)
    except ValueError as error:
        assert 'finite 0 <= spin < 1' in str(error), f'validation before sqrt: {spin}'
    else:
        raise AssertionError(f'invalid spin accepted: {spin}')
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
echo "kerr-oracle: RK-1/2 seed assertions satisfied (RK-3/9 deferred)"
