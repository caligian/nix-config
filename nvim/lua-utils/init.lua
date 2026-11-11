if vim.g.loaded_lua_utils then
  return
end

vim.g.loaded_lua_utils = true

require 'lua-utils.type'
require 'lua-utils.list'
require 'lua-utils.dict'
require 'lua-utils.fs'
require 'lua-utils.set'
require 'lua-utils.string'
