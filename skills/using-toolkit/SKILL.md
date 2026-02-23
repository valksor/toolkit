---
name: using-toolkit
description: Use when working in any valksor project - establishes available toolkit skills, commands, and agents across all tech stacks
---

# valksor/toolkit

Personal multi-stack toolkit. One repo for everything: AI skills, commands, agents, shell scripts, and project templates across npm, Go, Kotlin, and more.

## Prerequisites

This toolkit builds on `superpowers`. Install it first if you haven't:
```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

Superpowers provides core workflow skills (`brainstorming`, `writing-plans`, `systematic-debugging`, `test-driven-development`, etc.) that this toolkit's commands reference.

## Available Commands

| Command | Description |
|---------|-------------|
| `/commit` | Create proper git commits for all uncommitted changes |
| `/review-impl` | Calibrated 3-perspective review of code changes |
| `/review-plan` | Calibrated 3-perspective review of a plan document |

## Available Agents

| Agent | Description |
|-------|-------------|
| `toolkit:reviewer-senior-dev` | Calibrated senior developer review (architecture, quality, patterns) |
| `toolkit:reviewer-senior-qa` | Calibrated senior QA review (testability, failure modes, coverage) |
| `toolkit:reviewer-end-user` | Calibrated end-user review (UX, error messages, API clarity) |
| `toolkit:reviewer-user-perspective` | Lightweight verdict on whether a feature is expected from a given user role |

## Available Skills

| Skill | Description |
|-------|-------------|
| `toolkit:using-toolkit` | This file — toolkit overview |
| `toolkit:review-calibration` | Severity classification and anti-hate-loop rules for multi-pass reviews |

## Workflow Integration

For any development task, prefer this order:
1. `superpowers:brainstorming` — design before building
2. `superpowers:writing-plans` → `/review-plan` — review the plan before coding
3. `superpowers:test-driven-development` — RED-GREEN-REFACTOR
4. `/review-impl` — review implementation before shipping
5. `superpowers:verification-before-completion` — evidence before claiming done
6. `/commit` — commit the result

## Structure

```
toolkit/
├── skills/      ← AI skills (you are here)
├── commands/    ← Slash commands
├── agents/      ← Reviewer agents
├── scripts/     ← Standalone shell scripts by stack (coming soon)
└── templates/   ← Project scaffolding templates by stack (coming soon)
```

## Adding New Skills

Skills live in `skills/{skill-name}/SKILL.md`. Follow the `superpowers:writing-skills` skill for format and conventions.
