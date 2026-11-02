#!/bin/sh
# Independent Decimal60 shadow fixture audit; never a production generator.
set -eu
ROOT=${1:?absolute game ROOT}
case "$ROOT" in /*) ;; *) exit 2;; esac
python3 -I - "$ROOT" <<'PY'
import json, runpy, sys
from pathlib import Path
from decimal import Decimal as D
root=Path(sys.argv[1]); ref=runpy.run_path(str(root/'tools/kerr_ref.py'))
actual=json.loads((root/'tests/fixtures/kerr/shadow.json').read_text())
assert actual==ref['shadow_fixture'](), 'shadow fixture drift'
r={(p['id'],p['spin'],p['quantity']):D(p['precise']) for p in actual['records']}
assert len(r)==13==len(actual['records']), 'shadow completeness'
for key,value in {
 ('RK-14','0.9','alpha-min'):'-2.8444214034761693',('RK-14','0.9','alpha-max'):'6.8323192304466666',
 ('RK-14','0.998','alpha-min'):'-2.1108877945528310',('RK-14','0.998','alpha-max'):'6.9966662713999613',
 ('RK-15','0.9','beta-max'):'5.1961524227066319',
 ('RK-16','0.9','uniform-u-mean-N200000'):'5.0437368945142949',('RK-16','0.998','uniform-u-mean-N200000'):'4.8770013845209779',
 ('RK-17','0.9','alpha-min'):'-3.4170599872799702',('RK-17','0.9','alpha-max'):'6.2964531467076725',
 ('RK-17','0.9','beta-max'):'5.0696345295581239'}.items():
 assert r[key]==D(value), f'shadow literal {key}'
assert actual['unit']=='GM/c^2; observer at infinity', 'infinity units'
assert {key[0] for key in r}=={'RK-14','RK-15','RK-16','RK-17'}, 'shadow IDs'
print('kerr-shadow-oracle: RK-14..17 (13 records), Decimal60 and literal pins PASS')
PY
