# Evaluation pass 2 — Relevance scoring

Load this file only when executing Step 5b of SKILL.md.

**Input:** every row in the session CSV (with `hook_pattern_id` / `hook_pattern_proposed` already filled by pass 1).
**Output:** two new columns — `relevance` (integer 1–100) and `relevance_reason` (one short sentence).

## What "relevant" means here

Relevance is "how useful is this post to Anna, given what Anna cares about and what Anna is trying to do." Not "is this a good post." A viral post about crypto scoring 30 is correct — it's viral, but not relevant to a marketing-focused audience.

## Inputs to the score

Before scoring any row, load:

1. **`topics.md`** — the user's topic list. Semantic interpretation: if a post is clearly *about* one of these topics, it scores higher.
2. **`user_context.md`** — free-text from setup Q6. Whatever the user said goes here. Might be "I'm a B2B SaaS marketer focused on brand voice" or "I'm building a content-creation tool for solo operators." Treat this as the primary signal.
3. **`config.md`** — `primary_intent` field (from Q1): content ideas / competitor watch / trend spotting / hook library. Different intents bias what counts as relevant.

## Scoring scale (1–100)

Calibrate roughly like this. Don't be stingy with the top or bottom — the distribution should span the full range.

| Range | Label | When |
|-------|-------|------|
| 90–100 | Exactly what I want | Post is squarely on one of the user's topics AND matches their intent. They would bookmark this post. |
| 70–89 | Very relevant | Adjacent to user's topics or demonstrates a technique directly applicable to their work. |
| 50–69 | Relevant | In the general neighborhood. Useful for pattern-spotting even if not directly actionable. |
| 30–49 | Tangential | Loosely connected. Good hook or interesting shape, but subject matter isn't the user's world. |
| 10–29 | Off-topic but noteworthy | Not relevant, but unusual in some way (unexpected virality, hook pattern worth noting). |
| 1–9 | Noise | Not relevant to anything the user cares about. Pure platform churn. |

## Scoring rubric (weights)

Combine these signals in the score. This is qualitative — no formula. Use judgment.

- **Topic match (~40%)** — does the post's subject matter overlap with `topics.md` or `user_context.md`?
- **Intent match (~30%)** — for `hook library` intent, novel hook shape matters more than subject; for `competitor watch`, author identity matters more; for `trend spotting`, velocity/recency matters more; for `content ideas`, subject + quality both matter.
- **Actionability (~20%)** — could the user do something concrete with this post? Write their own version? Study the hook? Reply to the thread? Higher = more relevant.
- **Anti-pattern penalty (~10%)** — if the post matched an `aNN` anti-pattern in pass 1, drop the score by 10–20 unless it's viral *because* it's an anti-pattern (rare but interesting — note in `relevance_reason`).

## Output format

For each row, write:

- `relevance` — integer 1–100. No decimals, no ranges.
- `relevance_reason` — one sentence, under 120 chars, explaining the score. Example: "Direct match on brand voice topic + actionable hook template." or "Viral but off-topic (crypto); noting the hook shape only."

## Never

- Never score from engagement counts alone. A post with 10K likes about dog training scores low if the user doesn't care about dog training.
- Never score the whole thread body. Score the hook text — the same hook that pass 1 matched against.
- Never assign ranges ("70–80"). Single integer.
- Never explain the rubric in `relevance_reason`. The reason explains *this* post's score, not the scoring system.

## Edge cases

- **Empty `user_context.md`** → rely on `topics.md` and `primary_intent` alone. Score a bit more conservatively (skew toward 40–70 band) because you have less signal.
- **Post author is in `my_topics` as a name** (e.g. user tracks `@justinwelsh` as a topic) → bump score by +10 if the match is exact.
- **Post matches the user's own hook style** (observable from past caught posts in previous sessions, if any) → no bump; this skill doesn't track that. Neutral score.
