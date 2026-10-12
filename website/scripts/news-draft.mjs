#!/usr/bin/env node
// make news-draft TAG=vX: draft a News post for a GitHub release, for a person
// (or Claude) to edit. It never publishes anything: it writes one Markdown file
// under website/news/ with `draft: true` and prints its path.
//
//   node website/scripts/news-draft.mjs --tag v0.4.0-m4 [--date 2026-10-10] [--force]
//
// Inputs: the release (title, date, notes) from `gh release view TAG`, if the
// release exists yet, and every fragment in changelogs/unreleased/*.md. The draft
// carries `release_tag` and `release_url` in its front matter, TODO sections,
// and the fragments as raw notes (in an MDX comment) to cut down. Read
// website/news/README.md, including the spoiler policy, before publishing.
import {execFileSync} from 'node:child_process';
import {existsSync, readdirSync, readFileSync, writeFileSync} from 'node:fs';
import {dirname, join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '..', '..');
const newsDir = join(repo, 'website', 'news');
const REPO = 'sunholo-data/stapledons-godot';

const args = process.argv.slice(2);
const opt = (name) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : undefined;
};
const tag = opt('tag');
if (!tag) {
  console.error('usage: news-draft.mjs --tag vX [--date YYYY-MM-DD] [--force]');
  process.exit(2);
}

let release = null;
try {
  const out = execFileSync('gh', ['release', 'view', tag, '-R', REPO, '--json', 'name,body,publishedAt,url'], {
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'ignore'],
  });
  release = JSON.parse(out);
} catch {
  console.error(`news-draft: no GitHub release ${tag} yet (or gh is not logged in); drafting from the changelog fragments only`);
}

const date = opt('date') || (release?.publishedAt || new Date().toISOString()).slice(0, 10);
const slug = tag.toLowerCase().replace(/[^a-z0-9-]+/g, '-');
const file = join(newsDir, `${date}-${slug}.md`);
if (existsSync(file) && !args.includes('--force')) {
  console.error(`news-draft: ${file} exists (use --force to overwrite)`);
  process.exit(1);
}

const fragDir = join(repo, 'changelogs', 'unreleased');
const fragments = existsSync(fragDir)
  ? readdirSync(fragDir)
      .filter((f) => f.endsWith('.md'))
      .sort()
      .map((f) => ({f, text: readFileSync(join(fragDir, f), 'utf8').trim()}))
  : [];

const title = release?.name || `Release ${tag}`;
const url = release?.url || `https://github.com/${REPO}/releases/tag/${tag}`;
const q = (s) => JSON.stringify(s);
// Raw notes sit inside an MDX comment; stop them from closing it early.
const raw = (s) => s.replace(/\*\//g, '* /');

const body = `---
title: ${q(title)}
date: ${date}
authors: [sunholo]
tags: [release]
release_tag: ${q(tag)}
release_url: ${q(url)}
draft: true
---

TODO: one or two sentences a player would care about. What can you see or do now?

{/* truncate */}

## What's new

TODO: three to six bullets, each a thing that now runs, with its PR link. Only merged work.

## Not yet

TODO: what is still in progress or planned, in non-narrative terms. No spoilers
(see website/news/README.md).

**Release:** [${tag}](${url})

{/*
Raw material: delete before publishing.

## Release notes (${tag})

${raw((release?.body || '(no release yet)').trim())}

## changelogs/unreleased fragments

${raw(fragments.map(({f, text}) => `### ${f}\n\n${text}`).join('\n\n') || '(none)')}
*/}
`;
writeFileSync(file, body);
console.log(`news-draft: wrote ${file} (draft: true; edit it, then delete the draft line to publish)`);
