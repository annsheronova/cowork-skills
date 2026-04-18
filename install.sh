#!/bin/bash
# Install all skills in this repo into Cowork's skills directory (~/.claude/skills/).
#
# Idempotent: safe to re-run to pick up updates. Never overwrites your edited config files.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/annsheronova/cowork-skills/main/install.sh | bash
#
# Or, if you've already cloned the repo:
#   bash install.sh

set -e

REPO_URL="https://github.com/annsheronova/cowork-skills.git"
CLONE_DIR="$HOME/Dev/cowork-skills"
SKILLS_DIR="$HOME/.claude/skills"
COWORK_DIR="$HOME/cowork"

echo "▸ cowork-skills installer"

# 1. Clone or update
mkdir -p "$(dirname "$CLONE_DIR")"
if [ -d "$CLONE_DIR/.git" ]; then
    echo "  Pulling latest changes in $CLONE_DIR..."
    git -C "$CLONE_DIR" pull --ff-only
else
    echo "  Cloning $REPO_URL into $CLONE_DIR..."
    git clone "$REPO_URL" "$CLONE_DIR"
fi

# 2. Symlink each skill under skills/ into ~/.claude/skills/
mkdir -p "$SKILLS_DIR"
for skill_path in "$CLONE_DIR"/skills/*/; do
    [ -d "$skill_path" ] || continue
    skill_name="$(basename "$skill_path")"
    link="$SKILLS_DIR/$skill_name"

    if [ -L "$link" ]; then
        rm "$link"
    elif [ -e "$link" ]; then
        echo "  ! $link exists and is not a symlink — skipping. Move or rename it, then re-run." >&2
        continue
    fi

    ln -s "$skill_path" "$link"
    # Trim trailing slash for display
    echo "  Linked $skill_name  →  $(echo "$skill_path" | sed 's:/*$::')"

    # 3. Seed runtime folder for this skill (only on first install; never overwrites)
    runtime_dir="$COWORK_DIR/$skill_name"
    mkdir -p "$runtime_dir/library"

    if [ -f "$skill_path/config.md" ] && [ ! -f "$runtime_dir/config.md" ]; then
        cp "$skill_path/config.md" "$runtime_dir/config.md"
        echo "    Seeded $runtime_dir/config.md (edit before first run)"
    fi

    if [ -f "$skill_path/hook_patterns.md" ] && [ ! -f "$runtime_dir/library/hook_patterns.md" ]; then
        cp "$skill_path/hook_patterns.md" "$runtime_dir/library/hook_patterns.md"
    fi
done

echo ""
echo "Done. Restart Cowork (or open a new session) to load the skills."
echo ""
echo "Next steps:"
for skill_path in "$CLONE_DIR"/skills/*/; do
    [ -d "$skill_path" ] || continue
    skill_name="$(basename "$skill_path")"
    if [ -f "$skill_path/README.md" ]; then
        echo "  • $skill_name: see $CLONE_DIR/skills/$skill_name/README.md"
    fi
done
