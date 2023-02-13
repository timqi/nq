vim.g.mapleader = " "
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.swapfile = false
vim.o.writebackup = false
vim.o.nu = true
vim.o.signcolumn = "number"
vim.o.laststatus = 1
vim.o.mouse = "v"
vim.o.cursorline = true
vim.o.smartindent = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.scrolloff = 3
vim.o.statusline = "%F %h%w%m%r%=%-14.(%l,%c%V%) %P"
vim.opt.completeopt = { "menu", "preview", "menuone", "noselect" }

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

function general_theme()
	vim.cmd("colorscheme habamax")
	local hl = vim.api.nvim_set_hl
	hl(0, "Normal", { ctermbg = "NONE", bg = "NONE" })
	hl(0, "NormalFloat", { ctermbg = "NONE", bg = "NONE" })
	hl(0, "EndOfBuffer", { ctermbg = "NONE", bg = "NONE" })
	hl(0, "Directory", { ctermbg = "NONE", bg = "NONE" })
	hl(0, "CursorLine", { ctermbg = 237, bg = "#386641" })
	hl(0, "LineNr", { ctermfg = 237, ctermbg = "NONE", fg = "#386641" })
	hl(0, "SpellBad", { ctermbg = 17, bg = "#959595" })
	hl(0, "StatusLine", { ctermbg = 58, bg = "#6a994e" })
	hl(0, "StatusLineNC", { ctermbg = 244, bg = "#6d6875" })
	hl(0, "Search", { ctermbg = 240, bg = "#03045e" })
	hl(0, "Visual", { ctermbg = 240, bg = "#03045e" })
	hl(0, "VisualNOS", { ctermbg = 240, bg = "#03045e" })
	hl(0, "PmenuSel", { ctermbg = 22, ctermfg = 255, bg = "#03045e", fg = "#ffffff" })
end
general_theme()
local plugins = {
	{ "AndrewRadev/splitjoin.vim", event = "VeryLazy" },
	-- {
	-- 	"Mofiqul/vscode.nvim",
	-- 	config = function()
	-- 		require("vscode").setup({})
	-- 		general_theme()
	-- 	end,
	-- },
	{
		"numToStr/Comment.nvim",
		event = "VeryLazy",
		config = function()
			require("Comment").setup()
		end,
	},
	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},
	{
		"windwp/nvim-autopairs",
		event = "VeryLazy",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	},
	{
		"skywind3000/asyncrun.vim",
		cmd = "AsyncRun",
		config = function()
			vim.g.asyncrun_open = 8
		end,
	},
	{
		"ibhagwan/fzf-lua",
		event = "VeryLazy",
		config = function()
			local fzf = require("fzf-lua")
			fzf.register_ui_select()
			local bufopts = { noremap = true, silent = false, buffer = bufnr }
			vim.keymap.set({ "n", "i" }, "<c-j>", fzf.files, bufopts)
			vim.keymap.set({ "n", "i" }, "<c-h>", fzf.oldfiles, bufopts)
			vim.keymap.set("n", "<leader>s", fzf.grep, bufopts)
			vim.keymap.set("n", "<leader>w", fzf.grep_cword, bufopts)
			vim.keymap.set("v", "<leader>w", fzf.grep_visual, bufopts)
			vim.keymap.set("n", "<leader>h", fzf.help_tags, bufopts)
			vim.keymap.set("n", "<leader>p", fzf.resume, bufopts)
			vim.keymap.set("n", "<leader>/", fzf.search_history, bufopts)
			vim.keymap.set("n", "<leader>m", fzf.marks, bufopts)
			vim.keymap.set("n", "<leader>t", fzf.btags, bufopts)
			vim.keymap.set("n", "<leader>r", fzf.tags_grep_cword, bufopts)

			fzf.setup({
				winopts = {
					fullscreen = true,
					border = false,
					preview = {
						default = "bat",
						border = "border",
						wrap = "wrap",
						vertical = "up:80%",
						layout = "vertical",
						winopts = { number = false },
					},
					hl = {
						FzfLuaNormal = "Normal",
						FzfLuaNormal = "Normal",
					},
				},
				fzf_opts = {
					["--layout"] = "default",
				},
				previewers = {
					bat = { args = "-p --color always" },
				},
				files = {
					previewer = false,
				},
				oldfiles = {
					previewer = false,
				},
			})

			vim.api.nvim_create_user_command("Workspace", function()
				fzf.fzf_exec("zoxide query -l", {
					prompt = "Workspace> ",
					actions = {
						["default"] = function(selected)
							vim.cmd("cd " .. selected[1])
							fzf.files()
						end,
					},
				})
			end, {})

			vim.api.nvim_create_user_command("Playground", function()
				local CREATE_NEW = "::CREATE NEW GROUP"
				local d = vim.fn.expand("~/.config/playground")
				if not vim.fn.isdirectory(d) then
					vim.fn.mkdir(d)
				end
				fzf.fzf_exec(function(fzf_ob)
					fzf_ob(fzf.utils.ansi_codes.magenta(CREATE_NEW))
					local dd = vim.fn.glob(d .. "/*")
					for s in dd:gmatch("[^\r\n]+") do
						fzf_ob(vim.fn.fnamemodify(s, ":t"))
					end
				end, {
					actions = {
						["default"] = function(selected)
							if CREATE_NEW ~= selected[1] then
								vim.cmd("e " .. d .. "/" .. selected[1])
								return
							end
							local ok, res = pcall(vim.fn.input, "New playground name: ", "")
							if ok then
								vim.cmd("e " .. d .. "/" .. res)
							end
						end,
					},
				})
			end, {})
		end,
	},
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
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
					["<S-up>"] = cmp.mapping.scroll_docs(-4),
					["<S-down>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif has_words_before() then
							cmp.complete()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function()
						if cmp.visible() then
							cmp.select_prev_item()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "copilot" },
				}, { { name = "buffer" } }),
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"hrsh7th/nvim-cmp",
		},
		event = "VeryLazy",
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
				vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, bufopts)
				vim.keymap.set("n", "ga", vim.lsp.buf.rename, bufopts)
				vim.keymap.set("n", "ge", vim.lsp.buf.code_action, bufopts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
				vim.keymap.set({ "i", "n" }, "<c-p>", vim.lsp.buf.signature_help, bufopts)
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
		"mhartington/formatter.nvim",
		event = "VeryLazy",
		config = function()
			require("formatter").setup({
				filetype = {
					python = {
						{ exe = "isort", args = { "-q", "--profile=black", "-" }, stdin = true },
						require("formatter.filetypes.python").black,
					},
					rust = { { exe = "rustfmt", args = { "--emit=stdout", "--edition=2021" }, stdin = true } },
					go = { require("formatter.filetypes.go").gofmt },
					lua = { require("formatter.filetypes.lua").stylua },
					["*"] = { require("formatter.filetypes.any").remove_trailing_whitespace },
				},
			})
			vim.keymap.set("n", "=", ":FormatWrite<CR>", { noremap = true, silent = false })
		end,
	},
	{
		"williamboman/mason.nvim",
		event = "VeryLazy",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			require("mason").setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
					border = "rounded",
				},
			})
			require("mason-lspconfig").setup({
				ensure_installed = { "pyright", "gopls" },
			})
		end,
	},
}
local lazy_opts = {
	lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
	concurrency = 20,
	install = { missing = false },
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"tarPlugin",
				"tutor",
				"zipPlugin",
			},
		},
	},
	ui = { border = "rounded" },
}
require("lazy").setup(plugins, lazy_opts)

for from, to in pairs({
	["<C-c>"] = ":q<CR>",
	["-"] = ":Explore<CR>",
	["[q"] = ":cnext<CR>",
	["]q"] = ":cprevious<CR>",
}) do
	vim.keymap.set("n", from, to, {})
end

for from, to in pairs({
	["<C-b>"] = "<left>",
	["<C-f>"] = "<right>",
	["<C-a>"] = "<home>",
	["<C-e>"] = "<end>",
	["<C-d>"] = "<del>",
}) do
	vim.keymap.set({ "i", "c" }, from, to, {})
end

vim.api.nvim_create_user_command(
	"Lg",
	[[execute '!tmux popup -d "\#{pane_current_path}" -xC -yC -w99\% -h99\% -E "zsh -i -c lazygit"']],
	{}
)

local augroup = vim.api.nvim_create_augroup("nvimlua", {})
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = { "python" },
	command = [[
		nnoremap <leader>b :AsyncRun python %
		let b:neoformat_run_all_formatters = 1
	]],
})
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = { "go" },
	command = "nnoremap <leader>b :AsyncRun go run % ",
})
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = { "javascript", "html", "vue" },
	command = "setlocal sw=2 ts=2 sts=2",
})
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = { "qf" },
	command = "set nonu",
})
vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
	group = augroup,
	command = [[
		if (bufname() != "" && &buftype == "" && &filetype != "" && &readonly == 0)
			write
		endif
	]],
})
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup,
	command = [[if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g'\"" | endif]],
})
