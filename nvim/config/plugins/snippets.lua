local ls = require("luasnip")
local home = os.getenv "HOME"
local templates_dir = string.format('%s/.user/nvim/templates', home)
local kbd = vim.keymap.set

kbd( {"i"}, "<A-/>", function() ls.expand() end, {silent = true})
kbd( {"i", "s"}, "<C-j>", function() ls.jump( 1) end, {silent = true})
kbd( {"i", "s"}, "<C-k>", function() ls.jump(-1) end, {silent = true})

require("luasnip.loaders.from_vscode").lazy_load()
require("luasnip.loaders.from_vscode").lazy_load({ paths = {templates_dir} })
