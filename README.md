# cowork-skills

Anna's personal collection of Claude Cowork skills. Each folder under `skills/` is a standalone skill that installs into `~/.claude/skills/` and shows up in your Cowork sidebar.

## Install

Paste this into Terminal on your Mac:

```bash
curl -fsSL https://raw.githubusercontent.com/annsheronova/cowork-skills/main/install.sh | bash
```

That clones the repo to `~/Dev/cowork-skills/`, symlinks every skill into `~/.claude/skills/`, and seeds editable runtime config under `~/cowork/<skill-name>/`. Safe to re-run any time — it pulls updates and never clobbers your edited configs.

After install, restart Cowork. Then follow the setup steps in the skill's own README (below).

## Skills

### [threads-collector](./skills/threads-collector/)

Scrolls Threads (threads.com) via the Claude-in-Chrome extension and catches posts matching user-defined criteria. Produces a structured CSV library plus individual markdown files per caught post, classified by category, template type, and hook type. Ships with a Q1 2026 Threads-specific hook pattern catalog.

**First-run setup:** edit `~/cowork/threads-collector/config.md` and fill in `my_topics`. Full docs in [skills/threads-collector/README.md](./skills/threads-collector/README.md).

**Trigger phrases:** "collect threads", "catch threads posts", "run the threads collector".

## Manual install (if you don't want to pipe curl to bash)

```bash
git clone https://github.com/annsheronova/cowork-skills.git ~/Dev/cowork-skills
bash ~/Dev/cowork-skills/install.sh
```

You can read [install.sh](./install.sh) first — it's short.

## Updating

```bash
cd ~/Dev/cowork-skills
git pull
# Optional — only needed if the repo adds new skills:
bash install.sh
```

## Adding a new skill to this repo

Create a new folder at `skills/<skill-name>/` with at minimum:

- `SKILL.md` — YAML frontmatter (`name`, `description`) + instructions body
- `README.md` — usage, prerequisites, troubleshooting
- Any config templates or supporting files the skill needs (e.g. `config.md`, reference data)

Push. Anyone who has already run the installer picks up the new skill on their next `git pull` + `bash install.sh` (or just re-runs the one-liner).

## License

MIT.
