# Installing valksor/toolkit for Codex

## Prerequisites

- Git
- [superpowers](https://github.com/obra/superpowers) (recommended — install first)

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/valksor/toolkit.git ~/.codex/valksor-toolkit
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/valksor-toolkit/skills ~/.agents/skills/toolkit
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\toolkit" "$env:USERPROFILE\.codex\valksor-toolkit\skills"
   ```

3. **Restart Codex** to discover the skills.

## Verify

```bash
ls -la ~/.agents/skills/toolkit
```

## Updating

```bash
cd ~/.codex/valksor-toolkit && git pull
```

## Uninstalling

```bash
rm ~/.agents/skills/toolkit
rm -rf ~/.codex/valksor-toolkit
```
