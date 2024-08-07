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
    { 'nvim-treesitter/nvim-treesitter' },
    { 'neovim/nvim-lspconfig' },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-path' },
    { 'hrsh7th/cmp-cmdline' },
    { 'hrsh7th/nvim-cmp' },
    { 'hrsh7th/cmp-vsnip' },
    { 'hrsh7th/vim-vsnip' },
    { 'williamboman/mason.nvim' },
    { 'nvim-tree/nvim-tree.lua' },
    { "willothy/nvim-cokeline", dependencies = { "nvim-lua/plenary.nvim" }, config = true },
    { 'nvim-lualine/lualine.nvim', dependencies = { 'linrongbin16/lsp-progress.nvim' } },
    { 'lewis6991/gitsigns.nvim' },
    { 'windwp/nvim-autopairs', event = "InsertEnter", opts = {} },
    { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
    { dir = '~/.config/nvim/colorschemes/placid' },
    { dir = '~/.config/nvim/colorschemes/nymph' },
    { dir = '~/.config/nvim/colorschemes/haven' },
    { dir = '~/.config/nvim/colorschemes/gruvbox' }
})
