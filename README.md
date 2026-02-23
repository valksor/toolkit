# valksor/toolkit

Personal multi-stack toolkit. One repo for AI skills, shell scripts, and project templates across npm, Go, Kotlin, and whatever comes next.

Builds on [superpowers](https://github.com/obra/superpowers) — install that first.

## Install (Claude Code)

```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace

/plugin marketplace add valksor/toolkit
/plugin install toolkit@valksor/toolkit
```

## Install (Codex)

See [.codex/INSTALL.md](.codex/INSTALL.md)

## Install (OpenCode)

See [.opencode/INSTALL.md](.opencode/INSTALL.md)

## Structure

```
toolkit/
├── skills/      ← AI skills (cross-platform)
├── scripts/     ← Shell scripts by stack (npm/, go/, kotlin/, ...)
└── templates/   ← Project scaffolding by stack
```

## Update

```
/plugin update toolkit
```
