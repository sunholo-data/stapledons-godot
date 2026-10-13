---
title: "A thousand aboard"
date: 2026-10-13T22:00:00
authors: [sunholo]
tags: [progress]
---

The bubble ship now carries a population. Besides the featured crew, about a thousand people live aboard, and the simulation keeps track of them: their moods, their trust in the captain, their ages, the children born and the people who die. Whether children are born at all is a decision for the captain, and some people will not like it.

{/* truncate */}

![People aboard over a century under three birth policies: hold settles near 1,600, encourage passes 4,500, restrict falls to 240](https://storage.googleapis.com/stapledons-voyage-assets/site/f60d332b73fbcebf648e43015dc052eba7a1325b31136d4b6bd93724d23b556b.svg)

*The same thousand founders over a hundred years under each birth policy, from the crew lab's simulation runs (featured crew idle, no events). This is a chart of simulation output, not a capture from the game.*

## What's new

- **About a thousand people aboard, growing to about fifteen hundred.** A 100 m bubble has room for them: roughly 370,000 m² of floor over fifteen levels, so about 370 m² each at the start. The mass budget, the household power and the gardens were rescaled to match.
- **People as groups.** Ten departments and the children are each simulated as one group, which records how many people are content, uneasy, strained or breaking, how much they trust the captain, and how old they are. A group costs the same whether it holds a hundred people or a hundred thousand: a ten-year skip took 20.1 s with 1,000 people and 20.4 s with 100,000.
- **Groups have voices.** A featured crew member can speak for a department (half of the ten have one so far), so what happens to them colours how their people feel. When a featured crew member is lost, someone steps up from their department to fill the role.
- **Births are the captain's decision.** Encourage, hold or restrict. Holding takes the founders to about 1,600 in a century. Encouraging passes 4,500. Restricting shrinks the ship. Children join the departments at 18, and once a department is a quarter ship-born, the ship-born become a group of their own.
- **And it causes tension.** Restricting births costs the captain trust, most among people of child-bearing age and the warmest, most family-minded departments, and it keeps costing for as long as the policy lasts. Encouraging births while the gardens or water are short costs trust with the most conscientious. When a group's pressure rises far enough, a skip through time stops and asks the captain to decide.
- **Checked before it was trusted.** Eighteen claims, written before the runs, hold. Examples: nobody is born while the garden beds are dark, a divided department raises its voice and a uniformly uneasy one does not, and holding lands near the planned headcount after a century. Two claims failed on the way and changed the model. An independent review found three more bugs, now fixed. ([ailang-packages#139](https://github.com/sunholo-data/ailang-packages/pull/139))

## Not yet

- **In the game.** All of this runs in the simulation and the crew lab so far. Showing it in the game, with a society strip on the Crew page and the birth policy at the Voyage console, is the next step of the crew integration.
- **Who gets to have children.** Under a restriction, which households or departments may have children will be its own decision, with its own grievances.
- **Generations that differ.** The ship-born are not yet different from the founders in how they feel or what moves them.
- **Worlds.** The same machinery is meant to scale to a planet's billions, so the civilisations the ship meets can run their own versions of it.
