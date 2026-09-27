return function(ft)
  ---@cast ft filetype
  ft:set_repl_config('luajit', {})
  ft:set_opts {
    shiftwidth = 2,
    softtabstop = 2,
    expandtab = true,
  }
end
