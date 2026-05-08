#!/usr/bin/env bash
# Sync claude-brain repo to ~/.claude/ global config
# Run this after making changes to the repo.

set -euo pipefail

BRAIN_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Symlink $1 to $2, refusing to overwrite a real file or directory.
# Stale symlinks are replaced cleanly. -n prevents `ln -sf` from following
# an existing symlink-to-directory and creating a nested link inside it.
link_safe() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "  ✗ $dst is a real file/directory — refusing to overwrite." >&2
    echo "    Move it aside first if you want sync to manage it." >&2
    exit 1
  fi
  ln -sfn "$src" "$dst"
}

echo "Syncing claude-brain → $CLAUDE_DIR"

# CLAUDE.md
link_safe "$BRAIN_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "  ✓ CLAUDE.md"

# Rules — symlink each file
mkdir -p "$CLAUDE_DIR/rules"
for file in "$BRAIN_DIR"/rules/*.md; do
  link_safe "$file" "$CLAUDE_DIR/rules/$(basename "$file")"
done
echo "  ✓ rules/"

# Skills — symlink each skill directory (strip trailing slash for ln -n)
mkdir -p "$CLAUDE_DIR/skills"
for dir in "$BRAIN_DIR"/skills/*/; do
  name="$(basename "$dir")"
  link_safe "${dir%/}" "$CLAUDE_DIR/skills/$name"
done
echo "  ✓ skills/"

echo ""
echo "Done. Global config is now linked to $BRAIN_DIR"
echo "Per-project .claude/ files will still override these."
