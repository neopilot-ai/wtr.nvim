# wtr.nvim

> **Git Worktree Orchestration for Neovim** - Seamlessly manage multiple git worktrees with a powerful Telescope integration.

[![Tests](https://github.com/neopilot-ai/wtr.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/neopilot-ai/wtr.nvim/actions/workflows/ci.yml)

## Overview

`wtr.nvim` is a Neovim plugin that simplifies working with [Git worktrees](https://git-scm.com/docs/git-worktree). It provides an intuitive interface through Telescope to create, switch between, and delete worktrees without leaving your editor. Perfect for parallel development workflows where you need to work on multiple branches simultaneously.

### Features

- ⚡ **Quick Worktree Management**: Create, switch, and delete worktrees from Telescope picker
- 🌿 **Branch Aware**: Automatically handles branch creation and upstream tracking
- 🔄 **Smart Directory Switching**: Automatically changes directory and updates buffers when switching worktrees
- 📍 **Callback System**: Hook into worktree lifecycle events (create, switch, delete)
- 🛠️ **Highly Configurable**: Customize behavior to match your workflow
- 📊 **Status Tracking**: Real-time status updates during operations
- 🚀 **Auto-Push Support**: Optional automatic push on worktree creation

## Installation

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'neopilot-ai/wtr.nvim',
  requires = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim'
  }
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'neopilot-ai/wtr.nvim'
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'neopilot-ai/wtr.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim'
  }
}
```

## Configuration

### Basic Setup

```lua
require('wtr').setup({
  change_directory_command = "cd",           -- Command to change directory
  update_on_change = true,                   -- Update current buffer when switching worktrees
  update_on_change_command = "e .",          -- Command to run when buffer can't be updated
  clearjumps_on_change = true,               -- Clear jump list when switching worktrees
  confirm_telescope_deletions = false,       -- Ask for confirmation before deleting
  autopush = false,                          -- Automatically push new branches to origin
})
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `change_directory_command` | string | `"cd"` | Command used to change directory (e.g., `"tcd"` for tab-local, `"lcd"` for local-window) |
| `update_on_change` | boolean | `true` | Whether to update current buffer when switching worktrees |
| `update_on_change_command` | string | `"e ."` | Fallback command if buffer can't be updated intelligently |
| `clearjumps_on_change` | boolean | `true` | Clear the jump list when switching worktrees |
| `confirm_telescope_deletions` | boolean | `false` | Require confirmation before deleting a worktree |
| `autopush` | boolean | `false` | Automatically push newly created branches upstream |

### Logging

Configure logging level via environment variable or global setting:

```bash
# Via environment variable
WTR_NVIM_LOG=debug nvim

# Via Neovim configuration
vim.g.wtr_log_level = "debug"  -- Options: trace, debug, info, warn, error, fatal
```

## Usage

### Telescope Commands

Load the extension in your Neovim config:

```lua
require('telescope').load_extension('wtr')
```

Then use these commands:

| Command | Description |
|---------|-------------|
| `:Telescope wtr` | List and switch to existing worktrees |
| `:Telescope wtr create_wtr` | Create a new worktree (select branch, enter path) |

### Telescope Keybindings

When viewing worktrees in Telescope:

| Keymap | Description |
|--------|-------------|
| `<CR>` | Switch to selected worktree |
| `<C-d>` | Delete selected worktree (force on next use with `<C-f>`) |
| `<C-f>` | Toggle forced deletion for next delete operation |

### Lua API

```lua
local wtr = require('wtr')

-- Create a new worktree
wtr.create_worktree('path/to/worktree', 'branch-name', 'origin')

-- Switch to a worktree
wtr.switch_worktree('path/to/worktree')

-- Delete a worktree
wtr.delete_worktree('path/to/worktree', force, {
  on_success = function() print("Deleted!") end,
  on_failure = function(err) print("Error:", err) end
})

-- Get root git directory
local root = wtr.get_root()

-- Get current worktree path
local current = wtr.get_current_worktree_path()

-- Hook into worktree lifecycle events
wtr.on_tree_change(function(operation, metadata)
  -- operation: "create", "switch", or "delete"
  -- metadata: table with operation details (path, branch, upstream, prev_path)
  print(operation, vim.inspect(metadata))
end)
```

## Examples

### Example Configuration

```lua
require('wtr').setup({
  change_directory_command = "tcd",            -- Tab-local directory change
  update_on_change = true,
  clearjumps_on_change = true,
  confirm_telescope_deletions = true,
  autopush = true,                            -- Auto-push to origin
})

require('telescope').load_extension('wtr')

-- Custom keybindings
vim.keymap.set('n', '<leader>tw', ':Telescope wtr<CR>', { noremap = true })
vim.keymap.set('n', '<leader>tc', ':Telescope wtr create_wtr<CR>', { noremap = true })

-- Monitor worktree changes
require('wtr').on_tree_change(function(op, meta)
  if op == "switch" then
    print("Switched to: " .. meta.path)
  end
end)
```

## Workflow Examples

### Feature Development Workflow

```bash
# Start working on a feature in main branch
:Telescope wtr                # List existing worktrees
:Telescope wtr create_wtr     # Select "feature-branch" or "main", enter path
# Creates worktree and switches to it
:Telescope wtr                # Switch back to main
:Telescope wtr                # Switch to feature branch
```

### Parallel Work

Use multiple worktrees for simultaneous development:
- Main branch worktree: For reviewing and merging
- Feature branch worktrees: Isolated feature development
- Hotfix worktree: Quick bug fixes

## Troubleshooting

### Worktree not switching

- Ensure git recognizes the worktree: `git worktree list`
- Check that the path exists: `ls path/to/worktree`
- Try setting `update_on_change = false` in config

### Branch not found

- Fetch latest branches: `git fetch --all`
- Create worktree without upstream: just enter the path without upstream specification

### Files not updating

- Set `update_on_change_command` to `"e ."` to reload current directory
- Or manually update with `:set autochdir` or `:cd!`

### Permission denied errors

- Use `<C-f>` toggle in Telescope, then `<C-d>` to force delete
- Use `wtr.delete_worktree(path, true)` in Lua with force flag

## Architecture

```
wtr.nvim/
├── lua/
│   ├── wtr/
│   │   ├── init.lua      # Main module and core logic
│   │   ├── status.lua    # Status and logging management
│   │   ├── enum.lua      # Operation enumerations
│   │   └── test.lua      # Test utilities
│   └── telescope/
│       └── _extensions/
│           └── wtr.lua   # Telescope picker integration
```

## Development

### Running Tests

```bash
make test
```

### Building from Source

```bash
git clone https://github.com/neopilot-ai/wtr.nvim
cd wtr.nvim
# Follow installation instructions above
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request on the `dev` branch

## License

This project is licensed under the MIT License - see LICENSE file for details.

## Acknowledgments

- Built with [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for core utilities
- Telescope integration via [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- Inspired by git worktree workflows and parallel development practices

## Support

- 📖 [Git Worktrees Documentation](https://git-scm.com/docs/git-worktree)
- 💬 Issues: [GitHub Issues](https://github.com/neopilot-ai/wtr.nvim/issues)
- 🐛 Report bugs with reproduction steps

---

Made with ❤️ by the Neovim community
