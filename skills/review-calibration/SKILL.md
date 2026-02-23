---
name: review-calibration
description: >-
  Use this skill when performing calibrated code or plan reviews.
  Provides the severity classification system and anti-hate-loop rules
  that prevent infinite review cycles.
  Trigger phrases: "review calibration", "severity levels", "review rules"
---

# Review Calibration System

Shared severity classification and convergence rules for multi-perspective reviews. Prevents infinite "hate loops" where reviewers always find something to complain about.

## Severity Levels

Every finding MUST be classified into exactly one level:

### Blocker
- Genuinely broken: will cause real failures, data loss, security vulnerabilities, or makes the feature unusable
- **Requires concrete justification:** WHAT breaks, WHO is affected, HOW LIKELY it occurs
- If you cannot articulate a specific failure scenario with a victim, it is NOT a blocker
- **Maximum 3 blockers per reviewer per pass.** If you have 4+ candidates, demote the least severe to Concern

### Concern
- Real issue that MUST be addressed or explicitly deferred before proceeding
- Not immediately dangerous (otherwise it's a Blocker), but cannot be silently ignored
- Include: what the risk is, under what conditions it manifests, suggested mitigation
- **Maximum 5 concerns per reviewer.** If you have more, consolidate related items or demote the least important to Suggestions
- Unlike Suggestions, concerns require an explicit response: fix, defer with justification, or accept risk

### Suggestion
- Nice-to-have improvement: better naming, style preference, minor optimization, roughly-equivalent alternative approach
- **Explicitly optional.** The implementer should feel zero pressure to address these
- One sentence per suggestion is ideal

## Re-Review Rules (Pass 2+)

1. **Previously-addressed items are DONE.** Do not re-litigate. Do not say "this was improved but could be even better." It is done.
2. **The bar for new blockers RISES with each pass:**
   - Pass 1: Normal threshold
   - Pass 2: New blockers only if they are worse than issues already approved in pass 1
   - Pass 3+: New blockers only for genuine regressions introduced by the fixes themselves
3. **Total findings must DECREASE on each pass**, not stay the same or increase
4. If pass 1 had 0 blockers, pass 2 should almost certainly also have 0 blockers (unless a fix introduced a regression)

## Concern Resolution Requirement

On pass 2+, the orchestrator checks whether concerns from previous passes were resolved:

1. **Addressed** - The issue was fixed in the code/plan
2. **Deferred** - A TODO/ticket was created with justification for why it's acceptable to defer
3. **Risk accepted** - Explicit acknowledgment that the risk remains, with reasoning

**Unaddressed concerns escalate:** If a concern from pass N was not resolved by one of the above methods, it becomes a **Blocker** on pass N+1. This prevents concerns from being silently ignored.

The escalation rule is the key enforcement mechanism. Without it, "APPROVED WITH NOTES" becomes "just ship it."

## Convergence Criteria

| Verdict | Condition | Action |
|---------|-----------|--------|
| **PASS** | Zero blockers, zero concerns | Proceed |
| **APPROVED WITH NOTES** | Zero blockers, concerns exist | Resolve each concern (address/defer/accept), then proceed |
| **NEEDS WORK** | Any reviewer has 1+ blockers | Address blockers, re-run review |

**Important:** APPROVED WITH NOTES is NOT "proceed and maybe look at concerns later." Each concern must be explicitly resolved before proceeding. Unresolved concerns become blockers on the next pass.

## Pass 3+ Escape Valve

If a review is still not passing after 3 rounds, **stop running automated reviews.** Flag this to the user as unusual and suggest manually pair-reviewing the remaining items. This breaks the loop.

## Calibration Examples

**IS a blocker:**
> "The SQL query uses string interpolation instead of parameterized queries. This is a SQL injection vulnerability that any authenticated user could exploit."

**Is a Concern, NOT a blocker:**
> "The function handles errors by returning nil, which could cause a nil pointer dereference if the caller does not check. Unlikely in current call sites but could be a problem if reused."

**Is a Suggestion, NOT a blocker:**
> "This function is 45 lines. Consider extracting the validation logic into a helper."

## Reviewer Output Format

```
[ReviewerName] Review - Pass [N]

### Blockers ([count]/3 max)
- [B1] [title]: [what breaks, who is affected]

### Concerns
- [C1] [title]: [risk, conditions, mitigation]

### Suggestions
- [S1] [one-liner]

### Verdict: PASS / NEEDS WORK / APPROVED WITH NOTES
[One sentence summary]
```
