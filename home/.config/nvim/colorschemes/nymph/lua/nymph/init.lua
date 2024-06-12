local theme = require("nymph.theme")
local palette = require("nymph.palette")
local util = require("nymph.util")

local M = {}

function M.set_colorscheme()
    if vim.g.colors_name then
        vim.cmd('hi clear')
    end

    vim.opt.termguicolors = true
    vim.g.colors_name = 'nymph'

    for group, color in pairs(theme.set_colors(palette)) do
        util.highlight(group, color)
    end
end

return M
