if vim.g.loaded_nvim_utils then
  return
end

require('lib.definitions')
require('lib.filetype')
require('lib.autocmd')
require('lib.keymap')
require('lib.nvim')
require('lib.project')
require('lib.repl')
require('lib.shell')
require('lib.terminal')
require('lib.timer')
require('lib.buffer')
require('lib.setup')
require('lib.command')

package.user.lib.setup.setup()
vim.g.loaded_nvim_utils = true
