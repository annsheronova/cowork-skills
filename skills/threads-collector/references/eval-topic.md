# Evaluation pass 3 — Topic assignment

Load this file only when executing Step 5c of SKILL.md.

**Input:** every row in the session CSV (now has `hook_pattern_id`, `relevance`, `relevance_reason`).
**Output:** three new columns — `primary_topic`, `secondary_topic` (may be empty), and `new_topic_proposed` (populated when no existing topic fits).

## Process per post

For each row:

1. **Read `topics.md`** — the user's persistent topic list. Semantic match, not substring — "content systems" matches the topic `content strategy`.

2. **Score each topic against the post's subject matter.** Which topic is the post most squarely about? Second-most?

3. **Assign `primary_topic`:**
   - If one existing topic is a clear match → assign its exact label (copy verbatim from `topics.md`).
   - If two topics tie → pick the one more central to the user's `primary_intent`. If still tied, pick the one with fewer total posts in this run (for diversity in the report).
   - If no existing topic fits → set `primary_topic` empty and populate `new_topic_proposed` instead.

4. **Assign `secondary_topic`:**
   - If a second topic is also clearly relevant → assign it.
   - If the post is single-topic, leave `secondary_topic` empty. Don't stretch.
   - Never propose a NEW secondary topic. Only `primary_topic` triggers new-topic proposals.

5. **`new_topic_proposed`:**
   - Short noun phrase, 2–4 words, lowercase. Examples: "founder storytelling", "ai agent demos", "saas pricing psychology".
   - Should describe what the post is actually about — not a paraphrase of one word in the post.
   - Leave empty if `primary_topic` was assigned from the existing list.

## Clustering and promotion at end of pass

After every post is processed:

1. **Cluster `new_topic_proposed` values** across all rows. Merge trivial variations ("founder storytelling" and "founder stories" → one cluster; pick the cluster label with the higher count).

2. **No threshold for topic promotion** — unlike hook patterns, any proposed topic with count ≥1 is eligible for promotion. Topics are cheap; the user wants their topic list to grow.

3. **Hold in memory as `new_topics[]`** — each entry: `{label, post_count, example_post_url}`. The Save gate at end of Step 6 decides whether to append to `topics.md`.

4. **Update the session CSV:**
   - For posts whose proposed topic got promoted → replace `new_topic_proposed` with the promoted label in `primary_topic`, clear `new_topic_proposed`.
   - If the user rejects a specific new topic at the Save gate → leave both columns as-is for audit (the session CSV is scratch anyway).

## Matching guidance

- **Semantic > substring.** "content strategy" topic matches posts about "content systems", "content frameworks", "editorial calendars" — these are the same conceptual territory.
- **Author ≠ topic.** A post about Justin Welsh's morning routine is topic `productivity` or `founder storytelling`, not topic `@justinwelsh`. (Unless the user explicitly added `@justinwelsh` to their topics list as a competitor-watch label — then use it.)
- **"AI" is rarely a good topic alone.** If the user has `AI in marketing` as a topic, a post about AI-generated art is tangential — don't force-fit it. Propose `generative art` or similar instead.
- **Platform-meta posts are their own topic.** Posts about how Threads itself works ("the algorithm rewards X", "Mosseri said Y") belong to a topic like `threads platform` or `creator economy`, not whatever subject-matter topic the user normally cares about.

## Output fields produced by this pass

- `primary_topic` — column populated for every post (either from existing list or from promoted new-topic).
- `secondary_topic` — column populated for multi-topic posts, empty otherwise.
- `new_topic_proposed` — column populated for posts still in staging (no existing fit, not yet promoted).
- `new_topics[]` — run-level list of promoted new topics for the final report.
