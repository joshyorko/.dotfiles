#!/bin/bash

echo -e "🏁 Starting NvChad setup..."

# Function to check if a command exists
command_exists() {
    type "$1" &> /dev/null
}

# Function to install Git if it's not already installed
ensure_git_installed() {
    if ! command_exists git; then
        echo -e "🔧 Installing Git..."
        sudo apt-get update && sudo apt-get install git -y
    else
        echo -e "✅ Git is already installed."
    fi
}

# Function to clone the GitHub Copilot plugin repository
clone_copilot_repo() {
    echo -e "🚀 Cloning GitHub Copilot Plugin Repository..."
    git clone https://github.com/github/copilot.vim.git ~/.vim/pack/github/start/copilot.vim
}

# Function to configure Copilot in plugins.lua
configure_copilot() {
    echo -e "📝 Configuring Copilot in plugins.lua..."
    cat << EOF >> ~/.config/nvim/lua/custom/plugins.lua
local overrides = require("custom.configs.overrides")
---@type NvPluginSpec[]
local plugins = {
  -- Override plugin definition options
  {
    "neovim/nvim-lspconfig",
    dependencies = {
EOF

    # Add the Copilot Plugin Configuration
    cat << EOF >> ~/.config/nvim/lua/custom/plugins.lua
{
  "github/copilot.vim",
  lazy = false,
  config = function()
    vim.g.copilot_no_tab_map = true
    vim.g.copilot_assume_mapped = true
    vim.g.copilot_tab_fallback = ""
  end
},
EOF

    # Add the rest of the configuration
    cat << EOF >> ~/.config/nvim/lua/custom/plugins.lua
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
EOF
}

# Function to enable transparency in chadrc.lua
enable_transparency() {
    echo -e "💡 Enabling Transparency in chadrc.lua..."
    cat << EOF >> ~/.config/nvim/lua/custom/chadrc.lua
M.ui = {
  theme = "catppuccin",
  theme_toggle = { "catppuccin", "one_light" },
  hl_override = highlights.override,
  hl_add = highlights.add,
  transparency = true  
}
EOF
}

# Main setup function
main_setup() {
    ensure_git_installed
    clone_copilot_repo
    configure_copilot
    enable_transparency
    echo -e "🏁 NvChad setup completed successfully!"
}

# Execute the main setup function
main_setup
