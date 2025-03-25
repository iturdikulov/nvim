---

-- Insert timestamps from mpv
-- TODO: very scratchy, need to clean up/improve

function InitializeMpvInstance(file_path, duration)
    if file_path == nil then
        local currentLine = vim.fn.getline(".")

        -- Define a pattern to match the filename and seconds
        local pattern = "%[(%d%d:%d%d:%d%d)%]%(<file://(.-)>%)"

        -- Extract filename and seconds using the pattern
        local filename = nil;
        duration, filename = currentLine:match(pattern)

        if filename then
            file_path = filename
        else
            file_path = vim.fn.input("File: ", "", "file")
        end
        file_path = vim.fn.expand(file_path)
    end

    -- Get the directory of the current lua script
    local script_path = vim.fn.expand(vim.fn.stdpath("config") .. "/lua/Personal")
    local bash_script = script_path .. "/mpv-start" -- Assuming myscript.sh is in the same directory
    vim.fn.jobstart({ bash_script, duration, file_path })
    vim.defer_fn(function() OpenAndSeek() end, 600)
end

function InsertTimestamp()
    -- Insert timestamp in the current line
    -- Example:
    --
    -- [0:00:11](<file:///home/inom/How to Draw Gesture.mkv>)

    -- Pause video
    vim.fn.system('echo \'{ "command": ["set_property", "pause", true] }\' | socat - /tmp/dublang-mpv.sock')

    -- Get required data
    local time_pos_data =
        vim.fn.system('echo \'{ "command": ["get_property", "time-pos"] }\' | socat - /tmp/dublang-mpv.sock')
    local file_path = vim.fn.system('echo \'{ "command": ["get_property", "path"] }\' | socat - /tmp/dublang-mpv.sock')
    file_path = vim.fn.json_decode(file_path)["data"]

    local time = math.floor(vim.fn.json_decode(time_pos_data)["data"])

    local days = math.floor(time / 86400)
    local remaining = time % 86400
    local hours = math.floor(remaining / 3600)
    remaining = remaining % 3600
    local minutes = math.floor(remaining / 60)
    remaining = remaining % 60
    local seconds = remaining

    if hours < 10 then
        hours = "0" .. tostring(minutes)
    end

    if minutes < 10 then
        minutes = "0" .. tostring(minutes)
    end

    if seconds < 10 then
        seconds = "0" .. tostring(seconds)
    end

    -- Escape file path
    file_path = vim.fn.expand(file_path)

    vim.api.nvim_put(
        { "- [" .. hours .. ":" .. minutes .. ":" .. seconds .. "](<file://" .. file_path .. ">)" },
        "l",
        false,
        true
    )
    vim.cmd("startinsert!")
end

function OpenAndSeek()
    -- Input string
    local currentLine = vim.fn.getline(".")

    -- Define a pattern to match the filename and seconds
    local pattern = "%[(%d%d:%d%d:%d%d)%]%(<file://(.-)>%)"

    -- Extract filename and seconds using the pattern
    local duration, filename = currentLine:match(pattern)

    local processId = vim.fn.system("pgrep -f 'input-ipc-server=/tmp/dublang-mpv.sock'")
    if processId == "" then
        vim.notify("Mpv is not running, starting it now")
        InitializeMpvInstance(filename, duration)
        return
    end

    if not duration or not filename then
        return
    end

    -- Convert duration to seconds
    local hours, minutes, seconds = duration:match("(%d+):(%d+):(%d+)")
    local totalSeconds = (hours * 3600) + (minutes * 60) + seconds
    filename = vim.fn.expand(filename)

    local file_path = vim.fn.system('echo \'{ "command": ["get_property", "path"] }\' | socat - /tmp/dublang-mpv.sock')
    file_path = vim.fn.json_decode(file_path)["data"]
    if file_path ~= filename then
        vim.fn.system('echo \'{ "command" : ["loadfile", "' .. filename .. "\"] }' | socat - /tmp/dublang-mpv.sock && ")
    end
    vim.fn.system(
        'echo \'{ "command": ["seek", "' .. totalSeconds .. '", "absolute"] }\' | socat - /tmp/dublang-mpv.sock'
    )
end

-- Open mpv with initial file
vim.keymap.set(
    { "i" },
    "<C-g>",
    InsertTimestamp,
    { noremap = true, silent = true, desc = "[MPV] Insert timestamp" }
)
vim.keymap.set(
    "n",
    "<leader>tm",
    OpenAndSeek,
    { noremap = true, silent = true, desc = "[MPV] Open and seek to timestamp" }
)
