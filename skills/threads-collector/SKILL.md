---
name: threads-collector
description: Scrolls Threads (threads.com) via Chrome, collects high-engagement posts into a session CSV, then evaluates each one against the user's hook playbook, relevance, and topics. On first run, walks the user through a 6-question interview (intent, topics, surface, strictness, handle, context). Ships with a seeded hook pattern playbook and a topics list that grow through use. Renders top-10 posts inline in chat with new topics and new hook patterns extracted from the run. Use when user says "collect threads", "catch threads posts", "run threads collector", "swipe threads", "grab threads posts", "collect threads content", "watch threads trending", "catch trending threads posts", or similar. Supports For You, Following, Search, Profile, and Trending surfaces. No API used — pure Chrome automation.
---

# Threads Collector (v0.4.0)

Two-phase workflow: **scroll fast, evaluate deeply**. Scroll only filters on a likes threshold — cheap DOM work. All topic matching, relevance scoring, and hook pattern classification happens after collection, in three sequential evaluation passes over the session CSV.

## Reference files (progressive disclosure)

Load these only when the step below says to. Each is a focused instruction for one phase.

- **`scroll-extraction.md`** — DOM selectors, per-post fields, likes-only gate. Load at Step 4.
- **`eval-hook-pattern.md`** — hook pattern matching + proposing new patterns. Load at Step 5a.
- **`eval-relevance.md`** — relevance scoring 1–100. Load at Step 5b.
- **`eval-topic.md`** — primary/secondary topic assignment + proposing new topics. Load at Step 5c.
- **`output-rendering.md`** — session CSV schema, inline report, Save gate. Load at Step 6.

## Persistent files in `<runtime_folder>`

Owned by the user, grown across runs:

- `config.md` — interview answers (surface, my_handle, min_likes, target_collected, etc.)
- `user_context.md` — free-text from Q6
- `topics.md` — flat list of topic labels, grows via Save gate
- `hook_patterns.md` — flat table of hook shapes, grows via Save gate
- `hook_candidates.md` — staging for proposed patterns observed 1–2 times
- `sessions/session-<timestamp>.csv` — one per run, scratch

## Operating principles

1. **Chat is the UI. Files are persistence.** Never ask the user to open or edit a file. Collect all inputs via `AskUserQuestion`. Write config programmatically from their answers.
2. **One question at a time.** One `AskUserQuestion` call per decision point.
3. **Tips inside options.** Each option label includes a one-line "when to pick this."
4. **Scroll cheap, evaluate deep.** Don't waste LLM tokens on low-engagement posts. Don't apply topic filters at scroll time.
5. **Session CSV is scratch.** Treat it as a workbook for this run. Only the summary (rendered inline) and the new topics/hooks (on Save) cross the run boundary.
6. **Render inline, don't dump to files.** The end-of-run report is a formatted chat response, not a pointer to a CSV.

## How to run

### Step 0 — Preflight

Stop immediately if any check fails.

1. Verify the Claude-in-Chrome extension is connected. If not: "The Claude-in-Chrome extension isn't connected. Open Chrome, install/enable it, and re-run."
2. Resolve `<runtime_folder>`:
   - If a Cowork folder is mounted → `<runtime_folder> = <mounted>/threads-collector/`. Create if missing.
   - Else → `request_cowork_directory` with phrasing: "This skill stores your config and each session's results inside a folder on your computer. Pick one (a dedicated folder works well). Re-open the same folder each run so your topics list and hook playbook accumulate."
3. Bootstrap `<runtime_folder>` idempotently (seed only if absent, never overwrite):
   - Create `sessions/` directory.
   - Copy the plugin's bundled `hook_patterns.md`, `topics.md`, `user_context.md` to `<runtime_folder>/` if they don't exist.

### Step 1 — Configure via interview (first run) or quick confirm (returning user)

Decide which branch:
- If `<runtime_folder>/config.md` exists AND has non-placeholder `my_handle` AND has non-placeholder `user_context.md` → **Step 1b**.
- Otherwise → **Step 1a**.

#### Step 1a — First-run interview (6 questions)

Open with: "First time running this — let me ask six quick questions so I can tune it to you. Takes about a minute. No files to edit."

Use `AskUserQuestion` for each, one at a time. Acknowledge briefly after each.

**Q1. Primary intent.** "What are you mining Threads for?"
- `Content ideas` — collect high-performing posts for inspiration when writing my own
- `Competitor watch` — track specific creators or peers in my niche
- `Trend spotting` — surface what's hot on Threads right now
- `Hook library` — study what hooks work so I can write better ones
- `Something else` (free text)

**Q2. Topics.** "Which topics should I classify posts against? Pick as many as apply. You can add more later."

Show suggestions tailored to Q1. Always include `Custom…` (free text) so the user can add niche-specific topics. Multi-select. User must pick at least one. After they pick, write the answers as the seed `topics.md` (one label per line, lowercase).

**Q3. Surface.** "Which feed should I scroll?"
- `For You` — Threads' personalized feed
- `Following` — only people you follow
- `Trending` — what's hot on Threads right now (two-phase — see Step 3b)
- `Search a topic` — I'll ask what query
- `Watch a creator` — I'll ask whose handle

If `Search a topic` → follow-up free-text for the query.
If `Watch a creator` → follow-up free-text for the handle.

**Q4. Likes threshold.** "What's the minimum likes count for a post to count as worth collecting?"
- `Loose (50+)` — catch more posts; useful for niche or small-creator surfaces
- `Default (200+)` — balanced; recommended
- `Strict (1000+)` — only breakout posts
- `Custom` — I'll ask for an exact number

**Q5. Your handle.** "What's your Threads handle? I'll always skip your own posts."

Single "Enter your Threads handle" free-text option. Required.

**Q6. Context (free text).** "Anything else I should know about you or your audience? This helps me score how relevant each post is to you. Skip is fine."

Single "Enter context" free-text option. Empty is valid — write `_(none)_` to `user_context.md` if skipped.

**After Q6**, write config + context:

1. Write `<runtime_folder>/config.md` with:
   - `primary_intent` (from Q1)
   - `surface` (from Q3)
   - `min_likes` (from Q4: Loose=50, Default=200, Strict=1000, Custom=<user number>)
   - `my_handle` (from Q5)
   - `target_collected`: 100 (default — can change in quick-confirm)
   - `max_scroll_cycles`: 60
   - `scroll_wait_seconds`: 1.5
   - `stop_when_posts_older_than_hours`: 48
2. Append Q2 answers to `<runtime_folder>/topics.md` (one per line). If topics.md doesn't exist, create it with the seed topics from the bundled template plus user additions.
3. Write Q6 answer to `<runtime_folder>/user_context.md` verbatim (replacing the "_no context yet_" placeholder).

Acknowledge: "Set. Showing you the plan before I start." → Step 2.

#### Step 1b — Quick confirm (returning user)

Render one-line summary: "Running collector with **[surface]** / min_likes **[min_likes]** / target **[target_collected]** posts / topics: **[comma list from topics.md]**. Change anything?"

`AskUserQuestion`:
- `Run it` — proceed to Step 2
- `Change surface` — ask Q3 only, update config
- `Change likes threshold` — ask Q4 only, update config
- `Change target size` — ask a free-text "how many posts this run?"
- `Change context` — ask Q6 again, overwrite user_context.md
- `Re-run the full interview` — fall through to Step 1a

### Step 2 — Plan preview

Show a plain-English plan:

```
Here's what I'll do:
• Scroll [surface] on threads.com
• Keep any post with [min_likes]+ likes — skip everything below
• Stop at [target_collected] collected posts (or 60 scrolls)
• Skip posts from @[my_handle] and reply-posts
• Then: evaluate each post against your hook playbook, score relevance 1–100, assign topics
• Report: top 10 + new topics + top topics + new hook patterns
• Session CSV: sessions/session-[timestamp].csv
```

`AskUserQuestion`:
- `Go` — proceed to Step 3
- `Adjust something` — ask "What to adjust?" → route to Step 1b option
- `Cancel` — stop clean

### Step 3 — Open Threads in Chrome

Open https://threads.com in a new tab via Claude-in-Chrome MCP. Wait up to 10s for content to load. Navigate to the correct surface:

- `for_you` → default
- `following` → click Following tab
- `search:<query>` → https://threads.com/search?q=<query>
- `profile:<handle>` → https://threads.com/@<handle>
- `trending` → Step 3b

If the surface doesn't load in 10s, stop and report.

### Step 3b — Trending mode (only if surface = trending)

Trending shows topics, not posts. Two-phase:

**Phase 3b.1** — Navigate to https://threads.com/search (no query). Wait 2s. Extract the trending-now chips (topic names + URLs). Write to `<runtime_folder>/sessions/trending-<timestamp>.json`.

**Phase 3b.2** — Filter:
- Apply `trending_topics_allowlist` if set (substring match, case-insensitive).
- Apply `trending_topics_blocklist` if set.
- Cap at `trending_topics_per_run` (default 5).

If 0 topics qualify: report inline ("No trending topics matched your filters today. Trending list was: [list]. Widen allowlist?") and offer AskUserQuestion alternatives.

**Phase 3b.3** — For each qualifying topic:
1. Navigate to its URL.
2. Scroll + capture per Step 4, cap at `trending_posts_per_topic` (default 20) for this topic's contribution to the session CSV.
3. Tag each captured post with `caught_from_trending_topic=<topic>` and `seen_in=trending:<topic>`.
4. Move to the next topic.

When done, go to Step 5 (evaluation runs over the combined session CSV).

### Step 4 — Scroll and capture

**→ Load `scroll-extraction.md` now.**

Likes-only gate at scroll time. Every post that passes gets extracted and written to `<runtime_folder>/sessions/session-<timestamp>.csv`. Header row written on first append.

Loop:
1. Capture visible posts that pass the likes gate.
2. Scroll one viewport.
3. Wait `scroll_wait_seconds`.
4. Repeat until a stop condition fires: `target_collected` rows, `max_scroll_cycles`, 3 empty scrolls, or posts-older-than cutoff.

Log which stop condition triggered — reported in Step 6.

### Step 5 — Evaluate in three passes

Pass each row of the session CSV through three sequential evaluations. Each pass loads its own reference file, fills its own columns, and produces a run-level summary.

#### Step 5a — Hook pattern match

**→ Load `eval-hook-pattern.md` now.**

For each row: match against `hook_patterns.md` or propose a new pattern name. At end of pass: cluster proposed names; ≥3 occurrences → promote to `new_hook_patterns[]`; 1–2 occurrences → `hook_candidates[]`.

Writes `hook_pattern_id` or `hook_pattern_proposed` columns.

#### Step 5b — Relevance scoring

**→ Load `eval-relevance.md` now.**

For each row: score 1–100 against `user_context.md` + `topics.md` + `primary_intent`. Writes `relevance` (integer) and `relevance_reason` (short sentence).

#### Step 5c — Topic assignment

**→ Load `eval-topic.md` now.**

For each row: assign `primary_topic` and optional `secondary_topic`. If no existing topic fits: `new_topic_proposed`. At end of pass: promote all proposed topics (no threshold) to `new_topics[]`.

Writes `primary_topic`, `secondary_topic`, `new_topic_proposed` columns.

### Step 6 — Report inline + Save gate

**→ Load `output-rendering.md` now.**

Render directly in chat:
1. Headline (one sentence — how many collected, whether target was hit).
2. Top 10 table — sorted by `(relevance DESC, likes DESC)`.
3. New topics introduced this run (skip if none).
4. Top topics by post count across the run.
5. New hook patterns extracted (skip if none). Hook candidates one-liner if any.
6. Run stats (scrolled / passed likes gate / duplicated / captured / stop condition / runtime).
7. **Save gate** via AskUserQuestion — save new topics + hooks to persistent files, let user pick which, or discard. Skip this gate entirely if nothing new was proposed.
8. Follow-up actions via AskUserQuestion.

After Save: append-only writes to `topics.md` / `hook_patterns.md` / `hook_candidates.md`. Never overwrite.

## Failure modes

- **Chrome extension not connected** → Step 0 catches; stop with clear message.
- **DOM parse drift** (≥20% of visible posts fail likes parse) → Step 6 surfaces; offer a "rescan and fix selectors" follow-up.
- **Zero collected after full scroll** → report honestly; suggest loosening `min_likes` via Step 1b.
- **User aborts mid-interview** → acknowledge; no partial config written.
- **Evaluation passes error on one row** → log the row's post_url to run stats, skip it, don't abort the pass.
