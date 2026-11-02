#!/bin/sh
set -eu
ROOT=${1:?absolute game ROOT}
python3 -I - "$ROOT" <<'PY'
import runpy,sys
from pathlib import Path
c=runpy.run_path(str(Path(sys.argv[1])/'tools/kerr_ref.py'))['capture_oracle']
probes=[(20,0,26,0,False,'captured'),(20,0,28,0,False,'escaped'),
 (20,0,27,0,False,'critical'),(20,0,27,0,True,'escaped'),
 (2.1,0,28,0,True,'captured'),(3,0,28,0,False,'invalid'),
 (20,-1.8,27,.9,False,'critical'),(20,-1.8,27.00027,.9,False,'escaped'),
 (20,-1.8,26.99973,.9,False,'captured')]
for *args,want in probes: assert c(*args)==want,(args,c(*args),want)
print('kerr-capture-oracle: 9 independent topology probes PASS')
PY
