local CLI = "cursor"
local MAX_SLOTS = 10
local CLI_PATTERN = "^" .. CLI .. "_%d+$"

local function make_tool()
  -- Без is_proc: иначе tmux discovery схлопывает несколько cursor-agent в один tool.
  return { cmd = { "cursor-agent" } }
end

---@param n integer
local function ensure_slot(n)
  local name = ("%s_%d"):format(CLI, n)
  local tools = require("sidekick.config").cli.tools
  if not tools[name] then
    tools[name] = make_tool()
  end
  return name
end

--- Re-register cursor_N tools for tmux sessions that survived a Neovim restart
--- (sid = "<tool> <sha256(cwd)[:16-#tool]>"). Windows are not opened here.
local function reconnect_sessions()
  if vim.fn.executable("tmux") ~= 1 then
    return
  end
  local ok_session, Session = pcall(require, "sidekick.cli.session")
  local ok_config, Config = pcall(require, "sidekick.config")
  if not (ok_session and ok_config) then
    return
  end

  local lines = vim.fn.systemlist({ "tmux", "list-sessions", "-F", "#{session_name}" })
  if vim.v.shell_error ~= 0 then
    return
  end

  local full_hash = vim.fn.sha256(Session.cwd())
  Config.cli.tools = Config.cli.tools or {}
  for _, line in ipairs(lines) do
    local tool_name, hash = line:match("^(.-) (%w+)$")
    if tool_name and hash and tool_name:match(CLI_PATTERN) and not Config.cli.tools[tool_name] then
      local expected_len = 16 - #tool_name
      if expected_len > 0 and #hash == expected_len and full_hash:sub(1, expected_len) == hash then
        Config.cli.tools[tool_name] = make_tool()
      end
    end
  end
end

local function toggle_slot()
  local n = vim.v.count
  if n == 0 then
    n = 1
  end
  if n > MAX_SLOTS then
    vim.notify(("Sidekick: max %d cursor sessions"):format(MAX_SLOTS), vim.log.levels.WARN)
    return
  end
  local name = ensure_slot(n)
  require("sidekick.cli").toggle({ name = name, focus = true })
end

return {
  "folke/sidekick.nvim",
  opts = {
    cli = {
      watch = true,
      win = {
        layout = "right",
        split = { width = 80 },
        keys = {
          -- q в normal mode закрывает панель и мешает в tmux/Codex scrollback.
          hide_n = false,
          -- <C-.> — глобальный Focus Sidekick; дефолтный hide конфликтует.
          hide_ctrl_dot = false,
          -- <C-h> = Ctrl-Backspace в терминале; не уводить в соседнее окно.
          nav_left = false,
          -- Ctrl-Backspace → Ctrl-W в cursor CLI (удалить слово назад).
          -- <C-w> в terminal mode уже занят window-командами Neovim.
          ctrl_backspace = {
            "<C-BS>",
            function(t)
              if t.job then
                vim.api.nvim_chan_send(t.job, "\x17")
              end
            end,
            mode = "t",
            desc = "Delete word backward (send C-w to CLI)",
          },
          ctrl_h_word = {
            "<C-h>",
            function(t)
              if t.job then
                vim.api.nvim_chan_send(t.job, "\x17")
              end
            end,
            mode = "t",
            desc = "Delete word backward (send C-w to CLI)",
          },
        },
      },
      mux = {
        backend = "tmux",
        enabled = true,
        create = "terminal",
      },
    },
  },
  config = function(_, opts)
    require("sidekick").setup(opts)

    -- Дефолты Sidekick объединяются с opts, поэтому ограничиваем список после setup.
    require("sidekick.config").cli.tools = {
      [CLI .. "_1"] = make_tool(),
    }

    reconnect_sessions()
    vim.api.nvim_create_autocmd("DirChanged", {
      group = vim.api.nvim_create_augroup("sidekick_cursor_reconnect", { clear = true }),
      callback = reconnect_sessions,
    })
  end,
  keys = {
    {
      "<tab>",
      function()
        -- if there is a next edit, jump to it, otherwise apply it if any
        if require("sidekick").nes_jump_or_apply() then
          return -- jumped or applied
        end

        -- if you are using Neovim's native inline completions
        if vim.lsp.inline_completion.get() then
          return
        end

        -- fall back to normal tab
        return "<tab>"
      end,
      mode = { "i", "n" },
      expr = true,
      desc = "Goto/Apply Next Edit Suggestion",
    },
    {
      "<leader>as",
      function()
        require("sidekick.cli").select({ filter = { installed = true } })
      end,
      desc = "Select Sidekick CLI",
    },
    {
      "<leader>ad",
      function()
        require("sidekick.cli").close()
      end,
      desc = "Detach Sidekick CLI",
    },
    {
      "<leader>at",
      function()
        require("sidekick.cli").send({ msg = "{this}" })
      end,
      mode = { "n", "x" },
      desc = "Send current context to Sidekick",
    },
    {
      "<leader>af",
      function()
        require("sidekick.cli").send({ msg = "{file}" })
      end,
      desc = "Send file to Sidekick",
    },
    {
      "<leader>av",
      function()
        require("sidekick.cli").send({ msg = "{selection}" })
      end,
      mode = "x",
      desc = "Send selection to Sidekick",
    },
    {
      "<leader>ap",
      function()
        require("sidekick.cli").prompt()
      end,
      mode = { "n", "x" },
      desc = "Select Sidekick prompt",
    },
    {
      "<C-.>",
      function()
        require("sidekick.cli").focus()
      end,
      mode = { "n", "t", "i", "x" },
      desc = "Focus Sidekick CLI",
    },
    {
      -- langmapper (ru): <C-.> → <C-/>; Ghostty ctrl+KeyPeriod шлёт CSI-u в обеих раскладках.
      "<C-/>",
      function()
        require("sidekick.cli").focus()
      end,
      mode = { "n", "t", "i", "x" },
      desc = "Focus Sidekick CLI",
    },
    {
      "<M-x>",
      toggle_slot,
      mode = { "n", "t" },
      desc = "Toggle Sidekick Cursor CLI (count = slot 1..10)",
    },
  },
}
