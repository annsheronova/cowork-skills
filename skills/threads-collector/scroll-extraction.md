# Scroll + extraction reference

Load this file only when executing Step 4 of SKILL.md. Contents cover what to extract from each visible post, how to handle multi-part threads, and how to dedupe.

## Skip replies first

Threads surfaces reply-posts inline in feeds. Any post whose DOM indicates it's a reply to another user's post is dropped **immediately** (before any other extraction work). Check for a "Replying to @someuser" header or equivalent. Log the skip to `<runtime_folder>/library/drops-[date].csv` with reason `"reply_post (drop_replies=true)"`.

## Per-post field extraction

For each non-reply visible post, extract from the DOM:

| Field | Source | Notes |
|-------|--------|-------|
| `post_url` | canonical threads.com URL | first post of the thread if `is_thread` |
| `author_handle` | `@handle` | strip the `@` prefix |
| `author_display_name` | display name as rendered | |
| `post_text` | the HOOK post's full text | expand "Show more" inline before capturing |
| `timestamp_relative` | "2h", "1d" etc as shown | keep as-is for now; Step 6 parses if needed |
| `likes`, `replies`, `reposts` | engagement counts | **integers** — parse "2.3K"/"2.3k"/"2,300" → `2300`. Hook post only, not summed across thread |
| `is_thread` | boolean | true if "Show more from [user]" / "Show thread" indicator present |
| `thread_part_count` | integer or null | count of parts Threads reports; null for single posts. If unknowable without navigation, write the count actually captured |
| `thread_body_captured` | enum | `n/a` (single), `hook_only`, `inline_parts`, or `full_expansion` |
| `has_media` | boolean | true if any image/video/carousel on the hook post |
| `media_types` | list | `image`, `video`, `carousel`, or `none` |
| `seen_in` | string from config | `for_you` / `following` / `search:<query>` / `profile:<handle>` / `trending:<topic>` |
| `captured_at` | ISO timestamp | current run time |
| `caught_from_trending_topic` | string or null | populated only when `surface=trending` |

## Engagement parsing — be strict

Raw counts come as strings like "2.3K", "2,300", "1.1M". Parse to integer **at capture time**, not later:

- `2.3K` → `2300`
- `2,300` → `2300`
- `1.1M` → `1100000`
- empty / `null` / unparseable → leave as `null`, let Step 7 validation route to malformed-*.csv

Do NOT pass "K"/"M" strings into the library. The validator catches these but cleaner to parse correctly upfront.

## Thread handling

Behavior depends on `capture_thread_body` from config:

- **`hook_only`** — capture only the hook post's text into `post_text`. Set `thread_body_captured: hook_only`. No navigation. Fastest.
- **`inline_only`** (default) — after capturing the hook, click the inline expander if one exists ("Show more from [user]", chevron, etc.). Capture additional parts that render inline, in order. Do NOT navigate to a separate thread URL. Set `thread_body_captured: inline_parts` and `thread_part_count` to the number captured. If the expander requires full navigation, skip further parts and treat as `hook_only` for this row.
- **`full_expansion`** — navigate to the thread's full-view URL. Capture every part in order. Return to the feed and resume scrolling from where you left off. Set `thread_body_captured: full_expansion` and `thread_part_count` to the true total.

**Important:** the hook post's text (and ONLY the hook post's text) is what Step 6 classifies on. Classification describes the hook, not the full thread — because the hook decides whether the rest gets read. Full parts live in the markdown file for later human reading.

**Catch filter applies to the hook's engagement counts.** If the hook clears thresholds, the full thread is caught (not post-by-post).

## Deduplication

Before appending any captured post to the library:

1. Read `<runtime_folder>/library/index.csv` once at the start of Step 4 (lazy-load it into memory — don't re-read per post).
2. Check each post's `post_url` against the in-memory set.
3. If `post_url` is already in the library, skip silently (don't log as a drop — it's not a drop, it's a dedup).

Report total dedup count in Step 8's run stats.

## Scroll loop — performance notes

- Capture visible posts before scrolling, not after. If you scroll first, earlier-visible posts may have left the viewport and DOM references go stale.
- Wait `scroll_wait_seconds` (default 1.5s) after each scroll. Increase if you see lots of "no new posts" false-positives.
- Detect "end of feed" via 3 consecutive scrolls with zero new post_urls appearing. Don't rely on a Threads-served "end of feed" marker — it's inconsistent.
- Don't try to scroll past the `stop_when_posts_older_than_hours` boundary. Once you see a post older than the cutoff, stop scrolling (one old post can show up as an anomaly, so confirm with one more scroll before stopping — if the next viewport is also all-old, stop for real).
