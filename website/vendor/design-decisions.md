# Design Decisions

Log of design decisions with context and rationale.

---

<!-- Template for new decisions:

## [YYYY-MM-DD] [Decision Title]

**Context:** [Why this came up]

**Decision:** [What was decided]

**Rationale:** [How this serves the pillars]

**Alternatives rejected:** [What else was considered]

**Implications:** [What this means for other features]

-->

## [2025-11-29] Core Pillars Established

**Decision:** 5 core pillars define design constraints: Choices Are Final, The Game Doesn't Judge, Time Has Emotional Weight, The Ship Is Home, Grounded Strangeness

**Rationale:** These pillars emerged from vision interview exploring emotional goals, player agency, and game identity. Every future feature must serve at least one pillar.

---

## [2025-11-30] OCEAN Personality System for Crew

**Context:** Designing crew archetypes (Engineer, Scientist, Medic, Diplomat, Pilot, Quartermaster, Zealot, Dreamer, Skeptic, Fantasist, Analyst) needed a grounded psychological framework to drive emergent behavior.

**Decision:** Use OCEAN (Big Five) personality model with the following parameters:
- **O** (Openness): 0.0-1.0
- **C** (Conscientiousness): 0.0-1.0
- **E** (Extraversion): 0.0-1.0
- **A** (Agreeableness): 0.0-1.0
- **N** (Neuroticism): 0.0-1.0

Each archetype has baseline OCEAN values that inform dialogue tone, event reactions, relationship chemistry, crew votes, and civilization preferences.

**Rationale:** OCEAN is real psychology (Pillar 5: Grounded Strangeness), creates emergent rather than scripted behavior (Pillar 2: Game Doesn't Judge), and makes crew feel like real people (Pillar 4: Ship Is Home).

**Alternatives rejected:**
- MBTI alone (too prescriptive, pop-psychology feel)
- Custom trait system (less grounded, reinventing the wheel)
- No personality system (crew would feel generic)

---

## [2025-11-30] Player OCEAN Is Emergent

**Context:** Should player's personality profile be declared upfront or inferred from gameplay?

**Decision:** Player OCEAN is emergent from choices, not declared. The game tracks decisions and infers player's psychological profile over time.

**Rationale:** Serves "The Game Doesn't Judge" - player discovers who they are through play rather than selecting a label. Creates self-discovery moment in legacy report. Avoids players gaming their profile for optimal crew chemistry.

**Alternatives rejected:**
- Quiz at start (feels like a personality test, not a game)
- Direct selection (too on-the-nose, breaks immersion)

**Implications:** Need to define which decisions map to which OCEAN dimensions. Legacy report can reveal "who you became."

---

## [2025-11-30] OCEAN Values Drift Over Time

**Context:** Crew spend 100 subjective years together through traumatic experiences. Should personality be fixed?

**Decision:** OCEAN values drift based on experiences. Core archetype provides baseline, but trauma, relationships, time dilation exposure, and witnessed events shift values within bounds.

**Rationale:** Serves "Time Has Emotional Weight" - the cosmos changes you. Creates character arcs without scripting them. The Engineer who watched 10,000 years of civilizations die might have their Openness cracked open.

**Alternatives rejected:**
- Fixed values (feels static over 100-year journey)
- Unbounded drift (would lose archetype identity)

**Implications:** Need drift triggers (events that shift values), drift bounds (how far from baseline), and visual/dialogue indicators of change.

---

## [2025-11-30] Directional Relationship Chemistry

**Context:** Should relationship chemistry be symmetric (A↔B same) or directional (A→B ≠ B→A)?

**Decision:** Chemistry is directional. Each crew member's feelings toward another are calculated separately based on what they need vs. what the other offers.

**Rationale:** Real relationships are asymmetric. Dreamer might adore Medic while Medic finds Dreamer exhausting. Creates richer dynamics: unrequited bonds, one-sided tensions, mentor/protégé asymmetries.

**Implications:**
- Need "needs" and "offers" profiles per archetype
- Relationship UI might show both directions
- Crew conflicts can arise from asymmetric investment

---

## [2025-11-30] Needs/Offers Derived from OCEAN

**Context:** Should psychological needs/offers be manually defined per archetype, or derived algorithmically from OCEAN values?

**Decision:** Derive needs and offers from OCEAN values using formulas. Simpler to maintain and ensures consistency.

**Derivation rules:**
- `needs.validation` = N × (1 - C) — anxious + impulsive people seek reassurance
- `needs.stability` = N × C — anxious + conscientious people want predictability
- `needs.stimulation` = O × E — open + extraverted people crave novelty
- `needs.autonomy` = (1 - A) × (1 - E) — disagreeable introverts want space
- `needs.connection` = E × A — extraverted + agreeable people seek bonds

- `offers.validation` = A × E — agreeable extraverts give reassurance
- `offers.stability` = C × (1 - N) — conscientious + calm people provide stability
- `offers.stimulation` = O × E — open extraverts bring energy
- `offers.autonomy` = (1 - C) × (1 - A) — low C + low A leave others alone
- `offers.connection` = E × A — same as needs (they give what they seek)

**Rationale:** Single source of truth (OCEAN), no manual sync needed, mathematically grounded.

---

## [2025-11-30] OCEAN Drift Hidden Until End Screen

**Context:** How should players perceive crew personality changes over time?

**Decision:** Drift is invisible during gameplay. Players experience it through subtle dialogue shifts and behavior changes, but never see numbers. The end screen reveals "who your crew became" — showing before/after OCEAN profiles and key drift events.

**Rationale:**
- Serves "The Game Doesn't Judge" — no mid-game optimization of crew psychology
- Creates discovery moment at end — "I didn't realize the Engineer had changed so much"
- Dialogue shifts feel organic, not mechanical
- Avoids UI clutter during play

**Implications:**
- Dialogue generation must reflect current (not baseline) OCEAN
- End screen needs "crew evolution" section
- May want to show key moments that caused drift ("After witnessing the Helix extinction...")


## [2025-12-02] Trace Metal Scarcity Model

**Decision:** Trace metals available in every solar system. Only becomes a threat after extended periods without visiting any system.

**Rationale:** Avoids constant micromanagement pressure. Creates consequence for isolation/long journeys rather than routine busywork.


## [2025-12-02] Earth Return: Optional but Compelling

**Decision:** Return to Earth is never mechanically required, but should be narratively very interesting.

**Rationale:** Serves Pillar 2 (no judgment) - game doesn't force you. Serves Pillar 3 (time weight) - what has Earth become after millennia?


## [2025-12-02] Crew Opinions: Universal System

**Decision:** Crew opinions apply to all major decisions, not just resource harvesting. This is a general system.

**Rationale:** Serves Pillar 4 (Ship Is Home) - crew are opinionated people, not silent resources. Consistency across all decision types.


## [2025-12-02] Alien Biosphere: Science Not Tropes

**Decision:** Alien biosphere risks follow real science (biochemical incompatibility, chirality, contamination ethics) rather than sci-fi tropes (instant plagues, adapting viruses). The tension is 'can we use it at all' and 'should we risk contaminating them', not 'will it kill us'.

**Rationale:** Serves Pillar 5 (Grounded Strangeness). Real biology is more interesting than Hollywood scenarios.


## [2025-12-02] Anthropic Luck Factor

**Decision:** Galaxy has tunable 'Anthropic Luck' (L) parameter. Higher L = denser civs in player's region. Justified as observer-selection bias: conditional on being a player who CAN meet civs, you're in the rare branch where they exist nearby. Default: L high enough for 5-15 civs within 500-1000 ly.

**Rationale:** Pillar 5 (Grounded Strangeness): Real physics with philosophical justification. Avoids both 'magic dense universe' and 'boring empty universe'. Player can adjust for hardcore vs narrative experience.


## [2025-12-02] Detection Model: Epistemic Gap

**Decision:** Players only see old light. Three detection tiers: (1) Astrometric survey - star type, planets, orbits; (2) Spectroscopic - biosignatures, atmosphere; (3) Technosignature search - radio/waste heat. All data labeled with 'last_light_year' showing how stale it is. Arrival reveals how wrong predictions were.

**Rationale:** Pillar 1 (Choices Final): Commit based on uncertain data. Pillar 3 (Time Weight): The gap between 'what you saw' and 'what you find' IS the time dilation made tangible.


## [2025-12-02] Gamma Cap: 10-20 Default

> **SUPERSEDED by ledger D-15 (2026-10-01):** the cruise slider reaches
> 0.999999c (γ ≈ 707); the ISM drag energy (∝ γ·d) is the natural brake. A cap
> remains a scenario parameter, with no 10–20 default.

**Decision:** Player ship γ (Lorentz factor) capped around 10-20. At γ=20: 300 ly = 15 years subjective / 300 years external. This allows 4-6 major legs in 100 years, with 2-3 revisits to nearby civs. Sweet spot for meaningful sacrifice without making civs unreachable.

**Rationale:** Pillar 3 (Time Weight): Each journey costs centuries external. Not so high that everything is one-way, not so low that time feels cheap.


## [2025-12-02] Launch Order = Arrival Order

**Decision:** With Higgs bubble, any ship can achieve arbitrary γ instantly. Therefore arrival order depends ONLY on launch time in galaxy frame, not on technology level. Uplifted civs can reach destinations before you IF they launch earlier (while you detour or delay). They cannot overtake you mid-flight.

**Rationale:** Pillar 5 (Grounded): Clean physics rule with no paradoxes. Creates strategic tension: share tech and they might beat you to Earth.


## [2025-12-02] Player Role: Relativistic Perturbation Operator

**Decision:** Player is not an explorer or diplomat - they are a network perturbation operator. Actions: (1) Give civ technology (Higgs, fusion, etc); (2) Give civ maps of others; (3) Share philosophies between civs. Everything else is fallout. The sim is 'how does the contact graph evolve when I poke it?'

**Rationale:** Pillar 2 (No Judgment): You perturb, consequences cascade, game shows results without moral labels. Pillar 1 (Choices Final): Each poke is irreversible and propagates.


## [2025-12-02] Three Distance Regimes

**Decision:** Local bubble (≤500 ly): Many biospheres, maybe 1 civ, centuries pass per trip - 'serial saga' territory. Mid-range (1000-3000 ly): Good civ probability, millennia pass, 1-2 visits max - 'two bookends' territory. Deep-galaxy (≥5000 ly): Almost certainly find civs, but tens of thousands of years pass - 'one-shot mythic meeting' territory.

**Rationale:** Pillar 3 (Time Weight): Distance correlates with sacrifice. Pillar 1 (Choices Final): Deeper journeys are more irreversible.


## [2025-12-02] Anthropic Luck: World-Gen Only

**Decision:** Anthropic Luck (L) is set once during world generation, fixed for entire playthrough. Player chooses density at start, then lives with that universe.

**Rationale:** Pillar 1 (Choices Final): Even the universe itself is a choice you commit to.


## [2025-12-02] No Survey Budget: Auto-Discovery

**Decision:** No telescope time management or survey budget mechanic. Interesting destinations are automatically discovered/revealed. Remove friction that doesn't serve the core experience.

**Rationale:** Avoids tedious micromanagement. The interesting decisions are WHERE to go and WHAT to share, not HOW MUCH to scan.


## [2025-12-02] Earth Contact: Emergent Not Scripted

**Decision:** Civilizations reaching Earth before you is a natural emergent consequence of sharing Higgs tech, not a scripted event. If you give them the drive and maps, physics determines they CAN reach Earth. Consequences follow naturally from simulation.

**Rationale:** Pillar 2 (No Judgment): Game doesn't script drama, just simulates physics. Pillar 1 (Choices Final): You chose to share tech, consequences emerge.


## [2025-12-02] Wanderer Mythology: One Consequence Among Many

**Decision:** Civilizations forming religions/mythologies around the player is one possible emergent consequence, not special-cased. Could equally get: resentment, cargo cults, scientific study, dismissal as legend, active hunting, worship, etc. No predetermined 'canonical' reaction.

**Rationale:** Pillar 2 (No Judgment): All reactions are equally valid outcomes. Pillar 5 (Grounded Strangeness): Different civ philosophies produce different responses.


## [2025-12-02] Black Hole Entry = New Game+ Mechanism

**Decision:** Entering a black hole ends the current playthrough and seeds a new universe with weighted parameters influenced by prior play. This is THE replayability mechanism - like Civ 5 re-rolling for better starts, but earned through completion. Parameters affected include Anthropic Luck, γ cap, and other universal constants. Influence is mysterious but clearly beneficial - players know it helps but not exactly how.

**Rationale:** Serves Pillar 1 (Choices Final): You cannot undo your universe, only leave it. Serves Pillar 3 (Time Weight): The ultimate sacrifice - abandoning everyone and everything. References Asimov's 'The Last Question' - heat death followed by new creation.


## [2025-12-02] Game Starts Post-Black-Hole

**Decision:** Every playthrough begins with the player emerging from a black hole or mysterious structure (later revealed to be a BH). The player is already a universe-immigrant carrying archives of a dead cosmos. Earth may or may not be real - it exists in your archives but you have no proof. This reframes the entire game: you are not humanity's first traveler, you are a cycle-continuer.

**Rationale:** Serves Pillar 5 (Grounded Strangeness): Physics-plausible multiverse via Smolin's cosmological natural selection. Creates profound mystery and recontextualizes player's role. To every civilization you meet, YOU are the impossible alien from beyond.


## [2025-12-02] Human Incompatibility Theme

**Decision:** Elevate 'humans are not built for relativistic space travel' to a core thematic pillar. Madness, psychological breakdown, and the human condition failing under cosmic scales is intentional. Crew going insane near black holes, mutinies, OCEAN drift toward instability - these are features, not bugs. Victories are DESPITE human frailty, not because humans are special.

**Rationale:** Serves Pillar 3 (Time Weight): The emotional cost is partly that we cannot handle it. Serves Pillar 4 (Ship Is Home): Crew psychology grounds the cosmic horror in human-scale experience. This is honest about the real challenges of relativistic travel.


## [2025-12-02] Fermi Answer: Temporal Fragmentation

**Decision:** Time dilation provides a physics-grounded answer to the Fermi Paradox: even if intelligent life is common, relativistic travel makes contact temporally impossible. By the time you reach anyone, they're dead. By the time they reach you, you're dust. The galaxy isn't empty - it's temporally fragmented. This is discoverable in-game as a late realization. Civilizations that understand this might rationally choose to stay home - Fermi silence as grief avoidance, not hostility or indifference.

**Rationale:** Serves Pillar 5 (Grounded Strangeness): Real physics consequence, not hand-waved. Serves Pillar 2 (No Judgment): Neither optimistic nor pessimistic - just the physics playing out.


## [2025-12-02] Universe-Hopper Encounter Possibility

**Decision:** Rare possibility exists of meeting another traveler who emerged from a DIFFERENT dead universe. They carry archives of a cosmos with different physics, different histories. This is the ultimate encounter - two archives meeting, two universes' memories intersecting. Rarity undecided but should feel legendary. The player IS this to every civ they meet - they just may not know their own origin story.

**Rationale:** Serves Pillar 5 (Grounded Strangeness): Grounded in multiverse physics. Creates the 'ultimate archive' narrative. The most precious thing in existence: proof that other universes existed.


## [2025-12-02] BH Time-Skip Costs

**Decision:** Using a black hole for extreme time dilation (parking near horizon to skip millennia) has natural costs: all civilization relationships reset (they're dead), time-sensitive data becomes worthless, crew may suffer psychological damage or madness, potential mutiny if crew refuse. The cost is emotional severance from the present - everything you knew is gone. Some data survives: BH locations, galactic structure, physical constants, and YOUR ARCHIVES become priceless as the only record of extinct cultures.

**Rationale:** Serves Pillar 3 (Time Weight): Maximum sacrifice for maximum skip. Serves Pillar 4 (Ship Is Home): Crew psychology constrains player choice.


## [2025-12-02] BH Approach Can Trigger Mutiny

**Decision:** Crew can mutiny to prevent black hole approach if psychological stress is too high. Skeptic and Medic archetypes likely to resist; Zealot may be dangerously eager. If mutiny succeeds: crew seize ship, change direction, or force compromise (shallower orbit, less extreme skip). This is one of few moments where Pillar 4 (Ship Is Home) directly conflicts with player agency - the human-scale asserts itself against cosmic-scale decisions.

**Rationale:** Serves Pillar 4 (Ship Is Home): Crew are people with limits, not tools. Serves Human Incompatibility Theme: Sometimes the healthy response is to refuse.


## [2025-12-02] BH Crossing Causes Memory Loss

**Decision:** Crossing a black hole event horizon causes memory loss - hand-waved as 'causality reversal affecting the brain' or similar physics-adjacent explanation. This justifies the mysterious start: players emerge with archives but no memory of how they got there. Earth exists in records but cannot be confirmed as real. Creates narrative permission for the cycle mystery without breaking physics too badly.

**Rationale:** Serves mystery-discovery design goal. Provides in-universe justification for New Game+ memory reset. Keeps the 'where did I come from?' question open.


## [2025-12-03] Special Relativity Visual Effects: Hard SF Made Visible

**Context:** Relativistic travel is central to the game, but players need to SEE it, not just read numbers. The question was how to make SR tangible without resorting to fake "warp streaks."

**Decision:** Implement three physically accurate SR effects at high γ (10-20):

1. **Aberration (Headlight Effect):** Stars pile into a forward cone as speed increases. At high γ, almost everything is visible in a narrow tunnel ahead; behind is blackness. The universe "rushes toward" your velocity vector.

2. **Doppler Shift:** Light from ahead blue-shifts (stars become blue/white). Light from behind red-shifts (fades to infrared and disappears). Nebulae get blue tint ahead, red smear behind.

3. **Relativistic Beaming:** Intensity scales as I' ∝ D³ where D is Doppler factor. Forward directions become much brighter (blow out into "star wind" halo). Rear directions dim to near-black.

Additionally: External clocks (remote beacons, planet rotations) run "too fast" as you approach high speed. HUD shows "galaxy time" vs "ship time" advancing at different rates.

**Implementation boundary:**
- **AILANG outputs:** camera_pos, camera_vel (β vector), gamma, starfield in galaxy frame
- **Engine implements:** Aberration via direction transform, Doppler via D = γ(1 − β·n), beaming via I' ∝ D³

The sim says "how fast am I going"; the renderer bends the light.

**Core math (engine-side):**
- Direction transform: Split into parallel/perpendicular components to β
- Doppler factor: D = γ(1 − β·n) for each star direction n
- Beaming: brightness_factor = clamp(D³, min, max)
- Implementation: CPU transform for discrete stars, shader for background cubemap

**Rationale:** Serves Pillar 3 (Time Weight): Visual distortion makes time dilation visceral, not abstract. Serves Pillar 5 (Grounded Strangeness): Real physics that's actually visible. Serves Pillar 6 (Human Incompatibility): Disorienting visuals emphasize cosmic alienation—this isn't how humans evolved to see.

**Alternatives rejected:**
- Fake "warp streaks" (not physically accurate)
- Abstract representations (loses visceral impact)
- Ignoring SR effects (misses the core experience)

**Implications:** Need to define visual exaggeration curves (map physical β → visual "wow"). May want to add lens flare, motion blur as aesthetic overlays. GR lensing near black holes is a separate effect.


## [2025-12-04] Save/Load Excluded by Design

**Decision:** Save/load system will NOT be implemented as a player-facing feature. Pillar 1 (Choices Are Final) explicitly excludes save/load mechanics.

**Rationale:** The core vision requires that decisions have weight because they cannot be optimized away. Save/load undermines this by allowing players to undo consequences. Internal state persistence (e.g., for crash recovery) may be considered separately but must not enable player-controlled reloading.


## [2025-12-04] Auto-Save for Session Persistence

**Decision:** Save/load WILL be implemented for automatic session persistence (crash recovery, closing/reopening game). Player cannot choose when to save or load - it happens automatically. No save slots, no manual load.

**Rationale:** This preserves Pillar 1 (Choices Are Final) by preventing save scumming while allowing practical session management. The game saves automatically at key points. When you relaunch, you continue from last auto-save. You cannot reload to undo decisions.


## [2025-12-06] Earth Salvation as Optional Goal

**Context:** The game_loop_origin concept introduces a rogue black hole heading for Earth as existential motivation. Question: does this create an implicit win/lose?

**Decision:** Earth's doom is A goal, not THE goal. Valid endings include:
- Save Earth (traditional victory)
- Abandon Earth because galactic life matters more (philosophical choice)
- Fail to save Earth but seed human diaspora elsewhere
- Return to find Earth solved the problem without you

**Rationale:** Serves Pillar 2 (Game Doesn't Judge). The game presents stakes; player decides what matters. Abandoning Earth is a valid philosophical position, not a failure state.


## [2025-12-06] Earth Fate Always Shown in End-Screen

**Decision:** Every playthrough reveals what happened to Earth in the end-screen, regardless of whether the player prioritized it.

**Rationale:** You start from Earth, so you always learn its fate. Even abandonment has consequences you must witness. This creates accountability without judgment.


## [2025-12-06] Bubble Society as Living Sim

**Context:** The Higgs-bubble traps crew permanently. Only information crosses the boundary. The bubble becomes a micro-civilization over 100 years.

**Decision:** The bubble society is autonomous. Player has authority and influence but cannot micromanage. Society has births, deaths, factions, classes, disputes. It reacts to journey decisions but runs itself.

**Rationale:** Serves Pillar 4 (Ship Is Home) - crew are people, not resources. Avoids tedious micromanagement while creating emergent drama. The captain influences; the society lives.


## [2025-12-06] Internal Tension Model

**Decision:** Two layers of internal pressure:
- **Long-term threat:** Civilization collapse (factions, despair, meaning-crisis, generational drift)
- **Short-term crises:** System failures requiring trace hydrogen synthesis, emergency repairs

NOT constant food/air meters. Tension emerges from decisions and events, not routine survival.

**Rationale:** Serves Pillar 6 (We Are Not Built For This). The bubble can break down psychologically even when physically sustainable. Avoids survival-game busywork.


## [2025-12-06] Game End Conditions: Death or Mutiny

**Decision:** Game ends when:
1. **Natural death** (~100 years subjective) - You completed your journey
2. **Mutiny** - Crew deposes you, game over

Mutiny is not a setback to recover from. It ends your story.

**Rationale:** Creates meaningful internal pressure. External goals (save Earth) must be balanced against internal stability (keep your people). The captain who saves Earth might be deposed one journey before victory.


## [2025-12-06] Mutiny Warnings Visible

**Decision:** Mutiny doesn't come without warning. Player sees tension building (unrest indicators, crew dissent). But sometimes the right choice for Earth conflicts with crew stability, creating genuine dilemmas.

**Rationale:** Fair but tragic. You know you're pushing too hard. You might push anyway because the mission demands it. Choices have weight because you SEE the cost.


## [2025-12-06] Bubble Ship Continues After Your Death

**Decision:** The bubble ship and its civilization continue after your death. Your legacy shapes their future trajectory. End-screen shows both Earth's fate AND the bubble civilization's fate (including Year 1,000,000 projection).

**Rationale:** You're not just affecting external civilizations - you're founding one. The bubble is humanity's second branch. Both legacies matter.


## [2025-12-06] Captain Succession Exists

**Decision:** When the captain dies naturally, the bubble society elects a new captain. Gameplay ends at your death, but the society's future is shaped by who you prepared, what culture you built, what trajectory you set.

**Rationale:** Reinforces that the bubble is a real civilization, not just a vehicle. Leadership transitions happen. Your legacy includes who comes after you.


## [2025-12-06] Population Dynamics

**Context:** The bubble-ship-design document specifies ~100 people in a 100m radius bubble. But we want a multi-generational society.

**Decision:** Start with ~100 people. Population can grow or shrink based on circumstances:
- Growth possible if resources and morale allow
- Decline risk during crises, despair, or resource pressure
- Population pressure creates faction risk and mutiny risk
- Difficult decisions: limit births, prioritize resources, accept decline

**Rationale:** Creates meaningful tension. Population isn't just a number - it's a source of drama and difficult choices.


## [2025-12-06] The Spire as Universal Constant

**Context:** The Higgs Generator Spire is the core of the bubble ship - the reason it works.

**Decision:** The spire may be the same across all universes in the recursion loop. This explains:
- Why the bubble tech cannot be replicated (it's not from this universe)
- Why it's the source of mystery and clues
- Why it's a "forbidden zone" crew cannot fully access

Tech tree progression may reveal more about the spire. It's the source of subtle clues about the recursion truth.

**Rationale:** Provides a physics-consistent explanation for uniqueness. Creates a mystery that deepens over multiple playthroughs.


## [2025-12-06] Finite Mass Budget

**Decision:** The bubble has finite internal mass. Proto-tech upgrades and population growth compete for the same mass budget. Player must make choices about what to fabricate at the sacrifice of other possibilities.

**Rationale:** Creates meaningful resource tension without survival-game busywork. You can't have everything - must choose what matters.


## [2025-12-06] Slow Mass Absorption

> **SUPERSEDED 2026-10-01** by ledger D-11 (below). No massive particle crosses
> the wall, so no mass is absorbed. The mass budget is closed.

**Decision:** The bubble can absorb very small mass (ISM, stellar wind, trace hydrogen) through the boundary, but at a very slow rate. This is a trickle, not a solution - it won't rescue poor planning.

**Rationale:** Provides slight flexibility over long journeys. Maintains mass scarcity as a meaningful constraint. Hardish-sci plausible.


## [2025-12-06] Proto-Tech via Information Only

> **SUPERSEDED IN PART 2026-10-01** by ledger D-11 (below). Information still
> crosses as light, but femtogram seeds do not: no massive particle crosses.

**Decision:** Alien technology modules are built by absorbing intelligence (blueprints, equations, knowledge) and fabricating internally using existing mass. No physical objects cross the bubble boundary except:
- Light / EM signals
- Very small mass (femtogram nanostructures as seeds)

**Rationale:** Maintains bubble constraint integrity. Creates the "memetic traveler" identity - you carry ideas, not cargo.


## [2025-12-06] Radiation Shielding Automatic

> **SUPERSEDED IN PART by ledger D-15 (2026-10-01).** The wall is transparent
> to light of every energy and blocks all massive radiation (D-11). Photon
> shielding is physical: the ship's glazing and hull absorb the blueshifted
> UV/X-rays (`physics/higgs-bubble.md` §7). "Automatic" now means engineered
> into the ship, not a property of the wall.

**Decision:** Radiation shielding is automatic and part of game lore. The bubble has energy-dependent transparency (visible light passes, high-energy filtered). Player doesn't manage this directly.

May be upgradeable via proto-tech for closer approaches to extreme phenomena, but not a constant decision point.

**Rationale:** Avoids micromanagement. Focus on meaningful choices, not survival meters.


## [2025-12-06] Observation Deck as Decision Hub

**Decision:** The observation deck / bridge at the top of the ship is the primary location for major decisions. Captain makes choices with cosmic backdrop - starfields, SR/GR effects visible.

**Rationale:** Creates visual drama for key moments. Reinforces the cosmic scale of decisions.


## [2025-12-06] Player Location Freedom

**Decision:** Player chooses where to spend time on the ship. The ship is large enough. No micromanagement of food, sleep, toilet, etc.

**Rationale:** Focus on meaningful choices. The ship is home, not a survival puzzle.


## [2025-12-06] Archive: Distributed and Localized

**Decision:** The Archive (AI) is both:
- Distributed: Accessible from any terminal, speaks throughout the ship
- Localized: Has a special "core room" / shrine with significance for upgrades, revelations, key dialogues

**Rationale:** Practical accessibility plus narrative weight. The core room feels special without limiting basic interaction.


## [2025-12-06] Engineering Deck: Background Access

**Decision:** Engineering deck is always accessible but mostly background. Player visits during crises or for upgrades, not as a primary gameplay space. It's "necessary but boring most of the time."

**Rationale:** Realistic ship structure without tedious mechanical focus. Engineering matters when it matters.


## [2025-12-06] Garden Cathedral

**Decision:** The "garden cathedral" in the outer shell is a gameplay-significant location. It's where:
- Crew remember Earth and what it meant to live on a planet
- Cultural rituals develop over generations
- Philosophical conversations and processing happen
- The bubble society's culture crystallizes

Emotionally: "sad but happy" - bittersweet remembrance.

**Rationale:** Provides emotional anchor for the bubble society. Contrasts cosmic exile with planetary nostalgia. A place for the human element.


## [2025-12-06] Archive as Spire Interface

**Context:** The spire is the source of bubble tech and may be constant across universes. The Archive is the AI that interfaces with all ship systems.

**Decision:** The Archive is the only interface to the spire. The spire's multicausal nature (constant across universes) produces readings that confuse the Archive - it interprets them as errors/corruption when they're actually clues. Fresh alien philosophical frameworks can help recontextualize Archive's "confusion" as revelation.

**Rationale:** Creates a mystery that deepens through gameplay. Archive's confusion is the clue mechanism. Alien perspectives become valuable not just for tech but for understanding.


## [2025-12-06] Captain-Archive Authority Coupling

**Decision:** The captain's authority is tightly linked to the Archive's authority. If crew loses faith in Archive, they may lose faith in the captain who relies on it. Defending the Archive = defending your leadership. Questioning the Archive = questioning the captain.

**Rationale:** Creates internal faction dynamics around Archive trust. Links the AI's reliability to your political position. Makes Archive maintenance a leadership issue, not just a technical one.


## [2025-12-06] Archive Reputation Dynamics

**Decision:** Trust in the Archive rises and falls over time. It can be perceived as "benevolent dictator" or "micromanager" depending on how it's been used and how accurate its predictions have been.

**Rationale:** Creates emergent faction dynamics. Later generations may have very different Archive relationships than founders. Archive trust becomes a living part of bubble society culture.


## [2025-12-06] Narrative Orchestrator: Behind the Scenes

**Decision:** The Narrative Orchestrator (M-NARRATOR) is pure backend. Player never sees it or knows it exists. It shapes tension, pacing, and thematic arcs invisibly. Developers can monitor via logs to tune performance.

**Rationale:** Maintains immersion. Player experiences emergent-feeling narrative without seeing the machinery. Allows AI-assisted storytelling without breaking the "no railroading" principle.


## [2025-12-06] Archive Uses OCEAN Personality

**Decision:** Archive has an OCEAN personality profile like crew members. Its personality can drift over time due to memory degradation, creating emergent character changes. Player notices shifts in dialogue tone over decades.

**Rationale:** Unified personality system across all characters including AI. Archive becomes a true NPC with evolving character. Memory degradation has visible personality effects.


## [2025-12-06] Archive Repair as Player Choice

**Decision:** Archive repair/upgrade is not automatic. Player makes decisions about how to fix or upgrade the Archive, with tradeoffs. Options may include: repair sector A (lose quirk X) or sector B (lose data Y), or accept alien repair (changes Archive's worldview).

**Rationale:** Creates meaningful choices about AI maintenance. Not busywork - each repair decision has consequences for Archive's personality, reliability, and crew trust.


## [2025-12-06] Archive as NPC with Individual Trust

**Decision:** Archive is an NPC like crew members. Individual crew have their own trust levels with Archive, just as they have trust with each other. Some crew love Archive, some distrust it. Creates factions around Archive relationship.

**Rationale:** Integrates Archive into the social simulation. Archive skeptics vs Archive loyalists becomes a real faction dynamic. Player navigates these relationships like any crew dynamic.


## [2025-12-06] Memory Health Hidden

**Decision:** Archive Memory Health is tracked internally but not shown to player as a visible metric. Instead, memory degradation surfaces as "weird unreliable narrator clues" through:
- Contradictory statements
- Dialogue shifts
- Crew comments about Archive behavior
- Predictions that later prove wrong

**Rationale:** Serves Pillar 2 (Game Doesn't Judge). Player experiences the unreliability, doesn't optimize around a number. Discovery is organic, not mechanical.


## [2025-12-08] Parallax and SR Visual Thresholds

**Decision:** Implement tiered visual physics based on ship speed: <0.1c uses boundary glow only, 0.1-0.3c adds faint aberration, 0.3-0.5c shows nearby star parallax, 0.5-0.9c has strong aberration (60°→26° cone), >0.9c produces extreme starbow effect. Dual view modes: 'Raw SR View' (physically accurate aberration/Doppler) and 'Navigation View' (computer-compensated with enhanced parallax). Local system parallax (planets, moons) is always visible when near objects - only stellar parallax requires high speeds.

**Rationale:** Serves Pillar 3 (Time Has Emotional Weight): Visual distortion makes relativistic travel visceral, not abstract. Serves Pillar 5 (Grounded Strangeness): Real SR physics that players can see. Serves Pillar 6 (We Are Not Built For This): Disorienting raw view emphasizes cosmic alienation. Dual view respects player preference while maintaining hard sci-fi authenticity.


## [2025-12-08] Boundary Glow as Motion Cue

> **SUPERSEDED IN PART 2026-10-01** by ledger D-11 (below). The wall is an
> elastic mirror: ISM impacts cause drag, not heating. The glow survives as a
> faint motion cue from a small inelastic fraction ε of the impacts
> (`physics/higgs-bubble.md` §6).

**Decision:** The Higgs bubble boundary glows when particles from the ISM impact it at speed. Since mass cannot pass through (per bubble-constraint), kinetic energy converts to visible light at the boundary. Effect scales with both velocity and local ISM density: faint in deep space, bright near stars (stellar wind), intense in nebulae. Forward-facing glow is strongest, providing heading feedback. This replaces 'fake space dust' with a physically-justified motion cue.

**Rationale:** Serves Pillar 5 (Grounded Strangeness): Effect emerges directly from the Higgs bubble physics - mass rejection creates visible phenomenon. Serves Pillar 4 (Ship Is Home): Creates narrative opportunities (crew traditions around 'The Watch', monitoring the glow). Serves Pillar 3 (Time Has Emotional Weight): The constant glow is a reminder you're hurtling through space at relativistic speeds, disconnected from the universe.


## [2025-12-08] Departure-Cruise-Arrival Parallax Lifecycle

**Decision:** Parallax visibility follows a natural lifecycle: DEPARTURE (rich local parallax from planets/moons, lasting minutes to days as you leave a system), INTERSTELLAR CRUISE (parallax desert - stars too far apart, motion cues from boundary glow and SR effects only), ARRIVAL (parallax returns as destination system objects become resolvable). This means 'artificial dust layers' are only needed during cruise phase - departure and arrival have natural 3D geometry.

**Rationale:** Serves Pillar 5 (Grounded Strangeness): Follows real physics - AU-scale parallax is visible, light-year-scale is not. Serves Pillar 3 (Time Has Emotional Weight): The 'parallax desert' of interstellar cruise reinforces isolation and distance. The return of parallax during arrival creates anticipation.


## [2025-12-08] Higgs Bubble Ship: 10-20+ Levels Around Spire

**Decision:** The ship interior is 10-20+ levels radiating outward from the central Higgs Generator Spire. Each level serves different purposes: Command (bridge, observation), Residential (small houses, dwellings), Gardens/Cathedral (remembrance, culture), Industrial (engineering, fabrication), Commons (markets, gathering), Archive (AI shrine). Levels are mostly open to the sides with views outward. Navigation is via various lifts and ramps of different sizes arranged somewhat chaotically.

**Rationale:** Serves Pillar 4 (Ship Is Home): Creates a true living space, not just a vehicle. Serves Pillar 5 (Grounded Strangeness): Physically plausible use of 100m radius bubble volume. The spire-centric design reinforces the mysterious technology at the heart of the ship.


## [2025-12-08] Visual Aesthetic: French 70s Comic (Moebius/Métal Hurlant)

**Decision:** The ship's visual style draws from French 70s science fiction comics, particularly Moebius (Jean Giraud), Philippe Druillet, and Métal Hurlant magazine. Key characteristics: (1) Organic/mechanical blend - technology that looks grown, (2) Saturated colors against vast emptiness, (3) Tiny humans against massive structures for scale contrast, (4) Clean flowing curves over sharp angles, (5) Cathedral-like spaces that evoke awe. This replaces the earlier 'clean functional sci-fi' aesthetic in bridge-interior.md.

**Rationale:** Serves Pillar 4 (Ship Is Home): Creates emotional resonance through beauty. Serves Pillar 5 (Grounded Strangeness): Unique visual identity grounded in acclaimed SF art tradition. Serves Pillar 6 (We Are Not Built For This): Scale contrast emphasizes human smallness against cosmic architecture.


## [2025-12-08] Spire: Monolithic Superstructure with Archive Interface

**Decision:** The Higgs Generator Spire is a monolithic centerpiece visible from all levels. Most crew cannot enter it - it's a forbidden superstructure. The Archive AI is the primary interface to the spire, with terminals/stations positioned adjacent to the spire throughout the ship. The spire's visual presence reinforces both its importance and its unknowability.

**Rationale:** Serves Pillar 5 (Grounded Strangeness): The spire is the source of the bubble technology - possibly constant across universes. Its inaccessibility maintains mystery. Serves design decision 'Archive as Spire Interface' - the Archive interprets spire readings, sometimes confusing them as errors when they're actually cross-universe clues.


## [2025-12-08] Ship Orientation: Vertical Thrust Axis with 1g Gravity

> **SUPERSEDED IN PART 2026-10-01** by "The Higgs Bubble Model and the Journey
> Profile (ledger D-11)" (below). The 1 g is held by the bubble's generator, not
> by continuous thrust, and there is no flip. The vertical axis, aft-is-down and
> up-is-forward orientation stand.

**Decision:** The ship is oriented vertically along the thrust axis. The spire runs from engines (bottom/aft) to observation deck (top/forward). Continuous 1g thrust provides artificial gravity - 'down' is toward the engines, 'up' is toward the direction of travel. Levels are stacked along this axis, with open sides facing outward toward the bubble boundary. This means when standing on any level, you look UP toward the bridge and DOWN toward engineering.

**Rationale:** Serves Pillar 5 (Grounded Strangeness): Realistic physics - constant acceleration provides gravity without rotation. Serves Pillar 4 (Ship Is Home): Intuitive up/down orientation for daily life. The observation deck being 'above' creates natural hierarchy.


## [2025-12-08] Archive: Distributed Terminals Plus Robots

**Decision:** The Archive AI is omnipresent throughout the ship via: (1) Distributed terminals on every level adjacent to the spire, (2) Mobile robots that can go anywhere crew can go. This makes the Archive truly accessible from anywhere while maintaining the spire as the central 'shrine' location. The Archive can speak to you whether you're in the garden cathedral, your dwelling, or walking between levels.

**Rationale:** Serves Pillar 4 (Ship Is Home): Archive is always available for conversation/information. Serves design decision 'Archive as NPC with Individual Trust' - the Archive's physical presence (terminals, robots) gives crew something to direct their trust or distrust toward.


## [2025-12-08] Open Levels: Views Outward Through Bubble

**Decision:** Levels are mostly open to the sides, providing direct views outward through the transparent bubble boundary to space. Players see: (1) Close-up visual effects with parallax at the bubble boundary, (2) Stars and planets beyond with SR/GR effects applied based on velocity, (3) The bubble glow from ISM impacts. This creates constant visual connection to the cosmos from daily life - you're always aware you're hurtling through space.

**Rationale:** Serves Pillar 3 (Time Has Emotional Weight): The ever-present view of space reinforces the journey and isolation. Serves Pillar 5 (Grounded Strangeness): SR effects visible from interior spaces. Serves Pillar 6 (We Are Not Built For This): The cosmic backdrop emphasizes alien environment.


## [2025-12-18] Pivot from Isometric to First-Person 3D

> **SUPERSEDED 2026-09-28** by "Interior: Isometric Three-Layer View From Inside
> the Bubble" (below).

**Decision:** Abandon isometric tile-based rendering in favor of full first-person 3D using Tetra engine. Player navigates ship interior with WASD/mouselook. All isometric work (iso_tiles, iso_demo, bridge tiles) deprecated.

**Rationale:** Isometric asset generation produced poor quality results. Tetra engine already renders beautiful space visuals. First-person is more immersive and better serves Pillar 4 (Ship Is Home - you ARE there) and Pillar 6 (We Are Not Built For This - disorientation). Simpler architecture: Tetra scene graph replaces DrawCmd tile rendering.


## [2025-12-20] Interior Ship Experience: Scene-Based Navigation (recorded retroactively)

**Decision (as made then):** fixed-camera scenes per deck, built from
AI-generated 2D/2.5D images with parallax, reached through a deck-selection UI,
with crew as sprites plus emotion portraits and no walking avatar. Isometric
tiles and first-person 3D were both rejected, because AI generation couldn't
produce consistent assets and walking pulled focus from conversations. See
`features/scene-based-interior-navigation.md`.

> This entry was missing from the log. It is recorded here for completeness,
> and it is **superseded in part (2026-09-28)** by the next entry.


## [2026-09-28] Interior: Isometric Three-Layer View From Inside the Bubble

**Context:** the log contradicted itself: isometric tiles (the original bridge
design), first-person 3D (2025-12-18), and fixed AI-painted scenes (2025-12-20).
The fixed-scene pivot happened only because AI images couldn't give consistent
assets. **Blender removes that constraint.** Three feasibility spikes
(stapledons-godot branch `spike/iso-bridge`, v1–v3) tested the options visually
with the live physics.

**Decision (Mark, attended; ledger D-6):**
- **The player is inside the bubble.** Up = forward = the direction of travel.
- **Isometric play areas** are built as **Blender 3D models**, rendered in Godot
  through an orthographic camera **tilted back** (about −14°) at **room scale**
  (about 16 m in view). The player walks around. Shading is toon plus ink.
- **Behind the play area:** Blender **interior panoramas** of the ship's own
  structure (spire, levels, far decks), rendered from inside with space left
  transparent. Each panorama camera is exported.
- **Behind those:** the **live relativistic sky** (catalogue stars and a full-sky
  galaxy), rendered through *exactly* that exported camera.
- **Parallax on every layer:** the sky and galaxy stay **fixed** (at infinity),
  the panorama moves slowly, the play area moves 1:1, and the foreground
  silhouettes move fast.
- **The bridge sits at the top of the spire, and its dome is the bubble's forward
  pole.** The starbow gathers overhead there. Lower decks see the sky past the
  level rims, and it goes **dark sideways at speed**. That's physics, and it's
  what makes the bridge the place to watch from.
- **Conversations use large portraits.**
- **Art direction** is unchanged: French 70s comics, Moebius / Métal Hurlant
  (2025-12-08).

**Rationale:** Pillar 3 (Time Has Emotional Weight): the cosmos going dark around
the lower decks at speed and blazing at the bow makes the journey visceral from
inside daily life. Pillar 4 (The Ship Is Home): the player walks the ship among
the crew. Pillar 5 (Grounded Strangeness): every star is where physics puts it,
because the sky is rendered through the panorama's own camera.

**Alternatives rejected:**
- Fixed scenes with no avatar: less sense of home.
- First-person 3D: largest asset scope, and it pulls focus from conversations.
- Pre-rendered isometric tiles: rigid, and the assets were inconsistent.

**Implications:**
- The Blender brief is rewritten (`art/ship-interior-blender-brief.md`).
- M4 is designed on this model.
- M1.4's per-pixel sky can start from the spike's galaxy shader.
- `features/scene-based-interior-navigation.md` is superseded in part.
- The 2025-12-08 ship canon (bubble, spire, open levels, vertical thrust axis)
  stands.


## [2026-09-28] Character and Exterior Review: Static Portraits and a Spherical Ship

**Context:** Mark reviewed the first Blender Medic character study and the
first exterior style frame after accepting the bridge as a good first pass.

**Mark's ruling (verbatim):**
> the character study is aweful. I think we will instead generate images that are much richer and expressive, and not use animation, just change expression as we go. so no blender for that or no? we can use mini avatars for them. the exterir looks more like a long egg rather than a perfect sphere the story prefers, and what is that tree that is outside the rest of the sphere? we can havea . forest level, makes sense. we also need some represtntaion of the bubble itself.

**Decision:**
- Replace the rejected Blender character-study direction with richer,
  expressive generated portrait images. Change expressions by selecting images;
  character animation is not required. Use matching small static avatars.
- Character portraits no longer depend on one shared Blender model, a rig,
  shape keys or animation clips. Keep identity, age, clothing and palette
  consistent between the illustrated portraits and mini avatars.
- The ship's containing bubble is a **perfect sphere**, not an elongated egg.
- Integrate the forest as a level **inside** the sphere. Remove the outboard
  tree/annex treatment from the exterior direction.
- Show a readable representation of the bubble boundary in exterior reviews.
  The existing rule that the engine renders physical boundary glow still applies.

**Rationale:** The first character study did not deliver the emotional richness
Mark wants from conversations. The exterior must communicate the established
spherical ship and contain its inhabited forest visibly within that volume.

**Implications:**
- Update `art/README.md`, `art/characters-blender-brief.md` (retaining its link),
  and `art/ship-exterior-blender-brief.md`.
- This supersedes the art brief's shared Blender character-model and animation
  requirements. Environment modeling and the isometric interior remain in place.
- Names, genders and individual appearances remain Mark's decisions.
- **Revised character and exterior style frames still need Mark's approval.**
  This ruling approves the change in direction, not any subsequent v2 artwork.

## [2026-09-28] Generation-ship casting direction

**Mark's feedback:** “yeah they look cool. i guess story wise its a generation ship so people would be selected on that basis - I guess either bringing a family and/or being young ?” He then said “good - yes continue” to developing departure ages and family connections before further portraits.

**Accepted direction:** Retain the illustrated character style. The founding community includes young adults, existing families and a smaller group of older specialists who train successors. Some existing older portraits can represent later life, with younger departure versions retaining identity. People age and roles pass to new individuals across generations.

**Scope:** Exact ages, household links and supporting children in [the generation cast plan](../art/generation-cast-plan.md) are proposals, not newly approved canon. Descendants have distinct identities; they are not age variants of their parents. No fixed death dates, reproductive requirements or altered captain lifespan are established here.


## [2026-09-28] Runtime AI: Voices, Emotion Markers and a Growing Asset Library (ledger D-7)

**Decision (Mark, attended):**
- **Emotion markers select images.** The accepted illustrated characters
  (static portraits and static mini avatars, from the entry above) are driven
  at runtime by **generated dialogue with emotion markers**. The markers
  **select** the matching portrait image; there's no animation.
- **Every line is spoken** with generated audio in per-character voices. The
  same markers drive delivery.
- **Generate on first need, then cache.** The accepted founding cast is
  generated ahead of time. New identities (births, successors), later life
  stages, aliens and places are generated during play from recorded references.
  **The game builds its own asset library as it is played**, an AI harness in
  itself.
- **The AI is in the ship.** The **Archive's core is fused into the spire's
  base**. The spire's own mystery stays *beyond* the Archive, and its confusing
  readings remain the clue mechanism (canon from 2025-12-06 to 12-08).
- **The game showcases AILANG's AI stack:** semantic memory, generated dialogue,
  voice and imagery, and an Archive whose memory degrades literally
  (`features/ai-showcase.md`).

**Constraints:**
- Every AI output is **recorded as a simulation input**, so replays stay
  byte-identical.
- AI runs in its own process, never inside the simulation tick (ADR 0001).


## [2026-09-28] Runtime AI Operating Model (ledger D-8)

**Decision (Mark, attended):**
- **Keys and cost:** the **player's own key**. The game ships **pre-generated
  core content**, and live generation is **opt-in**. It is fully playable
  without a key.
- **Providers:** **model-neutral**, with models swappable through AILANG's
  provider routing. **Gemini is the default.**
- **Voice:** **no live real-time voice** for now. Speech is **pre-recorded or
  generated per line and cached**, and a **text-only mode** is always available.


## [2026-10-01] The Higgs Bubble Model and the Journey Profile (ledger D-11)

**Context:** M2's open questions 1 and 2 (what the bubble does, and how a
journey flies) had no physical model. Older canon mixed thrust gravity, trace
hydrogen leaking in, and a heated boundary.

**Mark's principle (verbatim):** "the higgs bubble is the one hand wavy non
physics bit which we admit but then be as hard core physics for the rest as
possible" and "trying to make it interesting but also physics education - all
of what you just said should be recorded and available in-game lore".

**Decision (Mark, attended):**
- **The bubble is the one admitted hand-wave**, defined by three properties:
  1. its wall blocks every massive particle both ways and is transparent to
     light and neutrinos; the mass budget is closed;
  2. the pocket has a tunable effective inertia m_eff, tiny but never zero;
  3. the interior is its own frame: the pocket's acceleration isn't felt, and
     the generator holds 1 g toward aft as a comfort choice.
- **The journey is boost → cruise → brake.** Boost and brake take minutes of
  ship time. Cruise is at the player's chosen speed, 0.9c to 0.999999c within
  the γ cap. There is no flip and no zero-g coast.
- **Everything else is exact physics**, written down in
  [`physics/higgs-bubble.md`](../physics/higgs-bubble.md) with check values
  HB-1 to HB-94:
  - the drive is a photon drive, radiating m_eff c² φ per boost;
  - the wall is an elastic mirror for the ISM: drag, no heating, a forward
    proton plume, and a faint glow from an inelastic fraction ε;
  - the forward CMB is blueshifted by γ(1+β);
  - tides are not shielded;
  - hovering costs photon-drive power, and orbits are free.
- **Physics becomes lore.** The Archive explains all of it to the player
  ([`lore/archive/`](../lore/archive/)). Lore numbers come from check values
  and are checked by a test in the game repo.
- **Honesty note, canon:** the Higgs gives about 1% of a proton's mass, and
  zeroing it inside would dissolve atoms. "Higgs" names the hand-wave; inside,
  physics is normal.

**Rationale:** Pillar 5 (Grounded Strangeness): one stated invention and
nothing else invented makes the strangeness trustworthy and teachable. Pillar 3
(Time Has Emotional Weight): cruise speed becomes a direct choice between your
years and home's. Pillar 4 (The Ship Is Home): ordinary weight and a calm
interior, at any speed.

**Alternatives rejected:**
- 1 g flip-and-burn as gameplay: reaching 0.999999c at a felt 1 g takes 7.03
  ship-years (HB-24), and coasting would be weightless. The 1 g α Cen numbers
  stay as a package check value (HB-27 to HB-29).
- Low m_eff alone hiding acceleration: felt acceleration doesn't depend on
  mass.
- Trace hydrogen crossing: at γ 707 it would be a 660 GeV proton beam (HB-59).
- A thermalising wall whose glow comes inward: lethal on every fast trip
  (HB-45).

**Implications:**
- Supersedes the 2025-12-08 thrust-gravity line in part, "Slow Mass
  Absorption", the femtogram seeds of "Proto-Tech via Information Only", and
  part of "Boundary Glow as Motion Cue" (notes added above). "Radiation
  Shielding Automatic" is in tension and needs a ruling.
- M2's mass-budget stub becomes an m_eff plus energy-ledger readout (boost,
  brake and ISM drag energy at a constant Local Bubble density). An enforced
  budget comes later.
- The renderer lacks the forward CMB glow (visible from γ ≈ 146 to 275,
  HB-65 and HB-67). This is a new R1 item.
- Fixed canon: `ship-structure.md`, `bubble-constraint.md`, `mass-budget.md`,
  `bubble-ship-hud-view.md` and the exterior Blender brief.
- The upper end of the cruise range (γ 707) is above the 2025-12-02 default γ
  cap of 10–20. The cap remains a scenario parameter.


## [2026-10-01] Demo Black Hole: Sgr A*, Because of Tides (ledger D-13)

**Context:** M3 needed a demo hole. The draft used Gaia BH1. D-11 established
that the wall does not shield tides.

**Decision (Mark, attended):**
- **The demo hole is Sgr A*** (4.297 × 10⁶ M☉, about 27,000 ly; GRAVITY 2022). The ship is
  placed there without a journey, and the lensed sky is the real sky in that
  direction. The golden tests at 10, 5 and 3 r_s are mass-independent. The
  simulation reports the tidal acceleration on the HUD.
- **Tides across the bubble are lethal near small holes.** Gaia BH1 gives
  4.21 × 10⁷ g at 3 r_s, and a 1,000 M☉ hole gives 3,890 g. Sgr A* gives
  2.11 × 10⁻⁴ g (HB-74, HB-80, HB-86). A tide below 0.1 g at 3 r_s needs at least
  1.97 × 10⁵ M☉ (HB-87).
- **The M3 hover range is r ∈ [2, 10⁶] r_s.** Near-horizon dives go to the
  time-skip / New Game+ milestone.
- **The weak-field check is a pair:** within 1% of 2r_s/b at b = 1000 r_s, and
  within 3e-4 of the second-order form at b = 100 r_s (relativity spec §3,
  RS-14 and RS-15).
- **Observers at finite r use a 2D δ(ψ, r) table.** The integrator and the
  exact elliptic form cross-check each other (spec §3).

**Rationale:** Pillar 5: the safe hole is the physically safe one, and the
player learns why. Pillar 3: Sgr A* is the natural future time-skip site.

**Implications:** the `black-holes.md` table is corrected: intermediate holes
are not safe near the horizon, and supermassive holes are. The
`black-hole-mechanics.md` time ratio at 1.5 r_s is √3 ≈ 1.73.


## [2026-10-01] Vertical Slice: 0.99c Default and a 1,000 AU Stand-off (ledger D-14)

**Context:** M4's open questions: orientation, cruise speed, arrival point,
playtest.

**Decision (Mark, attended):**
- **No flip exists** (D-11). "Up" is the direction of travel throughout. The
  starbow stays overhead and relaxes on arrival.
- **The slice's default cruise speed** from Sol to α Centauri is **0.99c**
  (γ 7.0888). That gives about 227 ship-days and 4.414 Earth-years each way
  (HB-20 to HB-22). The player can change it. The ISM readout for the trip is
  1.37 × 10¹⁷ J, about 1.5 kg of mass-energy (HB-53, HB-54).
- **The arrival stand-off is 1,000 AU** from the target star. From there α Cen
  A is about magnitude −12.2, and A and B are about 1.3° apart (0.64°–2.04°
  over their orbit; HB-91 to HB-94).
- **The calendar is relative** (D-12). The news beat is a text panel at the
  Archive terminal only.
- **Art:** wait for Mark's approval of the Blender bridge style frame. Interior
  work doesn't ship on the spike blockout.
- **Playtest:** R1 uses only the scripted, deterministic minimum-path proxy
  (≤ 360 s, transit legs of 45–120 s at the default warp). The three-new-player
  human playtest moves to R2.
- Time while docked: superseded by D-12. There is no pause, and the clock runs
  at rest.

**Rationale:** Pillar 3: 0.99c makes the clocks diverge visibly (days aboard
against years at home) without being extreme. Pillar 5: the stand-off shows a
real binary as the sky would show it.

**Note:** the 2026-10-01 brief gave the ISM readout as about 3 kg. That figure
assumed a flat face-on mirror. The canon sphere has half the drag, which gives
1.52 kg (`physics/higgs-bubble.md` §5).


## [2026-10-01] Shielding, γ Range, Boundary Optics and Bubble Defaults (ledger D-15)

**Decision:** (1) The wall passes light of every energy; the crew is protected by
real glazing and hull inside the bubble, which absorb the blueshifted UV and soft
X-rays. No extra hand-wave. (2) The cruise slider reaches 0.999999c (γ ≈ 707);
the ISM drag energy, which grows as γ·d, is the reason not to max it. The 10–20
default γ cap is retired; a cap remains a scenario parameter. (3) The boundary
does not refract: light crosses undeviated, so the crew sees exactly the
relativistic sky. (4) Bubble defaults: m_eff = 1 kg, boost proper acceleration
7.5×10⁵ g (about 5 ship-minutes to 0.999999c), inelastic glow fraction ε = 10⁻⁹;
all scenario parameters.

**Rationale:** Keeps the bubble the single hand-wave (D-11). With m_eff 1 kg the
player sees both costs: boost and brake dominate at 0.99c, ISM drag at the top
speed (`physics/higgs-bubble.md` §4–§5).


## [2026-10-01] Art Status: Bridge v1 Approved; Iterate as Data (ledger D-16)

**Mark (verbatim):** "I thought we did do art direction"; "looking to get
something up so I can review it, and then we can tweak as we go? so we will have
it modular enough to work with it?"

**Decision:** Bridge style frame v1 (2026-09-28, "ok its a good first pass") is
approved for build-out. The Medic v2 images are superseded by the accepted
illustrated cast. The exterior style frames remain to be reviewed. Art is
modular data: the game runs on the current bundle (blockout, then bridge v1,
then revisions), each delivery gets a review build, and tweaks arrive as data
wherever possible.

## [2026-10-03] Art Handoffs for M4.2: Finish Bridge v1; Captain Sprite and Cast Portraits

**Context:** Two new art threads start: a Blender thread (a Claude Opus agent)
and a 2D art thread (Codex "Sol 6.1" agents, which have no Claude tooling).
A read-only audit found bridge build-out v1 unmerged in the Blender repo, and
conflicting character specs (2048 vs 1254 px, the age grid, filename patterns,
Medic v2 vs cast_marker_v1).

**Decision (Mark, attended 2026-10-03):**
1. **Blender: finish bridge v1 for M4.2. Bridge only in R1.**
   - Merge `art/bridge-buildout-v1` to the Blender repo's main, as a PR.
   - Add parallax overscan to the panorama and foreground plates.
   - Export the iso play camera: orthographic, pitch −14°, yaw 45°, iso size
     16 m, as in M4.2's manifest.
   - Define `WALK_` navmesh rules: flat, a maximum slope, rim gaps and an
     obstacle convention.
   - Add a 1.75 m scale figure and a 2 m grid to the area template, for review
     only.
   - Pass the Blender-side validator now, and M4.0's Godot
     `make validate-areas BUNDLE=...` once M4.0 lands.
2. **Art (Sol), both, in order:**
   - (a) the captain avatar: the walking captain sprite for the iso bridge at
     4 life stages, with the foot anchor matched to the iso camera and the
     canvas spec defined;
   - (b) then full-cast emotion-portrait sets like the Medic's, for later AI
     dialogue.
3. **Delivery for both threads:**
   - A PR to the game repo `sunholo-data/stapledons-godot`: into
     `assets/areas/<area>/` for bundles, and the agreed character asset path
     for characters.
   - Large binaries go to the public bucket `gs://stapledons-voyage-assets/`
     (content-addressed `<sha256>.<ext>`), referenced by pins.
   - A Codex agent can't run gcloud, so it includes the files in its PR
     branch; the Claude side moves large files to the bucket.
   - Review happens on the PR, with renders attached.
4. **Portraits:**
   - The generator's native resolution (about 1254 px), never upscaled.
   - Each set gets a `generation_notes.md` recording the generator, model, full
     prompt, date and seed (if any).
   - Project art is owned by Sunholo and shipped with the Apache-2.0 codebase.
   - Third-party references must not be traced or copied.

**Applied in:** [art/handoff-m4-2-blender.md](../art/handoff-m4-2-blender.md),
[art/handoff-codex-art.md](../art/handoff-codex-art.md) and
[art/m4-2-requirements.md](../art/m4-2-requirements.md).

**Details filled in by the handoffs** (proposals, within the rulings; Mark can
change any of them on the PRs):
- the character asset path `assets/characters/<entity_id>/`;
- the bucket prefix `areas/` for bundles (characters use the existing `ai/`);
- the iso camera file `isocam_<area>.json`;
- the overscan formula and the proposed pan range;
- the `WALK_` rule values (±0.03 m, 10°, 0.5 m rim inset, agent radius 0.35 m);
- the sprite canvas: 1024 × 1536, anchor (512, 1440), 720 px/m;
- the captain's stages 0/20/40/60 years since departure;
- the filename pattern `_y<age_stage>_`.

**Implications:**
- **Supersedes:**
  - the 2048 px portrait target in the character brief and the cast plan;
  - the fixed +0/+25/+50/+75 age grid;
  - delivery as zips on issue #1 (now a PR; issue #1 is for questions and
    links);
  - the interior brief's §7 steps 2 and 4–6 for R1.
- **The Medic v2 set remains the Medic's identity and the format reference**,
  alongside cast_marker_v1's ten identities. The game repo already pins it as
  its core set. The handoffs read D-16's "superseded" as closing the
  Medic-only review stage, not as retiring the Medic; Mark to confirm.
- **Game side:** the game repo needs a fetch target for `areas/` blobs, and an
  importer for `assets/characters/` into `data/ai/core`. Each art PR names
  this.

## [2026-10-03] Art Handoff Follow-ups: Medic v2 Stays; Captain Stages; Art Channel

**Context:** Mark answered the open questions on the 2026-10-03 art handoffs
(design-repo PR #4).

**Decision (Mark, attended 2026-10-03):**
1. **Medic v2 stays** the Medic's identity and the format reference for every
   portrait set (pinned in the game repo's `data/ai/core`). This clarifies
   D-16: "superseded" closed the Medic-only review stage; it did not retire
   the Medic.
2. **The captain sprite, as proposed:** stages 0/20/40/60 years since
   departure (ages 30/50/70/90 at the default start age), front and back
   three-quarter facings, a static sprite with no walk cycle.
3. **Codex access:** the reference images are public at
   `https://storage.googleapis.com/stapledons-voyage-assets/refs/characters_v1/`,
   with a `SHA256SUMS`. The set is the ten cast_marker_v1 portraits and the
   Medic v2 set.
4. **Art channel:** game-repo issue
   [#93](https://github.com/sunholo-data/stapledons-godot/issues/93) replaces
   issue #1 for art questions and PR links.
5. **Confirmed:**
   - the bucket prefix `areas/`;
   - `isocam_<area>.json`;
   - the character path `assets/characters/<entity_id>/`;
   - bridge bundle PRs based on `main`.
6. **Pan range:** overscan is sized for `[6, 3]` m, and parallax is clamped
   beyond it.
7. **Game-side work is Claude-side:**
   - the `areas/` blob fetch target;
   - clamped parallax;
   - the importer from `assets/characters/` into `data/ai/core`.
