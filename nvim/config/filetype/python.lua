return function(ft)
  ---@cast ft filetype
  ft:set_lsp_config('ruff', {
    init_options = {
      settings = {
        configuration = os.getenv("HOME") .. '/ruff.toml',
      }
    }
  })

  ft:set_lsp_config('jedi_language_server', {
    init_options = {
      workspace = {
        extraPaths = {
          os.getenv("HOME") .. "/Repos/common_utils/src",
        }
      }
    },
    settings = {
      workspace = {
        extraPaths = {
          os.getenv("HOME") .. "/Repos/common_utils/src",
        }
      }
    }
  })

  ft:set_repl_config('ipython3', {
    input = {
      file = {
        use = true,
        format = 'load -y %file\r\n',
      },
      cd = 'import os; os.chdir("%s")',
    }
  })
end
