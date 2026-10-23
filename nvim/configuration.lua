vim.g.clipboard = {
  name = "wl-copy",
  copy = {
    ["+"] = { "wl-copy", "--type", "text/plain" },
    ["*"] = { "wl-copy", "--type", "text/plain" },
  },
  paste = {
    ["+"] = { "wl-paste", "--no-newline" },
    ["*"] = { "wl-paste", "--no-newline" },
  },
  cache_enabled = 1,
}

vim.g.loaded_clipboard_provider = nil
vim.cmd("runtime autoload/provider/clipboard.vim")
vim.opt.clipboard = "unnamedplus"

require('lib')
package.user.lib.setup.setup()
