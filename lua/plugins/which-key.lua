return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = function(_, opts)
		opts = opts or {}

		-- which-key читает сырой символ раскладки; переводим ru → en
		local ok, lmu = pcall(require, "langmapper.utils")
		if ok then
			local wk_ok, wk_state = pcall(require, "which-key.state")
			if wk_ok and wk_state.check then
				local check_orig = wk_state.check
				---@diagnostic disable-next-line: duplicate-set-field
				wk_state.check = function(state, key)
					if key ~= nil then
						key = lmu.translate_keycode(key, "default", "ru")
					end
					return check_orig(state, key)
				end
			end

			-- не показывать дубликаты, созданные langmapper (LM …)
			opts.filter = function(mapping)
				if not mapping.lhs then
					return false
				end
				if mapping.desc and mapping.desc:find("LM", 1, true) then
					return false
				end
				return mapping.lhs == lmu.translate_keycode(mapping.lhs, "default", "ru")
			end
		end

		return opts
	end,
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
	},
}
