local ok, avante = pcall(require, "avante")
if not ok then
    return
end

require('avante_lib').load()

avante.setup({
    provider = "openrouter_gemini_flash",
    auto_suggestions_provider = "openrouter_gemini_flash",
    cursor_applying_provider = 'openrouter_gemini_flash', -- In this example, use Groq for applying, but you can also use any provider you want.
    vendors = {
        openrouter_gemini_flash = {
            __inherited_from = "openai",
            endpoint = "https://openrouter.ai/api/v1",
            model = "google/gemini-2.0-flash-001",
            api_key_name = "OPENAI_API_KEY",
            temperature = 0,
            max_tokens = 8192,
        },
        openrouter_claude = {
            __inherited_from = "openai",
            endpoint = "https://openrouter.ai/api/v1",
            model = "anthropic/claude-3.5-haiku-20241022:beta",
            api_key_name = "OPENAI_API_KEY",
            temperature = 0,
            max_tokens = 4096,
        },
        openrouter_deepseek = {
            __inherited_from = "openai",
            endpoint = "https://openrouter.ai/api/v1",
            model = "deepseek/deepseek-chat",
            api_key_name = "OPENAI_API_KEY",
            temperature = 0,
            max_tokens = 8192,
        },
        openrouter_gpt_4o_mini= {
            __inherited_from = "openai",
            endpoint = "https://openrouter.ai/api/v1",
            model = "openai/gpt-4o-mini",
            api_key_name = "OPENAI_API_KEY",
            temperature = 0,
            max_tokens = 16384,
        },
    },
    hints = { enabled = false },
    behaviour = {
        auto_suggestions = false, -- Experimental stage
        enable_cursor_planning_mode = true, -- enable cursor planning mode!
    },
})
