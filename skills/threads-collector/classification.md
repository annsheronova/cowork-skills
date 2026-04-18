# Classification reference

Load this file only when executing Step 6 of SKILL.md. Contents cover the enum values each caught post must be classified into, the rules for picking values, and how to write `why_it_hit`.

## Principle

Classification runs on the **hook post's text alone**. No external lookups, no profile clicks, no engagement-count-based heuristics in `why_it_hit`. Engagement is the *result*, not the *explanation*.

## Fields to assign (per caught post)

### `category_primary` (required)

Match to one of the topics listed in `my_topics` from config. Use case-insensitive keyword + semantic match — don't require exact string equality.

If no topic in `my_topics` fits: assign a best-guess one-word label AND set `category_needs_review=true`. This flag surfaces uncertainty so the user can review and add topics to config later.

### `category_secondary` (optional)

A second topic tag if the post straddles two `my_topics`. Leave blank if not applicable.

### `template_type` (required) — one of:

| Value | What it looks like |
|-------|---------------------|
| `Listicle` | "7 things", "5 ways", numbered list of items |
| `Framework` | named method, acronym, multi-step process ("The ABC Framework…") |
| `Personal Story` | first-person narrative — "Last year I…" / "When I was 25…" |
| `Before-After-Bridge` | "Was X. Now Y. Here's how I got there." |
| `Contrarian` | opposing the conventional wisdom — "Everyone says X. Wrong." |
| `Teardown` | analyzing a specific piece of content or campaign |
| `Confessional` | admission of failure, ignorance, or vulnerability — "I was wrong about X" |
| `POV Declaration` | stating a strong opinion as fact — "The best X is Y" |
| `Question Hook` | opens with a question that invites a reply |
| `Joke Opinion` | humor-forward, punchline-first |
| `Observation-to-Insight` | notices a pattern, then explains why it matters |
| `Tiny-but-Mighty` | one sentence, maximum impact |

### `hook_type` (required) — one of:

| Value | What it looks like |
|-------|---------------------|
| `Number` | opens with a specific number ("73%", "7 things", "In 3 years") |
| `Bold Claim` | opens with a declarative, provocative statement |
| `Narrative` | opens with a story beat ("I walked into…") |
| `Confessional` | opens with admission — "I used to think X" |
| `Contrarian Flip` | opens by naming the consensus, then rejecting it |
| `Working Question` | opens with a question designed to invite replies |
| `Observation` | opens with a specific thing the author noticed |
| `Specific Detail` | opens with a concrete, unexpected detail ("The CEO wore Crocs") |
| `Joke` | opens with a punchline-first setup |
| `Direct Promise` | opens by stating what the reader will get ("Here's how to…") |

### `tone` (required) — one of:

`earnest`, `contrarian`, `playful`, `analytical`, `confessional`, `provocative`

### `opens_with` (required) — one of:

`observation`, `number`, `bold claim`, `question`, `story`, `confession`, `list-item`

### `reply_like_ratio` (computed, not classified)

`replies / likes`, rounded to 3 decimals. Values >1 are legal (some posts get more replies than likes). Values >10 suggest a parsing error — the validation step in Step 7 catches those.

### `why_it_hit` (required)

One sentence. Base it on the post's **content and structure**, NOT the engagement numbers. The question to answer is: "what about the words in this post made people want to reply?"

Good examples:
- "Flips the default assumption (followers > positioning), triggers reply-debate."
- "Specific credential ('500+ posts') + unresolved promise force the 'more' tap."
- "Humble-starting ('I used to suck at…') invites 'same, here's mine' replies."

Bad examples (avoid):
- "Got a lot of likes." (tautological — we already know)
- "The author is famous." (external factor, not in-text)
- "It went viral." (also tautological)

If you can't confidently write a `why_it_hit` for a post, write "Unclear — hook structure is conventional, performance may be author-driven." — this is an honest flag, not a failure.

## Category match heuristics

When matching post text to `my_topics` for `category_primary`:

1. **Exact substring match** — if any `my_topics` entry appears verbatim in `post_text`, that's the primary. If multiple match, pick the one appearing earliest in the post.
2. **Semantic match** — if no substring hits, pick the topic whose concept is closest to the post's apparent subject. "AI writing tools" and "AI in marketing" both map to "AI in marketing" if that's in `my_topics`.
3. **Fallback** — if neither works, best-guess a one-word label and set `category_needs_review=true`.

Don't over-think category matching. It's a sorting aid, not a judgment. The user can re-categorize in the CSV later.

## When classification feels off

Common causes (for the user to know):

- `my_topics` in config is too abstract. "Marketing" → everything maps to marketing. Fix: tell the user to split into more specific topics in their next `Change topics` quick-confirm.
- The post is off-niche (e.g. a personal-life post from a B2B creator). `category_needs_review=true` is the right behavior here.
- Template/hook types are ambiguous — a post can be both "Contrarian" and "Question Hook". Pick the dominant frame (the first 2 lines usually decide).
