if package.user.loaded_nvim then
  return
end

---@class user.state
package.user.state.workspace = package.user.state.workspace or {}
package.user.state.autocmd = package.user.state.autocmd or {}
package.user.state.buffer = package.user.state.buffer or {}
package.user.state.terminal = package.user.state.terminal or { id = {}, pid = {} }
package.user.state.repl = package.user.state.repl or {}
package.user.state.command = package.user.state.command or {}
package.user.state.keymap = package.user.state.keymap or {}
package.user.state.augroup = package.user.state.augroup or {}

---@class user.config
package.user.config.filetype = package.user.config.filetype or {}
package.user.config.keymap = package.user.config.keymap or {}
package.user.config.autocmd = package.user.config.autocmd or {}
package.user.config.augroup = package.user.config.augroup or {}
package.user.config.workspace = package.user.config.workspace or { check_depth = 5 }
package.user.config.plugins = package.user.config.plugins or {}
package.user.config.plugins.telescope = package.user.config.plugins.telescope or {
  defaults = {
    layout_config = { height = 0.3 },
    layout_strategy = 'bottom_pane',
    previewer = false,
  },
  pickers = {
    ['*'] = { previewer = false, },
    oldfiles = { previewer = false, },
    find_files = { previewer = false, },
    git_files = { previewer = false, },
    buffers = {
      show_all_buffers = true,
      sort_lastused = true,
      previewer = false,
      mappings = {
        i = { ["<c-d>"] = "delete_buffer", },
        n = { ["dd"] = "delete_buffer", }
      }
    },
    diagnostics = {
      previewer = false,
    }
  },
  extensions = {
    frecency = {
      previewer = false,
    },
    file_browser = {
      previewer = false,
    },
    project = {
      previewer = false,
    }
  }
}
package.user.config.buf_opts = {
  tabstop = 4,
  shiftwidth = 4,
  softtabstop = 4,
  expandtab = true,
  autoindent = true,
  autochdir = false,
  background = 'dark',
  cursorline = false,
  wildmenu = true,
  wildmode = 'longest:full,full',
  number = true,
  relativenumber = true,
  termguicolors = true,
  clipboard = 'unnamedplus',
}

local map = vim.keymap.set
local on = vim.api.nvim_create_autocmd

for key, value in pairs(package.user.config.buf_opts) do
  vim.o[key] = value
end

map('n', '<leader>lf', ':Format<CR>', { desc = "Format buffer" })
on('LspAttach', {
  callback = function(args)
    pcall(function()
      local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
      require("lsp-format").on_attach(client, args.buf)
    end)
  end,
})

if vim.g.neovide then
  vim.o.guifont = "UbuntuMono Nerd Font:h13"
  vim.o.linespace = 0
  vim.g.neovide_scale_factor = 1.0
  vim.g.neovide_padding_top = 0
  vim.g.neovide_padding_bottom = 0
  vim.g.neovide_padding_right = 0
  vim.g.neovide_padding_left = 0
  vim.g.neovide_opacity = 0.98
  vim.g.neovide_normal_opacity = 0.98
  vim.g.neovide_scroll_animation_length = 0.3
  vim.g.neovide_theme = 'auto'
  vim.g.neovide_refresh_rate = 60
  vim.g.neovide_cursor_antialiasing = true
  vim.g.neovide_cursor_vfx_mode = "sonicboom"
  vim.g.neovide_cursor_vfx_opacity = 100.0
end

package.user.loaded_nvim = true
