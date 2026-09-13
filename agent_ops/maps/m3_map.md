# Module 3 deck map — Observability for Debugging and Improvement

Source: `agent_operations/M3-Observability for Debugging and Improvement.pdf` and the
companion `agent_operations/m3.html`. Brief: `agent_ops/briefs/m3.md`. Concept list:
`agent_ops/maps/m3_concepts.md` (approved 2026-09-12).

Baseline: google-adk **2.9.0** (tag `v2.9.0`), google-cloud-aiplatform **2.1.0**,
google-agents-cli **1.5.0**. Everything the companion page or Jeff's tutorials date to
2.7.1/2.8.0 is re-verified here against 2.9.0.

**33 pages: 23 content + opener, objectives, 3 dividers, 3 recaps, consequences, references.**
≈58 min against a 50-min budget. Jeff: a couple over is fine; page 31 (the tour) is the
live-skip candidate.

One page fewer than the concept list projected: concepts 3 and 7 each budgeted 2 pages, and
concept 3's two became pages 6 and 7 while concept 7's second page proved unnecessary once the
sink dropped to one line (page 11).

Follows `FORMAT.md` and DECK_AUTHORING §2, §3, §6. No course-wide running scenario —
each page carries its own example, per the skill.

## Organizing frame

**What an agent emits → how you turn it on where it runs → what you ask of it.**

| Section | Question | Pages |
|---|---|---|
| 1. Logs | What comes out of the process, and what do I add? | 3–12 |
| 2. Traces | Where did the turn spend its time, and who turns that on? | 13–24 |
| 3. Metrics | What do I chart and alert on? | 25–30 |

Pages 31–33 close the deck: the tour, consequences, references.

The spine holds because each section needs the one before it: you cannot correlate logs
to spans (page 23) before you have both; you cannot read the metric catalog (page 26)
before you know the `gen_ai.*` vocabulary the spans introduced.

## What changed vs. the sources, and why

| Source says | Deck says | Why |
|---|---|---|
| Slide 8: ADK logs structured lifecycle events (`agent.started`, `llm.request`, …) | Those event names **do not exist**. ADK logs plain text lines; the real structure is span names | Grepped `_instrumentation.py` and the whole `google/adk` tree on 2.9.0: zero occurrences. Jeff's logging tutorial captures the actual lines |
| Slides 11, 27: "Cloud Trace gives you tracing" | Instrumentation, recording and export are **three** states; nothing is recorded until a `TracerProvider` is installed | Ran a real turn with no provider: every span is a `NonRecordingSpan`, trace id all zeros (`scratchpad/notrace.py`) |
| Deck's span names "thought / action" | `invocation`/`invoke_workflow` → `invoke_agent` → `call_llm` → `generate_content`, `execute_tool` | The live Agent Runtime capture and `adk web` both show these; the deck's names appear nowhere |
| Slide 25: the OTel variable controls prompt capture, content redacted by default | **Two** knobs with **opposite** defaults; "content off" needs both | Eight-run matrix on 2.9.0 against real Gemini calls (`scratchpad/knobs.py`) |
| Slide 29: Agent Runtime "automatic", Cloud Run "flag" | Both need a switch; they differ in *who writes it* | `cli_deploy.py`, and confirmed on a live engine 2026-09-12 |
| Slide 30's `get_fast_api_app(...)` call | Raises `TypeError`; `web=` is required | Reproduced |
| Slide 32: callbacks "run in request thread", OTel "non-blocking async" | Wrong in both directions. The real split: plugins/callbacks can **change behavior**, OpenTelemetry only **records** | Callbacks may be async; on Agent Runtime OTel export is request-driven, not background |
| Nothing on metric name stability | Two families: 7 stable `gen_ai.*`, 16 `adk.experimental.*` | Re-read `_metrics.py` on 2.9.0. The experimental set is ungated and always emitted |

**Added, with no source in the deck:** the four log streams (page 3), structured logging as
the convergence point (page 9), latency decomposed across three grains (page 27), and task
outcome as a fact no framework metric carries (page 28).

**Plain-language rewrite, 2026-09-13.** Pages 21, 22, 26, 27, 28 and 29 were rewritten after
review for shorthand and unexplained terms. Changes of substance, beyond wording:

- Page 22, row 2: `adk deploy cloud_run` accepts `--env NAME=VALUE` (passed to
  `gcloud run deploy --update-env-vars`); `gke` has no env flag. Precedence at startup is the
  normal one: container environment, then `.env` for anything unset, then the default. ADK's
  `load_dotenv(override=True)` is followed by restoring the pre-existing environment
  (`envs.py:76-82`), so the file never beats the environment. (A first draft said the reverse;
  Jeff caught it 2026-09-13.) A `.gitignore` that lists `.env` keeps it out of the image.
- Page 26: added how metrics export is turned on, and two verified `increase()` queries for total
  tokens and average tokens per model call (48h window: 77,243 input tokens, 132 calls, 585/call).
- Page 27: chart is now a column chart, not horizontal bars, so it cannot be read as a span
  waterfall.
- Page 28: the gauge figure is gone; a three-row table (question / measured how / value) plus one
  plain bullet per row. Example walks turn-error alert, tool-error alert, outcome alert.
- Page 29: retitled and reframed for a learner: why input grows, why output does not, why it
  matters, how to see it.

## Diagram convention

Seven figures, one visual grammar. Boxes are processes or stores; rounded boxes are signals
in flight; a **solid** arrow is data moving, a **dashed** arrow is configuration reaching a
component. Literal identifiers (`uvicorn.access`, `ADK_CAPTURE_…`) are in `var(--mono)`;
prose labels in `var(--sans)`. Blue = the thing being taught, gray = inert or not-installed,
red = the failure being diagnosed, green = the recommended path. Every figure's arrowhead
marker id is page-unique (`ar14`, `ar17`, …). No figure exceeds 1000 × 420.

---

# Section 1 — Logs (pages 3–12)

## Page 1 — Module opener

**Type:** Module opener (`.page.divider`).

**Module number:** 03. **Title:** Observability for Debugging and Improvement.
**dsub:** Logs, traces and metrics from an agent that decides what to do next.

**Agenda (`.agenda`):**
1. Logs — the four streams, and the one you write
2. Traces — the shape of a turn, and who turns it on
3. Metrics — what to chart, and what a chart cannot tell you

**Notes:** Frame the module against Module 2: that one shipped the agent, this one asks what
it tells you once it is running. The through-line is that an agent's output is a *decision
sequence*, so the observability question is "what did it decide and why," not just "is it up."

---

## Page 2 — What you will be able to do

**Type:** Objectives (`.numrows`).

1. Name the four log streams in an ADK process and say which configuration reaches each.
2. Choose between an arbitrary log line, a per-agent callback, and a plugin — and emit JSON.
3. Turn export on for the target you actually deploy to, and say what breaks if you do not.
4. Read a trace to find the slow step and the failed step, and tell a failed tool from a failed turn.
5. Keep prompt text out of telemetry, which takes **two** variables, not one.
6. Chart the seven stable metrics; know which questions need BigQuery rows instead.

**Notes:** Objective 5 is the one with a compliance consequence. Objective 6 is the one
students most often get wrong in the first week, because the useful ids are exactly the ones
a metric may not carry.

---

## Page 3 — Section divider: Logs

**Type:** Section divider. **Section:** 01. **Kicker:** Logs.
**dsub:** Four streams, two destinations, and the one line you wrote.

---

## Page 4 — One process, four log streams

**Type:** Mechanism (figure + `.checks`).

**Lede:** You set `--log_level WARNING` to quiet a noisy service, and the framework goes
quiet — but one line per request keeps printing, health checks included.

**Body — the four streams (`.checks`):**
- **Your code** — `logging.getLogger("my_agent")`. Configured by you, wherever you configure it.
- **`google_adk`** — the framework's own tree. `adk web --log_level` sets it; nothing else does.
- **`uvicorn.access`** — one line per HTTP request. Configured by **uvicorn at startup**; the ADK flag never reaches it.
- **OpenTelemetry** — `gen_ai.*` events, only when a `LoggerProvider` is installed (section 2).

**Diagram** (`fig-streams`, 1000 × 300): four rounded blue boxes across the top labelled with
the stream names in mono. Solid arrows from all four converge into one gray box **stdout /
stderr**, and from there one solid arrow to a blue box **Cloud Logging**. Above each of the
first three, a dashed arrow down from a small gray box naming its configurator:
`logging.config` → your code; `--log_level` → `google_adk`; `uvicorn` defaults →
`uvicorn.access`. The fourth has a dashed arrow from `TracerProvider / LoggerProvider` drawn
**gray and dotted** with the label "section 2". Caption: "Four producers, one pipe. The
dashed arrows are what you can turn."

**Example:** *Actor:* Marco, quieting a chatty service. *Input:* `adk web --log_level WARNING`.
*Mechanism:* the flag configures the root logger and `google_adk` only; `uvicorn.access` was
configured by uvicorn before the flag was read. *Result:* framework and tool lines stop; one
`INFO: … "POST /run HTTP/1.1" 200 OK` per request continues, health checks included.

**Takeaway:** Almost every "my logs look wrong" problem is one stream configured and another
expected to follow.

**Sources:** `cli/utils/logs.py` (configures root + `google_adk` only), logging tutorial 1.3,
1.5, Part 2 (captured 2026-09-03), google-adk 2.9.0.

**Notes:** This is generic — any Python process with a web server has this shape. Say so.
What is agent-specific is only that stream 4 carries the trajectory, which is section 2's
subject. Delivery beat: ask the room who has set a log level and still seen output. Gotcha
for notes: `--log_level` on `adk deploy cloud_run` sets *gcloud's* verbosity, not the
container's — that lands on page 10.

---

## Page 5 — What ADK logs on its own

**Type:** Concept + correction.

**Lede:** Before you write a single log line, the framework is already writing them — as
plain text, at INFO, with no severity the platform understands.

**Body (`.checks`):**
- Text lines, never JSON. `2026-09-03 21:51:45,037 - INFO - agent.py:53 - tool get_weather called for city='London'`
- On Cloud Run and Agent Runtime they are captured with **no sink and no setup**…
- …and arrive with **Default** severity, not ERROR — even the ones written to stderr.
- So `severity>=ERROR` as an alert filter sees nothing, including real errors.

**`.note.red`** — **The source deck is wrong here.** Slide 8 lists structured lifecycle events
(`agent.started`, `llm.request`, `tool.called`). Those names do not exist in ADK 2.9.0. The
structure you actually get is span names, not log events — section 2.

**Example:** *Actor:* an on-call engineer with a `severity>=ERROR` alert. *Input:* the tool
raises, ADK logs the traceback to stderr. *Mechanism:* the platform captures stderr as
`textPayload` with severity unset. *Result:* the alert never fires. Measured across a Cloud
Run Job, a Cloud Run service, and an Agent Runtime engine.

**Takeaway:** You get logs for free, and they are the wrong shape for anything automated.

**Sources:** logging tutorial 1.4, 1.5, 1.6 (three deploys, captured 2026-09-03); grep of
`google/adk` for the slide's event names on 2.9.0 — zero occurrences.

**Notes:** Generic (stdout capture) — say so. The correction matters because a student who
believes slide 8 will go looking for a filter that cannot exist. This page sets up page 9:
the fix is one logging config, not per-line effort.

---

## Page 6 — Three ways to write your own log line

**Type:** Comparison (`table.cmp`, `tr.hl` on the plugin row).

**Lede:** You want cost per turn. There are three places to put that line, and they differ in
how much of the agent they see.

**Table — columns: Mechanism / Sees / Registration / Survives the level dial:**
| | | | |
|---|---|---|---|
| Arbitrary `logger.info` in a tool | whatever is in scope | none | yes |
| Per-agent callback (`after_model_callback`) | one agent's model calls, as objects | on **each** agent | yes |
| **Plugin on the `App`** (`tr.hl`) | every agent and tool, as objects | **once** | yes, and it has 4 error hooks |

**`.note.blue`** — **Hooks hand you objects, not strings.** `after_model_callback` receives
`llm_response`, so `usage_metadata.prompt_token_count` is an integer. That is the whole reason
to prefer a hook over a print.

**Example:** *Actor:* Priya, costing a four-agent app. *Input:* `after_model_callback` reading
`llm_response.usage_metadata`. *Mechanism:* as a per-agent callback she wires it four times;
as a plugin, once on the `App`. *Result:* same data, one registration instead of four, plus
`on_model_error_callback` firing on the failures the callback path never sees.

**Takeaway:** Plugins are the production choice: one registration, every agent, objects not
strings, and the error hooks callbacks lack.

**Sources:** `plugins/base_plugin.py` on 2.9.0 — 14 hooks, 4 of them error hooks
(`on_model_error_callback`, `on_tool_error_callback`, `on_agent_error_callback`,
`on_run_error_callback`), counted from the class 2026-09-12; logging tutorial 4.1, 4.4.

**Notes:** Agent-specific by the trajectory mechanism: the thing worth logging is a step the
model chose, and only a lifecycle hook sees the step as data. Keep off the face: plugins and
callbacks can *change* behavior (return a value and you have overridden the step);
OpenTelemetry only records. That is the real content of the source deck's slide 32, whose own
version of the distinction is wrong in both directions.

---

## Page 7 — Emit an object, not a sentence

**Type:** Code (two blocks, contrast).

**Lede:** The hook handed you four numbers. Whether they stay numbers is decided on this line.

**`.codelabel.bad` — throws the data away:**
```python
logger.info(f"tokens: {n}, latency: {ms}ms")
```

**`.codelabel.good` — keeps it queryable:**
```python
logger.info(
    "llm_response",
    extra={"event": "llm_response", "input_tokens": 141,
           "output_tokens": 6, "latency_ms": 1617},
)
```

**`.note.blue`** — In Logs Explorer the first is one string you would need a regex to sum.
The second gives you `jsonPayload.latency_ms`, a chartable field, and
`SUM(jsonPayload.input_tokens)` in a BigQuery sink.

**Example:** *Actor:* Priya again. *Input:* the same `usage_metadata`. *Mechanism:* `extra=`
puts each value in its own field; page 9's formatter renders them as JSON. *Result:* "what did
this turn cost" is a query, not a grep.

**Takeaway:** A hook hands you numbers; f-strings turn them back into prose. Emit the object.

**Sources:** logging tutorial 4.1; `logging` stdlib `extra=`; docs.cloud.google.com/run/docs/logging.

**Notes:** `extra=` alone is not enough — it needs the JSON formatter from page 9 to reach the
payload. Say that here so page 9 lands as the completion of this thought rather than a new one.

---

## Page 8 — The two shipped plugins are development tools

**Type:** Concept + `.note.red`.

**Lede:** ADK ships two logging plugins. Neither is the one you deploy with.

**Body (`.checks`):**
- `LoggingPlugin` narrates the loop with **`print()`** and ANSI color codes.
- It ignores your handlers, levels and formatters — and corrupts a JSON line.
- `DebugLoggingPlugin` buffers one whole turn into a redacted YAML file at mode `0600`.
- Both are excellent at a laptop and wrong in a pipeline.

**Example:** *Actor:* the same service as a Cloud Run Job with `LOG_LEVEL=WARNING`.
*Input:* `LoggingPlugin` left registered. *Mechanism:* `_log` calls `print`, which no level
dial reaches. *Result:* the narration keeps going, lands on stdout at Default severity, with
literal `^[[90m` bytes in the payload. Nothing in it is a field you can filter or alert on.

**Takeaway:** Development plugins print; production plugins log. Check which one you shipped.

**Sources:** `plugins/logging_plugin.py` (`_log` → `print`, `:289-293` on 2.9.0),
`debug_logging_plugin.py` (0600, `temp:`/credential redaction); logging tutorial 3.2, 3.4
(captured 2026-09-03).

**Notes:** Generic — a print-based library behaves this way in any language. Say so.

---

## Page 9 — Structured logging: where the four streams converge

**Type:** Mechanism + code.

**Lede:** One config call, and the framework's lines come out shaped like yours — including
lines you never wrote.

**Two terms, both standard Python, neither ADK (`.note.blue`):**
- **`dictConfig`** is `logging.config.dictConfig`: the one call that configures every logger,
  handler and formatter in the process from a dict. The alternative to `basicConfig` plus
  per-logger fiddling.
- **`ContextVar`** is `contextvars.ContextVar`: a variable scoped to the current task rather
  than the process, so concurrent requests each see their own value.

**Code (≤ 20 lines):** a `dictConfig` with one JSON formatter on the root handler, the
formatter reading a module-level `ContextVar` for the trace id and emitting `severity` and
`logging.googleapis.com/trace` alongside the record's own fields.

**Diagram** (`fig-converge`, 1000 × 260): the same four stream boxes as page 4, now all
feeding a single blue box **JSON formatter on the root handler**, which emits one rounded box
`{"severity": …, "logging.googleapis.com/trace": …, …}` to Cloud Logging. A dashed arrow from
a small box `ContextVar` into the formatter, labelled "set once per request."

**Example:** *Actor:* anyone debugging one user's turn. *Input:* the trace id set into a
`ContextVar` at request start. *Mechanism:* the formatter reads it on every record emitted
while that request runs. *Result:* three lines carry the same trace — your
`chat_request_received`, the plugin's `llm_request`, and `google_adk`'s "Sending out request,"
a line you never wrote. In Logs Explorer they collapse into one request's story.

**Takeaway:** Configure the formatter once and every stream, including the framework's, comes
out queryable and correlated.

**Sources:** logging tutorial 4.2, 4.3 (captured 2026-09-04);
docs.cloud.google.com/run/docs/logging special fields; `logging.config`, `contextvars` (stdlib).

**Notes:** Generic (Cloud Run structured logging) — say so; the payoff is agent-shaped because
one request is a whole trajectory. The `logging.googleapis.com/trace` field is what makes
page 23's log-under-span join possible, so plant it here.

---

## Page 10 — Level and format, per platform

**Type:** Comparison (`table.cmp`).

**Lede:** Two separate questions, and the answer to each changes with where you deployed.

**Table — columns: Target / Who sets the level / Who sets the format:**
| | | |
|---|---|---|
| `adk web` / `api_server` | `--log_level` | you |
| `adk deploy cloud_run` | **not** `--log_level` (that is gcloud's verbosity); container runs at INFO | you |
| Agent Runtime, **native** | no flag; `LOG_LEVEL` only if your code reads it | **the platform** — its handler is installed before your module imports |
| Agent Runtime, **BYOC** | yours | you |
| GKE | yours | you |

**`.note`** — There is no ADK log-level environment variable. `LOG_LEVEL` is a convention your
own code implements.

**Example:** *Actor:* one agent, two Agent Runtime engines. *Input:* the same `basicConfig`.
*Mechanism:* native hands the platform the agent and it runs its own server, installing its
handler first; BYOC hands over a container running your server. *Result:* native prints
`2026-09-03 21:51:45,037 - INFO - agent.py:53 - tool get_weather called…`; BYOC prints
`INFO - demo_agent.agent - tool get_weather called…`, the format the code asked for. Both land
on `reasoning_engine_stderr` at Default severity.

**Takeaway:** The level is yours everywhere; the format is yours everywhere except a native
Agent Runtime deploy, where the platform's handler wins.

**Sources:** logging tutorial 1.6 (two deploys, captured 2026-09-03);
`cli_tools_click.py:2529-2530` (`log_level` → gcloud `verbosity`),
`_cloud_run_deployer.py:120-121`; google-adk 2.9.0.

**Notes:** Agent-specific by the hosted-model mechanism: the config surface changes per target
while the agent code does not. Delivery beat: "whose handler got there first" is the whole
rule.

---

## Page 11 — Reading logs back

**Type:** Concept (`.checks` + `.grid.c2`).

**Lede:** The logs are landing. Now answer a support ticket with them.

**Body — three consumption paths, narrowing:**
- **Log Explorer**, filtered by `jsonPayload.session_id` or `trace` — one conversation, in order.
- **A sink to BigQuery** — one table per log name; the sink's writer identity needs
  `roles/bigquery.dataEditor`. Generic infrastructure; say so.
- **`BigQueryAgentAnalyticsPlugin`** — the agent-shaped option: one row per lifecycle event
  with ids, tokens, latency and content, into `agent_events`, with `create_views=True`.

**Example:** *Actor:* support, on "the agent failed for my order." *Input:*
`jsonPayload.session_id="s-8841"`. *Mechanism:* Log Explorer returns that session's lines in
order; the malformed tool input is visible. *Result:* ticket answered. But "which session cost
the most" is not a log filter — that is
`SUM(usage_total_tokens) GROUP BY session_id` over `v_llm_response`.

**Takeaway:** Filters answer "what happened in this session"; rows answer "which session," and
only one of those is a log query.

**Sources:** `plugins/bigquery_agent_analytics_plugin.py` (table `agent_events`,
`create_views=True`, `enable_otel_correlation`); adk.dev BigQuery Agent Analytics;
docs.cloud.google.com sink→BigQuery.

**Notes:** The plugin is agent-specific — sessions and per-event rows are managed data with
their own retention and access story, and the content column is prompt text. Plant
`session_id`; page 27 reuses it as the canonical unbounded id. Keep the sink itself to one
line: it is generic and the brief marks it a tour.

---

## Page 12 — Section 1 recap

**Type:** Recap (`.checks`, green dots).

- Four streams, four configurators. `uvicorn.access` is the one that surprises you.
- ADK's own logs are text at Default severity. Slide 8's event names do not exist.
- Plugin > per-agent callback > arbitrary line, for anything you will query later.
- `extra=` plus one `dictConfig` makes every stream JSON, correlated by trace id.
- The format is yours except on a native Agent Runtime deploy.

---

# Section 2 — Traces (pages 13–24)

## Page 13 — Section divider: Traces

**Type:** Section divider. **Section:** 02. **Kicker:** Traces.
**dsub:** The shape of one turn, and the three switches between code and Cloud Trace.

---

## Page 14 — Instrumentation, recording, export

**Type:** Mechanism (figure) — **the page the rest of the section depends on.**

**Lede:** `adk web` shows you a trace tree with no configuration at all. The same agent in a
script shows nothing. Neither is a bug.

**Body — three states (`.checks`):**
- **Instrumentation** is in the code, always. ADK calls `start_as_current_span` around every
  turn whatever you do.
- **Recording** needs a `TracerProvider`. Without one, every span is a `NonRecordingSpan` and
  is dropped on the floor.
- **Export** needs that provider to have a network exporter. This is the switch page 18 is about.

**Diagram** (`fig-three-states`, 1000 × 340): three columns, left to right.
**Nothing installed** — a gray box `start_as_current_span()` with a dashed gray arrow to a
gray `NonRecordingSpan` and a gray ✕; trace id `00000000000000000000000000000000` in mono
below. **`adk web`** — the same blue call box, solid arrow into a blue `TracerProvider`, then
to two blue boxes `ApiServerSpanExporter` and `InMemoryExporter`, with a note "Trace tab; dies
on restart." **`--otel_to_cloud`** — the same provider, solid arrow to a green
`OTLP → telemetry.googleapis.com` and on to a green **Cloud Trace**. Caption: "The same code
in all three. Only the right-hand column leaves the process."

**Example:** *Actor:* verified on 2.9.0, 2026-09-12. *Input:* one real turn, no provider
installed. *Mechanism:* `trace.get_current_span()` inside the run. *Result:* a
`NonRecordingSpan` with an all-zeros trace id. The agent answered normally; nothing was
recorded, let alone exported.

**Takeaway:** Instrumentation is free, recording is a provider, export is an exporter. Most
"tracing is not working" is the second one missing.

**Sources:** no-provider check `scratchpad/notrace.py` (2026-09-12);
`api_server.py:1188-1196` (`adk web` always installs both in-memory exporters), `:650-666`
(the three branches); google-adk 2.9.0.

**Notes:** Agent-specific: the tree *is* the decision sequence, which is what a flat log cannot
give you. Tie back to M2 page 14 explicitly — its "Turn export on" column is this **third**
state, not the first; a student who read that page can leave thinking spans exist everywhere
and the flag only ships them. Also correct the tracing tutorial's own "you are not switching
tracing on, it is on" framing: that is `adk web`-specific.

---

## Page 15 — The tree you actually get

**Type:** Mechanism (figure) + `.note.red`.

**Lede:** Five span names, and the nesting is not what most people draw.

**Diagram** (`fig-tree`, 1000 × 380): an indented tree with real durations from the live
Agent Runtime capture. `invoke_workflow weather_agent` 6.13s → `invoke_agent weather_agent`
5.98s → `call_llm` 2.91s → (`generate_content gemini-3.7-flash` 1.46s **and**
`execute_tool get_forecast` 1.15s as siblings) ; then a second `call_llm` 3.06s →
`generate_content` 2.91s. Scope badges on the right: `gcp.vertex.agent` on the ADK spans,
`opentelemetry.instrumentation.google_genai` on the two `generate_content` spans, in different
blues. Caption: "One turn, two tools calls' worth of model round-trips. `execute_tool` hangs
off the `call_llm` that requested it."

**`.note.red`** — The source deck's "thought / action" span names do not exist. And the root is
`invocation` everywhere except Agent Runtime, where it is `invoke_workflow` (page 20).

**Example:** *Actor:* the live probe engine, 2026-09-12. *Input:* "Give me a 3-day forecast for
Tokyo." *Mechanism:* the model asks for a tool, ADK runs it inside that model call's span, then
calls the model again with the result. *Result:* 60 spans across 12 traces; `execute_tool`
nested under `call_llm`, not under `invoke_agent`.

**Takeaway:** The tool span lives under the model call that asked for it — which is why the
waterfall reads as a decision sequence rather than a list of steps.

**Sources:** live 2.9.0 Agent Runtime capture 2026-09-12 (`scratchpad/ae_spans.json`);
`_instrumentation.py:157,551,588`; tracing tutorial 1.1.

**Notes:** Two instrumentation scopes in one tree is a filtering trap — it comes back on
page 26 for metrics. Delivery beat: draw the tree on the whiteboard wrong (tool under agent)
and let the room correct it.

---

## Page 16 — Reading a trace: the slow step

**Type:** Concept + figure.

**Lede:** "The agent is slow" is not actionable. A waterfall makes it "this tool call is slow."

**Diagram** (`fig-waterfall`, 1000 × 260): a horizontal waterfall, bars proportional.
`invoke_agent` 4.69s spanning the full width; `call_llm` 2.53s and `call_llm` 2.16s; under the
first, `execute_tool get_forecast` 0.41s in a contrasting fill. Axis in seconds.

**Body (`.checks`):**
- Read the **widest child**, not the total.
- Two `call_llm` spans means the model was asked twice — once to choose the tool, once to
  phrase the answer.
- A tool that looks slow is often a model that was called twice.

**Example:** *Actor:* an engineer with a 4.7s p95. *Input:* one forecast turn. *Mechanism:* the
waterfall attributes 4.69s across two model calls at 2.53s and 2.16s and one tool at 0.41s.
*Result:* the tool is not the problem; the second model round-trip is. Caching the tool would
have bought 0.41s at best.

**Takeaway:** The waterfall tells you which of the model's two calls to attack.

**Sources:** tracing tutorial 1.1, 1.4 (captured 2026-09-07).

---

## Page 17 — Reading a trace: the failed step

**Type:** Concept + `.note.red`.

**Lede:** The tool returned `{"status": "error"}`, the user got "I don't have data for that,"
and every span in the trace is green.

**Body (`.checks`):**
- A plain `FunctionTool` stamps **no** `error.type` for a returned failure status.
- `_detect_error_in_response` returns `None` on `FunctionTool` — the hook exists and does nothing.
- Override it and the same status turns the span red with `error.type="lookup_failed"`.
- A **raised** exception is different: it propagates and both parents go ERROR.

**`.note.blue`** — Three different things: a failed **tool**, a failed **turn**, and an
**unmet request**. They do not imply each other in either direction.

**Example:** *Actor:* a user asking for weather in Atlantis. *Input:* the tool returns a failure
status. *Mechanism:* `FunctionTool` reads it as an ordinary return value. *Result:* the
`execute_tool` span is **UNSET** with no `error.type`, every parent green, and the model
routes around the failure to tell the user there is no data. Nothing in the trace says the
user did not get what they asked for.

**Takeaway:** Whether a returned failure reaches the trace at all is a choice you make in the
tool.

**Sources:** `functions.py:88` (`_detect_error_in_response` returns `None`); tracing tutorial
1.4 (three failure modes, captured 2026-09-07).

**Notes:** Agent-specific by multi-dimensional correctness: a green tree and an unmet request
coexist precisely because the model is allowed to recover. This is the setup for page 28's
outcome counter — name that hand-off.

---

## Page 18 — Turning export on, per target

**Type:** Comparison (`table.cmp`) + code.

**Lede:** Same agent, four places to run it, four different switches.

**Table — columns: Target / The switch / Who writes it:**
| | | |
|---|---|---|
| Agent Runtime | `GOOGLE_CLOUD_AGENT_ENGINE_ENABLE_TELEMETRY=true` | `adk deploy agent_engine --otel_to_cloud` |
| Cloud Run / GKE | `--otel_to_cloud` in the container `CMD` | the deploy |
| `agents-cli` → any | `ENABLE_TELEMETRY`, read by the scaffold's server | the deploy / Terraform |
| **Your own server** (`tr.hl`) | two calls, below | you |

**Code:**
```python
from google.adk.telemetry import google_cloud
from google.adk.telemetry.setup import maybe_set_otel_providers

hooks = google_cloud.get_gcp_exporters(
    enable_cloud_tracing=True, enable_cloud_metrics=True, enable_cloud_logging=True
)
maybe_set_otel_providers(otel_hooks_to_setup=[hooks])
```

**`.note`** — Unset resolves to **off** on Agent Runtime unless the platform sets it. This is
the third state from page 14, nothing more.

**Example:** *Actor:* the live probe deploy, 2026-09-12. *Input:*
`adk deploy agent_engine --otel_to_cloud`. *Mechanism:* the deploy writes the variable into the
deployment. *Result:* read back off the resource:
`GOOGLE_CLOUD_AGENT_ENGINE_ENABLE_TELEMETRY = true`, and 60 spans in Cloud Trace from five turns.

**Takeaway:** Export is a flag on `adk deploy`, a variable the scaffolded server reads on
`agents-cli`, and two lines of startup code in a runtime you wrote.

**Sources:** `cli_deploy.py:843-844,1277-1286`; `api_server.py:650-719`;
live 2.9.0 engine capture 2026-09-12; tracing tutorial 2.1–2.4.

**Notes:** Agent-specific: the model's host owns the telemetry switch, so the same agent
exports differently per target with no code change. M2 page 14 has this table from the
*deployment* angle; this page is the *observability* angle. Say that out loud if both modules
are delivered together.

---

## Page 19 — The packages, and how it fails without them

**Type:** Concept + `.note.red`.

**Lede:** The flag turns export on. It does not install the exporters, and what happens next
depends on where you deployed.

**Body (`.checks`):**
- `--otel_to_cloud` needs `google-adk[otel-gcp]` plus the Cloud exporter packages in the image.
- **Cloud Run / GKE:** the Cloud Logging exporter import is unguarded — the revision
  **boot-crashes**, and `adk deploy` still exits 0.
- **Agent Runtime:** the container starts, serves traffic, and logs a warning — telemetry is
  silently off.
- `adk deploy agent_engine` stages **`<agent_dir>/requirements.txt`**, the file *inside* the
  agent folder. One beside it is ignored.

**`.note.red`** — Two failure modes, one cause. Loud on Cloud Run; quiet on Agent Runtime,
which is the worse one for an operator.

**Example:** *Actor:* me, on the probe deploy, 2026-09-12. *Input:* `requirements.txt` placed
one directory too high. *Mechanism:* the deploy generated its own two-line file; the exporters
never arrived. *Result:* the engine deployed clean, answered turns, and stderr read
`Unable to import GoogleGenAiSdkInstrumentor — some telemetry will be disabled. Make sure to
install google-adk[otel-gcp]`. No crash, no spans. Moving the file fixed it.

**Takeaway:** `adk deploy` exiting 0 is not evidence that telemetry works. Check a span, or
check stderr.

**Sources:** `telemetry/google_cloud.py:272` (unguarded import);
`templates/adk.py:407-417,485-490,540-546` (guarded, degrades); live probe deploy 2026-09-12;
tracing tutorial 2.2.

**Notes:** This page exists because I hit it live. Use it as the delivery beat: the failure is
not in the flag, the code, or the permissions — it is the file's directory.

---

## Page 20 — Agent Runtime differs in two more ways

**Type:** Concept.

**Lede:** Two things change on Agent Runtime that change nothing about your code.

**Body (`.checks`):**
- The root span is **`invoke_workflow`**, not `invocation` — telemetry schema v2, selected by
  `GOOGLE_CLOUD_AGENT_ENGINE_ID`.
- Metric export is **driven by the request**, not a background timer, because CPU is throttled
  the instant a response ends.
- So `_RequestDrivenMetricReader` replaces `PeriodicExportingMetricReader`, flushing after the
  response streams.
- Spans carry `service.name=<engine id>` and `cloud.platform=gcp.agent_engine` on the resource.

**`.note`** — **Reading them back:** the legacy Cloud Trace **v1** API does not return these
spans. Use Trace Explorer, filtered on the engine id as `service.name`.

**Example:** *Actor:* the same agent, two targets. *Input:* identical code. *Mechanism:* the
schema version is picked from the environment. *Result:* on Cloud Run the trace roots at
`invocation`; on Agent Runtime at `invoke_workflow weather_agent` — verified on the live
engine, 11 such roots across 12 traces.

**Takeaway:** Every OTel batch exporter assumes a daemon thread keeps running. On a
per-request runtime that assumption is false, and ADK works around it for you.

**Sources:** `telemetry/_schema_version.py:72-91`; `_agent_engine.py:1139-1199`,
`_agent_engine_metric_exporter.py`; live 2.9.0 capture 2026-09-12
(`scratchpad/ae_spans.json`); tracing tutorial 2.4.

**Notes:** Agent-specific: the runtime bills per request. The read-back gotcha is worth saying
out loud — I lost time to it on the capture that produced this page's numbers.

---

## Page 21 — Two settings control prompt text in telemetry

**Type:** Comparison (`table.cmp`) — **the compliance page.**

**Lede:** "Turn off prompt logging" is two variables with opposite defaults, and missing
either one leaves text in your traces.

**Table — columns: Variable / Governs / Default:**
| | | |
|---|---|---|
| `ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS` | ADK's own spans: `llm_request`, `llm_response`, `tool_call_args`, `tool_response` | **on** |
| `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` | the `gen_ai.*` log events — **and**, under the semconv opt-in, the `generate_content` span in `SPAN_ONLY`/`SPAN_AND_EVENT` | **off** (`NO_CONTENT`) |

**`.note.blue`** — Neither overrides the other. "Content off" means **both**.

**Example:** *Actor:* the eight-run matrix, 2.9.0, real Gemini calls, 2026-09-12. *Input:*
run 4 = ADK knob `true`, OTel knob `NO_CONTENT`. *Mechanism:* each knob gates a different
writer. *Result:* the ticket number `ZQX41` is on `gcp.vertex.agent.llm_request` and absent
from every log event. Run 7 (ADK `false`, `SPAN_AND_EVENT`): gone from ADK's spans, present on
`gen_ai.input.messages` of the instrumentor's span.

**Takeaway:** One variable off is not content off. Check both, and check them on the target you
actually deploy to.

**Sources:** eight-run matrix `scratchpad/knobs.py` (2026-09-12);
`telemetry/context.py:108-113,244-274`; `tracing.py:306,336,632`;
`_experimental_semconv.py:642`.

**Notes:** Agent-specific: the trajectory carries user content, so observability quietly
becomes a data-retention decision bounded by who can read Cloud Trace. I originally claimed
these two knobs do not interact; the matrix disproved it. Under the experimental semconv the
OTel variable reaches a *span*, which is why calling it "the events one" is wrong.

---

## Page 22 — Whether your setting survives deployment

**Type:** Comparison (`table.cmp`).

**Lede:** You set a policy once in `.env`. Whether it survives depends on the target.

**Table — columns: Target / What happens to `ADK_CAPTURE_…`:**
| | |
|---|---|
| `adk deploy agent_engine` → **native** | deploy writes `false` if absent; then the Vertex SDK **overwrites it to `false` at every container start**, regardless |
| `adk deploy cloud_run` / `gke` | nothing touches it; the agent folder's `.env` ships inside the image and wins |
| `agents-cli` → Agent Runtime | deploy writes `false`; **no overwrite** — the scaffold's own server runs, not `AdkApp` |
| Any BYOC / your own runtime | yours |

**`.note`** — No deploy tool touches the **OTel** variable on any target. If you want
`EVENT_ONLY` or the semconv opt-in, you set it yourself.

**Example:** *Actor:* a team standardizing `ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS=false`.
*Input:* the line in `demo_agent/.env`. *Mechanism:* three different code paths. *Result:* on
native Agent Runtime it is redundant (the SDK forces `false` anyway); on Cloud Run it is the
only thing stopping prompt text reaching Cloud Trace; on BYOC it is yours again.

**Takeaway:** The default differs per target, so a policy set once is not a policy in force
everywhere.

**Sources:** `cli_deploy.py:1285-1286`; `templates/adk.py:990-996`
(`os.environ[...] = "false"` unless the deprecated `enable_tracing=True`),
google-cloud-aiplatform 2.1.0; live probe resource read 2026-09-12.

**Notes:** Rows 1 and 3 both land on Agent Runtime and differ for a real reason: an
`agents-cli` deployment ships a container running the scaffold's FastAPI server, so `AdkApp`
never runs and never overwrites. Same outcome, different mechanism, and only row 3 can be
turned back on with `--update-env-vars`. M2 page 14 carries the matching correction.

---

## Page 23 — Joining logs to spans

**Type:** Mechanism + code.

**Lede:** The tool span is red. Its **Logs & Events** tab is empty. The warning your tool wrote
is sitting in the console with nothing tying it to that span.

**Body (`.checks`):**
- A log entry sits under a span when it carries `trace` **and** `spanId` for a span in the same project.
- ADK's `gen_ai.*` events carry them for free.
- Your `logging` records do not — ADK installs **no** `LoggingHandler` (grep: zero).
- One handler on the root logger fixes it.

**Code:** installing `LoggingHandler` from `opentelemetry.sdk._logs` on the root logger, four
lines.

**Example:** *Actor:* an engineer on a `classified-error` turn. *Input:*
`execute_tool get_weather` red with `error.type=lookup_failed`. *Mechanism:* before the bridge,
the tool's WARNING went to the console with no trace id. *Result:* after one `LoggingHandler`,
the same WARNING appears under the red span, and the "why" sits next to the "what."

**Takeaway:** Correlation is one handler, and without it your most useful log line is the one
furthest from the span that needs it.

**Sources:** tracing tutorial 3.1–3.5 (captured);
docs.cloud.google.com/trace/docs/trace-log-integration; grep of `google/adk` for
`LoggingHandler` on 2.9.0 — zero.

**Notes:** Generic (OTel correlation) — say so; agent-shaped because the thing you want beside
the red span is your tool's own warning. On Cloud Run the inbound request log and ADK's spans
are two different traces unless you propagate; that is the tutorial's Part 3 and belongs in
notes, not on the face.

---

## Page 24 — Section 2 recap

**Type:** Recap.

- Instrumentation is always on; recording needs a provider; export needs an exporter.
- `invoke_workflow`/`invocation` → `invoke_agent` → `call_llm` → `generate_content`, with
  `execute_tool` under the `call_llm` that asked.
- A green trace and an unmet request coexist. Classify tool errors yourself.
- Export is one switch, in a different place per target — and the packages are separate.
- Content off is **two** variables, and one target overwrites your choice.

---

# Section 3 — Metrics (pages 25–30)

## Page 25 — Section divider: Metrics

**Type:** Section divider. **Section:** 03. **Kicker:** Metrics.
**dsub:** What to chart, what to alert on, and the question a chart cannot answer.

---

## Page 26 — What ADK measures without any code from you

**Type:** Concept + `.note`.

**Lede:** Token counts and tool frequency are not custom metrics. They are already being
emitted, under two different names with two different stability promises.

**Body — two families (`.grid.c2`):**
- **Stable `gen_ai.*` (7)** — `invoke_agent.duration`, `invoke_workflow.duration`,
  `execute_tool.duration`, `invoke_agent.inference_calls`, `invoke_agent.tool_calls`, plus
  `client.operation.duration` and `client.token.usage` from the shared semconv helpers.
- **`adk.experimental.*` (16)** — every token histogram (input, output, total, cache-read,
  reasoning, tool) at both agent and workflow grain, plus skill loads and script executions.

**`.note`** — The experimental set is **not gated**. It is always emitted; the prefix is a
warning that the names may change, not a feature flag. A dashboard built on
`adk.experimental.invoke_agent.input_tokens` is a dashboard built on a name ADK reserves the
right to rename.

**Example:** *Actor:* one baseline turn. *Input:* a single question with one tool call.
*Mechanism:* three histograms record at different grains. *Result:* `invoke_agent.duration`
count=1 sum=3.26s; `client.token.usage` input sum=713 across count=2 model calls;
`inference_calls` sum=2 count=1. On `token.usage`, `sum ÷ count` is tokens **per call**, not
per turn.

**Takeaway:** Read the instrument's grain before you divide by its count, and check the prefix
before you build a dashboard on it.

**Sources:** `telemetry/_metrics.py` re-read on 2.9.0 2026-09-12 (`:67-153` stable,
`:141-309` experimental, `_create_token_histogram` at `:213`); metrics tutorial 1.1, 2.2
(captured 2026-09-06 on 2.8.0); adk.dev/observability/metrics.

**Notes:** Agent-specific: the measurements that matter exist because the workload is a model
loop. The two-scope trap from page 15 returns here — `gcp.vertex.agent` and the google-genai
instrumentor both emit, so a scope filter can silently halve your data. Correction worth
naming: the concept list said "seven `gen_ai.*` histograms" full stop; on 2.9.0 the catalog is
two families and the experimental one is larger.

---

## Page 27 — Which layer is slow: the turn, the model, or a tool

**Type:** Concept + figure + code.

**Lede:** "The agent got slow" has three possible culprits, and the same percentile read at
three grains tells you which one.

**Revised 2026-09-13.** This page previously covered metric-vs-row cardinality. That point is
generic infrastructure, it duplicated page 11, and it spent a metrics slide on something that is
not a metrics decision. The cardinality constraint now lives in page 11's notes (where
`session_id` is introduced) and as one bullet on page 29. In its place, the operator's first
question, which the tutorial's Part 3 opens with and the deck had no page for.

**Body:** p95 at turn / model / tool grain, one query shape with three groupings. The blue note
covers `_bucket` vs the bare metric name and the silent-empty failure.

**Diagram** (1000 × 250): three horizontal bars to scale on a shared 0–8s axis. turn
`invoke_agent.duration` 7.84s (red), model `client.operation.duration` 4.83s (blue), tool
`execute_tool.duration` split into `get_forecast` 2.16s (red) and `get_weather` 0.010s (green
hairline). Value labels sit at each bar's right end, not in a shared right-hand column.

**Example:** Marco / paged on turn-latency SLO / runs the three queries / turn 7.84s vs model
4.83s, `get_forecast` 2.16s vs `get_weather` 0.010s / files against the forecast API, not the
model provider.

**Takeaway:** one percentile at three grains turns "the agent is slow" into a named owner, and
the turn grain alone could never have told you which.

**Sources:** metrics tutorial 3.1, `slow-tool`, 30 turns (captured 2026-09-06, google-adk
2.8.0); `queries/latency.promql`; Cloud Monitoring PromQL docs (verified 2026-09-12).

**Notes:** first operator question; why turn is larger than model + tool and why they do not
add; percentile vs average; agent-specific as nested external dependencies; the concurrency deep
dive; delivery beat showing the turn number alone first.

## Page 28 — Three ways to count failure, and which one to alert on

**Type:** Concept + figure.

**Revised 2026-09-13.** Same measured content as the previous "Three different facts on one run",
reframed around the alerting decision. The old framing stated three ratios and let the audience
infer the point; the gauge stack also read as a trace tree. Now the headline is the operational
mistake, the three bars are labelled as questions rather than metric names, and the example walks
the bad alert before the fix.

**Lede:** Alert on the tool error ratio and it fires at 2am for turns where every user got a
helpful answer. The number is right; it is measuring the wrong thing.

**Diagram** (1000 × 260): three horizontal bars, same 0–1 scale, each labelled with the question
it answers and, below in mono, the instrument behind it. "Did a tool fail?" 0.476 (red). "Did the
turn fail?" 0 (green hairline). "Did the user get an answer?" 0.476, dashed border = your counter.

**Example:** Marco / wants to be paged only when users stop getting answers / first alerts on tool
error ratio > 0.2 and it fires on a normal week / re-keys the alert to
`tutorial.weather.requests{outcome="unavailable"}`.

**Takeaway:** the framework can tell you execution finished; only your code can tell you the task
was accomplished, so that is the metric you alert on.

**Sources:** metrics tutorial 3.7, `unknown-city`, 40 turns (captured 2026-09-12);
`queries/errors.promql`, `queries/outcome.promql`, `queries/alert-policy.json`.

**Notes:** callback to page 17; why rows 1 and 3 match here and diverge in real apps; the real
alert-policy shape (`conditionPrometheusQueryLanguage`, no `thresholdValue`); the missing `_total`
suffix trap; outcome is an allowlist on the tool's status, not parsed model text.

## Page 29 — Input tokens grow as a conversation gets longer

**Type:** Concept + figure.

**Lede:** Input tokens climb through a session while output stays flat. The average over the
run hides exactly the thing you wanted to see.

**Diagram** (`fig-tokens`, 1000 × 280): a line chart plotting the six **measured** points below,
x = elapsed time across the 20-turn session, two series. **Input tokens per call** rising
366 → 382 → 638 → 1129 → 1405 → 1720; **output tokens per call** flat at 14–15, drawn near the
axis. A gray dashed horizontal line at ~950 labelled "mean over the run," annotated "one
middling number that matches no turn."

**Body (`.checks`):**
- Context accumulates, so each turn re-sends the conversation.
- Output per call does not grow, so cost per call is driven by input.
- `rate(…_sum) / rate(…_count)` over a short window shows the climb; a run average does not.
- Cost **per session** is a row question (page 27).

**Example:** *Actor:* the `growing-context` run, captured 2026-09-12. *Input:* 20 turns in one
reused session. *Mechanism:* each turn's prompt includes every prior turn. *Result:* input per
call rose **366 → 1720 tokens, 4.7×**, while output per call held at 14–15. Over the session:
**72,308 input tokens against 1,735 output** across 120 model calls — a 42:1 ratio.

**Takeaway:** The cost curve is a property of the agent loop, not of your traffic — so measure
it per call over a window, not per run.

**Sources:** metrics tutorial 3.4 (**captured 2026-09-12** on adk 2.8.0, `adk web --otel_to_cloud`,
`query_range` at `step=30s`); `queries/tokens.promql`; Module 6 picks up cost.

**Notes:** Agent-specific: per-token cost grows with context. Hand off to Module 6 explicitly.
A number from the live capture worth mentioning: `call_llm` reported `output_tokens=69` with
`reasoning.output_tokens=48` while its child `generate_content` reported 21 for the same call —
ADK's span counts reasoning tokens, the instrumentor's does not. Two "output token" numbers,
one model call.

---

## Page 30 — Section 3 recap

**Type:** Recap.

- Seven stable `gen_ai.*` instruments, sixteen `adk.experimental.*` — the prefix is a promise, not a switch.
- Check the grain before dividing by count.
- Bounded attributes are labels; ids are rows.
- Tool error, invocation error and task outcome are three facts. Alert on the third.
- Input tokens climb with context; read per call over a window.

---

## Page 31 — Where each signal is read

**Type:** Comparison (`table.cmp`) + red note. **Live-skip candidate, except the note.**

**Revised 2026-09-13.** Retitled from "Five consoles, one line each": BigQuery and Data Studio
are not consoles. The table gained a middle column ("what you read there") so each row states the
artifact before the caveat, and the Data Studio row's report-vs-dataset point moved into a red
note, since one table cell could not carry it.

**Lede:** Five Google Cloud services, each already used somewhere in this module. Here is the one
thing that changes about each when the workload is an agent.

| Service | What you read there | The agent-specific part |
|---|---|---|
| Cloud Logging (**Observability Analytics** is the new name; needs an upgraded bucket) | individual log entries | filter by `session_id`, not by time window |
| Cloud Trace | one turn as a span waterfall | read the waterfall, not the total, and not via the v1 API |
| Cloud Monitoring | histograms, dashboards, alerts | alert on your own outcome ratio, not a raw tool-error count |
| BigQuery (*a data warehouse, not a console*) | one row per agent event | group by the unbounded id a metric may not carry |
| **Data Studio** (Looker Studio reverted to Data Studio, April 2026) | charts built on those rows | those rows include a `content` column of user prompt text |

**Red note:** a report is backed by a dataset. Granting the **report** shows the charts; adding
someone to the **dataset** lets them query `agent_events` directly, `content` included. Two
separate grants, and the second is the reflex fix when a colleague's chart will not load.

**Takeaway:** Each console answers one shape of question; the last row is a data-protection
decision, not a sharing convenience.

**Sources:** docs.cloud.google.com Observability Analytics; Data Studio welcome page (both
re-verified 2026-09-12).

**Notes:** Generic — say so. This is the page to skip if the room ran slow, because every
service is already named where it is first used. The two renames are worth a sentence either
way: students will hit both names in search results.

---

## Page 32 — Consequences

**Type:** Consequences (`table.cmp`: You observed / Because / So you…).

| You observed | Because | So you… |
|---|---|---|
| Set the log level, still one line per request | `uvicorn.access` is configured by uvicorn, not by the flag | configure it in your own `dictConfig` |
| `severity>=ERROR` alert never fires | ADK logs text; the platform assigns Default severity | emit an explicit `severity` field |
| `adk web` traces, the same agent in a script does not | no `TracerProvider` outside `adk web` | install one, or run under a server that does |
| `adk deploy` exited 0, no spans anywhere | the exporter packages were not in `<agent_dir>/requirements.txt` | check a span, not the exit code |
| Prompt text in Cloud Trace after setting the OTel variable | that variable does not govern ADK's own spans | set both variables |
| `.env` says `true`, the engine still redacts | the Vertex SDK overwrites it at startup on a native deploy | accept it, or use BYOC |
| Tool error rate 50%, users not complaining | the model routes around tool failures | alert on a task-outcome counter instead |
| The dashboard broke after an ADK upgrade | it was built on an `adk.experimental.*` name | pin to the stable `gen_ai.*` set |

**Notes:** This is the page to photograph. Every row is something in this deck that was
verified rather than assumed; rows 4 and 6 came out of the live deploy done while building it.

---

## Page 33 — References

**Type:** References.

- ADK: Logging, Cloud Trace, Metrics (adk.dev/observability/*, /integrations/cloud-trace/)
- `google/adk-python` **v2.9.0** — `telemetry/`, `plugins/`, `cli/api_server.py`, `cli/cli_deploy.py`
- google-cloud-aiplatform **2.1.0** — `vertexai/agent_engines/templates/adk.py`
- Cloud Run structured logging; Cloud Trace log-span integration; Observability Analytics
- Jeff's tutorials: `gcp-demos/ai/adk/{logging,tracing,metrics}`
- This deck's own runs: knob matrix, no-provider check, live Agent Runtime capture (2026-09-12)

**Re-verify note:** ADK's telemetry surface moved between 2.7.1 and 2.9.0 (metric catalog,
schema v2, content-knob semantics). Re-check the version before reusing any specific here.

---

## Open questions for Jeff

- ~~Pages 28 and 29 rest on drafted tutorial pages.~~ **Resolved 2026-09-12.** Ran
  `unknown-city 40` and `growing-context 20` locally on adk 2.8.0 with
  `adk web --otel_to_cloud` against `jwd-gcp-demos`; both pages now carry measured numbers and
  no `illustrative` tag. The `NEEDS-RUN` blocks in `gcp-demos` metrics 3.4 and 3.7 are filled
  in, and the run corrected two things there:
  - **`queries/outcome.promql` and 3.7 had the wrong metric name.** The counter is
    `tutorial.weather.requests` with **no `_total` suffix**; the file's own "ASSUMPTION TO
    VERIFY" comment guessed `_total` on Prometheus convention. Fixed in all four queries.
  - The wrong-scope filter trap in 3.4's deep dive is **confirmed**: filtering
    `gen_ai.client.token.usage_count` to `otel_scope_name="gcp.vertex.agent"` returns an empty
    result and no error.

  Metrics **3.6** (the alert policy) is still `NEEDS-RUN` — it needs 120 turns and creates a
  policy, and no page in this deck cites it. Left alone deliberately.
- **34 pages against a 50-minute budget.** Page 31 is the live-skip. If you want a hard cut
  instead, the next candidate is merging 16 and 17 into one "reading a trace" page, which costs
  the separation between the slow step and the failed step.
