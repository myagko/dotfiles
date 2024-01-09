local M = {}

function M.colorscheme()
	if vim.g.colors_name then
		vim.cmd('hi clear')
	end

	vim.opt.termguicolors = true
	vim.g.colors_name = 'nymph'

	local theme = require('nymph.theme').set_colors(require('nymph.palette'))

	for group, color in pairs(theme) do
		require('nymph.util').highlight(group, color)
	end
end

return M
