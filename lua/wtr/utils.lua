--- wtr.nvim Utility Module
-- Provides utility functions for wtr operations.
-- @module wtr.utils
-- @license MIT

local Path = require("plenary.path")
local Job = require("plenary.job")

local Utils = {}

--- Normalize a path to absolute form.
-- @param path string relative or absolute path
-- @param base_path string base path for relative paths
-- @return string absolute path
function Utils.normalize_path(path, base_path)
    if Path:new(path):is_absolute() then
        return path
    else
        return Path:new(base_path, path):absolute()
    end
end

--- Check if a path exists.
-- @param path string path to check\n-- @return boolean true if path exists\nfunction Utils.path_exists(path)\n    return Path:new(path):exists()\nend\n\n--- Get the relative path from base to target.\n-- @param base string base path\n-- @param target string target path\n-- @return string|nil relative path, or nil if paths don't overlap\nfunction Utils.get_relative_path(base, target)\n    local base_path = Path:new(base):absolute()\n    local target_path = Path:new(target):absolute()\n    \n    if target_path:starts_with(base_path) then\n        local rel = target_path._path:sub(#base_path._path + 2)\n        return rel\n    end\n    \n    return nil\nend\n\n--- Create a Job for running a shell command.\n-- @param cmd table|string command and args\n-- @param opts table job options (cwd, on_stdout, etc.)\n-- @return Job new job instance\nfunction Utils.create_job(cmd, opts)\n    opts = opts or {}\n    \n    if type(cmd) == \"string\" then\n        cmd = { cmd }\n    end\n    \n    local job_opts = vim.tbl_extend(\"force\", {\n        command = cmd[1],\n        args = vim.tbl_slice(cmd, 2),\n    }, opts)\n    \n    return Job:new(job_opts)\nend\n\n--- Run a command synchronously and return output.\n-- @param cmd table command and args\n-- @param opts table job options (cwd, etc.)\n-- @return table|nil stdout lines, or nil on error\n-- @return number|nil exit code\nfunction Utils.run_command(cmd, opts)\n    opts = opts or {}\n    \n    local job = Utils.create_job(cmd, opts)\n    local stdout, code = job:sync()\n    \n    if code == 0 then\n        return stdout, code\n    end\n    \n    return nil, code\nend\n\n--- Trim whitespace from a string.\n-- @param str string string to trim\n-- @return string trimmed string\nfunction Utils.trim(str)\n    return vim.trim(str)\nend\n\n--- Split a string by a separator.\n-- @param str string string to split\n-- @param sep string separator pattern\n-- @return table table of split parts\nfunction Utils.split(str, sep)\n    return vim.split(str, sep)\nend\n\n--- Check if a string starts with a prefix.\n-- @param str string string to check\n-- @param prefix string prefix to match\n-- @return boolean true if starts with prefix\nfunction Utils.starts_with(str, prefix)\n    return str:sub(1, #prefix) == prefix\nend\n\n--- Check if a string ends with a suffix.\n-- @param str string string to check\n-- @param suffix string suffix to match\n-- @return boolean true if ends with suffix\nfunction Utils.ends_with(str, suffix)\n    return str:sub(-#suffix) == suffix\nend\n\n--- Merge two tables deeply.\n-- @param base table base table\n-- @param override table override table\n-- @return table merged table\nfunction Utils.deep_merge(base, override)\n    return vim.tbl_deep_extend(\"force\", base, override)\nend\n\n--- Convert table to string representation for debugging.\n-- @param tbl table table to convert\n-- @return string string representation\nfunction Utils.inspect(tbl)\n    return vim.inspect(tbl)\nend\n\nreturn Utils\n