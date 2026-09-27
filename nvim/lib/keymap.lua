require 'lib.definitions'

local lib = package.user.lib
local state = package.user.state.keymap
local fs = lib.fs
local copy = vim.deepcopy
local dict = lib.dict
local union = lib.union
local is = lib.is
local as = lib.as
local options = require 'lib.options'
local project = require 'lib.project'
local kbd = {
  validator = {
    union(is.string, is.list),
    is.string,
    union(is.callable, is.string),
    union(is.string, is.table)
  }
}
local assert_spec = lib.assert.spec

---@class keymap.opts
---@field desc? string
---@field buffer? number
---@field pattern? string|string[]
---@field event? string|string[]
---@field filetype? string|string[]
---@field expr? boolean
---@field noremap? boolean
---@field replace_keycodes? boolean
---@field remap? boolean

---@class keymap.spec
---@field [1] string|string[]
---@field [2] string
---@field [3] string|function
---@field [4]? string|keymap.opts

---@alias keymap.specs keymap.spec|keymap.spec[]

---@param mode? string|string[]
---@param lhs string
---@param rhs string|function
---@param opts? string|keymap.opts
function kbd.map(mode, lhs, rhs, opts)
  local args = copy { mode, lhs, rhs, opts }
  opts = opts or {}
  opts = is.string(opts) and { desc = opts } or opts
  mode = mode or 'n'
  opts = options.new(opts)
  mode = as.list(mode)
  local kbd_opts = {
    desc = opts.desc,
    buffer = opts.buffer,
    expr = opts.expr,
    noremap = opts.noremap,
    replace_keycodes = opts.replace_keycodes,
    remap = opts.remap
  }
  local au_opts = {
    pattern = opts.pattern,
    event = opts.event,
    filetype = opts.filetype,
  }
  local ft = opts.filetype
  local use_au = dict.length(au_opts) > 0

  if not use_au then
    vim.keymap.set(mode, lhs, rhs, kbd_opts)
  else
    au_opts.event = ft and 'Filetype' or au_opts.event
    au_opts.pattern = ft or au_opts.pattern or '*.*'

    vim.api.nvim_create_autocmd(au_opts.event, {
      pattern = au_opts.pattern,
      callback = function(_)
        kbd_opts = copy(kbd_opts)
        kbd_opts.buffer = _.buf
        vim.keymap.set(mode, lhs, rhs, kbd_opts)
      end,
    })
  end

  state[#state + 1] = args
end

function kbd.define(opts, specs)
  opts = opts or {}
  for i = 1, #specs do
    local spec = specs[i]
    local mode, lhs, rhs, o = unpack(spec)
    o = is.string(o) and { desc = o } or o or {}
    o = copy(o)
    dict.merge(o, opts)
    kbd.map(mode, lhs, rhs, o)
  end
end

function kbd.buf_map(bufnr, mode, lhs, rhs, opts)
  opts = opts or {}
  opts = copy(is.string(opts) and { desc = opts } or opts)
  opts.buffer = bufnr
  kbd.map(mode, lhs, rhs, opts)
end

function kbd.buf_define(bufnr, opts, specs)
  opts = copy(opts or {})
  opts.buffer = bufnr
  kbd.define(opts, specs)
end

function kbd.project_map(mode, lhs, rhs, opts)
  assert(is.callable(rhs), sprintf("rhs: Expected callable, got [%s] %s", type(rhs), rhs))
  return kbd.map(mode, lhs, function()
    local buf = vim.fn.bufnr()
    local filename = vim.api.nvim_buf_get_name(buf)

    if not filename:match('^/') then
      return
    else
      local wd = project.find_project_dir(filename)
      rhs(wd or fs.getcwd())
    end
  end, opts)
end

function kbd.project_define(opts, specs)
  for i = 1, #specs do
    if opts then
      specs[i][4] = specs[i][4] or {}
      dict.merge(specs[i][4], opts)
    end
    kbd.project_map(unpack(specs[i]))
  end
end

---@param spec keymap.spec
---@return boolean
function kbd.isa_config(spec)
  assert_spec(spec, kbd.validator)
  return true
end

kbd.bmap = kbd.buf_map
kbd.pmap = kbd.project_map
kbd.bdefine = kbd.buf_define
kbd.pdefine = kbd.project_define
kbd.new = kbd.map

return kbd
