--- wtr.nvim Enumeration Module
-- Defines immutable enumerations used throughout wtr.nvim.
-- @module wtr.enum
-- @license MIT

--- Create an immutable enum from a table.
-- @param tbl table enum values
-- @return table immutable enum
local Enum = function(tbl)
    return setmetatable(tbl, {
        __index = function(_, key)
            error(string.format("Enum value '%s' does not exist for this enum.", key))
        end,

        __newindex = function(t, key, value)
            error("Enums are immutable. You cannot set new values.")
        end,
    })
end

return {
    --- Worktree operation types.
    -- @table Operations
    -- @field Create "create" - Worktree was created
    -- @field Switch "switch" - Switched to a different worktree
    -- @field Delete "delete" - Worktree was deleted
    Operations = Enum({
        Create = "create",
        Switch = "switch",
        Delete = "delete",
    })
}
