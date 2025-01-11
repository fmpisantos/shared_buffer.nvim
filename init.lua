local M = {}

local function ensure_dirs_exist(filepath)
    local dir = vim.fn.fnamemodify(filepath, ":h")
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end
end

local function save_state(state, state_file)
    ensure_dirs_exist(state_file)
    vim.fn.writefile({ vim.fn.json_encode(state) }, state_file)
end

local function load_state(state_file)
    if vim.fn.filereadable(state_file) == 1 then
        local content = vim.fn.readfile(state_file)
        return vim.fn.json_decode(content[1])
    end
    return { bufnr = -1 }
end

-- Buffer content sync
local function save_buf_content(bufnr, content_file)
    if bufnr and bufnr > 0 then
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        vim.fn.writefile(lines, content_file)
    end
end

local function load_buf_content(bufnr, content_file)
    if vim.fn.filereadable(content_file) == 1 then
        local lines = vim.fn.readfile(content_file)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    end
end

function M.setup(type)
    local state_file = vim.fn.stdpath("data") .. "/shared_" .. type .. "_state.json";
    M.state = load_state(state_file);
    return M.state,
        function(_state)
            save_state(_state, state_file);
        end
end

function M.setupWBuff(type)
    -- File paths
    local content_file = vim.fn.stdpath("data") .. "/shared_" .. type .. "_buf_content.txt"
    local state_file = vim.fn.stdpath("data") .. "/shared_" .. type .. "_state.json"

    -- State management
    local state = load_state(state_file)
    local bufnr = vim.api.nvim_create_buf(false, true)

    -- Load initial content
    load_buf_content(bufnr, content_file)

    -- Watch for file changes
    vim.loop.new_fs_event():start(content_file, {}, vim.schedule_wrap(function()
        load_buf_content(bufnr, content_file)
    end))

    -- Save content on buffer changes
    vim.api.nvim_buf_attach(bufnr, false, {
        on_lines = function()
            save_buf_content(bufnr, content_file)
        end
    })

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
