colorscheme habamax
syntax on
set nocompatible
set noswapfile

" number of columns occupied by a tab
set tabstop=4
" convert tabs to white space
set expandtab
" with for autoindents
set shiftwidth=4
set smarttab
set softtabstop=4
" indent a new line the same amount as the line just typed
set autoindent

" enable line numbers
set number
" enable relative line numbers
set relativenumber

" highlight current cursorline
set cursorline
set incsearch
set scrolloff=999
set ignorecase
set smartcase
set linebreak

" display command line's tab complete options as a menu
set wildmenu
set title
set laststatus=2

" https://learnvimscriptthehardway.stevelosh.com/chapters/17.html
set statusline=%.50f\       " Path to the file
set statusline+=%y\         " Filetype of the file
set statusline+=%=          " Switch to the right side
set statusline+=[%l,%c      " Current line
set statusline+=/           " Separator
set statusline+=%L]         " Total lines

filetype plugin on
" switch on file type detection, with automatic indenting and settings
filetype plugin indent on
