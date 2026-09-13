# Module 3 — concept list

Delivery minutes (non-lab): **50** (Jeff, 2026-09-12) → page budget ≈ 50 / 2.5 = **20 content pages**

Baseline: google-adk **2.9.0** (tag `v2.9.0`, 2026-09-10), google-cloud-aiplatform **2.1.0**.
The companion page `agent_operations/m3.html` was verified against 2.7.1 / 2026-08-25; Jeff's
`gcp-demos/ai/adk/{logging,tracing,metrics}` tutorials against 2.8.0. Anything either dates is
re-verified here against 2.9.0. The content-knob behavior (concept 12) is from an eight-run
matrix against real Gemini calls on 2.9.0, 2026-09-12 (`scratchpad/knobs.py`).

| # | Concept | Agent-specific? | Example (actor / input / mechanism / result) | Verify against | Disposition | Pages |
|---|---|---|---|---|---|---|
| 1 | **One process, four log streams** — your code, the `google_adk` tree, `uvicorn.access`, and OpenTelemetry. Configured in four different places, landing in two different destinations. Almost every "my logs look wrong" problem is one stream configured and another expected to follow | generic (a Python process with a web server) — **say so**; what is agent-specific is only that stream 4 carries the trajectory | Marco sets `--log_level WARNING` to quiet a service. The framework and tool lines stop. One `INFO: … "POST /run HTTP/1.1" 200 OK` per request keeps printing, health checks included, because `uvicorn.access` is configured by uvicorn at startup and the flag never reaches it | logging tutorial 1.3, 1.5, Part 2 (captured runs 2026-09-03); `cli/utils/logs.py` sets only root + `google_adk` | focus | 1 |
| 2 | **What ADK logs on its own, and what the platform does to it.** Text lines, never JSON. On Cloud Run and Agent Runtime they are captured with no sink and arrive with **Default** severity, not ERROR, even from stderr | generic (stdout capture) — **say so**. The correction matters because slide 8 claims structured JSON events | The same `tool get_weather called for city='Tokyo'` line: on a Cloud Run service it is `textPayload`, severity blank; a `severity>=ERROR` alert would never see a real error either. Measured across a Cloud Run Job, a Cloud Run service, and an Agent Runtime engine | logging tutorial 1.4, 1.5, 1.6 (three deploys, 2026-09-03); slide 8's event names do not exist in `_instrumentation.py` | focus | 1 |
| 3 | **Three ways to write your own log line, and which to reach for.** Arbitrary entries under your own logger; a per-agent callback; a plugin on the `App`. The plugin wins for production telemetry: one registration covers every agent and tool, hooks receive objects (so tokens and latency are numbers, not prose), it is independent of the level dial, and it has four error hooks callbacks lack. **Whichever you pick, emit a JSON object, not a sentence** — a hook hands you `usage_metadata` as numbers, and `logger.info(f"tokens: {n}")` throws that away | **yes**: trajectory-level observability — the thing worth logging is a step the model chose, and only a lifecycle hook sees the step as data | Priya wants cost per turn. `after_model_callback` reads `llm_response.usage_metadata` and logs `extra={"event":"llm_response","input_tokens":141,"output_tokens":6,"latency_ms":1617}`. Shown beside the text version of the same line: one is four queryable fields, the other is a string you would need a regex to sum. As a per-agent callback she wires it onto each of four agents; as a plugin, once on the `App` | `plugins/base_plugin.py` (14 hooks, **4** of them error hooks: `on_model_error_callback`, `on_tool_error_callback`, `on_agent_error_callback`, `on_run_error_callback` — counted from the class on 2.9.0, 2026-09-12); logging tutorial 4.1, 4.4 | focus | 2 |
| 4 | **The two shipped plugins are development tools.** `LoggingPlugin` narrates the loop with `print()` and ANSI codes — it ignores your handlers, levels and formatters, and corrupts a JSON line. `DebugLoggingPlugin` buffers one whole turn into a redacted YAML file at mode 0600 | generic (a print-based library) — **say so** | Deployed as a Cloud Run Job, `LOG_LEVEL=WARNING` silences the framework and the narration keeps going, landing on stdout with Default severity and literal `^[[90m` bytes in the payload. Nothing in it is a field you can filter or alert on | `plugins/logging_plugin.py` (`_log` → `print`), `debug_logging_plugin.py` (0600, `temp:`/credential redaction); logging tutorial 3.2, 3.4 (captured 2026-09-03) | focus | 1 |
| 5 | **Structured logging is where the four streams converge.** One logging config applies a JSON formatter to *every* stream, so the framework's lines and the server's come out shaped like yours: an explicit `severity` field and the request's trace id, written to stdout. Two terms get defined on the page, both standard Python, neither ADK: **`dictConfig`** is `logging.config.dictConfig`, the one call that configures every logger, handler and formatter in the process from a dict — the alternative to `basicConfig` plus per-logger fiddling. **`ContextVar`** is `contextvars.ContextVar`, a variable whose value is scoped to the current task rather than the process, so concurrent requests each see their own; the server sets the trace id into one at the start of a request and the formatter reads it back on every record emitted while that request runs | generic (Cloud Run structured logging) — **say so**; the payoff is agent-shaped: one request is a whole trajectory | Set the trace id into a `ContextVar` once per request. Three lines follow it: your `chat_request_received`, the plugin's `llm_request`, and `google_adk`'s "Sending out request" — a line you never wrote — all carrying the same `logging.googleapis.com/trace`. In Logs Explorer they collapse into one request's story, and `jsonPayload.latency_ms` is now a chartable field | logging tutorial 4.2, 4.3 (captured 2026-09-04); docs.cloud.google.com/run/docs/logging special fields; `logging.config.dictConfig`, `contextvars` (stdlib) | focus | 1 |
| 6 | **Where the level and the format come from, per platform.** Two separate questions, and the answer to each differs by target. **Level:** there is no ADK log-level environment variable — `--log_level` is a flag on `adk web`/`api_server`; `adk deploy cloud_run --log_level` sets *gcloud's* verbosity and the container still runs at INFO; Agent Runtime has no flag; `LOG_LEVEL` is a convention your own code implements. **Format:** whoever installs the logging handler first decides it. You do, in every case except one: on a **native** Agent Runtime deploy (you hand over the agent, the platform runs its own server) the platform installs its handler before your module imports, so your formatter never takes and lines come out in the platform's timestamped `file:line` style. On **BYOC** (you hand over a container running your server) you install the handler, so your format survives. The level is yours in both | **yes**: the model is hosted somewhere you did not write the server for — the config surface changes per target while the agent code does not | Same agent, same `basicConfig`, two engines side by side. Native prints `2026-09-03 21:51:45,037 - INFO - agent.py:53 - tool get_weather called for city='London'`; BYOC prints `INFO - demo_agent.agent - tool get_weather called for city='London'`, the format the code asked for. Both land on `reasoning_engine_stderr` with Default severity | logging tutorial 1.6 (two deploys, captured 2026-09-03); `cli_tools_click.py:2529-2530` (`log_level` → `verbosity`), `_cloud_run_deployer.py:120-121` | focus | 1 |
| 7 | **Reading logs back: Cloud Logging, then a sink to BigQuery, then the plugin.** Log Explorer by `session_id` or `trace`; a sink creates one table per log name and needs `roles/bigquery.dataEditor` on its writer identity; `BigQueryAgentAnalyticsPlugin` is the agent-shaped alternative — one row per lifecycle event with ids, tokens, latency and content | **yes** for the plugin: sessions and per-event rows are managed data with their own retention and access story. The sink itself is generic — **say so** | Support ticket "the agent failed for my order". Filter `jsonPayload.session_id="s-8841"` in Log Explorer, read the conversation in order, find the tool call with malformed input. For "which session cost the most" a sink cannot help: that is `SUM(usage_total_tokens) GROUP BY session_id` over `v_llm_response` | `plugins/bigquery_agent_analytics_plugin.py` (table `agent_events`, `create_views=True`, `enable_otel_correlation`); adk.dev BigQuery Agent Analytics; docs.cloud.google.com sink→BigQuery | tour (sink) + focus (plugin) | 1 |
| 8 | **The instrumentation is in the code; recording and export are two separate switches.** ADK calls `start_as_current_span` around every turn whatever you do — `invocation` → `invoke_agent {name}` → `call_llm` → `generate_content {model}` and `execute_tool {tool}` — but those calls only produce a span if a `TracerProvider` is installed, and the span only leaves the process if that provider has a network exporter. Three states: **nothing installed** → every span is a no-op, dropped; **`adk web`** → installs a provider with two in-memory exporters, which is why the Trace tab works with no flag and why the tree dies on restart; **`--otel_to_cloud` or your own two calls** → the same tree ships to Cloud Trace. The deck's "thought / action" span names do not exist in any state. **Ties back to M2 page 14 explicitly:** its "Turn export on" column is this third state, not the first — a student who read that page can leave thinking spans exist everywhere and the flag only ships them | **yes**: trajectory — the tree *is* the sequence of decisions, and its shape is what a flat log cannot give you | Verified 2026-09-12 on 2.9.0: the same London turn run with no provider installed answers normally, and `trace.get_current_span()` inside it is a `NonRecordingSpan` with trace id `00000000000000000000000000000000` — nothing was recorded, let alone exported. Under `adk web`, seven spans, five names, `execute_tool get_weather` at 1 ms nested under the **first** `call_llm` (the model call that requested it), not under `invoke_agent` | No-provider check `scratchpad/notrace.py` (2026-09-12); `api_server.py:1188-1196` (`adk web` installs `ApiServerSpanExporter` + `InMemoryExporter` always), `:650-666` (three branches); `_instrumentation.py:157,551,588`; tracing tutorial 1.1 | focus | 1 |
| 9 | **Reading a trace: the slow step and the failed step.** A waterfall turns "the agent is slow" into "this tool call is slow". A failed *tool* is not a failed *turn*, and whether a returned failure reaches the trace at all is a choice you make in the tool | **yes**: correctness is multi-dimensional — a green tree and an unmet request coexist, and the model routes around the failure | Forecast turn: `invoke_agent` 4.69 s, two `call_llm` at 2.53 s and 2.16 s, `execute_tool get_forecast` 0.41 s. Atlantis turn: the tool returns `{"status":"error"}`, the span is **UNSET** with no `error.type`, every parent green, and the user is told there is no data | tracing tutorial 1.1, 1.4 (three failure modes, captured 2026-09-07); `functions.py:88` (`_detect_error_in_response` returns `None` on `FunctionTool`) | focus | 2 |
| 10 | **Installing the provider and exporter, per target** — the third state from concept 8, one row per place you deploy. Agent Runtime: `GOOGLE_CLOUD_AGENT_ENGINE_ENABLE_TELEMETRY`, written by `adk deploy agent_engine --otel_to_cloud`; unset resolves to **off** unless the platform sets it. Cloud Run/GKE: `--otel_to_cloud` baked into the container `CMD`. Your own server: `get_gcp_exporters` + `maybe_set_otel_providers`, the two calls the flag makes for you. **The exporter packages are a separate requirement from the flag, and missing them fails differently per target:** Cloud Run and GKE boot-crash at an unguarded import; a native Agent Runtime deploy serves traffic with telemetry silently off, because the Vertex SDK wraps every telemetry import in `try/except` | **yes**: the model is an external dependency whose host owns the telemetry switch; the same agent exports differently per target with no code change | `adk deploy cloud_run --otel_to_cloud` on an image without the extra: the revision crashes at the unconditional Cloud Logging import, and `adk deploy` still exits 0. The curl, not the exit code, is the check. The same omission on a native engine deploys clean, answers turns, and exports nothing — no crash to tell you | `cli_deploy.py:843-844,1277-1286`; `api_server.py:650-719`; `telemetry/google_cloud.py:272` (unguarded); `templates/adk.py:407-417,485-490,540-546` (guarded), `:1798` truth table; tracing tutorial 2.1–2.4 | focus | 2 |
| 11 | **Agent Runtime differs in two more ways.** The root span is `invoke_workflow`, not `invocation` (telemetry schema v2, selected by `GOOGLE_CLOUD_AGENT_ENGINE_ID`), and metric export is driven by the request, not a background timer, because CPU is throttled the instant a response ends | **yes**: the runtime bills per request, so the assumption every OTel batch exporter makes (a daemon thread keeps running) is false | Same agent, same code, two targets: on Cloud Run the trace roots at `invocation`; on Agent Runtime at `invoke_workflow weather_agent`. A `PeriodicExportingMetricReader` there would tick only while a request happens to be in flight, so ADK installs `_RequestDrivenMetricReader` and flushes after the response streams | `telemetry/_schema_version.py:72-91`; `_agent_engine.py:1139-1199`, `_agent_engine_metric_exporter.py`; tracing tutorial 2.4; **live 2.9.0 engine capture 2026-09-12** (`scratchpad/ae_spans.json`: 11 `invoke_workflow weather_agent` roots, `service.name=<engine id>`, `cloud.platform=gcp.agent_engine`) | focus | 1 |
| 12 | **The two content knobs.** `ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS` governs ADK's own spans and defaults **on**. `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` governs the `gen_ai.*` log events, and under the experimental semconv also the `generate_content` span in `SPAN_ONLY`/`SPAN_AND_EVENT`; it defaults **off**. Neither overrides the other, so "content off" is both | **yes**: the trajectory carries user content, and observability quietly becomes a data-retention decision bounded by who can read Cloud Trace | Run 4 of the matrix: ADK knob `true`, OTel knob `NO_CONTENT` → the ticket number `ZQX41` is on `gcp.vertex.agent.llm_request` and absent from every log event. Run 7: ADK `false`, `SPAN_AND_EVENT` → gone from ADK's spans, present on `gen_ai.input.messages` of the instrumentor's span | Eight-run matrix on 2.9.0, 2026-09-12; `telemetry/context.py:108-113,244-274`; `tracing.py:306,336,632`; `_experimental_semconv.py:642` | focus | 2 |
| 13 | **Who sets the knobs for you.** `adk deploy agent_engine --otel_to_cloud` writes the ADK knob `false` only if absent from `.env`; Cloud Run and GKE deploys write nothing and ship the agent folder's `.env` inside the image; no deploy tool touches the OTel variable. On a **native** Agent Runtime deploy the Vertex SDK overwrites the ADK knob at startup regardless. **Notes carry why an `agents-cli` engine escapes this:** it ships a container running the scaffold's own server, so `AdkApp` never runs and never overwrites — the value you set survives, and the outcome only matches because that deploy writes `false` itself | **yes**: same mechanism as 12 — the default differs per target, so a policy you set once is not in force everywhere | A team standardizes on `ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS=false` in `demo_agent/.env`. On Agent Runtime it is redundant (the SDK forces `false` anyway); on Cloud Run it is the only thing stopping prompt text reaching Cloud Trace; on a BYOC engine it is yours again | `cli_deploy.py:1285-1286`; `templates/adk.py:990-996` (`os.environ[...] = "false"` unless legacy `enable_tracing=True`), google-cloud-aiplatform 2.1.0 | focus | 1 |
| 14 | **Joining logs to spans.** A log entry sits under its span when it carries `trace` and `spanId` naming a span in the same project. ADK's `gen_ai.*` events carry them free; your `logging` records do not until you add a bridge, and on Cloud Run the request log and ADK's spans are two different traces unless you propagate | generic (OTel correlation) — **say so**; agent-shaped because the thing you want beside the red span is your tool's own warning | `classified-error` turn: `execute_tool get_weather` is red with `error.type=lookup_failed`, and its **Logs & Events** tab is empty — the tool's WARNING went to the console with no trace id. One `LoggingHandler` on the root logger and the same WARNING appears under the red span | tracing tutorial 3.1–3.5 (captured); docs.cloud.google.com/trace/docs/trace-log-integration; ADK installs no bridge (grep: zero `LoggingHandler`) | focus | 2 |
| 15 | **What ADK measures for free, and which names are stable.** Two families, and the difference is the point. **Stable `gen_ai.*`** (7): `invoke_agent.duration`, `invoke_workflow.duration`, `execute_tool.duration`, `invoke_agent.inference_calls`, `invoke_agent.tool_calls`, plus `client.operation.duration` and `client.token.usage` from the shared semconv helpers. **`adk.experimental.*`** (16 more): every token histogram (input, output, total, cache-read, reasoning, tool) at both agent and workflow grain, skill loads and script executions. The experimental set is **not gated by anything** — it is always emitted; the prefix is a name-stability warning, not a feature flag. Token counts and tool frequency are *not* custom metrics. They arrive under two instrumentation scopes, a live trap when filtering | **yes**: the measurements that matter (tokens, tool calls per turn) exist because the workload is a model loop; `count` and `sum` mean different things per metric | One baseline turn: `invoke_agent.duration` count=1 sum=3.26 s; `client.token.usage` input sum=713 across count=2 model calls; `inference_calls` sum=2 count=1. On `token.usage`, `sum ÷ count` is tokens per **call**, not per turn. **Dashboard trap:** a chart built on `adk.experimental.invoke_agent.input_tokens` is a chart built on a name ADK reserves the right to rename | `telemetry/_metrics.py` re-read on 2.9.0 2026-09-12 (`:67-153` stable, `:141-309` experimental, `_create_token_histogram` at `:213`); metrics tutorial 1.1, 2.2 (captured 2026-09-06 on 2.8.0); adk.dev/observability/metrics | focus | 1 |
| 16 | **Metrics or rows, decided by cardinality.** Bounded attributes (tool, model, error type) belong on metrics; unbounded ids (session, user, invocation) can never be metric attributes and belong in BigQuery rows. ADK records none of them on metrics, by design | **yes**: per-token cost accrues per session and per user, and those are exactly the dimensions a metric may not carry | "Tokens rose 40% this week" is a metric answer. "Which conversation ran up the bill, and what did they ask" is a row answer: `SUM(usage_total_tokens) GROUP BY session_id`, then read `content` on the top invocation's `USER_MESSAGE_RECEIVED` row | metrics tutorial 1.3 (captured), 4.3, 4.6; `_metrics.py` (no session/user attributes) | focus | 1 |
| 17 | **Three different facts on one run: tool error, invocation error, task outcome.** A tool can fail inside a turn that succeeds, and no framework metric says whether the user got what they asked for. One custom counter in an `after_tool_callback` closes the gap, and it is the number to alert on | **yes**: correctness is multi-dimensional and non-determinism means the model routes around failures — execution success and task success are separate facts | `unknown-city` at ~50% Atlantis: tool error ratio ≈ 0.5, invocation error ratio 0, tasks unaccomplished ≈ 0.5. An alert on the tool ratio pages for turns every user got an answer to; an alert on the outcome counter pages for the ones they did not | metrics tutorial 3.3, 3.6, 3.7 (3.3 captured; 3.6/3.7 drafted — tag `illustrative`); `queries/errors.promql`, `outcome.promql` | focus | 2 |
| 18 | **Tokens per call as the cost signal.** Input tokens climb across a session as context accumulates while output stays flat; the average over a run hides the climb. Cost per session comes from rows | **yes**: per-token cost grows with context — the one cost curve that is a property of the agent loop rather than the traffic | `growing-context`, 20 turns in one session: input tokens per call rise turn over turn, output per call flat. The mean over the whole run reports one middling number. Read `rate(…_sum) / rate(…_count)` over a short window instead | metrics tutorial 3.4 (drafted — tag `illustrative`); `queries/tokens.promql`; Module 6 picks up cost | focus | 1 |
| 19 | **The tour.** Cloud Logging (Observability Analytics is the new name; needs an upgraded bucket), Cloud Trace, Cloud Monitoring, BigQuery, Data Studio (Looker Studio reverted to Data Studio in April 2026). One line each plus the one specific that matters for agents | generic — **say so** | The specific for each: filter logs by `session_id`; read the waterfall, not the total; alert on a PromQL ratio; group rows by an unbounded id; share the report, not the dataset that holds prompt text | docs.cloud.google.com Observability Analytics, Data Studio welcome (both re-verified 2026-09-12) | tour | 1 |

**Total content pages: 24** (+ opener, objectives, 3 section dividers, 3 recaps, consequences, references = **10 structural**) → **34 pages, ≈60 min** against a 50-min budget.

**Jeff, 2026-09-12: a couple of pages over is fine.** Keeping 24 content pages, and keeping concept 5
(the two terms it defines are the reason it exists) and concept 3 at two pages (the JSON-vs-text
contrast needs both). The one page I would still drop if the room runs slow is **concept 19's
dedicated tour page** — every service can be named where it is first used, and that is a cut you
can make live by skipping one page rather than a cut that has to happen now. Nothing else comes
out; 9, 12 and 17 carry the module.

## Order and why

The spine is **what an agent emits → how you turn it on where it runs → what you ask of it**.

Section 1 (logging, concepts 1–7) opens with the four streams because every later confusion is a
stream mix-up, and because it disposes of slide 8's invented event names in the first beat. What
ADK does on its own (2) comes before what you add (3, 4) so "write your own" is a decision rather
than a default. Structured logging (5) is the convergence point and therefore has to follow both.
Configuration per platform (6) needs streams *and* the plugin idea already in place, because the
question it answers is "which of these can I set from where." Consumption (7) closes the section
and plants `session_id`, which section 3 reuses.

Section 2 (tracing, concepts 8–14) starts by separating instrumentation from recording from export
(8), because that three-way split is what makes the rest of the section legible: `adk web` shows a
tree with no flag, a script shows nothing at all, and the flag is about neither instrumentation nor
recording but about where the tree goes. Reading (9) comes before configuring (10) so the student
knows what they are turning on. Agent Runtime's
two differences (11) need the tree from 8 and the flag from 10. The content knobs (12, 13) come
last in the section because they only make sense once you know there are ADK spans, instrumentor
spans, and log events to put content on — and 13 is a separate page because "who sets it for you"
is the part that bites. Correlation (14) closes by joining section 2 back to section 1.

Section 3 (metrics, concepts 15–18) needs the `gen_ai.*` vocabulary from 8 and 10. Free metrics
(15) → the cardinality rule that forces the metrics/rows split (16) → the three error facts (17),
which needs 16 because the outcome counter is the thing metrics *can* do → tokens (18), which
needs 16 because cost per session is the row answer. 17 before 18 so the section ends on the cost
signal that hands off to Module 6.

## Cut from the source, and why

- **Slides 2–6, 16, 23, 33** (objectives, topics ×3, three signals, architecture ×2, pattern) —
  five of these are navigation. The three-signals slide survives as one row of the opener's frame;
  the two architecture slides are replaced by the concrete path in concept 8 and 10's diagrams.
- **Slide 8's lifecycle event names** — they do not exist. Replaced by the real span names (8),
  with the correction stated out loud once and in notes.
- **Slides 19–20** (callback logging code, two slides) — collapsed into concept 3's one block. The
  deck's `before_model_callback` / `after_model_callback` pair is the per-agent option, shown as
  the contrast case against the plugin, not as the recommendation.
- **Slide 25's claim** that the OTel variable controls prompt capture and content is redacted by
  default — half right, and the half that is wrong is the dangerous half (ADK's spans default on).
  Rewritten as concept 12.
- **Slide 27** (Cloud Trace capabilities) — repeats slide 11. One row of the tour.
- **Slide 29's table** (Agent Runtime "automatic" vs Cloud Run "flag") — both need a switch.
  Rewritten as concept 10.
- **Slide 30's `get_fast_api_app` call** — raises `TypeError` (`web=` is required). Corrected
  inline on the code page.
- **Slide 31** (custom span) — one code block inside concept 9's page, not a page. Per the brief.
- **Slide 32** (callback vs OTel table) — the "impact: runs in request thread / non-blocking
  async" row is wrong in both directions (callbacks may be async; on Agent Runtime OTel export is
  request-driven, not background). The real distinction — plugins and callbacks can change
  behavior, OpenTelemetry only records — goes in concept 3's note.
- **Sampling, third-party OTLP backends, the agents-cli prompt-response tier** — per the brief,
  notes only.

## Verified since the first draft

- **Concept 8 was wrong in its first form** ("ADK opens spans around every turn with no
  configuration"). That is true of `adk web`, which always installs a provider plus two in-memory
  exporters, and false of an agent in general: with no provider installed every span during a real
  turn is a `NonRecordingSpan` with an all-zeros trace id. Rewritten as the three states. Jeff
  caught this; the tracing tutorial's "you are not switching tracing on, it is on" framing is
  `adk web`-specific and should be read that way.

## Resolved since the concept list was written

- **M2 page 14 is reconciled.** Analysis in
  [`m2_m3_telemetry_reconciliation.md`](m2_m3_telemetry_reconciliation.md); the four M2 edits are
  applied and rendered, and the three M3 rows (concepts 8, 10, 13) are folded into the table above.
  Two defects were real and both were on M2's slide face, not in its notes.
- **Concept 11's Agent Runtime destination — RESOLVED, re-run on 2.9.0, 2026-09-12.** Throwaway
  engine `773472895035768832` in `jwd-gcp-demos/us-central1`, five turns, **60 spans across 12
  traces in Cloud Trace**. Traces export. The deck can now state this as observed, not documented.
  Captured spans: `scratchpad/ae_spans.json`. What the run confirms, all on a live engine:
  - **The tree and its root.** `invoke_workflow weather_agent` → `invoke_agent` → `call_llm` →
    `generate_content {model}`, with **`execute_tool` nested under the `call_llm` that requested
    it**, not under `invoke_agent` (concept 8's example, now verified on Agent Runtime too).
    `invoke_workflow` as root confirms schema v2 (concept 11).
  - **Two instrumentation scopes in one tree**: `gcp.vertex.agent` 2.9.0 owns 47 spans,
    `opentelemetry.instrumentation.google_genai` 0.7b1 owns the 12 `generate_content` spans
    (concept 15's filtering trap, live).
  - **Both content knobs off, by default.** Every `llm_request`, `tool_call_args`, `tool_response`
    is `{}`; no `gen_ai.input.messages` anywhere. Concept 12's "content off is both" is what a
    default native deploy actually produces.
  - **A number for concept 15's notes:** `call_llm` reports `output_tokens=69` with
    `reasoning.output_tokens=48`, while its child `generate_content` reports `output_tokens=21`.
    Same model call, two different output-token numbers, because ADK's span counts reasoning
    tokens and the instrumentor's does not.
  - **Read-back gotcha worth a notes line:** the legacy Cloud Trace **v1** API does not return
    these spans; I queried it and wrongly reported "no traces." Spans carry
    `service.name=<engine id>` and `cloud.platform=gcp.agent_engine` on the resource.
  - Two deploy mechanics corrected along the way: `adk deploy agent_engine` stages
    **`<agent_dir>/requirements.txt`** (inside the agent folder; one beside it is ignored and the
    generated Dockerfile installs only base `google-adk`), and it does **not** rewrite an existing
    `google-adk[otel-gcp]` line. And `--region` overrides `GOOGLE_CLOUD_LOCATION`, so a regional
    engine 404s on a global-only model — fixed per-model with
    `Gemini(model=…, client_kwargs={"location": "global"})`, as
    `gcp-demos/ai/adk/metrics/demo_agent/agent.py` already does.
  - **Still open, and the deck should not claim otherwise:** why your 2.8.0 run found no logs.
    Traces are answered; the log question is not.

- **Concepts 17 and 18 — captured 2026-09-12, no longer illustrative.** Ran `unknown-city 40`
  and `growing-context 20` locally (adk 2.8.0, `adk web --otel_to_cloud`, `jwd-gcp-demos`).
  Concept 17's three numbers: tool error ratio **0.476**, invocation error ratio **0**, tasks
  unaccomplished **0.476**, counter coverage **1.0**. Concept 18's curve: input per call
  **366 → 1720** (4.7×) across 20 turns while output held at **14–15**; 72,308 input tokens
  against 1,735 output over 120 model calls. The `NEEDS-RUN` blocks in `gcp-demos` metrics 3.4
  and 3.7 are filled in, and the run found a bug there: the counter is
  `tutorial.weather.requests` with **no `_total` suffix**, so the documented query returned zero
  series and no error. Fixed in the page and in `queries/outcome.promql`.

## Open questions for Jeff

None outstanding.
