# Agent Skills

Skills for Claude Code, installable via [`npx skill`](https://www.npmjs.com/package/skill).

## Install a skill

```bash
SKILL_BASE_URL=https://github.com/firstfloris/agent-skills/tree/main npx skill skills/ultimate-commit-reviewer
```

Then follow the instructions in the skill's `SKILL.md`.

## Available skills

### ultimate-commit-reviewer

Post-commit hook that spawns 6 parallel review agents after every `git commit`:

1. **Documentation Review** — checks if CLAUDE.md/AGENTS.md need updating
2. **Dead Code & Deprecation** — unused imports, console.log, commented code
3. **UI Polish** — Jakub Krehel + Vercel Web Interface Guidelines
4. **Design Engineering** — Emil Kowalski animation/transition principles
5. **Security** — XSS, injection, secrets, SSRF, auth
6. **Deslopify** — sloppy patterns like empty catches, debounce hacks, over-defensive nulls

After installing, run:

```bash
bash .codebuddy/skills/ultimate-commit-reviewer/scripts/install.sh
```
