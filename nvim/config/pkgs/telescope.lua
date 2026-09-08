package.plugins.opts.telescope = package.plugins.opts.telescope or {
  defaults = {
    layout_config = {height = 0.3};
    layout_strategy = 'bottom_pane';
    previewer = false;
  },
  pickers = {
    ['*'] = {
      previewer = false;
    };
    oldfiles = {
      previewer = false;
    };
    buffers = {
      show_all_buffers = true,
      sort_lastused = true,
      previewer = false,
      mappings = {
        i = { ["<c-d>"] = "delete_buffer", },
        n = { ["dd"] = "delete_buffer", }
      }
    }
  }
}
require("telescope").setup(package.plugins.opts.telescope)
require('telescope').load_extension('project')
require("telescope").load_extension("file_browser")
