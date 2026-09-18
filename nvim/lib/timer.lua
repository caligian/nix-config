local T = require 'lua-utils.type'
local class = T.class
local uv = vim.uv
local result = require 'lua-utils.result'
local Ok, Err = result.Ok, result.Err

---@type {[string]: timer}
package.user.state.timer = package.user.state.timer or {}
local state = package.user.state.timer

---@class timer
---@field name string
---@field timer userdata
---@field callback function
---@field timeout integer
---@field repeat_after integer
---@overload fun(name: string, timeout?: integer, repeat?: integer, callback?: function): timer
local timer = class 'timer'

function timer:initialize(name, timeout, repeat_after, callback)
  self.name = name
  ---@diagnostic disable-next-line
  self.timer = uv.new_timer()
  self.timeout = timeout or 1000
  self.repeat_after = repeat_after or 0
  self.callback = vim.schedule_wrap(callback)
  state[self.name] = self
end

---@return boolean
function timer:start()
  ---@diagnostic disable-next-line
  return self.timer:start(self.timeout, self.repeat_after, self.callback) == 0
end

function timer:is_running()
  if not self.timer then
    return false
  end

  ---@diagnostic disable-next-line
  return self.timer:get_due_in() ~= 0
end

---@return boolean
function timer:again()
  ---@diagnostic disable-next-line
  return self.timer:again()
end

---@return boolean
function timer:stop()
  ---@diagnostic disable-next-line
  return self.timer:stop() == 0
end

return timer
