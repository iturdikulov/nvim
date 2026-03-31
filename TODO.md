# Neovim Config TODO

## Bugs / Fixes

- [ ] Fix hardcoded wrong username in `lsp.lua` — `/home/inom/` should be ... (sqls config path), propably need to check file existence
- [ ] Update README — references `codecompanion` and Rosé Pine colorscheme, but actual setup uses `kanso.nvim` and no codecompanion

## Cleanup

- [ ] Remove deprecated `on_attach` pattern from `pylsp` LSP config (use capabilities system instead)
- [ ] Review `vim.lsp.on_type_formatting.enable()` — likely auto-managed, may be redundant
- [ ] Audit `pylsp` vs `basedpyright` — dual Python LSP may cause conflicts; consider removing pylsp
- [ ] Remove or disable `FixCursorHold.nvim` — fixed upstream in Neovim, plugin is obsolete

## Improvements

- [ ] Update all plugins (`lazy sync` / review `lazy-lock.json` for stale commits)
- [ ] Modernize LSP config — migrate fully to `vim.lsp.config()` + `vim.lsp.enable()` style (Neovim 0.10+)
- [ ] Review `opencode.nvim` — evaluate if still useful or can be removed
- [ ] Consider adding `codecompanion.nvim` back if AI chat workflow is needed (README implies it was used)

## Nice to Have

- [ ] Add more LuaSnip snippets (currently only markdown and fastapi)
- [ ] Review and trim unused keybindings in `remap.lua`
- [ ] Evaluate `sniprun` usage — overlaps with DAP/neotest for code execution
