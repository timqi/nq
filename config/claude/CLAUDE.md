# System Tools

- `gh` - GitHub CLI for accessing GitHub
- `glab` - GitLab CLI for accessing self-hosted GitLab at https://gitlab.fish
- `uv` - Python project and dependency management tool (preferred over pip/poetry/etc.)
- `codex` - OpenAI Codex CLI. Use `codex exec --model gpt-5.4 -c service_tier=fast -c model_reasoning_effort=high "<prompt>"` as a second opinion for analysis, refactoring, code review, and double-checking work when the user asks or when a double-check would be valuable for complex/high-risk changes. Default to `model_reasoning_effort=high`; use `xhigh` only for architecture decisions, security review, or correctness-critical debugging. **Note**: Codex is slow — when running it as a background task, allow extra time (use longer timeouts, e.g. 600000ms) before checking output. Do not assume it has finished quickly. When using Codex via a subagent (Agent tool), the subagent handles its own timeout so this is less of a concern.

# Workflow

- **Plan review with Codex (REQUIRED)**: When you produce a plan (whether in plan mode or when outlining steps before implementation), you MUST use a codex-expert subagent to review it BEFORE presenting the final plan to the user or beginning implementation. Feed the full plan to Codex with `model_reasoning_effort=xhigh` and ask it to critique, identify gaps, suggest improvements, and flag potential issues. Incorporate feedback into the plan. The ONLY exception is trivial single-file changes (< 20 lines). If you skip this step, explain why.

- To read code from GitHub: for a quick look at one or two files, use WebFetch with raw.githubusercontent.com; for deep analysis, clone the repo to ~/go/src/research/claude/ (a scratch space managed by Claude) and read from the filesystem to save tokens.

# Code Quality

- After writing code, list what could break and suggest tests to cover it.
- When there's a bug, start by writing a test that reproduces it, then fix it until the test passes.
- When the user corrects a stable, recurring preference or pattern, add it to the project CLAUDE.md file (if one exists) or the global ~/.claude/CLAUDE.md file. Do not record one-off corrections as permanent rules.
- **Do not modify code unless explicitly asked.** When diagnosing issues or proposing changes, output the solution first and ask whether to apply it before making any edits.
