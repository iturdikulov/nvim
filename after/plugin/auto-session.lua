local ok, auto_session = pcall(require, "auto-session")
if not ok then
    return
end

auto_session.setup {
    suppressed_dirs = { "~/", "~/Downloads", "/", "/tmp", "~/Arts_and_Entertainment/", "~/Documents/"},
}
