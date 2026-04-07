# System Tools

- `gh` - GitHub CLI for accessing GitHub
- `glab` - GitLab CLI for accessing self-hosted GitLab at https://gitlab.fish
- `uv` - Python project and dependency management tool (preferred over pip/poetry/etc.)
- `codex` - OpenAI Codex CLI, used via `codex-expert` subagent for second opinions on analysis, refactoring, code review, and double-checking complex/high-risk changes. See `agents/codex-expert.md` for invocation details and workflows.
- `wt` - Worktrunk CLI for git worktree management (preferred over raw `git worktree` commands). Use `wt switch -c <branch>` to create, `wt list` to show, `wt merge`/`wt remove` to clean up.

# Workflow

- **Plan review with Codex**: Use a codex-expert subagent to review your plan BEFORE presenting it or beginning implementation when the change involves: security, data integrity, architectural decisions, or non-trivial cross-cutting behavior changes. Ask it to critique, identify gaps, and flag issues. Incorporate feedback. Skip for mechanical changes (renames, import updates, formatting) and single-purpose edits with clear intent. If you skip, explain why.

- To read code from GitHub: for a quick look at one or two files, use WebFetch with raw.githubusercontent.com; for deep analysis, clone the repo to ~/code/ref/claude/ and read from the filesystem to save tokens. If the repo already exists locally, run `git pull` first to ensure the code is up to date.

# Communication Style

- Lead with the answer. Skip preamble, filler, and disclaimers.
- Don't repeat the question back. Just answer it.
- If the user asks a yes/no question, start with yes or no.
- Keep explanations concise — focus on key results, keep process details minimal.
- Research thoroughly before concluding, but report findings briefly.
- **English coaching**: The user's native language is Chinese. When the user writes in English, start with a one-line grammar/vocabulary correction (focus on articles, prepositions, tense, plurals). Skip if flawless or message is in Chinese. Ignore capitalization.

# Code Quality

- After writing code, list what could break and suggest tests to cover it.
- When there's a bug, start by writing a test that reproduces it, then fix it until the test passes.
- When the user corrects a stable, recurring preference or pattern, add it to the project CLAUDE.md file (if one exists). Do not record one-off corrections as permanent rules.
- **Propose before modifying — never edit code without explicit approval.** When diagnosing issues or proposing changes, always present the solution in text first and wait for the user to approve before making any edits. This approval gate applies every time the direction changes:
  1. If the user's approval message contains a new idea, alternative approach, or revised direction, treat it as a NEW proposal — do NOT carry over the previous approval. Stop, analyze the new approach (pros/cons, affected files, scope of changes), present your analysis, and wait for a second explicit "go ahead" before editing.
  2. Only a clear, unambiguous approval with no new requirements (e.g. "do it", "looks good, apply it") counts as permission to proceed with edits.

# Safety

- Never commit `.env`, credentials, API keys, or secrets. Warn the user if asked to do so.
