# cowork-skills

A Claude Cowork plugin — Anna's personal collection of skills. Installs into Cowork as a single plugin; new skills join this plugin over time.

## Install

In Claude Cowork: **Customize → Plugins → Add plugin → GitHub**, and paste:

```
https://github.com/annsheronova/cowork-skills
```

Cowork clones, validates, and installs the plugin. All skills below become available in your sidebar automatically. Start a fresh Cowork session after install.

> For private repo installs, make sure the GitHub account connected to your Cowork is granted read access to the repo.

## Skills included

### threads-collector

Scrolls Threads (threads.com) via the Claude-in-Chrome extension and catches posts matching user-defined criteria. Produces a structured CSV library plus individual markdown files per caught post, classified by category, template type, and hook type. Ships with a Q1 2026 Threads-specific hook pattern catalog that grows with each run.

**First run:** the skill bootstraps your editable config at `~/cowork/threads-collector/config.md` from the packaged template. Fill in `my_topics` before doing a real run. See [skills/threads-collector/README.md](./skills/threads-collector/README.md) for full usage.

**Triggers:** say "collect threads", "catch threads posts", "run the threads collector".

## Repository layout

```
cowork-skills/
├── .claude-plugin/
│   └── plugin.json       Plugin manifest
├── skills/
│   └── threads-collector/
│       ├── SKILL.md      Skill definition
│       ├── config.md     Runtime config template
│       ├── hook_patterns.md   Seeded Q1 2026 catalog
│       └── README.md     Per-skill docs
└── README.md             This file
```

## Adding a new skill

Create a new folder at `skills/<skill-name>/` with at minimum:
- `SKILL.md` — YAML frontmatter (`name`, `description`) + instructions body
- `README.md` — usage, prerequisites, troubleshooting
- Any config templates or supporting files the skill needs

Bump `version` in `.claude-plugin/plugin.json`, push, and Cowork users get the new skill on next plugin update.

## License

MIT.
