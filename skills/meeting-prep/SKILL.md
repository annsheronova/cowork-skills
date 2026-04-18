---
name: meeting-prep
description: |
  Generate a one-page prep note for an upcoming meeting by pulling the event
  from Google Calendar, finding prior email history with each attendee,
  adding a light public-context bio per external attendee, and writing the
  result as a Notion page. Use this skill whenever the user asks to
  "prep for my meeting", "get ready for my next call", "brief me on today's
  meetings", "who am I meeting with today", "research the attendees for my
  10am", "run my morning briefing", "meeting prep note", "prep notes for
  tomorrow's calls", or any variation on pre-meeting research — even if the
  user doesn't use the exact word "prep". Also triggers on the morning
  scheduled job the user set up with this skill.
---

# Meeting prep

Generate a short, decision-ready prep note for an upcoming meeting. One note per meeting, written to Notion, structured so the user can skim it in under a minute.

## What a good prep note looks like

A prep note is a briefing, not a research report. It respects the reader's time. Aim for the feel of a chief-of-staff handing their exec an index card before the meeting walks in.

Three rules carry most of the value:

1. **Bottom Line Up Front.** The first section — "At a glance" — must tell the user what the meeting is, who's in it, and what matters, in a few lines. If they read only that section and nothing else, they're still 80% prepared.
2. **Three talking points, not ten.** Pick the highest-leverage things to raise or be ready for. A long list of maybes is worse than three sharp ones.
3. **Context over trivia.** "Last email was Mar 14, Alex said the pilot is behind by two weeks" is worth more than a Wikipedia-style bio.

Everything else below serves these three.

## Inputs the skill expects

- A date (defaults to today in the user's local timezone).
- Optionally a specific meeting title, time, or attendee if the user is asking about one particular event.
- Optional "focus" hint from the user (e.g. "I care most about the commercial angle").

## Workflow

Do the steps in order. Skip a step cleanly if its data source isn't available — note the gap in the output rather than inventing content.

### 1. Get the meeting(s) from Google Calendar

Look for a Google Calendar tool in the available MCPs (tool names typically contain `calendar` — e.g. `list_events`, `get_event`). Query for events on the target date. For each event, capture:

- Title, start/end time, location or video link
- Organizer
- Attendee list (emails + display names) — separate internal vs. external by comparing email domain to the user's own domain
- Description and any attached agenda

**If no Google Calendar MCP is connected:** stop and tell the user. Suggest connecting one with the MCP registry (`search_mcp_registry` → `suggest_connectors` with the Google Calendar UUID). Don't try to screen-scrape Calendar in the browser as a first resort — it's slow and fragile; the native MCP is the right tool.

Filter out events that don't need prep: solo blocks ("focus time", "lunch", "heads-down"), canceled events, and meetings with zero external attendees AND fewer than 3 internal attendees (1:1 internal syncs typically don't need a formal brief, but tell the user you skipped them so they can override).

### 2. For each remaining meeting, gather context

Run these in parallel where you can:

**a. Gmail history with each attendee.** Use the Gmail MCP (tool names typically contain `search_threads`). For each non-user attendee, search the last ~90 days of email with that person (`from:<email> OR to:<email>` with a date filter). Pull the 3 most recent threads. Read subject lines first; open the thread only if the subject doesn't make the content obvious. Capture:

- Most recent exchange (date + one-line summary of what it was about)
- Any open commitments ("I'll send you the deck Thursday")
- Any unresolved questions the user asked or was asked

**b. Prior prep notes / internal context.** Check Notion for existing pages about this attendee or company. Search by the attendee's name and by their company domain. If you find an older prep note for the same company, link to it and reuse the bio — don't re-research from scratch.

**c. Light public research (external attendees only).** For each external attendee where you don't already have context in Notion or Gmail, do ONE round of web search. Budget: one paragraph per person. Look for:

- Current role and company (a LinkedIn-style one-liner — no need to visit LinkedIn itself)
- Company one-liner: what the company does, size/stage if easy to find
- One recent news item or signal from the last ~90 days if it exists (funding round, launch, leadership change, notable post). If nothing recent surfaces in a single search, leave it out rather than padding.

Do not deep-dive. The goal is a paragraph. If the person is senior or the meeting is high-stakes and the user wants more, they can ask.

**d. Agenda inference.** If the calendar description is empty or vague, infer the likely agenda from the meeting title, attendee makeup, and email history. Flag it clearly as inferred.

### 3. Draft the prep note

Use the structure in `references/prep-note-template.md`. Keep it to roughly one screen. Mark anything uncertain so the user knows what to verify.

### 4. Write it to Notion

Use the Notion MCP to create the page. Where to put it:

- If the user has previously told the skill which Notion parent page to use, reuse that parent.
- Otherwise, search Notion for a page titled "Meeting Prep" or "Daily Briefings" and create underneath it.
- Otherwise, ask the user once which parent page to use and remember their answer for next time (write the answer to `~/.meeting-prep-config.json` or an equivalent small state file).

Page title format: `YYYY-MM-DD — <Meeting Title>` (so notes sort chronologically).

### 5. Report back

In the chat, reply with a compact summary: a linked list of the Notion pages you created, one line per meeting describing who it's with and the "At a glance" headline. Don't repeat the full prep note content in chat — the Notion page is the deliverable.

## Scheduled morning run

If the user asks to "run this every morning" or similar, use the scheduled-tasks MCP (`create_scheduled_task`) to register a daily job. Recommended defaults: 7:30am local time, prompt = "Run meeting-prep for today". See `references/scheduling.md` for the specifics.

## Failure modes — how to handle them gracefully

- **No meetings today.** Say so and stop. Don't fabricate a quiet-day briefing.
- **Gmail MCP missing.** Note the gap in the prep note ("couldn't check email history — Gmail MCP not connected") and continue with what you have.
- **Web search blocked / returns nothing useful for a person.** Write the bio as "[Name], [role at company if in email signature] — no public profile found in a quick search." Don't guess.
- **Attendee is ambiguous** (common name, no useful email signature). Say so rather than researching the wrong person.

## Tone and style of the note itself

Write like you're briefing a friend who is smart and busy. Full sentences where they earn their place; bullets where they read faster. Don't hedge ("it seems that perhaps") and don't pad ("it's worth noting that"). If something is uncertain, say `Unverified:` inline — one word, done.

## References

- `references/prep-note-template.md` — the exact section structure for the Notion page
- `references/scheduling.md` — how to set up the morning scheduled run
- `references/fallbacks.md` — what to do when individual tools are missing or return nothing
