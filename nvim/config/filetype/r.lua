return function(ft)
  ---@cast ft filetype
  ft:set_repl_config('R', {})
  ft:set_opts { shiftwidth = 2, tabstop = 2, expandtab = true }
  ft:set_vars { r_indent_align_args = 1 }
end
