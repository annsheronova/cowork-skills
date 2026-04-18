# Hook Patterns — Flat Reference

A lookup table of hook shapes observed on Threads. Seeded with 15 patterns grounded in Q1 2026 Threads research, plus 6 anti-patterns that underperform specifically on Threads.

The `eval-hook-pattern.md` step matches each caught post against this table. If a match: the post gets that pattern's `id`. If no match: the step proposes a new pattern name. Proposed patterns that appear ≥3 times in a single run get promoted to this table (new `hNN` row). Proposed patterns appearing 1–2 times go to `hook_candidates.md` staging.

Never overwrite rows — only append. The user may edit definitions freely.

---

## Patterns

| id | pattern_name | definition | example_hook | example_post_url |
|----|--------------|------------|--------------|------------------|
| h01 | Specific-number flex | Open with an oddly specific number tied to a personal result. | "2 years ago I jumped on Threads with 52 Followers. Today I have 58,000+ Thriends." | threads.com/@heythemnaji |
| h02 | Contrarian flip | State a common belief, flip it, promise the why. | "Most creators think they need more followers. They actually need clear positioning." | threads.com/@digitalalliancehq |
| h03 | Confession-as-authority | Lead with a vulnerable admission that re-frames as credibility. | "Over the past year, I've gained thousands of followers and left my corporate job for good. Want to know a secret?" | threads.com/@hopeengineer |
| h04 | Before-Path-After | Three-beat identity shift: past self, transition implied, present self. | "Me at 17: Alcohol, Partying, Video games. Now me at 20: Gym, Studying, Building my business." | threads.com/@creatortadeaas |
| h05 | List-title open loop | Announce a numbered list you haven't delivered yet — force the "more" tap. | "I've posted 500+ times on Threads. Here are 7 types of posts that always go viral:" | threads.com/@creatortadeaas |
| h06 | Industry-drama piggyback | Quote a real, fresh platform or industry stat as the entire hook. | "Threads just overtook X!! It now has 130.2 million daily users. X has only 130.1 million." | threads.com/@mattnavarra |
| h07 | Pattern-interrupt imperative | Command to stop doing the obvious thing, then redirect. | "Stop posting motivational quotes. Here is what actually grows your account." | — |
| h08 | Secret-reveal | Claim a hidden mechanism, promise to share. | "The one thing I changed in my bio that tripled my profile visits" | — |
| h09 | Question-as-post | A post that IS the question. No setup, no context. | "What's the career advice you wish you got at 22?" | — |
| h10 | Hot-take declaration | Label the take explicitly as unpopular before stating it. | "Unpopular opinion: most Threads advice is wrong. Here is what the data actually shows." | — |
| h11 | Fill-in-the-blank | Sentence with a literal underscore gap for readers to complete. | "The hardest part of my job is _______." | — |
| h12 | Plain-language contradiction | Two short sentences where the second contradicts the first. | "Ego says: 'Don't be too vulnerable.' Wisdom says: 'Authenticity builds real connection.'" | threads.com/@wholistic.scott |
| h13 | Single-image + one-liner | One strong image plus one declarative line of text. No paragraph. | "[image]. The only thing that compounds faster than money is skill." | — |
| h14 | Authority-citation | Open with a verbatim quote from a known platform authority. | "Adam Mosseri: 'If you're really trying to grow, reply much more than you post.'" | threads.com/@mosseri |
| h15 | Receipts-first | Lead with proof (stat, screenshot, credential) BEFORE any claim. | "$47K in 6 months from a Threads account I started on a train." | — |

---

## Anti-patterns (do not match to these; flag if observed)

| id | pattern_name | definition | why_it_fails |
|----|--------------|------------|--------------|
| a01 | Generic engagement bait | "Comment your age and I'll guess your job" / "This or that" prompts with no personal stake. | Mosseri named this as the target of 2024–2026 enforcement. Short-term replies, long-term account down-ranking. |
| a02 | Twitter-style mega-threads | Numbered multi-post chains imported from X muscle-memory (1/12, 2/12…). | Threads' 100–280 char sweet spot punishes long chains. Single strong posts beat multi-part threads on engagement velocity. |
| a03 | Naked link posts | Post body is just a link or a link + one sentence. | Links pull users off-platform, killing reply velocity — which is what the algorithm ranks on. |
| a04 | Over-polished brand broadcast | Corporate press-release cadence; "we're excited to announce." | Near-zero reply velocity. Monologue voice signals "don't reply." |
| a05 | Motivational-quote hooks | "You got this." "Discipline > motivation." | No open loop, no debate, nothing to reply to. Reads as filler. |
| a06 | Authenticity theater | Formulaic vulnerable confession ("I cried today because…") with no specific stakes. | Formulaic versions burn out per Mosseri's Jan 2026 "authenticity is infinitely reproducible" observation. Genuine specificity (h03) still works. |

---

## Notes

- Seeded Q1 2026. Sources: Buffer 2026 Threads data, SociaVault, Metricool algorithm breakdown, Miraflow, Post Everywhere, Marketing Agent 2026 playbook, Mosseri public statements.
- Example hooks from named creator accounts are verbatim first lines. Composite examples (no URL) are template-grade.
- To retire a pattern, prepend `[retired]` to its `pattern_name` — the matcher will skip those during evaluation.
