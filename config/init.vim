if get(s:, 'loaded', 0) != 0 | finish | else | let s:loaded = 1 | endif
set encoding=utf-8 fileencodings=utf-8,ucs-bom,gbk,gb18030,big5,euc-jp,latin1
let mapleader = "\<space>"

set nocompatible hidden wrap
set hlsearch incsearch ignorecase smartcase
set backspace=indent,eol,start
set completeopt=menuone,preview,noinsert,noselect
set noswapfile nobackup nowritebackup
set cindent autoindent smartindent expandtab smarttab 
set nu signcolumn=number laststatus=1
set wildignore+=.bak,*.swp,*.class,*.pyc,*DS_Store*,*.swp,*/.Trash/*
set updatetime=1000
set ts=4 sw=4 sts=4
au FileType javascript,html,vue setlocal sw=2 ts=2 sts=2

syntax on
filetype plugin indent on
nnoremap <c-c> :q<cr>
nnoremap - :Explore<cr>
for [k, v] in items({"<c-b>": "<left>", "<c-f>": "<right>",
\"<c-a>": "<home>","<c-e>": "<end>", "<c-d>": "<del>" })
    exe "inoremap ".k." ".v | exe "cnoremap ".k." ".v
endfor

au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal! g'\"" | endif


call plug#begin('~/.config/nvim/plugged')
Plug 'vim-test/vim-test'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
Plug 'easymotion/vim-easymotion'
Plug 'jiangmiao/auto-pairs'
Plug '907th/vim-auto-save'
Plug 'tpope/vim-commentary'
Plug 'sbdchd/neoformat'
nnoremap = :Neoformat<cr>
let g:auto_save = 1
let g:netrw_dirhistmax = 0

Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
nnoremap <c-e>      :<C-U>call fzf#vim#history()<CR>
nnoremap <c-p>      :<C-U>call fzf#vim#files('')<CR>
nnoremap <leader>m  :<C-U>call fzf#vim#marks()<CR>
nnoremap <leader>w  y:<C-U><C-R>=printf("Rg %s", expand("<cword>"))<CR>
nnoremap <leader>s  :<C-U><C-R>=printf("Rg ")<CR>
vnoremap <leader>s  y:<C-U><C-R>=printf("Rg %s", getreg('"'))<CR>
nnoremap <leader>t  :<C-U>BTags<CR>
let g:fzf_layout = { 'window': 'enew' }
let g:fzf_commits_log_options =  "-200 --color=always"
let g:fzf_preview_window = ['up:80%', 'ctrl-/']

if get(g:, "feature_mode", "basic") != "basic"
"## Advanced features ##
Plug 'tomasiser/vim-code-dark'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'antoinemadec/coc-fzf', {'branch': 'release'}
Plug 'honza/vim-snippets'
let g:coc_fzf_preview = 'up:80%'
let g:coc_global_extensions = ["coc-go", "coc-pyright", "coc-snippets"]
nnoremap gd          :<C-u>call CocActionAsync('jumpDefinition')<CR>
nnoremap gt          :<C-u>call CocActionAsync('jumpTypeDefinition')<CR>
nnoremap gi          :<C-u>call CocActionAsync('jumpImplementation')<CR>
nnoremap gr          :<C-u>call CocActionAsync('jumpReferences')<CR>
nnoremap qf          :<C-u>call CocActionAsync('doQuickfix')<CR>
nnoremap K           :<C-u>call CocActionAsync('doHover')<CR>
nnoremap <leader>n   :<C-u>call CocActionAsync('rename')<CR>
nnoremap <leader>a   :<C-u>CocFzfList diagnostics --current-buf<cr>
nnoremap <leader>t   :<C-u>CocList outline<CR>
nnoremap <leader>c   :<C-u>CocList commands<CR>
nnoremap <leader>p   :<C-u>CocFzfListResume<CR>
inoremap <expr><c-j> coc#float#scroll(1)
inoremap <expr><c-k> coc#float#scroll(0)
nnoremap <expr><c-j> coc#float#scroll(1)
nnoremap <expr><c-k> coc#float#scroll(0)
inoremap <expr><c-y> coc#_select_confirm()
inoremap <expr><c-n> pumvisible() ? "\<c-n>" : coc#refresh()

"## Advanced features end ##
endif

call plug#end()

set termguicolors
if get(g:, "feature_mode", "basic") != "basic" |colorscheme codedark |endif
hi Normal ctermbg=NONE guibg=NONE
hi LineNr ctermbg=NONE guibg=NONE ctermfg=241
hi EndOfBuffer ctermbg=NONE guibg=NONE
hi Visual ctermbg=DarkGray
hi Search ctermbg=DarkGray
hi Directory ctermbg=None
