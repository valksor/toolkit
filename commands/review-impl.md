---
name: review-impl
description: Calibrated 3-perspective review of code changes (Senior Dev, Senior QA, End User)
argument-hint: "[all | plan:<path> | plan:auto | file-or-diff-scope]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Task
  - Edit
  - Write
---

Run a calibrated multi-perspective review of implementation changes using three parallel reviewers: Senior Developer, Senior QA, and End User.

## Step 1: Gather the Changes

Collect the implementation to review. The scope depends on the argument:

### If `plan:<path>` or `plan:auto` was provided (Plan-Scoped Review)

**1. Locate the plan file:**
- `plan:<path>`: Use the specified path (expand `$CLAUDE_CONFIG_DIR` and `~` as needed)
- `plan:auto`: Check conversation context for an active plan path, or fall back to Step 1.5's matching logic

**2. Extract file paths from the plan:**

```bash
grep -oE '(`[^`]+\.[a-zA-Z0-9]+`|/[a-zA-Z0-9_/-]+\.[a-zA-Z0-9]+|[a-zA-Z0-9_-]+/[a-zA-Z0-9_/-]+\.[a-zA-Z0-9]+)' "$PLAN_PATH" | tr -d '`' | sort -u
```

**3. Get changed files and generate filtered diff:**

```bash
git diff HEAD --name-only
git diff HEAD -- <filtered-file-list>
```

**4. Report scope:** Files in plan / files changed / reviewing (intersection) / excluded.

**Fallback:** If plan not found or no files match, fall back to default (full diff) without error.

---

### If the user provided specific files

Read those files directly.

### If the user passed `all`

```bash
git diff HEAD --name-only
git diff HEAD
```

### Otherwise (default)

```bash
git diff --name-only
git diff
```

---

If no changes exist in the selected scope, check alternatives before giving up:
- If default scope has no unstaged changes but staged changes exist, tell the user: "No unstaged changes found. Run `/review-impl all` to include staged changes." and stop.
- If no uncommitted changes at all, compare against base branch:

```bash
git log --oneline main..HEAD 2>/dev/null || git log --oneline master..HEAD 2>/dev/null
git diff main...HEAD 2>/dev/null || git diff master...HEAD 2>/dev/null
```

For large diffs (500+ lines), also read the full content of the most critical changed files.

## Step 1.5: Locate Related Plan (Optional)

**Skip if:** user passed `all`, specific files, or `plan:*` (plan already loaded).

Check the last 10 plan files for one that matches the changes:

```bash
ls -t "$CLAUDE_CONFIG_DIR/plans/"*.md 2>/dev/null | head -10
```

Read each and check if it references any of the changed files. If multiple match, pick the one with the most file path matches. Save content for Step 3 context if found.

## Step 2: Determine Review Pass Number

Check conversation context for previous `## Implementation Review Summary - Pass` outputs:
- None found → **Pass 1**
- Pass 1 found, work done since → **Pass 2**
- Pass 2 found → **Pass 3**

**Concern Escalation (Pass 2+):** Check whether concerns from the previous pass were resolved:
- **Addressed**: fixed in code
- **Deferred**: TODO/ticket created with justification
- **Risk accepted**: explicitly acknowledged with reasoning

Any unresolved concern becomes a **Blocker** on this pass. Prefix it: `"ESCALATED FROM PASS [N-1]: [concern] — was a concern, not resolved."`

**Pass 3+:** Tell the user this is unusual. Suggest manual pair-review. Only proceed if confirmed.

## Step 3: Dispatch Three Parallel Reviews

Launch ALL THREE in a single message using the Task tool.

### Subagent 1: Senior Developer

```
subagent_type: "toolkit:reviewer-senior-dev"

PASS NUMBER: [N]
[If pass 2+:]
PREVIOUSLY ADDRESSED:
- [summary of items fixed in previous passes]

[If escalated concerns:]
ESCALATED FROM PASS [N-1]: [concern description] — was a concern that was not addressed, deferred, or accepted; now a blocker.

CHANGED FILES:
[file list]

DIFF:
[diff content]

[If plan found in Step 1.5:]
DESIGN PLAN (context — check if implementation matches intent):
[plan content]
```

### Subagent 2: Senior QA

```
subagent_type: "toolkit:reviewer-senior-qa"

PASS NUMBER: [N]
[If pass 2+:]
PREVIOUSLY ADDRESSED:
- [summary of items fixed in previous passes]

[If escalated:]
ESCALATED FROM PASS [N-1]: [concern] — now a blocker.

CHANGED FILES:
[file list]

DIFF:
[diff content]

[If plan found:]
DESIGN PLAN:
[plan content]
```

### Subagent 3: End User

```
subagent_type: "toolkit:reviewer-end-user"

PASS NUMBER: [N]
[If pass 2+:]
PREVIOUSLY ADDRESSED:
- [summary of items fixed in previous passes]

[If escalated:]
ESCALATED FROM PASS [N-1]: [concern] — now a blocker.

CHANGED FILES:
[file list]

DIFF:
[diff content]

[If plan found:]
DESIGN PLAN:
[plan content]
```

## Step 4: Merge and Present Results

**DO NOT** output individual reviewer responses. Process internally → single consolidated summary.

### 4.1 Parse

Extract blockers, concerns, suggestions, and verdict from each agent.

### 4.2 Deduplicate

Two findings are duplicates if they reference the same file/function AND describe the same issue, OR describe the same conceptual problem regardless of wording. For duplicates: keep the most detailed description, note all sources (`[Senior Dev, QA]`), count as ONE item.

### 4.3 Overall Verdict

- Any blocker → **NEEDS WORK**
- No blockers, concerns exist → **APPROVED WITH NOTES**
- No blockers, no concerns → **PASS**

### 4.4 Output

```
## Implementation Review Summary - Pass [N]

[If plan-scoped:]
**Scope:** Plan-scoped — `[plan-filename]`
- Reviewing: [Z] files | Excluded: [W] files

### Overall Verdict: [PASS / NEEDS WORK / APPROVED WITH NOTES]

### Blockers ([X] unique)
| # | Finding | Flagged By | File(s) | Impact |
|---|---------|------------|---------|--------|
| 1 | [title + description] | [Senior Dev, QA] | [file:line] | [who/what] |

[If 0 blockers: "No blockers identified."]

### Concerns ([Y] unique)
| # | Finding | Flagged By | Notes |
|---|---------|------------|-------|
| 1 | [description] | [End User] | [conditions/mitigation] |

### Suggestions ([Z] total)
- [suggestion] ([source])

### Verdict Summary
| Reviewer | Verdict |
|----------|---------|
| Senior Dev | [verdict] |
| Senior QA | [verdict] |
| End User | [verdict] |

```

**After producing this summary, immediately proceed to Step 5 — do not wait for the user.**

## Step 5: Address Findings

Work through all findings from the summary. Do not ask for permission — fix, evaluate, and act.

### 5.1 Fix All Blockers

Blockers are non-negotiable. For each one:
1. Read the affected file(s) to understand context
2. Implement the fix
3. Note what was done in one line

For bug/crash blockers where the root cause is unclear, use `superpowers:systematic-debugging` before writing the fix.

### 5.2 Evaluate and Address Concerns

For each concern, assess three things before acting:
- **Technically valid?** Is this a real issue, not a false positive given the actual codebase?
- **Viable now?** Can it be addressed within the current scope — no large unrelated refactors, no out-of-scope changes?
- **Improves things?** Does addressing it clearly improve correctness, safety, or clarity without introducing new risk?

If all three are yes → **fix it**, note what was done.
If viable but borderline → **defer**: add a `// TODO:` comment with one line of justification.
If not viable or out of scope → **skip with reason**.

### 5.3 Evaluate Suggestions

For each suggestion:
- Is it clearly beneficial with low implementation risk?
- Does it fit cleanly within the changed files?

If yes to both → **apply it**.
Otherwise → **skip** — suggestions are optional by definition.

### 5.4 Report and Re-run

Output a brief action summary:

```
## Fixes Applied - Pass [N]

### Blockers ([N] fixed)
- [B1]: [what was done]

### Concerns
- [C1]: Fixed — [what was done]
- [C2]: Deferred — [TODO added, reason]
- [C3]: Skipped — [out of scope / not valid]

### Suggestions
- [S1]: Applied — [what was done]
- [S2]: Skipped — [reason]
```

Then **automatically re-run from Step 1** as pass [N+1] to confirm the fixes hold.

**Stopping condition:** If after re-running the verdict is PASS or APPROVED WITH NOTES, stop and tell the user. If still NEEDS WORK after one fix-and-re-review cycle, stop, report remaining issues, and ask the user how to proceed rather than looping.

## Restrictions

- NEVER skip calibration rules (see `toolkit:review-calibration`)
- NEVER dispatch reviewers sequentially — always in parallel
- NEVER re-litigate addressed findings on pass 2+
- NEVER wait for user input between Step 4 and Step 5 — address findings automatically
- Pass 3+ with remaining blockers → suggest manual pair-review instead of another automated pass
- Large diffs (500+ lines) → instruct reviewers to focus on the most critical files
