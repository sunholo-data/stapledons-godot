#!/bin/sh
set -eu
ROOT=${1:?absolute game ROOT}
case "$ROOT" in /*) ;; *) exit 2;; esac
python3 -I - "$ROOT" <<'PY'
import json,runpy,sys
from decimal import Decimal as D
from pathlib import Path
root=Path(sys.argv[1]); f=runpy.run_path(str(root/'tools/kerr_curvature_ref.py'))['tides']
rows=json.loads((root/'tests/fixtures/kerr/curvature.json').read_text())
assert len(rows)==80, 'curvature completeness'
keys=set()
for row in rows:
 key=(row['s'],row['u'],row['mode']); assert key not in keys; keys.add(key)
 actual=f(row['u'],row['s'],row['mode'])
 assert json.loads(json.dumps(actual,default=str))==row, f'curvature fixture drift {key}'
 for name in ('trace','ricci','orth'): assert abs(D(row[name]))<D('1e-48'),(key,name)
 assert abs(sum(D(x) for x in row['eigen']))<D('1e-48'), 'vacuum trace'
 if row['s']=='0' and row['mode'] in ('hover','radial','zamo'):
  q=1/D(row['u'])**3; assert max(abs(D(a)-b) for a,b in zip(row['eigen'],[-2*q,q,q]))<D('1e-48')
# Reviewed literals from independent metric curvature, not the package.
for mode,eigen in {'zamo':['-0.032464437581687481847','0.015625','0.016839437581687481847'],
 'hover':['-0.03599609375','0.015625','0.02037109375'],
 'pro':['-0.038712993421052631579','0.015625','0.023087993421052631579'],
 'retro':['-1.016796875','0.015625','1.001171875'],
 'radial':['-0.037578125','0.015625','0.021953125']}.items():
 r=next(r for r in rows if r['s']=='0.9' and r['u']=='4' and r['mode']==mode)
 assert max(abs(D(a)-D(b)) for a,b in zip(r['eigen'],eigen))<D('1e-20'),mode
for args in [('NaN','.9','hover'),('4','Infinity','pro'),('1','.9','hover'),('4','.9','garbage')]:
 try: f(*args)
 except ValueError: pass
 else: raise AssertionError(('invalid accepted',args))
print('kerr-curvature-oracle: 80 metric-derived frames, literal/sign/trace/unit/domain checks PASS')
PY
