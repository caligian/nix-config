local lib = package.user.lib
local list = lib.list
local path = lib.fs
local buffer = require 'lib.buffer'
local nvim = require 'lib.nvim'
local lpeg = vim.lpeg
local P = lpeg.P
local section_pattern = P("\\") * (P("sub") ^ 0) * P("section") * (P("*") ^ -1)
local tex = {}

function tex.change_extension(s, from, to)
  return (string.gsub(s, '%.' .. from .. '$', '.' .. to))
end

function tex.rm_extension(s, from)
  return (string.gsub(s, '%.' .. from .. '$', ''))
end

function tex.run(cmd, ...)
  return nvim.cmd(":! " .. sprintf(cmd, ...))
end

function tex.in_project(file)
  return path.is_dir(dirname(file) .. '/.git')
end

function tex.if_in_project(file, when, unless)
  if tex.in_project(file) then
    return when(file)
  else
    return unless(file)
  end
end

function tex.git_stage()
  vim.cmd('Git stage %')
end

function tex.git_commit()
  vim.cmd(':Git commit')
end

---@param bufname string
---@return string
function tex.get_bib_file(bufname)
  return (bufname:gsub('%.tex$', '.bib'))
end

---@param file string
---@param ext string
---@return string?
function tex.has_file(file, ext)
  file = tex.change_extension(file, 'tex', ext)
  ---@type string
  return (path.is_file(file) and file)
end

---@param file string
---@param dir string
---@return string?
function tex.has_dir(file, dir)
  d = dirname(file)
  local check = d .. '/' .. dir
  ---@type string
  return (path.is_dir(check) and check)
end

function tex.clear(bufname)
  local curdir = vim.fn.getcwd()
  local dir = path.dirname(bufname)
  path.cd(dir)
  vim.cmd('latexmk -C ' .. bufname)
  path.cd(curdir)
end

---Open a tex PDF using xdg-open
---@param bufname string
function tex.open(bufname)
  local app = 'xdg-open'
  local pdf = tex.change_extension(bufname, 'tex', 'pdf')

  if path.is_file(pdf) then
    tex.run(app .. ' ' .. pdf)
  else
    printf("No PDF file exists for %s", bufname)
  end
end

---@param bufname string
function tex.compile(bufname)
  local dir = path.dirname(bufname)
  tex.clear(bufname)
  local pdf = tex.change_extension(bufname, 'tex', 'pdf')
  if path.is_file(pdf) then path.rm(pdf) end
  tex.run('latexmk -pdf -outdir=%s %s', dir, bufname)
end

function tex.wrap(name, ...)
  local args = { ... }
  return function()
    local bufnr = vim.fn.bufnr()
    local bufname = buffer.get_name(bufnr)
    table.insert(args, 1, bufname)
    return tex[name](unpack(args))
  end
end

function tex.normal(cmd, ...)
  nvim.normal(sprintf(cmd, ...))
end

function tex.search_below(pattern)
  buffer.find_below_and_goto(buffer.current(), pattern)
end

function tex.search_above(pattern)
  buffer.find_above_and_goto(buffer.current(), pattern)
end

function tex.search_wrap_above(pattern)
  return function()
    return tex.search_above(pattern)
  end
end

function tex.search_wrap_below(pattern)
  return function()
    return tex.search_below(pattern)
  end
end

function tex.cmd_mark_env()
  vim.cmd('normal! vae')
end

function tex.cmd_mark_cmd()
  vim.cmd('normal! vac')
end

function tex.cmd_clear()
  tex.rm_clear(buffer.get_name(buffer.current()))
end

function tex.cmd_goto_next_section()
  local buf = buffer.current()
  local current_linenum = buffer.get_current_linenum(buf)
  local lc = buffer.get_line_count(buf)

  for i = current_linenum + 1, lc do
    local line = buffer.get_line(buf, i)
    if line then
      if section_pattern:match(line) then
        vim.cmd(string.format('normal! %dG', i + 1))
        return
      end
    end
  end
end

function tex.cmd_goto_prev_section()
  local buf = buffer.current()
  local current_linenum = buffer.get_current_linenum(buf)

  for i = current_linenum - 1, 0, -1 do
    local line = buffer.get_line(buf, i)
    if line then
      if section_pattern:match(line) then
        vim.cmd(string.format('normal! %dG', i + 1))
        return
      end
    end
  end
end

tex.cmd_goto_next_main_section = tex.search_wrap_below "\\section[*]?"
tex.cmd_goto_prev_main_section = tex.search_wrap_above '\\section[*]?'
tex.cmd_goto_next_env = tex.search_wrap_below('\\begin%{')
tex.cmd_goto_prev_env = tex.search_wrap_above('\\begin%{')
tex.cmd_goto_next_item = tex.search_wrap_below('\\item')
tex.cmd_goto_prev_item = tex.search_wrap_above('\\item')
tex.cmd_compile = tex.wrap 'compile'
tex.cmd_open = tex.wrap 'open'

return function(ft)
  ---@cast ft filetype
  ft:set_lsp_config('texlab', {})
  ft:set_opts {
    wrapmargin = 0,
    formatoptions = vim.o.formatoptions .. 't',
    textwidth = 80,
    shiftwidth = 2,
  }
  ft:map('n', '<space>lf', ':echo "Cannot use lsp formatter on latex files."<CR>', { desc = 'Disable LSP formatter' })
  ft:map('n', '<C-t>', '<plug>(vimtex-toc-toggle)', { desc = 'Toggle table of contents' })
  ft:map('n', '<C-z>', '<plug>(vimtex-toc-open)', { desc = 'Open table of contents' })
  ft:map({ 'i', 'v', 'n' }, "<C-M-e>", tex.cmd_goto_next_main_section, { desc = 'Goto next \\section' })
  ft:map({ 'i', 'v', 'n' }, '<C-M-a>', tex.cmd_goto_prev_main_section, { desc = 'Goto prev \\section' })
  ft:map({ 'i', 'v', 'n' }, "<C-M-n>", tex.cmd_goto_next_section, { desc = 'Goto next \\(sub)*section' })
  ft:map({ 'i', 'v', 'n' }, '<C-M-p>', tex.cmd_goto_prev_section, { desc = 'Goto prev \\(sub)*section' })
  ft:map({ 'i', 'v', 'n' }, "<M-e>", tex.cmd_goto_next_env, { desc = 'Goto next env' })
  ft:map({ 'i', 'v', 'n' }, '<M-a>', tex.cmd_goto_prev_env, { desc = 'Goto prev env' })
  ft:map({ 'i', 'v', 'n' }, "<M-f>", tex.cmd_goto_next_item, { desc = 'Goto next item' })
  ft:map({ 'i', 'v', 'n' }, '<M-b>', tex.cmd_goto_prev_item, { desc = 'Goto prev item' })
  ft:map('n', '<leader>cp', tex.cmd_compile, { desc = 'Create PDF' })
  ft:map('n', '<leader>co', tex.cmd_open, { desc = "Open PDF" })
  ft:map('n', '<leader>cr', tex.cmd_clear, { desc = 'Clear everything except .bib and .tex' })
  ft.utils = tex
end
