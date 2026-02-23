#!/usr/bin/env bash
# Sync local workspace to all Claude Code plugin locations.
# Run from anywhere — script resolves its own location.
#
# Usage: ./scripts/sync.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$SOURCE_DIR/.claude-plugin/marketplace.json"

# Read metadata from marketplace.json (requires jq; fall back to hardcoded values)
if command -v jq &>/dev/null && [[ -f "$MANIFEST" ]]; then
    MARKETPLACE=$(jq -r '.name' "$MANIFEST")
    PLUGIN_NAME=$(jq -r '.plugins[0].name' "$MANIFEST")
    VERSION=$(jq -r '.plugins[0].version' "$MANIFEST")
else
    MARKETPLACE="valksor-toolkit"
    PLUGIN_NAME="toolkit"
    VERSION="0.1.0"
fi

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
PLAUDE_DIR="${PLAUDE_CONFIG_DIR:-$HOME/.plaude}"

sync_to() {
    local dest="$1"
    mkdir -p "$dest"
    rsync -a --delete --exclude=".git" "$SOURCE_DIR/" "$dest/"
    echo "  ✓ $dest"
}

echo "Syncing $SOURCE_DIR → plugin locations..."

sync_to "$CLAUDE_DIR/plugins/$PLUGIN_NAME"
sync_to "$CLAUDE_DIR/plugins/cache/$MARKETPLACE/$PLUGIN_NAME/$VERSION"

# .plaude locations (skip silently if .plaude doesn't exist)
if [[ -d "$PLAUDE_DIR" ]]; then
    sync_to "$PLAUDE_DIR/plugins/$PLUGIN_NAME"
    sync_to "$PLAUDE_DIR/plugins/cache/$MARKETPLACE/$PLUGIN_NAME/$VERSION"
fi

# Register source path so /update-toolkit can rsync without arguments
echo "$SOURCE_DIR" > "$CLAUDE_DIR/plugins/$PLUGIN_NAME/.dev-source"
echo "  ✓ registered source → $CLAUDE_DIR/plugins/$PLUGIN_NAME/.dev-source"

echo ""
echo "Done. Restart your Claude Code session to pick up changes."
