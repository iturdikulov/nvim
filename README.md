# My Neovim Configuration

A personalized Neovim setup designed for a fast, efficient, and LLM enhanced
development workflow.

## Why?

I found myself spending too much time configuring and context-switching between
different tools.

I want to use fast and highly personalized development environment (PDE). This
configuration is result of my journey to create it. I think it's 3 or 4
iteration.

So it's a highly customized setup that integrates some of the best Neovim
plugins available, with a focus on:

- **Efficient Workflow:** Fast fuzzy finding with Telescope, easy file
  navigation with Harpoon, and a streamlined UI with a custom statusline and
  dashboard.
- **Powerful Tooling:** Built-in support for LSP, autocompletion, debugging,
  testing, and refactoring.
- **Aesthetics:** A clean and modern look and feel with the Rosé Pine
  color-scheme.
- **Code-Assisted Development:** Integrated access to coding assistants like
  `codecompanion.nvim` and `minuet-ai.nvim` for code generation, analysis, and
  chat.

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/your-nvim-config.git ~/.config/nvim
   ```
2. **Install plugins:** Launch Neovim. The `lazy.nvim` plugin manager will
   automatically install all the required plugins.

   ```bash
   nvim
   ```

## Usage

This configuration comes with a lot of features. Here are some of the
highlights:

### Coding Assistance

- **CodeCompanion:** Interact with LLM assistants directly within Neovim.
  - `<leader>a`: Toggle the CodeCompanion chat window.
  - `<leader>ck`: Show available CodeCompanion actions.
  - `ga` (visual mode): Add the selected code to the chat window.
  - `<leader>cs`: Select the AI model to use.
- **Minuet AI:** Get code completions from AI.
  - `<M-n>`/`<M-p>`: Cycle through completion suggestions.
  - `<A-y>`: Accept a completion.

### General Usage & Navigation

- **Telescope:** Fuzzy find anything.
  - `<M-f>`: Find files.
  - `<M-F>`: Find old files.
  - `<leader>ff`: Find git files.
  - `<leader>fs`: Grep for a string in the current directory.

- **Harpoon:** Mark and quickly jump to files.
  - `<m-h><m-a>`: Add the current file to the harpoon list.
  - `<m-h><m-h>`: Toggle the harpoon menu.
  - `<space>1-5`: Jump to the corresponding file in the harpoon list.

- **Snacks:** A collection of useful UI enhancements.
  - `<leader>D`: Show the dashboard.
  - `<leader>pv`: Open the file explorer.
  - `<leader>z`: Toggle Zen mode.
  - `<leader>T`: Toggle the terminal.

### Development

**LSP:** Language server protocol support for diagnostics, code actions, and
more:

- `K`: Show hover documentation.
- `gd`: Go to definition.
- `gr<key>`: Various LSP commands

- **Debugging:** Integrated debugging with `nvim-dap`.
  - `<F5>`: Continue.
  - `<F10>`: Step over.
  - `<leader>b`: Toggle breakpoint.

- **Testing:** Run tests with `neotest`.
  - `<leader>dnn`: Run the nearest test.
  - `<leader>dnf`: Run all tests in the current file.

- **Refactoring:**
  - `<leader>rr`: Select a refactoring action.
  - `<leader>re`: Extract a function (visual mode).

## Contribution

This is a personal configuration, but feel free to fork it and customize it to
your liking. If you want to add a new plugin:

1. Add a new file in the `lua/plugins/` directory.
2. In that file, return a `lazy.nvim` plugin specification. For example:
   ```lua
   return {
       "author/plugin-name.nvim",
       -- lazy.nvim options
   }
   ```
3. Restart Neovim. The new plugin will be installed automatically.
