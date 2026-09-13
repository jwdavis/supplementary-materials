# M2 page 14 vs M3 concepts 8, 10, 12, 13 — who is right

Written 2026-09-12 for Jeff's review. Nothing has been changed in either deck yet.

**Baseline for every verdict below:** google-adk **2.9.0** (`v2.9.0`), google-cloud-aiplatform
**2.1.0** (the `vertexai.agent_engines.templates.adk` module that runs a native Agent Runtime
deploy), google-agents-cli 1.5.0. Evidence is either a source line at that version, or one of two
recorded runs on 2.9.0 against a real Gemini model:

- **the knob matrix** — eight turns, one per content-knob combination, console span and log
  exporters, needles for the user's text and the reply text (`scratchpad/knobs.py`, 2026-09-12)
- **the no-provider check** — one turn with no `TracerProvider` installed at all
  (`scratchpad/notrace.py`, 2026-09-12)

Headline: **M2 page 14 holds up well.** Its speaker notes are more accurate than I claimed when I
flagged this. There are two real defects, both on the slide face rather than in the notes, plus one
place where M2 and M3 are both right and would still confuse a student who sees them a day apart.
M3 has one defect of its own that this comparison caught.

---

## 1. The `SPAN_ONLY` / `SPAN_AND_EVENT` behavior

**M2 face** (blue note, "The three content variables"):

> `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=EVENT_ONLY` puts them in the GenAI log events
> instead of `<elided>`.

**M2 notes** (bullet 4):

> `EVENT_ONLY` and `SPAN_AND_EVENT` fill the `gen_ai.*` log events; `SPAN_ONLY` and
> `SPAN_AND_EVENT` put content on the `generate_content` span only under the semconv opt-in; unset
> or unrecognised means `NO_CONTENT`; `true` is a back-compat alias for `EVENT_ONLY`.

**M3 concept 12:** the OTel variable governs the log events and, under the experimental semconv,
also the `generate_content` span in the two span-bearing modes.

**Verdict: M2's notes and M3 agree, and both are right. M2's face is incomplete, not wrong.**
The face mentions only `EVENT_ONLY`, so a student reading the slide alone would conclude the
variable never touches a span — which is the same wrong conclusion I drew from the M2 map before
running the matrix.

Evidence, matrix run 8 (`SPAN_ONLY`, experimental semconv, ADK knob unset):

| Span | Attribute carrying text |
|---|---|
| `generate_content gemini-3.7-flash` | `gen_ai.input.messages`, `gen_ai.output.messages` |
| `call_llm` | `gcp.vertex.agent.llm_request`, `llm_response` (from the *ADK* knob's default-on) |

and run 7 (`SPAN_AND_EVENT` with the ADK knob explicitly `false`): content **gone** from
`call_llm`, still **present** on `generate_content`. Source: `_experimental_semconv.py:642`
(`should_add_content_to_experimental_spans`) against `tracing.py:306,336,632`
(`should_add_content_to_legacy_spans`).

**Fix:** one clause on M2's face — "…and, under the semconv opt-in, `SPAN_ONLY` / `SPAN_AND_EVENT`
put it on the `generate_content` span." Notes need no change.

---

## 2. The `AdkApp` overwrite on native Agent Runtime

**M2 face**, row 1 ("Content in the export, by default" for `adk deploy agent_engine`):

> ADK span attributes **off** — the deploy writes `false` unless `.env` sets it.

**M2 notes** (bullet 5): the deploy "fills a gap in the file and never overrides a value in it.
Setting `true` in `.env` is therefore honoured." Bullet 7 then says, of the SDK path: "`AdkApp`
forces `ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS=false` unless the deprecated `enable_tracing=True` is
passed."

**M3 concept 13:** on a native deploy the SDK overwrites the knob at startup regardless of what the
deployment environment carries.

**Verdict: M2's face is wrong for the native path, and its two notes bullets contradict each
other.** Bullet 5 is right about what `adk deploy` writes into the deployment. Bullet 7 is right
about what happens at runtime. Both are true and they have opposite consequences, and neither
bullet says which one the student will actually observe.

The runtime wins. `AdkApp.set_up` runs inside the deployed container on every start, before the
agent serves anything:

```python
# google-cloud-aiplatform 2.1.0, vertexai/agent_engines/templates/adk.py:990-996
if self._tmpl_attrs.get("enable_tracing"):
    os.environ["ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS"] = "true"
else:
    os.environ["ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS"] = "false"
```

That is an unconditional assignment to `os.environ`, not a `setdefault`. ADK reads the variable per
turn (`context.py:176-183`, every `TelemetryConfig` resolves its env fallbacks at construction), so
the value the container starts with is the value every turn sees. Setting `true` in `.env` is
honoured *by the deploy* — it lands in the deployment environment, `gcloud`/the SDK will show it —
and then overwritten in process. The only way to get `true` on a native deploy is the deprecated
`enable_tracing=True`, which the SDK warns about and which is being removed.

**Scope of the correction:** native Agent Runtime only. On Cloud Run, GKE, BYOC, and any runtime you
wrote, nothing overwrites the variable and M2's face is correct as written.

**Fix:** M2 row 1 gains a qualifier — span attributes off **and not settable to on** on a native
deploy, because the SDK forces `false` at startup; `.env` decides on Cloud Run and GKE. Notes
bullets 5 and 7 should be joined so the deploy-time and runtime facts sit in one place.

---

## 3. "Turn export on" and what a student thinks that means

**M2 face**, column 2 heading: *Turn export on*, with the custom-runtime row reading "Your startup
code installs the exporters and the global OpenTelemetry providers".

**M3 concept 8** (as revised 2026-09-12): instrumentation, recording, and export are three states,
and with nothing installed ADK records nothing at all.

**Verdict: both correct, and together they mislead.** M2 is precise about the custom-runtime row.
But a student who has seen M2's page and then hears M3 say "`adk web` is already tracing with no
flag" can reasonably conclude that spans exist everywhere and the flag only ships them — which is
false off `adk web`.

Evidence, the no-provider check: the same London turn, no provider installed, answers normally, and
`trace.get_current_span()` inside the run is a `NonRecordingSpan` with trace id
`00000000000000000000000000000000`. Nothing recorded, nothing to export. `adk web` looks different
only because it always installs a provider plus two in-memory exporters
(`api_server.py:1188-1196`), which is what its Trace tab reads.

**Fix:** no change to M2. M3 concept 8 already carries the three states; its page should say
explicitly that the M2 "turn export on" switch is the third state, not the first.

---

## 4. `agents-cli` to Agent Runtime — does the scaffolded server change the answer?

**M2 face**, row 2: the scaffolded server reads `ENABLE_TELEMETRY` and passes `otel_to_cloud` to
`get_fast_api_app`; content off both ways, written by the deploy.

**Verdict: M2 is right, and this row is the one that makes §2 tolerable.** An `agents-cli`
Agent Runtime deployment runs the scaffold's own FastAPI server in a container, not the SDK's
`AdkApp` wrapper, so `AdkApp.set_up` never runs and never overwrites the knob. The Terraform
default writes `false` explicitly, which is why the outcome matches anyway.

So the overwrite in §2 applies to the **native SDK/`adk deploy agent_engine`** path only, and M2's
rows 1 and 2 differ for a real reason rather than by accident. Worth one sentence in M3's notes so
the two rows do not look like a contradiction.

---

## 5. Where M3 is wrong, caught by this comparison

**M3 concept 10** says an `adk deploy cloud_run --otel_to_cloud` image "needs `google-adk[otel-gcp]`
or it boot-crashes". That is right for the *Cloud Run* path — the Cloud Logging exporter import at
`telemetry/google_cloud.py:272` is unguarded, and the tracing tutorial's 2.2 records exactly that
crash.

But M3's concept 10 row for **Agent Runtime** inherits the same sentence, and there the failure mode
is different: the SDK's `_default_instrumentor_builder` wraps every telemetry import in
`try/except (ImportError, AttributeError)` and degrades with a warning
(`templates/adk.py:407-417, 485-490, 540-546`). A native deploy missing the exporter packages does
not crash; it serves traffic with telemetry silently off. That is a worse failure for an operator
and a better teaching beat, and M3 currently flattens the two into one claim.

**Fix:** split the claim by target in M3's page. Cloud Run and GKE crash loudly; native Agent Runtime
degrades quietly.

---

## 6. The 2.9.0 re-run: traces export, and the read-back was the problem

**Run on 2026-09-12.** Throwaway engine `773472895035768832` in `jwd-gcp-demos/us-central1`,
`adk deploy agent_engine --otel_to_cloud`, adk 2.9.0. Five turns. **Traces export fine.** 60 spans
across 12 traces, read out of Trace Explorer.

Two things I had wrong, both now corrected above:

| Was | Actually |
|---|---|
| `adk deploy agent_engine` rewrites `[otel-gcp]` to `[a2a]` | It only **appends**; an existing `google-adk[otel-gcp]` line is untouched (`cli_deploy.py:153-177`) |
| A native deploy runs the Vertex SDK's `AdkApp`, so logs land under `adk-on-agent-engine` | It runs the **ADK CLI's `api_server`**. Container stderr shows `api_server.py` warnings and `_setup_gcp_telemetry`'s code path, not the SDK builder |

The second one matters: the `adk-on-agent-engine` log-name story does not apply to
`adk deploy agent_engine` at all. It belongs to an **SDK** deploy (`AdkApp(...)` passed to
`agent_engines.create`), which is a different path. So the 2.8.0 log miss is still open, and the
honest framing for the deck is the one below, not a log-name explanation.

**What the deploy writes** (read off the live resource):

```
GOOGLE_CLOUD_AGENT_ENGINE_ENABLE_TELEMETRY = true     <- --otel_to_cloud
ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS       = false    <- .env did not set it
```

**The tree, one real turn** (`invoke_workflow` root confirms schema v2, concept 11):

```
invoke_workflow weather_agent        6.13s  [gcp.vertex.agent]
  invoke_agent weather_agent         5.98s  [gcp.vertex.agent]
    call_llm                         2.91s  in=366 out=69 (reasoning=48)
      generate_content gemini-3.7-flash  1.46s  [instrumentation.google_genai]  in=366 out=21
      execute_tool get_forecast      1.15s  [gcp.vertex.agent]
    call_llm                         3.06s  in=499 out=48 (reasoning=23)
      generate_content …             2.91s  [instrumentation.google_genai]
```

Confirms, on a live engine, three things the deck asserts: `execute_tool` nests under the
**`call_llm`** that requested it (concept 8), the two instrumentation scopes sit in one tree
(concept 15), and `call_llm`'s output tokens include reasoning tokens the `generate_content` span
does not count (worth a note on concept 15).

**Both content knobs verified off:** every `gcp.vertex.agent.llm_request`, `tool_call_args` and
`tool_response` is `{}` (ADK knob `false`, per the deploy), and no `gen_ai.input.messages` or
`output.messages` appears anywhere (OTel knob unset → `NO_CONTENT`). Concept 12's "content off is
both" is exactly what a default native deploy produces.

**Reading it back.** Trace Explorer, filtered on the engine. The Cloud Trace **v1** API
(`cloudtrace.googleapis.com/v1/projects/*/traces`) does **not** return these spans — I queried it
first and wrongly concluded there were none. Spans exported through `--otel_to_cloud` carry
`service.name = <engine id>` and `cloud.platform = gcp.agent_engine` on the resource; filter on
those.

### Still open: the 2.8.0 logs

Metrics landed (metrics tutorial 2.5, positive). Traces export on 2.9.0, shown above. Whether the
2.8.0 log miss was a version difference, a query, or indexing is not answered by this run, and the
deck should not claim it is. Concept 11 states the tree and the export switch, both now observed.

### Getting a clean answer on 2.9.0

One deploy. Five things the 2.8.0 attempt did not have together:

| | What | Why |
|---|---|---|
| 1 | Exporter packages listed in **`<agent_dir>/requirements.txt`** — the file *inside* the agent folder | `adk deploy agent_engine` stages that file; a `requirements.txt` beside the agent folder is ignored, and the generated Dockerfile installs only base `google-adk` |
| 2 | `--otel_to_cloud` on the deploy | writes `GOOGLE_CLOUD_AGENT_ENGINE_ENABLE_TELEMETRY=true`, the export switch |
| 3 | `Gemini(model=…, client_kwargs={"location": "global"})` in the agent | `--region` overrides `GOOGLE_CLOUD_LOCATION`, and the deploy region must be real while the model is served only on `global` |
| 4 | Read logs by **resource**, not log name: `resource.type="aiplatform.googleapis.com/ReasoningEngine"` | this is the query that was wrong last time |
| 5 | Read traces by **`service.name=<engine id>`**, and wait for indexing | span names alone will not find them |

**Row 1 corrects an earlier claim in this file.** I had written that `adk deploy agent_engine`
"rewrites the `[otel-gcp]` extra to `[a2a]`." It does not. `_ensure_agent_engine_dependency`
(`cli_deploy.py:153-177`) only **appends** `google-cloud-aiplatform[adk,agent_engines]` and
`google-adk[a2a]==<version>`, and only when no line already starts with `google-cloud-aiplatform`.
An existing `google-adk[otel-gcp]` line is never touched, and pip installs the union of the extras.
Tested against 2.9.0 on three requirements files, 2026-09-12.

That matters because it removes the leading explanation for the missing traces: your 2.8.0
`metrics/demo_agent/requirements.txt` lists all four exporters explicitly, so the image had them.

---

## Summary of edits — **applied 2026-09-12** on Jeff's go-ahead

| Deck | Page | Change | Severity | Status |
|---|---|---|---|---|
| M2 | 14 face, blue note | Add the `SPAN_ONLY`/`SPAN_AND_EVENT` clause | incomplete, not wrong | applied |
| M2 | 14 face, row 1 | Native AE: span content is off **and not settable on**; `.env` decides on Cloud Run/GKE | **wrong as written** | applied |
| M2 | 14 notes, bullets 5 + 7 | Merge; state deploy-time vs runtime in one place, and that runtime wins | contradictory | applied |
| M2 | 14 notes, agents-cli bullet | Why rows 1 and 2 differ: the scaffold's server means no `AdkApp`, no overwrite | clarity | applied |
| M3 | concept 8 | Say explicitly that M2's "turn export on" is the third state | clarity | applied |
| M3 | concept 10 | Split the missing-package failure by target: Cloud Run crashes, native AE degrades silently | **wrong as written** | applied |
| M3 | concept 13 | One sentence on why `agents-cli` → AE is unaffected by the overwrite | clarity | applied |
| M3 | concept 11 | Replace the open question with the 2.9.0 re-run result | open | see §7 |

M2 page 14 renders clean after the edits (checked 2026-09-12). The M3 rows are edits to the concept
list, which is still at its review gate; they become page edits when the deck is written.

No edit here changes a takeaway line in either deck. M2's takeaway ("export is a flag on
`adk deploy`, a variable the scaffolded server reads on `agents-cli deploy`, and four lines of
startup code in a runtime you wrote") survives all of it.
