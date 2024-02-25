local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git", "clone", "--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git", "--branch=stable",
		lazypath
	})
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- treesitter
	{ 'nvim-treesitter/nvim-treesitter' },

	-- lsp
	{ 'neovim/nvim-lspconfig' },

	-- cmp
	{ 'hrsh7th/cmp-nvim-lsp' }, { 'hrsh7th/cmp-buffer' },
	{ 'hrsh7th/cmp-path' }, { 'hrsh7th/cmp-cmdline' },
	{ 'hrsh7th/nvim-cmp' }, { 'hrsh7th/cmp-vsnip' },
	{ 'hrsh7th/vim-vsnip' },

	-- mason
	{ 'williamboman/mason.nvim' },

	-- Telescope
	--[[
	{
		'nvim-telescope/telescope.nvim', tag = '0.1.4',
		dependencies = { 'nvim-lua/plenary.nvim' }
	},
	--]]

	-- tree
	{ 'nvim-tree/nvim-tree.lua' },

	-- buffer
	{
		"willothy/nvim-cokeline",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = true
	},

	-- statusline
	{
		'nvim-lualine/lualine.nvim',
		dependencies = { 'linrongbin16/lsp-progress.nvim' }
	},

	-- git signs
	{ 'lewis6991/gitsigns.nvim' },

	-- autopairs
	{
		'windwp/nvim-autopairs',
		event = "InsertEnter",
		opts = {}
	},

	-- colorschemes
	{ dir = '~/.config/nvim/colorschemes/placid' }
})
