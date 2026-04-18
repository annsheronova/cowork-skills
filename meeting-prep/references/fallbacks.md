# Fallbacks when a data source is missing

Not every user has every MCP connected. The skill should degrade gracefully rather than refusing to work.

## Google Calendar not connected

This is the only blocking dependency — without calendar events, there's no meeting to prep for.

1. Call `search_mcp_registry` with `["google calendar", "calendar"]` to find the connector.
2. Call `suggest_connectors` so the user gets a Connect button in the UI.
3. Tell the user: "I need Google Calendar connected to pull your meetings. I've surfaced the connector above — once you connect, say 'prep my meetings' and I'll pick up from here."
4. Stop. Don't try to scrape calendar.google.com via the browser as a first resort; it's slow and fragile, and the native MCP is the right tool for repeated daily use.

## Gmail not connected

Degrade:

- Skip step 2a (email history lookup).
- In each attendee block, write `*Last email:* couldn't check — Gmail not connected.`
- Suggest connecting Gmail at the end of the run, but don't block on it. A prep note without email context is still useful.

## Notion not connected

Degrade:

- Write the prep note as a local markdown file in the outputs folder instead of a Notion page.
- Name it `YYYY-MM-DD-<slug>.md`.
- In the chat reply, link to the local file and mention that connecting Notion would let the notes land there automatically.

## Web search unavailable or returns nothing

For external attendees with no hit:

> **[Name]** — [role from email signature if available, else "role unknown"]. No recent public profile found in a quick search.

Don't invent a bio. Don't say "based on the name, they likely..." — that's worse than an empty field.

## Scheduled-tasks MCP missing

If the user asks to set up the morning run but there's no scheduled-tasks MCP:

- Search the MCP registry for one.
- If none exists, explain that scheduled runs aren't available yet and offer to run the prep each morning manually when they say "morning brief".

## Attendee not in email, not in Notion, not on the web

Just the meeting title and the bare attendee list. That's still useful — the user knows who's joining and can fill in context themselves. Be honest about the gap in the "Attendees" section.
