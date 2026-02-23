---
name: commit
description: Create proper git commits for all uncommitted changes with descriptive messages
argument-hint: "[optional message hint]"
allowed-tools:
  - Bash
  - Read
---

Create well-structured git commits for all uncommitted changes in the repository.

## Requirements

- **File-based commits**: Commit whole files only, not partial files or line hunks
- **Gradual commits**: Even if changes are logically related, limit each commit to **20-25 files maximum**. Split larger changesets into multiple focused commits. This improves reviewability, makes git bisect more effective, and keeps history readable.
- **No push**: Only commit locally, never push to remote
- **Co-author**: Always include co-author line in commit message

## Commit Message Format

**First, check `git log --oneline -5` to match the repository's existing commit style.**
The format below is a fallback when no clear pattern exists:

```
<Short summary line - what was done>

<Detailed description of changes>:
- <bullet point 1>
- <bullet point 2>
- <bullet point 3>

<Optional context or rationale>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

## Example

This is just an example. Always prioritize matching the repository's existing commit style.

```
Add user authentication middleware

Implements JWT validation middleware for protected API routes:
- Validate token signature and expiry on each request
- Attach decoded user context to request pipeline
- Return 401 with actionable error message on failure

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

## Mode Detection

**Check for plan mode** before operations. Plan mode is indicated by:
- System instructions include "Plan mode is active"
- An active plan file path exists (e.g., `~/.plaude/plans/<name>.md`)

---

### If Plan Mode IS Active → Plan the Commits

**Only use read-only Tier 1 commands.** Do not execute any git write operations.

1. Gather information:
   - `git status` - see uncommitted changes
   - `git diff` - understand what changed
   - `git log --oneline -5` - match existing commit style

2. Analyze changes and group related files logically

3. **Append a Commit Plan section to the active plan file:**

```
## Commit Plan

### Commit 1: <short summary>
**Files:**
- path/to/file1
- path/to/file2

**Message:**
~~~
<Short summary line>

<Detailed description>:
- bullet point 1
- bullet point 2

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
~~~

### Commit 2: <short summary>
...
```

4. Inform user:

```
📝 Commit plan appended to plan file

Commits planned: N
Files staged: M

Review the plan. After exiting plan mode, run /commit again to execute.
```

---

### If Plan Mode is NOT Active → Execute Commits

1. Run `git status` to see all uncommitted changes
2. Run `git diff` to understand what changed
3. Run `git log --oneline -5` to match existing commit message style
4. Group related files logically for each commit
5. Stage files with `git add <specific-files>` (not `git add -A` or `git add .`)
6. Create commit using HEREDOC format for proper message formatting
7. Repeat for remaining changes
8. Run final `git status` to confirm all changes are committed

## Restrictions

- **In plan mode**: Only read-only git commands, write plan to plan file
- **NEVER use `git -C` pattern**
- **NEVER use `git add -A` or `git add .`** - always specify files explicitly
- **NEVER push to remote**
- **NEVER amend existing commits** unless explicitly requested
