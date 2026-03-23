---
name: guided-migration
description: >-
  Use when performing large codebase migrations or refactors — language upgrades,
  framework migrations, dependency replacements, monolith decomposition, or any
  multi-step transformation where the codebase must remain deployable throughout.
---

# Guided Migration

Migration-specific technique that layers on top of the standard `brainstorming → writing-plans → executing-plans` workflow. Does not replace these skills — it specializes them for migrations.

**Core principle:** Every step leaves the codebase in a deployable, test-passing state. Never big-bang.

## When to Use

- JS to TypeScript migration
- React class to functional component migration
- Language/framework version upgrade (Go 1.21→1.22, Django 4→5, Python 2→3)
- Dependency replacement (swapping ORMs, HTTP clients, test frameworks)
- Monolith to modular restructuring
- API versioning migrations
- Any transformation touching 20+ files with the same pattern

**When NOT to use:** Small refactors (under 10 files), new feature development, bug fixes.

## Phase 1: Assessment (During Brainstorming)

Before designing the migration, scan and measure:

### Scope Scan

Produce a table:

| Area | Files Affected | Risk Level | Codemod Eligible | Manual Required |
|------|---------------|------------|------------------|-----------------|
| ... | ... | Low/Med/High | Yes/No/Partial | Yes/No |

### Risk Inventory

- What has no tests? Those files are highest risk.
- What touches critical paths (auth, payments, data persistence)?
- What has complex conditional logic that a codemod can't handle?

### Compatibility Check

Can old and new coexist during the migration?
- **Yes:** Use dual implementations, adapter pattern, or feature flags
- **No:** Find a way to make them coexist, or plan for the smallest possible atomic swap

### Codemod Feasibility

Can AST transforms handle the mechanical parts?
- Check for available tools (see Quick Reference below)
- Estimate what percentage can be automated vs manual

## Phase 2: Migration Plan (During Writing-Plans)

Each task in the plan is a migration step, not a feature. Use this template:

```
### Step N: [description]

**Files:** [list of files this step touches]
**Transform:** codemod | manual | hybrid
**Verification:**
- [ ] [specific test command or check]
- [ ] [another verification]
**Rollback:** `git revert <commit>` | [specific undo steps]
**Deploys independently:** yes | no (if no, explain dependency)
```

### Ordering Rules

1. **Lowest risk first** — build confidence, catch tooling issues early
2. **Highest value first** (among equal risk) — deliver benefits sooner
3. **Respect dependency order** — if B imports A, migrate A first
4. **Leaf files first** — files with no internal dependents, work inward

## Phase 3: Execution (During Executing-Plans)

- Use `superpowers:using-git-worktrees` for isolation when appropriate
- **One commit per migration step** — never batch steps together
- **Run full test suite after each step** — not just affected tests
- **Codemods first, manual adjustments second** — mechanical changes are less error-prone
- When old/new must coexist: adapter pattern, feature flags, or dual implementations
- **Don't mix migration with feature work** — keep migrations behavior-preserving

## Quick Reference

| Migration Type | Order | Coexistence Strategy | Codemod Tool |
|---|---|---|---|
| JS → TS | Leaf files first, work inward | `.ts` and `.js` coexist naturally | `ts-migrate`, manual rename |
| React class → functional | Smallest components first | Both patterns coexist | `react-codemod` |
| Go version upgrade | stdlib replacements first, then new features | N/A (compile-time) | `gofmt`, `go fix` |
| Python 2 → 3 | `__future__` imports, then syntax, then stdlib | `six` compatibility layer | `2to3`, `futurize` |
| Django upgrade | Follow release notes order | Deprecation warnings first | N/A |
| Dependency swap | Adapter wrapping old API → swap impl → remove adapter | Adapter pattern | Manual |
| API versioning | New version alongside old → migrate consumers → remove old | Parallel versions | Manual |

## Verification Checklist (Per Step)

After every migration step, all of these must be true:

- [ ] All existing tests pass (not just new/changed ones)
- [ ] No type errors or compile errors
- [ ] Application starts and serves traffic (if applicable)
- [ ] No regressions in critical paths identified during assessment
- [ ] Git history is clean (one logical commit per step)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Big-bang migration ("convert everything at once") | Always incremental, leaf-to-root |
| Skipping the assessment | Run the scope scan before designing steps |
| No rollback plan | Every step must be revertible with `git revert` |
| Testing only changed files | Full test suite after every step |
| Mixing migration with feature work | Keep migrations behavior-preserving; features are separate PRs |
| Spending too long on codemods | If a codemod takes longer to build than manual migration, do it manually |

## Integration

- **Called during:** `superpowers:brainstorming` (assessment), `superpowers:writing-plans` (plan structure)
- **Pairs with:** `superpowers:using-git-worktrees` (isolation), `superpowers:subagent-driven-development` (parallel execution), `toolkit:review-calibration` (review severity)
