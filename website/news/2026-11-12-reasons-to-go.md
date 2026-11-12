---
title: "Reasons to go"
date: 2026-11-12T12:00:00
authors: [sunholo]
tags: [design, physics]
---

The galaxy map shows thousands of stars and, until now, no reason to pick one. This is the design for how a destination explains itself: the ship looks, the light is old, and the answer is a set of odds, never a promise. None of it is built yet.

{/* truncate */}

## The ship looks whenever it stops

There is no telescope time to manage. Whenever the ship is at rest its instruments survey the sky, and anything they find becomes a mark on the map. What they can find follows from counting photons, not from a range we chose:

- **Planets** show up from far away, by the dip in a star's light or the wobble of the star.
- **Signs of life** are much harder. An Earth-like planet is about ten billion times fainter than its star, so reading its air is a job for nearby stars only.
- **Signs of minds** are seen when they are loud, large or near. A quiet civilisation stays invisible.

## A card that answers three questions

Selecting a mark opens a card. It answers in pictures first.

![A design mock-up of the reason card for one world: a spectrum with four marked lines, the ship's eight resources with two ringed, three cost bars, and two bars of likely states](/img/news/reason-card-mockup-20261112.jpg)

*A design mock-up on invented example data. The star names are real; no reading or cost here comes from the game.*

- **What did we see?** The spectrum itself, with the lines that fired, how sure the ship is, and how long ago the light left.
- **What could it change aboard?** Only light crosses the bubble wall, so no world can give the ship water or metal. A world can teach. A living world might show the gardens a better pigment. A technological one might send a design that sheds heat or saves power. The card lights the ship's resources that this kind of world could improve, and rings the ones the ship is shortest of.
- **What does going cost?** Time, first. Years at home on Earth, and years aboard for the crew. The mass the drive burns comes third.

Under those sit two bars: what is probably there when the light left, and what is probably there by the time the ship arrives. Civilisations end. The second bar is allowed to be worse than the first.

## Oxygen is not life

Some worlds are traps. A dried-out planet around a red dwarf can fill its air with oxygen with no life at all, because the star's light splits water and the hydrogen escapes. The ship's belief has to carry that doubt: oxygen alone leaves the card unsure, and oxygen with methane beside it does not.

## No best choice

The card never recommends. It has no score and no "best" sort. Where a lit resource and a ringed one coincide, the player notices. The crew will have opinions later, and the Archive may offer a reading of its own, which may be wrong.

## On arrival

When the ship arrives, a second card sets three things side by side: what the light said, what was predicted, and what is there. Over a voyage those cards add up to a record of how often old light told the truth.

## Not yet

All of this is a design, approved on 12 November and now a sprint. The photon budgets come first, as checked numbers in the physics spec and then as code in the `sunholo/observe` package. The map marks and the card follow once the simulation can say honestly what the ship would see.
