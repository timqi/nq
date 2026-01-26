# Vimrc Usage Instructions

## Leader Key

The leader key is `<Space>`.

## General Navigation

| Key | Action |
|-----|--------|
| `Ctrl-c` | Quit current window |
| `-` | Open file explorer (netrw) |
| `j` / `k` | Move by visual line (useful for wrapped lines) |
| `[q` / `]q` | Previous/Next quickfix item |

## Emacs-style Editing (Insert/Command mode)

| Key | Action |
|-----|--------|
| `Ctrl-b` | Move cursor left |
| `Ctrl-f` | Move cursor right |
| `Ctrl-a` | Move to line start |
| `Ctrl-e` | Move to line end |

## Visual Mode

| Key | Action |
|-----|--------|
| `<` / `>` | Indent and keep selection |

## Formatting

| Key | Action |
|-----|--------|
| `=` | Format current file (Neoformat) |

Python files use `isort` + `black` (120 char line length). Rust uses `cargo fmt`.

## Fuzzy Finding (FZF / fzf-lua)

| Key | Action |
|-----|--------|
| `Ctrl-p` | Find files |
| `<Space>p` | Find files |
| `<Space>u` | Recent files |
| `<Space>fb` | Find buffers |
| `<Space>s` | Grep (search text) |
| `<Space>w` | Grep word under cursor |
| `<Space>b` | Grep current buffer |
| `<Space>t` | Tags in current buffer |
| `<Space>y` | All tags |
| `<Space>r` | Grep current tag |
| `<Space>m` | Find marks |
| `<Space>c` | Commands |
| `<Space>n` | FzfLua builtin commands |
| `<Space>h` | Help tags |
| `<Space>j` | Command history |
| `<Space>fk` | Keymaps |

## LSP (Neovim only)

### Navigation

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gi` | Go to implementation |
| `gr` | Go to references |
| `K` | Hover documentation |
| `Ctrl-k` | Signature help |

### Code Actions

| Key | Action |
|-----|--------|
| `<Space>rn` | Rename symbol |
| `<Space>ca` | Code action |
| `<Space>f` | Format file |
| `<Space>D` | Type definition |

### Diagnostics

| Key | Action |
|-----|--------|
| `<Space>e` | Show diagnostic float |
| `[d` / `]d` | Previous/Next diagnostic |
| `<Space>q` | Diagnostic location list |

## Git

| Command | Action |
|---------|--------|
| `:Lg` | Open lazygit in tmux popup |
| `:Git ...` | Fugitive git commands |

## Text Objects (from plugins)

- `i` / `a` variants for quotes, brackets, arguments
- `ii` / `ai` - indent object (select by indentation)
- `gc` - comment operator (e.g., `gcc` comments line)
- `ys`, `cs`, `ds` - surround operations

## Auto Features

- **Auto-save**: Files save automatically on changes
- **Restore cursor**: Opens files at last edit position
- **Auto-install**: Plugins install automatically on first run

## File Type Settings

- JavaScript/HTML/Vue: 2-space indentation
- Python: Runs both isort and black on format

## Plugin Management

### Neovim (lazy.nvim)

```vim
:Lazy          " Open plugin manager
:Lazy sync     " Update plugins
```

### Vim (vim-plug)

```vim
:PlugInstall   " Install plugins
:PlugUpdate    " Update plugins
```

## LSP Servers (auto-installed via Mason)

| Language | Server |
|----------|--------|
| Python | pyright |
| Go | gopls |
| TypeScript/JavaScript | ts_ls |
| Rust | rust_analyzer |
| HTML | html |
| CSS | cssls |
| JSON | jsonls |
