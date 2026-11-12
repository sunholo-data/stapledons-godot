#!/usr/bin/env python3
"""R3-UNIVERSE-LAB UL3c: an independent reference for sim/lab_stats.ail.

Role: oracle (tools/python-allowlist.txt). Standard library only; run with -I.
It shares no code and no method with the AILANG module:

  order-statistic ranks   exact integer arithmetic: the binomial tails are exact, so each
                          rank is decided with no rounding. The module sums a floating-point
                          log recurrence.
  Student t               the regularised incomplete beta function by its continued fraction
                          with math.lgamma, then bisection. The module uses the finite
                          trigonometric series for integer degrees of freedom (A&S 26.7.3-4).
  mean, spread, error     math.fsum and statistics.stdev / statistics.median.
  quantile estimate       Hyndman and Fan type 7, written from its definition.
  met, missed, unsettled  the rule as the module states it (a closed band), written again here.
  the stopping rule       the per-look level 0.05 / (cap / batch) recomputed here, and a seeded
                          SIMULATION of the whole rule (16 looks of 64 to 1,024 seeds) that
                          counts how often a target whose truth sits exactly on a band's edge
                          is called met or missed: with a 95 % interval at every look (what
                          the first version did) and with the split level (what the rule does).

  python3 -I tools/lab_stats_ref.py --write tests/fixtures/lab/stats_reference.json
  python3 -I tools/lab_stats_ref.py --check tests/fixtures/lab/stats_reference.json PROBE.json

--check fails if the committed reference is not what this file computes now (a stale
file), if the simulated false "met" or false "missed" rate under the rule is above 2.5 %,
or if the module's probe (sim/lab_stats_test.ail statsOracle) differs from the reference:
ranks and refusals exactly, floats to the tolerances below.
"""
import json
import math
import random
import statistics
import sys
from fractions import Fraction

ALPHA = Fraction(1, 20)
QUANTILES = {"0.1": Fraction(1, 10), "0.5": Fraction(1, 2), "0.9": Fraction(9, 10)}
MAX_N = 1024
BATCH, CAP = 64, 1024
T_DFS = list(range(1, 41)) + [64 * k - 1 for k in range(1, 17)] + [50, 100, 500, 1000]
REL_SUM, REL_T = 1e-12, 1e-9  # mean/spread/error; anything through the t quantile
SIM_SEED, SIM_REPS = 20261112, 10000


# ------------------------------------------------------------ exact order-statistic ranks
def ranks(n, q, alpha=ALPHA):
    """(l, u), 1-based: the largest l with P(B <= l-1) <= alpha/2 and the smallest u with
    P(B >= u) <= alpha/2, B ~ Binomial(n, q). None when either does not exist. Also the
    exact coverage P(l <= B <= u-1) and how close a tail comes to alpha/2 (the knife edge).
    Integers throughout: with q = a/b, P(B = k) = C(n, k) a^k (b-a)^(n-k) / b^n."""
    a, b = q.numerator, q.denominator
    c, total = b - a, b ** n
    half = alpha / 2
    num, den = half.numerator, half.denominator             # tail <= alpha/2  <=>  den * weight <= num * total
    edge = None                                            # least |den * weight - num * total|
    low, low_w, cum, w = None, 0, 0, c ** n                # w = weight of k = 0
    for k in range(0, n):                                  # cum = P(B <= k) * total; rank l = k + 1
        cum += w
        d = abs(den * cum - num * total)
        edge = d if edge is None or d < edge else edge
        if den * cum > num * total:
            break
        low, low_w = k + 1, cum
        w = w * (n - k) * a // ((k + 1) * c)
    up, up_w, cum, w = None, 0, 0, a ** n                  # w = weight of k = n
    for k in range(n, 0, -1):                              # cum = P(B >= k) * total; rank u = k
        cum += w
        d = abs(den * cum - num * total)
        edge = d if edge is None or d < edge else edge
        if den * cum > num * total:
            break
        up, up_w = k, cum
        w = w * k * c // ((n - k + 1) * a)
    gap = float(Fraction(edge, num * total))
    if low is None or up is None:
        return None, None, gap
    return (low, up), float(1 - Fraction(low_w + up_w, total)), gap


# ------------------------------------------------------------ Student t, two-sided
def betacf(a, b, x):
    tiny = 1e-300
    c, d = 1.0, 1.0 - (a + b) * x / (a + 1.0)
    d = 1.0 / (d if abs(d) > tiny else tiny)
    h = d
    for m in range(1, 5000):
        m2 = 2 * m
        aa = m * (b - m) * x / ((a + m2 - 1.0) * (a + m2))
        d = 1.0 + aa * d
        d = 1.0 / (d if abs(d) > tiny else tiny)
        c = 1.0 + aa / c
        c = c if abs(c) > tiny else tiny
        h *= d * c
        aa = -(a + m) * (a + b + m) * x / ((a + m2) * (a + m2 + 1.0))
        d = 1.0 + aa * d
        d = 1.0 / (d if abs(d) > tiny else tiny)
        c = 1.0 + aa / c
        c = c if abs(c) > tiny else tiny
        delta = d * c
        h *= delta
        if abs(delta - 1.0) < 1e-16:
            return h
    raise SystemExit("lab-stats-ref: betacf did not converge")


def betainc(a, b, x):
    if x <= 0.0:
        return 0.0
    if x >= 1.0:
        return 1.0
    front = math.exp(math.lgamma(a + b) - math.lgamma(a) - math.lgamma(b) + a * math.log(x) + b * math.log1p(-x))
    if x < (a + 1.0) / (a + b + 2.0):
        return front * betacf(a, b, x) / a
    return 1.0 - front * betacf(b, a, 1.0 - x) / b


def t_two_sided_tail(t, df):
    return betainc(df / 2.0, 0.5, df / (df + t * t))


def t_critical(df, alpha=0.05):
    lo, hi = 0.0, 1.0e6
    for _ in range(400):
        mid = (lo + hi) / 2.0
        if mid <= lo or mid >= hi:
            break
        if t_two_sided_tail(mid, df) > alpha:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2.0


# Printed values (any t table), a check on this oracle itself.
T_TEXTBOOK = {1: 12.7062047, 2: 4.3026527, 5: 2.5705818, 7: 2.3646243, 30: 2.0422725, 63: 1.9983405, 1000: 1.9623391}
# The same at another level: the two-sided 1 % points (the 0.995 column), three decimals.
T_TEXTBOOK_99 = {1: 63.657, 5: 4.032, 10: 3.169, 30: 2.750, 60: 2.660, 120: 2.617}


# ------------------------------------------------------------ the shared samples
def lcg(seed, n, f):
    x, out = seed, []
    for _ in range(n):
        x = (1103515245 * x + 12345) % 2147483648
        out.append(f(x // 65536))
    return out


def samples():
    return [
        ("n0", []), ("n1", [5.0]), ("n2", [3.0, 7.0]), ("n5", [2.0, 0.0, 5.0, 1.0, 1.0]),
        ("n8", [4.0, 4.0, 9.0, 0.0, 2.0, 7.0, 4.0, 1.0]), ("ties8", [1.0, 1.0, 1.0, 2.0, 2.0, 2.0, 2.0, 2.0]),
        ("equal6", [3.0] * 6), ("equal64", [2.0] * 64),
        ("lcg64", lcg(1, 64, lambda v: float(v % 12))),
        ("frac128", lcg(2, 128, lambda v: (v % 50) / 7.0)),
        ("lcg1024", lcg(3, 1024, lambda v: float(v % 40))),
    ]


BANDS = [("2..5", 2.0, 5.0), ("0..10", 0.0, 10.0), ("..3", None, 3.0), ("3..", 3.0, None), ("4.4..4.6", 4.4, 4.6), ("19..20", 19.0, 20.0),
         ("2..2", 2.0, 2.0), ("..2", None, 2.0)]


def verdict(low, high, lo, hi):
    """A closed band. Met: the whole interval within [lo, hi], ends included. Missed: wholly
    outside (strictly). Else unsettled."""
    inside = (lo is None or lo <= low) and (hi is None or high <= hi)
    outside = (lo is not None and high < lo) or (hi is not None and low > hi)
    return "met" if inside else "missed" if outside else "unsettled"


def quantile7(xs, q):
    s = sorted(xs)
    h = (len(s) - 1) * q
    i = math.floor(h)
    return s[i] if i + 1 >= len(s) else s[i] + (h - i) * (s[i + 1] - s[i])


def looks(batch=BATCH, cap=CAP):
    return cap // batch


def look_alpha(batch=BATCH, cap=CAP):
    return ALPHA / looks(batch, cap)


def describe(xs):
    n = len(xs)
    if n == 0:
        return {"refused": "empty_sample"}
    out = {"n": n, "mean": math.fsum(xs) / n}
    if n < 2:
        out["summary"] = {"refused": "too_few_values"}
    else:
        sd = statistics.stdev(xs)
        se = sd / math.sqrt(n)
        t = t_critical(n - 1)
        low, high = out["mean"] - t * se, out["mean"] + t * se
        out["summary"] = {"spread": sd, "standard_error": se, "low": low, "high": high,
                          "verdicts": {name: verdict(low, high, lo, hi) for name, lo, hi in BANDS}}
    s = sorted(xs)
    for name, q in QUANTILES.items():
        r, cover, _ = ranks(n, q)
        est = statistics.median(xs) if name == "0.5" else quantile7(xs, float(q))
        out["q" + name] = {"refused": "no_interval"} if r is None else {
            "estimate": est, "lower_rank": r[0], "upper_rank": r[1], "low": s[r[0] - 1], "high": s[r[1] - 1], "coverage": cover}
    # The stopping decision, where this sample is a look of the standard rule.
    if n % BATCH == 0 and BATCH <= n <= CAP:
        a = look_alpha()
        t = t_critical(n - 1, float(a))
        sd = statistics.stdev(xs)
        low, high = out["mean"] - t * sd / math.sqrt(n), out["mean"] + t * sd / math.sqrt(n)
        r, cover, _ = ranks(n, QUANTILES["0.5"], a)
        out["look"] = {"alpha": float(a), "t": t, "low": low, "high": high,
                       "verdicts": {name: verdict(low, high, lo, hi) for name, lo, hi in BANDS},
                       "median_lower_rank": r[0], "median_upper_rank": r[1], "median_low": s[r[0] - 1], "median_high": s[r[1] - 1],
                       "median_coverage": cover}
    else:
        out["look"] = {"refused": "not_a_batch"}
    return out


# ------------------------------------------------------------ the whole rule, simulated
def normal_pairs(rng):
    """Box-Muller on random.random() (the Mersenne Twister's documented 53-bit floats)."""
    while True:
        u1, u2 = rng.random(), rng.random()
        r = math.sqrt(-2.0 * math.log(1.0 - u1))
        yield r * math.cos(2.0 * math.pi * u2)
        yield r * math.sin(2.0 * math.pi * u2)


OLD_RULE, NEW_RULE = "a 95 % interval at every look (the first version)", "the level split across the looks (the rule)"
ON_EDGE, OUTSIDE, INSIDE = "truth exactly on the edge", "truth 0.05 spreads outside the band", "truth 0.5 spreads inside the band"


def simulate():
    """SIM_REPS runs of standard-normal results, 16 looks each. For a target band [0, 10] and
    a true mean placed relative to its lower edge, count what the rule concludes: met, missed
    or still unsettled at the cap. One set of draws serves every placement (a shift of the
    mean leaves the spread alone)."""
    k = looks()
    ns = [BATCH * (i + 1) for i in range(k)]
    crit = {OLD_RULE: [t_critical(n - 1, 0.05) for n in ns], NEW_RULE: [t_critical(n - 1, float(look_alpha())) for n in ns]}
    places = {ON_EDGE: 0.0, OUTSIDE: -0.05, INSIDE: 0.5}
    counts = {rule: {place: {"met": 0, "missed": 0, "unsettled_at_cap": 0, "seeds_total": 0} for place in places} for rule in crit}
    gen = normal_pairs(random.Random(SIM_SEED))
    for _ in range(SIM_REPS):
        s = ss = 0.0
        stats = []
        for n in ns:
            for _ in range(BATCH):
                x = next(gen)
                s += x
                ss += x * x
            m = s / n
            stats.append((m, math.sqrt(max(ss - n * m * m, 0.0) / (n - 1)) / math.sqrt(n)))
        for rule, ts in crit.items():
            for place, mu in places.items():
                c = counts[rule][place]
                out, used = "unsettled_at_cap", ns[-1]
                for n, (m, se), t in zip(ns, stats, ts):
                    v = verdict(m + mu - t * se, m + mu + t * se, 0.0, 10.0)
                    if v != "unsettled":
                        out, used = v, n
                        break
                c[out] += 1
                c["seeds_total"] += used
    for rule in counts:
        for place in counts[rule]:
            c = counts[rule][place]
            c["met_rate"], c["missed_rate"] = c["met"] / SIM_REPS, c["missed"] / SIM_REPS
            c["mean_seeds"] = c.pop("seeds_total") / SIM_REPS
    return {"seed": SIM_SEED, "runs": SIM_REPS, "looks": k, "batch": BATCH, "cap": CAP, "band": [0.0, 10.0], "spread": 1.0, "results": counts}


def reference():
    for df, want in T_TEXTBOOK.items():
        if abs(t_critical(df) - want) > 5e-7:
            raise SystemExit("lab-stats-ref: the oracle's own t(%d) = %r is not the printed %r" % (df, t_critical(df), want))
    for df, want in T_TEXTBOOK_99.items():
        if abs(t_critical(df, 0.01) - want) > 6e-4:
            raise SystemExit("lab-stats-ref: the oracle's own t(%d, 0.01) = %r is not the printed %r" % (df, t_critical(df, 0.01), want))
    table, least, gap = {}, {}, None
    for name, q in QUANTILES.items():
        rows = []
        for n in range(1, MAX_N + 1):
            r, _, g = ranks(n, q)
            rows.append(list(r) if r else None)
            gap = g if gap is None or g < gap else gap
            if r and name not in least:
                least[name] = n
        table[name] = rows
    # The stopping level: ranks at every look of the standard rule, and t for two rules, so a
    # number of looks that does not come from the rule cannot pass.
    ns = [BATCH * (i + 1) for i in range(looks())]
    a16, a8 = look_alpha(), look_alpha(64, 512)
    look_ranks = {}
    for name, q in QUANTILES.items():
        rows = []
        for n in ns:
            r, _, g = ranks(n, q, a16)
            rows.append(list(r) if r else None)
            gap = g if g < gap else gap
        look_ranks[name] = rows
    a, b = dict(samples())["lcg64"], lcg(4, 64, lambda v: float(v % 12))
    return {"schema": "lab-stats-reference-2", "confidence": 0.95, "max_n": MAX_N, "ranks": table, "least_n_with_an_interval": least,
            "closest_tail_to_alpha_over_2_relative": gap, "t_dfs": T_DFS, "t": [t_critical(df) for df in T_DFS],
            "look": {"family_alpha": float(ALPHA),
                     "standard_rule": {"looks": looks(), "alpha": float(a16), "seeds": ns, "t": [t_critical(n - 1, float(a16)) for n in ns], "ranks": look_ranks},
                     "rule_64_512": {"looks": looks(64, 512), "alpha": float(a8), "t": [t_critical(n - 1, float(a8)) for n in ns[:8]]}},
            "cases": {name: describe(xs) for name, xs in samples()},
            "paired": describe([x - y for x, y in zip(a, b)]),
            "sequential": simulate()}


# ------------------------------------------------------------ comparison
def differ(path, want, got, tol, out):
    if isinstance(want, dict) and isinstance(got, dict):
        for k in sorted(set(want) | set(got)):
            if k not in want or k not in got:
                out.append("%s.%s: only in %s" % (path, k, "the reference" if k in want else "the module"))
            else:
                differ("%s.%s" % (path, k), want[k], got[k], REL_SUM if k in ("mean", "spread", "standard_error", "estimate") else tol, out)
    elif isinstance(want, list) and isinstance(got, list):
        if len(want) != len(got):
            out.append("%s: %d entries against %d" % (path, len(want), len(got)))
        else:
            for i, (w, g) in enumerate(zip(want, got)):
                differ("%s[%d]" % (path, i), w, g, tol, out)
    elif isinstance(want, float) and isinstance(got, (int, float)) and not isinstance(got, bool):
        if not math.isclose(want, got, rel_tol=tol, abs_tol=tol):
            out.append("%s: reference %r, module %r" % (path, want, got))
    elif want != got or isinstance(want, bool) != isinstance(got, bool):
        out.append("%s: reference %r, module %r" % (path, want, got))


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "--write":
        with open(sys.argv[2], "w") as f:
            json.dump(reference(), f, indent=None, separators=(",", ":"), sort_keys=True)
            f.write("\n")
        return
    if len(sys.argv) == 4 and sys.argv[1] == "--check":
        ref, committed, probe = reference(), json.load(open(sys.argv[2])), json.load(open(sys.argv[3]))
        stale = []
        differ("reference", ref, committed, 0.0, stale)
        if stale:
            sys.exit("lab-stats-oracle: FAIL the committed reference is not what the oracle computes: %s" % "; ".join(stale[:5]))
        if ref["closest_tail_to_alpha_over_2_relative"] < 1e-6:
            sys.exit("lab-stats-oracle: FAIL a binomial tail is within 1e-6 of alpha/2: a float sum cannot be trusted to decide that rank")
        seq = ref["sequential"]["results"]
        old, new = seq[OLD_RULE], seq[NEW_RULE]
        limit = float(ALPHA) / 2
        if new[ON_EDGE]["met_rate"] > limit or new[ON_EDGE]["missed_rate"] > limit:
            sys.exit("lab-stats-oracle: FAIL under the rule a truth on the band's edge is called met in %.2f %% and missed in %.2f %% of runs; the limit is %.1f %% each" % (
                100 * new[ON_EDGE]["met_rate"], 100 * new[ON_EDGE]["missed_rate"], 100 * limit))
        if old[ON_EDGE]["met_rate"] <= limit:
            sys.exit("lab-stats-oracle: FAIL the simulation does not show the fault it is there to show (95 %% at every look: met in %.2f %%)" % (100 * old[ON_EDGE]["met_rate"]))
        want = {k: ref[k] for k in ("ranks", "t", "t_dfs", "cases", "paired", "look")}
        bad = []
        differ("module", want, probe, REL_T, bad)
        if bad:
            sys.exit("lab-stats-oracle: FAIL %d differences: %s" % (len(bad), "; ".join(bad[:8])))
        n_ranks = sum(1 for rows in ref["ranks"].values() for r in rows if r)
        std = ref["look"]["standard_rule"]
        print("lab-stats-oracle: %d rank pairs exact (n = 1..%d, q = 0.1, 0.5, 0.9; %d refusals), %d t values within %.0e, %d samples and the paired "
              "differences agree (mean, spread, error within %.0e); closest tail to alpha/2: %.1e relative" % (
                  n_ranks, MAX_N, 3 * MAX_N - n_ranks, len(T_DFS), REL_T, len(ref["cases"]), REL_SUM, ref["closest_tail_to_alpha_over_2_relative"]))
        print("lab-stats-oracle: the stopping level 0.05 / %d looks = %g: %d t values and %d rank pairs at the looks of the standard rule, and %d t values for an %d-look rule, agree" % (
            std["looks"], std["alpha"], len(std["t"]), sum(len(v) for v in std["ranks"].values()), len(ref["look"]["rule_64_512"]["t"]), ref["look"]["rule_64_512"]["looks"]))
        print("lab-stats-oracle: the whole rule simulated, %d runs of %d looks, truth exactly on the band's edge: with a 95 %% interval at every look it is called met in %.2f %% "
              "and missed in %.2f %% of runs; with the rule's split level, met in %.2f %% and missed in %.2f %% (limit %.1f %% each). Truth 0.05 spreads outside: met %.2f %% before, %.2f %% now. "
              "Truth 0.5 spreads inside: met in %.1f %% of runs after %.0f seeds on average (before: %.0f)" % (
                  ref["sequential"]["runs"], ref["sequential"]["looks"], 100 * old[ON_EDGE]["met_rate"], 100 * old[ON_EDGE]["missed_rate"],
                  100 * new[ON_EDGE]["met_rate"], 100 * new[ON_EDGE]["missed_rate"], 100 * limit,
                  100 * old[OUTSIDE]["met_rate"], 100 * new[OUTSIDE]["met_rate"],
                  100 * new[INSIDE]["met_rate"], new[INSIDE]["mean_seeds"], old[INSIDE]["mean_seeds"]))
        return
    sys.exit(__doc__)


if __name__ == "__main__":
    main()
