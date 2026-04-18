# Scheduling the morning run

The user wants prep notes ready before they start their day. Set this up as a daily scheduled task.

## Default configuration

- **Time:** 7:30 AM, user's local timezone. Early enough that notes are ready before 9am meetings; late enough that morning calendar changes are captured.
- **Prompt:** `"Run meeting-prep for today's calendar events."`
- **Frequency:** Daily, Monday–Friday. Offer weekends only if the user explicitly asks.

## Creating the task

Use the scheduled-tasks MCP. The tool is typically named `create_scheduled_task`. A sensible payload:

```
{
  "name": "Daily meeting prep",
  "schedule": "0 30 7 * * MON-FRI",   // cron-style, 7:30 Mon–Fri
  "prompt": "Run meeting-prep for today's calendar events. Write one Notion page per meeting under the usual parent page."
}
```

If the MCP expects natural language instead of cron, use `"Every weekday at 7:30am"`.

## Offering the option

Don't auto-enable the scheduled run on first use. The first time the skill runs successfully, ask the user once:

> "Want me to run this every weekday morning at 7:30 so prep notes are waiting for you?"

If they say yes, set up the task and confirm. If they say no, don't ask again — they'll tell you when they want it.

## Changing the schedule

If the user asks to change the time ("move it to 6:45", "skip Fridays"), use `list_scheduled_tasks` to find the existing task, then `update_scheduled_task` rather than creating a duplicate.

## What the scheduled job does differently

Nothing special — it runs the same workflow. The only difference is the scheduled context has no user in the loop, so:

- If an error happens (Gmail quota, Notion auth expired), note it in the final Notion page and move on rather than asking clarifying questions.
- If there are no meetings for the day, write a tiny Notion page that just says "No meetings today" so the user knows the job ran.
