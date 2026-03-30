---
name: review-plan
description: Calibrated 4-perspective review of a plan document (Senior Dev, Senior QA, End User, Security)
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

Run a calibrated multi-perspective review of a plan document using four parallel reviewers: Senior Developer, Senior QA, End User, and Security.

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

## Step 3: Dispatch Four Parallel Reviews

Launch ALL FOUR in a single message using the Task tool.

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

### Subagent 4: Security

```
subagent_type: "toolkit:reviewer-security"

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

Extract blockers, concerns, advisories, and verdict from each agent.

### 4.2 Deduplicate

Two findings are duplicates if they reference the same section/component AND describe the same issue, OR describe the same conceptual problem regardless of wording. Keep the most detailed description, note all sources, count as ONE item.

### 4.3 Overall Verdict

- Any blocker → **NEEDS WORK**
- No blockers, concerns exist → **CONCERNS REMAIN**
- No blockers, no concerns → **PASS**

### 4.4 Output

```
## Plan Review Summary - Pass [N]

### Overall Verdict: [PASS / NEEDS WORK / CONCERNS REMAIN]

### Blockers ([X] unique)
| # | Finding | Flagged By | Impact |
|---|---------|------------|--------|
| 1 | [title + description] | [Senior Dev, QA] | [who/what] |

[If 0 blockers: "No blockers identified. Plan is approved to proceed."]

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

Work through all findings by editing the plan file directly. **Validate every finding against the actual plan content before acting.** AI reviewers can misread plans, hallucinate gaps, or misjudge severity — the orchestrator must verify before modifying.

### 5.1 Validate and Fix Blockers

Blockers are highest priority but must be validated first. For each blocker:
1. Re-read the relevant plan section to verify the finding is real
2. Check whether the described gap or risk actually applies given the plan's context
3. If **CONFIRMED** → edit the plan to resolve it (add missing steps, fix incorrect assumptions, clarify ambiguities), note what was changed
4. If **INVALID** (the reviewer misread the plan, the gap doesn't exist, or the risk is already addressed elsewhere in the plan) → mark as "Invalid — [reason]" and do not modify

Invalid blockers do not count toward the NEEDS WORK verdict. If all blockers are invalidated, update the effective verdict accordingly.

### 5.2 Validate and Address Concerns

For each concern, validate before acting:
- **Actually exists?** Re-read the plan — does this gap or risk actually exist, or did the reviewer misread?
- **Proportionate?** Given the actual plan, is the severity appropriate?

If validated → **edit the plan to address it**, note what was changed. Pre-existing vs regression is not a valid distinction — all real findings must be addressed.
If validated but can only be resolved during implementation (not in the plan itself) → **add a note** in the relevant plan section: `> Note: [concern] — will be addressed during implementation.`
If invalid (reviewer misread the plan) → **decline** — "Invalid: [reason]."

### 5.3 Evaluate Advisories

For each advisory:
1. Re-read the relevant plan section to verify the finding is accurate
2. Assess: Does it meaningfully improve the plan's clarity or completeness?
3. Assess: Is it a small, safe addition?

If the finding is valid → **apply it** to the plan, note what was changed.
If the finding is valid but can only be resolved during implementation → **defer** with a brief reason.
If the finding is invalid (reviewer misread the plan) → **decline** — "Invalid: [reason]."

Every advisory gets an explicit disposition. No advisory is dismissed without a stated reason.

### 5.4 Report and Re-run

Output a brief action summary:

```
## Plan Revisions - Pass [N]

### Blockers ([N] confirmed and fixed, [M] invalid)
- [B1]: Fixed — [what was updated in the plan]
- [B2]: Invalid — [reviewer misread X; plan already addresses Y]

### Concerns
- [C1]: Fixed — [what was updated]
- [C2]: Noted for implementation — [section updated]
- [C3]: Declined — [invalid / out of scope / reason]

### Advisories
- [A1]: Applied — [what was added]
- [A2]: Deferred — [reason]
- [A3]: Declined — [reason]

### Post-Validation Verdict: [PASS / NEEDS WORK]
[Recalculated verdict: if all blockers are fixed/invalidated AND all concerns are fixed/deferred/declined → PASS. Only NEEDS WORK if confirmed blockers remain unfixed.]
```

**Post-validation verdict rules:** After Steps 5.1-5.3, every finding has an explicit disposition. Recalculate the verdict based on what remains *unresolved*:
- All blockers fixed or invalidated, all concerns fixed/deferred/declined → **PASS**
- Confirmed blockers remain unfixed → **NEEDS WORK**

CONCERNS REMAIN should not appear as a post-validation verdict because Step 5 requires dispositioning every concern. If a concern was deferred (with justification) or declined (as invalid), it is resolved — not open.

Then **automatically re-run from Step 1** as pass [N+1] to confirm the revisions hold. Include invalidated findings under "PREVIOUSLY ADDRESSED" as "Invalid — verified against plan, not a real issue" so reviewers do not re-raise them.

**Stopping condition:** If after re-running the verdict is **PASS**, stop and tell the user the plan is ready — suggest proceeding with `superpowers:executing-plans` or `superpowers:subagent-driven-development`. If still NEEDS WORK after one fix-and-re-review cycle, stop, report remaining issues, and ask the user how to proceed.

## Restrictions

- NEVER skip calibration rules (see `toolkit:review-calibration`)
- NEVER dispatch reviewers sequentially — always in parallel
- NEVER re-litigate addressed findings on pass 2+
- NEVER wait for user input between Step 4 and Step 5 — address findings automatically
- Pass 3+ with remaining blockers → suggest manual pair-review instead of another automated pass
