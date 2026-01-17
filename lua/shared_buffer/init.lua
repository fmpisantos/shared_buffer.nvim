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

-- Track active watchers for cleanup
local active_watchers = {}

local function ensure_dirs_exist(filepath)
    if not filepath or filepath == "" then
        vim.notify(M.error_messages.INVALID_FILE_PATH, vim.log.levels.ERROR)
        return false
    end
    
    local dir = vim.fn.fnamemodify(filepath, ":h")
    if vim.fn.isdirectory(dir) == 0 then
        if vim.fn.mkdir(dir, "p") == 0 then
            vim.notify(M.error_messages.FAILED_CREATE_DIR .. dir, vim.log.levels.ERROR)
            return false
        end
    end
    return true
end

local function save_state(state, state_file)
    if not ensure_dirs_exist(state_file) then
        return false
    end
    
    local success, err = pcall(function()
        vim.fn.writefile({ vim.fn.json_encode(state) }, state_file)
    end)
    
    if not success then
        vim.notify("Failed to save state: " .. tostring(err), vim.log.levels.ERROR)
        return false
    end
    return true
end

local function load_state(state_file)
    if vim.fn.filereadable(state_file) == 1 then
        local content = vim.fn.readfile(state_file)
        if #content > 0 then
            local status, decoded = pcall(vim.fn.json_decode, content[1])
            if status then
                return decoded
            else
                vim.notify(M.error_messages.FAILED_DECODE_STATE .. state_file, vim.log.levels.ERROR)
            end
        end
    end
    return { bufnr = -1 }
end

local function save_buf_content(bufnr, content_file)
    if not bufnr or bufnr <= 0 or not vim.api.nvim_buf_is_valid(bufnr) then
        vim.notify(M.error_messages.INVALID_BUFFER_NUMBER, vim.log.levels.ERROR)
        return false
    end
    
    if not ensure_dirs_exist(content_file) then
        return false
    end
    
    local success, err = pcall(function()
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        vim.fn.writefile(lines, content_file)
    end)
    
    if not success then
        vim.notify(M.error_messages.FAILED_WRITE_BUFFER_CONTENT .. tostring(err), vim.log.levels.ERROR)
        return false
    end
    return true
end

local function load_buf_content(bufnr, content_file)
    if not bufnr or bufnr <= 0 or not vim.api.nvim_buf_is_valid(bufnr) then
        vim.notify(M.error_messages.INVALID_BUFFER_NUMBER, vim.log.levels.ERROR)
        return false
    end
    
    if vim.fn.filereadable(content_file) ~= 1 then
        -- File doesn't exist yet, which is fine for first run
        return true
    end
    
    local success, err = pcall(function()
        local lines = vim.fn.readfile(content_file)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    end)
    
    if not success then
        vim.notify("Failed to load buffer content: " .. tostring(err), vim.log.levels.ERROR)
        return false
    end
    return true
end

function M.setup(type)
    if not type or type(type) ~= "string" or type == "" then
        vim.notify(M.error_messages.INVALID_TYPE, vim.log.levels.ERROR)
        return nil
    end
    
    local state_file = vim.fn.stdpath("data") .. "/shared_" .. type .. "_state.json"
    M.state = load_state(state_file)
    
    return M.state, function(_state)
        save_state(_state, state_file)
    end
end

function M.setupWBuff(type)
    if not type or type(type) ~= "string" or type == "" then
        vim.notify(M.error_messages.INVALID_TYPE, vim.log.levels.ERROR)
        return nil
    end
    
    -- File paths
    local content_file = vim.fn.stdpath("data") .. "/shared_" .. type .. "_buf_content.txt"
    local state_file = vim.fn.stdpath("data") .. "/shared_" .. type .. "_state.json"
    
    -- State management
    local state = load_state(state_file)
    
    -- Create buffer
    local bufnr = vim.api.nvim_create_buf(false, true)
    if not bufnr or bufnr <= 0 then
        vim.notify(M.error_messages.FAILED_CREATE_BUFFER, vim.log.levels.ERROR)
        return nil
    end
    
    -- Flag to prevent recursive saves
    local is_loading = false
    
    -- Load initial content
    load_buf_content(bufnr, content_file)
    
    -- Create file watcher
    local watcher = vim.loop.new_fs_event()
    if watcher then
        -- Ensure file exists for watcher
        if vim.fn.filereadable(content_file) ~= 1 then
            vim.fn.writefile({}, content_file)
        end
        
        local success, err = pcall(function()
            watcher:start(content_file, {}, vim.schedule_wrap(function()
                is_loading = true
                load_buf_content(bufnr, content_file)
                vim.schedule(function()
                    is_loading = false
                end)
            end))
        end)
        
        if not success then
            vim.notify(M.error_messages.FAILED_START_WATCHER .. tostring(err), vim.log.levels.WARN)
            watcher = nil
        else
            active_watchers[bufnr] = watcher
        end
    end
    
    -- Save content on buffer changes and cleanup on detach
    local success = pcall(function()
        vim.api.nvim_buf_attach(bufnr, false, {
            on_lines = function()
                if not is_loading then
                    save_buf_content(bufnr, content_file)
                end
            end,
            on_detach = function()
                -- Cleanup watcher
                if active_watchers[bufnr] then
                    local w = active_watchers[bufnr]
                    if not w:is_closing() then
                        w:stop()
                        w:close()
                    end
                    active_watchers[bufnr] = nil
                end
            end
        })
    end)
    
    if not success then
        vim.notify(M.error_messages.FAILED_ATTACH_BUFFER, vim.log.levels.ERROR)
        if watcher and not watcher:is_closing() then
            watcher:stop()
            watcher:close()
        end
        return nil
    end
    
    -- Save state
    state.bufnr = bufnr
    save_state(state, state_file)
    
    return bufnr
end

return M
