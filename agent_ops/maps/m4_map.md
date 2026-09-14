# Module 4 deck map — Agent Evaluation and Quality Assurance

Source: `agent_operations/M4-Agent Evaluation and Quality Assurance.pdf` and the companion
`agent_operations/m4.html`. Brief: `agent_ops/briefs/m4.md`. Concept list:
`agent_ops/maps/m4_concepts.md` (approved 2026-09-13). Secondary sources: `agent_ops/m2-d.html`
pages 4–10 (the M2 eval section, which this module points to and does not repeat) and
`agent_ops/m3.html` pages 18–21 and 28 (telemetry setup and the outcome-counter alert).

Baseline: google-adk **2.9.0** (PyPI wheel read 2026-09-13), google-agents-cli **1.5.0**,
google-cloud-aiplatform **1.165.1** (vendors the `agentplatform` SDK). Doc pages fetched 2026-09-13.
Two things were measured in `jwd-gcp-demos` on 2026-09-13 and cleaned up afterward: importing a
local-run Cloud Trace trace into an evaluation set (`scratchpad/m4_trace_import.py`) and scoring it
server-side (`scratchpad/m4_score_run.py`). ROUGE-1 figures were computed with `rouge_score`.

**35 pages: 24 content (22 required + 2 optional) + opener, objectives, 4 dividers, 3 recaps,
consequences, references.** ≈55 min required against a 50-min budget; Jeff accepted the overage
and asked for no folds.

## Organizing frame

| Question | Answer | Section |
|---|---|---|
| What does an eval grade that a test cannot? | The decision: the trajectory and the answer, each with its own metric, each a score against a threshold | 1 · What gets graded (pages 4–16) |
| What is the managed service, and how does it relate to ADK's metrics? | Three layers. ADK is the local harness and delegates five metrics to the service; the service is the scorer plus the production half; agents-cli is a front end | 2 · The managed layer (pages 18–22) |
| Where does evaluation run once the agent is live, and how does a team hear about a drop? | On demand over traces, continuously with a monitor, alerted by an ordinary Monitoring policy, fed back into the set | 3 · In the lifecycle (pages 24–30) |
| What else exists? | Conformance replay; simulation, optimization, custom metrics | 4 · Optional (pages 32–33) |

## What changed vs. the sources, and why

- **Slides 4–11 (unit-testing an LLM function, judging a marketing post) are one sentence on page 5.**
  Generic LLM-application testing, not agent evaluation; their code no longer imports.
- **Slides 13–16 (definition, "why critical", maturity model, business challenges) are page 4**, a
  worked trajectory regression reused from M2 page 4, so the course compounds.
- **Slide 25 is rebuilt as page 8.** Its four field names (`determine_intent`, `use_tool`,
  `review_results`, `report_generation`) do not exist. The companion page's per-step averaging is
  also out of date: on 2.9.0 an invocation scores 1.0 or 0.0.
- **Slide 26's six trajectory matches are noted on page 18 and replaced by the three ADK match
  types on page 8.** They are `v1beta1 evaluateInstances` inputs, absent from the current metric set.
- **Slides 27–31 (test file vs. evalset, four slides) are page 7.** Same schema, two discoverers.
- **Slides 19–21 (metric lists) are rebuilt as pages 10 and 20** from the current metric sets.
- **Slide 40 (model eval vs. agent eval) is replaced by pages 18–19.** It was a false split.
- **Slides 35–38 (three ways to run, CLI, pytest, CI pipeline) are Module 2's.** Page 14 keeps
  the one fact this module needs and the corrected `await`.
- **Added, from no source slide:** rubrics as a concept (12); judge configuration and cost (13);
  the name-by-name ADK/service mapping and the harness rule (19); how a trace becomes gradable per
  runtime (25), with a measured result; Online Monitors (27); the alert policy (28); loss analysis
  (29); conformance (32); related topics (33).

## Diagram convention

Boxes carry literal values in `var(--mono)`; labels in `var(--sans)`. Blue is the thing being
graded (a trajectory, a reply, a trace). Green is the expected value or a pass. Red is a mismatch
or a fail. Gray is scaffolding. Arrows are data flow, left to right, and are labeled with what
moves (a tool call, a score, a trace). Every diagram has explicit `width`/`height` equal to its
viewBox, ≤ 1000 wide, and a per-page marker id. When a diagram is a simplification, its caption
says "mental model".

---

## Page 1 — Module opener

**Type:** Module opener (`.page.divider`, module number 04, `dsub`, `agenda`).

**Title:** Agent Evaluation and Quality Assurance

**dsub:** What an eval grades that a test cannot, how a score becomes a pass, and how the same
grading runs against production.

**Agenda:** 1 What gets graded · 2 The managed layer · 3 In the lifecycle · 4 Optional: replay,
simulation, optimization

**Notes:** Baseline on the face of the references page: google-adk 2.9.0, google-agents-cli 1.5.0,
google-cloud-aiplatform 1.165.1. This module is taught before Module 2; wherever it touches
pipeline placement it says "Module 2" and moves on. Delivery beat: ask who has an eval set today,
and who has one that a build depends on. The gap between those two hands is the module.

---

## Page 2 — What you will be able to do

**Type:** Objectives (`.numrows`).

1. Explain what an eval grades that a unit test cannot, and name the two properties of agents that make it necessary.
2. Write an eval case by hand and say which metrics read which of its fields.
3. Compute `tool_trajectory_avg_score` and `response_match_score` for a given case, and say why each passes or fails.
4. Choose among the thirteen ADK criteria for four scenarios, and configure a judge with its cost in mind.
5. Say which ADK criteria are the same thing as a service metric, which are a different scorer, and which harness a team uses when.
6. Turn a production trace into an evaluation item from any runtime, run an offline evaluation, create a monitor, and alert on its score.

**Notes:** Objective 6 is the one the source deck does not attempt. It is also the one this deck
measured (page 25).

---

## Page 3 — Section divider: What gets graded

**Type:** Section divider (section 1 of 4, `.kicker` "Section 1", `dsub`).

**dsub:** A recorded conversation, a metric that reads it, a score, and a threshold. Eleven pages,
one case.

**Notes:** The section reuses one case throughout: the refund agent and order 6041. Say so here so
nobody waits for a new scenario.

---

## Page 4 — A test checks execution. An eval grades the decision.

**Type:** Mechanism (`.lede` + full-width `figure > svg` + `.checks` + `.ex` + `.takeaway` + `.src`).

**Lede:** Priya changes one clause of the refund agent's instruction. Every test passes. The agent
now refunds orders that never shipped.

**Body (`.checks`):**
- **A test checks correct execution of deterministic code.** It asserts on a code path. No code path changed; the instruction is text.
- **An eval grades the quality of a response and the path the agent took to produce it.** The path is the trajectory: which tools, which arguments, in what order.
- **Two properties of agents make this necessary.** The same input can produce a different trajectory on the next run. And correctness has several dimensions at once: trajectory, answer, safety, cost.
- **The instruction, the tool definitions, and the model id are source files.** They live in the repo and change in a reviewed diff. An eval is how that diff is checked.

**Diagram (960×230):** Two rows, labeled at left in sans: **before the edit** (green rule) and
**after the edit** (red rule). Each row is a chain of mono boxes joined by arrows: user box
`"refund order 6041"` (gray) → `get_order(id=6041)` (blue) → `verify_shipment(id=6041)` (blue in
row 1; in row 2 the box is dashed red with the text `skipped`) → `issue_refund(id=6041)` (blue) →
reply box `"I've taken care of that."` (gray). To the right of each row, two result chips:
`answer check: pass` (green in both rows) and `trajectory check: 1.0` (green, row 1) /
`trajectory check: 0.0` (red, row 2). Caption inside: "Same reply, different path. Only the
trajectory check sees it."

**Example (`.ex`, labeled rows):**
- **Actor:** Priya, editing the refund agent's instruction.
- **Input:** "refund order 6041", before and after the edit.
- **Mechanism:** before, the trajectory is `get_order → verify_shipment → issue_refund`; after a later wording change, `get_order → issue_refund`. The final reply is the same sentence both times.
- **Result:** an answer check passes. A trajectory check scores the second run 0.

**Takeaway:** An eval replays a recorded conversation and grades what the agent decided. Nothing
else in the test suite reads a decision.

**Sources:** M2 page 4 (`agent_ops/m2-d.html`); `trajectory_evaluator.py` (google-adk 2.9.0).

**Notes:** Agent-specific, on two mechanisms: non-determinism of model output and multi-dimensional
correctness. Delivery beat: show the two rows, ask which existing test would catch row 2, then
reveal the chips. Hand-off: page 6 shows the file that records the green row.

---

## Page 5 — Model evaluation happens first, and picks the model

**Type:** Concept (`.lede` + `.checks` + `.ex` + `.note.gray` + `.takeaway` + `.src`).

**Lede:** Before the refund agent exists, Marco has to choose a model. That is the one place model
evaluation belongs in this module.

**Body (`.checks`):**
- **Pointwise:** score one model's responses against metrics. **Pairwise:** compare two candidates' responses and pick one.
- **The Gen AI evaluation service runs either** over a prompt set with `client.evals.evaluate`, using the same rubric metrics the agent pages use later (`TEXT_QUALITY`, `INSTRUCTION_FOLLOWING`, `SAFETY`).
- **After the decision, the model id is a line in the repo.** From then on the agent is what gets evaluated, and a model change is a diff that the agent eval set catches.
- **The source deck's slides 4–11** test an LLM-backed function with `unittest` and a judge prompt. That is application testing, not agent evaluation, and its SDK import was removed on 2026-06-24.

**Example (`.ex`):**
- **Actor:** Marco, before writing agent code.
- **Input:** 30 representative prompts; two candidate model ids.
- **Mechanism:** `client.evals.evaluate` with `TEXT_QUALITY` and `INSTRUCTION_FOLLOWING`; latency recorded per response.
- **Result:** the cheaper model scores within 0.02 and answers in half the time. Its id goes in `config.py` <span class="tag illus">illustrative</span>.

**Note (gray):** Generic. Model selection is not agent-specific; it appears here because the brief
asked where model evaluation fits, and the answer is "before the agent, once".

**Takeaway:** Evaluate models to choose one; evaluate the agent forever after.

**Sources:** [evaluate-agents](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/evaluate-agents);
source slides 17, 40; companion page 4 (SDK module removal).

**Notes:** Pairwise is what an A/B on prompt variants uses too; mention it and move on. If asked
about ROUGE/BLEU: one of them appears on page 9 as `response_match_score`; the rest are for
translation and summarization and are not used by any agent metric.

---

## Page 6 — An eval case is a recorded conversation with the expected trajectory inside it

**Type:** Code (`.lede` + `.codelabel` + `pre.code` + `.checks` + `.takeaway` + `.src`).

**Lede:** The green row on page 4, written down so a machine can replay it.

**Code (`.codelabel` "refunds.test.json — EvalSet schema, google-adk 2.9.0"):**
```json
{
  "eval_set_id": "refunds",
  "eval_cases": [{
    "eval_id": "refund_6041",
    "conversation": [{
      "invocation_id": "inv-1",
      "user_content":  {"role": "user",  "parts": [{"text": "refund order 6041"}]},
      "final_response": {"role": "model", "parts": [{"text": "Your refund of $42 has been issued."}]},
      "intermediate_data": {
        "tool_uses": [
          {"name": "get_order",       "args": {"id": 6041}},
          {"name": "verify_shipment", "args": {"id": 6041}},
          {"name": "issue_refund",    "args": {"id": 6041}}
        ],
        "tool_responses": [],
        "intermediate_responses": []
      }
    }],
    "session_input": {"app_name": "refund_agent", "user_id": "test_user", "state": {}}
  }]
}
```

**Body (`.checks`):**
- **`user_content`** is the prompt. **`final_response`** is the reference answer. **`tool_uses`** is the expected trajectory, in order, with arguments.
- **`tool_responses`** records what each tool returned. It is here for metrics that need it; page 8 says which do not.
- **Reference-based metrics read `final_response` and `tool_uses`.** Reference-free metrics read only the prompt and what the agent did, so a case can omit both.
- **The file is code.** It lives in the repo, and a change to it is a reviewed diff.

**Takeaway:** One invocation, three fields a metric reads, and the whole schema fits on a page.

**Sources:** `eval_set.py`, `eval_case.py:36-42` (google-adk 2.9.0);
[adk.dev/evaluate](https://adk.dev/evaluate/) schema block.

**Notes:** Agent-specific: eval sets are maintained artifacts, and a case records a trajectory. The
legacy flat format (`[{query, expected_tool_use, reference}]`) still loads with a warning; page 7.
`session_input.state` is where a case pins initial session state (a logged-in user, a cart). Multi-
turn: more invocations in `conversation`. Delivery beat: point at `tool_uses` and say "page 4's
green row".

---

## Page 7 — Test file and evalset: one schema, two discoverers

**Type:** Comparison (`.lede` + `table.cmp` + `.ex` + `.takeaway` + `.src`).

**Lede:** The source deck spends four slides on the difference. There is one.

**Table (`table.cmp`):**

| | `.test.json` | `.evalset.json` |
|---|---|---|
| Schema | `EvalSet` | `EvalSet` |
| Found by | `AgentEvaluator.evaluate`: given a directory, walks it recursively for this suffix; reads `test_config.json` beside each file | `adk web` and `adk eval_set` create and manage it; `adk eval` takes it by path or id |
| Loader | `_load_eval_set_from_file`: parse `EvalSet`; on failure, fall back to the legacy flat list with a warning | same |
| Convention | one short session, run often | many sessions, run less often |

**Example (`.ex`):**
- **Actor:** Priya.
- **Input:** a session saved from `adk web` as `refunds.evalset.json`.
- **Mechanism:** pytest never sees it. She copies it unchanged to `tests/eval/refunds.test.json`; `AgentEvaluator.evaluate(agent_module, "tests/eval")` finds it.
- **Result:** same bytes, two discoverers.

**Takeaway:** The suffix decides which tool finds the file. Nothing else differs.

**Sources:** `agent_evaluator.py:340-346, 394-421`, `local_eval_sets_manager.py:46` (google-adk 2.9.0).

**Notes:** Generic (a file-discovery convention); say so. The "old format vs. new format" question
is separate from the suffix: the fallback applies to either suffix, and
`AgentEvaluator.migrate_eval_data_to_new_schema` converts a legacy file. In practice capture cases in
`adk web` and the current schema is what you get.

---

## Page 8 — How a trajectory becomes a number

**Type:** Mechanism (`.lede` + full-width `figure > svg` + `.checks` + `.ex` + `.takeaway` + `.src`).

**Lede:** `tool_trajectory_avg_score` is the default trajectory metric. Here is what it computes on
page 4's case, extended to two invocations.

**Diagram (960×300):** Two invocation panels side by side, each a two-column mono table
**expected** | **actual**. Panel 1 (title `invocation 1 · "refund 6041"`): rows `get_order(id=6041)`
| `get_order(id=6041)`, `verify_shipment(id=6041)` | `verify_shipment(id=6041)`,
`issue_refund(id=6041)` | `issue_refund(id=6041)`; each actual cell green; a chip below `1.0`
green. Panel 2 (title `invocation 2 · "and 6042"`): rows `get_order(id=6042)` | `get_order(id=6042)`
(green), `verify_shipment(id=6042)` | `—` (red, dashed), `issue_refund(id=6042)` |
`issue_refund(id=6042)` (green); chip below `0.0` red, with a small sans label "one mismatch, whole
invocation scores 0". Under both panels a bracket to a mono formula `case = (1.0 + 0.0) / 2 = 0.5`
and a red chip `< 1.0 threshold → FAIL`. Caption inside: "match_type EXACT (default)".

**Body (`.checks`):**
- **Per invocation, the actual list of tool calls is compared with the expected list.** The invocation scores **1.0 or 0.0**. The case score is the mean over invocations. Default threshold **1.0**.
- **`match_type`** changes what counts as a match: `EXACT` (same calls, same order, nothing extra), `IN_ORDER` (expected calls present in order, extras allowed), `ANY_ORDER`.
- **What it does not see (red dot):** the metric reads tool **names and arguments** only. `tool_responses` are in the case and this metric never reads them, so a correctly named call that returned an error scores 1.0.
- **Who does read tool results:** `hallucinations_v1` (the tool output is its context), the rubric-based tool-use judges, and the service's `TOOL_USE_QUALITY` (loss patterns *Tool Failure*, *Tool Error*).

**Example (`.ex`):**
- **Actor:** Marco, reading a failed case.
- **Input:** the two invocations above.
- **Mechanism:** invocation 1 matches: 1.0. Invocation 2 skipped `verify_shipment`: 0.0. Mean 0.5, threshold 1.0.
- **Result:** fail. Under `IN_ORDER` with an extra `get_customer` call between steps: still 1.0, because the three expected calls appear in order <span class="tag illus">computed from the 2.9.0 code path</span>.

**Takeaway:** One wrong call zeroes the invocation. Set `IN_ORDER` when helper calls may vary, and
use a different metric when tool success is the question.

**Sources:** `trajectory_evaluator.py:106-173`, `eval_metrics.py:193-240`, `eval_config.py:237-239`,
`eval_case.py:197-222` (google-adk 2.9.0); [criteria](https://adk.dev/evaluate/criteria/).

**Notes:** Correction to the source (slide 25's field names do not exist) and to the companion page
(which says each matching step scores 1 and the steps are averaged; on 2.9.0 the invocation is
binary). The source's six matches (exact, in-order, any-order, precision, recall, single-tool) are
`v1beta1` service inputs, not ADK's; page 18. Argument comparison is exact: `{"id": 6041}` vs
`{"id": "6041"}` is a mismatch. Production-side, the outcome counter from Module 3 page 28 is how
tool success is counted.

---

## Page 9 — Grading the answer: shared words, or a judge

**Type:** Comparison (`.lede` + `table.cmp` + `.checks` + `.ex` + `.takeaway` + `.src`).

**Lede:** The reference says "Your refund of $42 has been issued." Two replies come back. One is
right and fails; one is wrong and passes.

**Table (`table.cmp`, mono in cells):**

| Reply | ROUGE-1 F | `response_match_score` @ 0.8 | `final_response_match_v2` |
|---|---|---|---|
| A: "I have issued your $42 refund." | 0.615 | fail | valid |
| B: "Your refund of $42 has been denied." | 0.857 | pass | invalid |

**Body (`.checks`):**
- **`response_match_score` counts shared words.** ROUGE-1 F-measure between reply and reference: tokens `[a-z0-9]`, Porter-stemmed. Default threshold 0.8. A reply that reuses enough of the reference's words scores high whatever it means; a correct reply in other words scores low.
- **`final_response_match_v2` asks a judge.** The reply and the reference go to a judge model with the question "valid or invalid"; the judge is sampled `num_samples` times, each invocation is majority-voted, and the score is the fraction of valid invocations.
- **The judge is a model call with its own non-determinism.** That is why it is sampled, and why page 13 shows the cost.

**Example (`.ex`):**
- **Actor:** Priya, choosing an answer metric for the refund agent.
- **Input:** the reference and the two replies above.
- **Mechanism:** reply A shares 4 of the reference's 7 stemmed tokens; reply B shares 6 of 7.
- **Result:** ROUGE passes the wrong reply and fails the right one. The judge gets both right <span class="tag illus">computed with rouge_score, 2026-09-13</span>.

**Takeaway:** Use `response_match_score` for short, fixed replies. For anything a person could
phrase two ways, use `final_response_match_v2`.

**Sources:** `final_response_match_v1.py:68-69, 180-199`, `final_response_match_v2.py:134-136, 196-209`
(google-adk 2.9.0); [criteria](https://adk.dev/evaluate/criteria/); scratchpad run.

**Notes:** Generic (text similarity vs. model judgment); say so. Ties in the judge's majority vote
count as invalid (`aggregate_per_invocation_samples`). The judge prompt tells the model to trust the
reference for arithmetic and to treat unit changes (miles vs. km) as invalid. Off the face:
`response_evaluation_score` is a third answer metric, the service's coherence score on a 1–5 scale;
it is in page 10's table.

---

## Page 10 — The thirteen ADK criteria, sorted by what each needs

**Type:** Comparison (`.lede` + `table.cmp` in `.tscroll` + `.takeaway` + `.src`).

**Lede:** Every name a `test_config.json` can contain, and what each one needs from you and from
the cloud.

**Table (`table.cmp`; ✓ / — cells; `tr.hl` on the four most used):**

| Criterion | Reference? | Rubrics? | Judge? | Runs |
|---|---|---|---|---|
| `tool_trajectory_avg_score` (hl) | ✓ | — | — | local |
| `response_match_score` (hl) | ✓ | — | — | local |
| `final_response_match_v2` (hl) | ✓ | — | ✓ | local judge |
| `hallucinations_v1` (hl) | — | — | ✓ | local judge |
| `rubric_based_final_response_quality_v1` | — | ✓ | ✓ | local judge |
| `rubric_based_tool_use_quality_v1` | — | ✓ | ✓ | local judge |
| `rubric_based_multi_turn_trajectory_quality_v1` | — | ✓ | ✓ | local judge |
| `per_turn_user_simulator_quality_v1` | — | — | ✓ | local judge |
| `response_evaluation_score` | ✓ | — | ✓ | **service** |
| `safety_v1` | — | — | ✓ | **service** |
| `multi_turn_task_success_v1` | — | — | ✓ | **service** |
| `multi_turn_trajectory_quality_v1` | — | — | ✓ | **service** |
| `multi_turn_tool_use_quality_v1` | — | — | ✓ | **service** |

**Below the table (`.note.blue`):** "service" means the criterion sends your invocations to the
Agent Platform evaluation service; it needs `GOOGLE_CLOUD_PROJECT`, `GOOGLE_CLOUD_LOCATION`, and a
region the service supports. "local judge" means ADK calls a judge model you name; page 13.

**Takeaway:** The four highlighted rows cover most teams. Reach for the service-backed five for
simulated multi-turn conversations, and for safety.

**Sources:** `metric_evaluator_registry.py:206-260`; `vertex_ai_eval_facade` imports in
`safety_evaluator.py`, `response_evaluator.py`, `multi_turn_*_evaluator.py` (google-adk 2.9.0);
[criteria](https://adk.dev/evaluate/criteria/) table.

**Notes:** Agent-specific: correctness is multi-dimensional, and the five delegating criteria make
the eval itself depend on an external service with regions and quotas. The criteria page on
adk.dev lists 13; the overview page says 12 and omits `response_evaluation_score`. This deck
follows the criteria page. Delivery beat: cover the "Runs" column first; that is the column that
changes what a CI job needs.

---

## Page 11 — Choosing by scenario

**Type:** Comparison (`.lede` + `table.cmp` + `.ex` + `.takeaway` + `.src`).

**Lede:** Four agents, four different questions, four different rows from the table.

**Table (`table.cmp`):**

| The agent | The question | Criteria | Why |
|---|---|---|---|
| Refund flow with a fixed order of steps | Did it verify before it refunded, and say so? | `tool_trajectory_avg_score` with `IN_ORDER` + `final_response_match_v2` | order is a requirement; helper calls may vary; replies are phrased freely |
| RAG answer over a policy document | Did it say only what the document says? | `hallucinations_v1` | there is no single reference sentence; claims are checked against the tool output |
| Customer-facing reply with house rules | Amount stated, no delivery promise, under three sentences? | `rubric_based_final_response_quality_v1` with three rubrics | the rules are the rubrics; page 12 |
| Open-ended multi-turn support | Did the simulated user get what they came for? | `multi_turn_task_success_v1` under user simulation | reference-based criteria are not supported with a simulated user |

**Example (`.ex`):**
- **Actor:** Marco, with the RAG agent.
- **Input:** the agent answers "the return window is 45 days"; the retrieved policy says 30.
- **Mechanism:** `hallucinations_v1` splits the reply into sentences and labels each `supported`, `unsupported`, `contradictory`, `disputed`, or `not_applicable` against the tool output. The score is the fraction supported or not applicable.
- **Result:** one of two sentences unsupported: 0.5 <span class="tag illus">illustrative</span>.

**Takeaway:** Pick the criterion by the question, then check its column on page 10 for what it
needs.

**Sources:** [criteria](https://adk.dev/evaluate/criteria/) sections for each metric;
[adk.dev/evaluate](https://adk.dev/evaluate/) user-simulation note.

**Notes:** The user-simulation constraint, verbatim from the docs: `tool_trajectory_avg_score`,
`response_match_score`, and `final_response_match_v2` "are not supported in combination with User
Simulation". `hallucinations_v1` has an option, `evaluate_intermediate_nl_responses`, to check text
the agent emitted before tool calls as well as the final reply.

---

## Page 12 — A rubric is one testable criterion; the score is the fraction that passed

**Type:** Concept + code (`.lede` + `.checks` + `pre.code` ≤ 12 lines + `.ex` + `.takeaway` + `.src`).

**Lede:** "Under three sentences" is not a reference answer and not a word count the framework
knows. It is a rubric.

**Body (`.checks`):**
- **Shape:** an id, a text property the judge can test, and an optional type. Each rubric gets **Pass** or **Fail** per invocation; the metric's score is the fraction that passed.
- **You write them** for ADK's three `rubric_based_*` criteria, in `test_config.json` or on the case (`EvalCase.rubrics`, additive). An empty effective list raises at evaluation time.
- **The service generates them** for its adaptive metrics (`FINAL_RESPONSE_QUALITY`, `TOOL_USE_QUALITY`, the three multi-turn), from the agent's instruction and tool declarations plus the prompt. Each comes back with a verdict and a reasoning sentence; page 20 shows real ones.
- **Static metrics** (`SAFETY`, `HALLUCINATION`) return one 0–1 number instead of a pass rate.

**Code (`.codelabel` "test_config.json — three rubrics"):**
```json
{"criteria": {"rubric_based_final_response_quality_v1": {
  "threshold": 0.67,
  "rubrics": [
    {"rubric_id": "amount",   "rubric_content": {"text_property": "The reply states the refund amount."}},
    {"rubric_id": "no_date",  "rubric_content": {"text_property": "The reply does not promise a delivery date."}},
    {"rubric_id": "short",    "rubric_content": {"text_property": "The reply is under three sentences."}}
  ]}}}
```

**Example (`.ex`):**
- **Actor:** Priya, writing rubrics for the refund agent.
- **Input:** the three rubrics above.
- **Mechanism:** the ADK judge marks each per invocation.
- **Result:** a reply that states the amount in four sentences with no delivery promise scores 2/3 ≈ 0.67.

**Takeaway:** A rubric turns a house rule into a number. Write them for what you can state; let
the service generate them for what it can read from your agent's own configuration.

**Sources:** `eval_rubrics.py:24-65`, `rubric_based_evaluator.py:134-260` (google-adk 2.9.0);
[criteria](https://adk.dev/evaluate/criteria/) rubric sections;
[manage-metrics](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/manage-metrics).

**Notes:** Agent-specific: the rubrics are derived from, or written against, the agent's
configuration, which is code. Per-case rubrics are filtered by `type` (`FINAL_RESPONSE_QUALITY`,
`TOOL_USE_QUALITY`, `TRAJECTORY_QUALITY`). Custom LLM metrics on the service (`types.LLMMetric`) are
the third home: a prompt template you write, registered once, applied to runs and monitors alike.

---

## Page 13 — Configuring a judge, and what a run costs

**Type:** Code (`.lede` + `.codelabel` + `pre.code` + `.checks` + `.note` + `.ex` + `.takeaway` + `.src`).

**Lede:** The criteria on page 10 with a "judge" tick each take a judge model, a sample count, and
a threshold. Those three numbers set the cost of a run.

**Code (`.codelabel` "test_config.json — judge options and match type"):**
```json
{"criteria": {
  "tool_trajectory_avg_score": {"threshold": 1.0, "match_type": "IN_ORDER"},
  "final_response_match_v2": {
    "threshold": 0.8,
    "judge_model_options": {"judge_model": "gemini-2.5-flash", "num_samples": 5}
  }
}}
```

**Body (`.checks`):**
- **A bare float is a threshold.** An object adds `judge_model_options` (`judge_model`, default `gemini-2.5-flash`; `num_samples`, default 5), `match_type` for the trajectory criterion, `rubrics[]` for the rubric criteria.
- **`AgentEvaluator` runs every case `num_runs=2` times** by default, because the agent is non-deterministic.
- **Cost, in calls:** one case with one judge criterion is 2 agent runs and 10 judge calls, before the agent's own tool and model calls.

**Note (yellow):** `gemini-2.5-flash` is the code default; the docs' samples say
`gemini-flash-latest`. Name the model you want in the config.

**Example (`.ex`):**
- **Actor:** Priya, sizing the PR set.
- **Input:** 60 cases, `final_response_match_v2` at defaults.
- **Mechanism:** 60 × 2 runs = 120 agent runs; 120 × 5 samples = 600 judge calls per pipeline run.
- **Result:** `num_samples: 3` for the PR set, 5 for the nightly set: 360 judge calls on a PR <span class="tag illus">computed from defaults</span>.

**Takeaway:** Two defaults, `num_runs=2` and `num_samples=5`, exist because the agent and the judge
are both non-deterministic. Know them before you size a set.

**Sources:** `eval_metrics.py:81-115`, `agent_evaluator.py:73`, `eval_config.py:97-135`
(google-adk 2.9.0); [criteria](https://adk.dev/evaluate/criteria/) config samples.

**Notes:** Per the brief: cost is one bullet, not a headline. `parallelism_limit` (default 1)
serializes judge calls; raise it for speed at the price of rate limits.
`include_intermediate_responses_in_final` sends text the agent emitted before tool calls to the
judge as well.

---

## Page 14 — A score is not a pass until something compares it to the threshold

**Type:** Code (`.lede` + two `pre.term` blocks with `.codelabel.good` / `.codelabel.bad` + `.note.blue` + `.takeaway` + `.src`).

**Lede:** Page 8's case scores 0.5 against a threshold of 1.0. Two commands run it. One fails.

**Terminal 1 (`.codelabel.good` "pytest — AgentEvaluator raises"):**
```
$ pytest tests/eval
E   AssertionError: tool_trajectory_avg_score for app Failed. Expected 1.0, but got 0.5.
1 failed in 4.56s
$ echo $?
1
```

**Terminal 2 (`.codelabel.bad` "adk eval — prints, and stops there"):**
```
$ adk eval app/ refunds.evalset.json --config_file_path test_config.json
refunds:
  Tests passed: 0
  Tests failed: 1
$ echo $?
0
```

**Code (`pre.code`, the test, 8 lines):**
```python
import pytest
from google.adk.evaluation.agent_evaluator import AgentEvaluator

@pytest.mark.asyncio
async def test_refund_flow():
    await AgentEvaluator.evaluate(
        agent_module="app.agent",
        eval_dataset_file_path_or_dir="tests/eval/refunds.test.json")
```

**Note (blue):** `AgentEvaluator.evaluate` is `async`. Without `await` it returns a coroutine that
never runs, and the test passes without evaluating anything.

**Takeaway:** Something has to compare the score with the threshold and fail. `AgentEvaluator`
does; the CLI does not. Module 2 places that comparison in the pipeline.

**Sources:** `agent_evaluator.py:553-575, 844-887`; `cli_tools_click.py:1290-1520` (no exit on
failure) (google-adk 2.9.0); M2 page 6 (both outputs reproduced on 2.9.0).

**Notes:** Generic (assert vs. print); say so. This module states the fact and stops. Module 2 has
the four ways to run an eval, the exit-code detail for `agents-cli eval run`, and the set tiering.
If someone asks now: `adk eval` is built for a person reading scores, and it declines to choose a
pass threshold for you.

---

## Page 15 — Two ways to grow a set

**Type:** Mechanism (`.lede` + full-width `figure > svg` + `.checks` + `.ex` + `.takeaway` + `.src`).

**Lede:** A customer was refunded twice. The conversation that did it is the next eval case.

**Diagram (960×260):** Two lanes. **Capture** (top, green rule): gray box `production failure:
refunded twice` → blue box `adk web: reproduce the session` → blue box `save session as case` →
green box `edit expected tool_uses + reference` → gray box `refunds.evalset.json` → chip `fails
until fixed, then guards`. **Generate** (bottom, blue rule): gray box `generate_eval_cases
count=20 "refunds for unshipped orders"` → blue box `service: ConversationScenario × 20` (mono
inside: `starting_prompt · conversation_plan · user_persona`) → gray box `refunds.evalset.json`
→ chip `no expected trajectory: reference-free metrics + user simulation only`. Caption inside:
"Captured cases are recorded trajectories. Generated cases are plans for a simulated user."

**Body (`.checks`):**
- **Capture:** chat in `adk web` until the agent does the right or wrong thing; save the session as a case; edit the expected trajectory and the reference. Every production failure and bug report becomes a case.
- **Generate:** `adk eval_set generate_eval_cases` (also `agents-cli eval dataset synthesize` and `client.evals.generate_conversation_scenarios`; one service call) writes scenario cases with a starting prompt, a plan, and a persona, and **no expected trajectory**. They need a project.
- **Version the set with the agent.** A version ships when its scores are at or above the last accepted version's on the same set.
- **Cover what production sends:** ambiguous inputs, tool errors, out-of-scope requests. A set of clean requests passes regressions through.

**Example (`.ex`):**
- **Actor:** Priya, after the double refund.
- **Input:** "refund 6041" sent twice in one `adk web` session.
- **Mechanism:** save the session as a case; edit the second invocation's expected `tool_uses` to `[get_order]` and its reference to say the refund already exists.
- **Result:** the case fails until the instruction is fixed, then guards it. `generate_eval_cases` with `count: 20` adds twenty scenario cases for the simulated-user run.

**Takeaway:** Capture gives you cases with an expected trajectory. Generation gives you breadth
with none. Use both, and know which metrics each can feed.

**Sources:** `adk_web_server.py` eval-set routes (`…/eval-sets/{id}/add-session`);
`cli_tools_click.py:1645-1895` (google-adk 2.9.0); [user-sim](https://adk.dev/evaluate/user-sim/);
companion page 34.

**Notes:** Agent-specific: eval sets are maintained artifacts, and captured cases are recorded
trajectories. `generate_eval_cases` takes a `ConversationGenerationConfig` (`count`, `model_name`
required; `generation_instruction`, `environment_context` optional) and hashes each scenario into
an `eval_id`, so re-running does not duplicate. Hold some cases out of the local loop and grade them
only when you think you are done; otherwise you fit the agent to the cases you iterate on.

---

## Page 16 — Section 1 recap

**Type:** Recap (`.checks` with green dots).

- A test checks execution of deterministic code. An eval grades the response and the path to it, because the path can change with no code change.
- A case records the prompt, the reference reply, and the expected tool calls. `.test.json` and `.evalset.json` hold the same schema; the suffix picks the discoverer.
- `tool_trajectory_avg_score`: 1.0 or 0.0 per invocation, averaged, threshold 1.0; reads names and arguments, not results. `response_match_score` counts shared words; `final_response_match_v2` asks a judge.
- Thirteen criteria; eight run locally, five send your invocations to the service. Rubrics are testable criteria scored as a pass rate.
- A judge is sampled five times and every case runs twice. A score is not a pass until `AgentEvaluator` compares it with the threshold.

**Notes:** Read the third row twice; it is the one that changes what someone writes tomorrow.
Hand-off: section 2 explains the "service" those five criteria send to.

---

## Page 17 — Section divider: The managed layer

**Type:** Section divider (section 2 of 4).

**dsub:** Three layers, not four systems. What the Agent Platform evaluation service is, which ADK
criteria are the same thing under another name, and what agents-cli adds.

**Notes:** The brief listed four things that looked like four systems. This section is the answer
to that list.

---

## Page 18 — Three layers, not four systems

**Type:** Mechanism (`.lede` + full-width `figure > svg` + `.checks` + `.ex` + `.takeaway` + `.src`).

**Lede:** ADK eval, the Gen AI evaluation service, Agent Platform agent evaluation, agents-cli.
Four names, three layers, and one of the names is a naming accident.

**Diagram (960×320):** Three horizontal bands. **Top band, "harnesses"** (gray rule): three boxes
left to right: `ADK eval` (blue; mono inside: `pytest · adk eval · adk web`), `agents-cli eval`
(blue; `generate · grade · analyze · compare`), `Console / SDK` (blue; `client.evals.*`). **Middle
band, "scorers"**: left, a green box `ADK local metrics` (mono list: `tool_trajectory_avg_score ·
response_match_score · final_response_match_v2 · hallucinations_v1 · rubric_based_* · user_sim`);
right, a large blue box `Agent Platform evaluation service` (mono list: `RubricMetric.* · metric
registry · loss clustering · online monitors`). Arrows: `ADK eval` → `ADK local metrics` (labeled
"8 criteria"); `ADK eval` → service (labeled "5 criteria delegate", mono:
`vertexai.types.RubricMetric.MULTI_TURN_TASK_SUCCESS`); `agents-cli` → service; `Console / SDK` →
service. **Bottom band, "data"**: gray boxes `recorded cases (EvalSet)` under ADK, `agents-cli
dataset` under agents-cli, `production traces` under the service, with the note "three dataset
formats". Caption inside: "mental model; the five delegating criteria are literal".

**Body (`.checks`):**
- **ADK eval is the local harness.** Thirteen criteria. Eight run in your process. Five send your invocations to the service, passing the accessor the service's own docs name.
- **The service is the scorer plus the production half.** Rubric metrics, a metric registry, runs over historical traces, Online Monitors, loss clustering. ADK has no equivalent for the production half.
- **agents-cli is a third front end over the service**, with its own dataset format.
- **The source deck's "model eval vs. agent eval" table is a false split**, and its six trajectory matches are `v1beta1` inputs that are not in the current metric set.

**Example (`.ex`):**
- **Actor:** Marco, running `multi_turn_task_success_v1` locally.
- **Input:** no `GOOGLE_CLOUD_PROJECT` set.
- **Mechanism:** the ADK facade raises "specify both project id and location". He sets the project and `us-central1`; the v2 metric spec needs a model not offered there, so he pins `version="v1"`.
- **Result:** one metric, reachable three ways: ADK config, `client.evals.evaluate`, `agents-cli eval grade`.

**Takeaway:** Layers, not alternatives. ADK grades locally and borrows the service for five
criteria; the service grades anything, including production; agents-cli is a way to call it.

**Sources:** `multi_turn_task_success_evaluator.py:60-62`, `vertex_ai_eval_facade.py:40-60`
(google-adk 2.9.0); `agentplatform/_genai/_evals_constant.py` (aiplatform 1.165.1);
`aiplatform_v1beta1/types/evaluation_service.py:357-377`; [agent-evaluation](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/agent-evaluation).

**Notes:** Agent-specific: the model is an external dependency and so is the scorer. The
`_evals_constant.py` comment is the citation for the region point: "v2/v3 specs require Gemini 3.5
Flash, which is not available in all regions (e.g. us-central1)". "Gen AI evaluation service" and
"Agent Platform evaluation" are the same service under two names, in the SDK as `vertexai.evals` and
`agentplatform.evals`. Delivery beat: build the diagram top-down; the five-criteria arrow is the
reveal.

---

## Page 19 — Same names, three relationships, and the harness decides

**Type:** Comparison (`.lede` + `table.cmp` in `.tscroll` + `.note.green` + `.ex` + `.takeaway` + `.src`).

**Lede:** `safety_v1` in a `test_config.json` and `SAFETY` on a monitor are the same scorer.
`hallucinations_v1` and `HALLUCINATION` are not.

**Table (`table.cmp`):**

| ADK criterion | Service metric | Relationship |
|---|---|---|
| `multi_turn_task_success_v1` | `MULTI_TURN_TASK_SUCCESS` | same thing: ADK sends your invocations to the service |
| `multi_turn_tool_use_quality_v1` | `MULTI_TURN_TOOL_USE_QUALITY` | same thing |
| `multi_turn_trajectory_quality_v1` | `MULTI_TURN_TRAJECTORY_QUALITY` | same thing |
| `safety_v1` | `SAFETY` | same thing |
| `response_evaluation_score` | `COHERENCE` (1–5) | same thing |
| `hallucinations_v1` | `HALLUCINATION` | same idea, different scorer: ADK's sentence-level judge on your model vs. the service's claim-level judge |
| `rubric_based_tool_use_quality_v1` | `TOOL_USE_QUALITY` | same idea: your rubrics vs. generated rubrics |
| `final_response_match_v2` | `FINAL_RESPONSE_MATCH` | same idea: ADK's local judge vs. the service's |
| `tool_trajectory_avg_score`, `response_match_score` | — | ADK only; no model call |

**Note (green):** The harness decides. ADK criteria wherever the harness is ADK: the dev loop,
pytest, `adk eval`, a local agent module, recorded cases. Service metrics wherever the harness is
the service: a deployed agent, production traces, monitors, loss clustering. Development and
pre-merge use ADK; production uses the service, because ADK's harness cannot read production
traffic.

**Example (`.ex`):**
- **Actor:** Priya, asked why the PR gate and the production dashboard report different hallucination numbers.
- **Input:** `hallucinations_v1` in `test_config.json`; `HALLUCINATION` on the Online Monitor.
- **Mechanism:** the first is ADK's sentence-level judge on `gemini-2.5-flash` over recorded cases; the second is the service's claim-level judge over sampled production traces.
- **Result:** two scorers, two populations. Each number is compared with its own previous value, not with the other.

**Takeaway:** Know which rows are the same scorer. Compare a metric only with itself, on the same
harness, over the same kind of data.

**Sources:** the evaluator files cited on pages 10 and 18;
[manage-metrics](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/manage-metrics).

**Notes:** `safety_v1` maps to the service's older `PrebuiltMetric.SAFETY`, not the adaptive
`RubricMetric.SAFETY`; both return 0/1. `response_evaluation_score` is the only 1–5 criterion in
ADK. If the room asks for one rule: local for the gate, service for production, and never read one
as a proxy for the other.

---

## Page 20 — The service's seven agent metrics, and what a run returns

**Type:** Code (`.lede` + `.codelabel` + `pre.code` ≤ 14 lines + `.checks` + `.ex` + `.takeaway` + `.src`).

**Lede:** One production trace from the weather agent, two service metrics, twenty-three seconds.
The rubrics came back quoting the agent's own instruction.

**Code (`.codelabel` "agentplatform SDK, aiplatform 1.165.1 — server-side run"):**
```python
from agentplatform import Client, types
client = Client(project=PROJECT, location="us-central1")

run = client.evals.create_evaluation_run(
    dataset=types.EvaluationRunDataSource(evaluation_set=EVAL_SET),
    metrics=[types.RubricMetric.TOOL_USE_QUALITY(version="v1"),
             types.RubricMetric.FINAL_RESPONSE_QUALITY(version="v1")],
    dest="gs://BUCKET/eval-results/",
    display_name="weather-v7")
# poll client.evals.get_evaluation_run(name=run.name) until state is SUCCEEDED
# run.evaluation_results.summary_metrics: AVERAGE, MEDIAN, P90 … per metric
# per-item JSON, with every rubric, verdict, and reasoning, lands in dest
```

**Body (`.checks`):**
- **Single-turn:** `FINAL_RESPONSE_QUALITY`, `TOOL_USE_QUALITY` (adaptive), `HALLUCINATION`, `SAFETY` (static). **Multi-turn:** `MULTI_TURN_TASK_SUCCESS`, `MULTI_TURN_TOOL_USE_QUALITY`, `MULTI_TURN_TRAJECTORY_QUALITY` (adaptive).
- **`client.evals.evaluate(dataset, metrics=[…])`** for a notebook; **`create_evaluation_run`** for a run the console lists, with results in a bucket.
- **Each adaptive rubric returns** its text, an importance, a verdict, and a reasoning sentence.
- **Custom metrics** (`types.LLMMetric`, `types.CodeExecutionMetric`) register once with `create_evaluation_metric` and apply to runs and monitors alike.

**Example (`.ex`):**
- **Actor:** the M3 weather agent, one trace.
- **Input:** "What's the weather in London?"; the agent called `get_weather(city="London")` and replied "The weather in London is currently 15°C and drizzling."
- **Mechanism:** the run above. Generated rubrics included "calls `get_weather` for a current-weather question, as the developer instructions specify" (pass), "the `city` parameter is set to London" (pass), and "the final answer is one or two sentences long" (pass).
- **Result:** `final_response_quality_v1` 1.0 (three rubrics, three pass); `tool_use_quality_v1` 0.75 (four rubrics, three pass). 23 seconds. **Observed 2026-09-13.**

**Takeaway:** The service reads your agent's instruction and tool declarations and writes the
rubrics for you. What comes back is a pass rate and the reasons.

**Sources:** `scratchpad/m4_score_run.py` output 2026-09-13; `agentplatform/_genai/evals.py:3539-3600`
(aiplatform 1.165.1); [manage-metrics](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/manage-metrics);
[view-results](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/view-results).

**Notes:** Agent-specific: multi-dimensional correctness, and the rubrics are generated from the
agent's configuration. `version="v1"` because v2/v3 specs need a model not offered in
`us-central1`; without the pin the run errors. The one failing tool-use rubric's text was not
captured (proto3 JSON omits `false`, and the filter skipped it); say "four generated, three passed"
and no more. The docs' samples pass metrics both as bare strings and as `types.RubricMetric.*`
objects; use the objects. The install is `pip install google-cloud-aiplatform[adk,evaluation]`.

---

## Page 21 — agents-cli: what it adds, and the SDK call behind each

**Type:** Comparison (`.lede` + `table.cmp` in `.tscroll` + `.ex` + `.takeaway` + `.src`).

**Lede:** agents-cli has an `eval` command group. None of it scores anything the SDK cannot.

**Table (`table.cmp`):**

| Command | What it does | SDK call underneath | Status in 1.5.0 |
|---|---|---|---|
| `eval generate` | runs the agent over a dataset, writes traces; `--url` targets a Cloud Run, GKE, or local server | `client.evals.run_inference` | — |
| `eval grade` | scores traces with the service | `client.evals.evaluate` | — |
| `eval run` | `generate` then `grade` | both | — |
| `eval compare` | diffs two result files, with deltas | a JSON diff | — |
| `eval analyze` | loss clusters from a result file | `client.evals.generate_loss_clusters` | Experimental |
| `eval dataset synthesize` | scenario cases plus full simulated runs | `generate_conversation_scenarios` + `run_inference` | Experimental |
| `eval submit` / `eval results` | managed cloud run | `create_evaluation_run` | Experimental |
| `eval metric list` | the service's metric names | `SUPPORTED_PREDEFINED_METRICS` | — |

**Example (`.ex`):**
- **Actor:** Priya, on a scaffolded project.
- **Input:** `tests/eval/eval_config.yaml` with `custom_response_quality`, a local 1–5 judge in `response_quality.py`, and a three-case dataset (`eval_case_id`, `prompt`, `reference.response`).
- **Mechanism:** `agents-cli eval run` writes `results_<timestamp>.json`; `eval compare` against last week's file.
- **Result:** `+0.07` on quality and `-1` turn. Nothing in the scaffold's pipeline calls it (Module 2, page 9).

**Takeaway:** Use agents-cli for `compare` and for the scaffold it ships. Everything it scores, it
scores by calling the service, and its dataset is a third format.

**Sources:** `google/agents/cli/eval/cmd_*.py`, `scaffold/agents/adk/tests/eval/*`
(google-agents-cli 1.5.0); M2 page 8.

**Notes:** Generic (a CLI front end); say so. Three dataset formats: ADK `EvalSet`
(`eval_id`/`conversation`/`user_content`), agents-cli (`eval_case_id`/`prompt`/`reference.response`),
and the service's `EvaluationItem`. A team usually settles on one harness; mixing means two
dataset formats to maintain. The scaffold's `agent_turn_count` custom metric is an inline function
in YAML; worth pointing at as the simplest custom metric that exists.

---

## Page 22 — Section 2 recap

**Type:** Recap.

- Three layers: ADK grades locally and sends five criteria to the service; the service grades anything, including production; agents-cli calls the service.
- Nine ADK criteria have a service counterpart: five are the same scorer, three are the same idea with a different scorer, and two are ADK-only.
- The harness decides: ADK for development and the gate, the service for production. Compare a metric only with itself.
- The service's seven agent metrics return a pass rate over rubrics it generates from your agent's instruction and tools, with the reasons.

**Notes:** Hand-off: section 3 is where the service's production half gets used.

---

## Page 23 — Section divider: In the lifecycle

**Type:** Section divider (section 3 of 4).

**dsub:** Where evaluation runs once the agent is live: on demand over traces, continuously with
a monitor, alerted by Monitoring, and fed back into the set.

**Notes:** This section restates the two OpenTelemetry variables Module 3 set, and does not
re-teach them. It refers to Module 2 for the gate.

---

## Page 24 — Three moments, same metrics, different data

**Type:** Comparison (`.lede` + `table.cmp` + `.ex` + `.takeaway` + `.src`).

**Lede:** Nothing merged for eleven days, and task success in production fell from 0.91 to 0.78.

**Table (`table.cmp`; `tr.hl` on the third row):**

| Moment | Harness | Data | What you do with the score |
|---|---|---|---|
| While developing | `adk web` | a handful of recorded cases | read it |
| Before merge | pytest + `AgentEvaluator` | the PR set | it is the gate (Module 2 places it) |
| In production (hl) | the service | live traces: on demand over history, or sampled on a schedule | dashboard, alert, and new cases for the set |

**Body (`.checks`, two rows):**
- **What changes between moments is the data source**, not the kind of grading.
- **Behavior changes with frozen code** when the model behind an alias moves to a new version, or when the input mix shifts. Only the production moment sees that.

**Example (`.ex`):**
- **Actor:** Marco.
- **Input:** the agent passed its PR gate on 2026-08-30; nothing merged since.
- **Mechanism:** on 2026-09-10 the monitor's task success reads 0.78; the model alias had moved to a new version.
- **Result:** the eval set never ran, because nothing merged. The monitor is what saw it <span class="tag illus">illustrative</span>.

**Takeaway:** The gate catches your changes. Production scoring catches everyone else's.

**Sources:** [agent-evaluation](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/agent-evaluation)
workflow table; [evaluate-agents](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/evaluate-agents)
three-type table.

**Notes:** Generic lifecycle table; say so. The agent-shaped row is the last one: the model is an
external dependency that changes under you. The docs' own three types are "Rapid Evaluation /
Test Case Evaluation / Online Monitoring" with frequencies "Frequent / Scheduled / Continuous";
this table is the same thing with the harness named.

---

## Page 25 — How a production trace becomes something the service can grade

**Type:** Mechanism (`.lede` + full-width `figure > svg` + `table.cmp` + `.ex` + `.takeaway` + `.src`).

**Lede:** The service grades traces. Whether your agent's traces are gradable depends on two
environment variables and, for the console, on where the agent runs.

**Diagram (960×280):** Left, a blue box `agent process` with three stacked runtime chips
`Agent Runtime` (green), `Cloud Run` (blue), `GKE` (blue). From it, an arrow labeled in mono
`OTEL_SEMCONV_STABILITY_OPT_IN=gen_ai_latest_experimental` /
`OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=EVENT_ONLY` to a middle gray box `Cloud Trace
+ Cloud Logging` containing two mono lines: `invoke_agent span: gen_ai.agent.name ·
gen_ai.agent.description · gen_ai.conversation.id` and `event
gen_ai.client.inference.operation.details: input/output messages · system_instruction ·
tool_definitions`. From the middle box, two arrows right: one (green) to `Console: Evaluation ·
Online monitors` labeled "Agent Runtime only (reads by reasoning engine id)"; one (blue) to
`SDK: import_evaluation_set(cloud_trace_source=…)` labeled "any runtime: project + trace ids".
A dashed second path from the agent box, labeled `…COMPLETION_HOOK=upload → gs://…`, to a gray box
`GCS JSONL` → `load_from_observability_eval_cases`. Caption inside: "The variables are Module 3's.
This page is about who can read the result."

**Table (`table.cmp`):**

| Runtime | The two variables | Console Evaluation / Monitors | SDK import by trace id |
|---|---|---|---|
| Agent Runtime | set when Cloud Trace is enabled | yes (documented prerequisite) | yes |
| Cloud Run | you set them (Module 3 page 18) | not listed; the Cloud Run Agent Platform page names Agent Identity and Agent Registry only, both Preview | **yes, measured** |
| GKE | you set them | not listed | expected as Cloud Run; not measured |

**Example (`.ex`):**
- **Actor:** the M3 weather agent, run locally with `adk web --otel_to_cloud` (resource `generic_task`, job `adk-metrics`); not on Agent Runtime.
- **Input:** trace `002b92f8…` from 2026-09-13: the three span attributes present; log events in the older per-message form (`gen_ai.user.message`, `gen_ai.choice`), not `inference.operation.details`.
- **Mechanism:** `client.evals.import_evaluation_set(evaluation_set={"display_name": …}, gcs_destination={…}, cloud_trace_source={"project_id": "jwd-gcp-demos", "trace_ids": ["002b92f8…"]})` in `us-central1`.
- **Result:** `importedItemCount: 1` in 3 seconds. The item held the agent's instruction and tool declarations, the prompt, the `get_weather` call and its response, and the final text. The session's four invocations landed under one turn, with the prompt once. **Observed 2026-09-13.** The console would not list this agent: it has no reasoning engine id.

**Takeaway:** Any runtime that exports the `gen_ai.*` spans can have its traces graded through
the SDK. The console's Evaluation and Monitor pages are for Agent Runtime.

**Sources:** `scratchpad/m4_trace_import.py` output 2026-09-13;
[evaluate-offline](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/evaluate-offline)
prerequisites and telemetry sections;
[Cloud Run Agent Platform features](https://docs.cloud.google.com/run/docs/ai/agent-platform-features);
`agentplatform/_genai/evals.py:3945-3996`, `types/common.py:6871-6884, 4172-4225` (aiplatform 1.165.1);
M3 pages 18–21.

**Notes:** Agent-specific: trajectory-level observability carries user content; the imported item
contained every user message. The measured trace had the older per-message log events and the
import still reconstructed the conversation; the docs list `inference.operation.details` as the
requirement, so set the two variables and do not rely on the older events. The GCS upload path
(`OTEL_INSTRUMENTATION_GENAI_UPLOAD_FORMAT=jsonl`, `…COMPLETION_HOOK=upload`, `…UPLOAD_BASE_PATH`)
is documented for multimodal content and is runtime-independent. `agents-cli eval generate --url`
scores fresh traffic against a Cloud Run or GKE URL; it is not history. Sessions: `session_ids` on
the same source imports every trace of a conversation.

---

## Page 26 — Production, on demand: the offline run

**Type:** Code (`.lede` + `.numrows` + `pre.code` ≤ 10 lines + `.ex` + `.takeaway` + `.src`).

**Lede:** After the drop on page 24, Marco wants the last two weeks of version 7 scored. Two ways,
one for each column of page 25's table.

**Body (`.numrows`, "Console, Agent Runtime"):**
1. Agent Platform → Agents → Evaluation → **New evaluation**.
2. **Traces** or **Sessions** tab; filter by version or time ("Last 2 weeks").
3. **Output private data path**: a bucket, entered once.
4. **Evaluate agent**. The four default metrics are added; each failing rubric links to its trace.

**Code (`.codelabel` "SDK, any runtime — import, then run"):**
```python
op = client.evals.import_evaluation_set(
    evaluation_set={"display_name": "v7-last-2-weeks"},
    gcs_destination={"output_uri_prefix": "gs://BUCKET/eval-items/"},
    cloud_trace_source={"project_id": PROJECT, "session_ids": SESSION_IDS})
# poll the operation; op.response.evaluation_set is the set name
run = client.evals.create_evaluation_run(
    dataset=types.EvaluationRunDataSource(evaluation_set=EVAL_SET),
    metrics=[types.RubricMetric.TOOL_USE_QUALITY(version="v1"),
             types.RubricMetric.HALLUCINATION(version="v1")],
    dest="gs://BUCKET/eval-results/")
```

**Example (`.ex`):**
- **Actor:** Marco.
- **Input:** "Last 2 weeks", version 7, about 400 traces.
- **Mechanism:** the four default metrics run; results land in the bucket and the Evaluations tab.
- **Result:** `HALLUCINATION` unchanged; `TOOL_USE_QUALITY` fell. He opens the failing rubrics' traces <span class="tag illus">illustrative counts; the mechanism is the one measured on page 20</span>.

**Takeaway:** A trace is one execution path; a session is a whole conversation. Pick the window,
pick the metrics, and read the failing rubrics, not the average.

**Sources:** [evaluate-offline](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/evaluate-offline);
`agentplatform/_genai/evals.py:3539-3600, 3945-3996` (aiplatform 1.165.1); `scratchpad/m4_score_run.py`.

**Notes:** The "four core metrics" added by default are not named on the offline page; from the
metric page and the `.show()` sample they are `FINAL_RESPONSE_QUALITY`, `TOOL_USE_QUALITY`,
`HALLUCINATION`, `SAFETY`, and the deck says "four default metrics" without listing them as a
documented default. The run creates an `EvaluationExperiment` automatically so it appears in the
console; pass an existing experiment name to group runs.

---

## Page 27 — Production, continuously: an Online Monitor

**Type:** Mechanism (`.lede` + full-width `figure > svg` + `.checks` + `.note.red` + `.ex` + `.takeaway` + `.src`).

**Lede:** Nobody runs page 26 every ten minutes. An Online Monitor does.

**Diagram (960×240):** A loop of three blue boxes with arrows, labeled "every ~10 minutes" on the
return arrow. `1 Query` (mono inside: `sample 10% of traces · max 50 per run · filter: duration,
tokens`) ← gray input box `Cloud Trace + Cloud Logging`. → `2 Evaluate` (mono: `MULTI_TURN_TASK_SUCCESS
· SAFETY`) with a small gray box below `evaluation service`. → `3 Report` with two output arrows:
to gray box `Cloud Logging` (mono: `labels.reasoning_engine_id · labels.trace`) and to green box
`Cloud Monitoring` (mono: `aiplatform.googleapis.com/online_evaluator/scores`). A resource label
above the loop in mono: `projects/P/locations/R/onlineEvaluators/ID`.

**Body (`.checks`):**
- **An `OnlineEvaluator` resource runs the loop:** query (sample a percentage of live traces, capped by max samples per run, optionally filtered by duration or token usage) → evaluate (the configured metrics, via the service) → report (results to Logging, numeric scores to Monitoring).
- **Agent Runtime only:** the monitor is created against an "Agent engine" chosen from a dropdown.
- **Manage it:** enable, disable, pause, resume, duplicate; the **Sampled traces** column shows what it scored.

**Note (red):** From the docs: the monitor runs as the project-level service account, so any user
who can create an `OnlineEvaluator` can attach it to any agent in the project. Restrict creation to
administrators.

**Example (`.ex`):**
- **Actor:** Priya, setting up the refund agent's monitor.
- **Input:** 10% sampling, 50 max per run, `MULTI_TURN_TASK_SUCCESS` and `SAFETY`.
- **Mechanism:** six runs an hour.
- **Result:** up to 300 scored conversations an hour, each visible in Logging under `labels.reasoning_engine_id` <span class="tag illus">illustrative sizing</span>.

**Takeaway:** A monitor is scheduled sampling plus the same metrics, with its scores exported to
Monitoring. That export is what the next page alerts on.

**Sources:** [evaluate-online](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/evaluate-online).

**Notes:** Agent-specific: non-determinism plus the model as an external dependency mean frozen
code does not mean frozen behavior; and the sampled traces carry user content. The 10-minute cadence
is the docs' "typically"; no numeric defaults for sampling are documented. The diagnostic log
filter: `resource.labels.online_evaluator="projects/…/onlineEvaluators/ID"`. No SDK sample for
creating a monitor exists in the docs; the console is the documented path.

---

## Page 28 — Alerting on quality is an ordinary Cloud Monitoring policy

**Type:** Code (`.lede` + `.codelabel` + `pre.code` ≤ 18 lines + `.checks` + `.ex` + `.takeaway` + `.src`).

**Lede:** Module 3 alerted on a counter your code wrote. This alert is on a score the monitor
wrote. Same mechanism.

**Code (`.codelabel` "policy.yaml — from the docs; gcloud monitoring policies create --policy-from-file"):**
```yaml
displayName: "Low Task Success Score"
conditions:
- displayName: "Task Success < 0.8"
  conditionThreshold:
    filter: >
      metric.type="aiplatform.googleapis.com/online_evaluator/scores"
      AND metric.labels.evaluation_metric_name="task_success"
    comparison: COMPARISON_LT
    thresholdValue: 0.8
    duration: 1800s
    aggregations:
    - alignmentPeriod: 60s
      perSeriesAligner: ALIGN_MEAN
combiner: OR
enabled: true
notificationChannels:
- "projects/PROJECT_ID/notificationChannels/CHANNEL_ID"
```

**Body (`.checks`):**
- **The metric:** `aiplatform.googleapis.com/online_evaluator/scores`, labeled by `evaluation_metric_name`. The monitor writes it; nothing else does.
- **The policy:** below a threshold, for a duration, on a per-minute mean. Slack, email, or Pub/Sub as the channel.
- **Offline runs export nothing to Monitoring.** An alert needs a monitor.
- **Console shortcut:** Dashboard → Evaluation → **Recommended Alerts** gives one template per metric on the monitor.

**Example (`.ex`):**
- **Actor:** Marco, on call.
- **Input:** the policy above.
- **Mechanism:** on 2026-09-10 the 30-minute mean of `task_success` reads 0.78.
- **Result:** the incident opens, with a link to the sampled traces.

**Takeaway:** Put the alert on the score, with a duration long enough to cover several monitor
runs. Then follow the link to the traces.

**Sources:** [quality-alerts](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/quality-alerts)
(`policy.yaml` verbatim); M3 page 28.

**Notes:** Generic (Cloud Monitoring); say so. The label value is snake_case (`task_success`)
while the SDK accessor is `MULTI_TURN_TASK_SUCCESS`; the docs do not list the full label vocabulary,
so read it off Metrics Explorer for your monitor. The docs' Python sample is labeled "Agent
Platform SDK" and imports `google.cloud.monitoring_v3`; it is the Monitoring client. Alert on
severity: a quality drop is a ticket unless safety is the metric, and then it is a page.

---

## Page 29 — Reacting: cluster the failures, turn them into cases, compare versions

**Type:** Mechanism (`.lede` + full-width `figure > svg` + `table.cmp` + `.ex` + `.takeaway` + `.src`).

**Lede:** Forty failing traces is a number. Thirty-one of them missing the same tool call is a
diagnosis.

**Diagram (960×200):** A left-to-right loop of five boxes: green `monitor / offline run` → blue
`generate_loss_clusters` (mono inside: `Omission of Required Tool Call: 31 · Over-Punting: 6 ·
Tool Error: 3`) → blue `open the traces` → green `add cases to the set (page 15)` → blue `fix
instruction or tool definition` → gray `PR gate (Module 2)` → back to the first box with the label
"next version, compare". Caption inside: "the triage order from the docs".

**Table (`table.cmp`, the taxonomy, abridged):**

| Metric | Categories | Examples of loss patterns |
|---|---|---|
| `multi_turn_task_success_v1` (13 patterns) | Hallucination, Instruction Following, Tool Calling, Tool Output Handling, Tool Quality | Hallucination of Action; Over-Punting; Incorrect Tool Selection; Incomplete Execution; Tool Failure |
| `multi_turn_tool_use_quality_v1` (13 patterns) | Hallucination, Tool Calling, Tool Response | Hallucination of Parameter Value; Omission of Required Tool Call; Incorrect Parameter Value; Tool Error |

**Example (`.ex`):**
- **Actor:** Marco.
- **Input:** 40 failures from the offline run.
- **Mechanism:** `generate_loss_clusters`: *Omission of Required Tool Call*, 31 of 40, all missing `verify_shipment`. He adds three of those conversations to the set and restores the instruction clause.
- **Result:** the PR set fails, then passes; the next monitor window reads 0.90 <span class="tag illus">illustrative</span>.

**Takeaway:** Cluster first, then read traces, then find whether the cause is the prompt, a tool
definition, or the data. Every failing trace you keep becomes a case.

**Sources:** [view-results](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/view-results)
loss taxonomy and triage list; `cmd_analyze.py`, `cmd_compare.py` (google-agents-cli 1.5.0).

**Notes:** Agent-specific: eval sets are maintained artifacts, and production is where the new
cases come from. "Over-Punting", from the docs: the agent declines a task, claiming it lacks a tool
or capability it has. Version comparison: `agents-cli eval compare` on two result files, or the
dashboard's Performance Trends across versions. `eval analyze` is Experimental in 1.5.0.

---

## Page 30 — Section 3 recap

**Type:** Recap.

- Three moments, same metrics: read the score, gate on it, score production. Only the third sees a model change with no deploy.
- A trace is gradable when the two OpenTelemetry variables are set. The console reads Agent Runtime; the SDK imports by trace id from any runtime, measured.
- Offline: pick a window, run the metrics, read the failing rubrics. Online: a monitor samples on a schedule and exports scores to Monitoring.
- The alert is an ordinary Monitoring policy on `online_evaluator/scores`. The reaction is clusters → traces → cause → new cases → compare.

**Notes:** Hand-off: the optional section, if time. Otherwise skip to consequences.

---

## Page 31 — Section divider: Optional

**Type:** Section divider (section 4 of 4, `.kicker` "Optional").

**dsub:** Two pages that can be dropped: conformance replay, and the topics this module names but
does not teach.

**Notes:** Cut here if the room is out of time; pages 34–35 do not depend on these.

---

## Page 32 — Conformance testing is replay, not scoring

**Type:** Code (`.lede` + `pre.term` ≤ 12 lines + `.checks` + `.ex` + `.takeaway` + `.src`).

**Lede:** Marco renamed a tool. He wants to know if anything else changed, with no model call and
no score.

**Terminal (`.codelabel` "adk conformance — google-adk 2.9.0; record and live mode marked work in progress"):**
```
$ tree tests/refund/verify_before_refund
spec.yaml                    # description, agent, user_messages
generated-recordings.yaml    # every LLM request/response and tool call/result
generated-session.yaml       # the session as recorded
$ adk conformance record tests/refund none
$ adk conformance test tests/refund
Event count mismatch -
Actual: 6   Recorded: 7
--- recorded function_call
+++ actual function_call
-  "name": "verify_shipment"
+  "name": "check_shipment"
```

**Body (`.checks`):**
- **`record`** runs the agent with a recordings plugin and writes the LLM requests and responses and the tool calls and results.
- **`test` (replay, the default)** reruns the agent against the recording and fails on any difference: event count, request, response, tool call. No model is called; the recording answers for it.
- **It is a deterministic regression test whose fixture is the model's recorded behavior.** It cannot say whether a new behavior is better. Evaluation does that.
- **Status in 2.9.0:** `record` prints "work in progress"; `--mode live` is not implemented.

**Example (`.ex`):**
- **Actor:** Priya, then Marco.
- **Input:** the refund case, recorded once.
- **Mechanism:** Marco renames `verify_shipment` to `check_shipment`; replay reruns the case.
- **Result:** failure at the first tool call with a unified diff of the recorded vs. actual function call. Nothing was graded; something changed.

**Takeaway:** Replay tells you that behavior changed. An eval tells you whether it is still good.
Use replay for cheap, deterministic regression on things that must not move.

**Sources:** `cli/conformance/cli_test.py`, `_replay_validators.py:124-141`,
`cli_tools_click.py:568-700` (google-adk 2.9.0); [adk.dev/evaluate](https://adk.dev/evaluate/)
conformance section.

**Notes:** Generic (record/replay); say so. The agent-shaped fact is that the thing mocked is the
model. Recording needs `adk web` started with
`--extra_plugins=google.adk.cli.plugins.recordings_plugin.RecordingsPlugin`. The trailing
streaming-mode argument is required: `none` or `sse`. Not to be confused with `adk test`, which
replays a JSON fixture against a mocked `BaseLlm` (Module 2 page 5).

---

## Page 33 — Related topics

**Type:** Comparison (`.grid.c4` cards, `.lede`, `.takeaway`, `.src`).

**Lede:** Four things this module names and does not teach. Each card says what it is, its status,
and one example.

**Cards:**
- **User simulation** — a `ConversationScenario` (`starting_prompt`, `conversation_plan`, `user_persona`) drives a simulated user; personas `EXPERT`, `NOVICE`, `EVALUATOR`. Reference-based criteria unsupported. *Example:* a `NOVICE` cannot correct the agent, so a wrong refund amount goes unchallenged and `multi_turn_task_success_v1` fails.
- **Environment simulation** — mock a tool or inject failures and latency. Experimental. *Example:* a 503 injected on `verify_shipment`; the rubric expects the agent to say it could not verify.
- **`adk optimize`** — GEPA rewrites the root agent's instruction against a training eval set and reports validation scores. Experimental. *Example:* 100 metric calls; the best candidate's instruction printed.
- **Custom metrics** — a Python function `(eval_metric, actual_invocations, expected_invocations, conversation_scenario) → EvaluationResult`, registered under `custom_metrics` with a `code_config.name`. *Example:* the refund amount in the reply equals the tool's return.

**Takeaway:** Each of these plugs into the same config and the same harness. Learn the harness
first.

**Sources:** [user-sim](https://adk.dev/evaluate/user-sim/),
[environment_simulation](https://adk.dev/evaluate/environment_simulation/),
[optimize](https://adk.dev/optimize/), [custom_metrics](https://adk.dev/evaluate/custom_metrics/);
`simulation/pre_built_personas.py:460-510` (google-adk 2.9.0).

**Notes:** Status labels come from the docs: environment simulation "is an experimental feature";
`GEPARootAgentPromptOptimizer` "is experimental" and warns on construction. User simulation's
default model is `gemini-flash-latest` with a thinking budget of 10240 and `max_allowed_invocations`
20. Audio (live) evaluation exists from 2.6.0 and is out of scope.

---

## Page 34 — Consequences

**Type:** Consequences (`table.cmp`: You observed / Because / So you…).

| You observed | Because | So you… |
|---|---|---|
| Every test passes and the agent now refunds unshipped orders | tests assert on code paths; the instruction is text | add the conversation as an eval case and gate on `tool_trajectory_avg_score` |
| A correct reply fails `response_match_score` | ROUGE counts shared words | switch that case to `final_response_match_v2` |
| A case passes although the tool returned an error | the trajectory metric reads names and arguments only | add `hallucinations_v1` or a tool-use rubric; alert on the outcome counter in production |
| The PR set costs more than the unit tests | `num_runs=2` and `num_samples=5` | lower `num_samples` on the PR set, keep 5 nightly |
| `adk eval` reports a failure and the build is green | the CLI prints; it does not compare | wrap the run in pytest with `await AgentEvaluator.evaluate` (Module 2 for the pipeline) |
| `multi_turn_task_success_v1` raises about a project | five criteria delegate to the service | set project and location; pin `version="v1"` in regions without the v2 model |
| The gate's hallucination score and the dashboard's disagree | different scorers over different data | compare each with its own history only |
| Task success fell with no deploy | the model behind the alias changed | an Online Monitor plus a Monitoring policy on `online_evaluator/scores` |
| Your agent runs on Cloud Run and the console's Evaluation page does not list it | the console reads Agent Runtime | set the two OTel variables; import by trace id with `cloud_trace_source` |
| Forty failures and no pattern | you read traces before clustering | `generate_loss_clusters`, then traces, then cases |

**Notes:** Read the ninth row aloud; it is the one the measurement on page 25 settled.

---

## Page 35 — References

**Type:** References.

- google-adk 2.9.0: `google/adk/evaluation/` (`agent_evaluator.py`, `trajectory_evaluator.py`, `final_response_match_v1.py`, `final_response_match_v2.py`, `eval_metrics.py`, `eval_config.py`, `eval_rubrics.py`, `metric_evaluator_registry.py`, `vertex_ai_eval_facade.py`), `google/adk/cli/conformance/`, `cli_tools_click.py`
- google-agents-cli 1.5.0: `google/agents/cli/eval/cmd_*.py`, `scaffold/agents/adk/tests/eval/`
- google-cloud-aiplatform 1.165.1: `agentplatform/_genai/evals.py`, `_evals_constant.py`, `types/common.py`
- adk.dev: [evaluate](https://adk.dev/evaluate/), [criteria](https://adk.dev/evaluate/criteria/), [user-sim](https://adk.dev/evaluate/user-sim/), [custom_metrics](https://adk.dev/evaluate/custom_metrics/), [environment_simulation](https://adk.dev/evaluate/environment_simulation/), [optimize](https://adk.dev/optimize/)
- Agent Platform: [agent-evaluation](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/agent-evaluation), [evaluate-agents](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/evaluate-agents), [evaluate-offline](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/evaluate-offline), [evaluate-online](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/evaluate-online), [manage-metrics](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/manage-metrics), [view-results](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/view-results), [quality-alerts](https://docs.cloud.google.com/gemini-enterprise-agent-platform/optimize/evaluation/quality-alerts), [Cloud Run Agent Platform features](https://docs.cloud.google.com/run/docs/ai/agent-platform-features)
- [GA announcement, 2026-07-31](https://developers.googleblog.com/en/agent-and-model-evaluations-in-gemini-enterprise-agent-platform-are-now-ga/)
- Measured 2026-09-13 in `jwd-gcp-demos`: `m4_trace_import.py`, `m4_score_run.py`; ROUGE-1 with `rouge_score`
- Companion: `agent_operations/m4.html` (2.7.1, 2026-08-25)

**Re-verify before delivery:** metric names and defaults, the region note for v2/v3 metric specs,
the Experimental labels in agents-cli, and whether the Cloud Run and GKE Agent Platform pages have
gained an evaluation integration.

**Notes:** Versions on the face. The companion page's per-step trajectory averaging is superseded
by page 8.
