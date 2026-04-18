# Output rendering reference

Load this file only when executing Step 7 (validate + write) or Step 8 (report inline) of SKILL.md. Contents cover validation rules, CSV schema, markdown format for post files, the hook_patterns.md append format, and the inline chat report format.

## Step 7a — Pre-write validation

Every caught + classified post must pass ALL these checks before going into the library. Rows that fail go to `<runtime_folder>/library/malformed-[YYYY-MM-DD].csv` instead — the library stays clean.

Validation rules:

- `author_handle` is non-empty and matches `^[a-zA-Z0-9._]+$` (no spaces, no `@` prefix)
- `post_url` is non-empty, starts with `https://`, contains `threads.com` or `threads.net`
- `post_text` is non-empty and ≥ 5 characters
- `likes`, `replies`, `reposts` are integers ≥ 0 (not null, not "K"/"M" strings — these must have been parsed at capture time per scroll-extraction.md)
- `captured_at` is a valid ISO timestamp
- At least one of `category_primary`, `template_type`, `hook_type` is assigned (even if `category_needs_review=true`)
- `reply_like_ratio` is a number between 0 and 10 (>10 suggests a parsing error)

Malformed rows go to `malformed-[date].csv` with columns: `post_url`, `failing_fields`, `raw_snapshot`, `captured_at`. `failing_fields` is a short string describing which check(s) failed, e.g. `"likes=null"`, `"post_url missing https"`.

**Drift detection:** if ≥20% of caught posts ended up in malformed-*.csv this run, flag it loudly in Step 8 — it usually means a DOM selector drifted.

## Step 7b — CSV schema

Append one row per validated post to `<runtime_folder>/library/index.csv`. Columns (in order):

```
post_url, author_handle, author_display_name, post_text_first_line, likes, replies, reposts, reply_like_ratio, is_thread, thread_part_count, thread_body_captured, has_media, media_types, seen_in, caught_from_trending_topic, captured_at, category_primary, category_secondary, category_needs_review, template_type, hook_type, tone, opens_with, why_it_hit
```

`post_text_first_line` is `post_text` truncated to the first line break or 200 chars, whichever comes first — keeps the CSV scannable in spreadsheet apps. Full body lives in the per-post markdown file.

If `index.csv` doesn't exist yet, create it with this header row first, then append the data row.

## Step 7b — Per-post markdown file

Write each validated post to `<runtime_folder>/library/posts/<author_handle>_<post_id>.md`. `post_id` is the last path segment of `post_url` (e.g. `DQ7Ez9F` from `threads.com/@creatortadeaas/post/DQ7Ez9F`).

**For a single post** (`is_thread=false`):

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

**For a multi-part thread** (`is_thread=true`):

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

If `thread_body_captured: hook_only`, write only Part 1 and append at the bottom:
```
_(subsequent parts not captured — set capture_thread_body to inline_only or full_expansion in config to capture them)_
```

## Step 7c — hook_patterns.md append

After the CSV + markdown writes, take the top 3 caught posts by `reply_like_ratio` (descending) and append them to `<runtime_folder>/library/hook_patterns.md` under the "Observed in the wild" section.

Append format (one table row per post):

```markdown
| YYYY-MM-DD | @handle | "first-line of hook (≤100 chars)" | [hook_type] | [link to post] |
```

If the "Observed in the wild" section doesn't exist yet, create it with a table header, then append rows:

```markdown
## Observed in the wild

| Date | Author | First line | Hook type | Link |
|------|--------|------------|-----------|------|
```

Never overwrite user edits to hook_patterns.md — only append. The user may edit or reorganize the seeded catalog above "Observed in the wild" freely.

## Step 8 — Inline report format

This is the end-of-run summary rendered directly in chat. Goal: the user sees results without opening any file.

### Headline (one sentence)

```
Caught 14 posts from For You. 3 standouts.
```

For trending surface, add per-topic breakdown:

```
Caught 27 posts across 4 trending topics:
• "AI agents" → 12 caught
• "product launch" → 8 caught
• "creator economy" → 5 caught
• "remote work" → 2 caught
```

### Top-3 table

Render as a markdown table. Columns in this exact order:

```markdown
| Author | Hook (first line) | Likes | Replies | Hook type | Why it hit |
|--------|-------------------|-------|---------|-----------|------------|
| @creatortadeaas | "I've posted 500+ times on Threads. Here are 7 types…" | 2,847 | 412 | List-title open loop | Specific credential + unresolved promise force the 'more' tap |
| @hopeengineer | "Over the past year, I've gained thousands of followers and left my corporate job. Want to know a secret?" | 1,203 | 287 | Confession-as-authority | Humble-starting + open loop invites 'drop it' replies |
| @digitalalliancehq | "Most creators think they need more followers. They actually need clear positioning." | 892 | 156 | Contrarian Flip | Flips the default assumption, triggers reply-debate |
```

Rules:
- Truncate "Hook" column to ~80 chars with an ellipsis if longer.
- Format likes/replies with thousands commas.
- Keep the table narrow enough to render nicely on a laptop screen — 6 columns max.

### Category breakdown (one line)

```
Categories: 6 content strategy · 4 AI in marketing · 3 brand voice · 1 unclassified
```

### Run stats (one line)

```
Stats: 87 seen · 12 deduped · 61 dropped (38 low-likes · 15 excluded keyword · 8 replies) · 14 caught · 0 malformed
```

If malformed ≥20% of caught:

```
⚠️  DOM extraction is drifting — 5 of 14 caught posts failed validation. Tell me "the selectors need updating" and I'll rescan and fix.
```

### Follow-up actions

Use `AskUserQuestion` with these options (render only the ones that apply):

- `Draft 3 post ideas from these hooks` — always
- `Run again on a different surface` — always
- `Show me all catches as a table` — only if caught > 3
- `Show me what got dropped and why` — only if drops > 0
- `Done` — always

### FYI footer (one line, at the bottom)

```
Full library: <runtime_folder>/library/index.csv — open it in any CSV viewer to query/filter.
```

This is a footnote, not a call-to-action. Most users won't open it. That's fine.
