require 'lib.definitions'

local lib = package.user.lib
local is = lib.is
local fs = lib.fs
local list = lib.list
local nvim = {}
local Result = lib.Result
local Ok = lib.Ok
local Err = lib.Err

nvim.fnamemodify = vim.fn.fnamemodify
nvim.fname = {}

---@param s string
---@param no_suffix? boolean
---@param as_list? boolean
---@return string
function nvim.fname.expand(s, no_suffix, as_list)
  return vim.fn.expand(s, no_suffix, as_list)
end

---@param file string
---@param rest string Rest of the mods
---@return string
function nvim.fname.abspath(file, rest)
  return nvim.fnamemodify(file, ':p' .. (rest or ''))
end

---@param file string
---@param rest string Rest of the mods
---@return string
function nvim.fname.head(file, rest)
  return nvim.fnamemodify(file, ':h' .. (rest or ''))
end

---@param file string
---@param rest string Rest of the mods
---@return string
function nvim.fname.extension(file, rest)
  return nvim.fnamemodify(file, ':e' .. (rest or ''))
end

---@param file string
---@param rest string Rest of the mods
---@return string
function nvim.fname.root(file, rest)
  return nvim.fnamemodify(file, ':r' .. (rest or ''))
end

---@param file string
---@param rest string Rest of the mods
---@return string
function nvim.fname.relpath(file, rest)
  return nvim.fnamemodify(file, ':.' .. (rest or ''))
end

---@param file string
---@param rest string Rest of the mods
---@return string
function nvim.fname.relhomepath(file, rest)
  return nvim.fnamemodify(file, ':~' .. (rest or ''))
end

---@param keys string
---@param mode? string
---@param replace_termcodes? boolean
function nvim.feedkeys(keys, mode, replace_termcodes)
  mode = mode or 'm'
  replace_termcodes = (replace_termcodes == nil and true) or replace_termcodes
  vim.api.nvim_feedkeys(keys, mode, replace_termcodes)
end

---@param special? boolean
---@return string
function nvim.replace_termcodes(s, special)
  return vim.api.nvim_replace_termcodes(s, true, false, special)
end

---Run ex string with `normal!`
---@param ... string
---@return boolean, string?
function nvim.normal(...)
  for _, cmd in ipairs({ ... }) do
    local ok, msg = pcall(vim.cmd, 'normal! ' .. nvim.replace_termcodes(cmd))
    if not ok then return false, msg end
  end

  return true, nil
end

function nvim.noh()
  vim.cmd ':noh'
end

function nvim.goto_next_search()
  nvim.normal 'n'
end

function nvim.goto_prev_search()
  nvim.normal 'N'
end

---@param as_list? boolean
---@return (string|string[])?
function nvim.region(as_list)
  local esc = nvim.replace_termcodes("<esc>", true, false, true)
  nvim.feedkeys(esc, "x", false)
  local vstart = vim.fn.getpos("'<")
  local vend = vim.fn.getpos("'>")
  local ok, _region = pcall(vim.fn.getregion, vstart, vend, vim.empty_dict())

  if not ok then
    return
  elseif as_list then
    return _region
  else
    return list.concat(_region, "\n")
  end
end

---@param s? string (default: Current region)
---@return (Ok<string|string[]> | Err)?
function nvim.eval(s)
  s = s or nvim.region()
  if s then
    ---@type Ok<string|string[]> | Err
    return nvim.load_string(s)
  end
end

---@return (Ok<string|string[]> | Err)?
function nvim.eval_region()
  return nvim.eval(nvim.region())
end

function nvim.mode()
  return vim.fn.mode()
end

function nvim.in_visual_mode()
  local mode = nvim.mode()
  return mode == 'v' or mode == 'V' or mode == ''
end

function nvim.in_normal_mode()
  return nvim.mode() == 'n'
end

---@param s string
---@return Result
function nvim.loadstring(s)
  local fn, msg = loadstring(s)
  if fn then
    return Result(pcall(fn))
  else
    return result.Err(msg)
  end
end

---@param file string
---@return Result
function nvim.loadfile(file)
  if not nvim.is_file(file) then
    errorf("Invalid file %s", file)
  end
  return nvim.loadstring(fs.slurp(file))
end

function nvim.is_file(file)
  return vim.fn.filereadable(file) == 1
end

function nvim.is_dir(file)
  return vim.fn.isdirectory(file) == 1
end

---@param prompt string?
---@param on_input function
---@param on_nothing? function
function nvim.input(prompt, on_input, on_nothing)
  vim.ui.input({ prompt = prompt or '% ' }, function(input)
    if not input then
      return false
    elseif #input > 0 then
      on_input(input)
    elseif on_nothing then
      on_nothing()
    end
  end)
end

function nvim.select(choices, prompt, on_choice, formatter)
  vim.ui.select(
    choices,
    { prompt = prompt, format_item = formatter },
    on_choice
  )
end

---@param ... string
---@return Ok<boolean>|Err
function nvim.cmd(...)
  local cmd = table.concat({ ... }, "\n")
  local res = Result(pcall(vim.api.nvim_exec2, cmd, { output = true }))

  if is.Err(res) then
    ---@cast res Err
    return res
  else
    res = Ok(true)
    ---@cast res Ok<boolean>
    return res
  end
end

---@param ... string
---@return Ok<string>|Err
function nvim.exec(...)
  local cmd = table.concat({ ... }, "\n")
  local res = Result(pcall(vim.api.nvim_exec2, cmd, { output = true }))

  if is.Ok(res) then
    ---@cast res Ok<string>
    return res
  end

  ---@cast res Err
  return res
end

---@param linenum number
---@return boolean, string?
function nvim.goto_linenum(linenum)
  local ok, msg = nvim.cmd('normal! %dG', linenum)
  if ok then
    return true, nil
  else
    return false, msg
  end
end

---@param cmd string
---@param ... any
function nvim.system(cmd, ...)
  cmd = sprintf(cmd, ...)
  vim.cmd(sprintf(":! %s", cmd))
end

nvim.strftime = vim.fn.strftime
nvim.strptime = vim.fn.strptime
nvim.get_region = nvim.region
nvim.get_mode = nvim.mode
nvim.load_file = nvim.loadfile
nvim.load_string = nvim.loadstring
nvim.expand = nvim.fname.expand
nvim.abspath = nvim.fname.abspath
nvim.extension = nvim.fname.extension
nvim.relpath = nvim.fname.relpath
nvim.relhomepath = nvim.fname.relhomepath


return nvim
