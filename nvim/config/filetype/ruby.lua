return function(ft)
  ---@cast ft filetype
  ft:set_repl_config('irb', {})
end
