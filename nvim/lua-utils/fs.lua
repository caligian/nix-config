local lfs = require 'lfs'
local lpath = require 'path'
lpath.fs = require 'path.fs'
lpath.env = require 'path.env'
local types = require 'lua-utils.type'
local is = types.is
local as = types.as

---Common path utilities
---When called with arguments, join arguments with '/' and return the path
---@overload fun(...: string): string
local path = {}
path.cd = lfs.chdir
path.chdir = lfs.chdir
path.getcwd = lfs.currentdir
path.lock = lfs.lock
path.mkdir = lfs.mkdir
path.rmdir = lfs.rmdir
path.touch = lfs.touch
path.unlock = lfs.unlock
path.lockdir = lfs.lock_dir
path.abspath = lpath.abs
path.rmtree = lpath.fs.removedirs
path.rm = lpath.fs.remove
path.cp = lpath.fs.copy
path.ln = lpath.fs.symlink
path.symlink = path.ln
path.getenv = lpath.env.get
path.basename = lpath.name

---@param file string
---@return string?
function path.dirname(file)
  local dir = lpath.parent(file)
  if dir ~= '..' or dir ~= '.' then
    return dir
  end
end

function path.join(...)
  local p = table.concat({ ... }, '/')
  p = string.gsub(p, '//+', '/')
  return p
end

function path:__call(...)
  return path.join(...)
end

function path.cp(src, dst)
  local ok, _ = pcall(lfs.link, src, dst, false)
  return ok
end

function path.symlink(src, dst)
  local ok, _ = pcall(lfs.link, src, dst, true)
  return ok
end

function path.exists(p)
  return lfs.attributes(p) ~= nil
end

function path.stat(p)
  return lfs.attributes(p)
end

function path.mtime(p)
  local attrs = path.stat(p)
  if attrs then
    return attrs.modification
  end
end

function path.ctime(p)
  local attrs = path.stat(p)
  if attrs then
    return attrs.change
  end
end

function path.gid(p)
  local attrs = path.stat(p)
  if attrs then
    return attrs.gid
  end
end

function path.dev(p)
  local attrs = path.stat(p)
  if attrs then
    return attrs.dev
  end
end

function path.nlink(p)
  local attrs = path.stat(p)
  if attrs then
    return attrs.nlink
  end
end

function path.size(p)
  local attrs = path.stat(p)
  if attrs then
    return attrs.size
  end
end

function path.mode(p)
  local attrs = path.stat(p)
  if attrs then
    return attrs.mode
  end
end

path.type = path.mode

function path.permissions(p)
  local attrs = path.stat(p)
  if attrs then
    return attrs.permissions
  end
end

path.perms = path.permissions

function path.blksize(p)
  local attrs = path.stat(p)
  if attrs then
    return attrs.blksize
  end
end

function path.blocks(p)
  local attrs = path.stat(p)
  if attrs then
    return attrs.blocks
  end
end

function path.uid(p)
  local attrs = path.stat(p)
  if attrs then
    return attrs.uid
  end
end

function path.atime(p)
  local attrs = path.stat(p)
  if attrs then
    return attrs.access
  end
end

function path.has_mode(p, mode)
  local a = path.stat(p)
  if a then
    return a.mode == mode
  end
end

function path.is_link(p)
  local a = path.stat(p)
  if a then
    return a.mode == "link"
  end
end

path.is_symlink = path.is_link

function path.is_file(p)
  local a = path.stat(p)
  if a then
    return a.mode == "file"
  end
end

function path.is_dir(p)
  local a = path.stat(p)
  if a then
    return a.mode == "directory"
  end
end

function path.is_mount(p)
  local a = path.stat(p)
  if a then
    return a.mode == "mount"
  end
end

---@param dir string
---@param fullname? boolean
---@return string[]
function path.list_files(dir, fullname)
  if not path.is_dir(dir) then
    errorf("Invalid directory %s", dir)
  end

  local files = {}
  local n = 0

  for file in lfs.dir(dir) do
    if file ~= "." and file ~= ".." then
      if fullname then
        files[n + 1] = path.join(dir, file)
      else
        files[n + 1] = file
      end
      n = n + 1
    end
  end

  return files
end

---@alias path.find.filter (fun(x: string): boolean)
---@alias path.find.pattern path.find.filter | string

---@class path.find.opts
---@field hidden? boolean (default: true)
---@field include? string | string[] (default: '.+')
---@field exclude? string | string[] (default: '')
---@field type? string | string[] (default: all) Any of [l]ink, [d]irectory, [f]ile, [m]ount

---@param dir string
---@param opts? path.find.opts
---@return string[]?
function path.match_files(dir, opts)
  local function matches(p, patterns)
    for i = 1, #patterns do
      local check = patterns[i]
      local ok = string.match(p, check) ~= nil

      if ok then
        return true
      end
    end

    return false
  end

  local function is_ok(p, include, exclude, allowed_types, hidden)
    if not path.exists(p) then
      errorf("Invalid file path %s", p)
    elseif not hidden and path.basename(p):match('^%.') then
      return false
    elseif not allowed_types[path.mode(p)] then
      return false
    elseif exclude then
      if matches(p, exclude) then return false end
    elseif include then
      if matches(p, include) then return true end
    end

    return true
  end

  local function as_list(p)
    if type(p) ~= 'table' then
      return { p }
    else
      return p
    end
  end

  opts = opts or {}
  local home = os.getenv("HOME")
  dir = (is.string(dir) and string.gsub(dir, '^~', home)) or dir
  local files = (is.list(dir) and dir) or path.list_files(dir, true)
  local include = as_list(opts.include or '.+')
  local exclude = opts.exclude and as_list(opts.exclude)
  local use_type = as_list(opts.type or { 'l', 'd', 'f', 'm' })
  local valid_types = {
    link = 'link',
    symlink = 'link',
    l = 'link',
    file = 'file',
    f = 'file',
    dir = 'directory',
    directory = 'directory',
    d = 'directory',
    mount = 'mount',
    m = 'mount',
  }
  local allowed_types = {}
  local result = {}
  local n = 0
  local hidden = as.value(opts.hidden)
  hidden = (hidden == nil and true) or hidden

  for _, _type in ipairs(use_type) do
    local name = valid_types[_type]
    if not name then
      errorf("Invalid path type provided: %s", _type)
    else
      allowed_types[name] = true
    end
  end

  for _, file in ipairs(files) do
    if is_ok(file, include, exclude, allowed_types) then
      result[n + 1] = file
      n = n + 1
    end
  end

  return result
end

---Similar to fs.glob but returns a list instead
---@param pattern string
---@return string[]
function path.glob(pattern)
  local files = {}
  for filename, _ in lpath.fs.glob(pattern) do
    files[#files + 1] = filename
  end
  return files
end

---Split path by system separator string
---@param filename string
---@return string[]
function path.split(filename)
  local sep = lpath.root(filename)
  local ps = {}

  if sep == '\\' then
    ps = filename:gsub("\\+", "\\"):split('\\+')
  else
    ps = filename:gsub("/+", "/"):split("/")
  end

  return ps
end

---Return the extension of filename
---@param filename string
---@return string?
function path.extension(filename)
  local filename_len = #filename
  for i = filename_len, 1, -1 do
    local c = filename:sub(i, i)
    if c == '.' then
      return filename:sub(i + 1, filename_len)
    end
  end
end

---Remove the extension and return the file basename
---@param filename string
---@return string?
function path.strip_extension(filename)
  local ext = path.extension(filename)
  if ext then
    local name = path.basename(filename)
    return (name:gsub('[.]' .. ext, ''))
  else
    return path.basename(filename)
  end
end

---@class path.ls.args
---@field parent string
---@field path string
---@field extension string
---@field type string
---@field basename string

---@class path.ls.opts
---@field depth? number (default: -1) When depth is a negative number, go all the way
---@field exit? (fun(context: path.ls.args): boolean) Stop when exit() is true and return the result
---@field each? fun(context: path.ls.args) Run this function
---@field map? (fun(context: path.ls.args): any) Run this function and collect the result
---@field include? string|string[] (default: .*) Include only these files in the result
---@field exclude? string|string[]
---@field hidden? boolean
---@field type? string|string[] Refer to path.list_files.opts.type

---List files recursively
---@param dirname string
---@param opts? path.ls.opts
---@return string[]?
function path.ls(dirname, opts)
  if not path.is_dir(dirname) then
    return
  end

  dirname = string.gsub(dirname, '^~', os.getenv("HOME"))

  local function create_context(filename, filetype)
    return {
      path = filename,
      parent = path.dirname(filename),
      extension = path.extension(filename),
      basename = path.basename(filename),
      type = filetype
    }
  end

  local function list_files(d, _opts)
    _opts = _opts or {}
    local required_depth = _opts.depth
    local current_depth = _opts.current_depth
    local result = _opts.result
    local stop_when = _opts.exit
    local include = _opts.include
    local exclude = _opts.exclude
    local map = _opts.map
    local each = _opts.each
    local _type = opts.type
    local hidden = opts.hidden

    if current_depth == required_depth then
      return
    end

    include = as.list(include or '.*')
    exclude = exclude and as.list(exclude)
    local next_dirs = {}
    result = result or (map and {})
    local files = path.match_files(d, {
      include = include,
      exclude = exclude,
      type = _type,
      hidden = hidden,
    })

    for i = 1, #files do
      local file = files[i]
      local mode = path.type(file)
      local context = create_context(file, mode)

      if each then
        each(context)
      elseif map then
        result[#result + 1] = map(context)
      end

      if path.is_dir(file) then
        next_dirs[#next_dirs + 1] = file
      end
    end

    for i = 1, #next_dirs do
      local dir = next_dirs[i]
      result[#result + 1] = dir

      list_files(dir, {
        include = include,
        exclude = exclude,
        depth = required_depth,
        current_depth = current_depth + 1,
        result = result,
        exit = stop_when,
        map = map,
        each = each,
      })
    end
  end

  opts = opts or {}
  dirname = lpath.abs(dirname)
  local depth = opts.depth or 1
  local exit = opts.exit
  local include = opts.include
  local exclude = opts.exclude
  local result = not opts.each and {}
  local map = opts.map
  local each = opts.each
  local hidden = opts.hidden

  list_files(dirname, {
    depth = depth,
    current_depth = 0,
    result = result,
    exit = exit,
    map = map,
    each = each,
    include = include,
    exclude = exclude,
    hidden = hidden
  })

  return result
end

---Find the directory containing the marker files.
---Traverse backwards into parent directories if markers files are not present
---@param dirname string starting directory
---@param markers string | string[] Marker files, for example, `.git`
---@param depth? number (default: 3) Maximum depth to traverse backwards to
---@return string?
function path.search_parents(dirname, markers, depth, _current_depth)
  dirname = string.gsub(dirname, '^~', os.getenv("HOME"))
  dirname = lpath.abs(dirname)
  _current_depth = _current_depth or 0
  depth = depth or 3
  markers = type(markers) == 'string' and { markers } or markers

  if dirname == '/' then
    return
  elseif _current_depth == depth then
    return
  end

  for i = 1, #markers do
    local check_filename = path(dirname, markers[i])
    if path.exists(check_filename) then
      return dirname
    end
  end

  return path.search_parents(
    path.dirname(dirname),
    markers,
    depth,
    _current_depth + 1
  )
end

---Find the directory containing the marker files
---Traverse forwards into children directories if markers files are not present
---@param dirname string starting directory
---@param markers string | string[] Marker files, for example, `.git`
---@param depth? number (default: 3) Maximum depth to traverse backwards to
---@return string?
function path.search_children(dirname, markers, depth, _current_depth)
  dirname = string.gsub(dirname, '^~', os.getenv("HOME"))
  ---@cast markers string[]
  markers = type(markers) == 'string' and { markers } or markers
  dirname = path.abspath(dirname)
  depth = depth or 3
  _current_depth = _current_depth or 0
  local next_dirs = {}

  if _current_depth == depth then
    return
  end

  for filename, filetype in lpath.fs.dir(dirname) do
    local basename = path.basename(filename)
    for i = 1, #markers do
      if basename == markers[i] then
        return dirname
      elseif filetype == 'dir' then
        next_dirs[#next_dirs + 1] = filename
      end
    end
  end

  for i = 1, #next_dirs do
    local found = path.search_children(
      next_dirs[i], markers,
      depth, _current_depth + 1
    )
    if found then
      return found
    end
  end
end

---Check if directory is a git directory
---@param dirname string
---@return string?
function path.is_git_dir(dirname)
  dirname = string.gsub(dirname, '^~', os.getenv("HOME"))
  dirname = lpath.abs(dirname)
  local check = path(dirname, '.git')
  if path.is_dir(check) then
    return dirname
  end
end

---Find all git directories in directory
---@param dirname string
---@return string[]
function path.git_dirs(dirname, depth)
  dirname = string.gsub(dirname, '^~', os.getenv("HOME"))
  local res = {}
  depth = depth or 4

  local function find(d, current_depth)
    current_depth = current_depth or 0
    if current_depth == depth then
      return
    elseif path.is_git_dir(d) then
      res[#res + 1] = d
    else
      local next_dirs = path.ls(d, { type = 'd' })
      for i = 1, #next_dirs do
        find(next_dirs[i], current_depth + 1)
      end
    end
  end

  find(lpath.abs(dirname), 0)
  return res
end

---@param file string
---@param mode? string (default: 'r')
---@param as_list? boolean
---@return string|string[]
function path.slurp(file, mode, as_list)
  if not path.is_file(file) then
    errorf("Invalid file %s", file)
  end

  local fh = io.open(file, mode or 'r')
  if not fh then
    errorf("Could not read file %s", file)
  end

  local lines = fh:read("*a")
  if as_list then
    return string.split(lines, "\n")
  else
    return lines
  end
end

---@param dst string
---@param s string
---@param mode string
---@return boolean
function path.spit(dst, s, mode)
  mode = mode or 'w'
  local fh = io.open(dst, mode)

  if not fh then
    return false
  else
    fh:write(s)
    return true
  end
end

---Create a path
---@param ... string
---@return string
function path:__call(...)
  return table.concat({ ... }, '/')
end

setmetatable(path, path)
return path
