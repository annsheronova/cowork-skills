# Output rendering reference

Load this file only when executing Step 6 of SKILL.md.

Covers: session CSV schema, the end-of-run inline report, the Save gate, and how promoted hooks/topics get written back to persistent files.

## Session CSV schema

The session CSV lives at `<runtime_folder>/sessions/session-<timestamp>.csv`. It exists only for this run — no cross-run dedup, no persistent library. Old sessions stay in `sessions/` for reference until the user cleans them up.

Columns (in order):

```
post_url, author_handle, author_display_name, post_text, timestamp_relative, likes, replies, reposts, is_thread, thread_part_count, thread_body, has_media, media_types, seen_in, caught_from_trending_topic, captured_at, hook_pattern_id, hook_pattern_proposed, primary_topic, secondary_topic, new_topic_proposed, relevance, relevance_reason
```

Notes:
- `post_text` is the **full** hook text, not a truncated first-line. The CSV can handle it (Excel/Numbers wrap long cells). Full text is needed because the CSV is the single source of truth — no per-post markdown files in v0.4.0.
- `thread_body` contains subsequent parts joined with `\n\n---\n\n` delimiters, or is empty if `is_thread=false` or body wasn't captured.
- Columns 17–23 are populated by Step 5 evaluation passes, not by Step 4 capture.
- CSV values containing commas/newlines/quotes must be RFC4180-quoted. Use a CSV library, don't hand-roll.

First data write to the session CSV must include the header row. After that, append only.

## End-of-run inline report

Render directly in chat — no "go open the CSV" redirect. Structure in this exact order:

### 1. Headline (one sentence)

```
Collected 100 posts. Evaluated for you. Showing top 10.
```

If collection stopped short of target, be explicit:

```
Collected 73 posts (feed went stale after 60 scrolls). Showing top 10.
```

### 2. Top 10 table

Sort posts by `(relevance DESC, likes DESC)`. Take the top 10. Render as markdown table:

```markdown
| # | Author | Hook | Likes | Replies | Topic | Pattern | Relevance |
|---|--------|------|-------|---------|-------|---------|-----------|
| 1 | @handle | "First 80 chars of post_text…" | 2,847 | 412 | content strategy | List-title open loop | 95 |
```

Rules:
- Truncate `Hook` column to ~80 chars + ellipsis.
- `Pattern` column: use `pattern_name` from `hook_patterns.md` if matched, or `hook_pattern_proposed` + `(new)` suffix if it's a proposed pattern.
- Format counts with thousands commas.
- If `hook_pattern_id` is an anti-pattern (`aNN`), suffix with ` ⚠️` — unusual to see an anti-pattern score high, worth the flag.

### 3. New topics introduced this run

Only render this section if `new_topics[]` is non-empty.

```
**New topics from this run** (will add to your topics list on Save):
• founder storytelling — 7 posts
• ai agent demos — 4 posts
• saas pricing psychology — 2 posts
```

### 4. Top topics across the run

Count posts per `primary_topic` across ALL 100 (not just top 10). Sort descending. Show top 6 max:

```
**Top topics this run:** content strategy (28) · ai in marketing (19) · brand voice (14) · founder storytelling (7) · creator economy (6) · personal branding (5)
```

### 5. New hook patterns extracted

Only render this section if `new_hook_patterns[]` is non-empty (patterns promoted with ≥3 occurrences).

```
**New hook patterns extracted** (will add to playbook on Save):

• **Comment-to-unlock reveal** — Post promises a reveal gated on replies.
  Example: "Drop a '1' below if you want me to share the full framework."
  Seen in 4 posts this run.

• **Milestone announcement** — Lead with a round-number achievement.
  Example: "Just hit 10K followers. Here's what changed."
  Seen in 3 posts this run.
```

Also append a one-liner if `hook_candidates[]` is non-empty (1–2 occurrence proposals that didn't promote):

```
_3 other candidates observed 1–2 times went to hook_candidates.md for next run._
```

### 6. Run stats (one line)

```
Stats: 143 scrolled · 127 passed likes gate · 27 duplicated · 100 captured · stopped on: target reached · runtime 4m 12s
```

If DOM parse failed on ≥20% of visible posts, flag loudly:

```
⚠️  DOM extraction is drifting — 31% of visible posts failed likes parse. Tell me "the selectors need updating" and I'll rescan and fix.
```

### 7. Save gate (AskUserQuestion)

This is the moment where new topics and promoted hooks get written to persistent files — or discarded.

Question: "What should I do with this run's new topics and hook patterns?"

Options:
- `Save everything` — append all `new_topics` to `topics.md`, all `new_hook_patterns` to `hook_patterns.md`, all `hook_candidates` to `hook_candidates.md`. Default choice.
- `Let me pick which topics to save` — render a multi-select of just the new topics for user to check/uncheck, then save only the checked ones. Still save all hook patterns + candidates.
- `Let me pick which hooks to save` — mirror of the above for hooks. Still save all topics.
- `Discard new topics and hooks` — write nothing to persistent files. Session CSV stays.
- `Done` — default to "Save everything" silently. For users who don't want to see this gate every time.

If no `new_topics[]` AND no `new_hook_patterns[]` → skip this gate entirely, go to 8.

### 8. Follow-up actions (AskUserQuestion)

```
What's next?
```

Options (render only applicable ones):
- `Draft 3 posts in my voice from the top hooks` — use brand-voice skills with these hooks as inspiration
- `Show me the full top-100 sorted by engagement` — re-render the CSV as a longer inline table
- `Run again on a different surface` — back to Step 1b "Change surface"
- `Open the session CSV` — prints the file path
- `Done` — end clean

## How promoted items get written back

### topics.md append
- For each item in saved `new_topics[]`: append one line to `topics.md` — just the label, lowercase. Keep existing content intact (never rewrite the file).
- Format exactly as existing lines: no bullets, no prefix, no count annotation.

### hook_patterns.md append
- For each item in saved `new_hook_patterns[]`: append a new row to the `## Patterns` table in `hook_patterns.md`.
- Id is the next `hNN` after the current max in the file.
- Row format: `| hNN | pattern_name | definition | example_hook | example_post_url |`
- Keep the rest of the file untouched. Do not reorganize, do not reflow.

### hook_candidates.md append
- If the file doesn't exist, create it with a header:
  ```markdown
  # Hook Candidates (staging)
  
  Proposed hook patterns observed 1–2 times. Promoted to `hook_patterns.md` if they appear ≥3 times in any single future run.
  
  | First seen | Count | Proposed name | Example hook | Example post_url |
  |------------|-------|---------------|--------------|------------------|
  ```
- Append one row per item in saved `hook_candidates[]`.

## Never

- Never overwrite `topics.md`, `hook_patterns.md`, `user_context.md`, or `config.md`. Append or leave alone.
- Never auto-promote hook candidates from previous sessions. Each run stands on its own for hook promotion.
- Never write a "library" folder or `index.csv` — that's v0.3.0 architecture. Session CSV only.
