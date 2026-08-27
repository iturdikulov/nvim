-- Spell via treesitter @spell + noplainbuffer where queries exist.
-- https://github.com/neovim/neovim/pull/19419
--
-- Buffers without @spell (e.g. LSP hover scratch markdown) get no highlighting.

local query_filetypes = {
	"typst",
	"gitcommit",
	"markdown",
	"html",
	"python",
	"javascript",
	"javascriptreact",
	"typescript",
	"tsx",
	"c",
	"cpp",
	"rust",
}

-- No bundled/custom treesitter grammar: full-buffer spell.
-- plaintex syntax marks commands/math as @NoSpell, so prose is still checked.
local plain_filetypes = {
	"text",
	"plaintex",
}

local code_filetypes = {
	python = true,
	javascript = true,
	javascriptreact = true,
	typescript = true,
	tsx = true,
	c = true,
	cpp = true,
	rust = true,
}

local spell_file = table.concat({
	vim.fn.stdpath("config") .. "/spell/en.utf-8.add",
	vim.fn.stdpath("config") .. "/spell/ru.utf-8.add",
}, ",")

local function apply_spell(spelloptions)
	vim.opt_local.spell = true
	vim.opt_local.spelllang = { "en", "ru", "cjk" }
	vim.opt_local.spelloptions = spelloptions
	vim.opt_local.spellfile = spell_file
end

vim.opt.spell = false

local group = vim.api.nvim_create_augroup("Spellcheck", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = query_filetypes,
	callback = function()
		apply_spell("camel,noplainbuffer")
	end,
	desc = "Spellcheck only in @spell regions",
})

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = plain_filetypes,
	callback = function()
		apply_spell("camel")
	end,
	desc = "Full-buffer spellcheck for plain text / plaintex",
})

local M = {}

--- In code buffers, cmp-spell only inside comment-like text.
function M.cmp_entry_filter(_, ctx)
	if not code_filetypes[vim.bo[ctx.bufnr].filetype] then
		return true
	end

	local before = ctx.cursor_before_line or ""

	return before:match("%s*%-%-")
		or before:match("%s*#")
		or before:match("%s*//")
		or before:match("%s*/%*")
		or before:match("^%s*%*")
end

return M
