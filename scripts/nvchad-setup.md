
# Comprehensive Guide to Configuring GitHub Copilot and Transparency in NvChad

This guide outlines the steps to install and configure GitHub Copilot and enable transparency in your NvChad environment.

## Part 1: Installing GitHub Copilot

1. **Clone the GitHub Copilot Plugin Repository**

   Clone the GitHub Copilot plugin into the Vim plugin directory using the following command:

  ```bash
   git clone https://github.com/github/copilot.vim.git ~/.vim/pack/github/start/copilot.vim
   ```

## Part 2: Configuring Copilot in `plugins.lua`

1. **Open the `plugins.lua` File**

   Locate and open the `plugins.lua` file in the NvChad configuration. This file is typically found in `~/.config/nvim/lua/custom/`.

2. **Add the Copilot Plugin Configuration**

   Insert the configuration for GitHub Copilot in the `plugins.lua` file:

   ```lua
   local overrides = require("custom.configs.overrides")

    ---@type NvPluginSpec[]
    local plugins = {

      -- Override plugin definition options

      {
        "neovim/nvim-lspconfig",
        dependencies = {
          -- format & linting
          {
            "jose-elias-alvarez/null-ls.nvim",
            config = function()
              require "custom.configs.null-ls"
            end,
          },
        },
        config = function()
          require "plugins.configs.lspconfig"
          require "custom.configs.lspconfig"
        end, -- Override to setup mason-lspconfig
      },
      {
        "github/copilot.vim",
        lazy = false,
        config = function()
          vim.g.copilot_no_tab_map = true;
          vim.g.copilot_assume_mapped = true;
          vim.g.copilot_tab_fallback = "";
        end
      },



      -- override plugin configs
      {
        "williamboman/mason.nvim",
        opts = overrides.mason
      },

      {
        "nvim-treesitter/nvim-treesitter",
        opts = overrides.treesitter,
      },

      {
        "nvim-tree/nvim-tree.lua",
        opts = overrides.nvimtree,
      },

      -- Install a plugin
      {
        "max397574/better-escape.nvim",
        event = "InsertEnter",
        config = function()
          require("better_escape").setup()
        end,
      },

      -- To make a plugin not be loaded
      -- {
      --   "NvChad/nvim-colorizer.lua",
      --   enabled = false
      -- },

      -- All NvChad plugins are lazy-loaded by default
      -- For a plugin to be loaded, you will need to set either `ft`, `cmd`, `keys`, `event`, or set `lazy = false`
      -- If you want a plugin to load on startup, add `lazy = false` to a plugin spec, for example
      -- {
      --   "mg979/vim-visual-multi",
      --   lazy = false,
      -- }
    }

    return plugins

   ```

   This configuration sets up GitHub Copilot, ensuring it's not lazy-loaded.

## Additional Configurations

1. **Configure Key Mappings for Copilot (Optional)**

   If you have additional key mappings for Copilot in your `mappings.lua` file, ensure they are configured properly:

   ```lua
   local M = {}

   M.copilot = {
     i = {  -- in insert mode
       ["<C-l>"] = {  -- using Ctrl-l
         function()
           vim.fn.feedkeys(vim.fn['copilot#Accept'](), '')
         end,
         "Copilot Accept",
         {replace_keycodes = true, nowait=true, silent=true, expr=true, noremap=true}
       }
     }
   }

   -- Include other mappings
   return M
   ```

2. **Restart Neovim**

   After modifying the `mappings.lua` file, restart Neovim for the changes to take effect.

By following these steps, you will have successfully installed GitHub Copilot and configured transparency within your NvChad setup.



## Part 3: Enabling Transparency in `chadrc.lua`

1. **Open the `chadrc.lua` File**

   Open the `chadrc.lua` file in the NvChad configuration, usually located at `~/.config/nvim/lua/custom/`.

2. **Configure Transparency**

   Add or modify the transparency setting in the `chadrc.lua` file:

   ```lua
   --@type ChadrcConfig
   local M = {}

   -- Path to overriding theme and highlights files
   local highlights = require "custom.highlights"

   M.ui = {
     theme = "catppuccin",
     theme_toggle = { "catppuccin", "one_light" },
     hl_override = highlights.override,
     hl_add = highlights.add,
     transparency = true  -- Enable transparency
   }

   M.plugins = "custom.plugins"

   -- check core.mappings for table structure
   M.mappings = require "custom.mappings"

   return M
   ```

   This configuration enables transparency in the NvChad UI.

3. **Save and Reload Configuration**

   After editing the `chadrc.lua` file, save it and reload your Neovim configuration to apply the changes.

By following these steps, you'll successfully integrate GitHub Copilot into your NvChad setup and enable transparency in the Neovim UI.



