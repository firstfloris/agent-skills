---
name: ultimate-commit-reviewer
description: Install a post-commit review hook that automatically spawns parallel review agents after every git commit. Use when setting up a new project, onboarding a teammate, or when someone asks to "install commit review", "set up post-commit hook", "add commit review agents", or "install review hook". Reviews commits for documentation staleness, dead code, UI polish, design engineering, security vulnerabilities, and sloppy patterns.
---

# Ultimate Commit Reviewer

Install a Claude Code post-commit hook that spawns up to 6 parallel review agents after every `git commit`. Each agent reviews the diff for a specific concern and fixes issues directly.

## Agents

| # | Agent | Triggers on | What it checks |
|---|-------|-------------|----------------|
| 1 | Documentation Review | `src/` changes (no docs updated) | CLAUDE.md/AGENTS.md staleness |
| 2 | Dead Code & Deprecation | `.ts/.tsx` changes | Unused imports, console.log, commented code |
| 3 | UI Polish | `.tsx/.css` changes | Jakub Krehel + Vercel Web Interface Guidelines |
| 4 | Design Engineering | `.tsx/.css` changes | Animation, transitions, active states, design tokens |
| 5 | Security | `.ts/.tsx` changes | XSS, injection, secrets, SSRF, auth, data exposure |
| 6 | Deslopify | `.ts/.tsx` changes | Sloppy timers, empty catches, over-defensive nulls |

## Installation

Run the install script from the skill directory:

```bash
bash .codebuddy/skills/ultimate-commit-reviewer/scripts/install.sh
```

This does two things:

1. Creates `.claude/hooks/post-commit-review.sh` with the hook script
2. Adds a `PostToolUse` entry to `.claude/settings.json` that triggers on `Bash` tool calls matching `git commit`

## How It Works

After every `git commit`, the hook:

1. Detects changed files and categorizes them (src, UI, TypeScript, API)
2. Outputs instructions for Claude to spawn the applicable review agents
3. Each agent runs in the background with `model: "opus"`
4. Agents fix issues directly and report what changed

## Customization

Edit `.claude/hooks/post-commit-review.sh` to:
- Add or remove review agents
- Change file category patterns (e.g. `src/` prefix, file extensions)
- Adjust review criteria per agent
- Add project-specific rules (e.g. brand constraints, framework conventions)

## Uninstall

Delete `.claude/hooks/post-commit-review.sh` and remove the `PostToolUse` entry from `.claude/settings.json`.
