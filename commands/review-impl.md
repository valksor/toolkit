---
name: review-impl
description: Calibrated 4-perspective review of code changes (Senior Dev, Senior QA, End User, Security)
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

Run a calibrated multi-perspective review of implementation changes using four parallel reviewers: Senior Developer, Senior QA, End User, and Security.

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

## Step 3: Dispatch Four Parallel Reviews

Launch ALL FOUR in a single message using the Task tool.

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

### Subagent 4: Security

```
subagent_type: "toolkit:reviewer-security"

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

Extract blockers, concerns, advisories, and verdict from each agent.

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

### Advisories ([Z] total)
- [advisory] ([source])

### Verdict Summary
| Reviewer | Verdict |
|----------|---------|
| Senior Dev | [verdict] |
| Senior QA | [verdict] |
| End User | [verdict] |
| Security | [verdict] |

```

**After producing this summary, immediately proceed to Step 5 — do not wait for the user.**

## Step 5: Validate and Address Findings

Work through all findings from the summary. **Validate every finding against the actual codebase before acting.** AI reviewers can misread code, hallucinate issues, or misjudge severity — the orchestrator must verify before fixing.

### 5.1 Validate and Fix Blockers

Blockers are highest priority but must be validated first. For each blocker:
1. Read the affected file(s) and surrounding context to verify the finding is real
2. Check whether the described failure scenario actually applies to this code
3. If **CONFIRMED** → implement the fix, note what was done
4. If **INVALID** (the reviewer misread the code, the issue does not actually exist, or the failure scenario is impossible given the actual implementation) → mark as "Invalid — [reason]" and do not fix

Invalid blockers do not count toward the NEEDS WORK verdict. If all blockers are invalidated, update the effective verdict accordingly.

For confirmed bug/crash blockers where the root cause is unclear, use `superpowers:systematic-debugging` before writing the fix.

### 5.2 Validate and Address Concerns

For each concern, validate before acting:
- **Actually exists?** Read the relevant code — does this issue actually exist, or did the reviewer misread the implementation?
- **Proportionate?** Given the actual code, is the severity appropriate, or is this a minor issue being overcategorized?

If validated → **fix it**, note what was done. Pre-existing vs regression is not a valid distinction — all real findings must be addressed.
If the fix requires changes to files *outside* the review scope → **defer**: add a `// TODO:` comment with one line of justification.
If invalid (reviewer misread the code) → **decline** — "Invalid: [reason]."

### 5.3 Evaluate Advisories

For each advisory:
1. Read the relevant code to verify the finding is accurate
2. Assess: Is the improvement real and worthwhile?
3. Assess: Can it be applied cleanly within the changed files with low risk?

If the finding is valid and can be applied within the reviewed files → **apply it**, note what was done.
If the finding is valid but requires changes to files *outside* the review scope → **defer** with a brief reason.
If the finding is invalid (reviewer misread the code) → **decline** — "Invalid: [reason]."

Every advisory gets an explicit disposition. No advisory is dismissed without a stated reason.

### 5.4 Report and Re-run

Output a brief action summary:

```
## Fixes Applied - Pass [N]

### Blockers ([N] confirmed and fixed, [M] invalid)
- [B1]: Fixed — [what was done]
- [B2]: Invalid — [reviewer misread X; actual code does Y]

### Concerns
- [C1]: Fixed — [what was done]
- [C2]: Deferred — [requires changes outside review scope; TODO added]
- [C3]: Declined — [invalid: reason]

### Advisories
- [A1]: Applied — [what was done]
- [A2]: Deferred — [requires changes outside review scope]
- [A3]: Declined — [invalid: reason]

### Post-Validation Verdict: [PASS / NEEDS WORK / APPROVED WITH NOTES]
[Updated verdict after removing invalid findings]
```

Then **automatically re-run from Step 1** as pass [N+1] to confirm the fixes hold. Include invalidated findings under "PREVIOUSLY ADDRESSED" as "Invalid — verified against codebase, not a real issue" so reviewers do not re-raise them.

**Stopping condition:** If after re-running the verdict is PASS or APPROVED WITH NOTES, stop and tell the user. If still NEEDS WORK after one fix-and-re-review cycle, stop, report remaining issues, and ask the user how to proceed rather than looping.

## Restrictions

- NEVER skip calibration rules (see `toolkit:review-calibration`)
- NEVER dispatch reviewers sequentially — always in parallel
- NEVER re-litigate addressed findings on pass 2+
- NEVER wait for user input between Step 4 and Step 5 — address findings automatically
- Pass 3+ with remaining blockers → suggest manual pair-review instead of another automated pass
- Large diffs (500+ lines) → instruct reviewers to focus on the most critical files
