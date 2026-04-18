# cowork-skills

A personal collection of Claude Cowork skills. Each subdirectory is a standalone skill with its own `SKILL.md`, config, and documentation.

## Install (one command)

Run this in your Mac's Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/annsheronova/cowork-skills/main/install.sh | bash
```

This clones the repo into `~/.claude/skills/cowork-skills/`, symlinks each skill so Cowork discovers it, and seeds runtime config files under `~/cowork/<skill-name>/`. Safe to re-run any time — it pulls updates and never clobbers your edited configs.

After install, open the per-skill README below and finish any config steps that skill needs, then start a fresh Cowork session.

## Skills in this repo

### [threads-collector](./threads-collector/)

Scrolls Threads (threads.com) via the Claude-in-Chrome extension and catches posts that match user-defined criteria. Produces a structured CSV library plus individual markdown files per post, with automatic classification by category, template type, and hook type. Ships with a Q1 2026 Threads-specific hook pattern catalog that grows with each run.

**After install**, edit `~/cowork/threads-collector/config.md` and fill in `my_topics`. See [threads-collector/README.md](./threads-collector/README.md) for prerequisites and usage.

## Manual install (if you'd rather not pipe curl to bash)

```bash
mkdir -p ~/.claude/skills
cd ~/.claude/skills
git clone https://github.com/annsheronova/cowork-skills.git
bash cowork-skills/install.sh
```

The `install.sh` script is idempotent — you can read it first at [install.sh](./install.sh), then run it.

## Adding a new skill

Create a new top-level folder. Minimum contents:

- `SKILL.md` — the skill definition with YAML frontmatter (`name`, `description`) and the full instructions body.
- `README.md` — install instructions, prerequisites, troubleshooting.
- Any config templates, reference data, or supporting files the skill needs.

## License

Personal use. No warranty, no support commitments.
