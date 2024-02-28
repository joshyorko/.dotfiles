#!/bin/bash

# List of repositories to clone
repositories=(
    "Mini-IronRipper"
    "langchain_projects"
    "ansible"
    ".dotfiles"
    "youtube_summarizer"
    "company_datalake"
    "yorko-resume"
    "socialscrape_web_app"
    "docusense"
    "docusense_2.0"
    "openai_plugins"
    "work"
    "forgpt"
    "fire_Test"
    "whisper_app"
    "congenial-pancake"
    "template_streamlit"
    "networkLogsscrape"
    "Josh-s-Stuff"
)

# Base URL for GitHub repositories, added a trailing slash
base_url="git@github.com:joshyorko/"

# Directory where repositories will be cloned, ensure there's no trailing slash
# as we'll add it in the loop.
clone_dir="/home/kdlocpanda/personal/my_repos"

# Loop through each repository and clone it
for repo in "${repositories[@]}"; do
    # Added a slash between the base_url and repository name, and between clone_dir and repo name
    git clone "${base_url}${repo}.git" "${clone_dir}/${repo}"
done
