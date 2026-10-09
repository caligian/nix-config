require("telescope").setup {
  defaults = { previewer = false }
}
require('telescope').load_extension('frecency')
require('telescope').load_extension('project')
require("telescope").load_extension("file_browser")
