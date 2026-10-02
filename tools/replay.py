#!/usr/bin/env python3
"""Replay harness (design m2-journey-core §M2.5; `make replay`, `make replay-record`).

usage:
  replay.py                       every case: tests/replays/*.ndjson + the generated session
  replay.py --case NAME ...       only these cases (alpha_cen, offaxis_v11_equiv, session10k, ...)
  replay.py --session PATH        one input log anywhere (M4); its golden sits beside it
  replay.py --record LOG|NAME|all write this architecture's golden(s) (a reviewed diff; never in make test)
  replay.py --compat [--case ...] `make replay-compat` (AI.3, design AC13): see below
  options: --ticks N (generated session size, default 10000 -> case session10k), --arch A

Per case: the log runs on the bytecode VM and on the tree-walking interpreter;
the two stdouts must be byte-identical, must hold one reply per input line up
to the first quit, and must equal the committed golden byte for byte (full
golden `NAME.state.ARCH.ndjson`) or by sha256 (`NAME.state.ARCH.sha256`, for
the generated session, whose output is ~4 MB, and any output over 256 KB). Goldens are per architecture:
std/math exp/log differ by 1 ulp between arm64 and x86_64 (ailang#1465), and
every journey runs through exp-derived floats. A missing golden is a failure.

AILANG comes from $AILANG (default `ailang`); its --version is printed. The
interpreter runs with --max-recursion-depth: ship.ail's read loop is a tail
call, which the VM eliminates and the interpreter does not (RT_REC_003 at
10,000 lines on v0.51.0, reported upstream).

--compat: protocol 2.1 changed only the first lines of every 2.0 golden. The
2.0 goldens are frozen in tests/replays/compat-2.0/ with the sha256 of each
input log (inputs.sha256). For each case whose input is unchanged since the
freeze, the 2.1 output (VM == interpreter) has exactly the new fields
stripped, as bytes: the hello's proto minor 1 -> 0, and in each full state
the params keys ai_max_open and ai_ttl_ticks (the last two of params) and
the ai section (the last of changes). Each must be present exactly once
where expected. The result must equal the frozen golden byte for byte (or
its sha256 for digest goldens). A case with a changed input, or without a
frozen golden, prints `skipped` with the reason; no case compared fails.
"""
import argparse
import concurrent.futures
import hashlib
import os
import platform
import re
import shlex
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INTERP_DEPTH = "100000"
DIGEST_OVER = 256 * 1024  # bytes: larger goldens are committed as a sha256 only
SESSION_RE = re.compile(r"^session(\d+)k$")
EXTRA = {}  # case name -> check(out_bytes, ctx) -> error string or None


def rel(path, ctx):
    r = os.path.relpath(path, ctx.root)
    return path if r.startswith("..") else r


def arch():
    m = platform.machine().lower()
    return {"aarch64": "arm64", "amd64": "x86_64"}.get(m, m)


def check(name):
    def deco(f):
        EXTRA[name] = f
        return f
    return deco


@check("alpha_cen")
def _alpha_cen(out, ctx):
    last = out.rstrip(b"\n").split(b"\n")[-1]
    return None if b'"k":"arrived"' in last else "last reply has no arrived event"


@check("diag_thrust600")
def _thrust600(out, ctx):
    n = out.count(b'"status":"ok"')
    return None if n == 601 else "expected 601 ok replies, got %d" % n


@check("offaxis_v11_equiv")
def _offaxis(out, ctx):
    golden = os.path.join(ctx.root, "tests", "fixtures", "v11_offaxis.%s.golden" % ctx.arch)
    path = os.path.join(ctx.scratch, "offaxis_v11_equiv.vm.ndjson")
    r = subprocess.run([sys.executable, os.path.join(ctx.root, "tests", "offaxis_v11_equiv.py"), golden, path],
                       capture_output=True, text=True)
    ctx.note(r.stdout.strip())
    return None if r.returncode == 0 else "v1.1 kinematics differ (AC13)"


def session_check(out, ctx, ticks):
    accepted = sum(1 for l in out.split(b"\n") if b'"status":"ok"' in l and b'"full":false' in l)
    return None if accepted == ticks else "expected %d accepted ticks, got %d" % (ticks, accepted)


class Ctx:
    def __init__(self, a):
        self.root = a.root
        self.replays = a.replays or os.path.join(a.root, "tests", "replays")
        self.scratch = a.scratch or os.path.join(a.root, ".godot", "tmp", "replay")
        self.arch = a.arch or arch()
        self.ailang = shlex.split(os.environ.get("AILANG", "ailang"))
        self.ticks = a.ticks
        os.makedirs(self.scratch, exist_ok=True)


class Note:
    """ctx plus a per-case notes list (cases run concurrently; nothing prints from a worker)."""
    def __init__(self, ctx, notes):
        self.__dict__.update(ctx.__dict__)
        self.note = notes.append


class Case:
    def __init__(self, name, log, golden_dir, ticks=None):
        self.name, self.log, self.golden_dir, self.ticks = name, log, golden_dir, ticks

    def golden(self, ctx, kind):
        return os.path.join(self.golden_dir, "%s.state.%s.%s" % (self.name, ctx.arch, kind))


def session_name(ticks):
    if ticks % 1000:
        sys.exit("--ticks must be a multiple of 1000")
    return "session%dk" % (ticks // 1000)


def generated(ctx, name):
    ticks = int(SESSION_RE.match(name).group(1)) * 1000
    log = os.path.join(ctx.scratch, name + ".ndjson")
    subprocess.run([sys.executable, os.path.join(ctx.root, "tools", "gen_session.py"), "--ticks", str(ticks), log], check=True)
    return Case(name, log, ctx.replays, ticks)


def case_of(ctx, ref):
    """A case by name (tests/replays/NAME.ndjson or a generated sessionNk) or by log path."""
    if SESSION_RE.match(ref):
        return generated(ctx, ref)
    if ref.endswith(".ndjson"):
        log = os.path.abspath(ref)
        return Case(os.path.basename(log)[:-len(".ndjson")], log, os.path.dirname(log))
    log = os.path.join(ctx.replays, ref + ".ndjson")
    if not os.path.exists(log):
        sys.exit("no replay case %s (%s)" % (ref, log))
    return Case(ref, log, ctx.replays)


def all_cases(ctx):
    names = sorted(f[:-len(".ndjson")] for f in os.listdir(ctx.replays)
                   if f.endswith(".ndjson") and ".state." not in f)
    return [case_of(ctx, n) for n in names] + [generated(ctx, session_name(ctx.ticks))]


def run(ctx, case, vm):
    args = ctx.ailang + ["run", "--quiet"] + (["--bytecode"] if vm else ["--max-recursion-depth", INTERP_DEPTH]) + \
        ["--package-dir", os.path.join(ctx.root, "sim"), "--caps", "IO", "--entry", "main", os.path.join(ctx.root, "sim", "ship.ail")]
    t = time.monotonic()
    with open(case.log, "rb") as f:
        r = subprocess.run(args, stdin=f, capture_output=True)
    dt = time.monotonic() - t
    if r.returncode != 0:
        raise RuntimeError("%s (%s) exited %d: %s" % (case.name, "VM" if vm else "interpreter", r.returncode, r.stderr.decode()[-400:]))
    return r.stdout, dt


def expected_replies(log):
    """One reply per input line up to (not including) the first quit; ship.ail stops there."""
    n = 0
    with open(log, "rb") as f:
        for line in f:
            if line.strip() == b"" or re.match(rb'^\{"v":2,"type":"quit"\}\s*$', line):
                break
            n += 1
    return n


def first_diff(a, b):
    la, lb = a.split(b"\n"), b.split(b"\n")
    for i, (x, y) in enumerate(zip(la, lb), start=1):
        if x != y:
            return "line %d differs:\n      got  %s\n      want %s" % (i, x[:240].decode(errors="replace"), y[:240].decode(errors="replace"))
    return "line count differs: got %d, want %d" % (len(la), len(lb))


def both(ctx, case):
    with concurrent.futures.ThreadPoolExecutor(2) as ex:
        vm, it = ex.submit(run, ctx, case, True), ex.submit(run, ctx, case, False)
        (out, tvm), (out_i, tit) = vm.result(), it.result()
    for tag, data in (("vm", out), ("interp", out_i)):
        with open(os.path.join(ctx.scratch, "%s.%s.ndjson" % (case.name, tag)), "wb") as f:
            f.write(data)
    return out, out_i, tvm, tit


def verify(ctx, case):
    """Returns a list of failure strings (empty = pass)."""
    out, out_i, tvm, tit = both(ctx, case)
    fails = []
    lines = out.count(b"\n")
    if out != out_i:
        fails.append("VM != interpreter: " + first_diff(out, out_i))
    want = expected_replies(case.log)
    if lines != want or not out.endswith(b"\n"):
        fails.append("expected %d replies (one per input line before quit), got %d" % (want, lines))
    full, digest = case.golden(ctx, "ndjson"), case.golden(ctx, "sha256")
    sha = hashlib.sha256(out).hexdigest()
    if os.path.exists(full):
        with open(full, "rb") as f:
            gold = f.read()
        if out != gold:
            fails.append("golden %s: %s" % (rel(full, ctx), first_diff(out, gold)))
        how = "cmp %s" % rel(full, ctx)
    elif os.path.exists(digest):
        with open(digest) as f:
            want_sha = f.read().split()[0]
        if sha != want_sha:
            fails.append("golden %s: sha256 %s != %s" % (rel(digest, ctx), sha, want_sha))
        how = "sha256 %s" % rel(digest, ctx)
    else:
        fails.append("no %s golden (%s or .sha256); review and run make replay-record LOG=%s" % (ctx.arch, rel(full, ctx), case.name))
        how = "no golden"
    extra = EXTRA.get(case.name)
    notes = []
    if extra:
        e = extra(out, Note(ctx, notes))
        if e:
            fails.append(e)
    if case.ticks:
        e = session_check(out, ctx, case.ticks)
        if e:
            fails.append(e)
    text = "  %s  %-22s %6d lines %9d bytes  VM %6.2f s  interpreter %6.2f s  sha256 %s  %s\n" % (
        "ok  " if not fails else "FAIL", case.name, lines, len(out), tvm, tit, sha[:16], how)
    text += "".join("        %s\n" % n for n in notes) + "".join("        %s\n" % f for f in fails)
    return text, fails


HELLO21 = rb'^(\{"v":2,"type":"hello","proto":\{"major":2,"minor":)1(\})'
AI_PARAMS = rb',"ai_max_open":[0-9]+,"ai_ttl_ticks":[0-9]+\}'
AI_SECTION = rb',"ai":\{"last_req":[0-9]+,"open":\[[^\]]*\],"core":"[0-9a-f]*"\}\}(,"events":)'


def strip21(out):
    """The 2.1 stream as 2.0 printed it, or raises ValueError naming the line that lacks a 2.1 field."""
    lines = out.split(b"\n")
    for i, line in enumerate(lines):
        if line.startswith(b'{"v":2,"type":"hello"'):
            line, n = re.subn(HELLO21, rb"\g<1>0\g<2>", line)
            if n != 1:
                raise ValueError("line %d: hello without proto minor 1 (not a 2.1 stream)" % (i + 1))
        if line.endswith(b'"full":true}'):
            line, a = re.subn(AI_PARAMS, b"}", line)
            line, b = re.subn(AI_SECTION, rb"}\g<1>", line)
            if (a, b) != (1, 1):
                raise ValueError("line %d: full state without the 2.1 params keys and ai section (%d, %d)" % (i + 1, a, b))
        lines[i] = line
    return b"\n".join(lines)


def frozen_inputs(compat):
    path = os.path.join(compat, "inputs.sha256")
    if not os.path.exists(path):
        return {}
    with open(path) as f:
        return {name: sha for sha, name in (l.split() for l in f if l.strip())}


def compat_one(ctx, case):
    """(text, fails, compared) for one case under --compat."""
    compat = os.path.join(ctx.replays, "compat-2.0")
    full = os.path.join(compat, "%s.state.%s.ndjson" % (case.name, ctx.arch))
    digest = os.path.join(compat, "%s.state.%s.sha256" % (case.name, ctx.arch))
    with open(case.log, "rb") as f:
        sha_in = hashlib.sha256(f.read()).hexdigest()
    want_in = frozen_inputs(compat).get(case.name + ".ndjson")
    why = None
    if not (os.path.exists(full) or os.path.exists(digest)) or want_in is None:
        why = "no 2.0 freeze for this case (%s)" % ctx.arch
    elif want_in != sha_in:
        why = "input changed since the freeze"
    if why:
        return "  skipped  %-22s %s\n" % (case.name, why), [], False
    out, out_i, tvm, tit = both(ctx, case)
    fails = []
    if out != out_i:
        fails.append("VM != interpreter: " + first_diff(out, out_i))
    try:
        stripped = strip21(out)
    except ValueError as e:
        stripped = None
        fails.append(str(e))
    if stripped is not None:
        if os.path.exists(full):
            with open(full, "rb") as f:
                gold = f.read()
            if stripped != gold:
                fails.append("frozen %s: %s" % (rel(full, ctx), first_diff(stripped, gold)))
            how = "cmp %s" % rel(full, ctx)
        else:
            with open(digest) as f:
                want_sha = f.read().split()[0]
            got = hashlib.sha256(stripped).hexdigest()
            if got != want_sha:
                fails.append("frozen %s: sha256 of the stripped stream %s != %s" % (rel(digest, ctx), got, want_sha))
            how = "sha256 %s" % rel(digest, ctx)
    else:
        how = "not stripped"
    text = "  %s  %-22s %6d lines  VM %6.2f s  interpreter %6.2f s  2.1 minus the new fields == 2.0: %s\n" % (
        "ok     " if not fails else "FAIL   ", case.name, out.count(b"\n"), tvm, tit, how)
    return text + "".join("        %s\n" % f for f in fails), fails, True


def compat_main(ctx, cases):
    t = time.monotonic()
    with concurrent.futures.ThreadPoolExecutor(max(1, min(len(cases), (os.cpu_count() or 2) // 2))) as ex:
        results = list(ex.map(lambda c: _guard_compat(ctx, c), cases))
    fails = sum(len(f) for _, f, _ in results)
    compared = sum(1 for _, _, c in results if c)
    for text, _, _ in results:
        sys.stdout.write(text)
    if compared == 0:
        print("replay-compat: no case compared (nothing frozen matches)")
        sys.exit(1)
    print("replay-compat: %d compared, %d skipped, %s (%.1f s wall)" % (
        compared, len(cases) - compared, "nothing else moved" if fails == 0 else "%d failures" % fails, time.monotonic() - t))
    sys.exit(1 if fails else 0)


def _guard_compat(ctx, case):
    try:
        return compat_one(ctx, case)
    except RuntimeError as e:
        return "  FAIL     %s\n" % e, [str(e)], True


def record(ctx, case):
    out, out_i, tvm, tit = both(ctx, case)
    if out != out_i:
        sys.exit("refusing to record %s: VM != interpreter: %s" % (case.name, first_diff(out, out_i)))
    want = expected_replies(case.log)
    if out.count(b"\n") != want:
        sys.exit("refusing to record %s: %d replies for %d input lines" % (case.name, out.count(b"\n"), want))
    full, digest = case.golden(ctx, "ndjson"), case.golden(ctx, "sha256")
    if case.ticks or len(out) > DIGEST_OVER:  # the generated session and large outputs: digest only
        if os.path.exists(full):
            os.remove(full)
        with open(digest, "w") as f:
            f.write("%s  %s.state.ndjson\n" % (hashlib.sha256(out).hexdigest(), case.name))
        path = digest
    else:
        with open(full, "wb") as f:
            f.write(out)
        path = full
    print("recorded %s (%d lines, VM %.2f s, interpreter %.2f s); review the diff before committing" % (
        rel(path, ctx), out.count(b"\n"), tvm, tit))


def main():
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--case", nargs="+")
    p.add_argument("--session")
    p.add_argument("--record")
    p.add_argument("--compat", action="store_true")
    p.add_argument("--ticks", type=int, default=int(os.environ.get("REPLAY_TICKS", "10000")))
    p.add_argument("--arch")
    p.add_argument("--root", default=ROOT)
    p.add_argument("--replays")
    p.add_argument("--scratch")
    a = p.parse_args()
    ctx = Ctx(a)
    ver = subprocess.run(ctx.ailang + ["--version"], capture_output=True, text=True).stdout.strip().split("\n")[0]
    print("replay: %s, %s (%s)" % (ver, ctx.arch, " ".join(ctx.ailang)))
    if a.record:
        cases = all_cases(ctx) if a.record == "all" else [case_of(ctx, a.record)]
        for c in cases:
            record(ctx, c)
        return
    if a.session:
        cases = [case_of(ctx, a.session)]
    elif a.case:
        cases = [case_of(ctx, n) for n in a.case]
    else:
        cases = all_cases(ctx)
    if a.compat:
        compat_main(ctx, cases)
    t = time.monotonic()
    # cases run concurrently (each runs its VM and interpreter concurrently too); output order is the case order
    with concurrent.futures.ThreadPoolExecutor(max(1, min(len(cases), (os.cpu_count() or 2) // 2))) as ex:
        futures = [ex.submit(lambda c: (c, _guard(verify, ctx, c)), c) for c in cases]
        results = [f.result() for f in futures]
    fails = 0
    for c, (text, f) in results:
        sys.stdout.write(text)
        fails += len(f)
    print("replay: %d cases, %s (%.1f s wall)" % (len(cases), "all identical" if fails == 0 else "%d failures" % fails, time.monotonic() - t))
    sys.exit(1 if fails else 0)


def _guard(f, ctx, case):
    try:
        return f(ctx, case)
    except RuntimeError as e:
        return "  FAIL  %s\n" % e, [str(e)]


if __name__ == "__main__":
    main()
