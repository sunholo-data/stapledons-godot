#!/usr/bin/env python3
"""Reference for the sim's PRNG (sim/rng.ail, design m2-journey-core §M2.4).

Algorithm id "splitmix64-1". Everything is integer arithmetic mod 2^64; no
floats enter any value, vector or digest, so the output is the same on every
architecture.

    mix64(z)              SplitMix64 finaliser (Vigna, splitmix64.c)
    splitmix64(state, n)  n-th output (0-based) of SplitMix64 seeded with state
                          = mix64(state + (n + 1) * 0x9e3779b97f4a7c15)
    key(seed, stream)     mix64(mix64(seed) ^ stream_id)
    value(seed, s, n)     splitmix64(key(seed, s), n)
    top53(v)              v >>> 11, the integer the `draw` event reports

Stream ids are fixed constants (journey 1 ... news 6), not positions, so
adding a stream never shifts another's values.

Usage:
    rng_ref.py --check            self-test vectors, chi-square on 1e5 draws per
                                  stream, and the first 1,000 values of each
                                  stream from the AILANG sim (strict VM and
                                  interpreter; $AILANG, default `ailang`)
                                  compared bit for bit
    rng_ref.py --digest SEED N    digest over N draws of every stream (rngVm)
    rng_ref.py --dump SEED N      first N values of each stream, signed decimal
"""
import math
import os
import subprocess
import sys

MASK = (1 << 64) - 1
GAMMA = 0x9E3779B97F4A7C15
MUL_A = 0xBF58476D1CE4E5B9
MUL_B = 0x94D049BB133111EB
STREAMS = [("journey", 1), ("crew", 2), ("events", 3), ("galaxy", 4), ("ai", 5), ("news", 6)]
ALGORITHM = "splitmix64-1"
SIM = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sim")


def mix64(z):
    z &= MASK
    z = ((z ^ (z >> 30)) * MUL_A) & MASK
    z = ((z ^ (z >> 27)) * MUL_B) & MASK
    return z ^ (z >> 31)


def splitmix64(state, n):
    return mix64(state + (n + 1) * GAMMA)


def key(seed, sid):
    return mix64(mix64(seed) ^ sid)


def value(seed, sid, n):
    return splitmix64(key(seed, sid), n)


def top53(v):
    return v >> 11


def signed(v):
    return v - (1 << 64) if v >= 1 << 63 else v


def digest(seed, count):
    """Fold every stream's first `count` values, streams in id order: h = mix64(h ^ v)."""
    h = 0
    for _, sid in STREAMS:
        k = key(seed, sid)
        for n in range(count):
            h = mix64(h ^ splitmix64(k, n))
    return h


def dump(seed, count):
    return [str(signed(value(seed, sid, n))) for _, sid in STREAMS for n in range(count)]


# Published SplitMix64 outputs: seed 0 (design V4) and seed 1234567 (the
# sequence in Vigna's splitmix64.c test harnesses and Java SplittableRandom).
KNOWN = {
    0: [0xE220A8397B1DCDAF, 0x6E789E6AA1B965F4, 0x06C45D188009454F],
    1234567: [6457827717110365317, 3203168211198807973, 9817491932198370423, 4593380528125082431, 16408922859458223821],
}


def chi_square_p(chi2, dof):
    """Upper-tail p of chi-square via Wilson-Hilferty (stdlib only)."""
    z = ((chi2 / dof) ** (1.0 / 3.0) - (1.0 - 2.0 / (9.0 * dof))) / math.sqrt(2.0 / (9.0 * dof))
    return 0.5 * math.erfc(z / math.sqrt(2.0))


def chi_square(seed, sid, draws, bins, shift):
    counts = [0] * bins
    k = key(seed, sid)
    for n in range(draws):
        counts[(splitmix64(k, n) >> shift) % bins] += 1
    e = draws / bins
    return sum((c - e) ** 2 / e for c in counts)


def run_sim(entry, arg, strict):
    ail = os.environ.get("AILANG", "ailang")
    cmd = [ail, "run", "--quiet"] + (["--bytecode", "--strict-bytecode"] if strict else []) + [
        "--package-dir", SIM, "--entry", entry, "--args-json", str(arg), os.path.join(SIM, "rng_test.ail")]
    return subprocess.run(cmd, check=True, capture_output=True, text=True).stdout.strip().split("\n")


def check():
    ok = True
    for seed, want in KNOWN.items():
        got = [splitmix64(seed, n) for n in range(len(want))]
        good = got == want
        ok &= good
        print(f"splitmix64 seed {seed}: {'ok' if good else 'MISMATCH ' + str(got)}")
    for name, sid in STREAMS:
        hi = chi_square(7, sid, 100000, 256, 56)
        lo = chi_square(7, sid, 100000, 256, 0)
        p_hi, p_lo = chi_square_p(hi, 255), chi_square_p(lo, 255)
        good = p_hi > 0.001 and p_lo > 0.001
        ok &= good
        print(f"chi-square {name}: top byte {hi:.1f} (p={p_hi:.3f}), low byte {lo:.1f} (p={p_lo:.3f}) {'ok' if good else 'FAIL'}")
    keys = {key(s, sid) for s in (0, 7, (1 << 53) - 1) for _, sid in STREAMS}
    ok &= len(keys) == 18
    for seed in (0, 7, (1 << 53) - 1):
        want = dump(seed, 1000)
        for strict in (True, False):
            got = run_sim("rngDump", seed, strict)
            good = got == want
            ok &= good
            where = "strict VM" if strict else "interpreter"
            if good:
                print(f"sim {where} seed {seed}: {len(got)} values (6 streams x 1000) identical to the reference")
            else:
                bad = next((i for i, (a, b) in enumerate(zip(got, want)) if a != b), min(len(got), len(want)))
                print(f"sim {where} seed {seed}: MISMATCH at line {bad} ({len(got)} vs {len(want)} lines)")
    print("rng_ref: ok" if ok else "rng_ref: FAIL")
    return 0 if ok else 1


def main(argv):
    if argv[:1] == ["--check"]:
        return check()
    if argv[:1] == ["--digest"] and len(argv) == 3:
        print(signed(digest(int(argv[1]), int(argv[2]))))
        return 0
    if argv[:1] == ["--dump"] and len(argv) == 3:
        print("\n".join(dump(int(argv[1]), int(argv[2]))))
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
