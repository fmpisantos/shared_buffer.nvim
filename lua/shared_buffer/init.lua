local M = {}

M.error_messages = {
    INVALID_FILE_PATH = "Invalid file path: The given file path is either nil or empty.",
    FAILED_CREATE_DIR = "Failed to create directory: ",
    FAILED_DECODE_STATE = "Failed to decode state file: ",
    INVALID_BUFFER_NUMBER = "Invalid buffer number provided.",
    FAILED_WRITE_BUFFER_CONTENT = "Failed to write buffer content to file: ",
    FILE_NOT_READABLE = "File not readable or does not exist: ",
    INVALID_TYPE = "Invalid type: expected non-empty string.",
    FAILED_CREATE_BUFFER = "Failed to create buffer.",
    FAILED_START_WATCHER = "Failed to start file watcher: ",
    FAILED_ATTACH_BUFFER = "Failed to attach buffer for change tracking."
}

local function ensure_dirs_exist(filepath)
        -- Check for invalid or empty file path
    if not filepath or filepath == "" then
        vim.notify(M.error_messages.INVALID_FILE_PATH, vim.log.level.ERROR)
        return false
    end

    local dir = vim.fn.fnamemodify(filepath, ":h")
    if vim.fn.isdirectory(dir) == 0 then
        if vim.fn.mkdir(dir, "p") == 0 then
            vim.notify(M.error_messages.FAILED_CREATE_DIR .. dir, vim.log.level.ERROR)
            return false
        end
    end

    return true
end

local function save_state(state, state_file)
    ensure_dirs_exist(state_file)
    vim.fn.writefile({ vim.fn.json_encode(state) }, state_file)
end

local function load_state(state_file)
    if vim.fn.filereadable(state_file) == 1 then
        local content = vim.fn.readfile(state_file)
        local status, decoded = pcall(vim.fn.json_decode, content[1])
        if status then
            return decoded
        else
            vim.notify(M.error_messages.FAILED_DECODE_STATE .. state_file, vim.log.level.ERROR)
            return { bufnr = -1 }
        end
    end
    return { bufnr = -1 }
end

-- Buffer content sync
local function save_buf_content(bufnr, content_file)
    if not bufnr or bufnr <= 0 or not vim.api.nvim_buf_is_valid(bufnr) then
        vim.notify(M.error_messages.INVALID_BUFFER_NUMBER, vim.log.level.ERROR)
        return
    end
    
    if not ensure_dirs_exist(content_file) then
        vim.notify("Failed to ensure directory exists for file: " .. content_file, vim.log.level.ERROR)
        return
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    if not pcall(vim.fn.writefile, lines, content_file) then
        vim.notify(M.error_messages.FAILED_WRITE_BUFFER_CONTENT .. content_file, vim.log.level.ERROR)
    end
end

local function load_buf_content(bufnr, content_file)
    if not bufnr or bufnr <= 0 or not vim.api.nvim_buf_is_valid(bufnr) then
        vim.notify(M.error_messages.INVALID_BUFFER_NUMBER, vim.log.level.ERROR)
        return
    end

    if vim.fn.filereadable(content_file) == 1 then
        local lines = vim.fn.readfile(content_file)
        local status = pcall(vim.api.nvim_buf_set_lines, bufnr, 0, -1, false, lines)
        if not status then
            vim.notify(M.error_messages.FAILED_WRITE_BUFFER_CONTENT .. content_file, vim.log.level.ERROR)
        end
    else
        vim.notify(M.error_messages.FILE_NOT_READABLE .. content_file, vim.log.level.WARN)
    end
end

function M.setup(type)
    if not type or type(type) ~= "string" or type == "" then
        vim.notify("Invalid type: expected non-empty string.", vim.log.level.ERROR)
        return nil
    end

    local state_file = vim.fn.stdpath("data") .. "/shared_" .. type .. "_state.json";
    M.state = load_state(state_file);
    return M.state,
        function(_state)
            save_state(_state, state_file);
        end
end

function M.setupWBuff(type)
    if not type or type(type) ~= "string" or type == "" then
        vim.notify("Invalid type: expected non-empty string.", vim.log.level.ERROR)
        return nil
    end

    -- File paths
    local content_file = vim.fn.stdpath("data") .. "/shared_" .. type .. "_buf_content.txt"
    local state_file = vim.fn.stdpath("data") .. "/shared_" .. type .. "_state.json"

    -- State management
    local state = load_state(state_file)
    local bufnr = vim.api.nvim_create_buf(false, true)
    if not bufnr then
        vim.notify("Failed to create buffer.", vim.log.level.ERROR)
        return nil
    end

    -- Load initial content
    load_buf_content(bufnr, content_file)

    -- Watch for file changes
    local watcher, err = pcall(function()
        return vim.loop.new_fs_event():start(content_file, {}, vim.schedule_wrap(function()
            load_buf_content(bufnr, content_file)
        end))
    end)
    if not watcher then
        vim.notify("Failed to start file watcher: " .. err, vim.log.level.ERROR)
    end

    -- Save content on buffer changes
    local success = pcall(function()
        vim.api.nvim_buf_attach(bufnr, false, {
            on_lines = function()
                save_buf_content(bufnr, content_file)
            end
        })
    end)

    if not success then
        vim.notify("Failed to attach buffer for change tracking.", vim.log.level.ERROR)
    end

    -- Save state
    state.bufnr = bufnr
    save_state(state, state_file)

    return bufnr
end

M.buffers = {
    floatingDiff = {
        "fileDiff1",
        "fileDiff2"
    }
}

return M
