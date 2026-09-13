# Module 6 — page list (adaptation of the companion page)

Decision (Jeff, 2026-09-13): adapt `agent_operations/m6.html` page for page into the
agent_ops format, applying the brief's edits. No deck map; this list is the reviewed plan.

Delivery minutes (non-lab): **20**. Content pages: **15** (about 1.3 minutes each, the
companion's density). Revised 2026-09-13 per Jeff's feedback: examples as check rows, context caching before response caching on page 6, adk-redis as the page 10 example, Agent Analytics setup page added, model override and RunConfig labels verified live.

Baseline: google-adk **2.9.0**, default model `gemini-3.5-flash`. Prices from the Agent
Platform pricing page on 2026-09-13, global endpoint, per 1M tokens, labeled illustrative on
every page that uses them: Gemini 3.5 Flash-Lite $0.30 in / $2.50 out; Gemini 3.5 Flash
$1.50 / $9.00; Gemini 3.1 Pro $2.00 / $12.00; cached input 10% of the input price.

## Worked scenario numbers (illustrative, recomputed here)

Dana's support agent on Gemini 3.5 Flash. Prefix (instruction plus tool declarations)
4,000 tokens. Each turn: user 100, tool call 100, tool result 800, answer 200; history grows
1,200 per turn; two model calls per turn.

| | Input tokens | Output tokens | Input $ | Output $ | Total $ |
|---|---|---|---|---|---|
| Turn 1 | 9,100 | 300 | | | |
| Turn 12 | 35,500 | 300 | | | |
| 2-turn conversation | 20,600 | 600 | 0.031 | 0.005 | 0.036 |
| 12-turn conversation | 267,600 | 3,600 | 0.401 | 0.032 | 0.434 |

12-turn input split: prefix re-sent 96,000 (36%), history re-sent 158,400 (59%), new
tokens 13,200 (5%). Input is 92% of the bill; 12 turns cost 12× 2 turns.

| Page | From | Type | Example scenario |
|---|---|---|---|
| 1 | new | opener | — |
| 2 | source slide 2 | objectives | — |
| 3 What is billed, what multiplies, what hides | companion 3 | concept, cards + price table | Dana's one-day bill read three ways: SKU line, label split, no per-conversation view |
| 4 Where the tokens go | companion 4 | mechanism, bar + turn table | the 12-turn numbers above |
| 5 Trim the re-sent input | companion 5 | numbered rows | 30 tool declarations → 6 on the router: 1,680 fewer input tokens per call |
| 6 Two mechanisms, two names | companion 6 + 7 | cards + two-band diagram | "What is your return window?" 900×/day: response cache skips the model; context cache discounts the prefix |
| 7 Implicit caching | new | concept | turn 5 call B re-sends call A's 8,900 tokens; on a hit the call costs $0.0027 instead of $0.0147 |
| 8 Explicit ADK context caching | companion 8 | code | 4,000-token prefix cached across 22 calls saves $0.119 of $0.401 input; storage $0.002; the date-in-static_instruction miss |
| 9 Context compaction | new | concept + short code | token_threshold=20000, event_retention_size=6 on a 40-turn session |
| 10 Response caching, how you build it | adk-response-caching.html | code | the FAQ question hits a stored answer; exact match first, adk-redis for paraphrases |
| 11 Model right-sizing | companion 9 | comparison table | 40 eval cases, threshold 0.90: Flash-Lite 0.85, Flash 0.93, Pro 0.95 → Flash |
| 12 Fine-tuning break-even | companion 10 | concept | 200,000 classifications/month; tuned Flash at 1.5× with a 400-token prompt saves $0.00153/request; training $30; break-even 19,600 requests; without the prompt cut it loses $0.00135/request |
| 13 Routing: three ways | companion 11 + 12 + 13 | cards + code | 80% lookups on Flash-Lite, 20% policy reads on Pro: blended $0.64 per 1M input against $2.00 |
| 14 The FinOps toolkit | companion 3 table + 15 lede | mechanism figure + table | RunConfig labels → billing export split; budget Pub/Sub at 80%; org policy blocks a Pro deploy in dev |
| 15 Setting up BigQuery Agent Analytics | new (revision 2026-09-13) | code + concept | 1M model calls a month: about 2 GiB written and stored, daily query inside the free tier |
| 16 Cost per conversation | companion 15 | code (SQL) | top row a 31-turn conversation at $1.12, 30× the median; alert on prompt tokens per session |
| 17 The AI FinOps loop | companion 16 | cards | switching the lookup agent to Flash-Lite: eval holds at 0.91, ships |
| 18 Consequences | new | table | — |
| 19 References | new | list | — |

Dropped from the companion: page 1 (about), 14 (batch; one line in page 11 notes), 17, 18.
