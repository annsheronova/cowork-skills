# Evaluation pass 1 — Hook pattern matching

Load this file only when executing Step 5a of SKILL.md.

**Input:** every row in the session CSV.
**Output:** two new CSV columns per row — `hook_pattern_id` (existing) or `hook_pattern_proposed` (new), plus a run-level `new_hook_patterns[]` summary built at the end.

## Process per post

For each row in the session CSV:

1. **Read `post_text`** — use the hook post's text only, not `thread_body`. The hook is what defines the pattern.

2. **Match against `hook_patterns.md`:**
   - Walk the `## Patterns` table in order.
   - For each row, compare the hook against the pattern's `definition` and `example_hook`. Does this post's structure match the described shape?
   - Match is semantic, not literal. "Me at 17 vs now at 20" matches `h04 Before-Path-After` even if the exact words differ.
   - If the post matches a pattern → set `hook_pattern_id = hNN` and stop checking.

3. **Check anti-patterns:**
   - Walk the `## Anti-patterns` table.
   - If this post matches an anti-pattern → set `hook_pattern_id = aNN`. This is diagnostic: the post still gets reported, but the report flags that it's an underperform pattern. (A viral anti-pattern post is unusual signal — worth surfacing.)

4. **If no match in either table → propose a new pattern:**
   - Write a short name (2–4 words, noun phrase, PascalCase-free) into `hook_pattern_proposed`. Examples: "Milestone announcement", "Q&A reply bait", "Meme-format explainer".
   - Do NOT assign an `hNN` id — proposed patterns stay un-ID'd until promotion at end of run.
   - Leave `hook_pattern_id` empty for this post.

5. **Never guess between two patterns.** If a post plausibly fits h05 List-title and h03 Confession, pick one: whichever the *first line* more clearly signals. If genuinely unclear, propose a new pattern that describes the hybrid.

## Clustering and promotion at end of pass

After every post has been processed:

1. **Cluster `hook_pattern_proposed` values** across all rows. Normalize casing and trivial variations ("Q&A reply bait" and "QA reply bait" → one cluster).

2. **For each proposed pattern with count ≥3:**
   - Mint a new id: the next `hNN` after the last one in `hook_patterns.md`.
   - Draft a row: `id | pattern_name | definition | example_hook | example_post_url`.
     - `definition` — one sentence describing the shape.
     - `example_hook` — the `post_text` first line of the highest-likes post in this cluster.
     - `example_post_url` — that same post's `post_url`.
   - Hold these in memory as `new_hook_patterns[]`. Do NOT write to `hook_patterns.md` yet — the Save gate at end of Step 6 decides whether to append.

3. **For each proposed pattern with count 1–2:**
   - Hold in memory as `hook_candidates[]`. On Save, these get appended to `<runtime_folder>/hook_candidates.md` (staging file). Next run can promote them if they show up again.

4. **Update the session CSV:**
   - For posts whose `hook_pattern_proposed` got promoted → replace with the newly minted `hook_pattern_id`, clear `hook_pattern_proposed`.
   - For posts whose proposed name stayed in staging → leave both columns as-is (`hook_pattern_proposed` populated, `hook_pattern_id` empty).

## What counts as "match" vs "new"

A matched pattern is one where you can point to the defining mechanic in the existing `definition` column. "This is h02 Contrarian flip because the first sentence names a common belief and the second sentence inverts it" — clean match.

A new pattern is one where you'd need to stretch an existing definition to cover this post, OR where no existing pattern describes the mechanic at all. Example: a post structured as `"Drop a '1' below if you want me to share..."` doesn't fit any existing row. Propose "Comment-to-unlock reveal" as a new pattern.

## Report fields produced by this pass

- `hook_pattern_id` column populated for every post that matched or got promoted.
- `hook_pattern_proposed` column populated for staging posts.
- `new_hook_patterns[]` — list of promoted patterns (will appear in the final report's "New hook patterns extracted" section).
- `hook_candidates[]` — list of proposed names appearing 1–2 times.
