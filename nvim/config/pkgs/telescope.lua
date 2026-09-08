require("telescope").setup {
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
require('telescope').load_extension('frecency')
require('telescope').load_extension('project')
require("telescope").load_extension("file_browser")
