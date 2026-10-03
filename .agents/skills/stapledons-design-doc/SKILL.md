---
name: stapledons-design-doc
description: Write an implementation design document for Stapledon's Voyage (the Godot 4 + AILANG rebuild) in the shape design_docs/README.md defines, measured against the design canon in sunholo-data/stapledons-design (core pillars, design-decision log, the normative relativity and Higgs-bubble specs, the R1 roadmap, ADR 0001, rejected directions). Use when a design request arrives on the stapledons-design inbox (from Daneel's +design-stapledons@ or the plane), when a task says "Design doc:", or when checking whether an existing doc under design_docs/ followed the discipline.
---

# A Stapledon's Voyage design document

**Written 3 October 2026**, when Mark made this repo the target for Stapledon's Voyage design
requests. Requests reach a designer agent on the plane (`design-doc-creator-stapledons`) through
Daneel. Mark decided that designs land **here** (`design_docs/` sits next to the code) and that the
agent runs **this repo's own skill**. The generic ailang `design-doc-creator` scores designs against
the AILANG language's axioms, which are the wrong yardstick for a game.

The canonical texts outrank this file if they disagree:
- `CLAUDE.md`: the rules, the definition of done, and the design → sprint → execute → evaluate cycle.
- `design_docs/README.md`: the doc format and the index.
- The canon repo: **what** the game is.

**This repo says how the game is built; `stapledons-design` says what the game is.** Link to the
canon; never copy it into a design doc, and never change it silently.

## Read before you write

You are in a checkout of `sunholo-data/stapledons-godot` (default branch `main`).

1. `CLAUDE.md` in full: commands, the definition-of-done gates in order, the Python policy, the
   filesystem search rule.
2. `design_docs/README.md`: the format and the index of every design doc and its status.
3. The two most recent docs under `design_docs/planned/r1/` and `design_docs/implemented/r1/`. Copy
   their actual header and section shape. `m3-black-holes.md` and `m5-planets.md` are good models.
4. **The canon.** Clone it outside this checkout:
   `git clone --depth 1 https://github.com/sunholo-data/stapledons-design /tmp/ctx/stapledons-design`.
   Never clone into this repo, because anything left here lands in the PR. Then read:
   - `vision/core-pillars.md`: the non-negotiable pillars every feature must serve.
   - `vision/design-decisions.md` and `vision/open-questions.md`: what is settled, and what is not.
   - `physics/relativity-spec.md`: **normative**. Check values RS-n, the §5 audit of the old Go build.
   - `physics/higgs-bubble.md`: **normative**. The bubble is the one admitted hand-wave. Check values HB-n.
   - `roadmap/r1-foundations.md`: the milestones and the bar clauses.
   - `decisions/0001-engine-and-architecture.md`: Godot renders; the AILANG sim is a child process
     speaking NDJSON.
   - `features/…`: the feature doc(s) the request touches.
   - `rejected/`: a direction already rejected is not re-proposed without saying why it is different now.
   - `lore/archive/`: the player-facing physics entries. Their numbers must agree with HB/RS values.
5. **The decision ledger.** Read the `## Decision ledger` section of `design_docs/stapledon-mission.md`
   (rows D-n). An attended ruling there is settled. Cite it as **D-n** and don't reopen it.
6. **Open pull requests.** `gh pr list --repo sunholo-data/stapledons-godot` and the same for
   `stapledons-design`. A design or a sprint may be on a branch, not on `main`. If one covers the
   request, say so first and design the difference, or recommend closing one of the two.

**Searching.** Never walk home or root (CLAUDE.md, "Searching the filesystem"). On 2 Oct an
unbounded find hung the rig. Search with `git ls-files | grep …` or a bounded `find` inside a repo.
AILANG packages are under `runtime/cache/registry/OWNER/PKG/VER/` or `~/.ailang/cache/registry/…`.
`sunholo/relativity` is the single source of physics maths.

## Before writing: is it designed already, and is it this repo's?

1. **Search** `design_docs/` (planned and implemented, by release) and the README index. If a doc
   covers the request, reply with its path and what it covers; don't write a second one. If it
   covers it partly, say exactly how yours differs.
2. **Is it "how" or "what"?** A change to the game itself (a new pillar, a canon rule, a story or
   lore fact, a physics model) is a **canon change**. This repo cannot decide it. Write the
   implementation design. Put the canon change in a **"Design-repo changes this needs"** section and
   in the open questions, as `m5-planets.md` does. If the request contradicts a pillar, a normative
   spec, a D-n ruling or a rejected direction, **do not resolve it silently**. State the conflict,
   cite both sides, and make it a numbered open question for Mark with a recommendation.
3. **Physics first.** New maths goes into `sunholo/relativity` (or another `sunholo/*` package) first
   (CLAUDE.md gate 3). GDScript and shaders mirror the package. A design that puts a formula only in
   a shader is wrong.

## The document

**Path:** `design_docs/planned/<release>/<id>.md`, for example `design_docs/planned/r1/m6-<slug>.md`.
Use the roadmap's release and the milestone id if it has one. Otherwise use a short kebab id, and
say in the header that the roadmap has no row for it yet.

The format is `design_docs/README.md`'s. Keep the prose tight and let the tables carry the weight.

```
# <Milestone id>: <Title>

**Status:** Planned (design, awaiting Mark's answers / sprint plan). Created <date> from <the request: who, how, its words>.
**Release:** r1 · **Milestone:** <id> of [R1 foundations](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md) (or "new; the roadmap has no row yet")
**Priority:** P<n>. <one line: what it unblocks, what it does not block>
**Implements:**
- [<canon doc>](https://github.com/sunholo-data/stapledons-design/blob/main/<path>) §<section>: <what exactly, and what of it is replaced or out of scope>
**Depends on:** <packages at versions, milestones, art stops; each one measured>
**Estimated:** ~<n> LOC (code + tests), <k> sub-milestones
**Evidence:** every codebase claim has a row in the [Verification log](#verification-log), pinned to `<commit>`.

## Game vision alignment
## Problem
## Goals and non-goals
## Design
## Acceptance criteria
## Sub-milestones and estimates
## Risks and mitigations
## Open questions for Mark
## Design-repo changes this needs        (only if the request touches canon)
## Deliverables
## Verification log
```

**Game vision alignment.** Score the design with the `game-vision-designer` skill
(`.claude/skills/game-vision-designer/SKILL.md`; read it, and its `resources/`) against
`vision/core-pillars.md`. Use one row per pillar, plus **Hard sci-fi authenticity (spec)**:
Relevance (0 / + / ++), Score, and Notes that say concretely how the design serves the pillar or
strains it. Close with **Net** and a **Go / No-go**. A negative score on a pillar is not hidden; it
becomes an open question. No vibes: every note names a mechanism, a number or a scene.

**Problem.** What is wrong or missing today, with evidence: the file and line read, the command
run, the render looked at. **Every premise is measured before the design is written** and gets a
row in the Verification log. Premises come back false more often than not.

**Design.** One sentence first, then the components, in the order CLAUDE.md's gates impose:
1. package maths (`sunholo/*`, with tests and check values);
2. the pure sim (`sim/core.ail` stays `--strict-bytecode` clean, I/O only in `sim/ship.ail`, VM ==
   interpreter);
3. the NDJSON protocol change (additive, and say so);
4. Godot rendering, which mirrors the package and never holds the only copy of a formula;
5. UI and scenes.

Precision and determinism are design decisions here, not afterthoughts:
- float64 scalars where `Vector3`'s float32 cannot hold the value;
- γ and 1−β taken from the sim or the package, never `1.0 - beta` near c;
- every lookup table finite over its range;
- no hidden state, and every AI output recorded as a sim input (D-7).

**Acceptance criteria.** A table. **Every row names the command that checks it**: `make test`,
`make golden`, `make capture`, a named test, or a check value RS-n or HB-n asserted in
`tests/test_physics.gd`. The sprint evaluator scores these rows, so a criterion no command can
check does not belong here. Any visual that shows SR or GR needs check values, a GPU-vs-CPU golden
case and reference renders before merge (gate 2).

**Open questions for Mark.** Number them. Each has a **recommendation**, **what choosing otherwise
costs**, and a **default if unanswered**, which is the ledger's own row shape. Every canon conflict
from above is one of these. **Do not write them into the ledger in `stapledon-mission.md`:** only
an attended session edits the ledger (CLAUDE.md, "Recording Mark's decisions"). They live in the
doc until Mark answers.

**Verification log.** Columns: `| # | Claim | Command | Result |`, rows V1… as in `m5-planets.md`.
Pin it to the commit you read (`git rev-parse --short HEAD`). Every claim in the document is either
a row here or a question above. Python is allowed only as an **oracle** in a scratch directory,
never committed (CLAUDE.md, "Python"). Say so in the row.

**The retired Go build** (`sunholo-data/stapledons_voyage`) is reference only. If you consult it,
say what is kept and what was wrong, against the relativity spec's §5 audit. Never port its code.

## The contract the wrapper and CI enforce

- **Write exactly one file**: `design_docs/planned/<release>/<id>.md`. Nothing else under
  `design_docs/`, and nothing anywhere else in this checkout. The wrapper commits every non-scratch
  change, pushes the task branch and opens the PR. Docs-only PRs auto-merge once checks pass, and
  `artifact_patterns` is `design_docs/**/*.md`. That pattern is the whole safety scope, so a stray
  file there would merge unreviewed.
- **Don't** add the doc's row to the index in `design_docs/README.md`, write a sprint plan
  (`-sprint.md`, which is the separate sprint-planner step after Mark approves), touch
  `stapledon-mission.md` or its ledger, or edit the canon repo.
- **Nothing shaped like a credential** (API keys, tokens, `-----BEGIN`), and no client material.
- **CI** (`.github/workflows/ci.yml`) runs `make test` on every PR. A docs-only PR cannot break it,
  so if CI is red on your PR, something other than your one file changed.
- **AILANG problems found while designing** (a missing package function, a VM/interpreter
  disagreement) are reported upstream as CLAUDE.md says (`ailang messages` to `user`,
  `--from stapledons_godot`), and noted in the doc's Risks section.

## Finishing

1. The only file you have written is `design_docs/planned/<release>/<id>.md`.
2. End your final message with the marker the coordinator reads:
   ```
   DESIGN_DOC_PATH: design_docs/planned/<release>/<id>.md
   ```
3. Then list the numbered open questions, one line each with its recommendation, so the requester
   can answer on the thread without opening the document. Last, add one line naming the index row
   an attended session should add to `design_docs/README.md` once the doc merges.

## What not to do

- Don't score against AILANG's axioms or anyone else's. The yardstick is the pillars, the normative
  specs and the D-n ledger.
- Don't decide canon. A conflict with a pillar, a spec or a ruling is Mark's decision, stated as one.
- Don't paste canon text in; link to it with a section reference.
- Don't put physics maths only in GDScript or a shader, or design around float32 near c.
- Don't propose a save, reload or undo mechanic without naming its conflict with *Choices Are Final*.
- Don't hand off to the sprint planner. A design ends at the PR and Mark's answers.
