# Threads Collector Skill

A Cowork skill that scrolls Threads (via Chrome) and catches posts matching criteria you define. On-demand — invoke it when you want. No API needed.

## Install

Install the parent plugin from the repo root — see [../../README.md](../../README.md). The skill will show up in Cowork once the plugin is installed. There's nothing to copy by hand.

## First run

Open (or select) a folder in Cowork where you want the skill's config and library to live. A dedicated folder like `~/Documents/threads-research/` works well. Re-open the same folder each time you run the skill — that's how the library accumulates across runs.

On first invocation the skill:

1. Checks the Claude-in-Chrome extension is connected (stops if not).
2. Resolves its runtime folder as `<your folder>/threads-collector/` and creates it.
3. Seeds `<your folder>/threads-collector/config.md` from the plugin's bundled template, and stops with a message asking you to edit it.
4. Seeds `<your folder>/threads-collector/library/hook_patterns.md` from the Q1 2026 research catalog so it's ready for observations to accumulate.

Edit `<your folder>/threads-collector/config.md` — fill in your `my_handle` and your `my_topics`. Everything else has sensible defaults. Re-run the skill.

## Prerequisites

- **Claude-in-Chrome extension** installed and connected. The skill drives Chrome via this extension.
- **You're logged into Threads** in Chrome. The skill won't handle authentication — it assumes you're in.

## How to run

Just say any of these in Cowork:
- "collect threads"
- "swipe threads"
- "catch threads posts"
- "run the threads collector"
- "grab threads posts for me"

The skill will:
1. Run preflight (extension connected, config has real values, folders exist)
2. Load your config
3. Open threads.com in Chrome
4. Scroll the configured surface
5. Capture posts that pass your catch rules
6. Classify each caught post (category, template type, hook type, tone)
7. Validate each row, write valid ones to the library, route malformed rows to an audit file
8. Append top 3 caught posts (by reply_like_ratio) to `hook_patterns.md`
9. Report back: how many caught, how many dropped (and why), standouts worth your attention

## Where the data lives

Inside `<your Cowork folder>/threads-collector/`:

```
threads-collector/
  config.md                         — your catch criteria (you edit)
  library/
    index.csv                       — one row per caught post, with classifications
    hook_patterns.md                — seeded catalog + auto-growing observed patterns
    posts/
      <handle>_<post_id>.md         — full text of each caught post
    drops-YYYY-MM-DD.csv            — audit trail: what was dropped and why
    malformed-YYYY-MM-DD.csv        — audit trail: rows that failed validation
    trending-YYYY-MM-DD-HHMM.json   — trending topics snapshot (only when surface=trending)
```

The `index.csv` is the queryable core. Open in Excel/Numbers/any CSV viewer to filter, sort, and browse.

## Sample output — `index.csv` (3 example rows)

This is what you'll see after a successful run. Columns truncated to the interesting ones here; the full CSV has more metadata.

| post_url | author_handle | first_line | likes | replies | reply_like_ratio | category_primary | template_type | hook_type | is_thread | thread_part_count | why_it_hit |
|----------|---------------|------------|-------|---------|------------------|------------------|---------------|-----------|-----------|-------------------|-------------|
| threads.com/@creatortadeaas/post/DQ7Ez9F | creatortadeaas | "I've posted 500+ times on Threads. Here are 7 types of posts that always go viral" | 2847 | 412 | 0.145 | content strategy | Listicle | List-title open loop | true | 7 | Specific credential + unresolved promise force the 'more' tap |
| threads.com/@hopeengineer/post/DPDjNPx | hopeengineer | "Over the past year, I've gained thousands of followers and left my corporate job. Want to know a secret?" | 1203 | 287 | 0.239 | content strategy | Confessional | Confession-as-authority | false |  | Humble-starting + open loop invites 'drop it' replies |
| threads.com/@digitalalliancehq/post/DVgmjZN | digitalalliancehq | "Most creators think they need more followers. They actually need clear positioning." | 892 | 156 | 0.175 | brand voice | Contrarian | Contrarian flip | false |  | Flips the default assumption, triggers reply-debate |

The `hook_type` column maps to categories in `hook_patterns.md` — so after a month you can run "show me every post classified as 'Contrarian flip'" and get your own in-niche corpus of that pattern. Sort by `reply_like_ratio` to find the highest-conversation posts; sort by `likes` for pure reach winners.

**On multi-part threads:** when `is_thread=true`, the index.csv row captures the hook post's engagement counts and first-line only. The full thread body (all parts, labeled Part 1, Part 2, etc.) lives in the post markdown file at `library/posts/<handle>_<id>.md`. Classification (`hook_type`, `template_type`, `why_it_hit`) describes the hook post, not the full thread — because the hook is what decides whether readers ever see the rest. Configure `capture_thread_body` in config.md to control how much of each thread gets saved: `hook_only` (fastest), `inline_only` (default, captures inline-visible parts), or `full_expansion` (slowest, captures every part).

**On replies:** reply-type posts are dropped by default. The skill is designed for catching standalone posts and same-author threads, not reply chains. This is a hard default (`drop_replies: true`) not a configurable option.

## Tuning after your first few runs

- **Too few catches (<5 per run)?** Your `catch_rule` is too strict. Lower `min_likes` (try 100) or add more to `required_keywords_any`.
- **Too many catches (>30 per run) and the library feels noisy?** Raise `min_likes` to 500, or add specific `required_keywords_any` to narrow the topic.
- **Everything caught is the same creator or topic?** Your For You feed is narrow. Change `surface:` to `search:<topic>` for a run or two to widen.
- **Category classifications feel wrong?** Add more specificity to `my_topics` and re-run. The classifier only knows what you tell it.
- **`malformed-*.csv` getting fat?** See Common Failures #2 below — a DOM selector has probably drifted.

## Common failures and fixes

### 1. "No posts captured" on first run

**Most likely cause:** DOM extraction broke because Threads changed their post-card markup.
**How to confirm:** Check `library/drops-[today].csv`. If it's empty (no posts were even captured-then-dropped), extraction failed before the filter stage. If it's full, the filters are fine — the problem is your catch rule is too strict.
**Fix:** Tell the assistant "the DOM selectors need updating in the threads-collector skill." It can re-inspect the current Threads DOM (via the Chrome extension) and re-tune the extraction logic to match the new markup.

### 2. "Lots of `malformed-*.csv` rows"

**Most likely cause:** One specific DOM selector has drifted — typically the engagement-count nodes (likes/replies/reposts), because Threads changes their formatting ("2.3K" vs "2,300" vs "2.3k") periodically.
**How to confirm:** Open `malformed-[today].csv`. The `failing_fields` column tells you which check failed. If every row fails on `likes=null` or `likes=unparseable`, it's the engagement selector.
**Fix:** Tell the assistant "the engagement count parsing is broken — show me the raw strings from malformed-*.csv and fix the parser." The fix is usually a small regex update, not a full skill rewrite.

### 3. "Chrome tab didn't load" or "stuck on login"

**Most likely cause:** Claude-in-Chrome extension isn't connected, or you're logged out of Threads.
**Fix:** Open Chrome. Confirm the Claude-in-Chrome extension icon is active (not greyed out). Open a new tab to threads.com and confirm you're logged in — the skill won't handle auth. Re-run.

### 4. "Dedup skipped everything"

**Most likely cause:** You already ran the skill on this exact surface recently and the library already has all the visible posts.
**Fix:** Either (a) wait a few hours for fresh posts to appear in your feed, (b) switch `surface:` in config to a different one (try `search:<your topic>` or `trending`), or (c) clear `library/index.csv` if you're re-testing and want to start over.

### 5. "Classification feels off — wrong categories, wrong hook types"

**Most likely cause:** Your `my_topics` in config is too abstract ("marketing") vs specific ("B2B SaaS demand gen for Series A"). The classifier matches against exactly the topic strings you provide — too generic in, too generic out.
**Fix:** Edit `config.md`. Add 3–5 more specific `my_topics`. Re-run. Posts that still don't fit any topic get `category_needs_review=true` — you can bulk-review those later and add topics based on what the collector keeps surfacing.

### 6. "Trending mode returned 'No trending topics matched your allowlist'"

**Most likely cause:** Your `trending_topics_allowlist` is too narrow. Threads' Trending Now surface is global and rarely has niche B2B topics.
**Fix:** Either (a) widen the allowlist (e.g. add "tech", "business", "productivity"), or (b) set allowlist to `[]` to drill into all trending topics and rely on post-level filters to trim. The blocklist still applies.

## What this skill doesn't do (by design)

- **No author follower lookup.** Would require either the Threads API or clicking through to each profile (slow). If you want tier-based filtering later, we can add an optional Phase 2 that clicks through to profiles.
- **No scheduled runs.** Invoke manually. If you later want a daily cron, we can add a `/schedule` wrapper.
- **No publishing.** This skill is read-only. Writing posts is a separate concern (and a different skill).

## About `hook_patterns.md`

The skill ships with a seeded catalog of 15 hook patterns grounded in Q1 2026 Threads research (creator interviews, algorithm breakdowns, Buffer/SociaVault data), plus 6 anti-patterns that underperform specifically on Threads. It lives at `<your Cowork folder>/threads-collector/library/hook_patterns.md`.

Every run, the skill appends the top 3 caught posts (by reply_like_ratio) to the "Observed in the wild" section. Over time this becomes a personal catalog: instead of general "what works on social," you accumulate "what's working *in my niche* on Threads *this month*."

Open and edit it any time. Reclassify patterns, add your own, delete ones that don't apply to your niche. The skill won't overwrite your edits — it only appends.
