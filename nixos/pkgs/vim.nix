{
  pkgs,
  ...
}:
[
  (pkgs.vim-full.customize {
    name = "vi";
    vimrcConfig.packages.myPlugins = with pkgs.vimPlugins; {
      start = [
        vim-surround
        auto-pairs
        vim-sexp
        vim-suda
        vim-bbye
        vim-easymotion
        rainbow
        vim-mucomplete
        fzf-vim
      ];
    };
    vimrcConfig.customRC = ''
      syntax on

      set nocompatible
      set backspace=indent,eol,start
      set number
      set hidden
      set number
      set relativenumber
      set shiftwidth=4
      set softtabstop=4
      set expandtab
      set autoindent
      set background=dark
      set clipboard=unnamedplus
      set autochdir
      set cursorline
      set mouse=a
      set bg=dark

      let mapleader = "<space>"

      noremap <space>bb :Buffers<CR>
      noremap <space>ff :Files<CR>
      noremap <space>/ :Rg<CR>
      noremap <space>fs :w! %<CR>
      noremap <space>o :setlocal readonly<CR>
      noremap <space>w <C-w>
      noremap <space>tt :tabnew<CR>
      noremap <space>tk :tabclose<CR>
      noremap <space>tn :tabnext<CR>
      noremap <space>tp :tabprev<CR>
      noremap <space>bn :bnext<CR>
      noremap <space>bp :bprev<CR>
      noremap <space>bq :bwipeout!<CR>
      noremap <space>bk :hide<CR>

      autocmd! Filetype nix,lua,sh,bash,perl setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab

      color unokai
    '';
  })
]
