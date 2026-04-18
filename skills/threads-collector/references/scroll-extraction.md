# Scroll + extraction reference

Load this file only when executing Step 4 of SKILL.md.

## The gate is likes only

Scroll-time filtering in v0.4.0 is deliberately minimal. For each visible post:

1. Parse the likes count from the DOM.
2. If `likes >= min_likes` → extract all fields below, append to the session CSV.
3. Otherwise → skip silently. Don't log it. Don't drop-CSV it. We don't care about low-engagement posts, full stop.

Topic relevance, hook pattern, primary/secondary topic assignment — all of that happens in Step 5 on the posts that passed this gate. Never here.

**Hard always-skips** (before the likes check):
- Reply-type posts (DOM header says "Replying to @x") — the skill is for standalone posts and same-author threads only.
- Posts authored by `my_handle` — never catch yourself.
- Ads / sponsored posts — labeled in the DOM.
- Reposts — they're someone else's content showing up in your feed.

These skips are silent. No logging.

## Per-post field extraction

For each post that passed the gate, extract from the DOM:

| Field | Source | Notes |
|-------|--------|-------|
| `post_url` | canonical threads.com URL | the hook post if is_thread |
| `author_handle` | `@handle` | strip the `@` prefix |
| `author_display_name` | display name as rendered | |
| `post_text` | full visible text of the hook post | expand "Show more" inline before capturing |
| `timestamp_relative` | "2h", "1d" etc as shown | keep as-is |
| `likes`, `replies`, `reposts` | engagement counts | **integers** — parse "2.3K"/"2,300"/"1.1M" → int. Hook post only, not summed across thread |
| `is_thread` | boolean | true if "Show more from [user]" / "Show thread" indicator present |
| `thread_part_count` | integer or null | count of parts Threads reports; null for single posts |
| `thread_body` | string or null | if is_thread: all inline-visible parts joined with `\n\n---\n\n`. Null for single posts |
| `has_media` | boolean | true if any image/video/carousel on the hook post |
| `media_types` | list | `image`, `video`, `carousel`, or `none` |
| `seen_in` | string from config | `for_you` / `following` / `search:<query>` / `profile:<handle>` / `trending:<topic>` |
| `captured_at` | ISO timestamp | current run time |
| `caught_from_trending_topic` | string or null | populated only when `surface=trending` |

## Engagement parsing — strict

Raw counts come as strings like "2.3K", "2,300", "1.1M". Parse to integer at capture time:

- `2.3K` → `2300`
- `2,300` → `2300`
- `1.1M` → `1100000`
- empty / null / unparseable → skip the post entirely (don't guess)

If ≥20% of visible posts fail to parse likes, the DOM selector has drifted — flag in Step 6's run stats.

## Thread body capture

Capture inline-visible parts only. No navigation to separate thread URLs (too slow, breaks scroll position).

- If a "Show more from [user]" expander renders inline without navigating away → click it, capture the revealed parts.
- If the expander wants to navigate → skip the expansion, keep the hook text only, set `thread_body=null` and `thread_part_count=null`.

The likes/replies/reposts counts always describe the hook post only. Step 5 evaluations run on `post_text` (the hook), not `thread_body` — because the hook decides whether anyone reads the rest.

## Deduplication — in-memory, session-scoped

Session CSV is scratch. There's no persistent library to dedup against. But within a single run:

- Keep an in-memory set of `post_url` values.
- Before appending, check if `post_url` is already in the set.
- If yes, skip silently.

This catches the common case where the same post renders twice during a single scroll (viewport overlap, Threads re-rendering, etc.).

## Scroll loop

- Capture visible posts before scrolling, not after.
- Wait `scroll_wait_seconds` (default 1.5s) after each scroll.
- Stop conditions (any one triggers stop):
  - Session CSV has `target_collected` rows (default 100)
  - `max_scroll_cycles` reached (default 60)
  - 3 consecutive scrolls with zero new post_urls appearing
  - Any post's relative timestamp exceeds `stop_when_posts_older_than_hours` (default 48)

Report which stop condition fired in Step 6's run stats.
