---
name: review-plan
description: Calibrated 3-perspective review of a plan document (Senior Dev, Senior QA, End User)
argument-hint: "<plan-file-path>"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Task
  - Edit
  - Write
---

Run a calibrated multi-perspective review of a plan document using three parallel reviewers: Senior Developer, Senior QA, and End User.

## Step 1: Locate the Plan

If the user provided a file path argument, use that.

Otherwise:
1. Check for recent `.md` files in `docs/plans/`, the current directory, and `~/.claude/plans/`
2. If multiple candidates, ask the user which file to review

Read the full plan content.

## Step 2: Determine Review Pass Number

Check conversation context for previous `## Plan Review Summary - Pass` outputs:
- None found → **Pass 1**
- Pass 1 found, work done since → **Pass 2**
- Pass 2 found → **Pass 3**

**Concern Escalation (Pass 2+):** Check whether concerns from the previous pass were resolved:
- **Addressed**: plan updated to fix the issue
- **Deferred**: note added that this will be handled during implementation, with justification
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

[If escalated:]
ESCALATED FROM PASS [N-1]: [concern] — now a blocker.

PLAN TO REVIEW:
[full plan content]
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

PLAN TO REVIEW:
[full plan content]
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

PLAN TO REVIEW:
[full plan content]
```

## Step 4: Merge and Present Results

**DO NOT** output individual reviewer responses. Process internally → single consolidated summary.

### 4.1 Parse

Extract blockers, concerns, suggestions, and verdict from each agent.

### 4.2 Deduplicate

Two findings are duplicates if they reference the same section/component AND describe the same issue, OR describe the same conceptual problem regardless of wording. Keep the most detailed description, note all sources, count as ONE item.

### 4.3 Overall Verdict

- Any blocker → **NEEDS WORK**
- No blockers, concerns exist → **APPROVED WITH NOTES**
- No blockers, no concerns → **PASS**

### 4.4 Output

```
## Plan Review Summary - Pass [N]

### Overall Verdict: [PASS / NEEDS WORK / APPROVED WITH NOTES]

### Blockers ([X] unique)
| # | Finding | Flagged By | Impact |
|---|---------|------------|--------|
| 1 | [title + description] | [Senior Dev, QA] | [who/what] |

[If 0 blockers: "No blockers identified. Plan is approved to proceed."]

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

Work through all findings by editing the plan file directly. Do not ask for permission.

### 5.1 Fix All Blockers

Blockers are non-negotiable. For each one:
1. Identify which section of the plan the blocker concerns
2. Edit the plan file to resolve it — add missing steps, fix incorrect assumptions, clarify ambiguities
3. Note what was changed in one line

### 5.2 Evaluate and Address Concerns

For each concern, assess:
- **Technically valid?** Is this a real gap or risk given the plan's actual scope?
- **Viable to address in the plan?** Can it be resolved by clarifying or extending the plan — not by writing implementation code now?
- **Improves the plan?** Does addressing it make the plan safer or clearer to execute?

If all three are yes → **edit the plan to address it**, note what was changed.
If it should be deferred to implementation → **add a note** in the relevant plan section: `> Note: [concern] — will be addressed during implementation.`
If not valid or out of scope → **skip with reason**.

### 5.3 Evaluate Suggestions

For each suggestion:
- Does it meaningfully improve the plan's clarity or completeness?
- Is it a small, safe addition?

If yes to both → **apply it** to the plan.
Otherwise → **skip** — suggestions are optional.

### 5.4 Report and Re-run

Output a brief action summary:

```
## Plan Revisions - Pass [N]

### Blockers ([N] fixed)
- [B1]: [what was updated in the plan]

### Concerns
- [C1]: Fixed — [what was updated]
- [C2]: Noted for implementation — [section updated]
- [C3]: Skipped — [not valid / out of scope]

### Suggestions
- [S1]: Applied — [what was added]
- [S2]: Skipped — [reason]
```

Then **automatically re-run from Step 1** as pass [N+1] to confirm the revisions hold.

**Stopping condition:** If after re-running the verdict is PASS or APPROVED WITH NOTES, stop and tell the user the plan is ready — suggest proceeding with `superpowers:executing-plans` or `superpowers:subagent-driven-development`. If still NEEDS WORK after one fix-and-re-review cycle, stop, report remaining issues, and ask the user how to proceed.

## Restrictions

- NEVER skip calibration rules (see `toolkit:review-calibration`)
- NEVER dispatch reviewers sequentially — always in parallel
- NEVER re-litigate addressed findings on pass 2+
- NEVER wait for user input between Step 4 and Step 5 — address findings automatically
- Pass 3+ with remaining blockers → suggest manual pair-review instead of another automated pass
