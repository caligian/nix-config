if package.user.loaded_nvim then
  return
end

---@class user.state
local state = package.user.state
state.workspace = state.workspace or {}
state.autocmd = state.autocmd or {}
state.buffer = state.buffer or {}
state.terminal = state.terminal or { id = {}, pid = {} }
state.repl = state.repl or {}
state.command = state.command or {}
state.keymap = state.keymap or {}
state.augroup = state.augroup or {}

---@class user.config
local config = package.user.config
config.filetype = config.filetype or {}
config.keymap = config.keymap or {}
config.autocmd = config.autocmd or {}
config.augroup = config.augroup or {}
config.workspace = config.workspace or { check_depth = 5 }
config.plugins = config.plugins or {}
config.plugins.telescope = {
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
config.buf_opts = {
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

for key, value in pairs(config.buf_opts) do
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
