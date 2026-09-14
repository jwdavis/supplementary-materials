# Agent Operations: module-by-module rebuild plan

Status: **revised 2026-09-12 with Jeff's decisions**. Nothing built yet.

## What we are building

New standalone teaching decks for the six Agent Operations modules, replacing
(not annotating) the source PDFs. Distilled to the concepts that matter, ordered
to build, every claim carrying a concrete example. Everything lands in a new
`agent_ops/` directory; `agent_operations/` (PDFs + companion pages) is left
untouched and used read-only as a source.

| Property | Decision | Source of the decision |
|---|---|---|
| Location | `agent_ops/` (new). `agent_ops/mN.html`, `agent_ops/index.html`, `agent_ops/briefs/`, `agent_ops/maps/`, `agent_ops/CLAUDE.md` | Jeff, 2026-09-12 |
| Page shape | Paged like a deck (prev/next, arrow keys, `#sNN` links) but **each page scrolls** when the content is taller than the viewport | Jeff (m6.html#s08) |
| Look | MAS-ADKAE visual grammar: white card on gray, "Proprietary + Confidential", Google Cloud mark, divider slide with the shape cluster + module number as the opening page | Jeff (MAS-ADKAE/m1.html#2) |
| Type size | agent_operations companion size: 20px body, 32px h1, 15.5px code, 17.5px tables. Not the MAS 13–16px | Jeff (m6.html#s06) |
| Components | The companion CSS already merges both: check-rows, numrows, card grid, `cmp` tables, colored notes, example card, blue takeaway band, inline SVG | agent_operations/m6.html |
| Speaker notes | Same mechanism as the BigQuery skeleton: `details.notes` sibling after every page, `N` toggles a notes panel mirroring the active page, print mode emits each page followed by its notes. Notes carry why-this-page, delivery beat, citations, gotchas | Jeff, 2026-09-12 |
| Examples | **No course-wide running scenario.** Simple per-page examples in the m6 companion style: each names actor, input, mechanism, result; numbers computed or labeled illustrative | Jeff, 2026-09-12 |
| Page budget | Brief states the module's delivery minutes for non-lab content; the concept list proposes a page count from it | Jeff, 2026-09-12 |
| Pedagogy and accuracy | DECK_AUTHORING.md §2 (pedagogy, minus the running-scenario rule), §3 (accuracy and sourcing), §6 (revision), §7 (deck map) apply. §4 (960×540 fit rules) and §5 (BigQuery skeleton) do **not** | .dev/DECK_AUTHORING.md |
| Agent-specific claims | Only from the defensible list; otherwise say "generic" and give the example anyway | memory: agent-ops-content-standard |

## How to operationalize it (the question you asked)

Three layers, matching what already works for the other courses (DECK_AUTHORING.md
= how, `<course>/prompt.md` = what). None of them is a one-off prompt.

| Layer | File | Holds | Why this layer |
|---|---|---|---|
| **Skill** (the procedure) | `.claude/skills/agent-ops-module/SKILL.md` + bundled files | The staged workflow for "build module N": source read → concept list → deck map → HTML → render check → index update, with a review gate after each stage. Takes the module number as its argument | It is a repeatable multi-stage process with gates. A skill is invoked on demand (`/agent-ops-module 3`), can carry reference files, and is checked in |
| **Format contract** | `.claude/skills/agent-ops-module/skeleton.html` and `FORMAT.md` (bundled in the skill) | The exact HTML/CSS/JS skeleton to copy verbatim: companion paging + scroll + chrome + type scale, MAS divider opener, BigQuery notes panel ported in. Plus the page types (divider, objectives, concept, mechanism, comparison, code, recap, consequences, references) | The BigQuery skeleton in DECK_AUTHORING §5 does not fit; this replaces it for this course only |
| **Per-module brief** | `agent_ops/briefs/mN.md` | Your input per module: the Module 2 section of thoughts.md is the model. Fixed headings so the skill can rely on them | Only the part that changes per module lives here. Modules 3–6 mean writing one of these each, nothing else |
| **Directory CLAUDE.md** | `agent_ops/CLAUDE.md` (~10 lines) | "Decks here follow the agent-ops-module skill. `../agent_operations/` is read-only source material. Render before reporting done." | Auto-loads on any later edit in the folder, including revision passes where nobody invokes the skill |

So: not a single new prompt, not CLAUDE.md alone, and not a skill alone. The
skill is the workflow, the brief is the per-module input, the CLAUDE.md is the
safety net. Your prompt for module 3 becomes `/agent-ops-module 3` after writing
`briefs/m3.md`.

Background and Objective from thoughts.md move into the skill; the Module 2
section becomes `briefs/m2.md`. thoughts.md then goes away (it sits in
`_includes/`, a Jekyll folder, which is the wrong home).

## Skill stages

The concept-list stage is the addition to the DECK_AUTHORING process. It is where
"too wide" gets fixed, and it is cheap to argue about.

| Stage | Output | Gate |
|---|---|---|
| 0. Brief check | Read `briefs/mN.md`; say what is missing (scenario, budget, sources) before starting | Jeff fills gaps or says "use defaults" |
| 1. Source read | Read the PDF, the companion page (`agent_operations/mN.html`, which already carries verified corrections and source links), the named tutorials/artifacts, and the ADK source at the pinned tag. Report what is weak, wrong, or generic | Report only |
| 2. Concept list | `agent_ops/maps/mN_concepts.md`: 8–15 concepts. Each row: concept, agent-specific or generic, the one example, source to verify against, in/out, and estimated pages. Totals against the brief's minutes | **Jeff reviews.** This is the "distill" step |
| 3. Deck map | `agent_ops/maps/mN_map.md` per DECK_AUTHORING §7 (minus the running-scenario section), page by page, with the example and the speaker notes per page | **Jeff reviews.** No HTML before approval |
| 4. HTML | `agent_ops/mN.html` from the skeleton, `details.notes` after every page | Jeff reviews the render |
| 5. Render check | Headless Chrome screenshots of every page at 1280×900, read as PNG. Check: nothing clipped horizontally, SVG labels legible, code blocks ≤ 15.5px still readable, tall pages scroll rather than overflow, notes pair with the right page | Fix before handing over |
| 6. Index | Add to `agent_ops/index.html`; add `agent_ops/` to the root index on the first module | — |
| 7. Revisions | By page number, face and notes together, sweep the deck for the same problem | Repeat |

## Brief template (`agent_ops/briefs/mN.md`)

```
# Module N — <title>
## Delivery minutes (non-lab)
## Focus: what is new to <topic> because it is an agent
## Tour: Google Cloud services attendees may not know (keep small)
## Key sections, in order (with your thoughts per section, as in thoughts.md M2)
## Related topics (concise, secondary)
## Leaves out, and why
## Sources beyond the defaults (tutorials, artifacts, repos)
```

Defaults the skill applies unless the brief overrides: sources = PDF + companion
page + adk-python at the current release tag + docs.cloud.google.com + adk.dev.

## Sources available today

| Source | Trust | Use |
|---|---|---|
| `agent_operations/M*.pdf` | Raw material; often generic or wrong | Topic inventory only |
| `agent_operations/m1–m6.html` companions | Verified against google-adk 2.7.1 on 2026-08-25/09-09, with doc links | Corrections and sources carry forward; re-verify the ADK version at build time |
| `~/Desktop/Dev/gcp-demos/ai/adk/{logging,metrics,tracing}` | Incomplete, too detailed | Mine for the one worked example per concept in M3 |
| Claude artifacts: 14 with prefix ADK / Agents / GEAP (Deploy Agent Engine, Context Caching, otel_to_cloud, Eval Scenarios, Test vs Evalset, Gen AI Evaluation Service, WIF, Agent Identity, Model Armor, Security Threats, Logging Field Guide, Custom Metrics, Dynamic Model Routing, Event Loop) | Your prior work; check dates | Map per module in the brief; the skill reads them by URL |
| adk-python at the current tag, agents-cli | Authoritative for API shape and flags | Every code page |
| docs.cloud.google.com, adk.dev | Authoritative for limits, product behavior | Cite in notes |

Artifact → module mapping for the briefs: M2 = Deploy Agent Engine, otel_to_cloud;
M3 = Logging Field Guide, Custom Metrics, otel_to_cloud, Event Loop; M4 = Eval
Scenarios, Test vs Evalset, Gen AI Evaluation Service; M5 = WIF, Agent Identity,
Model Armor, Security Threats; M6 = Context Caching, Dynamic Model Routing.

## Decisions (resolved 2026-09-12)

| # | Question | Decision |
|---|---|---|
| 1 | Where do new decks live | New `agent_ops/` directory. `agent_operations/` untouched |
| 2 | Speaker notes | Yes, BigQuery-skeleton mechanism ported into the new skeleton |
| 3 | Running scenario | None. Per-page simple examples, m6 companion style |
| 4 | Page budget | Brief states non-lab delivery minutes; concept list proposes pages |
| 5 | Order of work | M2, M3, M4, M5, M6, then M1 |

## Execution checklist

- [x] Jeff reviews decisions; plan revised
- [x] Build the skill: SKILL.md, FORMAT.md, skeleton.html (companion chrome + MAS divider + BigQuery notes panel), render.sh, BRIEF_TEMPLATE.md (concept-list format lives in SKILL.md stage 2)
- [x] `agent_ops/CLAUDE.md`
- [x] `agent_ops/briefs/m2.md` from the thoughts.md M2 section; thoughts.md removed from `_includes/`
- [x] Jeff fills in delivery minutes in `agent_ops/briefs/m2.md` (35 min, 2026-09-12)
- [x] Module 2: stages 0–7 — `agent_ops/m2.html`, 22 pages, rendered and read
- [ ] Jeff reviews M2 by page number
- [ ] Retro on the skill after M2, edit it, then M3
