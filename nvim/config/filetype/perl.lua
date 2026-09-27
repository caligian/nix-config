return function(ft)
  ---@cast ft filetype
  ft:set_opts {
    shiftwidth = 2,
    softtabstop = 2,
    tabstop = 2,
    expandtab = true,
  }
  ft:set_lsp_config('perlpls', {})
  ft:set_lsp_config('perlnavigator', {
    settings = {
      perlnavigator = {
        perlPath = 'perl',
        enableWarnings = true,
        perltidyProfile = '',
        perlcriticProfile = '',
        perlcriticEnabled = true,
      }
    }
  })
end
