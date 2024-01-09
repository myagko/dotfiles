local M = {}

function M.colorscheme()
	if vim.g.colors_name then
		vim.cmd('hi clear')
	end

	vim.opt.termguicolors = true
	vim.g.colors_name = 'satyr'

	local theme = require('satyr.theme').set_colors(require('satyr.palette'))

	for group, color in pairs(theme) do
		require('satyr.util').highlight(group, color)
	end
end

return M
