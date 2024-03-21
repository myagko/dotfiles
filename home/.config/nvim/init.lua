-- Basic config
require("core.lazy")
require("core.configs")
require("core.keymaps")

-- Plugins
require("plugins.lsp")
require("plugins.treesitter")
require("plugins.cmp")
require("plugins.lualine")
require("plugins.cokeline")
require("plugins.nvimtree")
require("mason").setup()
require('gitsigns').setup()
require("nvim-autopairs").setup()
