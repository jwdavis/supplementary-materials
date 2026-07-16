# ADK Course Delta Review: Existing Content vs. ADK 2.4.0 (July 2026)

**Scope:** the five course modules (slide decks in `~/Downloads/Agent Development Kit - Module 1–5`) and the five labs (scbl140, scbl141, scbl132, scbl143, scbl148), compared against ADK Python **2.4.0** (released July 7, 2026), the GitHub release notes, and the current docs at adk.dev.

> [!NOTE]
> **How to read the vintage tags.** The course's effective baseline is ADK ~1.26 (Feb 26, 2026; the labs pin 1.22.1–1.30.0). Every delta below carries one of three tags (versions verified against the adk-python CHANGELOG and released wheels):
>
> | Tag | Meaning |
> |---|---|
> | 🔵 `pre-1.26` | Already true when the course was current. Not a 2.x delta — the content was stale on its own baseline. |
> | 🟣 `late 1.x` | Changed in 1.27–1.34 (Mar–May 19, 2026). Applies even to a course that stays on 1.x. |
> | 🟠 `2.x` | Specific to ADK 2.0 (May 19, 2026) and later. |

## Contents

- [Executive summary](#executive-summary)
- [Part 1: The big conceptual shifts](#part-1-the-big-conceptual-shifts)
- [Part 2: Renames, rebrands, and small API deltas](#part-2-renames-rebrands-and-small-api-deltas)
- [Part 3: Module-by-module assessment](#part-3-module-by-module-assessment)
  - [Module 1: Introducing ADK](#module-1-introducing-adk) — includes the [ten-capability inventory](#the-modern-what-does-adk-include-inventory)
  - [Module 2: Develop Agents with ADK](#module-2-develop-agents-with-adk)
  - [Module 3: Build Multi-agent Systems with ADK](#module-3-build-multi-agent-systems-with-adk) — includes the [four workflow-slide walkthroughs](#the-four-workflow-agent-slides-scenario-by-scenario-in-2x)
  - [Module 4: Deploy ADK Agents to Agent Runtime](#module-4-deploy-adk-agents-to-agent-runtime)
  - [Module 5: Evaluate ADK Agent Systems](#module-5-evaluate-adk-agent-systems)
- [Part 4: Lab-by-lab assessment](#part-4-lab-by-lab-assessment)
- [Part 5: Capabilities the course doesn't mention](#part-5-capabilities-the-course-doesnt-mention)
- [Part 6: Suggested refresh priority](#part-6-suggested-refresh-priority)
- [Part 7: Source-verified findings from deck development](#part-7-source-verified-findings-from-deck-development)
- [Appendix: quick-reference delta table](#appendix-quick-reference-delta-table)

---

## Executive summary

1. **ADK 2.0 went GA on May 19, 2026**
   - Current release: 2.4.0, on a roughly bi-weekly cadence. The course content targets ADK 1.x.
2. **The labs are in better shape than the slides**
   - Labs were revised April–July 2026 and pin mid/late 1.x versions (1.22.1–1.30.0) using patterns that carry forward cleanly into 2.x (`App` + plugins, `run_async`, `StdioConnectionParams`).
   - They still work; the risk is that several patterns they teach are now formally deprecated.
3. **The slides are a half-refresh**
   - Branding was updated (Agent Runtime, Gemini Enterprise Agent Platform) but the code was not.
   - Module 4 still deploys a LangChain agent with `reasoning_engines.LangchainAgent`; Module 5 teaches the legacy eval file format and a pre-ADK env var (`AF_TRACE_TO_CLOUD`).
4. **The single biggest conceptual delta is the ADK 2.0 Workflow engine**
   - `SequentialAgent`, `ParallelAgent`, and `LoopAgent` — the entire backbone of Module 3 — are now deprecated in favor of a graph-based `Workflow` class.
   - Every agent is now a *node* in an execution graph.
5. **One lab is out of scope**
   - scbl132 (VAISC-07) is a Vertex AI Search for commerce / Retail API notebook lab. It contains no ADK content and is unaffected by ADK versioning.
6. **Not every gap is a 2.0 gap**
   - A large share of the "modern ADK" inventory shipped during 1.x, much of it before the course's own baseline.
   - 🔵 Already available at the baseline: plugins and the `App` container (by 1.15), context caching (1.15), events compaction and pause/resume (1.16), the `McpToolset` casing (1.17), API-key/express-mode deploys (1.18), `adk conformance` (by 1.19), `adk optimize` (1.18–1.20), the Interactions API (1.21), user simulation (1.18–1.22), and skills (1.25).
   - 🟠 Genuinely 2.x-specific: the Workflow engine, the Task API, the workflow-agent deprecations, the Python 3.10 floor, the `[mcp]` packaging split, the google-genai v2 bump, `GOOGLE_GENAI_USE_ENTERPRISE`, `--trigger_sources`, and `ManagedAgent`.

---

## Part 1: The big conceptual shifts

*What to explain to students differently.*

### 1.1 Workflow graphs replace workflow agents

This is the headline of ADK 2.0 and the largest teaching delta.

**What the course teaches (Module 3):** orchestration is done with three workflow-agent classes — `SequentialAgent`, `ParallelAgent`, `LoopAgent` — plus custom workflow agents for anything conditional or dynamic.

**Current reality:** all three classes still function in 2.4.0 but carry `@deprecated` warnings ("in favor of Workflow… will be removed in a future version"). The replacement is a single graph primitive:

```python
from google.adk import Agent, Workflow

root_agent = Workflow(
    name="root_agent",
    edges=[("START", agent_a, agent_b)],          # sequential
    # ("START", a, (b, c))                        # fan-out (parallel)
    # ("START", a, {"route_x": b, "route_y": c})  # conditional routing
)
```

Key properties of the new engine:

- **Two main classes**
  - The README now describes ADK as built on `Agent` and `Workflow` (and `Workflow` is a top-level export alongside `Agent`, `Context`, `Event`, and `Runner`).
- **Anything can be a node**
  - Agents, plain Python functions (`FunctionNode`, `@node`), tools, or nested workflows.
  - `JoinNode` handles fan-in; `max_concurrency` throttles fan-out; per-node `RetryConfig` handles retries.
- **Cycles are allowed but must be conditional**
  - The `LoopAgent` use case becomes a conditional cycle in the graph.
- **Data flows as typed `event.output` values**
  - Replaces manual session-state plumbing, which changes how you teach the "share results via `output_key` / state" pattern.
- **Human-in-the-loop interrupts**
  - Deterministic pause/resume is built into the engine.
- **Caveats worth teaching honestly**
  - `Workflow` cannot yet be used as a sub-agent of an `LlmAgent` (which is why the old classes have not been removed).
  - Live/BiDi streaming is not supported inside workflows.

**How to frame it for students:** the mental model moves from "special container agents that run children in a fixed pattern" to "a directed graph where the edges define sequence, parallelism, and routing." Module 3's slide on *when to build a custom workflow agent* (conditional logic, dynamic agent selection, unique patterns) describes exactly the cases `Workflow` now handles natively with dict-edges and `ctx.run_node()`.

### 1.2 Every agent is a node; custom run overrides are bypassed

In 2.0, `BaseAgent` subclasses `BaseNode`.

> [!IMPORTANT]
> Custom agents that override `_run_async_impl()` are **silently bypassed** by the new engine — no error, the custom logic just never runs. The documented migration for *orchestration* logic is the graph/dynamic **Workflow** engine (the custom-agents doc says to evaluate those "before building a custom agent"); a custom agent's control flow typically becomes a function router node plus dict edges. `before_agent_callback` / `after_agent_callback` remain the hooks for *per-agent* logic (setup, validation, guardrails), but they are not a control-flow replacement. If any course material suggests subclassing an agent and overriding its run method for custom orchestration, that pattern is dead in 2.x.

Two related contract changes:

- **Events must be yielded, not appended**
  - Directly appending via `context.session.events.append()` breaks workflow determinism and replay.
- **Do not swallow exceptions broadly**
  - A `try/except BaseException` traps `NodeInterruptedError` and breaks pause/resume and automatic retries.
  - The pattern now is to let exceptions propagate and use `RetryConfig`.

### 1.3 The Task API: agents get a mode

New `LlmAgent` field `mode: 'chat' | 'task' | 'single_turn'`:

| Mode | Behavior |
|---|---|
| `chat` (default) | The 1.x behavior: conversational agent, valid transfer target. |
| `task` | A goal-oriented agent exposed to its parent *as a tool*. Runs its own loop until it calls an auto-injected `finish_task` tool, validates its output against `output_schema` (with automatic retry on validation failure), and can pause to ask the user something and resume. Cannot be a `transfer_to_agent` target. |
| `single_turn` | Stateless one-shot, also exposed as a tool. |

This formalizes and largely supersedes the manual `AgentTool` wrapper pattern that Lab scbl141 teaches as the workaround for mixing `VertexAiSearchTool` with other tools. `AgentTool` still exists, but "delegate to a sub-agent as a tool" now has a first-class answer.

### 1.4 Session compatibility is a real operational break

Sessions written by ADK 2.0 are readable by ADK 1.28+ (extra fields ignored) but **incompatible with older 1.x**.

- 🟣 `late 1.x` — the forward-compat event-schema fields (`output`, `node_info`, `isolation_scope`, routing/requested-input data) went into 1.28.
- 🟠 `2.x` — the compatibility break itself.
- 🔵 `pre-1.26` — the migration CLI predates all of this (`adk migrate session` shipped with the JSON DB schema in 1.22, Jan 2026):

```bash
adk migrate session --source_db_url ... --dest_db_url ...
```

Worth a mention in any deployment/production module: upgrading ADK under a `DatabaseSessionService` is now a schema migration event, not just a pip upgrade.

---

## Part 2: Renames, rebrands, and small API deltas

*The things students will hit immediately, and the easiest wins for a content refresh.*

| Course says | ADK 2.4.0 reality | Vintage and notes |
|---|---|---|
| `GOOGLE_GENAI_USE_VERTEXAI=TRUE` | `GOOGLE_GENAI_USE_ENTERPRISE` | 🟠 `2.x` Renamed in 2.3.0 (Jun 2026); old name still works with a deprecation warning. All five ADK labs and the Module 2 `.env` slide use the old name — correct for their vintage. |
| `MCPToolset` | `McpToolset` | 🔵 `pre-1.26` Renamed by 1.17 (Oct 2025); the old casing was already a deprecated alias at the course baseline. Same for `MCPTool` → `McpTool`. Lab scbl148 uses the old casing. |
| `SseServerParams` (scbl148 prose) | `SseConnectionParams`, plus `StreamableHTTPConnectionParams` | 🔵 `pre-1.26` The connection-params renames are mid-1.x; Streamable HTTP shipped in 1.11 (Aug 2025) and is the modern remote-MCP transport to teach. |
| MCP support is built in | MCP is an optional extra: `pip install "google-adk[mcp]"` | 🟠 `2.x` `mcp` was a core dependency through 1.34; it became an extra at 2.0.0 (verified in wheel metadata). |
| Python 3.9+ (Module 2 install slide) | Python 3.10+ | 🟠 `2.x` Floor raised in 2.0. Pydantic ≥2.12 required. |
| API server "uses Flask, on port 8000" (Module 2) | FastAPI/uvicorn | 🔵 `pre-1.26` Wrong for all of 1.x, not a version delta; port 8000 is still the default. |
| "A client-side, Python SDK" (Module 1) | Multi-language: Python, Go, Java, Kotlin, TypeScript | 🔵 `pre-1.26` The other language SDKs already existed in the 1.x era; the adk.dev docs move is 🟠 `2.x`. |
| Docs at google.github.io/adk-docs (lab links) | https://adk.dev/ | 🟠 `2.x` Lab scbl140 links to the old runtime docs URL. |
| `SequentialAgent` / `ParallelAgent` / `LoopAgent` | Deprecated in favor of `Workflow` | 🟠 `2.x` Deprecated at 2.0.0. Still functional; warnings fire. |
| Agent Config YAML (`from_config`) | Deprecated, being removed | 🟠 `2.x` Not taught in this course; only relevant if students ask. |
| `adk web`, `adk run`, `adk api_server`, `adk eval` | All still exist; CLI grew: `adk create`, `adk optimize`, `adk conformance record/test`, `adk migrate session`, `adk eval_set create/add_eval_case/generate_eval_cases` | 🔵 `pre-1.26` All of these subcommands are 1.x-era: `adk create` since 0.2, `adk conformance` by 1.19 (Nov 2025), `adk optimize` 1.18–1.20 (Nov–Dec 2025), `adk migrate session` 1.22 (Jan 2026). |
| Manual project scaffold (folder + `__init__.py` + `agent.py` + `.env`) | Same structure, but `adk create` generates it | 🔵 `pre-1.26` `adk create` predates the course entirely (0.2). The `root_agent` convention is unchanged; showing `adk create` saves lab time. |

### Model guidance

| Where | Course says | Current reality |
|---|---|---|
| Module 2/4 slides | `gemini-3.1-pro-preview` | Still a valid model string, so the slides are OK here. |
| ADK default | (n/a) | `LlmAgent.DEFAULT_MODEL = 'gemini-3.5-flash'`; quickstart uses `gemini-flash-latest`. |
| Lab 143 fallback | `gemini-2.5-flash` (code default), stale `.env` has `gemini-2.0-flash-exp` | See warning below. |
| Underlying SDK | google-genai 1.x | google-genai ≥2.9,<3 (SDK v2) — a breaking dependency bump that arrived with ADK 2.2.0. |

> [!WARNING]
> **The gemini-2.5 family shuts down in October 2026** (per the 2.2.0 release note). Any gemini-2.0/2.5 string in lab code or shipped `.env` files is a time bomb.

---

## Part 3: Module-by-module assessment

### Module 1: Introducing ADK

**Overall: light edits.** Positioning content, no code.

- **"A client-side, Python SDK"**
  - ADK is now a multi-language framework (Python, Go, Java, Kotlin, TypeScript); Python remains the flagship.
- **The ease-vs-flexibility landscape chart holds up**
  - But ADK's differentiator list should now lead with the graph Workflow engine, the Task API, and pause/resume.
- **The "What does ADK include?" slide should grow substantially**
  - See the expanded inventory below, which covers each addition with a reference link, description, scenario, and minimal example.
- **Agent Runtime / Gemini Enterprise naming is already updated here**
  - Matches current docs ("Google Cloud Agent Platform, formerly Vertex AI Agent Engine"). Keep.

#### The modern "What does ADK include?" inventory

Everything on the original slide (multi-agent systems, tools, evaluation, dev UI, callbacks, sessions/state, artifacts, managed deployment) still belongs. These ten capabilities are the additions a 2.x-era version of the slide should carry. All examples verified against ADK 2.4.0 source; all links verified live.

Vintage note: only items 1–2 are 🟠 2.x-specific. Items 3–7 and 9–10 are 🔵 — they shipped in 1.x *before* the course's 1.26 baseline, so the original slide could already have carried them — and item 8 is 🟣 late 1.x.

##### 1. Workflow graph engine

🟠 `2.x` (2.0.0, May 2026) · [adk.dev/workflows](https://adk.dev/workflows/) · [adk.dev/graphs](https://adk.dev/graphs/)

The 2.0 headline. A `Workflow` is a directed graph of nodes (agents, plain functions, tools, nested workflows) where edges express sequence, fan-out, and conditional routing — one primitive replacing the deprecated `SequentialAgent`/`ParallelAgent`/`LoopAgent` trio.

*Scenario:* a content pipeline where a researcher agent runs first, then a fact-checker and a stylist run in parallel, and a writer assembles the result.

```python
from google.adk import Agent, Workflow

researcher   = Agent(name="researcher", instruction="Research the topic.")
fact_checker = Agent(name="fact_checker", instruction="Verify claims.")
stylist      = Agent(name="stylist", instruction="Suggest tone and structure.")
writer       = Agent(name="writer", instruction="Write the article from all inputs.")

root_agent = Workflow(
    name="content_pipeline",
    edges=[
        ("START", researcher, (fact_checker, stylist)),  # fan-out
        (fact_checker, writer),                          # fan-in
        (stylist, writer),
    ],
)
```

##### 2. Collaboration modes (the Task API)

🟠 `2.x` (2.0.0) · [adk.dev/workflows/collaboration](https://adk.dev/workflows/collaboration/)

`LlmAgent` gains a `mode` field: `chat` (1.x behavior), `task` (runs its own loop until it calls the auto-injected `finish_task` tool, validates output against `output_schema`, can pause to ask the user, then automatically returns to the parent), and `single_turn` (stateless one-shot). Task and single-turn agents are exposed to their parent as tools.

*Scenario:* a support coordinator delegates "resolve this billing dispute" to a billing sub-agent and gets back a schema-validated result, without hand-writing an `AgentTool` wrapper.

*Caveat to teach:* task mode is disabled *inside graph workflows* in 2.0 (expected to return in a later release); it works in the coordinator/sub-agent pattern.

```python
from pydantic import BaseModel

class BillingResult(BaseModel):
    resolved: bool
    summary: str

billing_agent = Agent(
    name="billing_agent",
    instruction="Resolve the customer's billing issue.",
    mode="task",                      # runs to completion, then returns to parent
    output_schema=BillingResult,
)
coordinator = Agent(name="support", instruction="Route customer issues.",
                    sub_agents=[billing_agent])
```

##### 3. Pause/resume and human-in-the-loop

🔵 `pre-1.26` (invocation pause/resume since 1.16, Oct 2025; deterministic *workflow* resume is 🟠 `2.x`) · [adk.dev/runtime/resume](https://adk.dev/runtime/resume/)

Invocations can be interrupted (long-running tools, approval gates, the `request_input` tool) and deterministically resumed later — rehydrated from session history, surviving process restarts.

*Scenario:* an expense-approval agent files the request, pauses while a human manager approves in another system, and resumes hours later exactly where it stopped.

```python
from google.adk.apps import App, ResumabilityConfig

app = App(
    name="expense_approvals",
    root_agent=root_agent,
    resumability_config=ResumabilityConfig(is_resumable=True),
)
```

##### 4. Plugins

🔵 `pre-1.26` (`App` + plugins usable by 1.15, Sep 2025; `AutoTracingPlugin` is 🟠 `2.x`, 2.2.0) · [adk.dev/plugins](https://adk.dev/plugins/)

Packaged cross-cutting behavior attached once to the `App` rather than callback-by-callback on every agent: 16 hook points spanning the whole lifecycle (`on_user_message`, `before/after_run`, agent/model/tool callbacks, and error hooks like `on_model_error_callback`). Shipped plugins include `LoggingPlugin`, `ReflectRetryToolPlugin`, `SaveFilesAsArtifactsPlugin`, `BigQueryAgentAnalyticsPlugin`, and `AutoTracingPlugin`.

*Scenario:* Lab scbl140 already does this — a plugin that catches model 429 errors and substitutes a cached response so classroom demos never crash on quota.

```python
from google.adk.apps import App
from google.adk.plugins import BasePlugin

class QuotaFallback(BasePlugin):
    def __init__(self):
        super().__init__(name="quota_fallback")

    async def on_model_error_callback(self, *, callback_context, llm_request, error):
        if "429" in str(error):
            return canned_response  # an LlmResponse; suppresses the error

app = App(name="my_app", root_agent=root_agent, plugins=[QuotaFallback()])
```

##### 5. Context caching

🔵 `pre-1.26` (1.15, Sep 2025) · [adk.dev/context/caching](https://adk.dev/context/caching/)

Opt-in Gemini context caching for the static prefix of requests (system instruction, tool declarations), configured once on the `App`. Requires a ~4096-token minimum prefix.

*Scenario:* an agent with a 10k-token instruction block and 30 tool declarations serving many turns — the prefix is cached instead of re-billed and re-processed on every call.

```python
from google.adk.agents.context_cache_config import ContextCacheConfig
from google.adk.apps import App

app = App(
    name="my_app",
    root_agent=root_agent,
    context_cache_config=ContextCacheConfig(
        min_tokens=4096, ttl_seconds=600, cache_intervals=10),
)
```

##### 6. Events compaction (context compression)

🔵 `pre-1.26` (by 1.16, Oct 2025) · [adk.dev/context/compaction](https://adk.dev/context/compaction/)

Automatic LLM summarization of older conversation events at a configured interval, keeping long-running sessions inside the context window (summaries include thoughts and tool calls as of 2.2.0).

*Scenario:* a customer-service session spanning hundreds of turns keeps a rolling summary instead of replaying the full transcript to the model each turn.

```python
from google.adk.apps import App, EventsCompactionConfig

app = App(
    name="my_app",
    root_agent=root_agent,
    events_compaction_config=EventsCompactionConfig(
        compaction_interval=10,   # compact every 10 events
        overlap_size=2),          # keep 2 events of overlap for continuity
)
```

##### 7. Skills

🔵 `pre-1.26` (`SkillToolset` 1.25, Feb 2026, three weeks before the baseline; registry integration matured into 2.x) · [adk.dev/skills](https://adk.dev/skills/) · [skills-registry](https://adk.dev/integrations/skills-registry/)

Reusable packets of procedural knowledge in the SKILL.md format (frontmatter + instructions + optional scripts/resources), loaded from a directory or GCS and activated on demand via `SkillToolset` — plus a Google Cloud Skill Registry for sharing them across teams.

*Scenario:* a "brand voice" skill and a "quarterly report format" skill maintained by one team, dropped into any agent that writes customer-facing content.

```python
from google.adk.skills import load_skill_from_dir
from google.adk.tools.skill_toolset import SkillToolset

brand_voice = load_skill_from_dir("skills/brand_voice")  # folder containing SKILL.md
agent = Agent(name="marketing_writer", instruction="...",
              tools=[SkillToolset(skills=[brand_voice])])
```

##### 8. Environments and computer use

🟣 `late 1.x` (`BashTool` 1.27, Mar 2026; `EnvironmentToolset` 1.29, Apr 2026) · [environment-toolset](https://adk.dev/integrations/environment-toolset/) · [computer-use](https://adk.dev/integrations/computer-use/)

Agents get a workspace: `EnvironmentToolset` wraps an environment (local, or remote sandboxes: E2B, Daytona, Agent Engine Sandbox) with bash and file-I/O tools; the computer-use toolset drives a browser/GUI via Gemini's computer-use capability.

*Scenario:* a data-wrangling agent that downloads a CSV, runs a cleanup script in a sandbox, and saves results — without any hand-written function tools.

```python
from google.adk.environment import LocalEnvironment
from google.adk.tools.environment import EnvironmentToolset

agent = Agent(
    name="data_wrangler",
    instruction="Use the shell and file tools to clean the dataset.",
    tools=[EnvironmentToolset(environment=LocalEnvironment())],
)
```

##### 9. Prompt optimization (`adk optimize`)

🔵 `pre-1.26` (GEPA work landed 1.18–1.20, Nov–Dec 2025) · [adk.dev/optimize](https://adk.dev/optimize/)

GEPA-based automatic instruction tuning: the CLI iteratively rewrites an agent's instruction, using an eval set as the fitness function, and reports the best-performing variant.

*Scenario:* a team has 40 eval cases and a mediocre hand-written prompt; instead of guess-and-check prompt engineering, they let the optimizer search.

```bash
adk optimize my_agent/ \
    --sampler_config_file_path sampler_config.json \
    --print_detailed_results
```

##### 10. Conformance testing (`adk conformance`)

🔵 `pre-1.26` (CLI existed by 1.19, Nov 2025) · no dedicated adk.dev page yet — see `adk conformance --help` and the [release notes](https://adk.dev/release-notes/)

Record/replay regression testing: capture real agent runs (LLM calls and tool results) as YAML test cases, then replay them deterministically after code, prompt, or dependency changes and diff the behavior.

*Scenario:* before bumping the ADK pin or editing an instruction, replay the recorded suite in CI to catch behavioral regressions without live LLM calls.

```bash
adk conformance record tests/conformance/   # capture live runs as test cases
adk conformance test   tests/conformance/   # replay and diff after changes
```

### Module 2: Develop Agents with ADK

**Overall: moderate edits.** The core teaching (project structure, `root_agent`, four interaction surfaces, callbacks) survives almost intact.

**Still accurate:**

- Per-agent folder with `__init__.py` + `agent.py`, mandatory `root_agent` variable.
- `Agent(model=..., name=..., description=..., instruction=..., generate_content_config=...)` constructor shape.
- All six callbacks (`before/after_agent`, `before/after_model`, `before/after_tool`) and their skip semantics. In 2.x these are *more* important, since they are the sanctioned replacement for custom run-method overrides.
- `adk web` / `adk run` / `adk api_server` / programmatic Runner as the four surfaces.

**Needs fixing:**

- **Speaker notes say "ADK deploys to Agent Engine"**
  - Slide bodies say Agent Runtime; make the notes match.
- **"Flask" API-server claim** 🔵 `pre-1.26`
  - Speaker notes on the API-server slide (p. 38): "start a local API server, using Flask, on port 8000".
  - It's FastAPI/uvicorn, and always has been. Port 8000 is correct.
- **Python 3.9+ → 3.10+** 🟠 `2.x`
- **Sync runner example and `LLMAgent` spelling**
  - The programmatic example uses sync `for event in runner.run(...)` and the slide spells the class `LLMAgent`.
  - The code students open and run in scbl140 Task 4 (`app_agent/agent.py`, shipped in the lab bucket) instead uses `asyncio.run(main())` with `async for event in runner.run_async(...)`, matching current docs, and the class is `LlmAgent`.
  - Align the slide with the async pattern in the lab's code.
- **`.env` slide** 🟠 `2.x`
  - Swap `GOOGLE_GENAI_USE_VERTEXAI` → `GOOGLE_GENAI_USE_ENTERPRISE`.
- **Introduce `adk create` and the `App` container on the setup slide** 🔵 `pre-1.26`
  - `App(name=..., root_agent=..., plugins=[...])` is what Lab scbl140 already uses — right now the App/plugin pattern appears in the lab with no slide support at all.
  - Both `adk create` (0.2) and `App` (by 1.15) long predate the course baseline.
- **One slide each for plugins, context caching, and pause/resume** 🔵 `pre-1.26`
  - Plugins (the lab's `LabExUtils` 429-fallback plugin is a perfect concrete example), context caching (`ContextCacheConfig`), and pause/resume (`ResumabilityConfig`).
  - All three are 1.x features (1.15–1.16 era) the slides never covered, not 2.x additions — so they belong in a refresh even if the course stays on 1.x.

### Module 3: Build Multi-agent Systems with ADK

**Overall: this is the module the 2.0 release was aimed at. Substantial rework.**

- **Transfer rules survive**
  - The rules taught (sub-agent / parent / peer transfer, `disallow_transfer_to_peers`) still describe `LlmAgent` chat-mode delegation, and remain valid.
- **The three workflow-agent classes are deprecated** 🟠 `2.x`
  - See [Part 1.1](#11-workflow-graphs-replace-workflow-agents). A refreshed module teaches `Workflow` with edges as the primary orchestration tool.
  - Mention the legacy classes as "you will see these in existing code; they map to graph patterns like so."
- **The "when do you need a custom workflow agent" slide inverts**
  - Conditional logic, dynamic selection, and cyclic patterns are now *built into* `Workflow` (dict-edges, `ctx.run_node()`, conditional cycles, `JoinNode`).
- **The Task API deserves first-class treatment here**
  - `mode='task'` / `'single_turn'`, `finish_task`, schema-validated outputs, `parallel_worker`.
  - It is the new answer to "how do I delegate a bounded job to a sub-agent."
- **Typed data flow between nodes**
  - `event.output` replaces state-key plumbing for workflow steps; worth a note.

#### The four workflow-agent slides, scenario by scenario, in 2.x

The deck's "Types of workflow agents" section has one tab per class, each with its own example in the speaker notes. Below, each slide's own scenario is kept and shown twice: the 1.x solution as the course teaches it today, and the 2.x `Workflow` solution a refreshed slide would show. All 2.x snippets verified against ADK 2.4.0.

##### SequentialAgent → a linear edge path

*Slide scenario:* "Process a new order" — Order Validation Agent, Inventory Check Agent, Payment Processing Agent, Order Confirmation Agent, in that order.

**1.x as taught** — order comes from list position, and data moves between steps by writing `output_key` into session state and templating it into the next instruction:

```python
from google.adk.agents import Agent, SequentialAgent

validator = Agent(name="order_validator", instruction="Validate the incoming order.",
                  output_key="validation")
inventory = Agent(name="inventory_checker",
                  instruction="Check stock for this validated order: {validation}",
                  output_key="inventory")
payments  = Agent(name="payment_processor",
                  instruction="Process payment if in stock: {inventory}",
                  output_key="payment")
confirmer = Agent(name="order_confirmer",
                  instruction="Send the confirmation: {payment}")

root_agent = SequentialAgent(
    name="order_pipeline",
    sub_agents=[validator, inventory, payments, confirmer],
)
```

**2.x solution** — the wrapper agent disappears; sequence is an edge path, and each node receives the upstream node's typed `event.output` directly, so the `output_key` / `{state_key}` plumbing goes away:

```python
from google.adk import Agent, Workflow

root_agent = Workflow(
    name="order_pipeline",
    edges=[("START", validator, inventory, payments, confirmer)],
)
```

**Teaching beat:** the graph version also fixes what the slide's own scenario quietly can't do in 1.x — an *invalid* order still flows through payment. Give `validator` an `output_schema` with a `valid` field and route on it:

```python
edges=[
    ("START", validator, {"valid": inventory, "invalid": rejection_notifier}),
    (inventory, payments, confirmer),
]
```

In 1.x that upgrade required abandoning `SequentialAgent` for a custom agent; in 2.x it is one edge.

##### LoopAgent → a conditional cycle

*Slide scenario:* the marketing-analysis research loop from the slide diagram — Data Fetcher, Data Analyzer, Report Generator, and an Exit Condition Agent that decides whether to go around again.

**1.x as taught** — the loop exits via the `exit_loop` tool flipping the `escalate` action, plus a `max_iterations` safety net:

```python
from google.adk.agents import Agent, LoopAgent
from google.adk.tools import exit_loop

checker = Agent(name="exit_condition",
                instruction="If the report answers the question, call exit_loop. "
                            "Otherwise say what data is still missing.",
                tools=[exit_loop])

root_agent = LoopAgent(
    name="marketing_analysis",
    sub_agents=[fetcher, analyzer, reporter, checker],
    max_iterations=5,
)
```

**2.x solution** — the engine allows cycles, but only conditional ones (an unconditional cycle is rejected at graph validation). The exit-condition agent stops being a tool-calling trick and becomes an ordinary routing node with a structured output:

```python
from typing import Literal
from pydantic import BaseModel

class Sufficiency(BaseModel):
    route: Literal["refine", "done"]
    missing: str | None = None

checker = Agent(name="exit_condition",
                instruction="Decide whether the report answers the question.",
                output_schema=Sufficiency)

root_agent = Workflow(
    name="marketing_analysis",
    edges=[
        ("START", fetcher, analyzer, reporter, checker),
        (checker, {"refine": fetcher, "done": "END"}),
    ],
)
```

**Teaching beats:** the `exit_loop` / `escalate` idiom is gone entirely — worth saying out loud, since students will find it all over 1.x sample code. There is no `max_iterations` field on the cycle; the equivalent guard is a plain-function node (`@node`) that counts passes and forces the `done` route, which doubles as the module's first look at function nodes.

##### ParallelAgent → fan-out edges + JoinNode

*Slide scenario:* several Report Generation Agents run simultaneously, each responsible for a different region.

**1.x as taught** — and note that the slide scenario is incomplete on its own: to *use* the three reports you had to nest the `ParallelAgent` inside a `SequentialAgent` with a merger step, coordinating through three state keys:

```python
from google.adk.agents import Agent, ParallelAgent, SequentialAgent

amer = Agent(name="amer_report", instruction="Report on AMER.", output_key="amer")
emea = Agent(name="emea_report", instruction="Report on EMEA.", output_key="emea")
apac = Agent(name="apac_report", instruction="Report on APAC.", output_key="apac")

merger = Agent(name="merger",
               instruction="Combine the reports: {amer} {emea} {apac}")

root_agent = SequentialAgent(
    name="report_pipeline",
    sub_agents=[
        ParallelAgent(name="regional_reports", sub_agents=[amer, emea, apac]),
        merger,
    ],
)
```

**2.x solution** — fan-out is a tuple in an edge, fan-in is a `JoinNode`, and the two nested wrapper agents collapse into one graph. The merger receives the three branch outputs from the join as typed values instead of reading three state keys:

```python
from google.adk import Agent, Workflow
from google.adk.workflows import JoinNode

gather = JoinNode(name="gather_reports")

root_agent = Workflow(
    name="report_pipeline",
    edges=[
        ("START", (amer, emea, apac), gather),
        (gather, merger),
    ],
    max_concurrency=3,
)
```

**Teaching beats:** `max_concurrency` is new capability, not just new syntax — 1.x `ParallelAgent` had no throttle, which matters the first time a student fans out over twenty items and hits model quota. Per-branch `RetryConfig` likewise replaces the 1.x reality that one failed branch failed the whole parallel block.

##### Custom workflow agent → built-in graph features

*Slide scenario:* the slide is a checklist of five reasons to write one — conditional logic, complex state management, external integrations, dynamic agent selection, unique workflow patterns.

**1.x as taught** — subclass `BaseAgent` and override `_run_async_impl`, e.g. a support-triage agent that classifies a ticket, branches on the result, and logs to a CRM mid-flow:

```python
class TriageAgent(BaseAgent):
    async def _run_async_impl(self, ctx):
        async for event in self.classifier.run_async(ctx):
            yield event
        category = ctx.session.state["category"]
        crm.log_ticket(category)                       # external integration
        specialist = self.specialists[category]        # dynamic selection
        async for event in specialist.run_async(ctx):  # conditional branch
            yield event
```

**2.x solution** — every row of the slide's checklist is now a graph feature, and the same triage flow is declarative. Plain Python enters the graph as function nodes, and dynamic selection uses `ctx.run_node()`:

```python
from google.adk import Agent, Workflow
from google.adk.workflows import node

@node
async def log_to_crm(ctx):                 # external integration, no agent needed
    crm.log_ticket(ctx.input.output)
    return ctx.input.output

@node
async def escalate(ctx):                   # dynamic agent selection
    specialist = pick_specialist(ctx.input.output)
    return await ctx.run_node(specialist)

root_agent = Workflow(
    name="support_triage",
    edges=[
        ("START", classifier, log_to_crm,
         {"refund": refund_agent, "complaint": complaint_agent, "other": escalate}),
    ],
)
```

A refreshed version of the checklist slide maps 1:1:

| Slide's "use a custom agent when…" | 2.x built-in answer |
|---|---|
| Conditional logic | dict-edges (`{"route": node}`) |
| Complex state management | typed `event.output` flowing between nodes |
| External integrations | `@node` / `FunctionNode` plain-Python nodes |
| Dynamic agent selection | `ctx.run_node()` inside a function node |
| Unique workflow patterns | arbitrary graphs: conditional cycles, `JoinNode`, nested workflows |

**The migration trap to teach explicitly:** existing 1.x custom agents don't error under 2.x — their `_run_async_impl` overrides are *silently bypassed* (see [Part 1.2](#12-every-agent-is-a-node-custom-run-overrides-are-bypassed)), so the agent runs as if the custom logic were never written. Any student or team carrying a 1.x custom workflow agent forward must rebuild it as a graph (or move the logic into `before/after_agent_callback`), not just upgrade the pin.

**Caveats that keep the legacy slides half-alive:** `Workflow` cannot yet be a sub-agent of an `LlmAgent`, task mode is disabled inside graphs in 2.0, and live/BiDi streaming doesn't work in workflows. The deprecated trio therefore still appears in current docs and real codebases; the honest framing is "new builds use `Workflow`; here is how each legacy class maps."

### Module 4: Deploy ADK Agents to Agent Runtime

**Overall: the module most out of step with its own labs.** The deployment methods shown are still valid, but the code examples don't match what students do in Lab scbl143, and the naming/feature claims have drifted.

- **The walkthrough deploys a LangChain agent**
  - The develop/deploy/query slides use `reasoning_engines.LangchainAgent` + `agent_engines.create(...)`.
  - To be clear, both deployment surfaces are valid — the Vertex SDK path (`agent_engines.create(...)`) and the ADK CLI (`adk deploy agent_engine`) both worked in 1.26 and both work today. The problems are narrower:
  - The agent being deployed is a LangChain agent, so the walkthrough never shows deploying the kind of agent the course actually teaches students to build.
  - The slide flow doesn't match Lab scbl143, which uses the CLI. Either keep the SDK path but deploy an ADK agent, or align with the lab's flow:

  ```bash
  adk deploy agent_engine my_agent \
      --display_name "..." --region us-central1
  ```

  (The lab's version of this command also passes `--staging_bucket`, which was correct at its pin but is deprecated since 1.30 — see the next bullet.)
- **The `AdkApp` wrapper explanation is on its way out**
  - Lab scbl143 links to `vertexai.preview.reasoning_engines.AdkApp`; the phase-out happened in two steps (versions verified against released wheels):
  - 🟣 `late 1.x` — `--staging_bucket` was deprecated by 1.30 (Apr 2026) when deploy went source-based.
  - 🟠 `2.x` — the `--adk_app`, `--adk_app_object`, and `--absolutize_imports` flags were deprecated in 2.2.0 (Jun 2026) in favor of deploying the exported `root_agent`/`app` directly.
- **Deploy capabilities worth teaching, by vintage:**
  - 🔵 `pre-1.26` **API-key deploys** (`--api_key`) — deploy with just an API key, no GCP project, against the Gemini API backend. Express-mode Agent Engine deploys shipped in 1.18 (Nov 2025); the CLI onboarding flow was polished in 1.29–1.33 (🟣 `late 1.x`).
  - 🔵 `pre-1.26` **`--agent_engine_id`** for update-in-place redeploys — since 1.4 (Jun 2025).
  - 🟠 `2.x` **`--trigger_sources pubsub,eventarc`** for event-driven/batch invocation endpoints — new in 2.2.0.
  - Targets are `agent_engine`, `cloud_run` (with `--a2a`, `--with_ui`), and `gke` — all long-standing.
- **Naming confusion to address head-on**
  - Current docs say "Agent Runtime… part of the Google Cloud Agent Platform (formerly Vertex AI Agent Engine)".
  - The CLI command is still `adk deploy agent_engine` and resource names are still `.../reasoningEngines/NNNN`.
  - Tell students explicitly that the marketing name and the API surface disagree, or they will be confused the first time they see a resource name.
- **The keystone diagram's "Coming soon" claims are stale**
  - Managed sessions / memory / example store / code sandbox have since shipped in various forms (Vertex session service with TTL, memory with profile loading, Agent Engine Sandbox / computer use). Refresh or remove.
- **The quiz contradicts itself**
  - The feature table says Agent Runtime has "UI to list, view, and converse with agents"; the quiz answer says it "does not provide a UI".
  - The console today has Playground, Traces, Sessions, and Evaluation tabs — the quiz answer is wrong.
- **`ManagedAgent` is worth a forward-looking mention** 🟠 `2.x`
  - New in 2.4.0: server-hosted agents on the Managed Agents API, wrapped as a local agent class.

### Module 5: Evaluate ADK Agent Systems

**Overall: concepts survive; formats and metric inventory are stale.**

**Still accurate:**

- The two evaluation dimensions (final response vs. trajectory/tool use), `tool_trajectory_avg_score` (default 1.0), `response_match_score` (ROUGE, default 0.8).
- The three ways to run evals: Web UI eval tab, pytest via `AgentEvaluator.evaluate()`, and `adk eval`.
- Test files (`.test.json`, unit-test style) vs. evalsets (`.evalset.json`, integration style) as a taxonomy.

**Needs fixing:**

- **The file format shown is the legacy schema** 🔵 `pre-1.26`
  - The slides show a flat list of `query` / `expected_tool_use` / `reference` dicts.
  - The Pydantic `EvalSet`/`EvalCase` schema (`eval_cases`, `invocations`, etc.) dates to early-mid 1.x, so the slides were stale at the course's own baseline.
  - Legacy files are auto-migratable via `AgentEvaluator.migrate_eval_data_to_new_schema`. Slides should show the current schema.
- **`AF_TRACE_TO_CLOUD=1`** 🔵 `pre-1.26`
  - The slide's "expected to change" comment resolved before ADK 1.0.
  - The current flag is `--otel_to_cloud` with the OTel-GCP extra (`google-adk[otel-gcp]`), which Lab scbl140 already uses; `--trace_to_cloud` still works but is deprecated in 2.x.
- **The metric inventory has grown a lot** 🔵 `pre-1.26`
  - A selling point worth teaching — and it is almost entirely 1.x-era.
  - Rubric-based, safety, and hallucination metrics landed in 1.15–1.16 (Sep–Oct 2025); `final_response_match_v2` (LLM-as-judge) and multi-turn metrics (`multi_turn_task_success_v1`, trajectory and tool-use quality) are likewise 1.x-era.
  - User simulation arrived across 1.18–1.22 (simulator Nov 2025, eval integration Jan 2026), with refinements through 2.3.
  - `adk eval_set generate_eval_cases` for LLM-generated eval cases is also 1.x-era.
- **`adk conformance record` / `test`** 🔵 `pre-1.26`
  - Record/replay regression testing (CLI existed by 1.19, Nov 2025) — a new adjacent capability that fits naturally at the end of this module.
- **Eval extras install**
  - `pip install "google-adk[eval]"`.

---

## Part 4: Lab-by-lab assessment

| Lab | Pin | State | Effort to modernize |
|---|---|---|---|
| scbl140 (Get Started) | `google-adk[otel-gcp]==1.30.0` | ✅ Healthy. Already uses `App` + plugins, `run_async`, OTel. | **Low.** Bump pin to 2.x, swap `GOOGLE_GENAI_USE_VERTEXAI`, fix stale shipped `.env` (`gemini-2.0-flash-001`), update doc links to adk.dev. Verify plugin/`App` imports under 2.x. |
| scbl141 (Tools) | `google-adk==1.23.0` (full lockfile) | ✅ Healthy but oldest pin of the ADK labs. | **Medium.** Regenerate the lockfile for 2.x (google-genai jumps to 2.x — the biggest transitive change); consider teaching `mode='task'` alongside/instead of the `AgentTool` workaround; `[mcp]` extra note; AI Applications console steps need a click-through re-verify. |
| scbl132 (VAISC-07) | n/a | ➖ Not an ADK lab (Vertex AI Search for commerce / Retail API in Colab). | **None** for ADK purposes. If the class is meant to be all-ADK, this is a curriculum-composition question, not a refresh task. |
| scbl143 (Deploy) | `google-cloud-aiplatform[agent_engines,adk]==1.156.0` | ⚠️ Works, but teaches the deprecated `AdkApp`-wrapper mental model and pins ADK only transitively. | **Medium.** Pin `google-adk` directly; drop `AdkApp` framing (deprecated flags); stale `.env` has `gemini-2.0-flash-exp` (Oct 2026 shutdown); code fallback `gemini-2.5-flash` same problem; quiz links pin an old adk-python commit — repoint at 2.x source or adk.dev. |
| scbl148 (MCP) | `google-adk==1.22.1`, `mcp==1.10.1` | ⚠️ Most fragile lab. | **High.** `MCPToolset` → `McpToolset`; `mcp` pin is far behind (2.x wants `mcp>=1.24,<2` via the `[mcp]` extra); the `@modelcontextprotocol/server-google-maps` npm package is deprecated upstream — the lab's core dependency may vanish; consider adding/switching to `StreamableHTTPConnectionParams` for the remote-server story and the new agent-as-MCP-server (`RemoteMcpServer`) direction; misnamed `__init.py__` files in the bucket. |

---

## Part 5: Capabilities the course doesn't mention

For a "what's new" lecture segment or future course expansion, in rough order of teaching value. Note the vintage column: only the first two are 2.x-specific; most of this list was already shipping before the course's 1.26 baseline and simply never made it into the slides.

| # | Capability | What it is | Vintage |
|---|---|---|---|
| 1 | **`Workflow` graph engine** | Sequential/parallel/conditional/cyclic orchestration in one primitive ([Part 1.1](#11-workflow-graphs-replace-workflow-agents)) | 🟠 `2.x` |
| 2 | **Task API** (`mode='task'`) | Schema-validated, tool-exposed delegated agents with auto `finish_task` ([Part 1.3](#13-the-task-api-agents-get-a-mode)) | 🟠 `2.x` |
| 3 | **Plugins** | Cross-cutting hooks packaged on the `App`: `LoggingPlugin`, `ReflectRetryToolPlugin`, `SaveFilesAsArtifactsPlugin`, `BigQueryAgentAnalyticsPlugin` (agent analytics in BigQuery), `AutoTracingPlugin`. Lab scbl140's 429-fallback plugin is already a working example. | 🔵 `pre-1.26`, except `AutoTracingPlugin` (2.2.0) |
| 4 | **Pause/resume and HITL** | `ResumabilityConfig`, the `request_input` tool, session rewind, deterministic workflow resume | 🔵 `pre-1.26` (1.16+); deterministic *workflow* resume is 🟠 `2.x` |
| 5 | **Context caching and events compaction** | `ContextCacheConfig`, `EventsCompactionConfig`; cost/latency levers students always ask about | 🔵 `pre-1.26` (1.15–1.16) |
| 6 | **Interactions API** | `Gemini(use_interactions_api=True)` chains `previous_interaction_id` server-side instead of resending history | 🔵 `pre-1.26` (1.21, Dec 2025) |
| 7 | **Model breadth** | Native OpenAI (`OpenAILlm`, Responses API) and Anthropic support beyond LiteLLM; Gemma 4; `ManagedAgent` for server-hosted agents | Mixed: LiteLLM-based support is long-standing 1.x; `ManagedAgent` is 🟠 `2.x` (2.4.0) |
| 8 | **Environments and computer use** | `BashTool`, `EnvironmentToolset`, local/E2B/Daytona sandboxes, Agent Engine Sandbox | 🟣 `late 1.x` (1.27–1.29) |
| 9 | **Skills** | `SkillToolset`, SKILL.md format, GCP Skill Registry | 🔵 `pre-1.26` (1.25); registry integration matured into 2.x |
| 10 | **Prompt optimization** | `adk optimize` (GEPA-based) | 🔵 `pre-1.26` (1.18–1.20) |
| 11 | **Conformance testing** | `adk conformance record/test` for record-replay regression suites | 🔵 `pre-1.26` (by 1.19) |
| 12 | **Observability maturation** | Native OTel `gen_ai.*` metrics and spans, `--otel_to_cloud` everywhere, BigQuery analytics views | Accumulated across 1.x and 2.x |

---

## Part 6: Suggested refresh priority

1. **Module 4** — wrong today, not just outdated
   - Replace the LangChain/`reasoning_engines` deploy code with the `adk deploy agent_engine` flow the labs already use.
   - Fix the quiz contradiction; remove "coming soon" claims.
2. **Module 3** — deprecated today, removed eventually
   - Teach `Workflow`; demote the three workflow-agent classes to legacy status. Also 2.0's headline feature.
3. **Module 5** — field names students won't find in the docs
   - Current eval schema, current metric list, kill `AF_TRACE_TO_CLOUD`. Legacy formats still auto-migrate.
4. **Lab scbl148** — availability risk
   - The upstream npm deprecation is independent of ADK versioning.
5. **Module 2 + labs 140/141/143** — mechanical updates, mostly low effort
   - Env var, casing, pins, model strings, links.
   - The gemini-2.0/2.5 strings in shipped `.env` files must be gone before October 2026.
6. **Module 1** — light positioning updates.

---

## Part 7: Source-verified findings from deck development

Findings from building the replacement Module 2/3 decks (July 2026), each verified
against the adk-python 2.4.0 source or adk.dev docs. These go a level deeper than
the module assessments above and correct a few earlier assumptions.

### Tools and Module 2 territory

- **The tool-mixing lesson is on borrowed time.** The limitations doc scopes the
  "search tools can't mix with other tools" restriction to **ADK Python ≤1.15**,
  and in 2.4.0 source both `GoogleSearchTool` and `VertexAiSearchTool` hard-fail
  only on **Gemini 1.x models** — for Gemini 2+/3 they simply append to the
  request. scbl141's demonstrated error (at its own 1.23 pin, current model) may
  not reproduce; verify live before each delivery.
- **Async tools are the real best-practice gap.** Since ADK 1.10 the framework
  runs a batch of requested tool calls in parallel, but one sync tool blocks the
  batch (sync functions are invoked directly on the event loop — no thread
  offload, per `FunctionTool._invoke_callable`). Every tool in scbl141 is sync —
  and it isn't just student code: the `LangchainTool` adapter binds the wrapped
  tool's synchronous `_run` (never `arun`), so the lab's Wikipedia tool blocks the
  loop during its HTTP round trip.
- **Tool confirmation is a 1.x feature.** `FunctionTool(fn,
  require_confirmation=True)` (or a callable for conditional gating) shipped in
  **1.14**, experimental. The framework intercepts the call, emits a confirmation
  request (dialog in `adk web`; answerable via REST), and runs or rejects the tool
  on the response — no logic inside the tool itself.
- **Plugins:** the exported retry class is `ReflectAndRetryToolPlugin` (not
  `ReflectRetryToolPlugin`); `BasePlugin` exposes **16 hooks** including error
  hooks callbacks don't have; full shipped set also includes
  `GlobalInstructionPlugin`, `ContextFilterPlugin`, `MultimodalToolResultsPlugin`,
  `DebugLoggingPlugin`.
- **Context caching, precisely:** the 4096-token minimum is **Gemini's hard API
  floor**, measured against the **whole prior request prompt** (instruction +
  tools + history), not just the static prefix; caching starts on **turn 2** at
  the earliest; ADK's `min_tokens` defaults to 0 and only matters above 4096.
  Defaults: `ttl_seconds=1800`, `cache_intervals=10`. Related: `static_instruction`
  marks instruction content as fixed for caching.
- **`aiplatform[adk]` pins below 2.0.** The extra in
  `google-cloud-aiplatform==1.156.0` (scbl143) declares `google-adk>=1.0,<2.0` —
  a fresh install resolves the newest 1.x (1.36.1 as of July 2026), floats within
  1.x, and **cannot** reach 2.x by bumping aiplatform; a 2.x refresh must pin
  `google-adk` directly.

### The graph engine and Module 3 territory

- **LLM agents inside graphs must be `mode="single_turn"` (or `task`).** Explicit
  caution in the graph docs; and task mode is disabled inside graphs in 2.0
  (expected to return). Any Sequential/Loop/Parallel → Workflow conversion must
  add the mode.
- **Function-node parameter binding is name-sensitive.** Default binding is
  `'state'` mode: only the parameter literally named **`node_input`** receives the
  previous node's output; parameters with other names are bound from **state
  keys** by name; a parameter named `ctx` receives the `Context`. (An alternative
  `parameter_binding='node_input'` mode binds parameters from fields of the
  incoming dict/BaseModel.) Easy to get wrong — a router written as
  `def router(x)` silently reads `state["x"]`.
- **Data flow is a one-hop relay.** A successor receives only the immediately
  preceding node's `event.output` (scheduler passes `Trigger(input=output)`).
  A router that returns `Event(route=...)` **without** `output=` forwards `None`
  to the chosen node — routers must re-emit the payload (the official routing
  example has this bug). Exceptions: a `JoinNode` receives a dict of all
  predecessor outputs keyed by node name, and state-mode parameter binding can
  reach around the relay.
- **Agent nodes are typed citizens.** With `output_schema`, an agent node's
  response is parsed and `event.output` *is* the validated object (post-hoc
  parse — not the task-mode retry loop; empty responses yield `None`).
  `output_key` also works on graph nodes, writing the same value to state.
  Wrapping is automatic for agents and for plain function returns; explicit
  `Event(...)` is needed only for `route` or `message`.
- **Loops are back-edges, not a construct.** A dict route pointing at an earlier
  node re-activates it (fresh lifecycle); the exit is simply the forward route.
  The docs' snippet under "Loop and escalation exit" is actually a plain branch —
  nothing points backward. There is **no `max_iterations`**: cap loops in the
  router (e.g., count passes in state). Unconditional cycles are rejected at
  build time.
- **Terminal output rule.** The terminal node's `output` becomes the workflow's
  own output (`Workflow._finalize`) — a Workflow is itself a node, so nested
  graphs and Workflow-as-tool consume it; **only one** terminal node may produce
  output or the workflow raises. A user-facing terminal node must set `message`
  or the user sees nothing from that step.
- **Reliability knobs are per node:** `node(step, retry_config=
  RetryConfig(max_attempts=3), timeout=60.0)`; timeout raises `NodeTimeoutError`
  (itself retryable). `RetryConfig` defaults: 5 attempts, 1s initial delay, 2×
  backoff, 60s max delay. A `JoinNode` waits for **every** predecessor — one
  failed branch stalls the join, so give flaky branches retries and failsafe
  output.
- **`max_concurrency` is real but undocumented.** A `Workflow` field (verified in
  source) capping concurrently running graph-scheduled nodes; `None` = unlimited;
  dynamic nodes (`ctx.run_node()`) excluded to avoid deadlock. Absent from
  adk.dev as of July 2026.
- **Custom agents: the replacement is Workflows, not callbacks.** The
  custom-agents doc says to evaluate graph/dynamic workflows *before* building a
  custom agent; a custom agent's control flow becomes function router nodes +
  dict edges. Callbacks remain per-agent hooks only. (Section 1.2 above was
  corrected accordingly.)
- **Canonical fan-out spelling:** declare the join (`gather =
  JoinNode(name="gather")` — an ordinary variable, not a keyword) and write each
  branch as its own path edge to it: `("START", a, gather)`, `("START", b,
  gather)`, `(gather, next)`.

### Managed agents (Module 4 territory)

- **`ManagedAgent` is a data-plane proxy, and "custom" managed agents are
  configurations of Google's base agent — you never deploy anything.** Verified
  against the GEAP create-manage doc (Pre-GA): `agents.create` takes `{id,
  base_agent, system_instruction, tools, base_environment}`, and **the only
  supported `base_agent` is `antigravity-preview-05-2026`** — a custom managed
  agent is antigravity plus your instructions, a subset of its server-side tools
  (`code_execution`, `filesystem`, `google_search`), and sandbox settings (GCS
  mount, network allowlist, skills). No model choice, no custom code. ADK's
  `ManagedAgent` never creates agents (data plane only — the Interactions API);
  its `tools`/`environment` are per-interaction overrides that leave the hosted
  configuration unchanged. Backend is selected by environment
  (`GOOGLE_GENAI_USE_ENTERPRISE` → Agent Platform, global-only; otherwise Gemini
  API via `GEMINI_API_KEY`). Client-side Python/MCP tools are unsupported, but
  MCP servers and skills *can* be configured into the server-side sandbox at
  creation. `ManagedAgent` also carries `mode: 'single_turn'` for use as a
  Workflow node.

---

## Appendix: quick-reference delta table

| Topic | 1.x-era course | ADK 2.4.0 | Changed in |
|---|---|---|---|
| Orchestration | `SequentialAgent` / `ParallelAgent` / `LoopAgent` | `Workflow(edges=[...])`; old classes deprecated | 🟠 2.0 |
| Delegation as tool | `AgentTool(agent)` | `mode='task'` / `'single_turn'` (AgentTool still exists) | 🟠 2.0 |
| Custom agent logic | Override `_run_async_impl` | Bypassed in 2.0 — use before/after agent callbacks | 🟠 2.0 |
| Top-level exports | `Agent` | `Agent`, `Context`, `Event`, `Runner`, `Workflow` | 🟠 2.0 |
| Env var (Vertex path) | `GOOGLE_GENAI_USE_VERTEXAI` | `GOOGLE_GENAI_USE_ENTERPRISE` (old warns) | 🟠 2.3 |
| MCP classes | `MCPToolset`, `StdioServerParameters`, `SseServerParams` | `McpToolset`, `StdioConnectionParams`, `SseConnectionParams`, `StreamableHTTPConnectionParams`; `[mcp]` extra | 🔵 renames by 1.17; 🟠 extra 2.0 |
| Deploy | `agent_engines.create(...)` / `AdkApp` wrapper | `adk deploy agent_engine` (AdkApp flags deprecated); API-key deploys; `--trigger_sources` | mixed — see note ¹ |
| Eval file schema | `query` / `expected_tool_use` / `reference` list | Pydantic `EvalSet`/`EvalCase`; auto-migration available | 🔵 early 1.x |
| Eval metrics | 2 metrics | 12+ incl. safety, hallucination, LLM-judge, rubric, multi-turn, user simulation | 🔵 1.15–1.22 |
| Tracing env | `AF_TRACE_TO_CLOUD=1` | `--otel_to_cloud`, `[otel-gcp]` extra (`--trace_to_cloud` deprecated) | 🔵 pre-1.0 |
| Python | 3.9+ | 3.10+ | 🟠 2.0 |
| genai SDK | 1.x | ≥2.9,<3 (SDK v2) | 🟠 2.2 |
| Default model | (course: `gemini-3.1-pro-preview`) | `gemini-3.5-flash`; gemini-2.5 family EOL Oct 2026 | EOL notice 2.2 |
| Sessions | freely portable | 2.0 sessions need ADK ≥1.28; `adk migrate session` | mixed — see note ² |
| Docs | google.github.io/adk-docs | adk.dev (multi-language) | 🟠 2.0-era |
| Scaffolding | manual folder setup | `adk create my_agent` | 🔵 0.2 |

¹ Deploy: API-key deploys 🔵 1.18; `--staging_bucket` deprecated 🟣 1.30; `AdkApp` flags and `--trigger_sources` 🟠 2.2.
² Sessions: migrate CLI 🔵 1.22; the compatibility break itself 🟠 2.0.
