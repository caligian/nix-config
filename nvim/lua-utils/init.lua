if vim.g.loaded_lua_utils then
  return
else
  vim.g.loaded_lua_utils = true
end

require 'lua-utils.type'
require 'lua-utils.list'
require 'lua-utils.dict'
require 'lua-utils.fs'
require 'lua-utils.set'
require 'lua-utils.string'
require 'lua-utils.template'
