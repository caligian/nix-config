if package.user and package.user.lib.setup_done then
  return
end

---@class user
package.user = { setup_done = false }
package.user.lib = require 'lua-utils'

---@class user.state
---@field terminal { id: {[integer]: terminal}, pid: {[integer]: terminal} }
---@field autocmd {[integer]: autocmd}
---@field keymap keymap[]
---@field repl {[string]: {[string]: terminal}}
---@field command command[]
package.user.state = {
  workspace = {},
  autocmd = {},
  buffer = {},
  terminal = { id = {}, pid = {} },
  repl = {},
  command = {},
  keymap = {},
}

---@class user.config
---@field plugins table
---@field workspace {check_depth: integer, markers: string[]|string}
package.user.config = {
  filetype = {},
  keymap = {},
  command = {},
  workspace = {
    check_depth = 5,
  }
}
