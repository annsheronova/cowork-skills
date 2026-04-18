# cowork-skills

Anna's personal collection of Claude Cowork skills, packaged as a single Claude Code plugin. Each folder under `skills/` is a standalone skill that shows up in your Cowork sidebar after install.

## Install

In Cowork → **Customize** → **Browse plugins** → **Add plugin from URL** (or the equivalent "Add personal plugin" entry point), paste:

```
https://github.com/annsheronova/cowork-skills
```

Alternatively, from the terminal via Claude Code:

```bash
claude plugin marketplace add https://github.com/annsheronova/cowork-skills.git
claude plugin install cowork-skills@cowork-skills
```

Restart Cowork after install. The skills will appear in your sidebar and trigger on the phrases listed below.

## Skills

### [meeting-prep](./skills/meeting-prep/) (v0.1.0)

Generates a one-page prep note for each of your upcoming calendar meetings. Pulls the event from Google Calendar, looks up recent Gmail history per attendee, adds a light public-context bio for external attendees, and writes one Notion page per meeting in a BLUF-first template (At a glance → Attendees → Recent context → Likely agenda → exactly three talking points → optional watch-outs). Fits on one screen. Supports an optional daily 7:30am weekday scheduled run. Full docs in [skills/meeting-prep/README.md](./skills/meeting-prep/README.md).

**Prerequisites:** Google Calendar MCP (required), Gmail + Notion + web search (recommended; degrades gracefully when missing).

**Trigger phrases:** "prep for my meeting", "brief me on today's meetings", "who am I meeting with today", "run my morning briefing", "meeting prep note".

### [threads-collector](./skills/threads-collector/) (v0.4.0)

Scrolls Threads (threads.com) via the Claude-in-Chrome extension. Collects high-engagement posts into a session CSV with a single likes-only gate at scroll time, then evaluates each one in three sequential passes — hook pattern match, relevance score (1–100), primary/secondary topic. Renders the top 10 posts inline, plus any new topics and new hook patterns discovered during the run.

**First-run setup:** no config files to edit. Trigger the skill and it walks you through a 6-question interview (~1 minute) — intent, topics, surface, likes threshold, your handle, and a free-text context prompt for tuning relevance. Your topics list and hook playbook live in `<your folder>/threads-collector/` and grow on each run when you accept the Save gate. Session CSVs are scratch per run. Full docs in [skills/threads-collector/README.md](./skills/threads-collector/README.md).

**Trigger phrases:** "collect threads", "catch threads posts", "run the threads collector".

## Updating

Plugins update through Claude Code's normal plugin update flow:

```bash
claude plugin update cowork-skills@cowork-skills
```

Or via the Cowork UI where you originally installed it.

## Adding a new skill to this repo

Create a new folder at `skills/<skill-name>/` with at minimum:

- `SKILL.md` — YAML frontmatter (`name`, `description`) + instructions body
- `README.md` — usage, prerequisites, troubleshooting
- Any config templates or supporting files the skill needs (e.g. `config.md`, reference data)

Bump the version in `.claude-plugin/plugin.json`, then push. Installed users pick up the new skill on their next plugin update.

## Repo layout

```
cowork-skills/
├── .claude-plugin/
│   ├── plugin.json             ← plugin manifest
│   └── marketplace.json        ← marketplace entry (lets the repo be added as a source)
├── skills/
│   ├── meeting-prep/
│   │   ├── SKILL.md            ← workflow: Calendar → Gmail → web → Notion
│   │   ├── README.md           ← user-facing docs
│   │   ├── references/
│   │   │   ├── prep-note-template.md   ← output structure
│   │   │   ├── scheduling.md           ← morning scheduled-task setup
│   │   │   └── fallbacks.md            ← what to do when an MCP is missing
│   │   └── evals/
│   │       ├── evals.json              ← fixture-based test suite
│   │       └── fixtures/               ← mock Calendar/Gmail/web data per case
│   └── threads-collector/
│       ├── SKILL.md            ← thin orchestrator (steps 0–6)
│       ├── README.md           ← user-facing docs
│       ├── config.md           ← bundled template; copied to runtime on first run
│       ├── topics.md           ← seed topic list (grows per user)
│       ├── user_context.md     ← free-text placeholder
│       ├── hook_patterns.md    ← seeded flat-table hook playbook (grows per user)
│       ├── scroll-extraction.md   ← step 4 reference
│       ├── eval-hook-pattern.md   ← step 5a reference
│       ├── eval-relevance.md      ← step 5b reference
│       ├── eval-topic.md          ← step 5c reference
│       └── output-rendering.md    ← step 6 reference
└── README.md
```

## License

MIT.
