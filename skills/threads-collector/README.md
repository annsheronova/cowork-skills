# Threads Collector Skill (v0.4.0)

A Cowork skill that scrolls Threads (via the Claude-in-Chrome extension), collects high-engagement posts into a session CSV, then evaluates each one — matching against your hook playbook, scoring relevance, assigning topics. On-demand. No API. No config files to edit.

## What v0.4.0 does differently from v0.3.0

- **Scroll is cheap, evaluation is deep.** Scroll-time filter is a single likes threshold. Everything else — topic, relevance, hook pattern — happens after collection in three sequential evaluation passes.
- **Session CSVs, not a persistent library.** Each run writes to `sessions/session-<timestamp>.csv`. No cross-run dedup. What persists across runs: your topics list and hook playbook, both of which grow when you accept the Save gate.
- **Flat hook playbook.** `hook_patterns.md` is now a pure lookup table. No prose, no narrative — just `id | pattern_name | definition | example_hook | example_post_url`.
- **Relevance scoring (1–100).** Every captured post gets scored against your `user_context.md` and topics. The top 10 posts by `(relevance, engagement)` are the report's headline deliverable.
- **Open-ended topics.** The evaluator proposes new topic names when existing ones don't fit. On Save, they append to `topics.md` and become matchable on future runs.
- **Hook pattern discovery.** Same mechanism — proposed patterns observed ≥3 times in one run get promoted to `hook_patterns.md`. Proposals seen 1–2 times go to `hook_candidates.md` staging for next run.

## Install

Install the parent plugin from the repo root — see [../../README.md](../../README.md). Skill appears in Cowork once the plugin is installed. Nothing to copy by hand.

## First run

Say one of the trigger phrases below. The skill will:

1. Check that Claude-in-Chrome is connected.
2. Ask you to pick a folder for the runtime library (a dedicated folder like `~/Documents/threads-research/` works well — re-open the same folder every run so topics + hook playbook accumulate).
3. Walk you through **6 multiple-choice questions** (about a minute):
   - **Intent** — content ideas / competitor watch / trend spotting / hook library
   - **Topics** — which topics to classify against (suggestions tailored to your intent, plus custom)
   - **Surface** — For You / Following / Trending / Search / Watch a creator
   - **Likes threshold** — Loose (50+) / Default (200+) / Strict (1000+) / Custom
   - **Your handle** — so your own posts get skipped
   - **Context** — free text: anything you want me to know about you or your audience
4. Show you the plan before opening Chrome. Confirm `Go`, `Adjust something`, or `Cancel`.
5. Scroll with likes-only gate until 100 posts collected (or 60 scrolls, whichever first).
6. Evaluate all 100 in three passes: hook pattern match → relevance 1–100 → primary/secondary topic.
7. Render top 10 inline in chat + new topics + top topics + new hook patterns.
8. Save gate: append new topics and promoted hook patterns to persistent files (or discard).

On subsequent runs: one-line summary + quick-confirm (`Run it`, `Change surface`, `Change likes threshold`, `Change target size`, `Change context`, or full re-interview).

## Prerequisites

- **Claude-in-Chrome extension** installed and connected.
- **Logged into Threads** in Chrome. The skill won't handle authentication.

## Triggers

- "collect threads"
- "swipe threads"
- "catch threads posts"
- "run the threads collector"
- "grab threads posts for me"

## Where data lives

Inside `<your Cowork folder>/threads-collector/`:

```
threads-collector/
  config.md                            — written from your interview answers
  user_context.md                      — the free-text from Q6
  topics.md                            — flat list of topic labels (grows on Save)
  hook_patterns.md                     — flat table of hook shapes (grows on Save)
  hook_candidates.md                   — staging (auto-created after first run with candidates)
  sessions/
    session-YYYY-MM-DD-HHMM.csv        — one per run; scratch but kept for reference
    trending-YYYY-MM-DD-HHMM.json      — only when surface=trending
```

**The session CSV is scratch.** Old sessions aren't auto-deleted (useful if you want to query history manually), but they don't affect future runs — each run starts fresh.

## The three evaluation passes

After 100 posts are in the session CSV:

**Pass 1 — Hook pattern** (`eval-hook-pattern.md`). For each post, match against `hook_patterns.md`. If no match, propose a new pattern name. End-of-pass: promote proposals seen ≥3 times; stage proposals seen 1–2 times.

**Pass 2 — Relevance** (`eval-relevance.md`). Score 1–100 against `user_context.md` + `topics.md` + your primary_intent. Writes score + one-line reason.

**Pass 3 — Topic** (`eval-topic.md`). Assign primary_topic + optional secondary_topic. Propose new topic label if nothing fits. All proposed topics are eligible for promotion on Save — no threshold.

## Sample output — top 10 table

```
Collected 100 posts. Evaluated for you. Showing top 10.

|  # | Author              | Hook                                                                      | Likes | Replies | Topic              | Pattern                | Relevance |
|----|---------------------|---------------------------------------------------------------------------|-------|---------|--------------------|------------------------|-----------|
|  1 | @creatortadeaas     | "I've posted 500+ times on Threads. Here are 7 types of posts that..."    | 2,847 |    412  | content strategy   | List-title open loop   |   95      |
|  2 | @digitalalliancehq  | "Most creators think they need more followers. They actually need..."      |   892 |    156  | brand voice        | Contrarian flip        |   92      |
|  3 | @hopeengineer       | "Over the past year, I've gained thousands of followers and left my..."    | 1,203 |    287  | creator economy    | Confession-as-authority|   88      |

**New topics from this run** (will add to your topics list on Save):
• founder storytelling — 7 posts
• ai agent demos — 4 posts

**Top topics this run:** content strategy (28) · ai in marketing (19) · brand voice (14) · founder storytelling (7) · creator economy (6)

**New hook patterns extracted** (will add to playbook on Save):
• **Comment-to-unlock reveal** — Post promises a reveal gated on replies.
  Example: "Drop a '1' below if you want me to share the full framework."
  Seen in 4 posts this run.

Stats: 143 scrolled · 127 passed likes gate · 27 duplicated · 100 captured · stopped on: target reached · runtime 4m 12s
```

## Tuning after your first few runs

All conversational — no file editing.

- **Want more posts collected?** On next run: `Change target size` → enter 150 / 200 / etc.
- **Too few passing the likes gate?** `Change likes threshold` → `Loose (50+)`.
- **Posts all about the wrong subjects?** `Change context` — rewrite the free-text to be more specific about what you care about.
- **Relevance scores feel off?** Usually means `user_context.md` is too generic. Run `Change context` and be more specific about audience, goals, and what "relevant" means to you.
- **Topic list getting bloated?** Open `topics.md` and delete the ones you don't want to match against anymore. The skill only appends — it never overwrites your edits.
- **Hook playbook getting bloated?** Same — open `hook_patterns.md`, delete rows. Or prepend `[retired]` to a pattern's name to keep the row but skip it in matching.

## Common failures

### 1. "No posts collected"
**Likely cause:** likes threshold too high for this surface, or DOM extraction failed on likes parsing.
**Check:** `min_likes` in config. For niche surfaces, set to 50 or lower.
**Fix:** `Change likes threshold` → `Loose`. If still zero, the DOM has drifted — tell me "the likes selector is broken" and I'll rescan.

### 2. "Lots of posts collected but all irrelevant"
**Likely cause:** `user_context.md` is generic; `topics.md` is too broad.
**Fix:** `Change context` — be specific about who you are and who you're writing for. Edit `topics.md` to remove labels you don't actually care about.

### 3. "Same hook patterns repeatedly; nothing new proposed"
**Likely cause:** Working as intended — your feed is steady and the existing playbook covers it. If you want novelty, `Change surface` → `Trending` or `Search a topic`.

### 4. "DOM extraction drifted" warning
**Cause:** Threads changed their post-card markup.
**Fix:** Say "the DOM selectors need updating" and the assistant will re-inspect Threads' current DOM via the Chrome extension and update `scroll-extraction.md`.

### 5. "Chrome tab didn't load" or "stuck on login"
**Cause:** extension isn't connected, or you're logged out.
**Fix:** Open Chrome. Confirm the Claude-in-Chrome icon is active. Open threads.com and confirm you're logged in. Re-run.

### 6. "Trending mode found zero qualifying topics"
**Cause:** `trending_topics_allowlist` is too narrow for today's trending list.
**Fix:** The skill offers inline "widen allowlist" options. Or `Change surface` → `Search a topic` for more targeted discovery.

## What this skill doesn't do (by design)

- **No author-follower lookups** (would require clicking through to each profile or using the Threads API).
- **No scheduled runs** (invoke manually; you can wrap with `/schedule` if you want a daily).
- **No publishing** (read-only by design; writing posts is a separate concern).
- **No cross-run dedup** (session CSVs are scratch; what persists is topics + hook playbook).

## Design principles

- **Chat is the UI, files are persistence.** Setup happens via questions, not file editing.
- **One question at a time.** Each decision gets its own `AskUserQuestion`.
- **Smart defaults.** Picking default on every question should yield useful collection.
- **Plan before execute.** You see the plan before Chrome opens.
- **Render results inline.** The report is formatted chat content, not a "go open the CSV" redirect.
- **Separation of concerns.** Each pass has one job (hook / relevance / topic) and lives in one file.

If the skill ever asks you to edit a file, that's a bug — tell me and I'll fix it.
