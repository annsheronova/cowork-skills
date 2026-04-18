---
name: threads-collector
description: Scrolls Threads (threads.com) via Chrome and catches posts matching user-defined criteria in the config file. Use when user says "collect threads", "catch threads posts", "run threads collector", "swipe threads", "grab threads posts", "collect threads content", "watch threads trending", "catch trending threads posts", or similar. Reads <runtime_folder>/config.md for catch criteria. Supports For You, Following, Search, Profile, and Trending surfaces. No API used — pure Chrome automation.
---

# Threads Collector

A skill that drives Chrome to Threads, scrolls the user's feed, and catches posts that match the criteria defined in the user's config file. Produces a structured library the user can later query for content ideation.

## What this skill does (and doesn't)

**Does:**
- Opens Chrome and navigates to threads.com
- Scrolls a configured surface (For You / Following / search / profile)
- Reads the config to understand what "catch-worthy" means to this user
- Extracts each qualifying post's text, author, engagement counts, metadata
- Classifies each caught post (category, template type, hook type, tone) using the post text alone
- Writes caught posts to a library CSV and individual markdown files

**Doesn't:**
- Use the Threads API (by design — keeps it simple, no rate limits)
- Look up author follower counts (requires API or extra browser clicks — out of scope for v1)
- Run on a schedule (invoke on demand)
- Publish anything (read-only)

## How to run this skill

### Step 0 — Preflight (do this first, every single invocation)

Do NOT proceed to Step 1 if any of the checks below fail. Report the specific failure to the user and stop.

**A. System prerequisites**

1. Verify the Claude-in-Chrome extension is connected. If not: "The Claude-in-Chrome extension isn't connected. Open Chrome, install/enable it, and re-run." Stop.

2. Resolve the runtime folder. This skill is installed via the `cowork-skills` Claude Code plugin. The plugin's skill folder (the one containing this SKILL.md and the sibling `config.md` / `hook_patterns.md`) is read-only source of truth. User-editable runtime state — the user's real config and the library of caught posts — lives **inside whichever folder is mounted in the current Cowork session**, NOT in any hardcoded `~/`-anchored path.
   - If no Cowork folder is mounted, use the `request_cowork_directory` tool to ask the user to pick one. Suggested phrasing: "This skill stores your config and the library of caught posts inside a folder on your computer. Pick a folder — a dedicated one (e.g. `Documents/threads-research/`) or any Cowork project folder will work. Whichever folder you pick, re-open it the next time you run this skill so the library accumulates."
   - Once a folder is mounted, set `<runtime_folder> = <mounted folder>/threads-collector/`. Create it if it doesn't exist. All subsequent file paths in this SKILL.md that say `<runtime_folder>/...` resolve relative to this path.

3. Bootstrap `<runtime_folder>` on every invocation (idempotent — only seeds on absence, never overwrites):
   - If `<runtime_folder>/config.md` does not exist: copy the plugin's bundled `config.md` (sibling of this SKILL.md) to `<runtime_folder>/config.md`. Tell the user: "First run detected — I've seeded your config at `<runtime_folder>/config.md`. Open it in your editor, fill in `my_topics` (at minimum), then re-run the skill." Then stop (do not proceed to scrolling on first-seed run).
   - If `<runtime_folder>/library/` does not exist: create it, along with `library/index.csv` (with header row) and `library/posts/`. Seed `library/hook_patterns.md` by copying the plugin's bundled `hook_patterns.md`.

**B. Config value validation — fail loudly on placeholders**

After loading config (Step 1), before doing any scrolling, validate these fields have *real* values, not template placeholders:

- `my_handle` must not be `@your_handle_here`, empty, or missing. If it is: stop with "Your config still has a placeholder for `my_handle`. Edit `<runtime_folder>/config.md` and fill in your actual Threads handle, then re-run."
- `my_topics` must have at least 1 entry that isn't the template default list. If empty or unchanged from the template: warn "Your `my_topics` is empty or still the default template list. Category classification won't be useful until you customize this. Proceed anyway? (y/N)"
- If `surface: search:<query>` is set, `<query>` must be non-empty. Same for `profile:<handle>`.
- If `surface: trending` and `trending_topics_allowlist` is empty, warn: "Trending mode with an empty allowlist will drill into ALL trending topics regardless of your niche. Proceed? (y/N)"

The point: fail loudly on placeholder values instead of silently running a useless pass. Users who just installed the skill and haven't customized anything will see the warning, not a confusing empty library.

**The run:**

### Step 1 — Read the config
Load `<runtime_folder>/config.md`. Parse the sections:
- Surface to scroll
- Max scroll cycles and max posts to collect
- Engagement filters (min likes, min replies, min reposts, min reply_like_ratio)
- Content filters (required keywords, excluded keywords)
- Author filters (skip own handle, skip blocklist, only include allowlist)
- Format filters (single / thread / either, has media / text only / either)
- Hard excludes

If any field is ambiguous or the config file looks malformed, report back to the user before running.

### Step 2 — Open Threads in Chrome
Using the Chrome extension, open https://threads.com in a new tab (or reuse an existing Threads tab if one exists). Wait for content to load. Confirm the correct surface is shown per config:
- For You: the default tab
- Following: click the "Following" tab
- Search: navigate to https://threads.com/search?q=[query from config]
- Profile: navigate to https://threads.com/@[handle from config]
- Trending: see Step 2b below — trending mode is a two-phase flow

If the surface doesn't load within 10 seconds, report the issue and stop.

### Step 2b — Trending mode (only if surface = trending)
Trending is a two-phase surface because Threads shows trending *topics*, not trending posts directly.

**Phase 2b.1 — Discover trending topics:**
1. Navigate to https://threads.com/search (no query string — this is the trending landing page)
2. Wait 2 seconds for the "Trending now" section to render
3. Extract the list of trending topic names and their URLs. Each topic is typically a clickable chip/link. Capture as much as Threads shows — usually 10–15 topics.
4. Write the discovered list to `<runtime_folder>/library/trending-[YYYY-MM-DD-HHMM].json` as an audit trail (topic, url, discovered_at). This is useful later for "what was trending on [date]" queries.

**Phase 2b.2 — Filter the trending topics by user config:**
Apply the config's `trending_topic_filters` rules to pick which trending topics to actually drill into:
- If `trending_topics_allowlist` is non-empty, keep only topics matching any substring in the allowlist (case-insensitive). Example: if allowlist is ["AI", "marketing", "agent"], keep trending topics whose name contains any of those. This is how the user watches only trending topics *relevant to their niche*, not every celebrity-gossip spike.
- If `trending_topics_blocklist` is non-empty, drop topics matching any substring. Good for filtering out "election", "sports", etc.
- Cap the final list at `trending_topics_per_run` topics (default 5). If more than that qualify, pick the topics the user's config hasn't yet drilled into *this week* first (diversity) and fall back to order-of-appearance.

If after filtering, 0 trending topics qualify: log and exit cleanly with a message like "No trending topics matched your allowlist today. Trending list was: [list]. Consider relaxing the allowlist." Don't silently do nothing.

**Phase 2b.3 — Drill into each qualifying topic:**
For each qualifying trending topic:
1. Navigate to its URL (typically https://threads.com/search?q=<topic>&serp_type=trending or similar).
2. Scroll and capture per Steps 3 and 4 of the main flow, BUT:
   - Cap posts per topic at `trending_posts_per_topic` (default 20) instead of `max_posts_to_collect`.
   - Cap scroll cycles per topic at `trending_scroll_cycles_per_topic` (default 8).
   - Tag each captured post with `caught_from_trending_topic="<topic name>"` and `seen_in="trending:<topic name>"`.
3. Move to next topic.

When all qualifying topics have been processed, continue to Step 5 (filter) as usual. The catch rule applies per post regardless of which trending topic it came from.

### Step 3 — Scroll and capture
Scroll the feed progressively. Pattern:
1. Capture all currently visible posts (see Step 4 for what to extract)
2. Scroll down one viewport
3. Wait 1.5 seconds for new content to render
4. Repeat

Stop scrolling when any of these is true:
- Max scroll cycles reached (from config)
- Max posts collected reached (from config)
- No new posts appearing for 3 consecutive scrolls (hit end of fresh content)
- A post appears whose timestamp is older than the "stop when older than" setting in config (e.g. stop when posts are >24h old)

### Step 4 — Extract per post

**First, skip replies.** Threads surfaces reply-posts inline in feeds. Any post whose DOM indicates it's a reply to another user's post is dropped immediately (before any other extraction work). Check for "Replying to @someuser" header or equivalent. Log the skip to `drops-[date].csv` with reason `"reply_post (drop_replies=true)"`.

For each non-reply visible post, extract from the DOM:
- `post_url` — canonical threads.com URL of the hook post (first post if thread)
- `author_handle` — @handle without the @
- `author_display_name` — display name
- `post_text` — the HOOK post's full text. If truncated by "Show more", expand inline then capture. Multi-part thread bodies are handled separately (see "Thread handling" below) and do NOT go into this field.
- `timestamp_relative` — "2h", "1d" etc as shown
- `likes`, `replies`, `reposts` — integers, taken from the hook post's engagement counts (not summed across a thread)
- `is_thread` — true if "Show more from [user]" / "Show thread" indicator present
- `thread_part_count` — integer. If a thread, how many parts Threads reports. If unknowable without navigating away, write the count of parts actually captured here and set `thread_body_captured` accordingly. Null for single posts.
- `thread_body_captured` — enum: `n/a` (single post), `hook_only`, `inline_parts`, `full_expansion`. Tells downstream consumers what's in the post markdown file.
- `has_media` — true if any image/video/carousel attached to the hook post
- `media_types` — list: image / video / carousel / none
- `seen_in` — the surface from config (for_you / following / search:[query] / profile:[handle])
- `captured_at` — current ISO timestamp
- `caught_from_trending_topic` — name of the trending topic (only when surface=trending, otherwise empty)

**Thread handling** — when `is_thread=true`, behavior depends on `capture_thread_body` from config:

- `hook_only` — capture only the hook post's text into `post_text`. Set `thread_body_captured: hook_only`. Do not navigate anywhere. Fastest path.
- `inline_only` (default) — after capturing the hook, click the inline expander if one exists ("Show more from [user]", chevron, etc.). Capture any additional parts that render inline, in order. Do NOT navigate to a separate thread URL. Set `thread_body_captured: inline_parts` and `thread_part_count` to the number captured. If the expander requires full navigation, skip further parts and treat this as `hook_only` for this row.
- `full_expansion` — navigate to the thread's full-view URL. Capture every part in order, return to the feed, resume scrolling from where you left off. Set `thread_body_captured: full_expansion` and `thread_part_count` to the true total.

The hook post's text (and ONLY the hook post's text) is what Step 6 classifies on. Classification runs on the hook because the hook is what decides whether the rest gets read — so `hook_type`, `template_type`, and `why_it_hit` describe the hook, not the full thread. Full parts live in the markdown file for later human reading.

The catch rule in Step 5 applies to the hook post's engagement counts. If the hook clears the threshold, the full thread is caught (not post-by-post).

Deduplicate during capture: check `<runtime_folder>/library/index.csv` for existing `post_url` entries. Skip any URL already in the library.

### Step 5 — Apply catch filters from config
For each captured post, check against the config's filters in order:

1. **Hard excludes** (from config): is this an ad, a repost, a post by own handle, a post by blocklisted author? → drop.
2. **Author filters**: if allowlist is set and author not in it → drop. If author in blocklist → drop.
3. **Format filters**: does post match required format (single/thread/either, with-media/text-only/either)? → drop if mismatch.
4. **Content keyword filters**: if `required_keywords_any` is set, post_text must contain at least one → else drop. If `required_keywords_all` is set, post_text must contain all → else drop. If `excluded_keywords` set and post_text contains any → drop.
5. **Engagement filter**: post must satisfy the catch rule in config. Default is "likes >= min_likes OR reply_like_ratio >= min_reply_like_ratio". Whatever rule the config specifies, apply it.

Posts that pass all filters → "caught." Log drops with reason to `<runtime_folder>/library/drops-[YYYY-MM-DD].csv` for the user's audit (one row per drop, with `post_url`, `reason`).

### Step 6 — Classify caught posts
For each caught post, using the post text alone (no external lookups), assign:

- `category_primary` — match to the topics listed in config's "my_topics" section; if no match, use best-guess label and flag `category_needs_review=true`
- `category_secondary` — optional cross-topic tag
- `template_type` — one of: Listicle, Framework, Personal Story, Before-After-Bridge, Contrarian, Teardown, Confessional, POV Declaration, Question Hook, Joke Opinion, Observation-to-Insight, Tiny-but-Mighty
- `hook_type` — one of: Number, Bold Claim, Narrative, Confessional, Contrarian Flip, Working Question, Observation, Specific Detail, Joke, Direct Promise
- `tone` — one of: earnest, contrarian, playful, analytical, confessional, provocative
- `opens_with` — observation / number / bold claim / question / story / confession / list-item
- `reply_like_ratio` — computed from engagement counts (3 decimals)
- `why_it_hit` — one sentence hypothesis based on the post's content and structure (not engagement numbers alone)

### Step 7 — Validate, then write to library

**Step 7a — Pre-write validation (the malformed-row gate)**

For each caught + classified post, run this validation checklist BEFORE appending to index.csv. Any post failing validation does NOT go to the library — it goes to `<runtime_folder>/library/malformed-[YYYY-MM-DD].csv` instead, so the library stays clean.

Validation rules (all must pass):
- [ ] `author_handle` is non-empty and matches `^[a-zA-Z0-9._]+$` (no spaces, no @ prefix)
- [ ] `post_url` is non-empty, starts with `https://`, and contains `threads.com` or `threads.net`
- [ ] `post_text` is non-empty and at least 5 characters
- [ ] `likes`, `replies`, `reposts` are all integers ≥ 0 (not null, not "K"/"M" strings — these must be parsed to integers at capture time)
- [ ] `captured_at` is a valid ISO timestamp
- [ ] At least one of `category_primary`, `template_type`, `hook_type` is assigned (even if `category_needs_review=true`)
- [ ] `reply_like_ratio` is a number between 0 and 10 (values above 1 are legal — some posts have more replies than likes — but >10 suggests a parsing error)

Rows failing validation: write to malformed-[date].csv with columns `post_url, failing_fields, raw_snapshot, captured_at`. Include a short string describing which check failed (e.g. `"likes=null"`, `"post_url missing https"`).

At the end of the run, if ≥20% of caught posts ended up in malformed-*.csv, flag this prominently in the Step 8 report — it usually means a DOM selector drifted and needs updating.

**Step 7b — Write valid rows**

For each validated post:
- Append a row to `<runtime_folder>/library/index.csv` with all the fields above.
- Write a post markdown file to `<runtime_folder>/library/posts/<author_handle>_<post_id>.md`.

Post markdown file structure:

For a single post (`is_thread=false`):
```markdown
---
url: https://threads.com/@handle/post/ABC123
author: handle
display_name: Display Name
timestamp: 2026-04-18T10:22:00Z
likes: 892
replies: 156
reposts: 41
is_thread: false
---

[hook post text]
```

For a multi-part thread (`is_thread=true`):
```markdown
---
url: https://threads.com/@handle/post/ABC123
author: handle
display_name: Display Name
timestamp: 2026-04-18T10:22:00Z
likes: 892
replies: 156
reposts: 41
is_thread: true
thread_part_count: 4
thread_body_captured: inline_parts
---

## Part 1 (hook — this is what engagement counts describe)
[hook post text]

## Part 2
[part 2 text]

## Part 3
[part 3 text]

## Part 4
[part 4 text]
```

If `thread_body_captured: hook_only`, only Part 1 section is written and a note `_(subsequent parts not captured — set capture_thread_body to inline_only or full_expansion in config to capture them)_` is appended at the bottom.

**Step 7c — Append to hook_patterns.md**

After the CSV write, for the top 3 caught posts (by reply_like_ratio), append a row to `<runtime_folder>/library/hook_patterns.md` under the "Observed in the wild" section:
- Date
- Author handle
- First line (the hook, truncated to ~100 chars)
- Classified hook_type
- Link to the post

This turns hook_patterns.md into a living catalog seeded from the Threads-specific 2026 research (shipped with the skill) and accumulating your actual observations over time.

### Step 8 — Report back to the user
Write a short run summary to the chat:
- Surface scrolled, scroll cycles completed
- If surface = trending: list of trending topics discovered, list of topics actually drilled into, breakdown of caught posts per topic
- Total posts seen
- Posts deduplicated (already in library)
- Posts dropped (by reason, aggregated)
- Posts caught
- Breakdown of caught posts by template_type and tone
- 3 standouts (highest reply_like_ratio, plus any with >10x your `min_likes` threshold)
- Link to the library index CSV
- If surface = trending: link to the trending-*.json audit file

If anything looked unusual (DOM extraction struggled, config ambiguous, Chrome tab didn't load), flag it clearly at the top of the summary.

## Config file template

If the user doesn't have one yet, create `<runtime_folder>/config.md` with this content:

```markdown
# Threads Collector — My Catch Config

## Surface to scroll
# Options: for_you, following, search:<query>, profile:<handle>
surface: for_you

## My handle (posts I authored will always be skipped)
my_handle: [FILL IN — e.g., @yourusername]

## Run limits
max_scroll_cycles: 30
max_posts_to_collect: 50
stop_when_posts_older_than_hours: 48

## Engagement — what counts as "catch-worthy"
# Default rule: catch if likes >= min_likes OR reply_like_ratio >= min_reply_like_ratio
# You can make it stricter (AND) or add more conditions
min_likes: 200
min_replies: 0
min_reposts: 0
min_reply_like_ratio: 0.15
catch_rule: "likes >= min_likes OR reply_like_ratio >= min_reply_like_ratio"

## Content filters (optional — leave empty to skip)
# required_keywords_any: catch only if post contains AT LEAST ONE of these
required_keywords_any: []

# required_keywords_all: catch only if post contains ALL of these
required_keywords_all: []

# excluded_keywords: drop the post if it contains ANY of these
excluded_keywords:
  - "OnlyFans"
  - "promo code"
  - "sponsored"

## Author filters (optional)
# If allowlist is set, catch ONLY from these authors (everyone else dropped)
author_allowlist: []

# Always drop posts from these authors
author_blocklist: []

## Format filters
# Options: single, thread, either
post_format: either

# How much of a multi-post thread to capture
# Options: hook_only, inline_only, full_expansion
capture_thread_body: inline_only

# Options: any, text_only, must_have_media
media_requirement: any

## My topics (used for category classification)
my_topics:
  - brand voice
  - AI in marketing
  - Cowork / Claude agents
  - content strategy
  - remote teams

## Hard excludes (always drop)
drop_ads: true
drop_reposts: true
drop_own_posts: true
drop_replies: true          # reply-type posts skipped entirely
```

## First-run guidance for the user

When running this skill for the first time, do these things in order:

1. Open `config.md` and have the user review/edit it. In particular: their topics. Defaults for engagement thresholds and surface are reasonable but they should know they can tune.
2. Do a dry-run: scroll just 5 cycles, show them what would be captured, don't write to library yet. Confirms the DOM extraction works and the filters feel right before committing data.
3. On confirmation, run the full skill.

## Troubleshooting

**"No posts captured":** either (a) DOM extraction broke because Threads changed their page structure, or (b) filters are too strict. Check `drops-[date].csv` — if it's full, filters are too strict; if it's empty, DOM extraction failed.

**"Chrome tab didn't load":** Chrome extension may not be connected. Tell the user to open Chrome, confirm the Claude-in-Chrome extension is active, and retry.

**"Dedup skipped everything":** the library already has these posts. Either scroll a different surface, or clear library/index.csv if the user wants to re-test.

**"Classification feels off":** the post text alone isn't always enough for confident classification. The `category_needs_review=true` flag surfaces uncertainty. User can re-run classification after adding more topics to config.
