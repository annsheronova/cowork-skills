# Meeting Prep Skill (v0.1.0)

A Cowork skill that generates a one-page prep note for each of your upcoming meetings. Pulls the event from Google Calendar, looks up recent Gmail history with each attendee, adds a light public-context bio for externals, and writes the result as a Notion page. One page per meeting. Fits on one screen. Designed to be scanned in under a minute.

## What it does

For each meeting on a given day, the skill produces a note with:

- **At a glance** — 2–4 lines of BLUF. If you read nothing else, you're still prepared.
- **Attendees** — per-person block with role, company, last email exchanged, and (for externals) a LinkedIn-style one-liner plus any recent news.
- **Recent context** — 3–6 bullets of open threads, prior decisions, promises made.
- **Likely agenda** — from the calendar description, or inferred and marked `Unverified:`.
- **Talking points** — exactly three. Not ten. The forcing function is the value.
- **Watch-outs** — optional; omitted when nothing real to flag.

## Install

Install the parent plugin from the repo root — see [../../README.md](../../README.md). The skill appears in Cowork once the plugin is installed.

## Prerequisites

- **Google Calendar MCP** connected — required; without it there's no meeting to prep for.
- **Gmail MCP** connected — recommended; email history is a core input.
- **Notion MCP** connected — recommended; prep notes land there. If missing, the skill falls back to writing local markdown files.
- **Web search** available — recommended; used for light attendee research (budget: one paragraph per external person).

If a recommended MCP is missing, the skill degrades gracefully and tells you what's missing.

## Triggers

- "prep for my meeting"
- "get ready for my next call"
- "brief me on today's meetings"
- "who am I meeting with today"
- "research the attendees for my 10am"
- "run my morning briefing"
- "meeting prep note"

## First run

Say one of the trigger phrases. The skill will:

1. Check that Google Calendar is connected.
2. Ask once which Notion parent page to drop prep notes under (remembers your answer; looks for a page titled "Meeting Prep" or "Daily Briefings" first).
3. Pull today's events and filter out solo blocks and short internal syncs.
4. For each remaining meeting: gather Gmail history per attendee, check Notion for existing bios, and do one round of web search per external attendee.
5. Draft the prep note and write it as a new Notion page titled `YYYY-MM-DD — <Meeting Title>`.
6. Reply in chat with a compact linked summary — one line per meeting.

On subsequent runs: just run it. It remembers your parent page.

## Scheduled morning run

After a successful first run, the skill offers to set up a daily 7:30am weekday job so your prep notes are waiting when you start work. If you accept, it uses the `scheduled-tasks` MCP to register the task. You can change or cancel by saying "move my prep to 6:45" or "stop running morning prep".

## Where data lives

Prep notes land in your Notion under the parent page you picked:

```
📄 Meeting Prep (parent, your choice)
  └── 2026-04-20 — Acme × Nutripy — Pilot status check
  └── 2026-04-20 — Q2 partnership review
  └── 2026-04-21 — Intro — Jamie Okafor / Finch Capital
```

Re-running for the same meeting creates a second page rather than overwriting. Prep notes are cheap; keeping earlier versions lets you diff what changed.

If Notion isn't connected, notes fall back to `YYYY-MM-DD-<slug>.md` in your Cowork outputs folder.

## How the writing discipline is enforced

The [SKILL.md](./SKILL.md) gives the model three load-bearing rules:

1. **Bottom Line Up Front.** The "At a glance" section must fully brief the reader on its own.
2. **Three talking points, not ten.** A long list of maybes is worse than three sharp ones.
3. **Context over trivia.** "Last email was Mar 14, Alex said the pilot is behind by two weeks" is worth more than a generic bio.

The output template is in [references/prep-note-template.md](./references/prep-note-template.md). Fallback behavior when inputs are missing is in [references/fallbacks.md](./references/fallbacks.md). Morning-schedule setup is in [references/scheduling.md](./references/scheduling.md).

## Evals

Three fixture-based test cases live in [evals/evals.json](./evals/evals.json), covering:

- External meeting with rich email + web context
- Mixed internal/external attendees (tests that externals get more attention than internals)
- Cold meeting with zero email history (tests graceful handling without fabrication)

Each fixture is under [evals/fixtures/](./evals/fixtures/) and can be run through the skill-creator harness to benchmark changes.

## Sample output — top of a prep note

```markdown
# Acme × Nutripy — Pilot status check
2026-04-20 · 14:00–14:45 CET · Google Meet: meet.google.com/abc-defg-hij

## At a glance
Mid-pilot check-in with Alex Chen (Acme VP Product) and her day-to-day, Priya Ramesh.
Pilot was on track through March; Alex's Apr 14 email flagged a ~2-week slip on the
data-import milestone. She's asked to discuss scope vs. date — and has already said
she prefers a firm date over a shrinking feature list.

## Attendees
- **Alex Chen** — VP Product, Acme Corp. Pilot sponsor; signed the contract Mar 12.
  - *Last email:* 2026-04-14 — flagged 2-week slip; wants to choose narrower v1 or new date.
  - *Context:* ~800 people, Series D; joined Acme from Shopify 2023.
```
