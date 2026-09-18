return {
  lsp = {
    ruff = {
      init_options = {
        settings = {
          configuration = os.getenv("HOME") .. '/ruff.toml',
        }
      }
    },
    jedi_language_server = {
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
    }
  },
  repl = {
    command = 'ipython',
    input = {
      file = {
        use = true,
        format = 'load -y %s\r\n',
      },
      cd = 'import os; os.chdir("%s")',
    }
  }
}
