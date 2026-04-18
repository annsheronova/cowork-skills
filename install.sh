#!/bin/bash
# Install the threads-collector skill onto this Mac.
#
# Safe to run multiple times — it updates the repo on subsequent runs and never
# clobbers your edited config.md or hook_patterns.md.
#
# Usage:
#   bash install.sh

set -e

SKILLS_DIR="$HOME/.claude/skills"
REPO_DIR="$SKILLS_DIR/cowork-skills"
RUNTIME_DIR="$HOME/cowork/threads-collector"
REPO_URL="https://github.com/annsheronova/cowork-skills.git"

echo "[1/5] Ensuring skills directory at $SKILLS_DIR..."
mkdir -p "$SKILLS_DIR"

echo "[2/5] Fetching the repo..."
if [ -d "$REPO_DIR/.git" ]; then
    echo "   Repo already cloned — pulling latest."
    git -C "$REPO_DIR" pull --ff-only
else
    git clone "$REPO_URL" "$REPO_DIR"
fi

echo "[3/5] Linking threads-collector into the skills dir..."
cd "$SKILLS_DIR"
# Replace any stale symlink, but don't nuke a real folder by accident
if [ -L "threads-collector" ]; then
    rm "threads-collector"
elif [ -e "threads-collector" ]; then
    echo "   ERROR: $SKILLS_DIR/threads-collector exists and isn't a symlink." >&2
    echo "   Move or rename it, then re-run this script." >&2
    exit 1
fi
ln -s cowork-skills/threads-collector threads-collector

echo "[4/5] Setting up runtime folder at $RUNTIME_DIR..."
mkdir -p "$RUNTIME_DIR/library"

if [ ! -f "$RUNTIME_DIR/config.md" ]; then
    cp "$REPO_DIR/threads-collector/config.md" "$RUNTIME_DIR/config.md"
    echo "   Copied config template. You MUST edit this file before running the skill:"
    echo "     $RUNTIME_DIR/config.md"
else
    echo "   Existing config.md detected — left it alone."
fi

if [ ! -f "$RUNTIME_DIR/library/hook_patterns.md" ]; then
    cp "$REPO_DIR/threads-collector/hook_patterns.md" "$RUNTIME_DIR/library/hook_patterns.md"
    echo "   Seeded hook_patterns.md with the Q1 2026 Threads research catalog."
else
    echo "   Existing hook_patterns.md detected — left it alone (it grows with each run)."
fi

echo ""
echo "[5/5] Done."
echo ""
echo "To use the skill:"
echo "  1. Open $RUNTIME_DIR/config.md and fill in 'my_topics' with the topics you care about."
echo "  2. Make sure the Claude-in-Chrome extension is installed and connected, and you're logged into threads.com."
echo "  3. Open a new Cowork session and say: 'collect threads'"
echo ""
