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

### [threads-collector](./skills/threads-collector/)

Scrolls Threads (threads.com) via the Claude-in-Chrome extension and catches posts matching user-defined criteria. Produces a structured CSV library plus individual markdown files per caught post, classified by category, template type, and hook type. Ships with a Q1 2026 Threads-specific hook pattern catalog.

**First-run setup:** on first invocation the skill seeds `~/cowork/threads-collector/config.md` with a template. Edit it and fill in `my_topics` before running again. Full docs in [skills/threads-collector/README.md](./skills/threads-collector/README.md).

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
│   ├── plugin.json         ← plugin manifest
│   └── marketplace.json    ← marketplace entry (lets the repo be added as a source)
├── skills/
│   └── threads-collector/  ← first skill (SKILL.md, README.md, config.md, hook_patterns.md)
└── README.md
```

## License

MIT.
