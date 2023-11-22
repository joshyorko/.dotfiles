#!/usr/bin/env bash


#!/bin/bash

# Script to install Powerlevel10k, fonts, VS Code Insiders, and Google Chrome
sudo apt install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible

# Update and Upgrade
echo "🔄 Updating and Upgrading your system..."
sudo apt update && sudo apt upgrade -y

# Install Zsh if not installed
if ! command -v zsh &> /dev/null; then
    echo "🔧 Installing Zsh..."
    sudo apt install zsh -y
fi

# Install Powerlevel10k
echo "🚀 Installing Powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc

# Install Fonts for Powerlevel10k
echo "🔠 Installing fonts for Powerlevel10k..."
sudo apt install fonts-powerline -y

# Install VS Code Insiders
echo "💻 Installing VS Code Insiders..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt install apt-transport-https -y
sudo apt update
sudo apt install code-insiders -y

# Install Google Chrome
echo "🌐 Installing Google Chrome..."
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install ./google-chrome-stable_current_amd64.deb -y

# Cleanup
rm google-chrome-stable_current_amd64.deb
rm packages.microsoft.gpg

echo "✅ Installation complete!"
