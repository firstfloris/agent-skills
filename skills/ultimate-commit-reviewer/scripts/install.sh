#!/bin/bash
# Install the Ultimate Commit Reviewer hook for Claude Code.
# Creates .claude/hooks/post-commit-review.sh and wires it into .claude/settings.json.
set -euo pipefail

HOOK_DIR=".claude/hooks"
HOOK_FILE="$HOOK_DIR/post-commit-review.sh"
SETTINGS_FILE=".claude/settings.json"

mkdir -p "$HOOK_DIR"

cat > "$HOOK_FILE" << 'HOOKEOF'
#!/bin/bash
# Ultimate Commit Reviewer — spawns parallel review agents after every git commit.
# Agents: docs, dead-code, ui-polish, design-eng, security, deslopify.
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if ! echo "$COMMAND" | grep -q "^git commit"; then
  exit 0
fi

CHANGED_FILES=$(git diff HEAD~1 --name-only 2>/dev/null || echo "")
if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

COMMIT_MSG=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "")
DIFF_STAT=$(git diff HEAD~1 --stat 2>/dev/null || echo "")

# Categorize changed files
SRC_FILES=$(echo "$CHANGED_FILES" | grep "^src/" || true)
UI_FILES=$(echo "$CHANGED_FILES" | grep -E "\.(tsx|css)$" | grep -v "\.spec\.\|\.test\." || true)
TS_FILES=$(echo "$CHANGED_FILES" | grep -E "\.(ts|tsx)$" || true)
API_FILES=$(echo "$CHANGED_FILES" | grep "^src/app/api/" || true)
DOCS_UPDATED=$(echo "$CHANGED_FILES" | grep -E "^(CLAUDE\.md|AGENTS\.md|docs/)" || true)

cat <<HOOK_EOF
POST-COMMIT REVIEW — "$COMMIT_MSG"

Changed files:
$DIFF_STAT

Spawn the following review agents IN PARALLEL using the Agent tool.
Each agent should run in the background. Use model: "opus" for all agents.
Only skip an agent if its file category is empty.

---

HOOK_EOF

# 1. Docs review (skip if docs already updated or no src changes)
if [ -n "$SRC_FILES" ] && [ -z "$DOCS_UPDATED" ]; then
  cat <<'AGENT_EOF'
**AGENT 1 — Documentation Review** (spawn if src/ files changed)
Prompt: Review the git diff from the last commit (`git diff HEAD~1`) and check if CLAUDE.md or AGENTS.md need updating. Look for:
- New/changed page routes, API routes, lib files
- New components or conventions
- CSS/design changes
- New dependencies in package.json
- Deleted/renamed files with stale references
Only update what's actually outdated. Skip minor internal refactors.

AGENT_EOF
fi

# 2. Dead code review
if [ -n "$TS_FILES" ]; then
  cat <<'AGENT_EOF'
**AGENT 2 — Dead Code & Deprecation Review** (spawn if .ts/.tsx files changed)
Prompt: Review the git diff from the last commit (`git diff HEAD~1`). Find and fix:
- Unused imports (imported but never referenced in the file)
- Exports that were removed but are still imported elsewhere
- Commented-out code blocks (delete them — git has history)
- `console.log` left in production code (not console.warn/error)
- Unused variables, functions, or type definitions
- Deprecated API usage or stale TODO comments
Fix all issues directly — don't just report them.

AGENT_EOF
fi

# 3. UI polish review (Jakub Krehel + Vercel guidelines)
if [ -n "$UI_FILES" ]; then
  cat <<'AGENT_EOF'
**AGENT 3 — UI Polish Review** (spawn if .tsx/.css files changed)
Prompt: Review the git diff from the last commit (`git diff HEAD~1`) against these principles:

Jakub Krehel — Details That Make Interfaces Feel Better:
- Text wrapping: headings should use `text-balance` to prevent orphans
- Tabular numbers: dynamic number displays need `tabular-nums`
- Font smoothing: layouts need `antialiased` on body
- Interruptible animations: use transitions, not keyframes for user interactions
- Subtle exits: exit animations should use small values (-12px), not 100%
- Shadows over borders: prefer multi-layer box-shadow over border-color for depth
- Image outlines: images need `outline outline-1 -outline-offset-1 outline-black/10`

Vercel Web Interface Guidelines:
- Keyboard accessibility: onClick on non-interactive elements needs onKeyDown/tabIndex or use button
- Focus indicators: outline-none must have focus-visible:ring replacement
- Hit targets: interactive elements need minimum 44x44px
- Loading states: async handlers need loading/disabled feedback
- Autocomplete: inputs with known types need autoComplete attribute
- Motion preferences: animations need prefers-reduced-motion check
- Semantic HTML: clickable divs/spans should be buttons
- Error/empty states: data fetching needs error state handling
- Contrast: verify WCAG AA (4.5:1 text, 3:1 UI)

Fix issues directly.

AGENT_EOF
fi

# 4. Design engineering review (Emil Kowalski principles)
if [ -n "$UI_FILES" ]; then
  cat <<'AGENT_EOF'
**AGENT 4 — Design Engineering Review** (spawn if .tsx/.css files changed)
Prompt: Review the git diff from the last commit (`git diff HEAD~1`) for design engineering quality:
- Never use `transition: all` or `transition-all` — specify exact properties
- Enter animations should combine scale(0.95) + opacity, never scale(0) alone
- Use ease-out for user interactions, never ease-in (feels sluggish)
- All buttons need :active state (e.g. `active:scale-[0.97]`)
- Popovers/dropdowns should scale from trigger, not center
- Micro-interaction durations: 150-300ms, never >400ms
- New interactive components must have transitions for state changes
- No hard-coded color hex values — use CSS variables or Tailwind theme tokens

Output a markdown table: | Before | After | Why | for each issue found. Fix issues directly.

AGENT_EOF
fi

# 5. Security review
if [ -n "$TS_FILES" ]; then
  cat <<'AGENT_EOF'
**AGENT 5 — Security Review** (spawn if .ts/.tsx files changed)
Prompt: Review the git diff from the last commit (`git diff HEAD~1`) for security vulnerabilities:
- XSS: unescaped user input in JSX, innerHTML usage, unsanitized HTML rendering
- Injection: string concatenation in SQL/GraphQL queries, unsanitized URL params
- Secrets: hardcoded API keys, tokens, passwords, or credentials in source code
- SSRF: user-controlled URLs passed to fetch() on the server side
- Auth: missing authentication checks on API routes, exposed internal endpoints
- Headers: missing security headers (CORS, CSP, X-Frame-Options) on API responses
- Dependencies: known vulnerable patterns (eval, Function constructor, child_process)
- Data exposure: sensitive data in client bundles, localStorage with secrets, verbose error messages

Fix critical issues directly. For medium/low issues, add a comment with the risk.

AGENT_EOF
fi

# 6. Deslopify review
if [ -n "$TS_FILES" ]; then
  cat <<'AGENT_EOF'
**AGENT 6 — Deslopify Review** (spawn if .ts/.tsx files changed)
Prompt: Review the git diff from the last commit (`git diff HEAD~1`) for sloppy patterns:
- useRef-based debounce timers: replace with useEffect + cleanup pattern
- Empty catch blocks that silently swallow errors — add console.warn or proper handling (localStorage try/catch is OK)
- Unnecessary fallback chains on data that is already typed
- Double requestAnimationFrame hacks — find the root cause
- Retry loops without backoff or max attempts
- setInterval without cleanup (missing clearInterval in useEffect return)
- Defensive null checks on values that cannot be null (trust TypeScript types)
- Over-defensive optional chaining on non-optional properties

Fix sloppy patterns directly. Do not touch legitimate patterns (retry with backoff, server-side setInterval with .unref(), toast auto-dismiss timers).

AGENT_EOF
fi

cat <<'HOOK_EOF'
---

IMPORTANT: Spawn ALL applicable agents above in a SINGLE message using the Agent tool.
Set `model: "opus"` and `run_in_background: true` for each.
After all agents complete, summarize what was fixed.
HOOK_EOF

exit 0
HOOKEOF

chmod +x "$HOOK_FILE"
echo "Created $HOOK_FILE"

# Wire up in settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
fi

if grep -q "post-commit-review.sh" "$SETTINGS_FILE" 2>/dev/null; then
  echo "Hook already configured in $SETTINGS_FILE — skipping."
else
  node -e "
    const fs = require('fs');
    const settings = JSON.parse(fs.readFileSync('$SETTINGS_FILE', 'utf8'));
    if (!settings.hooks) settings.hooks = {};
    if (!settings.hooks.PostToolUse) settings.hooks.PostToolUse = [];
    settings.hooks.PostToolUse.push({
      matcher: { tool_name: 'Bash' },
      hooks: [{ type: 'command', command: 'bash .claude/hooks/post-commit-review.sh' }]
    });
    fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(settings, null, 2) + '\n');
  "
  echo "Added PostToolUse hook to $SETTINGS_FILE"
fi

echo ""
echo "Ultimate Commit Reviewer installed successfully!"
echo "After every git commit, Claude will spawn parallel review agents for:"
echo "  1. Documentation updates"
echo "  2. Dead code & deprecation"
echo "  3. UI polish (Jakub Krehel + Vercel guidelines)"
echo "  4. Design engineering (Emil Kowalski principles)"
echo "  5. Security vulnerabilities"
echo "  6. Deslopify (sloppy code patterns)"
