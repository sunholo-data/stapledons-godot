#!/bin/sh
# Escaping-ray check only. KS finite-difference oracle cannot classify capture.
set -eu
ROOT=${1:-$(pwd)}
python3 -I - "$ROOT" <<'PY'
import json,math,runpy,sys
from pathlib import Path
root=Path(sys.argv[1])
trace=runpy.run_path(str(root/'tools/kerr_ks_ref.py'))['trace']
data=json.loads((root/'tests/fixtures/kerr/ks_evaluation.json').read_text())
count=0;worst=0.0
for row in data['records']:
    if row['status']!='escaped': continue
    assert abs(sum(v*v for v in row['n'])-1)<1e-12
    ref=trace(row['u'],row['s'],row['n'])
    assert ref['status']=='escaped',ref
    error=math.dist(ref['sky'],row['sky'])
    assert error<1e-5,(row,error)
    count+=1;worst=max(worst,error)
assert count==140,count
print(f'kerr-ks-oracle: {count} escaping rays,0 failures,max {worst:.9g} rad; capture unresolved by this oracle')
PY
