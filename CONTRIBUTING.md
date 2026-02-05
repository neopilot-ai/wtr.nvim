# Contributing to wtr.nvim

Thank you for your interest in contributing to wtr.nvim! This guide will help you get started.

## Getting Started

### Prerequisites

- Neovim 0.5+
- Git
- Lua 5.1+
- Make (for running tests)

### Setup Development Environment

1. Clone the repository:
```bash
git clone https://github.com/neopilot-ai/wtr.nvim
cd wtr.nvim
```

2. Install dependencies:
```bash
git clone --depth 1 https://github.com/nvim-lua/plenary.nvim ~/.local/share/nvim/site/pack/vendor/start/plenary.nvim
git clone --depth 1 https://github.com/nvim-telescope/telescope.nvim ~/.local/share/nvim/site/pack/vendor/start/telescope.nvim
```

3. Run tests:
```bash
make test
```

## Project Structure

```
wtr.nvim/
├── lua/
│   ├── wtr/
│   │   ├── init.lua       # Main module with public API
│   │   ├── status.lua     # Status and progress tracking
│   │   ├── enum.lua       # Operation enumerations
│   │   ├── logger.lua     # Logging utilities (new)
│   │   ├── utils.lua      # Helper utilities (new)
│   │   └── test.lua       # Test utilities
│   └── telescope/
│       └── _extensions/
│           └── wtr.lua    # Telescope integration
├── tests/                 # Test files (if present)
├── README.md              # Main documentation
├── CONFIG.md              # Configuration reference
├── Makefile               # Build and test automation
└── .github/
    └── workflows/
        └── ci.yml         # GitHub Actions CI
```

## Coding Guidelines

### Lua Style

- Use 4 spaces for indentation
- Use snake_case for variables and functions
- Use UPPER_CASE for constants
- Use descriptive variable names

Example:
```lua
-- Good
function M.create_worktree(path, branch, upstream)
    local git_root = M.get_root()
    -- ...
end

-- Avoid
function M.cw(p, b, u)
    local gr = M.get_root()
    -- ...
end
```

### Documentation

All public functions must have LDoc-style documentation comments:

```lua
--- Brief description of function.
-- Longer description explaining behavior, edge cases, etc.
--
-- @param arg1 type|type2 description of arg1
-- @param arg2 type description of arg2
-- @return type1 description of return value
-- @usage M.function(arg1, arg2)
function M.function(arg1, arg2)
    -- implementation
end
```

### Error Handling

Use the error handling utilities:

```lua
-- Bad
if not found then
    print("Error: not found")
end

-- Good
if not found then
    status:error("Worktree not found at " .. path)
end
```

## Making Changes

1. **Create a feature branch:**
```bash
git checkout -b feature/my-feature
```

2. **Make your changes:**
   - Keep commits focused and atomic
   - Write clear commit messages
   - Add tests for new functionality

3. **Test your changes:**
```bash
make test
```

4. **Push to your fork:**
```bash
git push origin feature/my-feature
```

5. **Create a Pull Request:**
   - Target the `dev` branch
   - Provide a clear description of changes
   - Reference any related issues
   - Ensure CI passes

## Common Tasks

### Adding a New Feature

1. Add the feature to the appropriate module (usually [init.lua](lua/wtr/init.lua))
2. Document with LDoc comments
3. Export in the module's return statement
4. Add tests if applicable
5. Update README.md if user-facing
6. Update CONFIG.md if configuration changes

### Fixing a Bug

1. Create a feature branch: `git checkout -b fix/issue-name`
2. Add a test that demonstrates the bug
3. Fix the bug
4. Verify the test passes
5. Create a pull request with the fix

### Improving Documentation

1. Update the relevant file (README.md, CONFIG.md, etc.)
2. Keep examples accurate and up-to-date
3. Test any code examples you add
4. Keep language clear and concise

## Testing

### Running Tests

```bash
make test
```

### Writing Tests

Tests are located in the `tests/` directory. Follow the Plenary test format:

```lua
describe("wtr", function()
    it("should create a worktree", function()
        -- test implementation
    end)
    
    it("should switch worktrees", function()
        -- test implementation
    end)
end)
```

## Code Review Process

We review all pull requests. A maintainer will:

1. Review your code for style and correctness
2. Suggest improvements if needed
3. Request changes if necessary
4. Approve and merge when ready

Please be open to feedback - we value all contributions!

## Reporting Issues

When reporting a bug, please include:

1. **Minimal reproduction steps:**
   - How to trigger the issue
   - Expected vs actual behavior

2. **Environment info:**
   - Neovim version (`nvim --version`)
   - wtr.nvim version (branch/commit)
   - Relevant configuration

3. **Logs:**
   - Set `WTR_NVIM_LOG=debug` for debug output
   - Share relevant log entries

Example:
```
**Description:** Worktree creation fails when branch contains special characters

**Steps to reproduce:**
1. Try creating a worktree for branch `hotfix/my-fix-#123`
2. See error: "Invalid branch name"

**Environment:**
- Neovim v0.8.0
- wtr.nvim dev branch
- git version 2.40

**Logs:**
```

## Getting Help

- 📖 Check [README.md](README.md) and [CONFIG.md](CONFIG.md)
- 💬 Discuss in GitHub Issues
- 🔍 Search existing issues for similar problems
- 📝 Review code comments and LDoc documentation

## Commit Message Guidelines

Follow conventional commits style:

```
feat: add support for bare repositories
fix: handle error when worktree already exists
docs: update config documentation
refactor: extract utility functions
perf: optimize path resolution
test: add tests for error handling
chore: update dependencies
```

Format:
```
<type>(<scope>): <subject>

<body>

<footer>
```

- `type`: feat, fix, docs, refactor, perf, test, chore
- `scope`: optional, e.g., (status), (telescope)
- `subject`: imperative, lowercase, no period
- `body`: optional, explain what and why
- `footer`: optional, reference issues

## Code of Conduct

Be respectful, inclusive, and constructive. We're all volunteering here!

## Recognition

Contributors will be recognized in:
- Commit history
- Release notes (for significant contributions)
- CONTRIBUTORS file (coming soon)

## Questions?

Feel free to:
- Open an issue for discussion
- Comment on relevant PRs
- Reach out to maintainers

Thank you for contributing to wtr.nvim! 🎉
