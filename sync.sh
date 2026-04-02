#!/usr/bin/env bash
# Sync claude-brain repo to ~/.claude/ global config
# Run this after making changes to the repo.

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Syncing claude-brain → $CLAUDE_DIR"

# CLAUDE.md — symlink
ln -sf "$BRAIN_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "  ✓ CLAUDE.md"

# Rules — symlink each file
mkdir -p "$CLAUDE_DIR/rules"
for file in "$BRAIN_DIR"/rules/*.md; do
  ln -sf "$file" "$CLAUDE_DIR/rules/$(basename "$file")"
done
echo "  ✓ rules/"

# Skills — symlink each skill directory
mkdir -p "$CLAUDE_DIR/skills"
for dir in "$BRAIN_DIR"/skills/*/; do
  name="$(basename "$dir")"
  ln -sf "$dir" "$CLAUDE_DIR/skills/$name"
done
echo "  ✓ skills/"

echo ""
echo "Done. Global config is now linked to $BRAIN_DIR"
echo "Per-project .claude/ files will still override these."
