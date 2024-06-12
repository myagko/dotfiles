local theme = require("placid.theme")
local palette = require("placid.palette")
local util = require("placid.util")

local M = {}

function M.set_colorscheme()
    if vim.g.colors_name then
        vim.cmd('hi clear')
    end

    vim.opt.termguicolors = true
    vim.g.colors_name = 'placid'

    for group, color in pairs(theme.set_colors(palette)) do
        util.highlight(group, color)
    end
end

return M
