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

## Windows Setup

This config supports Windows, but some Linux-specific parts are intentionally
disabled on startup (you will see a notification about that).

Disabled on Windows:

- `config.gnupg`
- `devcontainers.nvim`
- `nvim-dap` (and related DAP plugins from `lua/plugins/dap.lua`)
- `nvim-dap-view`
- `nvim-lint`
- `sniprun`
- `asm_lsp`

### Windows (PowerShell)

#### Fast install with winget

If `winget` is missing on your system, install/update it first:

- Microsoft docs: [Install winget](https://learn.microsoft.com/windows/package-manager/winget/#install-winget)
- Microsoft Store: [App Installer](https://apps.microsoft.com/detail/9nblggh4nns1)
- PowerShell Gallery package: [winget-install](https://www.powershellgallery.com/packages/winget-install)

Install from PowerShell Gallery:

```powershell
Install-Script -Name winget-install -Scope CurrentUser
Get-InstalledScript -Name winget-install | Select-Object Name, Version, InstalledLocation
& "$( (Get-InstalledScript -Name winget-install).InstalledLocation )\winget-install.ps1"
```

If script execution is blocked:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Install-Script -Name winget-install -Scope CurrentUser
Get-InstalledScript -Name winget-install | Select-Object Name, Version, InstalledLocation
& "$( (Get-InstalledScript -Name winget-install).InstalledLocation )\winget-install.ps1"
```

If `winget-install.ps1` is still not recognized:

```powershell
$env:PATH += ";$HOME\Documents\WindowsPowerShell\Scripts"
winget-install.ps1
```

Or run it by full path:

```powershell
& "$HOME\Documents\WindowsPowerShell\Scripts\winget-install.ps1"
```

Run PowerShell as a regular user and install core tools:

```powershell
winget install --id Neovim.Neovim -e
winget install --id Git.Git -e
winget install --id BurntSushi.ripgrep.GNU -e
winget install --id OpenJS.NodeJS.LTS -e
winget install --id Python.Python.3.12 -e
```

Or in a single line:

```powershell
winget install --id Neovim.Neovim -e; winget install --id Git.Git -e; winget install --id BurntSushi.ripgrep.GNU -e; winget install --id OpenJS.NodeJS.LTS -e; winget install --id Python.Python.3.12 -e
```

After install, restart terminal and verify:

```powershell
nvim --version
git --version
rg --version
node --version
python --version
```

If `winget` says `NoApplicableInstallers` for ripgrep (common on Windows Server),
install the portable zip:

```powershell
$ver = "15.2.0"
$zip = "$env:TEMP\ripgrep.zip"
$dir = "$env:LOCALAPPDATA\ripgrep"
curl.exe -L "https://github.com/BurntSushi/ripgrep/releases/download/$ver/ripgrep-$ver-x86_64-pc-windows-gnu.zip" -o $zip
Expand-Archive -Path $zip -DestinationPath $dir -Force
$rgHome = Join-Path $dir "ripgrep-$ver-x86_64-pc-windows-gnu"
[Environment]::SetEnvironmentVariable(
    "Path",
    [Environment]::GetEnvironmentVariable("Path", "User") + ";$rgHome",
    "User"
)
$env:PATH += ";$rgHome"
rg --version
```

Then install Tree-sitter CLI (needed by `nvim-treesitter`):

```powershell
npm install -g tree-sitter-cli
tree-sitter --version
```

#### C compiler for nvim-treesitter

`tree-sitter-cli` only generates/builds parsers. On Windows you also need a C
compiler. Without it, install fails with `tree-sitter build` / `parser.so` errors.

**Recommended:** install [Zig](https://ziglang.org/download/) manually. No Windows
SDK, works when winget says `NoApplicableInstallers`. This config sets `CC` to
`zig` when `cl.exe` is not on PATH.

x64 PowerShell (user PATH, no admin required):

```powershell
$ver = "0.16.0"
$zip = "$env:TEMP\zig-x86_64-windows-$ver.zip"
$dir = "$env:LOCALAPPDATA\zig"
curl.exe -L "https://ziglang.org/download/$ver/zig-x86_64-windows-$ver.zip" -o $zip
Expand-Archive -Path $zip -DestinationPath $dir -Force
$zigHome = Join-Path $dir "zig-x86_64-windows-$ver"
[Environment]::SetEnvironmentVariable(
    "Path",
    [Environment]::GetEnvironmentVariable("Path", "User") + ";$zigHome",
    "User"
)
$env:PATH += ";$zigHome"
zig version
```

Newer builds and ARM/32-bit zips: [ziglang.org/download](https://ziglang.org/download/).
Official PATH notes: [Getting Started](https://ziglang.org/learn/getting-started/).

After that, **restart the terminal** (or keep using the current session where
`$env:PATH` was updated).

To remove Visual Studio Build Tools if you already installed them:

```powershell
winget list --name "Visual Studio"
winget uninstall -e --id Microsoft.VisualStudio.2022.BuildTools
```

If the id differs, uninstall whatever `winget list` shows, for example:

```powershell
winget uninstall -e --id Microsoft.VisualStudio.BuildTools
```

You can also uninstall from **Apps > Installed apps** or Visual Studio Installer.
Restart the terminal after uninstall so leftover `cl.exe` / VS env vars are gone.

**Alternative:** MSVC via Visual Studio Build Tools (`cl.exe`). Needs Windows SDK
and several GB. Run PowerShell as Administrator:

```powershell
winget install -e --id Microsoft.VisualStudio.2022.BuildTools --accept-package-agreements --accept-source-agreements --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

Then start Neovim from **Developer PowerShell for VS**, because `cl` is not on a
normal PATH.

Do not mix MinGW/MSYS gcc with MSVC. Pick Zig **or** MSVC.

1. Install required tools:
   - Neovim 0.11+
   - Git for Windows
   - `ripgrep` (`rg`)
   - `node` + `npm`
   - `tree-sitter-cli` (`npm install -g tree-sitter-cli`)
   - C compiler for parsers: `zig` or MSVC `cl.exe`
   - `python` (optional, but useful for many plugins/LSPs)
2. Clone config:
   ```powershell
   git clone https://github.com/iturdikulov/nvim.git "$env:LOCALAPPDATA\nvim"
   ```
3. Start Neovim:
   ```powershell
   nvim
   ```

#### Update config

Pull the latest config and sync plugins:

```powershell
git -C "$env:LOCALAPPDATA\nvim" pull
nvim --headless "+Lazy! sync" +qa
```

Then restart Neovim.

If you only need the git update (plugins already installed):

```powershell
git -C "$env:LOCALAPPDATA\nvim" pull
```

### Notes for Windows users

- `Leader+O` uses `vim.ui.open`, so opening files in external apps is
  cross-platform.
- If you want DAP/lint/sniprun on Windows later, they can be re-enabled with
  dedicated Windows-safe setup (separate plugin specs or OS checks).

#### Terminal (ConEmu)

Fast, no GPU (GDI). Works on Windows Server. [ConEmu](https://conemu.github.io/):

```powershell
winget install -e --id Maximus5.ConEmu
```

Start with IosevkaTerm:

```powershell
& "$env:ProgramFiles\ConEmu\ConEmu64.exe" -font "IosevkaTerm Nerd Font"
```

Or Settings → Main → Font → `IosevkaTerm Nerd Font`. Then run `nvim` inside ConEmu.

#### Nerd Font (icons)

Statusline, dashboard, and file icons need a [Nerd Font](https://www.nerdfonts.com/).
Without it you get empty boxes or question marks.

Install IosevkaTerm (smaller terminal package) via the official
[PowerShell installer](https://github.com/ryanoasis/nerd-fonts#option-5-powershell-installer):

```powershell
& ([scriptblock]::Create((iwr 'https://to.loredo.me/Install-NerdFont.ps1'))) -Name IosevkaTerm
```

Interactive picker (choose the font in the menu):

```powershell
& ([scriptblock]::Create((iwr 'https://to.loredo.me/Install-NerdFont.ps1')))
```

Or as a PowerShell module:

```powershell
Install-PSResource -Name NerdFonts
Import-Module -Name NerdFonts
Install-NerdFont -Name 'IosevkaTerm'
```

Then set the font in your terminal emulator to `IosevkaTerm Nerd Font` (or
`IosevkaTermNFM`) and open a new window. GUI Neovim (`nvim-qt` / Neovide) uses
`guifont = IosevkaTerm Nerd Font` on Windows.

Restart the terminal after installing the font.

## LSP and formatters setup

I do not use any package managers inside Neovim (mason) to install LSP servers
and tools binaries; this handled outside, with my OS package manager and other
managers. If you want to use some LSP servers, required to install them
manually.
[There](https://github.com/iturdikulov/dev/blob/master/.config/yadm/runs/python)
is example how I install them in Debian.

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
