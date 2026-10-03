# News: the public changelog

`website/news/` is the site's News section (Docusaurus blog plugin), served at
`/stapledons-godot/news/` with RSS (`news/rss.xml`) and Atom (`news/atom.xml`) feeds. This README is
excluded from the build.

## The release convention

- **Every versioned GitHub release gets a News post.** Its front matter carries the tag and links
  the release:

  ```yaml
  ---
  title: "v0.4.0: …"
  date: 2026-10-10
  authors: [sunholo]
  tags: [release, journey]
  release_tag: "v0.4.0-m4"
  release_url: "https://github.com/sunholo-data/stapledons-godot/releases/tag/v0.4.0-m4"
  ---
  ```

  and the body ends with a **Release:** link. A release covering several tags (v0.3.0–v0.3.2) can
  share one post that links each.
- **Progress posts** between releases (tag `progress`) are fine for merged milestones worth showing.
- **Draft from the record, then edit by hand.** `make news-draft TAG=vX` runs
  `website/scripts/news-draft.mjs`: it reads the release (if it exists) with `gh release view`
  and every fragment in `changelogs/unreleased/`, and writes `website/news/<date>-<tag>.md` with
  `draft: true`, TODO sections and the raw notes in an MDX comment. A person (or Claude) cuts it
  down, adds a real capture, deletes the raw notes and the `draft` line. Nothing publishes
  automatically: the post appears on the next `make site-deploy`.

## Writing a post

- Short: a one- or two-sentence summary, `{/* truncate */}`, three to six bullets of **What's
  new** (merged work only, each with its PR link), and a **Not yet** section for what is in
  progress or planned. Keep done separate from planned, as on the rest of the site.
- Use real captures: images in `static/img/news/` (resized, under 1 MB), or clips through
  `<ClipFigure name="…" />` in an `.mdx` post (`import {ClipFigure} from '@site/src/components/Clip';`).
  Big files go to the bucket (`tools/site_media.sh asset FILE`).
- Tags must exist in `tags.yml` and authors in `authors.yml` (the build fails otherwise).
- Numbers come from check values, captures or PRs, never from memory.

## Spoiler policy

The site shows mechanics, physics, art direction, visual and audio style, UI, the real science,
and milestones in non-narrative terms. It **never** shows:

- endings or the long-horizon endgame;
- plot beats, twists, or what happens to characters or civilisations;
- Archive or codex lore beyond the physics explainers;
- the contents of end-of-game or legacy screens;
- scripted events, news-from-home storylines, or what is found at destinations beyond the real
  astronomy;
- crew fates and arcs, or crew relationships beyond their roles;
- anything the design docs mark as story, narrative or secret.

If unsure, leave it out and ask Mark. Captions of crew art name roles only.
