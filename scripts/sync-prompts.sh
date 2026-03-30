#!/bin/bash
# ============================================================================
# Sync Claude Code commands → Copilot prompt files
# ============================================================================
# Run this after modifying any .claude/commands/**/*.md file to keep
# Copilot prompt files in sync. Both tools read the same instructions,
# just from different directories.
#
# Usage: ./scripts/sync-prompts.sh
# ============================================================================

set -e

CLAUDE_DIR=".claude/commands"
COPILOT_DIR=".github/prompts"

echo "Syncing Claude commands → Copilot prompts..."

# Sync all .md files, preserving subdirectory structure (e.g., project/)
find "$CLAUDE_DIR" -name "*.md" -type f | while read -r cmd_file; do
    # Get relative path from CLAUDE_DIR (e.g., project/0-setup.md)
    rel_path="${cmd_file#$CLAUDE_DIR/}"
    rel_dir=$(dirname "$rel_path")
    filename=$(basename "$rel_path")
    prompt_file="$COPILOT_DIR/$rel_dir/${filename%.md}.prompt.md"

    mkdir -p "$COPILOT_DIR/$rel_dir"
    cp "$cmd_file" "$prompt_file"

    echo "  ✓ $rel_path → $rel_dir/${filename%.md}.prompt.md"
done

# Also sync CLAUDE.md → copilot-instructions.md (skip if manually maintained)
if [ -f "CLAUDE.md" ] && [ ! -f ".github/copilot-instructions.md.manual" ]; then
    cp "CLAUDE.md" ".github/copilot-instructions.md"
    echo "  ✓ CLAUDE.md → .github/copilot-instructions.md"
fi

echo ""
echo "Done. Both Claude Code and Copilot will use the same instructions."
echo "Claude Code: .claude/commands/**/*.md"
echo "Copilot:     .github/prompts/**/*.prompt.md"
