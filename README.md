# Ultimate Commit Reviewer

A Claude Code hook that spawns 6 parallel review agents after every `git commit`. Each agent reviews your diff for a specific concern and fixes issues directly.

## Install

Copy this into Claude Code:

```
Install the ultimate-commit-reviewer hook in this project. Run these two commands:

1. SKILL_BASE_URL=https://github.com/firstfloris/agent-skills/tree/main npx skill skills/ultimate-commit-reviewer
2. bash .codebuddy/skills/ultimate-commit-reviewer/scripts/install.sh
```

## What it does

After every `git commit`, Claude automatically spawns these review agents in parallel:

| # | Agent | What it checks |
|---|-------|----------------|
| 1 | **Documentation** | CLAUDE.md/AGENTS.md staleness when src/ changes |
| 2 | **Dead Code** | Unused imports, console.log, commented-out code |
| 3 | **UI Polish** | Jakub Krehel + Vercel Web Interface Guidelines |
| 4 | **Design Engineering** | Emil Kowalski animation/transition principles |
| 5 | **Security** | XSS, injection, secrets, SSRF, auth, data exposure |
| 6 | **Deslopify** | Empty catches, debounce hacks, over-defensive nulls |

Each agent only runs when relevant files are changed (e.g. UI agents only trigger on `.tsx`/`.css` files).

## Customize

Edit `.claude/hooks/post-commit-review.sh` to add/remove agents or change review criteria.

## Uninstall

Delete `.claude/hooks/post-commit-review.sh` and remove the `PostToolUse` entry from `.claude/settings.json`.
