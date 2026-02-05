--- wtr.nvim - Git Worktree Orchestration for Neovim
-- Provides seamless management of Git worktrees with Telescope integration.
-- @module wtr
-- @author neopilot-ai
-- @license MIT

local Job = require("plenary.job")
local Path = require("plenary.path")
local Enum = require("wtr.enum")

local Status = require("wtr.status")

local status = Status:new()
local M = {}
local git_worktree_root = nil
local current_worktree_path = nil
local on_change_callbacks = {}

--- Initialize git repository information.
-- Discovers and caches Git repository information including root directory
-- and current worktree path. Called automatically before operations.
--
-- @usage require('wtr').setup_git_info()
M.setup_git_info = function()
    local cwd = vim.loop.cwd()

    local is_in_worktree = false

    local inside_worktree_job = Job:new({
        'git', 'rev-parse', '--is-inside-work-tree',
        cwd = cwd,
    })

    local process_inside_worktree = function(stdout)
        if stdout == "true" then
            is_in_worktree = true
        end
    end

    local find_git_dir_job = Job:new({
        'git', 'rev-parse', '--absolute-git-dir',
        cwd = cwd,
    })

    local process_find_git_dir = function(stdout)
        if is_in_worktree then
            -- if in worktree git dir returns absolute path

            -- try to find the dot git folder (non-bare repo)
            local git_dir = Path:new(stdout)
            local has_dot_git = false
            for _, dir in ipairs(git_dir:_split()) do
                if dir == ".git" then
                    has_dot_git = true
                    break
                end
            end

            if has_dot_git then
                if stdout == ".git" then
                    git_worktree_root = cwd
                else
                    local start = stdout:find("%.git")
                    git_worktree_root = stdout:sub(1,start - 2)
                end
            else
                local start = stdout:find("/worktrees/")
                git_worktree_root = stdout:sub(0, start - 1)
            end
        elseif stdout == "." then
            -- we are in the root git dir
            git_worktree_root = cwd
        else
            -- if not in worktree git dir should be absolute
            git_worktree_root = stdout
        end
        status:log():debug("git directory is: " .. git_worktree_root)
    end

    local find_toplevel_job = Job:new({
        'git', 'rev-parse', '--show-toplevel',
        cwd = cwd,
    })

    local find_toplevel_bare_job = Job:new({
        'git', 'rev-parse', '--is-bare-repository',
        cwd = cwd,
    })

    local process_find_toplevel = function(stdout)
        current_worktree_path = stdout
        status:log().debug("git toplevel is: " .. current_worktree_path)
    end

    local process_find_toplevel_bare = function(stdout)
        if stdout == "true" then
            current_worktree_path = cwd
        end
    end

    local stdout, code = inside_worktree_job:sync()
    if code ~= 0 then
        status:log().error("Error in determining if we are in a worktree")
        git_worktree_root = nil
        current_worktree_path = nil
        return
    end
    stdout = table.concat(stdout, "")
    process_inside_worktree(stdout)

    stdout, code = find_git_dir_job:sync()
    if code ~= 0 then
        status:log().error("Error in determining the git root dir")
        git_worktree_root = nil
        return
    end
    stdout = table.concat(stdout, "")
    process_find_git_dir(stdout)

    stdout, code = find_toplevel_job:sync()
    if code == 0 then
        stdout = table.concat(stdout, "")
        process_find_toplevel(stdout)
    else
        stdout, code = find_toplevel_bare_job:sync()
        if code == 0 then
            stdout = table.concat(stdout, "")
            process_find_toplevel_bare(stdout)
        else
            status:log().error("Error in determining the git toplevel")
            current_worktree_path = nil
            return
        end
    end

end

local function on_tree_change_handler(op, metadata)
    if M._config.update_on_change then
        if op == Enum.Operations.Switch then
            local changed = M.update_current_buffer(metadata["prev_path"])
            if not changed then
                status:log().debug("Could not change to the file in the new worktree, running the `update_on_change_command`")
                vim.cmd(M._config.update_on_change_command)
            end
        end
    end
end

local function emit_on_change(op, metadata)
    -- TODO: We don't have a way to async update what is running
    status:next_status(string.format("Running post %s callbacks", op))
    on_tree_change_handler(op, metadata)
    for idx = 1, #on_change_callbacks do
        on_change_callbacks[idx](op, metadata)
    end
end

local function change_dirs(path)
    local worktree_path = M.get_worktree_path(path)

    local previous_worktree = current_worktree_path

    -- vim.loop.chdir(worktree_path)
    if Path:new(worktree_path):exists() then
        local cmd = string.format("%s %s", M._config.change_directory_command, worktree_path)
        status:log().debug("Changing to directory " .. worktree_path)
        vim.cmd(cmd)
        current_worktree_path = worktree_path
    else
        status:error('Could not change to directory: ' .. worktree_path)
    end

    if M._config.clearjumps_on_change then
        status:log().debug("Clearing jumps")
        vim.cmd("clearjumps")
    end

    return previous_worktree
end

local function create_worktree_job(path, branch, found_branch)

    local worktree_add_cmd = 'git'
    local worktree_add_args = {'worktree', 'add'}

    if not found_branch then
        table.insert(worktree_add_args, '-b')
        table.insert(worktree_add_args, branch)
        table.insert(worktree_add_args, path)
    else
        table.insert(worktree_add_args, path)
        table.insert(worktree_add_args, branch)
    end

    return Job:new({
        command = worktree_add_cmd,
        args = worktree_add_args,
        cwd = git_worktree_root,
        on_start = function()
            status:next_status(worktree_add_cmd .. " " .. table.concat(worktree_add_args, " "))
        end
    })
end

-- A lot of this could be cleaned up if there was better job -> job -> function
-- communication.  That should be doable here in the near future
local function has_worktree(path, cb)
    local found = false
    local plenary_path = Path:new(path)

    local job = Job:new({
        'git', 'worktree', 'list', on_stdout = function(_, data)

            local list_data = {}
            for section in data:gmatch("%S+") do
                table.insert(list_data, section)
            end

            data = list_data[1]

            local start
            if plenary_path:is_absolute() then
                start = data == path
            else
                local worktree_path = Path:new(
                    string.format("%s" .. Path.path.sep .. "%s", git_worktree_root, path)
                )
                worktree_path = worktree_path:absolute()
                start = data == worktree_path
            end

            -- TODO: This is clearly a hack (do not think we need this anymore?)
            local start_with_head = string.find(data, string.format("[heads/%s]", path), 1, true)
            found = found or start or start_with_head
        end,
        cwd = git_worktree_root
    })

    job:after(function()
        cb(found)
    end)

    -- TODO: I really don't want status's spread everywhere... seems bad
    status:next_status("Checking for worktree " .. path)
    job:start()
end

--- Create a failure handler for Job operations.
-- Generates a failure callback that logs and displays formatted error messages.
--
-- @param from string operation name that failed (e.g., "create_worktree")
-- @param cmd table|string command being executed
-- @param path string worktree path involved in the operation
-- @param soft_error boolean|nil if true, error is logged but doesn't halt; defaults to false
-- @return function failure callback
local function failure(from, cmd, path, soft_error)
    return function(e)
        local cmd_str = type(cmd) == "string" and cmd or vim.inspect(cmd)
        local stderr_output = table.concat(e:stderr_result() or {}, "\n")
        local error_message = string.format(
            "%s: Operation failed.\n  Path: %s\n  Command: %s\n  Error: %s",
            from,
            tostring(path) or "unknown",
            cmd_str,
            stderr_output ~= "" and stderr_output or "(no error details available)")

        if soft_error then
            status:status(error_message)
            status:log().warn(error_message)
        else
            status:error(error_message)
            status:log().error(error_message)
        end
    end
end

local function has_origin()
    local found = false
    local job = Job:new({
        'git', 'remote', 'show',
        on_stdout = function(_, data)
            data = vim.trim(data)
            found = found or data == 'origin'
        end,
        cwd = git_worktree_root,
    })

    -- TODO: I really don't want status's spread everywhere... seems bad
    job:after(function()
        status:status("found origin: " .. tostring(found))
    end):sync()

    return found
end

local function has_branch(branch, cb)
    local found = false
    local job = Job:new({
        'git', 'branch', on_stdout = function(_, data)
            -- remove  markere on current branch
            data = data:gsub("*","")
            data = vim.trim(data)
            found = found or data == branch
        end,
        cwd = git_worktree_root,
    })

    -- TODO: I really don't want status's spread everywhere... seems bad
    status:next_status(string.format("Checking for branch %s", branch))
    job:after(function()
        status:status("found branch: " .. tostring(found))
        cb(found)
    end):start()
end

local function create_worktree(path, branch, upstream, found_branch)
    local create = create_worktree_job(path, branch, found_branch)

    local worktree_path
    if Path:new(path):is_absolute() then
        worktree_path = path
    else
        worktree_path = Path:new(git_worktree_root, path):absolute()
    end

    local fetch = Job:new({
        'git', 'fetch', '--all',
        cwd = worktree_path,
        on_start = function()
            status:next_status("git fetch --all (This may take a moment)")
        end
    })

    local set_branch_cmd = 'git'
    local set_branch_args= {'branch', string.format('--set-upstream-to=%s/%s', upstream, branch)}
    local set_branch = Job:new({
        command = set_branch_cmd,
        args = set_branch_args,
        cwd = worktree_path,
        on_start = function()
            status:next_status(set_branch_cmd .. " " .. table.concat(set_branch_args, " "))
        end
    })

    -- TODO: How to configure origin???  Should upstream ever be the push
    -- destination?
    local set_push_cmd = 'git'
    local set_push_args = {'push', "--set-upstream", upstream,  branch, path}
    local set_push  = Job:new({
        command = set_push_cmd,
        args = set_push_args,
        cwd = worktree_path,
        on_start = function()
            status:next_status(set_push_cmd .. " " .. table.concat(set_push_args, " "))
        end
    })

    local rebase = Job:new({
        'git', 'rebase',
        cwd = worktree_path,
        on_start = function()
            status:next_status("git rebase")
        end
    })

    if upstream ~= nil then
        create:and_then_on_success(fetch)
        fetch:and_then_on_success(set_branch)

        if M._config.autopush then
            -- These are "optional" operations.
            -- We have to figure out how we want to handle these...
            set_branch:and_then(set_push)
            set_push:and_then(rebase)
            set_push:after_failure(failure("create_worktree", set_branch.args, worktree_path, true))
        else
            set_branch:and_then(rebase)
        end

        create:after_failure(failure("create_worktree", create.args, git_worktree_root))
        fetch:after_failure(failure("create_worktree", fetch.args, worktree_path))

        set_branch:after_failure(failure("create_worktree", set_branch.args, worktree_path, true))

        rebase:after(function()

            if rebase.code ~= 0 then
                status:status("Rebase failed, but that's ok.")
            end

            vim.schedule(function()
                emit_on_change(Enum.Operations.Create, {path = path, branch = branch, upstream = upstream})
                M.switch_worktree(path)
            end)
        end)
    else
        create:after(function()
            vim.schedule(function()
                emit_on_change(Enum.Operations.Create, {path = path, branch = branch, upstream = upstream})
                M.switch_worktree(path)
            end)
        end)
    end

    create:start()
end

--- Create a new Git worktree.
-- Creates a new worktree for the specified branch at the given path.
-- If the branch doesn't exist, it will be created. Automatically sets up
-- upstream tracking and performs initial rebase if configured.
--
-- @param path string path/to/worktree - relative to git root or absolute
-- @param branch string branch name to create worktree for
-- @param upstream string|nil upstream remote (defaults to 'origin' if available)
-- @usage require('wtr').create_worktree('feature', 'feature-x', 'origin')
M.create_worktree = function(path, branch, upstream)
    status:reset(8)

    if upstream == nil then
        if has_origin() then
            upstream = "origin"
        end
    end

    M.setup_git_info()

    has_worktree(path, function(found)
        if found then
            status:error("worktree already exists")
        end

        has_branch(branch, function(found_branch)
            create_worktree(path, branch, upstream, found_branch)
        end)
    end)

end

--- Switch to a different Git worktree.
-- Changes the current working directory to the specified worktree.
-- Updates the current buffer if possible, and triggers on_change callbacks.
--
-- @param path string path to worktree - relative or absolute
-- @usage require('wtr').switch_worktree('feature')
M.switch_worktree = function(path)
    status:reset(2)
    M.setup_git_info()
    has_worktree(path, function(found)

        if not found then
            status:error("worktree does not exists, please create it first " .. path)
        end

        vim.schedule(function()
            local prev_path = change_dirs(path)
            emit_on_change(Enum.Operations.Switch, { path = path, prev_path = prev_path })
        end)

    end)
end

--- Delete an existing Git worktree.
-- Removes a worktree from the repository. Can force removal if necessary.
--
-- @param path string path to worktree - relative or absolute
-- @param force boolean|nil force removal (--force flag), defaults to false
-- @param opts table|nil options table with callbacks
-- @param opts.on_success function|nil callback on successful deletion
-- @param opts.on_failure function|nil callback on deletion failure, receives error object
-- @usage require('wtr').delete_worktree('feature', false, { on_success = function() print("Done!") end })
M.delete_worktree = function(path, force, opts)
    if not opts then
        opts = {}
    end

    status:reset(2)
    M.setup_git_info()
    has_worktree(path, function(found)
        if not found then
            status:error(string.format("Worktree %s does not exist", path))
        end

        local cmd = {
            "git", "worktree", "remove", path
        }

        if force then
            table.insert(cmd, "--force")
        end

        local delete = Job:new(cmd)
        delete:after_success(vim.schedule_wrap(function()
            emit_on_change(Enum.Operations.Delete, { path = path })
            if opts.on_success then
                opts.on_success()
            end
        end))

        delete:after_failure(function(e)
            -- callback has to be called before failure() because failure()
            -- halts code execution
            if opts.on_failure then
                opts.on_failure(e)
            end

            failure(cmd, vim.loop.cwd())(e)
        end)
        delete:start()
    end)
end

--- Set the Git worktree root directory.
-- Manually set the root directory for Git worktrees.
--
-- @param wd string path to worktree root directory
-- @usage require('wtr').set_worktree_root('/path/to/repo')
M.set_worktree_root = function(wd)
    git_worktree_root = wd
end

--- Set the current worktree path.
-- Manually set the path of the current active worktree.
--
-- @param wd string path to current worktree
-- @usage require('wtr').set_current_worktree_path('/path/to/current')
M.set_current_worktree_path = function(wd)
    current_worktree_path = wd
end

--- Update current buffer when switching worktrees.
-- Intelligently updates the current buffer to match the file in the new worktree.
-- Attempts to find the same relative path in the new worktree and switch to it.
--
-- @param prev_path string|nil previous worktree path
-- @return boolean true if buffer was successfully updated, false otherwise
-- @usage local updated = require('wtr').update_current_buffer(prev_path)
M.update_current_buffer = function(prev_path)
    if prev_path == nil then
        return false
    end

    local cwd = vim.loop.cwd()
    local current_buf_name = vim.api.nvim_buf_get_name(0)
    if not current_buf_name or current_buf_name == "" then
        return false
    end

    local name = Path:new(current_buf_name):absolute()
    local start, fin = string.find(name, cwd..Path.path.sep, 1, true)
    if start ~= nil then
        return true
    end

    start, fin = string.find(name, prev_path, 1, true)
    if start == nil then
        return false
    end

    local local_name = name:sub(fin + 2)

    local final_path = Path:new({cwd, local_name}):absolute()

    if not Path:new(final_path):exists() then
        return false
    end

    local bufnr = vim.fn.bufnr(final_path, true)
    vim.api.nvim_set_current_buf(bufnr)
    return true
end

--- Register a callback for worktree change events.
-- Callbacks are called with operation type and metadata when worktrees are
-- created, switched, or deleted.
--
-- @param cb function callback function(operation, metadata) called on changes
--   - operation: string "create", "switch", or "delete"
--   - metadata: table with operation-specific data (path, branch, upstream, prev_path)
-- @return nil
-- @usage require('wtr').on_tree_change(function(op, meta) print(op, meta.path) end)
M.on_tree_change = function(cb)
    table.insert(on_change_callbacks, cb)
end

--- Reset all registered callbacks.
-- Clears all previously registered on_tree_change callbacks.
--
-- @usage require('wtr').reset()
M.reset = function()
    on_change_callbacks = {}
end

--- Get the Git worktree root directory.
-- Returns the root directory of the Git repository containing worktrees.
--
-- @return string|nil root directory path, or nil if not in a worktree
-- @usage local root = require('wtr').get_root()
M.get_root = function()
    return git_worktree_root
end

--- Get the current worktree path.
-- Returns the path to the currently active worktree.
--
-- @return string|nil current worktree path, or nil if not in a worktree
-- @usage local current = require('wtr').get_current_worktree_path()
M.get_current_worktree_path = function()
    return current_worktree_path
end

--- Convert a worktree path to absolute.
-- Takes a relative or absolute path and returns the absolute path.
-- Relative paths are resolved relative to the git worktree root.
--
-- @param path string relative or absolute worktree path
-- @return string absolute path to worktree
-- @usage local abs_path = require('wtr').get_worktree_path('feature')
M.get_worktree_path = function(path)
    if Path:new(path):is_absolute() then
        return path
    else
        return Path:new(git_worktree_root, path):absolute()
    end
end

--- Initialize wtr.nvim with configuration.
-- Sets up the plugin with the provided configuration options.
-- Should be called once during Neovim startup.
--
-- @param config table|nil configuration options (see README for details)
--   - change_directory_command: string command to change directory (default: "cd")
--   - update_on_change: boolean update buffer on worktree switch (default: true)
--   - update_on_change_command: string fallback command (default: "e .")
--   - clearjumps_on_change: boolean clear jump list on switch (default: true)
--   - confirm_telescope_deletions: boolean require deletion confirmation (default: false)
--   - autopush: boolean auto-push new branches (default: false)
-- @usage require('wtr').setup({ autopush = true, change_directory_command = 'tcd' })
M.setup = function(config)
    config = config or {}
    M._config = vim.tbl_deep_extend("force", {
        change_directory_command = "cd",
        update_on_change = true,
        update_on_change_command = "e .",
        clearjumps_on_change = true,
        -- default to false to avoid breaking the previous default behavior
        confirm_telescope_deletions = false,
        -- should this default to true or false?
        autopush = false,
    }, config)
end

M.set_status = function(msg)
    -- TODO: make this so #1
end

M.setup()
M.Operations = Enum.Operations

return M
