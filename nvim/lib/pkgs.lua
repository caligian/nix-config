local list = require 'lua-utils.list'
local fs = require 'lua-utils.fs'
local ls = fs.list_files
local each = list.each
local home = os.getenv "HOME"
local pkgs_dir = string.format('%s/.user/nvim/config/pkgs', home)
local pkgs = { opts = {}, }

---Setup all plugins
function pkgs.setup()
  each(ls(pkgs_dir, true), function(file)
    if not (fs.is_file(file) and string.match(file, '%.lua$')) then
      return
    end

    file = fs.basename(file)
    file = string.gsub(file, '%.lua$', '')

    require(string.format('config.pkgs.%s', file))
  end)
end

return pkgs
