# AGENTS.md

This repository is designed for managing shared buffers in Neovim using Lua. This guide is intended for agents working within this codebase to ensure consistency and provide guidelines for contributing, building, and testing the code.

---

## Table of Contents

1. **Build, Lint, and Test Commands**
   - Running the code
   - Linting the code
   - Testing the code
   - Running a single test

2. **Code Style Guidelines**
   - Imports and dependencies
   - Formatting rules
   - Variable and function naming conventions
   - Code structure
   - Error handling

---

## 1. Build, Lint, and Test Commands

### Running the Code
This project is a Neovim plugin implemented in Lua. To test its functionality within Neovim:

1. Copy the repository to your local `~/.config/nvim/pack/plugins/start` folder.
2. Restart Neovim to automatically load the plugin.
3. Use the exposed API functions (like `M.setup()` or `M.setupWBuff()`) within your Neovim configuration for development and testing.

Alternatively, you can install the plugin using a plugin manager such as `packer.nvim` or `vim-plug` by pointing them to this repository.

### Linting the Code
To ensure code quality, use `luacheck`, a linter for Lua:

```bash
luacheck lua/
```

This will check the Lua scripts in the `lua/` directory for syntax issues and coding standards.

### Testing the Code
Unit tests for the project can be executed using [busted](https://olivinelabs.com/busted/), a Lua testing framework. To run all the tests, use the following command:

```bash
busted
```

### Running a Single Test
To execute a single test suite or a specific test case:

1. Specify the path to the test file and the test name (if needed):
    ```bash
    busted spec/path_to_test_file.lua
    ```
2. To run only a specific test within the file, use the `--filter` option:
    ```bash
    busted spec/path_to_test_file.lua --filter "test description"
    ```

---

## 2. Code Style Guidelines

To maintain consistency and readability, follow these guidelines when contributing to the codebase.

### Imports and Dependencies
- Use `require` to import Lua modules.
- For accessing Neovim-specific APIs, always use the `vim` Lua API.
- Group imports at the top of your files.
- External dependencies should be clearly documented.

### Formatting Rules
- Use **2 spaces for indentation** (preferred convention for Lua).
- Avoid trailing whitespace.
- Use single quotes (`'`) for strings unless the string itself contains a single quote.
- Align assignment operators (`=`) and tables neatly when they span multiple lines:

  ```lua
  local config = {
      key1 = "value1",
      key2 = "value2",
  }
  ```

### Variable and Function Naming Conventions
- Use `snake_case` for variables and function names.
- Constants should be **uppercase** with words separated by underscores:
  ```lua
  local BUFFER_ID = 1
  ```
- Prefix private functions with an underscore (`_`). Public functions are declared as part of the module.
- Use clear, descriptive names for variables and functions.

### Code Structure
- Structure the module with local helper functions at the top, followed by publicly exposed module functions.

  Example:
  ```lua
  -- Local helper function
test()
  
  -- Public module function 
return M
  ```

- Functions should generally be small, performing a single task. Larger functionality should be split into smaller helper functions.

### Error Handling
- Always validate inputs before using them, e.g., check for `nil` values, expected types, or empty inputs.
- Use `vim.fn` where possible to handle filesystem and buffer operations.
  - Example:
    ```lua
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end
    ```

- If a critical operation (e.g. filesystem operations or parsing JSON) fails, provide a fallback value or log an error message with `vim.notify()`:

  ```lua
  if condition_not_met then
      vim.notify('An error occurred: message', vim.log.level.ERROR)
  end
  ```

- Ensure cleanup functions (e.g., closing file handles or buffers) are implemented when needed.

---

### General Best Practices
- Avoid global variables unless absolutely necessary.
- Add docstrings to all functions, explaining their purpose and parameters.
- Keep functions side-effect free unless explicitly necessary.
- Avoid hardcoding file paths, use `vim.fn.stdpath()` to derive paths.
- Always attach error-handling callbacks for asynchronous operations such as file-system events:
    ```lua
    vim.loop.new_fs_event():start(filepath, {}, vim.schedule_wrap(function()
        -- handle file change
    end))
    ```
---