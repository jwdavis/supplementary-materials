# Module 2 — concept list

Delivery minutes (non-lab): **35** (Jeff, 2026-09-12) → page budget ≈ 35 / 2.5 = **14 content pages**

Baseline: google-adk **2.9.0** (tag `v2.9.0`, 2026-09-10), google-agents-cli **1.5.0**.
The companion page `agent_operations/m2.html` was verified against 2.7.1 / 2026-08-25;
anything it dates is re-verified here.

| # | Concept | Agent-specific? | Example (actor / input / mechanism / result) | Verify against | Disposition | Pages |
|---|---|---|---|---|---|---|
| 1 | The pipeline is the same as any service's, plus one step: an eval run. The artifact is code — instruction, tools, model id, config all live in the repo | **yes**: non-determinism of model output — unit tests cannot check what the model decides | Priya edits one sentence of the refund instruction; unit tests pass (nothing they cover changed); the eval set's 3 unshipped-order cases fail the trajectory check | companion m2 §04; Fowler CI | focus | 1 |
| 2 | Three kinds of check, three different things they catch: unit (logic, mocked), integration (agent runs, real model), eval (behavior graded) | **yes**: correctness is multi-dimensional — trajectory, response, safety | `adk test` replays recorded events against a *mocked* model (deterministic); the scaffolded integration test calls the real model and asserts only "some text came back"; only the eval scores the decision | ADK v2.9.0 `agent_test_runner.py` (mocks `BaseLlm`); scaffold `tests/integration/test_agent.py` | focus | 1 |
| 3 | **The eval CLI does not gate.** `adk eval` prints "Tests failed: 1" and exits 0; the gate must be a pytest assert or an explicit score check | **yes**: model output is graded, not asserted, so pass/fail is a threshold decision the tool declines to make | Reproduced: stub-model agent, 1 failing case → `Tests passed: 0 / Tests failed: 1`, exit 0. Same case via `AgentEvaluator.evaluate` under pytest → exit 1 | `cli_tools_click.py:1270-1510` (no failure exit); `agent_evaluator.py:289` (`assert not failures`); vendor: "eval run exits 0 whatever the scores are" | focus | 1 |
| 4 | Tiered eval sets: on-demand small (local), on-PR medium (automated), periodic large (nightly/weekly) | **yes**: eval sets are maintained artifacts, and per-token cost grows with set size, so comprehensiveness is traded against cost/time | Team of 4, ~10 PRs/day: 12-case smoke locally (~40 s), 60-case suite on every PR (~6 min), 400-case suite nightly via `eval submit` | Jeff's stated practice; `eval submit` documented for "large or CI-driven runs" | focus | 2 |
| 5 | Where each tier runs: local loop, PR trigger, schedule. On a PR the eval runs against the **merge result**, not the branch tip | generic (trigger mechanics) — say so; the *what-runs* is agent-specific | `on: pull_request` + `actions/checkout` → GITHUB_REF is the merge branch, so Marco's tool rename and Priya's instruction edit are evaluated together before either merges | GitHub Actions docs; scaffold `.github/workflows/pr_checks.yaml` | focus | 1 |
| 6 | What Google actually ships, and the gap: CI = unit + integration, staging = load test, prod = approval. No eval stage; `tests/eval/` is scaffolded but unwired | generic (pipeline shape) | 24 shipped pipeline files, zero occurrences of "eval"; `tests/eval/response_quality.py` (LLM-judge) ships beside them, called by nobody | `google-agents-cli` 1.5.0 scaffold templates; `references/cicd-pipeline.md` | focus | 1 |
| 7 | Four ways to get an agent onto Google Cloud, and when each is the right one | generic (deployment mechanics) — say so | manual docker+gcloud → same in Cloud Build → `adk deploy` → `agents-cli deploy` (reads `agents-cli-manifest.yaml`) | `adk deploy --help`, `agents-cli deploy --help` at pinned versions | focus | 1 |
| 8 | The three targets differentiated by what actually decides between them: who owns the URL, where sessions live, how model-generated code is isolated | **yes**: the model writes code the agent may execute, bounded by the agent's permissions | Two-person team, no infra owner → Agent Runtime (no Dockerfile, no URL to own). Security later wants a company domain + Cloud Armor → Cloud Run; the Sessions instance comes along unchanged via `agent_engine_id` | companion m2 §09-12, re-verified; Cloud Run sandboxes (Preview); GKE Agent Sandbox (GA) | focus | 2 |
| 9 | Configuration per target: env vars on Agent Runtime, `get_fast_api_app` switches / `--otel_to_cloud` elsewhere; sizing params are coupled | **yes**: the model is an external dependency, and per-request memory scales with context | Defaults `--cpu 1 --memory 4Gi --concurrency 8 --max-instances 10`; raising concurrency without memory is the main OOM cause because each in-flight request holds its whole context window | `agents-cli deploy --help`; deploy skill "Sizing a deployment" | focus | 1 |
| 10 | Model governance: pin the model id per environment; treat a model change as a release that goes through the eval gate | **yes**: the model is a versioned external dependency with retirement dates | Staging pins `gemini-2.5-flash`, prod uses a `-latest` alias; the alias moves, prod's tool-call formatting changes, staging never showed it | Model Registry aliases (mutable named ref); companion §21 | related | 1 |
| 11 | Tool and MCP governance: the description and schema are what the model decides from, so they are reviewed like code; Agent Registry is the catalog | **yes**: the model chooses tools by reading their text | `issue_refund` described as "Refund an order." → called for a policy question. Description changed to "Only call after the customer confirms and the order status is delivered" → false calls gone. Only the docstring changed | Agent Registry (agents, MCP servers, tools, skills); companion §24-25 | related | 1 |
| 12 | The tour: Artifact Registry, Cloud Build, Cloud Deploy, Secret Manager — one line each, plus the one specific that matters (tag with the commit) | generic — say so | `agent:$COMMIT_SHA` means the serving revision names the commit it was built from; with `latest` you match build timestamps to the git log | companion §15-18 | tour | 1 |

**Total content pages: 14** (+ opener, objectives, 3 section dividers, 2 recaps, consequences, references = **8 structural**) → 22 pages.

## Order and why

The spine is **what makes an agent pipeline different → where it runs → what you govern**.

Section 1 opens with the one structural difference (concept 1) because everything else
in the module hangs off it, then immediately distinguishes the three kinds of check
(2) so "eval" is a defined term before it is used. Concept 3 is the correction the
whole section exists to deliver, and it must come before tiering, because the tiering
advice is worthless if each tier silently passes. Tiering (4) and placement (5) then
answer the brief's developer/CI questions in order. The section closes on what Google
ships (6) — deliberately last, so the gap reads as "here is the baseline you extend,"
not as the recommendation.

Section 2 needs section 1 only for the eval gate (it appears as a pipeline step).
Mechanisms first (7), then the target decision (8), then configuration (9) — you
cannot discuss `--otel_to_cloud` or min-instances before knowing which target owns
the server.

Section 3 is governance, and it needs the eval gate from section 1: both the model
rule (10) and the tool rule (11) resolve to "change it, run the evals, canary."

## Cut from the source, and why

- **Slides 4–7** (CI/CD definition, CI, CD, benefits) — the brief cuts these. One
  definition page's worth survives as concept 1's frame, with the Fowler correction
  (CI is merge *plus automated verification*) and the delivery-vs-deployment
  distinction in speaker notes only.
- **Slide 23** (A2A discovery: well-known URI, curated registries, direct config) —
  multi-agent architecture, not CI/CD. One line in notes pointing at Agent Registry.
- **Slides 30–31** (Cloud Build worker pools, default vs private feature table) —
  brief excludes unless the tour needs them. One note: a private pool is what you
  need when an eval step must reach a private-IP resource.
- **Slide 19** (Terraform/IaC) — folded to one row of the tour page; the lab covers it.
- **Slides 21–22** (model governance for teams training their own models: lineage,
  hyperparameters, semantic versioning) — rewritten to the two rules in concept 10.
  Most attendees use a foundation model and never register one.
- **Hardware acceleration rows** (slides 10–12) — they compare targets for the *model*
  deployment, not the agent loop. One sentence: none of the three needs an
  accelerator to run an agent; the model runs elsewhere.

## Open questions for Jeff

- Concept 4's tiering is stated as recommended practice tagged `guidance`, not as a
  documented Google prescription — no vendor doc prescribes eval placement in CI.
  Flagging the epistemic status rather than asking you to re-decide it.
