require('lib.state').setup()

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
