user_config = user_config or {
  state = {
    autocmd = {},
    keymap = {},
    workspace = { check_depth = 4, dir = {}, buffer = {} },
    command = {},
  }
}

require('lib.pkgs').setup()
require('lib.project').setup()

require('config.autocmds')
require('config.keymaps')
require('config.commands')

vim.cmd 'color nightfox'
