---
name: threads-collector
description: Scrolls Threads (threads.com) via Chrome and catches posts matching criteria the user confirms via a short interview. On first run, walks the user through 5 multiple-choice questions (intent, topics, surface, strictness, handle) using AskUserQuestion — no file editing required. On subsequent runs, one-question quick-confirm. Classifies caught posts by category, hook type, template type, tone. Renders top catches inline in chat; backing library persists as CSV + markdown files in the user's Cowork folder. Use when user says "collect threads", "catch threads posts", "run threads collector", "swipe threads", "grab threads posts", "collect threads content", "watch threads trending", "catch trending threads posts", or similar. Supports For You, Following, Search, Profile, and Trending surfaces. No API used — pure Chrome automation.
---

# Threads Collector

Drives Chrome to Threads, scrolls a chosen surface, catches posts that pass user-confirmed filters, classifies each caught post, and renders the top catches inline. Persists the library as CSV + markdown files so it accumulates across runs.

## Reference files (progressive disclosure)

Read these only when the step below says to. They are out-of-line so they don't inflate the context window on every invocation.

- **`scroll-extraction.md`** — DOM selectors, per-post field extraction, thread handling, dedup rules. Load at Step 4.
- **`classification.md`** — category / hook_type / template_type / tone enums, classification rules, `why_it_hit` heuristic. Load at Step 6.
- **`output-rendering.md`** — CSV schema, post-markdown format, inline results table format, hook_patterns.md append rules. Load at Step 7 and Step 8.

## Operating principles

1. **Chat is the UI. Files are persistence.** Never ask the user to open or edit a file. Collect all inputs via `AskUserQuestion`. Write config programmatically from their answers.
2. **One question at a time.** Use one `AskUserQuestion` call per decision point. Don't batch. Acknowledge briefly after each answer, then move on.
3. **Tips inside options.** Every option label includes a one-line "when to pick this" tip so the user learns the skill while using it.
4. **Smart defaults.** First run should be completable by picking default options all the way through. Defaults must yield useful catches on a typical B2B-creator feed.
5. **Render inline, don't dump to files.** End-of-run summary is a formatted table in chat, not a pointer to a CSV.
6. **Library persists.** Config and library live in `<runtime_folder>` so subsequent runs dedupe against past catches and hook_patterns.md accumulates observations.

## How to run

### Step 0 — Preflight

Do NOT proceed if any check fails. Report the specific failure and stop.

1. Verify the Claude-in-Chrome extension is connected. If not: "The Claude-in-Chrome extension isn't connected. Open Chrome, install/enable it, and re-run." Stop.

2. Resolve the runtime folder. This skill writes all user-editable state (config + library) inside whichever folder is mounted in the current Cowork session, NEVER a hardcoded `~/`-anchored path.
   - If no Cowork folder is mounted, use `request_cowork_directory` to ask the user to pick one. Phrasing: "This skill stores your config and the library of caught posts inside a folder on your computer. Pick one — a dedicated folder works well. Re-open the same folder when you run this skill again so your library accumulates."
   - Once mounted, set `<runtime_folder> = <mounted>/threads-collector/`. Create it if missing.

3. Bootstrap `<runtime_folder>` idempotently (seed only if absent, never overwrite):
   - If `<runtime_folder>/library/` is missing, create it with `library/index.csv` (header row), `library/posts/`, and copy the plugin's bundled `hook_patterns.md` to `library/hook_patterns.md`.

### Step 1 — Configure via interview (first run) or quick confirm (returning user)

**Decide which branch:**

- If `<runtime_folder>/config.md` exists AND has non-placeholder values for `my_handle` and `my_topics` → go to **Step 1b (quick confirm)**.
- Otherwise → go to **Step 1a (first-run interview)**.

#### Step 1a — First-run interview (5 questions, ~30 seconds)

Open with a one-line warm intro in chat: "First time running this — let me ask a few quick questions so I can tune it to you. Takes about 30 seconds, no files to edit."

Then use `AskUserQuestion` for each of the following in order. ONE call per question. After each answer, acknowledge with a short one-liner ("got it", "noted", etc.) and proceed.

**Q1. Primary intent.** "What are you mining Threads for?"
- `Content ideas` — collect high-performing posts for inspiration when writing my own
- `Competitor watch` — track specific creators or peers in my niche
- `Trend spotting` — surface what's hot on Threads right now
- `Hook library` — study what hooks work so I can write better ones
- (Custom / Something else — free text)

**Q2. Topics.** "Which topics should I classify catches against? Pick as many as apply."

Show topic suggestions tailored to Q1's answer. Always include "Custom…" (free text) so the user can add niche-specific topics. Examples by intent:
- For `Content ideas` or `Hook library` → "brand voice", "AI in marketing", "content strategy", "personal branding", "LinkedIn/Threads growth", "creator economy"
- For `Competitor watch` → "B2B SaaS", "product marketing", "founder content", "sales enablement", "growth", "community building"
- For `Trend spotting` → "AI", "marketing", "tech", "creator economy", "productivity", "business"

Default: offer 6–8 suggestions as multi-select, plus a Custom option. User must pick at least one.

**Q3. Surface.** "Which feed should I scroll?"
- `For You` — Threads' personalized feed; best for discovering creators you don't follow yet
- `Following` — only people you follow; best when your follow list is already curated
- `Trending` — what's hot on Threads right now; best for timely takes
- `Search a topic` — I'll ask what query (e.g. "AI content strategy")
- `Watch a creator` — I'll ask whose handle (e.g. `@justinwelsh`)

If user picks `Search a topic`: follow up with a one-question AskUserQuestion asking for the query (use the "Something else" free-text option labeled "Enter your search query").

If user picks `Watch a creator`: follow up with a one-question AskUserQuestion asking for the handle (use the "Something else" free-text labeled "Enter the handle (with or without @)").

**Q4. Strictness.** "How picky should I be about what counts as catch-worthy?"
- `Loose` — catch anything with 50+ likes; lots of catches, more noise (good for niche/small-follower-count surfaces)
- `Default` — 200+ likes OR high reply ratio; balanced (recommended)
- `Strict` — 1000+ likes only; only breakout posts
- `Custom` — I'll walk you through setting thresholds (falls through to 2 follow-up questions: `min_likes` and `min_reply_like_ratio`)

**Q5. Your handle.** "What's your Threads handle? I'll always skip your own posts when they appear."

Use AskUserQuestion with a single "Enter your Threads handle" option (free text via the "Something else" path). Required — do not accept empty.

**After Q5**, write config.md programmatically:
- Use the plugin's bundled `config.md` template (sibling of this SKILL.md) as the base structure.
- Substitute user's answers into the fields: `surface`, `my_handle`, `my_topics`, `min_likes`, `min_reply_like_ratio`, and (for search/profile) the search query or target handle as part of `surface`.
- Map strictness presets to engagement thresholds:
  - Loose → `min_likes: 50`, `min_reply_like_ratio: 0.10`
  - Default → `min_likes: 200`, `min_reply_like_ratio: 0.15`
  - Strict → `min_likes: 1000`, `min_reply_like_ratio: 0.20`
- Keep all other config fields at their template defaults.
- Save to `<runtime_folder>/config.md`.

Acknowledge: "Config saved. Now let me show you the plan before I start scrolling." → Step 2.

#### Step 1b — Quick confirm (returning user)

Summarize current config in one sentence: "Running threads-collector with **[surface]** + topics: **[topic list]** + **[strictness preset]** thresholds. Change anything?"

Use `AskUserQuestion`:
- `Run it` — proceed to Step 2 with current config
- `Change surface` — ask Q3 only, update config, proceed
- `Change topics` — ask Q2 only, update config, proceed
- `Change thresholds` — ask Q4 only, update config, proceed
- `Re-run the full interview` — fall through to Step 1a

### Step 2 — Plan preview (confirmation gate)

Before opening Chrome, show the user a plain-English plan as a short bulleted summary in chat:

```
Here's what I'll do:
• Scroll [surface] on threads.com
• Catch posts matching [threshold summary, e.g. "200+ likes OR 15%+ reply ratio"]
• Classify against your topics: [topic list]
• Skip posts from @[my_handle]
• Stop after 50 posts or 30 scroll cycles (whichever first)
• Save to <runtime_folder>/library/
```

Use `AskUserQuestion`:
- `Go` — proceed to Step 3
- `Adjust something` — ask "What to adjust?" (surface / thresholds / topics / limits / handle) and loop back through the relevant single question, then re-show this plan
- `Cancel` — stop cleanly, don't touch Chrome

### Step 3 — Open Threads in Chrome

Using the Claude-in-Chrome MCP, open https://threads.com in a new tab (or reuse an existing Threads tab if present). Wait for content to load (up to 10 seconds). Confirm the correct surface is shown per config:

- `for_you` — default tab
- `following` — click the "Following" tab
- `search:<query>` — navigate to `https://threads.com/search?q=<query>`
- `profile:<handle>` — navigate to `https://threads.com/@<handle>`
- `trending` — see Step 3b (two-phase flow)

If the surface doesn't load within 10 seconds, report the issue to the user and stop.

### Step 3b — Trending mode (only if surface = trending)

Trending is a two-phase surface because Threads shows trending *topics*, not trending posts directly.

**Phase 3b.1 — Discover trending topics:**
1. Navigate to `https://threads.com/search` (no query string — this is the trending landing page).
2. Wait 2 seconds for the "Trending now" section to render.
3. Extract the list of trending topic names and URLs (usually 10–15 chips).
4. Write the discovered list to `<runtime_folder>/library/trending-[YYYY-MM-DD-HHMM].json` as an audit trail.

**Phase 3b.2 — Filter trending topics by config:**
- If `trending_topics_allowlist` is non-empty, keep only topics matching any substring (case-insensitive).
- If `trending_topics_blocklist` is non-empty, drop matching topics.
- Cap at `trending_topics_per_run` (default 5), preferring topics not yet drilled into this week.

If 0 trending topics qualify after filtering: report inline to the user ("No trending topics matched your allowlist today. Trending list was: [list]. Want to relax the allowlist?") and offer to proceed with an ad-hoc choice via AskUserQuestion.

**Phase 3b.3 — Drill into each qualifying topic:**
For each qualifying topic:
1. Navigate to its URL.
2. Scroll and capture per Steps 4–7, but cap posts per topic at `trending_posts_per_topic` (default 20) and scroll cycles at `trending_scroll_cycles_per_topic` (default 8).
3. Tag each captured post with `caught_from_trending_topic="<topic name>"` and `seen_in="trending:<topic name>"`.
4. Move to the next topic.

When all qualifying topics are processed, continue to Step 8 (report).

### Step 4 — Scroll and capture

**→ Load `scroll-extraction.md` now for DOM selectors, per-post field extraction, thread handling, and dedup rules.**

High-level loop:
1. Capture all currently visible posts per the extraction rules.
2. Scroll one viewport.
3. Wait `scroll_wait_seconds` (default 1.5s).
4. Repeat until a stop condition hits:
   - `max_scroll_cycles` reached
   - `max_posts_to_collect` reached
   - 3 consecutive scrolls with no new posts (end of fresh content)
   - A post's timestamp is older than `stop_when_posts_older_than_hours`

### Step 5 — Apply catch filters

For each captured post, check config filters in order. Log every drop with reason to `<runtime_folder>/library/drops-[YYYY-MM-DD].csv`.

1. **Hard excludes** — ads, reposts, own posts, reply-posts, blocklisted authors → drop.
2. **Author filters** — if `author_allowlist` set, drop anyone not in it; drop anyone in `author_blocklist`.
3. **Format filters** — match required format (single/thread/either) and media requirement (any/text_only/must_have_media).
4. **Content keyword filters** — apply `required_keywords_any`, `required_keywords_all`, `excluded_keywords` as defined.
5. **Engagement filter** — evaluate `catch_rule` from config (default: `likes >= min_likes OR reply_like_ratio >= min_reply_like_ratio`).

Posts that pass all → **caught**.

### Step 6 — Classify caught posts

**→ Load `classification.md` now for enums, rules, and `why_it_hit` heuristics.**

For each caught post, assign: `category_primary`, `category_secondary` (optional), `template_type`, `hook_type`, `tone`, `opens_with`, `reply_like_ratio`, `why_it_hit`. Classification runs on the hook post's text alone — no external lookups.

### Step 7 — Validate, write library, append hook_patterns.md

**→ Load `output-rendering.md` now for validation rules, CSV schema, markdown format, and hook_patterns.md append rules.**

Three sub-steps, in order:
1. **Validate** each caught + classified post against the validation checklist. Rows that fail go to `<runtime_folder>/library/malformed-[YYYY-MM-DD].csv`, not the library.
2. **Write** valid rows to `<runtime_folder>/library/index.csv` (append) and write a post markdown file to `<runtime_folder>/library/posts/<handle>_<post_id>.md`.
3. **Append** the top 3 caught posts (by `reply_like_ratio`) to the "Observed in the wild" section of `<runtime_folder>/library/hook_patterns.md`.

If ≥20% of caught posts ended up in malformed-*.csv, flag this prominently in Step 8 — a DOM selector has likely drifted.

### Step 8 — Report inline in chat

**→ `output-rendering.md` also covers the inline results format — use it to render.**

Do NOT dump the user to CSV files. Render the run summary directly in chat as formatted content:

1. **One-sentence headline** — e.g. "Caught 14 posts from For You, 3 standouts." If surface was trending, also list which trending topics were drilled and how many catches came from each.
2. **Top-3 table** — columns: author, first-line of hook (truncated to 80 chars), likes, replies, hook_type, why_it_hit. Use markdown table syntax.
3. **Category breakdown** — "6 content strategy, 4 AI in marketing, 3 brand voice, 1 unclassified".
4. **Run stats** (one line) — posts seen / deduped / dropped (by top reason) / caught / malformed. If malformed ≥20%: "⚠️ DOM extraction is drifting — tell me 'the selectors need updating' and I'll rescan and fix."
5. **Follow-up actions** via `AskUserQuestion`:
   - `Draft 3 post ideas from these hooks` — summarize top catches into original post suggestions using the user's brand voice
   - `Run again on a different surface` — jump back to Step 1b with the "Change surface" branch
   - `Show me all catches as a table` — render the full catch list inline
   - `Done` — end the turn cleanly

At the bottom of the report, one-line FYI (not a call-to-action): "Full library: `<runtime_folder>/library/index.csv` — open it in any CSV viewer if you want to query or filter."

## Failure modes and handling

- **Chrome extension not connected** → Step 0 catches this; stop with a clear message.
- **DOM extraction broke** (≥20% malformed) → Step 8 surfaces this prominently; offer a "re-scan and fix selectors" follow-up.
- **Config file has garbage values** (user hand-edited and broke it) → Step 1 validation catches this; offer to re-run the interview.
- **User aborts mid-interview** → acknowledge ("no worries, say 'collect threads' whenever you're ready"); don't write a partial config.
- **Zero catches after a full run** → report honestly ("no posts passed your filters"), inspect drops-*.csv, suggest loosening thresholds via Step 1b "Change thresholds".
