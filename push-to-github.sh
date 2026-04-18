#!/bin/bash
# Push cowork-skills to GitHub.
#
# Run this from your Mac's Terminal, from inside the cowork-skills folder:
#   cd "/Users/anna/Library/Application Support/Claude/local-agent-mode-sessions/360a4cf1-b959-4cb3-add1-13c6e02f500d/b16ec64d-922c-44b8-8b0e-0a09e4e6a651/local_075a28e4-4d35-4de4-ba6c-4423b51e037c/outputs/cowork-skills"
#   bash push-to-github.sh
#
# Prereqs:
#   1. The GitHub repo exists at github.com/annsheronova/cowork-skills (create it first if not).
#      Go to https://github.com/new, name it "cowork-skills", leave it empty (no README/license), click Create.
#   2. Git on your Mac can auth to GitHub over HTTPS. First push will either:
#        - Open a browser login (via Git Credential Manager / osxkeychain), OR
#        - Prompt for a Personal Access Token as the password (not your account password).
#      If neither happens and you get an auth error, run: `git config --global credential.helper osxkeychain`
#      then re-run this script — it'll open the login flow on next push.

set -e

REMOTE_URL="https://github.com/annsheronova/cowork-skills.git"

echo "Step 1: clearing the staging .git directory (created in sandbox, can't be used directly)..."
rm -rf .git

echo "Step 2: initializing fresh git repo..."
git init -b main
git add .
git commit -m "Initial commit: add threads-collector skill

A Cowork skill that scrolls Threads via Chrome and catches posts matching
user-defined criteria. Includes:
- SKILL.md with Step 0 preflight, validation gating, trending mode
- config.md for catch criteria (engagement thresholds, topics, filters)
- README.md with install, sample CSV output, common failures + fixes
- hook_patterns.md: seeded catalog of 15 Threads-specific hook patterns
  (Q1 2026 research) + 6 anti-patterns, auto-growing observed catalog"

echo "Step 3: adding remote and pushing..."
git remote add origin "$REMOTE_URL"
git push -u origin main

echo ""
echo "Done. Repo pushed to https://github.com/annsheronova/cowork-skills"
