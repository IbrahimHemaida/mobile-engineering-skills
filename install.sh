#!/usr/bin/env bash
# mobile-engineering-skills installer
# Usage: curl -fsSL https://raw.githubusercontent.com/IbrahimHemaida/mobile-engineering-skills/main/install.sh | bash
#
# Copies all fourteen skills into ~/.claude/skills/ (Claude Code's user-level
# skill directory, auto-discovered across every project). Run with
# --project to install into the current project's .claude/skills/ instead
# (shared with your team via git, not just this machine).

set -euo pipefail

REPO_URL="https://github.com/IbrahimHemaida/mobile-engineering-skills.git"
TARGET_DIR="${HOME}/.claude/skills"
MODE="user"

for arg in "$@"; do
  case "$arg" in
    --project)
      TARGET_DIR="$(pwd)/.claude/skills"
      MODE="project"
      ;;
    --help|-h)
      echo "Usage: install.sh [--project]"
      echo "  (default)   install to ~/.claude/skills (available in every project)"
      echo "  --project   install to ./.claude/skills (this project only, git-trackable)"
      exit 0
      ;;
  esac
done

command -v git >/dev/null 2>&1 || { echo "❌ git is required but not found."; exit 1; }

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "📥 Cloning mobile-engineering-skills..."
git clone --quiet --depth 1 "$REPO_URL" "$TMP_DIR"

mkdir -p "$TARGET_DIR"

echo "📦 Installing skills to $TARGET_DIR ($MODE-level)..."
for skill_dir in "$TMP_DIR"/skills/*/; do
  skill_name="$(basename "$skill_dir")"
  rm -rf "${TARGET_DIR:?}/${skill_name}"
  cp -r "$skill_dir" "$TARGET_DIR/"
  echo "  ✓ $skill_name"
done

echo ""
echo "✅ Done. Installed $(ls "$TMP_DIR"/skills | wc -l | tr -d ' ') skills to $TARGET_DIR"
echo ""
echo "Claude Code auto-discovers skills from this directory — no restart needed."
echo "Try it: open Claude Code in a mobile project and ask it to review a feature,"
echo "or invoke one directly, e.g. /mobile-architecture-guard"
