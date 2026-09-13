---
name: agent-ops-module
description: Build or revise one Agent Operations module deck in agent_ops/ through staged, reviewed outputs (brief → sources → brief refinement → concept list → deck map → HTML → render check → index). Use when Jeff says "build module N", "/agent-ops-module N", or asks to revise, extend, or re-verify an agent_ops deck.
---

# Agent Ops module builder

Argument: the module number (`/agent-ops-module 2`). Optionally a stage name to
jump to (`/agent-ops-module 2 map`, `html`, `revise`). Without a stage, resume
at the first stage whose output does not exist yet.

Paths, all relative to the repo root:

| What | Path |
|---|---|
| Brief (Jeff writes) | `agent_ops/briefs/mN.md` — template: [BRIEF_TEMPLATE.md](BRIEF_TEMPLATE.md) |
| Concept list (stage 3) | `agent_ops/maps/mN_concepts.md` |
| Deck map (stage 4) | `agent_ops/maps/mN_map.md` |
| Deck (stage 5) | `agent_ops/mN.html` — copy [skeleton.html](skeleton.html) |
| Renders (stage 6) | scratchpad, via [render.sh](render.sh) |
| Format contract | [FORMAT.md](FORMAT.md) |
| Source decks and companion pages | `agent_operations/` — **read-only** |

## Rules that carry over

- `.dev/DECK_AUTHORING.md` §2 (pedagogy), §3 (accuracy and sourcing), §6
  (revision passes) apply in full, with one exception: **there is no course-wide
  running scenario.** Each page carries its own simple example instead.
- §4 (960×540 fit) and §5 (BigQuery skeleton) do not apply. FORMAT.md replaces
  them.
- Deck map format follows §7 minus the running-scenario section; the per-page
  spec adds an **Example** field.

## Content rules specific to this course

These exist because the first Agent Operations build was rejected for invented
"agent-specific angles." Do not repeat that.

- **Claim a point is agent-specific only when it rests on one of these
  mechanisms:** non-determinism of model output; correctness that is
  multi-dimensional (trajectory, response, safety, cost); the model as an
  external dependency with quotas, versions, and regions; per-token cost that
  grows with context; the model following instructions found in untrusted text,
  bounded by the agent's permissions; trajectory-level observability that
  carries user content; sessions and memory as managed data; eval sets as
  maintained artifacts. Anything else is generic: say so on the page and still
  give the concrete example.
- **Prompts, tool definitions, model ids, and configuration are code.** They live
  in the repo and go through the pipeline like code. Never claim otherwise.
- **Every takeaway bullet gets one example** naming actor, input, mechanism,
  result. Numbers are computed or tagged illustrative.
- **Vague words are defects:** "outage," "drift," "handles it," "seamlessly,"
  "automatically," trailing "etc." Replace with the mechanism or cut.
- **The brief's Focus section wins.** If the source deck spends slides on
  something the brief marks as a tour or out of scope, the concept list says so
  and budgets accordingly.

## Stages

Stop at every gate marked **Jeff reviews** and wait. Do not start the next
stage's file until he says go.

### 0. Brief check

Read `agent_ops/briefs/mN.md`. If it is missing, say so and stop. If it lacks
delivery minutes, a Focus section, or names sources that cannot be found, list
what is missing and ask. Defaults that need no asking: sources below, page
pacing of about 2.5 minutes per content page <span>(heuristic)</span>.

### 1. Source read

Read all of these before writing anything:

1. The module PDF in `agent_operations/`.
2. The companion page `agent_operations/mN.html`. It carries verified
   corrections and source links from 2026-08/09; re-verify anything it dates.
3. Every artifact, tutorial folder, or repo the brief names. Artifacts: use the
   Artifact tool's `read` action with the URL.
4. `google/adk-python` at the **current release tag** (check PyPI or the repo
   tags; record the tag), and `adk.dev` / `docs.cloud.google.com` for product
   behavior.
5. `~/Desktop/Dev/gcp-demos/ai/adk/` — the folders matching the module's
   topics (M3: `logging/`, `metrics/`, `tracing/`; each has `README.md`,
   `TUTORIAL.md`, `demo_agent/`, `deploy/`, `examples/`). Jeff's demos:
   incomplete and over-detailed, so mine them for the one worked example per
   concept and re-verify anything lifted against the current ADK tag.

Where the brief asks for a best practice no source states, research it
(`adk.dev`, `docs.cloud.google.com`, the ADK repo, and the wider web) and bring
back the candidate practice plus its citation. If nothing authoritative exists,
say that and propose the practice as a recommendation to be labeled illustrative
on the page. Do not settle these in the deck map.

Report in chat: what the source deck gets wrong, what is generic, what is thin,
what the brief asks for that no source covers yet, and each researched best
practice with its citation.

### 2. Brief refinement — **Jeff reviews**

The brief is Jeff's. Propose, never rewrite in place. Having read the sources,
report in chat as a diff of proposed edits:

- Questions the brief asks that the sources answer differently than it assumes.
- Focus items the sources cannot support, and what to narrow them to.
- Scope the brief omits that the sources make obviously load-bearing.
- Best practices researched in stage 1 that should become stated brief positions
  rather than open questions.

Keep it to what changes the deck. If the brief needs no edits, say so in one
line and move on. Jeff edits `agent_ops/briefs/mN.md` himself, or tells you to
apply the proposal; the concept list follows the brief as it stands after that.

### 3. Concept list — **Jeff reviews**

Write `agent_ops/maps/mN_concepts.md`:

```
# Module N — concept list
Delivery minutes (non-lab): <from brief> → page budget ≈ <minutes / 2.5>

| # | Concept | Agent-specific? | Example (actor / input / mechanism / result) | Verify against | Disposition | Pages |
|---|---|---|---|---|---|---|
| 1 | … | yes: <mechanism from the list> / generic | … | doc URL, repo path, or "run it" | focus / tour / notes only / out | 2 |

Total pages: <sum> (+ opener, objectives, dividers, recap, consequences, references ≈ 7)

## Order and why
One paragraph: the spine, and why each concept only needs what came before it.

## Cut from the source, and why
Bulleted.

## Open questions for Jeff
Bulleted, only if any.
```

8–15 concepts. If the page total exceeds the budget, say which rows you would
cut first rather than silently shrinking pages.

### 4. Deck map — **Jeff reviews**

Write `agent_ops/maps/mN_map.md` per DECK_AUTHORING §7 (header, organizing
frame, what changed vs. the sources and why, diagram convention, then
`## Page N — Title` blocks). Each page block: type (from FORMAT.md), lede,
body, code (if any, ≤ 20 lines), **Diagram** spec precise enough to draw
without invention, **Example** (actor / input / mechanism / result), takeaway,
sources, speaker notes.

Verify every load-bearing claim during this stage, not after. Put the citation
in the page block.

### 5. HTML

Copy `skeleton.html` to `agent_ops/mN.html`. Keep its `<style>`, notes panel,
bar, and `<script>` verbatim. Replace the demo pages with the map's pages. Rules
in FORMAT.md. Every `section.page` is followed by its `details.notes`. Set the
`<title>` and the bar's module name.

### 6. Render check

```
.Codex/skills/agent-ops-module/render.sh agent_ops/mN.html <scratchpad>/mN
.Codex/skills/agent-ops-module/render.sh agent_ops/mN.html <scratchpad>/mN-tall 2000 "<tall page numbers>"
```

Read every PNG with the Read tool. Check: no horizontal clipping (tables and
code scroll inside their own box, never the page); SVG `width`/`height` equal
the viewBox and labels are legible; nothing smaller than 15.5px except
uppercase labels; the notes panel shows the right notes for the page; tall
pages scroll rather than lose content; dividers center. Fix, re-render, then
report done with the page numbers you looked at.

### 7. Index

First module: create `agent_ops/index.html` (a one-page deck from the skeleton
listing the modules as `ol.mods`-style links) and add an `agent_ops/` card to
the root `index.html`. Later modules: add the row.

### 8. Revisions

Jeff annotates by page number. Apply on the face and in the notes, sweep the
deck for the same problem, renumber `<!-- ==== N. TITLE ==== -->` banners if
pages are inserted, re-render the touched pages, and do not drop content
silently.
