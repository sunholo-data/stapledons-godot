#!/usr/bin/env python3
"""Bounded AILANG-only preflight; Python prepares inputs and checks evidence."""
import csv
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time
import extract

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / '.godot/tmp/catalogue-probe'

def sha(data):
    return hashlib.sha256(data).hexdigest()

def bounded(cmd):
    process = subprocess.Popen(cmd, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True)
    try:
        stdout, stderr = process.communicate(timeout=60)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        stdout, stderr = process.communicate()
        raise subprocess.TimeoutExpired(cmd, 60, output=stdout, stderr=stderr)
    return subprocess.CompletedProcess(cmd, process.returncode, stdout, stderr)

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'report.json').unlink(missing_ok=True)
    report = {'status': 'failed', 'runs': [], 'scope': 'normal photometry only; args-file load plus runtime/output; excludes FS shell read, WD fit, sort and binary writing'}
    try:
        ailang = os.environ.get('AILANG', str(ROOT / 'runtime/bin/ailang'))
        version = subprocess.check_output([ailang, '--version'], timeout=10).decode()
        lock = json.loads((ROOT / 'sim/ailang.lock').read_text())
        report.update(runtime=version, lock=lock, lock_sha256=sha((ROOT / 'sim/ailang.lock').read_bytes()))
        assert 'AILANG v0.47.2\n' in version and lock['ailang_version'] == 'v0.47.2' and any(p['name'] == 'sunholo/relativity' and p['version'] == '0.2.0' for p in lock['packages']), 'wrong pinned runtime/package'
        rows = []
        sources = []
        for name in ['gcns_head.dat', 'gcns_wd.dat', 'gcns_missing_phot.dat']:
            path = ROOT / 'tools/fixtures' / name
            parsed, _ = extract.parse_gcns(path.read_text())
            rows.extend(parsed[:1])
            sources.append({'path': str(path.relative_to(ROOT)), 'sha256': sha(path.read_bytes())})
        fixture = extract.format_csv(rows)
        test = (ROOT / 'sim/tools/catalogue_probe_test.ail').read_text()
        literal = re.search(r'fixture\(\) -> string = (".*");', test).group(1)
        assert json.loads(literal) == fixture, 'AILANG fixture differs from real-byte parser output'
        inputs = [('fixture', fixture, sources)]
        real = ROOT / 'data/raw/gcns.csv'
        assert real.is_file(), 'missing real data: run downloader medium then tools/extract.py gcns'
        with real.open() as stream:
            lines = [next(stream) for _ in range(5001)]
        report['raw_download_sha256sums'] = (ROOT / 'data/raw/SHA256SUMS').read_text() if (ROOT / 'data/raw/SHA256SUMS').is_file() else None
        inputs.append(('real5k', ''.join(lines), [{'path': 'data/raw/gcns.csv', 'sha256': sha(real.read_bytes())}]))
        for name, data, provenance in inputs:
            path = OUT / (name + '.csv')
            path.write_text(data)
            args = OUT / (name + '.args.json')
            args.write_text(json.dumps(data))
            parsed = list(csv.DictReader(data.splitlines()))
            expected = [len(parsed), sum(r['wd'] == '0' and r['G'] != '' and r['BPRP'] != '' for r in parsed),
                        sum(r['wd'] == '1' for r in parsed), sum(r['G'] == '' or r['BPRP'] == '' for r in parsed)]
            assert expected[1] > 0 and (name != 'real5k' or expected[0] == 5000), 'vacuous workload'
            reference = None
            for index in range(6):
                label = name + ('-interp' if index == 0 else '-vm' + str(index))
                cmd = [ailang, 'run', '--quiet', '--package-dir', 'sim', '--entry', 'render', '--args-file', str(args), 'sim/tools/catalogue_probe.ail']
                if index:
                    cmd[2:2] = ['--bytecode', '--strict-bytecode']
                if sys.platform == 'darwin':
                    cmd = ['/usr/bin/time', '-l'] + cmd
                start = time.monotonic()
                try:
                    result = bounded(cmd)
                except subprocess.TimeoutExpired as error:
                    (OUT / (label + '.stderr')).write_bytes(error.stderr or b'')
                    (OUT / (label + '.stdout')).write_bytes(error.output or b'')
                    report['runs'].append({'label': label, 'timeout_s': 60})
                    raise RuntimeError(label + ': timeout; performance gate unmet')
                elapsed = time.monotonic() - start
                (OUT / (label + '.stdout')).write_bytes(result.stdout)
                (OUT / (label + '.stderr')).write_bytes(result.stderr)
                rss = re.search(rb'(\d+)\s+maximum resident set size', result.stderr)
                report['runs'].append({'label': label, 'seconds': elapsed, 'peak_rss_bytes': int(rss[1]) if rss else None,
                                       'sha256': sha(result.stdout), 'stderr_sha256': sha(result.stderr), 'input_sha256': sha(data.encode()), 'provenance': provenance, 'counts': expected, 'returncode': result.returncode})
                assert result.returncode == 0, label + ': runtime failure'
                output = result.stdout.decode().splitlines()
                assert output[0] == 'counts,' + ','.join(map(str, expected)), label + ': accounting/error'
                assert len(output) == len(parsed) + 1 and all(line.startswith(','.join(row.values()) + ',') for line, row in zip(output[1:], parsed)), label + ': missing/duplicated/reordered rows'
                for line, row in zip(output[1:], parsed):
                    if row['G'] == '' or row['BPRP'] == '':
                        assert line.endswith(',missing'), label + ': defaulted missing photometry'
                    elif row['wd'] == '1':
                        assert line.endswith(',wd_deferred'), label + ': WD incorrectly transformed'
                if reference is None:
                    reference = result.stdout
                assert result.stdout == reference, label + ': parity mismatch'
            if name == 'fixture':
                for vm_shell in [False, True]:
                    label = 'fixture-shell-' + ('vm' if vm_shell else 'interp')
                    cmd = [ailang, 'run', '--quiet', '--package-dir', 'sim', '--caps', 'FS,IO', '--entry', 'main', '--args-json', json.dumps(str(path)), 'sim/tools/catalogue_probe.ail']
                    if vm_shell:
                        cmd.insert(2, '--bytecode')
                    result = bounded(cmd)
                    (OUT / (label + '.stdout')).write_bytes(result.stdout)
                    (OUT / (label + '.stderr')).write_bytes(result.stderr)
                    assert result.returncode == 0 and result.stdout == reference, label + ': FS shell parity failure'
                report['fixture_fs_shell_parity'] = 'interpreter and bridged VM identical to pure output'
            vm = [r['seconds'] for r in report['runs'] if r['label'].startswith(name + '-vm')]
            report[name] = {'parity_runs': 5, 'counts': expected, 'vm_mean_seconds': sum(vm) / 5}
        seconds = report['real5k']['vm_mean_seconds']
        report['estimates_seconds'] = {'medium_x10': seconds * 10, 'large_x66.2624': seconds * 66.2624,
                                     'warning': 'estimates exclude WD fit, sort, binary writing; not final medium timing'}
        report['status'] = 'passed'
    except Exception as error:
        report['error'] = str(error)
    (OUT / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k not in ['runs', 'lock', 'runtime']}, indent=2))
    return 0 if report['status'] == 'passed' else 1

if __name__ == '__main__':
    sys.exit(main())
