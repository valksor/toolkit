# Installing valksor/toolkit for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed
- Git
- [superpowers](https://github.com/obra/superpowers) (recommended — install first)

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/valksor/toolkit.git ~/.config/opencode/valksor-toolkit
```

### 2. Symlink skills

```bash
mkdir -p ~/.config/opencode/skills
rm -rf ~/.config/opencode/skills/toolkit
ln -s ~/.config/opencode/valksor-toolkit/skills ~/.config/opencode/skills/toolkit
```

### 3. Restart OpenCode

Verify by asking: "do you have the valksor toolkit?"

## Usage

Load the meta-skill to understand what's available:

```
use skill tool to load toolkit/using-toolkit
```

## Updating

```bash
cd ~/.config/opencode/valksor-toolkit && git pull
```

## Uninstalling

```bash
rm -rf ~/.config/opencode/skills/toolkit
rm -rf ~/.config/opencode/valksor-toolkit
```
