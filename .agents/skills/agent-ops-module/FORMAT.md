# agent_ops deck format

Replaces DECK_AUTHORING.md §4 and §5 for this course. The reference
implementation is [skeleton.html](skeleton.html); look at it before reading this.

## Shape

- One self-contained HTML file per module. No external CSS, JS, fonts, or images.
- Paged like a deck: one `section.page` visible at a time, prev/next, arrow
  keys, Home/End, `#sNN` deep links, `N` toggles the notes panel, `F`
  fullscreen. **A page scrolls when it is taller than the viewport.** There is
  no fixed slide height and no auto-fit.
- Page card is 1120px wide max on a gray ground. "Proprietary + Confidential"
  and the Google Cloud mark are injected by the script; do not write them.
- Page numbers are injected into every non-divider `h1`; do not write them.
  Precede each page with `<!-- ==== N. TITLE ==== -->` for review by number.

## Type scale (do not shrink)

| Element | Size |
|---|---|
| body, `.lede`, `.takeaway` | 20px |
| `h1` | 32px |
| `h2` / `h3` | 22px / 20px |
| `.note`, `.ex`, `.numrow .body` | 18.5px |
| `table.cmp` | 17.5px |
| `.cell p`, `.small` | 16–16.5px |
| `pre.code`, `pre.term`, `figcaption`, `.src` | 15–15.5px |
| uppercase labels (`.tag`, `.kk`, `.codelabel`, `th`) | 12–12.5px |
| SVG text | ≥ 13px labels, ≥ 15px box titles |

Inline `style="font-size:…"` to go smaller is not allowed. If it does not fit,
the page scrolls, or it is two pages.

## Page types

| Type | Build from | Use |
|---|---|---|
| Module opener | `.page.divider` with shapes, module number, `dsub`, `agenda` | Page 1 |
| Objectives | `.numrows` | Page 2 |
| Section divider | `.page.divider` with section number, `.kicker`, `dsub` | One per section |
| Concept | `.lede` + `.checks` (3–5 rows) + `.ex` + optional `.note` + `.takeaway` + `.src` | The workhorse |
| Mechanism | `.lede` + full-width `figure > svg` tracing literal values + `.ex` or `.takeaway` | Wherever a mechanism is explained |
| Code | `.lede` + `.codelabel` + one `pre.code` or `pre.term` (≤ 20 lines) + `.note` | Anything the student will type |
| Comparison | `.lede` + `table.cmp` with `tr.hl` for the recommended row; `.grid` cards for parallel non-comparisons | "Three ways to X" |
| Recap | `.checks` with green dots | End of each section |
| Consequences | `table.cmp`: You observed / Because / So you… | End of deck |
| References | list + re-verify note | Last page |

A page may combine a concept and a short code block, or a mechanism figure and
a comparison table, when one needs the other. Two ideas that do not need each
other are two pages.

## Components

| Class | Meaning |
|---|---|
| `.lede` | Opening sentence: a situation or a decision, never a definition |
| `.checks` / `.checkrow` + `.cdot` (`.red`, `.green`, `.gray`) | Sparse bullets; dot color = blue concept, red problem, green recommended, gray inert |
| `.numrows` / `.numrow` (`.good`, `.bad`, `.plain`) | Ordered steps or agendas |
| `.grid.c2/.c3/.c4` + `.cell` (`.green .red .yellow .gray`) | Parallel cards; top rule carries the color semantic |
| `table.cmp` (`tr.hl`, `tr.bad`, `td.m`, `.yes`, `.no`) inside `.tscroll` | Comparison and decision tables |
| `.ex` with `.lbl` Actor / Input / Mechanism / Result | The example; one per takeaway |
| `.note` (yellow caveat), `.note.blue` (rule), `.note.red` (correction / problem), `.note.green` (recommended), `.note.gray` (aside) with `.kk` label | Callouts |
| `.takeaway` | The one sentence to remember; on every concept and mechanism page |
| `.tag.limit / .guide / .heur / .illus / .model` | Epistemic status on every number and rule on the face |
| `pre.code` (`.kw .st .cm .fn .chg`) / `pre.term` (`.flag .lbl`) with `.codelabel` (`.good`, `.bad`) | Code; label overrides and versions |
| `figure > svg` + `figcaption` | Diagrams |
| `.cols` (`.c64`, `.c46`) | Two columns |
| `.src` | Source links with verification date, bottom of page |

## Color semantics (same as every deck in the repo)

| | |
|---|---|
| blue | the active concept, the thing being taught, the rule |
| green | the good outcome, the recommended pattern, the example |
| red | the problem, the anti-pattern, the correction |
| yellow | caution, caveat, "it depends" |
| gray | inert scaffolding, skipped data, captions |

## SVG rules

- `viewBox` plus explicit `width`/`height` equal to the viewBox. Full-width
  figures ≤ 1000 wide; half-column ≤ 480. Never scale a diagram down to fit;
  change the viewBox and reposition.
- Colors via the CSS variables (`fill="var(--fill-blue)"`) so dark mode holds.
- Literal values in `font-family:var(--mono)`; labels in `var(--sans)`.
- Arrowheads via a `<marker>` in `<defs>` with a per-page unique id.
- Estimate label width as chars × font-size × 0.52 and keep it inside the
  viewBox; `text-anchor="middle"` spans x ± w/2.
- Caption inside the figure when the diagram is a mental model rather than the
  implementation.

## Speaker notes contract

```html
<section class="page"> … </section>
<details class="notes" data-title="Page title">
  <summary>Speaker notes &mdash; Page title</summary>
  <div class="n-body"><ul><li>…</li></ul></div>
</details>
```

Every page has one, immediately after it, both direct children of `#deck`.
The script pairs them by index and warns in the console on a count mismatch.
Notes carry: why the page exists, the delivery beat, citations for each
load-bearing claim, gotchas and variants kept off the face, and the hand-off.
2–4 bullets is typical. Print mode emits each page followed by its notes.

## HTML conventions

- Entities for typography: `&mdash; &rsquo; &ldquo; &rdquo; &times; &asymp; &rarr; &hellip;`.
- Em dashes are fine in decks.
- No `id` on pages; the script assigns `sNN` from position.
- The `<title>` is `MN — Module title`; the bar's `.name` reads
  `Agent Operations · Module N · Title` and links to `index.html`.
