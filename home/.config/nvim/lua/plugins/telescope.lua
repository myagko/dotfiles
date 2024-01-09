require('telescope').setup {
	defaults = {
		prompt_prefix = "> ",
		selection_caret = "  ",
		entry_prefix = "  ",
		layout_strategy = "horizontal",
		layout_config = {
			horizontal = {
			prompt_position = "bottom",
			preview_width = 0.55,
			results_width = 0.8,
			},
			vertical = {
				mirror = false,
			},
			width = 0.87,
			height = 0.80,
			preview_cutoff = 120,
		},
		border = true,
		borderchars = { " ", " ", " ", " ", " ", " ", " ", " " },
		color_devicons = true,
	}
}
