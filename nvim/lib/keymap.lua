local state = package.user.state.keymap
local fs = require 'lua-utils.fs'
local copy = vim.deepcopy
local dict = require 'lua-utils.dict'
local types = require 'lua-utils.type'
local is = types.is
local as = types.as
local options = require 'lib.options'
local project = require 'lib.project'
local utils = {}

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
---@field [1]? string|string[]
---@field [2]? string
---@field [3]? string|function
---@field [4]? string|keymap.opts

---@alias keymap.specs keymap.spec|keymap.spec[]

---@param mode? string|string[]
---@param lhs string
---@param rhs string|function
---@param opts? string|keymap.opts
function utils.map(mode, lhs, rhs, opts)
  local args = copy { mode, lhs, rhs, opts }
  opts = opts or {}
  opts = is.string(opts) and { desc = opts } or opts
  mode = mode or 'n'
  opts = options.new(opts)
  mode = as.list(mode)
  local kbd_opts = opts / {
    desc = true,
    buffer = true,
    expr = true,
    noremap = true,
    replace_keycodes = true,
    remap = true
  }
  local au_opts = opts / { pattern = true, event = true, filetype = true }
  local ft = opts.filetype
  local use_au = dict.length(au_opts) > 0

  if not use_au then
    vim.keymap.set(mode, lhs, rhs, kbd_opts)
  else
    au_opts.event = ft and 'Filetype' or au_opts.event
    au_opts.pattern = ft or au_opts.pattern or '*.*'
    vim.api.nvim_create_autocmd(au_opts.event, {
      pattern = au_opts.pattern,
      callback = function(args)
        kbd_opts = copy(kbd_opts)
        kbd_opts.buffer = args.buf
        vim.keymap.set(mode, lhs, rhs, kbd_opts)
      end,
    })
  end

  state[#state + 1] = args
end

function utils.define(opts, specs)
  opts = opts or {}
  for i = 1, #specs do
    local spec = specs[i]
    local mode, lhs, rhs, o = unpack(spec)
    o = is.string(o) and { desc = o } or o or {}
    o = copy(o)
    dict.merge(o, opts)
    utils.map(mode, lhs, rhs, o)
  end
end

function utils.buf_map(bufnr, mode, lhs, rhs, opts)
  opts = opts or {}
  opts = copy(is.string(opts) and { desc = opts } or opts)
  opts.buffer = bufnr
  utils.map(mode, lhs, rhs, opts)
end

function utils.buf_define(bufnr, opts, specs)
  opts = copy(opts or {})
  opts.buffer = bufnr
  utils.define(opts, specs)
end

function utils.project_map(mode, lhs, rhs, opts)
  assert(is.callable(rhs), sprintf("rhs: Expected callable, got [%s] %s", type(rhs), rhs))
  local new_rhs = function()
    local buf = vim.fn.bufnr()
    local filename = vim.api.nvim_buf_get_name(buf)
    if not filename:match('^/') then
      return
    else
      local wd = project.find_project_dir(filename)
      rhs(wd or fs.getcwd())
    end
  end
  utils.map(mode, lhs, new_rhs, opts)
end

function utils.project_define(opts, specs)
  for i = 1, #specs do
    if opts then
      specs[i][4] = specs[i][4] or {}
      dict.merge(specs[i][4], opts)
    end
    utils.project_map(unpack(specs[i]))
  end
end

utils.bmap = utils.buf_map
utils.pmap = utils.project_map
utils.bdefine = utils.buf_define
utils.pdefine = utils.project_define

return utils
