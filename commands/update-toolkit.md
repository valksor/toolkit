---
name: update-toolkit
description: Update the valksor/toolkit plugin — syncs from local workspace if registered, otherwise pulls from git
allowed-tools:
  - Bash
---

Update the toolkit plugin to the latest version.

## Step 1: Locate the install directory

```bash
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
PLUGIN_DIR="$CLAUDE_DIR/plugins/toolkit"
echo "$PLUGIN_DIR"
```

## Step 2: Check for local dev source

```bash
cat "$PLUGIN_DIR/.dev-source" 2>/dev/null || echo ""
```

## Step 3: Sync or pull

### If `.dev-source` exists → rsync from local workspace

Read the source path from `.dev-source`, then run the sync script from that location:

```bash
SOURCE=$(cat "$PLUGIN_DIR/.dev-source")
bash "$SOURCE/scripts/sync.sh"
```

This syncs the local workspace to all four plugin locations without requiring a git push.

### If `.dev-source` does not exist → git pull

```bash
cd "$PLUGIN_DIR" && git pull --ff-only
```

## Step 4: Report

Tell the user what happened:
- Which method was used (local sync vs git pull)
- What changed (files updated, or "already up to date")
- Reminder to restart the Claude Code session for changes to take effect
