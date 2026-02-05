# wtr.nvim Configuration Guide

Complete reference for configuring `wtr.nvim` to suit your development workflow.

## Basic Setup

```lua
require('wtr').setup({
  change_directory_command = "cd",
  update_on_change = true,
  update_on_change_command = "e .",
  clearjumps_on_change = true,
  confirm_telescope_deletions = false,
  autopush = false,
})
```

## Configuration Options

### `change_directory_command`

**Type:** `string`  
**Default:** `"cd"`

The Vim command used to change directories when switching worktrees.

#### Options:
- `"cd"` - Change directory globally
- `"tcd"` - Change directory for the current tab only
- `"lcd"` - Change directory for the current window only

#### Example:
```lua
require('wtr').setup({
  change_directory_command = "tcd"  -- Tab-local directory changes
})
```

**Use Case:** Use `tcd` if you want different worktrees open in different tabs, each with their own directory context.

---

### `update_on_change`

**Type:** `boolean`  
**Default:** `true`

Whether to automatically update the current buffer's file when switching worktrees.

When enabled, wtr attempts to find the same file in the new worktree (by relative path) and opens it. If the file doesn't exist in the new worktree, the `update_on_change_command` is executed instead.

#### Example:
```lua
require('wtr').setup({
  update_on_change = true  -- Automatically update buffer when switching
})
```

**Use Case:** Keep this enabled for seamless context switching between worktrees.

---

### `update_on_change_command`

**Type:** `string`  
**Default:** `"e ."`

Fallback command to execute if `update_on_change` cannot find the file in the new worktree.

#### Options:
- `"e ."` - Open the current directory browser
- `"Telescope find_files"` - Open Telescope file finder
- `"NvimTreeToggle"` - Open NvimTree (if using nvim-tree)
- Any valid Vim command

#### Example:
```lua
require('wtr').setup({
  update_on_change_command = "Telescope find_files"  -- Use Telescope when file not found
})
```

**Use Case:** Choose based on your preferred file navigation method.

---

### `clearjumps_on_change`

**Type:** `boolean`  
**Default:** `true`

Whether to clear the jump list (`:jumps`) when switching worktrees.

This prevents Vim from jumping to outdated locations in the previous worktree.

#### Example:
```lua
require('wtr').setup({
  clearjumps_on_change = true  -- Clear jump history
})
```

**Use Case:** Keep this enabled unless you specifically want to preserve jump history across worktrees.

---

### `confirm_telescope_deletions`

**Type:** `boolean`  
**Default:** `false`

Whether to require confirmation before deleting a worktree via the Telescope picker.

When enabled, you'll be prompted: `Delete worktree? [y/n]:` before deletion occurs.

#### Example:
```lua
require('wtr').setup({
  confirm_telescope_deletions = true  -- Require confirmation
})
```

**Use Case:** Enable for safety if you frequently delete worktrees and want extra protection against accidental deletion.

---

### `autopush`

**Type:** `boolean`  
**Default:** `false`

Whether to automatically push newly created branches to the upstream remote.

When enabled and a branch is created with an upstream remote:
1. Branch is created locally
2. Upstream tracking is configured
3. Branch is pushed to the remote
4. Rebase is performed

#### Example:
```lua
require('wtr').setup({
  autopush = true  -- Automatically push branches to origin
})
```

**Use Case:** Enable if your workflow requires immediate branch availability on the remote.

---

## Logging Configuration

Configure logging level to see more or less debug information.

### Via Environment Variable

```bash
# Set before launching nvim
WTR_NVIM_LOG=debug nvim

# Or in a shell configuration
export WTR_NVIM_LOG=debug
nvim
```

### Via Vim Configuration

```lua
-- In your init.lua
vim.g.wtr_log_level = "debug"

require('wtr').setup()
```

### Log Levels (from least to most verbose)

- `error` - Only errors
- `warn` - Errors and warnings  (default)
- `info` - General information
- `debug` - Detailed debug information
- `trace` - Very detailed trace information
- `fatal` - Only fatal errors

#### Example:
```lua
-- Neovim startup
vim.g.wtr_log_level = "debug"
require('wtr').setup()
```

---

## Advanced Recipes

### Recipe 1: Multi-Tab Workflow

Keep multiple worktrees open in different tabs:

```lua
require('wtr').setup({
  change_directory_command = "tcd",      -- Tab-local directory changes
  clearjumps_on_change = true,           -- Clear jumps per tab
  update_on_change = true,               -- Update buffer per tab
})
```

### Recipe 2: Auto-Push to Remote

Automatically push branches when creating worktrees:

```lua
require('wtr').setup({
  autopush = true,                       -- Push branches automatically
  change_directory_command = "cd",       -- Global directory change
  confirm_telescope_deletions = true,    -- Safer deletion
})
```

### Recipe 3: Conservative (Safe) Setup

Minimal automation, maximum control:

```lua
require('wtr').setup({
  change_directory_command = "cd",
  update_on_change = false,              -- Manual buffer updates
  update_on_change_command = "Telescope find_files",
  clearjumps_on_change = false,          -- Keep jump history
  confirm_telescope_deletions = true,    -- Confirm deletions
  autopush = false,                      -- Manual push
})
```

### Recipe 4: NvimTree Integration

If using nvim-tree:

```lua
require('wtr').setup({
  change_directory_command = "cd",
  update_on_change_command = "NvimTreeOpen",  -- Open file tree on change
  clearjumps_on_change = true,
})
```

---

## Migrating from Other Tree Managers

### From Git Branches in Telescope

If you were using Telescope's `git_branches`, switch to wtr's integration:

```lua
-- Old way with just Telescope
require('telescope.builtin').git_branches()

-- New way with wtr
require('telescope').load_extension('wtr')
:Telescope wtr
```

---

## Troubleshooting Configuration

### Issue: Buffer not updating when switching worktrees

**Solution:** Ensure `update_on_change` is set to `true` and the file exists in both worktrees with the same relative path.

```lua
require('wtr').setup({
  update_on_change = true,
  update_on_change_command = "e .",  -- Fallback
})
```

### Issue: Directory not changing

**Solution:** Check that your `change_directory_command` is valid in Neovim.

```lua
-- Test your command
:cd  -- Test basic cd
:tcd  -- Test tab-local cd
:lcd  -- Test window-local cd

-- Then configure wtr
require('wtr').setup({
  change_directory_command = "tcd"  -- Or whichever works for you
})
```

### Issue: Jump list being preserved incorrectly

**Solution:** Toggle `clearjumps_on_change`:

```lua
require('wtr').setup({
  clearjumps_on_change = false  -- Keep jump history across worktrees
})
```

### Issue: Too many debug messages

**Solution:** Set logging level to `warn` or `error`:

```lua
vim.g.wtr_log_level = "error"  -- Only show errors
require('wtr').setup()
```

---

## Runtime Customization

You can also customize behavior at runtime using callbacks:

```lua
local wtr = require('wtr')

-- Execute custom actions on worktree changes
wtr.on_tree_change(function(operation, metadata)
  if operation == "switch" then
    -- Do something when switching
    print("Switched to: " .. metadata.path)
  elseif operation == "create" then
    -- Do something when creating
    print("Created worktree for branch: " .. metadata.branch)
  elseif operation == "delete" then
    -- Do something when deleting
    print("Deleted: " .. metadata.path)
  end
end)
```

---

## Default Configuration

Here's the complete default configuration:

```lua
{
  change_directory_command = "cd",
  update_on_change = true,
  update_on_change_command = "e .",
  clearjumps_on_change = true,
  confirm_telescope_deletions = false,
  autopush = false,
}
```
