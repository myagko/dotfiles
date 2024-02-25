local M = {}

function M.colorscheme()
	if vim.g.colors_name then
		vim.cmd('hi clear')
	end

	vim.opt.termguicolors = true
	vim.g.colors_name = 'placid'

	local theme = require('placid.theme').set_colors(require('placid.palette'))

	for group, color in pairs(theme) do
		require('placid.util').highlight(group, color)
	end
end

return M
