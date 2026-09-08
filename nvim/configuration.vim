" This file exists in case my API breaks. I don't want to keep setting the
" same shit over and over again

function! HideWindowIfPossible()
    if winnr('$') > 1
        silent! hide
    elseif tabpagenr("$") > 1
        silent! tabclose
    else
        echo "Cannot hide the last window"
    endif
endfunction

function! DeleteBufferWindowIfPossible()
  let bufnum = bufnr('%')
  let win_count = winnr('$')
  let tab_count = tabpagenr('$')

  " Prevent deleting the last buffer
  if win_count == 1 && tab_count == 1
    echo "Cannot delete the last buffer"
    return
  endif

  " Delete the buffer (it auto-closes windows)
  silent! execute "bdelete! " . bufnum

  " If we ended up with an empty tab (shouldn't happen with bdelete)
  if winnr('$') == 0 && tab_count > 1
    tabclose
  endif
endfunction

function! DeleteBlankBuffers()
  let buffers = getbufinfo()
  for buf in buffers
    if buf.name == ''
      silent! execute 'bdelete! ' . buf.bufnr
    endif
  endfor
endfunction

set mouse=a
set sw=4
set tabstop=4
set sts=4
set expandtab
set autoindent
set number
set relativenumber

let mapleader = " "
let maplocalleader = "<C-x>"

aunmenu PopUp

au TextYankPost * silent! lua vim.hl.on_yank {higroup='Visual', timeout=100}
au FileType vim,lua,nix,sh,bash,tex,latex,zsh set sw=2 tabstop=2 sts=2 expandtab
au FileType text set textwidth=72
au FileType help noremap <buffer> Q :call HideWindowIfPossible()<CR>
au FileType help noremap <buffer> q :call DeleteBufferWindowIfPossible()<CR>
au FileType netrw execute 'cd ' . expand('%:p')
au BufEnter * if &filetype == 'netrw' | execute 'cd ' . expand('%:p') | endif

nnoremap <C-Up> :resize +5 <CR>
nnoremap <C-Down> :resize -5 <CR>
nnoremap <C-Left> :vertical resize -5 <CR>
nnoremap <C-Right> :vertical resize +5 <CR>

nnoremap <leader>bk :call HideWindowIfPossible()<CR>
nnoremap <leader>bQ :bwipeout %<CR>
nnoremap <leader>bq :call DeleteBufferWindowIfPossible()<CR>
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprev<CR>

nnoremap <leader>fs :w<CR>
nnoremap <leader>fv :w <bar> luafile %<CR>
nnoremap <leader>fV :w <bar> source %<CR>
nnoremap <leader>f. :e .<CR>

nnoremap <C-g> :noh <CR>
nnoremap <C-x>d :!ls -lctrshA <CR>

nnoremap <M-.> :
vnoremap <M-.> :

nnoremap <M-!> :!

nnoremap <RightMouse> <Nop>
inoremap <RightMouse> <Nop>
vnoremap <RightMouse> <Nop>
