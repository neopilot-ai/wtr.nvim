--- wtr.nvim Logging Module
-- Provides a clean logging interface for wtr operations.
-- Wraps plenary.log and provides convenience methods.
-- @module wtr.logger
-- @license MIT

local Logger = {}

--- Set the logging level for the application.
-- @param level string one of: "trace", "debug", "info", "warn", "error", "fatal"
-- @return boolean true if level was valid, false otherwise
local function set_log_level(level)
    local valid_levels = { "trace", "debug", "info", "warn", "error", "fatal" }
    
    -- Check if level is valid
    for _, valid in ipairs(valid_levels) do
        if level == valid then
            return true
        end
    end
    
    return false
end

--- Get the current logging level.
-- Checks environment variable and Neovim global settings.
-- @return string current log level
local function get_log_level()
    local log_levels = { "trace", "debug", "info", "warn", "error", "fatal" }
    local log_level = vim.env.WTR_NVIM_LOG or vim.g.wtr_log_level
    
    for _, level in ipairs(log_levels) do
        if level == log_level then
            return log_level
        end
    end
    
    return "warn" -- default
end

--- Create a new Logger instance.
-- @param name string plugin name (defaults to "wtr-nvim")
-- @return Logger new logger instance
function Logger:new(name)
    local obj = {
        plugin_name = name or "wtr-nvim",
        _logger = nil
    }
    
    setmetatable(obj, self)
    self.__index = self
    
    -- Initialize the underlying plenary logger
    obj._logger = require("plenary.log").new({
        plugin = obj.plugin_name,
        level = get_log_level(),
    })
    
    return obj
end

--- Log a trace message.
-- @param msg string message to log
function Logger:trace(msg)
    if self._logger then
        self._logger.trace(msg)
    end
end

--- Log a debug message.
-- @param msg string message to log
function Logger:debug(msg)
    if self._logger then
        self._logger.debug(msg)
    end
end

--- Log an info message.
-- @param msg string message to log
function Logger:info(msg)
    if self._logger then
        self._logger.info(msg)
    end
end

--- Log a warning message.
-- @param msg string message to log
function Logger:warn(msg)
    if self._logger then
        self._logger.warn(msg)
    end
end

--- Log an error message.
-- @param msg string message to log
function Logger:error(msg)
    if self._logger then
        self._logger.error(msg)
    end
end

--- Log a fatal error message.
-- @param msg string message to log
function Logger:fatal(msg)
    if self._logger then
        self._logger.fatal(msg)
    end
end

--- Get the underlying plenary logger.
-- Use this for advanced logging operations.
-- @return object plenary logger instance
function Logger:get()
    return self._logger
end

--- Set the log level for this logger.
-- @param level string one of: "trace", "debug", "info", "warn", "error", "fatal"
-- @return boolean true if successfully set, false if invalid level
function Logger:set_level(level)
    if set_log_level(level) then
        if self._logger then
            self._logger.level = level
        end
        return true
    end
    return false
end

--- Log multiple messages with a prefix.
-- Useful for structured error reporting.
-- @param prefix string prefix for all messages
-- @param messages table array of strings or one string
-- @param level string log level (defaults to "info")
function Logger:log_group(prefix, messages, level)
    level = level or "info"
    
    if type(messages) == "string" then
        messages = { messages }
    end
    
    for _, msg in ipairs(messages) do
        local formatted = string.format("[%s] %s", prefix, msg)
        self[level](self, formatted)
    end
end

return Logger
