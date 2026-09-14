# Agent Operations supplementary materials — brief

Instructor companion pages for a six-module class on Agent Development Kit (ADK)
agent operations on Google Cloud. The source decks (PDFs in this folder) have
speaker notes and slide content that are insufficient for making the key points;
these pages give the instructor examples, restatements, corrections, and
supplementary material for a great delivery.

## Objective

For each module, one self-contained HTML file (`m1.html` … `m6.html`) that
pages through the deck **one slide at a time** (prev/next buttons, arrow keys,
`#sNN` deep links). Each page holds the supplementary content for that slide
and scrolls vertically when it is taller than the viewport. Type is large
(20px body). Visual grammar follows `MAS-ADKAE`: the Google palette used
semantically (blue = key point, green = example / recommended, red =
correction / problem, yellow = caveat, gray = scaffolding), check-rows, card
grids, `cmp` tables, colored callouts, a blue takeaway band, and an inline SVG
diagram wherever a page explains a mechanism.

## Guiding principles

1. Highlight content that is **not actionable** so the instructor can skip it.
2. Highlight content that is **vague or wishy-washy** and either drop it or make
   it concrete.
3. Identify content that is **factually inaccurate or out of date** and propose a
   corrected alternative.
4. Provide an **example scenario and example solution** for every key assertion.
   Students learn from illustrations.
5. Keep the instructor-facing content **concise and scannable**; use diagrams,
   infographics, and illustrations.
6. Where a point is **generic**, target the discussion on what is **unique about
   agents** (agent development and agent operations).

## How the pages encode this

- Every slide has a page: number, deck title, a one-line italic recap of the
  slide's claim, then the supplementary content in short headed blocks (Key
  point, Example, Definition, Code, Sources). Divider and Q&A slides carry only
  a "Skip" line so numbering matches the deck.
- A small badge next to the title marks a slide only when needed: `Skip`,
  `Correction` (red, with the fix in a red callout), or `Add`.
- Agent-specific claims are limited to a short list of defensible mechanisms
  (non-determinism; multi-dimensional correctness; the model as an external
  dependency with versions, shared throughput, regions; per-token cost growing
  with context; the model following instructions in untrusted text, bounded by
  the agent's permissions; trajectory-level observability that carries user
  text; session and memory as managed data; the eval set as a maintained
  artifact). Prompts, tool definitions, model ids, and configuration are code
  and are treated as code. Where a slide's point is generic, the page says so.
- Every example names the actor, the input, the mechanism, and the observable
  result; numbers are computed or labeled illustrative.
- `index.html` lists the modules, the "what is different for agents" table
  (each row linking to the page with the example), and the product-name
  changes.

## Baseline and verification

- Current baseline: **ADK 2.x** and current Google Cloud product names, with the
  deck's 1.x form kept alongside where they differ.
- API facts verified against **google-adk 2.7.1** (source on GitHub, tag `v2.7.1`),
  `adk.dev`, and current `docs.cloud.google.com` pages, as of **2026-08-25**.
- A few pricing figures are labeled "illustrative" / "verify" where a primary
  source did not render at build time; re-verify before delivery.

## Build

The pages share one stylesheet + JS. During authoring they were assembled from a
head/foot template plus per-page body fragments; the shipped files are fully
self-contained (inline CSS/JS/SVG, no CDN), light + dark theme, print-friendly.
Regenerate by editing the body fragments and re-running the build, or edit the
self-contained HTML directly.
