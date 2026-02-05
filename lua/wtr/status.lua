--- wtr.nvim Status and Logging Module
-- Manages status reporting and logging for wtr operations.
-- @module wtr.status
-- @license MIT

local Status = {}

--- Configure logging level based on environment or global settings.
-- @return string log level ("trace", "debug", "info", "warn", "error", "fatal")
local function set_log_level()
    local log_levels = { "trace", "debug", "info", "warn", "error", "fatal" }
    local log_level = vim.env.WTR_NVIM_LOG or vim.g.wtr_log_level

    for _, level in pairs(log_levels) do
        if level == log_level then
            return log_level
        end
    end

    return "warn" -- default, if user hasn't set to one from log_levels
end


--- Create a new Status instance for operation tracking.
-- @param options table|nil optional configuration
-- @return Status new status instance
function Status:new(options)
    local obj = vim.tbl_extend('force', {
        logger = require("plenary.log").new({
            plugin = "wtr-nvim",
            level = set_log_level(),
        })
    }, options or {})

    setmetatable(obj, self)
    self.__index = self

    return obj
end

--- Reset the status counter for a new operation.
-- @param count number total steps for the operation
function Status:reset(count)
    self.count = count
    self.idx = 0
end

--- Format a status message with progress indicator.
-- @param msg string message to format
-- @return string formatted message with progress
function Status:_get_string(msg)
    return string.format("%d / %d: %s", self.idx, self.count, msg)
end

--- Report the next status message and increment counter.
-- @param msg string status message to display
function Status:next_status(msg)
    self.idx = self.idx + 1
    local fmt_msg = self:_get_string(msg)
    print(fmt_msg)
    self.logger.info(fmt_msg)
end

--- Report an error and increment counter.
-- This triggers an error exception that halts execution.
-- @param msg string error message to display
function Status:next_error(msg)
    self.idx = self.idx + 1
    local fmt_msg = self:_get_string(msg)
    error(fmt_msg)
    self.logger.error(fmt_msg)
end

--- Report a status message (non-sequential).
-- @param msg string status message to display
function Status:status(msg)
    local fmt_msg = self:_get_string(msg)
    print(fmt_msg)
    self.logger.info(fmt_msg)
end

--- Report an error message and halt execution.
-- @param msg string error message to display
function Status:error(msg)
    local fmt_msg = self:_get_string(msg)
    error(fmt_msg)
    self.logger.error(fmt_msg)
end

--- Get the underlying logger instance.
-- @return object plenary logger instance
function Status:log()
    return self.logger
end

return Status
