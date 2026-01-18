# Shared Buffer.nvim

`shared_buffer.nvim` is a Neovim plugin written in Lua that offers efficient management for shared buffers. It provides functionalities for persisting the state and content of buffers, ensuring that your work is both synchronized and durable. It's especially useful for users working with temporary buffers or interactive workflows.

## Features

- **State Management**: Save and load the state of shared buffers to/from JSON files.
- **Buffer Content Synchronization**: Automatically save and load buffer content to and from file storage.
- **Automatic Directory Management**: Ensures necessary directories exist for storing buffer states and content.
- **File Watching**: Automatically updates buffer content when related files change.
- **Error Handling**: Logs detailed error messages using `vim.notify()`.

## Installation

You can add `shared_buffer.nvim` using your favorite Neovim plugin manager. Here are examples for the most popular ones:

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use 'fmpisantos/shared_buffer.nvim'
```

### Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'fmpisantos/shared_buffer.nvim'
```

After adding the plugin to your list, restart Neovim and run `:PackerInstall` (for packer) or `:PlugInstall` (for vim-plug).

Alternatively, you can clone this repository into your `~/.config/nvim/pack/plugins/start` directory as follows:

```bash
git clone https://github.com/fmpisantos/shared_buffer.nvim ~/.config/nvim/pack/plugins/start/shared_buffer.nvim
```

Restart Neovim to load the plugin.

## Usage

### Basic Setup

Call the `setup` function with a unique type identifier to initialize the state.

```lua
local shared_buffer = require('shared_buffer')

local state, save_state = shared_buffer.setup("my_type")

-- You can use `state` to manage your buffer state and call `save_state` to persist changes.
```

### Setup with Shared Buffer

The `setupWBuff` function creates a shared buffer, synchronizes its content to disk, and watches for changes in external files. Use it as follows:

```lua
local shared_buffer = require('shared_buffer')

local bufnr = shared_buffer.setupWBuff("my_shared_buffer")

if bufnr then
    -- Interact with the buffer using `bufnr`
    -- e.g., Jump to the buffer: `vim.api.nvim_set_current_buf(bufnr)`
end
```

### Features in Detail

#### Ensures Necessary Directories
The plugin checks and creates necessary directories for buffer state and content storage.

#### Saves and Loads Buffer State
The state information of shared buffers (e.g., the buffer number) is saved in a JSON file associated with the provided buffer type. Use `setup` or `setupWBuff` to manage and persist this state seamlessly.

#### Saves and Loads Buffer Content
The plugin saves the content of shared buffers as text files and can load the content back into the buffer. The file paths for saving are automatically determined using `vim.fn.stdpath("data")`.

#### Automatically Watches File Changes
Using Neovim's asynchronous event handling, the plugin watches the related content files for external changes and updates the buffer automatically.

## Example

Here's an example workflow to initialize and use the shared buffer:

```lua
-- Import the plugin
local shared_buffer = require("shared_buffer")

-- Initialize shared buffer
local buffer_type = "example_type"
local bufnr = shared_buffer.setupWBuff(buffer_type)

if bufnr then
    -- Set buffer as current
    vim.api.nvim_set_current_buf(bufnr)

    -- Perform actions in the buffer
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {"Hello, world!"})
end
```

## Error Handling

The plugin is designed to handle various errors and notify users through `vim.notify`. Some of the common error messages include:

- Invalid file path.
- Failure to create a directory or buffer.
- Issues with reading or writing files.

## Contributing

Contributions to this project are welcome. If you find any issue or have a feature request, feel free to open an issue or a pull request.

## License

This project is licensed under the [MIT License](LICENSE). Feel free to use, modify, and distribute it as you see fit.
