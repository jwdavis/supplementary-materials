# supplementary-materials

Course decks (Pub/Sub, Dataflow, BigQuery, …). Each deck is a single
self-contained HTML file: 960×540 `<section class="slide">` elements with
per-slide speaker notes in sibling `<details class="notes">` blocks.

## Look at slides before calling a deck done

Deck HTML cannot be verified by reading it. Overflow, clipped diagram labels, and
text past the canvas are invisible in the source and obvious in a render. Before
reporting any deck edit complete, render the slides you touched to PNG and read
them with the Read tool.

Render with headless Chrome — work out the invocation yourself (screenshot each
960×540 `.slide` element, or paginate to PDF and convert). Render generously:
per-call cost is fixed, so capturing a range of slides costs no more than
capturing one.

Full authoring conventions — process stages, pedagogy, slide craft, the HTML
contract — are in [DECK_AUTHORING.md](.dev/DECK_AUTHORING.md). Read it before
writing or revising a deck.
