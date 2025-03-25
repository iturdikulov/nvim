local ok, auto_save = pcall(require, "auto-save")
if not ok then return end
auto_save.setup{
    enabled = false, -- I'll enable it only with keybinds
}
vim.keymap.set("n", "<leader>ts", vim.cmd.ASToggle, {desc="Toggle auto-save"})
