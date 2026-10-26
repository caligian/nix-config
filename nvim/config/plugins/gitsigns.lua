require('gitsigns').setup {
  signs = {
    add          = { text = '┃' },
    change       = { text = '┃' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signs_staged = {
    add          = { text = '┃' },
    change       = { text = '┃' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signs_staged_enable = true,
  signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
  numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
  linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
  word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
  watch_gitdir = {
    follow_files = true
  },
  auto_attach = true,
  attach_to_untracked = false,
  current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
    delay = 1000,
    ignore_whitespace = false,
    virt_text_priority = 100,
    use_focus = true,
  },
  current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
  sign_priority = 6,
  update_debounce = 100,
  status_formatter = nil, -- Use default
  max_file_length = 40000, -- Disable if file is longer than this (in lines)
  preview_config = {
    -- Options passed to nvim_open_win
    style = 'minimal',
    relative = 'cursor',
    row = 0,
    col = 1
  },

  on_attach = function(bufnr)
    local gitsigns = require('gitsigns')

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts = type(opts) == 'string' and {desc = opts} or opts
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    map('n', ']c', function() if vim.wo.diff then vim.cmd.normal({']c', bang = true}) else gitsigns.nav_hunk('next') end end, 'Next hunk')
    map('n', '[c', function() if vim.wo.diff then vim.cmd.normal({'[c', bang = true}) else gitsigns.nav_hunk('prev') end end, 'Previous hunk')
    map('n', '<space>ghs', gitsigns.stage_hunk, 'Stage hunk')
    map('n', '<space>ghr', gitsigns.reset_hunk, 'Reset hunk')
    map('v', '<space>ghs', function() gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, 'Stage hunk (current line)')
    map('v', '<space>ghr', function() gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, 'Stage reset (current line)')
    map('n', '<space>ghS', gitsigns.stage_buffer, 'Stage buffer')
    map('n', '<space>ghR', gitsigns.reset_buffer, 'Reset buffer')
    map('n', '<space>ghp', gitsigns.preview_hunk, 'Preview hunk')
    map('n', '<space>ghi', gitsigns.preview_hunk_inline, 'Preview hunk (inline)')
    map('n', '<space>ghb', function() gitsigns.blame_line({ full = true }) end, 'Blame line')
    map('n', '<space>ghd', gitsigns.diffthis, 'Diffthis')
    map('n', '<space>ghD', function() gitsigns.diffthis('~') end, 'Diffthis (~)')
    map('n', '<space>ghQ', function() gitsigns.setqflist('all') end, 'Set qflist (all)')
    map('n', '<space>ghq', gitsigns.setqflist, 'Set qflist')
    map({'o', 'x'}, 'ih', gitsigns.select_hunk, 'Select hunk')
  end
}
