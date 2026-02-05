# wtr.nvim TODO & Issues

This document tracks known issues, planned features, and areas for improvement.

## High Priority

- [ ] **Async Job Communication** - Currently jobs are chained sequentially. Implement better async/await pattern for improved performance.
- [ ] **Comprehensive Test Suite** - Expand test coverage for all public functions and edge cases.
- [ ] **Windows Support** - Test and fix Windows compatibility issues with path handling.

## Medium Priority

- [ ] **Shell Integration** - Add shell functions for quick worktree management from terminal.
- [ ] **Vim Integration** - Add commands like `:WtrCreate`, `:WtrSwitch`, `:WtrDelete` for quicker access.
- [ ] **Status Line Integration** - Show current worktree info in status line.
- [ ] **Better Error Recovery** - Improve error handling when git operations fail midway.
- [ ] **Branch Tracking** - Display tracking status in picker (ahead/behind commits).
- [ ] **Bare Repository Support** - Better handling of bare repositories.

## Low Priority - Nice to Have

- [ ] **Fuzzy Finder Alternatives** - Support for fzf, fzy, ctrlp
- [ ] **Worktree Templates** - Save and reuse worktree configurations
- [ ] **Performance Metrics** - Show operation timing in status
- [ ] **Configuration Validation** - Validate config on setup
- [ ] **Auto-cleanup** - Detect and remove stale worktrees

## Known Issues

### Issue #1: Status Messages Everywhere
**Status:** Open  
**Description:** The status object is referenced throughout the code, making it hard to test and refactor.  
**Fix:** Inject status/logger as dependency instead of global reference.  
**Impact:** Medium  
**Code References:**
- [lua/wtr/init.lua](lua/wtr/init.lua#L250)
- [lua/wtr/enum.lua](lua/wtr/enum.lua)

### Issue #2: Async/Await Patterns
**Status:** Open  
**Description:** Job chaining with `and_then` is hard to follow and debug.  
**Fix:** Implement async/await or promise-like pattern.  
**Impact:** High  
**Code References:**
- [lua/wtr/init.lua](lua/wtr/init.lua#L420-L450)

### Issue #3: Worktree Path Resolution
**Status:** Open  
**Description:** Local vs absolute path handling has hacks and edge cases.  
**Fix:** Refactor path resolution into utils module with comprehensive tests.  
**Impact:** Medium  
**Code References:**
- [lua/wtr/init.lua](lua/wtr/init.lua#L200-L220)
- Comment: "This is clearly a hack (do not think we need this anymore?)"

### Issue #4: Configuration Immutability
**Status:** Open  
**Description:** `M._config` can be modified after setup, potentially breaking behavior.  
**Fix:** Make config read-only or store in private table.  
**Impact:** Low  
**Code References:**
- [lua/wtr/init.lua](lua/wtr/init.lua#L600)

### Issue #5: Origin Remote Hardcoding
**Status:** Open  
**Description:** Assumes "origin" is always the upstream remote.  
**Fix:** Allow configuration of upstream remote name.  
**Impact:** Medium  
**Code References:**
- [lua/wtr/init.lua](lua/wtr/init.lua#L330) - Comment: "How to configure origin??? Should upstream ever be the push destination?"

## Completed / Fixed

- [x] Add comprehensive README documentation
- [x] Add LDoc comments to public functions
- [x] Improve error messages
- [x] Create logger module
- [x] Create utils module
- [x] Add CONFIG.md
- [x] Add CONTRIBUTING.md

## Testing TODOs

- [ ] Unit tests for path resolution
- [ ] Unit tests for git operations
- [ ] Integration tests with actual git repos
- [ ] Error handling tests
- [ ] Edge case tests for special branch names
- [ ] Performance benchmarks

## Documentation TODOs

- [ ] API reference documentation
- [ ] Troubleshooting guide improvements
- [ ] Video walkthrough/demo
- [ ] GIF examples in README

## Performance TODOs

- [ ] Cache git info to avoid redundant commands
- [ ] Optimize worktree list parsing
- [ ] Add operation timeouts to prevent hangs
- [ ] Profile and optimize hot paths

## Refactoring Opportunities

### Telescope Extension
[lua/telescope/_extensions/wtr.lua](lua/telescope/_extensions/wtr.lua) could be split into:
- `telescope/actions.lua` - Picker actions
- `telescope/displayer.lua` - Display formatting
- `telescope/picker.lua` - Picker creation

### Main Module
[lua/wtr/init.lua](lua/wtr/init.lua) could be split into:
- `core.lua` - Core operations
- `validation.lua` - Git info validation
- `jobs.lua` - Job creation and management

### Status/Logger
Consider merging status.lua and logger.lua or providing better separation of concerns.

## Feature Requests (from users)

- Delete worktree via keyboard shortcut in picker
- Rename worktrees
- List only worktrees for a specific branch pattern
- Auto-delete old worktrees based on age
- Worktree search history
- Quick switch to most recently used worktree

## Dependencies to Review

- `plenary.nvim` - Consider if we need all of it
- `telescope.nvim` - Optional dependency?
- Git version requirements

## CI/CD Improvements

- [ ] Expand CI to test on multiple Neovim versions
- [ ] Add linting (luacheck)
- [ ] Add code coverage reports
- [ ] Add documentation build
- [ ] Test on macOS and Windows

## Notes

- This project started as a wrapper around git worktree commands
- Main complexity is in async job management and state tracking
- Telescope integration is the primary user interface
- Core functionality is stable but has technical debt

## How to Help

Pick any item above and implement it! Please:
1. Open an issue first to discuss approach
2. Create a feature branch
3. Submit a pull request with tests and docs
4. Update this file when completing items

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.
