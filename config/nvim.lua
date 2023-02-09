vim.cmd([[
set encoding=utf-8 fileencodings=utf-8,ucs-bom,gbk,gb18030,big5,euc-jp,latin1
let mapleader = "\<space>"

set nocompatible hidden wrap
set hlsearch incsearch ignorecase smartcase
set backspace=indent,eol,start
set completeopt=menu,menuone,noselect
set noswapfile nobackup nowritebackup
set cindent autoindent smartindent expandtab smarttab
set nu signcolumn=number laststatus=1 mouse=v cursorline
set wildignore+=.bak,*.swp,*.class,*.pyc,*DS_Store*,*.swp,
set updatetime=1000
set autoread autowrite
set ts=4 sw=4 sts=4 scrolloff=3
set statusline=%F\ %h%w%m%r%=%-14.(%l,%c%V%)\ %P

syntax on
filetype plugin indent on
nnoremap <c-c> :q<cr>
nnoremap - :Explore<cr>
for [k, v] in items({"<c-b>": "<left>", "<c-f>": "<right>",
\"<c-a>": "<home>","<c-e>": "<end>", "<c-d>": "<del>"})
    exe "inoremap ".k." ".v | exe "cnoremap ".k." ".v
endfor

inoremap jj <Esc>
nnoremap ; : | vnoremap ; :
nnoremap H ^ | vnoremap H ^
nnoremap L $ | vnoremap L $

nnoremap [q :cnext<cr>
nnoremap ]q :cprevious<cr>
nnoremap \q :cclose<cr>
nnoremap =q :copen<cr>

" Autocmd group
augroup vimrc
    au!
    au FileType javascript,html,vue setlocal sw=2 ts=2 sts=2
    au FileType python nnoremap <leader>b :AsyncRun python %<cr>
    au FileType go nnoremap <leader>b :AsyncRun go run %<cr>
    au FileType json syntax match Comment +\/\/.\+$+
    au FileType qf setlocal nonu
    au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
        \| exe "normal! g'\"" | endif
augroup END

" Basic config
let g:asyncrun_open = 8
nnoremap = :Neoformat<cr>
let g:neoformat_basic_format_align = 1
let g:neoformat_basic_format_trim = 1
let g:neoformat_python_iosrt = {
    \ 'exe': 'isort',
    \ 'args': ['--profile=black'],
    \ }
let g:neoformat_enabled_python = ['isort', 'black']
au FileType python let b:neoformat_run_all_formatters = 1
let g:neoformat_rust_rustfmt = {
    \ 'exe': 'rustfmt',
    \ 'args': ['--emit=stdout', '--edition=2021'],
    \ }

let g:auto_save = 1
let g:netrw_dirhistmax = 0

noremap  <c-j>      :<C-U>call fzf#vim#files('')<CR>
noremap  <c-h>      :<C-U>call fzf#vim#history()<CR>
nnoremap <leader>m  :<C-U>call fzf#vim#marks()<CR>
nnoremap <leader>n  :<C-U>Commands<CR>
nnoremap <leader>t  :<C-U>BTags<CR>
nnoremap <leader>y  :<C-U>Tags<CR>
nnoremap <leader>h  :<C-U>Helptags<CR>
nnoremap <leader>r  y:<C-U><C-R>=printf("Tags %s", expand("<cword>"))<CR>
nnoremap <leader>w  y:<C-U><C-R>=printf("Rg %s", expand("<cword>"))<CR>
nnoremap <leader>s  :<C-U><C-R>=printf("Rg ")<CR>
nnoremap <leader>j  :History:<CR>
let g:fzf_layout = { 'window': 'enew' }
let g:fzf_commits_log_options =  "-200 --color=always"
let g:fzf_preview_window = ['up:80%', 'ctrl-/']

" Custom Scripts
function! CreatePlayGround(fileName)
    let l:directory = expand('~/.config/playground')
    if !isdirectory(l:directory)
        call mkdir(l:directory)
    endif
    let l:ext = fnamemodify(a:fileName, ':e')
    if index(["go", "py"], l:ext) < 0
        echo "Only go,py supported. You typed: ".l:ext
        return
    endif
    exe 'edit '.l:directory.'/'.a:fileName
endfunction
command! -nargs=1 CreatePlayGround call CreatePlayGround(<f-args>)

function! s:GoToWorkspace(directory)
    execute 'cd '.a:directory
    execute 'Files'
    if exists(":CocRestart") | execute 'CocRestart' | endif
endfunction
command! Workspaces call fzf#run(fzf#wrap({
      \ 'source': 'zoxide query -l',
      \ 'sink': function('s:GoToWorkspace'),
      \ 'options': '--prompt "Workspace> " '
      \ }))

command! Lg execute '!tmux popup -d "\#{pane_current_path}" -xC -yC -w99\% -h99\% -E "zsh -i -c lazygit"'


function! ApplyTheme()
    try | colorscheme codedark | catch /.*/ | endtry
    for g in ['Normal', 'EndOfBuffer', 'LineNr', "Directory"]
        exe "hi ".g." ctermbg=NONE guibg=NONE" | endfor
    hi clear CursorLine
    hi CursorLine ctermbg=237 guibg=#386641
    hi LineNr ctermfg=238
    hi SpellBad ctermbg=17
    hi StatusLine ctermbg=58 guibg=#6a994e
    hi StatusLineNC ctermbg=244 guibg=#6d6875
    hi Search ctermbg=240 guibg=#03045e
    hi Visual ctermbg=240 guibg=#03045e
    hi VisualNOS ctermbg=240 guibg=#03045e
    hi PmenuSel ctermbg=22 guibg=#03045e ctermfg=255 guifg=#ffffff
endfunction 
call ApplyTheme()
]])

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
local plugins = {
	{
		"tomasiser/vim-code-dark",
		config = function()
			vim.api.nvim_call_function("ApplyTheme", {})
		end,
	},
	{ "junegunn/fzf" },
	{ "junegunn/fzf.vim" },
	{ "tpope/vim-commentary" },
	{ "tpope/vim-surround" },
	{ "tpope/vim-fugitive" },
	{ "jiangmiao/auto-pairs" },
	{ "907th/vim-auto-save" },
	{ "AndrewRadev/splitjoin.vim" },
	{ "sbdchd/neoformat", cmd = "Neoformat" },
	{ "skywind3000/asyncrun.vim", cmd = "AsyncRun" },
	{
		"gfanto/fzf-lsp.nvim",
		config = function()
			vim.g.fzf_lsp_command_prefix = "Lsp"
			vim.cmd("nnoremap <leader>a :<C-u>LspDiagnostics<CR>")
			require("fzf_lsp").setup({
				override_ui_select = true,
			})
		end,
	},
	{ "nvim-lua/plenary.nvim", lazy = true },
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"rafamadriz/friendly-snippets",
			"hrsh7th/cmp-vsnip",
			"hrsh7th/vim-vsnip",
			-- "hrsh7th/cmp-copilot",
		},
		config = function()
			local has_words_before = function()
				unpack = unpack or table.unpack
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
			end

			local feedkey = function(key, mode)
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
			end

			local cmp = require("cmp")
			cmp.setup({
				snippet = {
					expand = function(args)
						vim.fn["vsnip#anonymous"](args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif vim.fn["vsnip#available"](1) == 1 then
							feedkey("<Plug>(vsnip-expand-or-jump)", "")
						elseif has_words_before() then
							cmp.complete()
						else
							fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function()
						if cmp.visible() then
							cmp.select_prev_item()
						elseif vim.fn["vsnip#jumpable"](-1) == 1 then
							feedkey("<Plug>(vsnip-jump-prev)", "")
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "vsnip" },
					{ name = "copilot" },
				}, { { name = "buffer" } }),
			})
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = { { name = "buffer" } },
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"hrsh7th/nvim-cmp",
		},
		ft = { "python", "go" },
		config = function()
			local lspconfig = require("lspconfig")
			local on_attach = function(client, bufnr)
				vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
				local bufopts = { noremap = true, silent = false, buffer = bufnr }
				vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
				vim.keymap.set("n", "gk", vim.lsp.buf.hover, bufopts)
				vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
				vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, bufopts)
				vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, bufopts)
				vim.keymap.set("n", "ga", vim.lsp.buf.rename, bufopts)
				vim.keymap.set("n", "ge", vim.lsp.buf.code_action, bufopts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
			end

			local lsp_flags = { debounce_text_changes = 150 }
			local cmp_capabilities = require("cmp_nvim_lsp").default_capabilities()
			lspconfig["gopls"].setup({
				on_attach = on_attach,
				flags = lsp_flags,
				capabilities = cmp_capabilities,
			})
			lspconfig["pyright"].setup({
				on_attach = on_attach,
				flags = lsp_flags,
				capabilities = cmp_capabilities,
				settings = {
					python = {
						analysis = {
							reportOptionalSubscript = "none",
							reportGeneralTypeIssues = "none",
							reportOptionalOperand = "warning",
							reportOptionalMemberAccess = "none",
						},
					},
				},
			})
		end,
	},
	{
		"williamboman/mason.nvim",
		lazy = true,
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"jose-elias-alvarez/null-ls.nvim",
			"jay-babu/mason-null-ls.nvim",
		},
		cmd = "Mason",
		config = function()
			require("mason").setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})
			require("mason-lspconfig").setup({
				ensure_installed = { "pyright", "gopls" },
			})
			require("mason-null-ls").setup({
				ensure_installed = { "cspell" },
			})
		end,
	},
}
local lazy_opts = {
	lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
}
require("lazy").setup(plugins, lazy_opts)

