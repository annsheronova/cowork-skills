# cowork-skills

A personal collection of Claude Cowork skills. Each subdirectory is a standalone skill with its own `SKILL.md`, config, and documentation.

## Skills in this repo

### [threads-collector](./threads-collector/)

Scrolls Threads (threads.com) via the Claude-in-Chrome extension and catches posts that match user-defined criteria. Produces a structured CSV library plus individual markdown files per post, with automatic classification by category, template type, and hook type. Ships with a Q1 2026 Threads-specific hook pattern catalog that grows with each run.

## How to install a skill from this repo

Each skill is designed to be dropped into Cowork's skills directory and used on-demand. General pattern:

1. Clone or download this repo.
2. Copy the skill folder (e.g. `threads-collector/`) into your Cowork skills directory. On macOS the default is `~/.claude/skills/`.
3. Follow the per-skill README for any extra setup (config files, prerequisites, etc.).

## Adding a new skill

Create a new top-level folder. Minimum contents:

- `SKILL.md` — the skill definition with YAML frontmatter (`name`, `description`) and the full instructions body.
- `README.md` — install instructions, prerequisites, troubleshooting.
- Any config templates, reference data, or supporting files the skill needs.

## License

Personal use. No warranty, no support commitments.
