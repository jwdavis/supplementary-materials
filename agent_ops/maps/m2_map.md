# Module 2 deck map — CI/CD for Agent Deployments

Source: `agent_operations/M2-CI_CD for Agent Deployments.pdf` (35 slides) and the
companion `agent_operations/m2.html`. Brief: `agent_ops/briefs/m2.md`.
Baseline: google-adk **2.9.0**, google-agents-cli **1.5.0**, verified 2026-09-12.

22 pages: 14 content + opener, objectives, 3 dividers, 2 recaps, consequences, references.


## Revision 1 (2026-09-12, Jeff's page review)

| Page | Change |
|---|---|
| 4 | Was "one extra step" with a linear build→unit→eval diagram. **Rewritten as "What changes, and when you check it"**: three cadence lanes (while you work / on push / on PR), each a wider set. The image build is shown as a release step *after* the gate, not a per-commit one. Absorbs old page 8's merge-result point. |
| 6 | Example and blue rule contradicted the code (no visible assertion). **Rewritten around two real terminal sessions** from the reproduction: `adk eval` exit 0 vs `pytest` exit 1, with the verbatim `Expected 0.9, but got 0.0` line making the threshold comparison visible. |
| 7 | Dropped the `guidance` tag — no document says "two sets." Attribution moved to speaker notes as field practice. |
| 8 | Was "Where each tier runs" (assumed `agents-cli` was *the* local mechanism). **Replaced with "Four ways to run an eval"**: `adk web` (incl. save-session-as-case), `adk eval`, `agents-cli eval`, `pytest + AgentEvaluator`, with a Gates? column and the adk-vs-agents-cli differences. |
| 9 | Gained the merge-result mechanism (`GITHUB_REF` = merge branch) and the Marco/Priya example, where the PR trigger is already the subject. |
| 10 | Recap rows rewritten: "The artifact is code" replaced with plain language; rows realigned to the revised pages. |

Page count unchanged at 22.


## Revision 2 (2026-09-12, Jeff's second page review)

| Page | Change |
|---|---|
| 4 | Contradicted page 7 (three cadences vs. two-standard tiers). Lanes now match page 7 exactly: local / PR gate / optional scheduled. Restored old page 8's `main`+`feature` → merge-result fan-in inside the PR lane. |
| 8 | Answered: **`agents-cli eval grade` calls the Agent Platform evaluation service** (`agentplatform._genai`, `evaluation_service_qps`) — that is why it needs a project and eval-supported region, and where its metric set comes from. `adk eval` grades in-process. |
| 13 | Rewritten twice. No acceleration row. "Who owns the URL" → **"How callers reach it"**. Sessions row now `DatabaseSessionService` over a Postgres/MySQL/SQLite URL, not "Cloud SQL". **Retracted (Revision 2a):** an interim version claimed Agent Runtime is BYOC-only and that managed sessions are not automatic. Both wrong — over-generalized from the agents-cli scaffold's path. Verified: Agent Runtime accepts five forms (Developer Connect, source files, Dockerfile, Artifact Registry image, SDK agent object) per the *Deploy an agent* doc; `adk deploy agent_engine` bakes `--session_service_uri=agentengine://<engine>` and the memory equivalent into the container `CMD` (`cli_deploy.py`), resolved by `service_registry.py`; the SDK `AdkApp` defaults to `VertexAiSessionService` on Agent Engine (`templates/adk.py:739`). Only a hand-written container wires nothing. |
| 14–15 | Was one terse page; **split in two**. 14 = telemetry. **Corrected (Revision 2b):** the flag does two things on Agent Runtime — sets the platform var `GOOGLE_CLOUD_AGENT_ENGINE_ENABLE_TELEMETRY=true` (read by the platform, never by ADK; SDK default `"unspecified"` = default-on) *and* writes `--otel_to_cloud` into the container `CMD`, which at boot builds OTLP exporters for traces/metrics/logs to `telemetry.googleapis.com`. Precedence for `ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS`: library default true → `adk deploy agent_engine` writes false *only if absent from `.env`* → your `.env` wins → Cloud Run/GKE deploys never touch it (content exported by default). All three OTEL vars are read in-process on every target; only the injection path differs (`.env` / `--env` / manifest). `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` value is `EVENT_ONLY` (enum: NO_CONTENT/EVENT_ONLY/SPAN_ONLY/SPAN_AND_EVENT; `true` is a back-compat alias). 15 = secrets (incl. GKE mounting), identity, sizing with the `adk deploy --provider-args` equivalent. |
| 19 (model) | Alias example rewritten to the deploy-Tuesday / drift-Thursday case. `gemini-3.5-flash` baseline. "Pin per environment" → **promote one version through environments**. Added where Model Registry actually fits (models you tune, not foundation ids). |
| 20 (tools) | Refocused from generic dev advice onto the CI/CD-shaped problem: a remote MCP server is an **undeployed dependency** whose release changes behavior with no pipeline run. Agent Registry is the control point and the example. |
| 21 | Added `OTEL_RESOURCE_ATTRIBUTES=service.version=$COMMIT_SHA` — commit stamped on telemetry as well as the image. |
| 13 (2c) | "What you hand over" was wrong: both deploy tools build the image from source on every target (`gcloud run deploy --source`; Agent Engine build; `agents-cli` unless `--image`). Row rewritten by tool. Sessions row now names `VertexAiSessionService` on Cloud Run/GKE via `--session_service_uri=agentengine://<id>` (same `service_registry.py` factory) and the scaffold's `agent_platform_sessions` mode. |
| 14 (2c) | Was confounding the two content variables. `ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS` → `should_add_content_to_legacy_spans` (ADK-owned spans). `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` is a mode → `should_add_content_to_logs` (EVENT_ONLY/SPAN_AND_EVENT) **and** `should_add_content_to_experimental_spans` (SPAN_ONLY/SPAN_AND_EVENT). Precedence table made precise: the deployment env comes only from `<agent_dir>/.env` via `dotenv_values`; the shell is never read, so a shell-only value → the deploy writes `false`. |
| 22 | Fixed the merge row (the eval is the cause of the failure, not a later remedy) and the OOM row (now an observable symptom). Alias row replaces the staging/prod-skew row. |

**Page count is now 23 (was 22), ≈57 min against a 35-min budget.** The deck is over budget and needs a cut pass — see Open questions.

## Organizing frame

**What is different because it is an agent → where it runs → what you govern.**

The module turns on one structural fact: what changed is a source file the model
reads, and the only check that catches it is one that grades a decision. Section 1
establishes that, places the checks at three cadences (loop, push, PR), fixes the
trap the tooling sets (the eval CLIs exit 0 on failure), and names which of the four
mechanisms actually gates. Section 2 covers targets and configuration.
Section 3 governs the two things the model reads to make decisions: the model id and
the tool descriptions.

## What changed vs. the sources, and why

| Source says | Deck says | Why |
|---|---|---|
| Nothing about evaluation (0 of 35 slides) | An entire section, 6 pages | The brief's first focus item; the source's largest gap |
| Companion: `adk eval` in a build step, "non-zero exit stops the build" | `adk eval` exits **0** on failed cases; gate with pytest | Read in `cli_tools_click.py` and reproduced both ways; vendor skill confirms |
| Slides 10–12 differentiate targets by hardware acceleration | Differentiated by URL ownership, sessions, code-execution isolation | Accelerators compare the *model* deployment, not the agent loop |
| Slide 11: "isolate untrusted code with GKE Sandbox" (on Cloud Run) | Cloud Run sandboxes (Preview); GKE Agent Sandbox is the GKE answer | GKE Sandbox is a GKE node feature; wrong product for Cloud Run |
| Slide 29 `cloudbuild.yaml` | Rebuilt: commit-tagged image, declared substitutions, pytest eval gate, `--quiet` | Three bugs: undefined `${_PROJECT_ID}`, untagged image, no eval step |
| Slides 21–22: register models, track lineage/hyperparameters | Two rules: pin the id per environment; upgrade through the pipeline | Written for teams training models; attendees use foundation models |
| Slide 9 notes: "sessions and memory built in" to Agent Runtime | Sessions/Memory Bank are separate services any host can call | Companion correction, re-verified: they take an `agent_engine_id` |

## Diagram convention

Blue = the active concept. Green = recommended path / passing. Red = the problem or
blocked path. Gray = inert scaffolding. Literal values in mono. Every arrowhead uses
a per-page unique marker id (`mNN`). Full-width figures ≤ 1000 wide.

---

## Page 1 — Module opener (divider)

Type: divider. Shapes cluster, `02` in the blue circle.
- h1: CI/CD for Agent Deployments
- dsub: The pipeline that ships an agent is an ordinary service pipeline with one step added. This module is about that step, the three places it runs, and the two things you govern. Verified against **google-adk 2.9.0** and **google-agents-cli 1.5.0**, September 2026.
- agenda: 01 The check that is new (hot) · 02 Targets and configuration · 03 Governing what the model reads
- Notes: boundary of the module; ask who in the room already has a pipeline and whether anything in it checks behavior.

## Page 2 — Module objectives

Type: objectives (`.numrows`, 4 rows).
1. Place evaluation in the development loop and in CI, and build a gate that actually fails.
2. Choose a deployment target from what decides it: who owns the URL, where sessions live, how model-written code is isolated.
3. Configure a deployment: telemetry, secrets, identity, and sizing.
4. Govern the two inputs the model reads to make decisions: the model id and the tool descriptions.
- Notes: each objective is a capability; objective 1 is the one the source deck has nothing on.

## Page 3 — Section divider 1

kicker: Section 1 of 3 · h1: The check that is new · dsub: Everything else in your pipeline already works. One kind of check is missing, and the tooling makes it easy to add it and still catch nothing.

---

## Page 4 — What changes, and when you check it

Type: concept + mechanism. **Revised — see Revision 1.**
- lede: A pull request changes one sentence of the refund agent's instruction. Every test passes. The agent now refuses refunds it used to grant.
- checks (3 rows): **The instruction is a source file** — so are tool definitions, model id, generation config; they diff and get reviewed, but a few words of English can change behavior as much as a rewritten function. / **No test you already run would catch it** — unit tests assert on code paths, and no code path changed. / **An eval run would** — it grades what the agent decided.
- **Diagram** (viewBox 0 0 1000 286): three stacked cadence lanes, each a labelled box at x=16 w=250 with a mono subtitle, and a right-hand gray annotation. `WHILE YOU WORK` (y=32, blue) "a few eval cases / seconds · you read the scores" → "no gate — you are deciding, not blocking". `ON PUSH TO YOUR BRANCH` (y=130, blue) "unit tests + a larger eval set / minutes · fails your branch" → "fast feedback, still only your work". `ON PULL REQUEST` (y=218, **green**, stroke-width 2) "the full set, on the merge result / blocks the merge" → arrow (marker `m4`) → "then the release pipeline you already have: build image → push → deploy". Caption: each moment runs a wider set than the one before it.
- note.blue (Rule): building a container image is a *release* step, not a per-commit one. Evals run against the working tree or the merge result, long before anything is packaged.
- **Example**: Actor Priya. Input: the instruction edit. Mechanism: a dozen cases locally (two fail, she fixes and pushes); the branch runs the larger set; the PR runs the full set against the merge result. Result: three unshipped-order cases the local dozen never covered fail at the PR. `illustrative`
- takeaway: the same kind of check runs at three moments with three different breadths — and none of them needs an image built first.
- src: companion m2 §04 · martinfowler.com Continuous Integration (verified 2026-09-12)
- Notes: the three moments are a *cadence*, not a pipeline. "On push" is a choice, not a requirement. Fowler's full CI definition and the delivery-vs-deployment distinction stay off the face.

## Page 5 — Three kinds of check, three different things they catch

Type: comparison.
- lede: "We have tests" is not an answer to "does it still behave?" Three mechanisms, and only one of them grades a decision.
- table.cmp, cols: Check / What runs / What it catches / What it cannot
  - `pytest tests/unit` — your functions, model mocked or absent — logic bugs, schema errors — anything the model decides
  - `pytest tests/integration` — the agent, **real model** — wiring: does a turn complete and return text — whether the answer was *right* (scaffolded test asserts only that some text came back)
  - `adk test` — recorded events replayed, **model mocked** — regressions against a fixture, deterministically — anything not in the fixture
  - **hl:** eval run — the agent, real model, output **graded** — wrong tool, wrong trajectory, wrong answer, unsafe answer — determinism: scores move between runs
- note.blue (Rule): An eval is not a slower unit test. A unit test asserts; an eval scores, and a score needs a threshold.
- takeaway: Unit and integration tests tell you the agent *ran*. Only the eval tells you what it *decided*.
- src: `agent_test_runner.py` (mocks `BaseLlm`) and `tests/integration/test_agent.py` in the agents-cli scaffold, google-adk 2.9.0 (verified 2026-09-12)
- Notes: the scaffolded integration test asserts `len(events) > 0` and that some part has text — worth reading aloud, it surprises people. `adk test --rebuild` re-records fixtures.

## Page 6 — The gate that isn't

Type: code + correction. **The correction page of the module. Revised — see Revision 1.**
- lede: You add an eval step to your pipeline, push a change that breaks a case, and the build goes green.
- codelabel bad: "The command reports the failure — and succeeds"; `pre.term` with the real `adk eval` run: Eval Run Summary / Tests passed: 0 / Tests failed: 1 / `$ echo $?` → `0`, annotated "a build step here would carry on to push and deploy".
- note.red (Correction): failed cases do not change the exit code. `adk eval` exits non-zero only on a missing dependency or an unreadable eval-set file; `agents-cli eval run` behaves the same. The scores are the result — the exit code is not.
- codelabel good: "Run the same case from pytest, and the threshold is enforced"; `pre.term` with the verbatim failure: `AssertionError: Following are all the test failures.` / `response_match_score for app Failed. Expected 0.9, but got 0.0.` (the threshold line marked `.chg`) / `1 failed in 4.56s` / `$ echo $?` → `1`.
- note.blue (Why this works): the threshold lives in the eval config (`response_match_score: 0.9`); `AgentEvaluator` compares each score against it and raises `AssertionError`. Comparing a score against a threshold *is* the gate; the only question is whether something does it.
- **Example**: one agent whose model always replies "I cannot help with that", one case expecting "Your refund is issued", threshold 0.9, run both ways on 2.9.0 → both report the failure; `adk eval` exits 0, pytest exits 1. `reproduced`
- takeaway: something has to compare the score to a threshold and fail. Wrap the eval in a test, or read the results file and check it yourself — never trust the command's exit code.
- src: `cli_tools_click.py` (`cli_eval`) and `agent_evaluator.py` at tag `v2.9.0` · agents-cli eval guide ("eval run exits 0 whatever the scores are") (verified 2026-09-12)
- Notes: both blocks are real output from the same one-case reproduction, not composed. Page 8 covers which mechanisms gate. The non-pytest gate is parsing `results_<ts>.json` and applying your own threshold.

## Page 7 — Two eval sets, maybe three

Type: concept.
- lede: The set that answers "did I break it?" in forty seconds is not the set that answers "is this release good?"
- table.cmp, cols: Tier / When it runs / Size / What it is for
  - On demand — you changed something you think moves behavior — ~10–15 cases — the local loop; answer in under a minute
  - **hl:** On PR — automatically, same trigger as the unit tests — ~50–100 cases — the gate; nothing merges past it
  - Periodic — nightly or weekly, on a schedule — the full set — depth you cannot afford per PR
- checks (2 rows): **Two sets is the common case**; the third appears when PR volume makes the full set too slow or too expensive to run every time. / **They differ in comprehensiveness, not in kind** — same format, same metrics, same gate mechanics.
- tag: `guidance` on the tiering rule.
- **Example**: Actor: a four-person team shipping ~10 PRs/day. Input: a 12-case smoke set, a 60-case PR suite, a 400-case nightly. Mechanism: local run ≈ 40 s; PR suite ≈ 6 min alongside the unit tests; nightly via `agents-cli eval submit` (the managed async path, documented for large or CI-driven runs). Result: a broken trajectory is caught in the loop, at the PR, or overnight — three nets with different mesh. `illustrative`
- takeaway: Two sets, maybe three, differing in size and cadence; every one of them needs its own gate.
- src: agents-cli eval guide, `eval submit`/`eval results` for "large or CI-driven runs" (verified 2026-09-12)
- Notes: the numbers are illustrative; cost scales with cases × turns × judge calls. Hold a slice of cases out of the local loop, or you fit the agent to the cases you iterate against (vendor guidance). Failing production conversations become new cases — that is how the sets grow.

## Page 8 — Four ways to run an eval

Type: comparison. **New page — replaces "Where each tier runs"; see Revision 1.**
- lede: Two CLIs, a test harness, and a browser UI. They are not interchangeable, and only one of them fails a build on its own.
- table.cmp, cols: Mechanism / What it is for / Dataset and thresholds / Gates?
  - `adk web` — the inner loop: chat, then **save that session as an eval case**; run a set and read results in the browser — ADK `.evalset.json` — no, you read them
  - `adk eval` — running an ADK eval set from a terminal or script — ADK `.evalset.json` + `test_config.json` — no, exits 0 (page 6)
  - `agents-cli eval` — the Agent Platform path: richer metrics, custom LLM judges, can target a **deployed** agent — Agent Platform dataset + `eval_config.yaml` — no, writes a results file
  - **hl:** `pytest + AgentEvaluator` — the gate: the same ADK eval set wrapped in a test — ADK `.evalset.json` + `test_config.json` — **yes, asserts**
- note.blue (adk eval vs. agents-cli eval): different lineages, not versions of each other. `adk eval` runs an ADK eval set against a local agent module. `agents-cli eval` splits into `generate` + `grade`, uses the Agent Platform dataset format, supports custom metrics, targets a deployed agent with `--url`, and has a managed cloud path via `eval submit`. Dataset files are not interchangeable.
- **Example**: Priya turns a bug report into a regression case — reproduce in `adk web`, save the session into the eval set, run `pytest tests/eval` to confirm it fails. The same file the PR job runs. `illustrative`
- takeaway: use the UI to build cases, a CLI to explore scores, and pytest where something must actually fail.
- src: `adk eval --help`, dev-server eval routes (`.../eval-sets/{id}/add-session`, `/run`), google-adk 2.9.0 · `agents-cli eval --help`, google-agents-cli 1.5.0 (verified 2026-09-12)
- Notes: the `add-session` route is the cheapest way to grow an eval set from real conversations. For the PR job, `pytest tests/eval` needs no extra threshold code; the alternative is `agents-cli eval run` plus a script reading `results_<ts>.json`. `adk test` is deliberately absent — it replays fixtures against a mocked model (page 5).

## Page 9 — What Google ships, and what it leaves you

Type: comparison.
- lede: `agents-cli` scaffolds a complete pipeline. It is worth knowing exactly where the eval step is in it.
- table.cmp, cols: Stage / Trigger / What it runs
  - CI (PR checks) — pull request — `pytest tests/unit`, `pytest tests/integration`
  - Staging CD — merge to `main` — build, push `:$SHORT_SHA`, deploy staging, **load test**
  - Production CD — after staging — deploy to prod, optionally behind manual approval
- note.red (The gap): `tests/eval/` is scaffolded — datasets and an LLM-as-judge metric — and no pipeline stage calls it. Across the 24 shipped pipeline files there is not one occurrence of "eval". The wiring is yours to add.
- checks (2 rows, green/blue): **What to keep** — the stage shape, WIF auth with no long-lived keys, staged promotion with approval. / **What to add** — the eval gate at the CI stage, beside the tests that are already there.
- takeaway: The scaffold gives you the pipeline and the eval artifacts, and does not connect them. That is the one edit to make on day one.
- src: google-agents-cli 1.5.0 scaffold templates (`.cloudbuild/`, `.github/workflows/`); agents-cli deploy guide, CI/CD pipeline stages (verified 2026-09-12)
- Notes: checked by grepping all 24 pipeline files for "eval" — zero matches, with a "pytest" grep as the control. Not a criticism of the tool: a default cannot know your thresholds. Say plainly that this is the deck's recommendation, not a Google prescription — no vendor doc prescribes eval placement in CI.

## Page 10 — Section 1 recap

Type: recap, green dots, 5 rows:
- The artifact is code; the pipeline adds exactly one step, because model output is graded rather than asserted.
- Unit tests say it ran, integration says a turn completed, only the eval says what it decided.
- `adk eval` exits 0 on failure — gate with a pytest assert or a score check.
- Two eval sets, maybe three: on demand, on PR, periodic.
- On a PR, evaluate the merge result, not the branch tip.

---

## Page 11 — Section divider 2

kicker: Section 2 of 3 · h1: Targets and configuration · dsub: Three places an agent runs, what actually decides between them, and what each one needs configured.

## Page 12 — Four ways to ship the same agent

Type: comparison.
- lede: The same agent, four routes to production. They differ in how much of the build you own.
- table.cmp, cols: Route / What you write / What it does / Use it when
  - Manual — Dockerfile, `docker build/push`, `gcloud run deploy` — you own every step — learning, or a one-off
  - Cloud Build — the same, in `cloudbuild.yaml` — a trigger runs it on push or PR — you want it automated and auditable
  - `adk deploy` — one command — targets `agent_engine`, `cloud_run`, `gke`, `docker` — an ADK agent, no project scaffold
  - **hl:** `agents-cli deploy` — one command + a manifest — dispatches on `agents-cli-manifest.yaml`; Cloud Run path shells to `gcloud beta run deploy`, GKE to terraform + kubectl — a scaffolded project; the default
- note (Caveat): There is no `gcloud` command for Agent Runtime. Deploy it with `agents-cli deploy` or `adk deploy agent_engine`; query it through the SDK.
- takeaway: Pick by how much of the build you want to own; the artifact that reaches production is the same container either way.
- src: `adk deploy --help` (google-adk 2.9.0), `agents-cli deploy --help` (1.5.0) (verified 2026-09-12)
- Notes: `--staging_bucket` is deprecated in 2.9.0 ("no longer required or used") — older tutorials still pass it. `--image` skips the source build for Cloud Run/GKE.

## Page 13 — What actually decides the target

Type: comparison. **Replaces slides 10–12.**
- lede: The source decks compare these on hardware acceleration. Your agent loop is I/O-bound CPU work on all three, so that row decides nothing.
- table.cmp, cols: / Agent Runtime / Cloud Run / GKE
  - Who owns the URL — nobody; it is `reasoningEngines/NNN` behind the Vertex AI API — you do: a service URL, ingress, IAP — you do: Kubernetes networking
  - Sessions — wired to its own instance automatically — managed Sessions, Cloud SQL, or in-memory — same as Cloud Run
  - Model-written code — Code Execution sandbox (Preview) — Cloud Run sandboxes (Preview), `--with_cloud_run_sandbox` — GKE Agent Sandbox (GA, gVisor)
  - Ops you own — none: no Dockerfile to serve, no server — container + networking — a cluster
  - Pick it when — you want the shortest path and no server to own — you need your own domain, IAP, full networking — you already run Kubernetes
- note.red (Correction): The source says "isolate untrusted code with GKE Sandbox" on the Cloud Run row. GKE Sandbox is a GKE node feature. Cloud Run's own instance sandbox protects the platform from your container, not your agent from code the model wrote — that is what Cloud Run sandboxes add.
- **Example**: Actor: a two-person team with no infrastructure owner. Input: a Python ADK support agent. Mechanism: `agents-cli deploy` to Agent Runtime — no Dockerfile to serve, no ingress, no invoker role. Result: answering at its `reasoningEngines` endpoint. Six months later security wants a company domain and a Cloud Armor policy, which needs a URL the team owns — that is when the target changes to Cloud Run, and the Sessions instance follows unchanged via `agent_engine_id`. `illustrative`
- takeaway: Choose on URL ownership, session wiring, and code-execution isolation. None of the three needs an accelerator to run an agent — the model runs elsewhere.
- src: Cloud Run sandboxes (Preview) · GKE Agent Sandbox (GA) · Agent Runtime overview · companion m2 §09–12 (verified 2026-09-12)
- Notes: Sessions and Memory Bank are Agent Platform services, not runtime features — an agent on Cloud Run or a laptop uses them by passing `agent_engine_id`. Pod Snapshots are startup time, not conversational memory. Launch stages move; re-check before delivery.

## Page 14 — Configuring a deployment

Type: code + concept.
- lede: Same agent, three targets, and the switch that turns on telemetry is in a different place for each.
- table.cmp, cols: What you want / Agent Runtime / Cloud Run or GKE
  - Traces, metrics, logs — `--otel_to_cloud` at deploy, or the telemetry env var — `--otel_to_cloud`, or `get_fast_api_app(otel_to_cloud=True)` in your server
  - Secrets — `--secrets "API_KEY=my-secret:3"` — same flag; or mount in Kubernetes
  - Identity — `--agent-identity`, or `--service-account` — `--service-account`
  - Private egress — `--network-attachment` (PSC interface) — VPC connector / direct egress
- codelabel: Sizing — the defaults, and why they move together
- pre.term: `agents-cli deploy --cpu 1 --memory 4Gi --concurrency 8 --max-instances 10` with `.lbl` comment lines marking each default
- note (Caveat): The sizing parameters are coupled. Each in-flight request holds its whole context window in memory while it waits on the model, so peak ≈ base + concurrency × per-request memory. Raising `--concurrency` without `--memory` is the usual cause of OOM restarts. `heuristic`
- takeaway: Telemetry, secrets, and identity are one flag each; sizing is the one place you have to think, because memory bounds concurrency.
- src: `agents-cli deploy --help` (1.5.0) · agents-cli deploy guide, "Sizing a deployment" · `fast_api.py` `get_fast_api_app(otel_to_cloud=...)`, google-adk 2.9.0 (verified 2026-09-12)
- Notes: `--trace_to_cloud` is deprecated in 2.9.0 in favor of `--otel_to_cloud` (OTLP, all three signals, one endpoint). Defaults `min-instances 0` (scale to zero) but the generated Terraform pins 1 to avoid cold starts — a real inconsistency worth naming. On Agent Runtime CPU is throttled the moment a request ends, so ADK installs a per-request metrics flush.

## Page 15 — The pipeline, corrected

Type: code. **Rebuilds source slide 29.**
- lede: The source deck's pipeline has three defects, and two of them are silent.
- codelabel bad: The source pipeline (slide 29), three defects
- numrows (3 bad rows): `${_PROJECT_ID}` in the deploy step is an undefined user substitution, while the build step uses the built-in `$PROJECT_ID`. / The image has no tag, so every build overwrites the same reference and no revision names its commit. / There is no eval step at all.
- codelabel good: Fixed — the four steps that matter
- pre.code (≤ 20 lines): `substitutions:` block declaring `_DEPLOY_PROJECT_ID`, `_REGION`, `_REPO`; step 1 docker build `-t …/agent:$COMMIT_SHA`; step 2 `pytest tests/unit && pytest tests/eval` with comment `# the gate: AgentEvaluator asserts`; step 3 push; step 4 `gcloud run deploy … --quiet`; `images:` declaring the tagged artifact.
- takeaway: Tag with the commit, declare your substitutions, run the eval gate before push, and deploy with `--quiet` so the build never waits on a prompt.
- src: Cloud Build substitutions and `cloudbuild.yaml` schema; companion m2 §29 (verified 2026-09-12)
- Notes: `$COMMIT_SHA` is empty for a manual `gcloud builds submit` — an image tagged with it gets an empty tag. For Agent Runtime, step 4 is `agents-cli deploy`. A private worker pool is what you need if the eval step must reach a private-IP resource.

## Page 16 — Section 2 recap

Type: recap, green dots, 4 rows:
- Four routes to production; `agents-cli deploy` off a manifest is the default for a scaffolded project.
- Choose the target on URL ownership, sessions, and code-execution isolation — not accelerators.
- Telemetry, secrets, and identity are one flag each; sizing is coupled, and memory bounds concurrency.
- Tag images with the commit so a running revision names the commit that built it.

---

## Page 17 — Section divider 3

kicker: Section 3 of 3 · h1: Governing what the model reads · dsub: The model decides from two things you control: which model it is, and what your tools say they do.

## Page 18 — Model governance

Type: concept.
- lede: Staging pins `gemini-2.5-flash`. Production points at a `-latest` alias. One Tuesday, production starts formatting tool calls differently and staging never saw it.
- checks (3 rows): **Pin the model id per environment** — an alias is a mutable named reference; it resolves to different versions over time, so an alias in production means the model can change with no commit. / **Treat a model change as a release** — change the id in the repo, run the eval set, compare against the recorded baseline, canary. / **Model families retire on a schedule** — the upgrade is a matter of when, so rehearse it in staging.
- note.blue (Rule): If your agent uses a foundation model, Model Registry is not in your path — it is for models you train or tune. The two rules above are the whole practice.
- **Example**: Actor: the release. Input: model id changes from `gemini-2.5-flash` to its successor. Mechanism: the PR runs the 60-case suite; tool-call accuracy drops on 5 cases where the new model formats arguments differently. Result: blocked at the gate; the instruction is adjusted and re-run before any traffic sees it. `illustrative`
- takeaway: Pin the id, and put a model change through the same gate as a code change — because it is one.
- src: Model Registry version aliases (a mutable named reference to a version); companion m2 §21 (verified 2026-09-12)
- Notes: ADK 2.9.0 adds `FallbackModel` for automatic failover to a backup model on error — availability, not governance; mention only if asked, and note that a fallback means the model that answered may not be the one you pinned.

## Page 19 — Tool and MCP governance

Type: concept.
- lede: A tool described as "Refund an order." gets called by a customer asking what the refund policy is.
- checks (4 rows): **The description and schema are the interface to the model** — it chooses tools by reading them, so a vague description produces wrong calls. Review them like code. / **Least privilege per environment** — the dev credential for a tool must not reach production data; a wrong call is bounded by what the tool can do. / **Log every invocation** with agent id, model version, and user — the audit trail, and later the cost-attribution key. / **Agent Registry is the catalog** — one place to register and discover MCP servers, tools, and agents across the organization.
- **Example**: Actor: the refund agent. Input: `issue_refund(order_id, amount)`, described as "Refund an order." Mechanism: the description is changed to "Issue a refund. Only call after the customer confirms and the order status is delivered." Result: the false calls in the eval set disappear. Only the docstring changed — no logic, no model. `illustrative`
- takeaway: Tool descriptions are prompt code: they change behavior, they get reviewed, and they go through the eval gate.
- src: Agent Registry overview (agents, MCP servers, tools, skills); companion m2 §24–25 (verified 2026-09-12)
- Notes: Apigee can expose an existing API as an MCP server; MCP Toolbox for Databases covers governed database access without a hand-written tool per query. A2A discovery (source slide 23) is multi-agent architecture — point at Agent Registry and move on.

## Page 20 — The supporting cast

Type: comparison (tour). **Keep this short — one line each.**
- lede: Four services the pipeline uses. If you know them, this is a checkpoint, not a lesson.
- grid c4 cards: **Artifact Registry** — stores the built image, scans on push. **Cloud Build** — runs the steps on a trigger; serverless. **Cloud Deploy** — staged promotion with approvals for Cloud Run and GKE; Agent Runtime needs a custom target. **Secret Manager** — tool credentials and API keys, versioned; never in the repo.
- note.blue (The one specific worth keeping): Tag the image with the commit — `agent:$COMMIT_SHA`. Then `gcloud run revisions list` names the commit that built what is serving, and `git show` is the diff to read. With a floating tag you are matching build timestamps to the git log.
- takeaway: Generic CI/CD services, used generically — the only agent-specific habit here is tagging with the commit so a behavioral regression is a diff you can find.
- src: companion m2 §15–18 (verified 2026-09-12)
- Notes: this page is a tour by explicit instruction of the brief — do not expand it. Terraform: the lab covers it; the Agent Runtime resource uses `lifecycle.ignore_changes` on the container spec so Terraform owns infrastructure and the pipeline owns the agent version. Worker pools: a private pool is needed when a build step must reach a private IP.

## Page 21 — You observed → because → so you…

Type: consequences. table.cmp:
| You observed | Because | So you… |
| The build is green and the agent still regressed | `adk eval` exits 0 whatever the scores are | Gate on a pytest assert or a score check, not the command's exit code |
| Both branches passed; the merge broke | Each was evaluated alone, against its own branch tip | Evaluate the merge result on the PR, where `on: pull_request` already points |
| The eval suite is too slow to run per PR | One set is being asked to do every job | Split it: a small set on demand, a medium set on the PR, the full set nightly |
| Production formats tool calls differently than staging | Production points at a mutable model alias | Pin the model id per environment; upgrade through the pipeline |
| The agent calls a tool for a question it should answer itself | The model chose from the tool's description, and it was vague | Rewrite the description, re-run the evals; nothing else needs to change |
| A revision misbehaves and nobody can find the commit | The image carries a floating tag | Tag with `$COMMIT_SHA`; the revision then names its commit |
| OOM restarts after raising throughput | Each in-flight request holds its context window; memory bounds concurrency | Raise `--memory` with `--concurrency`, then load-test |

## Page 22 — References

Type: references. Links: google/adk-python at tag `v2.9.0` · agents-cli 1.5.0 (`deploy`, `eval`) · Cloud Run sandboxes · GKE Agent Sandbox · Agent Registry · Model Registry aliases · Cloud Build substitutions · GitHub Actions events · martinfowler.com Continuous Integration · companion `agent_operations/m2.html`.
- note (Re-verify before delivery): Product names, launch stages (Cloud Run sandboxes and Agent Runtime Code Execution are Preview), CLI flags, and default values were verified on **2026-09-12** against google-adk 2.9.0 and google-agents-cli 1.5.0. The eval exit-code behavior was reproduced on that baseline. All of it changes without notice.
