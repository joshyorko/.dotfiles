# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(ansible git python zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

alias ls="colorls"
alias ll="colorls -al"
alias lt="colorls --tree=3"
  personal() {
    ssh-add -D
    ssh-add ~/.ssh/id_ed25519_personal
    git config --global user.email "joshua.yorko@gmail.com"
    echo "Switched to Personal SSH and Git Config."
  }



  work() {
    ssh-add -D
    ssh-add ~/.ssh/id_ed25519_work
  
    git config --global user.name "Josh Yorko"
    git config --global user.email "joshua.yorko@gainwelltechnologies.com"
    echo "Switched to Work SSH and Git Config."
  }

 edir() {
    local search_term=$1
    local editor_option=$2

    # Check if a search term is provided
    if [ -z "$search_term" ]; then
        echo "❌ Provide a search term."
        return 1
    fi

    # Check for required tools: fzf and fd
    if ! command -v fzf >/dev/null 2>&1; then
        echo "❌ Install 'fzf'."
        return 1
    fi

    if ! command -v fd >/dev/null 2>&1; then
        echo "❌ Install 'fd'."
        return 1
    fi

    # Find directories matching the search term and select one using fzf
    local selected_dir=$(fd --type d --ignore-file ~/.ignore "$search_term" ~ ~/projects 2>/dev/null | fzf --prompt="Select a directory: ")

    # Check if a directory was selected
    if [ -n "$selected_dir" ]; then
        case $editor_option in
            -c) 
                if command -v code >/dev/null 2>&1; then
                    code "$selected_dir"
                else
                    echo "❌ 'code' is not installed."
                    return 1
                fi
                ;;
            -o) cd "$selected_dir" ;;  # Only change to the selected directory
            *) nvim "$selected_dir" ;;  # Default to nvim if no option or unrecognized option is given
        esac
    else
        echo "🚫 No directory selected."
    fi
}
  export PATH=/home/kdlocpanda/.local/bin:$PATH
  export PATH=/home/kdlocpanda/.cargo/bin:$PATH


MODEL_DIR="/home/kdlocpanda/personal/models/ggufs"
llm() {
    local ggufs_dir="/home/kdlocpanda/personal/models/ggufs" # Ensure this is the correct path to your ggufs directory
    local model_file=""

    # If no arguments, use fzf to select a model file
    if [[ $# -eq 0 ]]; then
        echo "Select a model:"
        model_file=$(find "$ggufs_dir" -name '*.gguf' | fzf --height 40% --reverse)

        # Exit if no file is selected
        if [[ -z "$model_file" ]]; then
            echo "No model selected. Exiting."
            return 1
        fi
    else
        # If an argument is provided (for backward compatibility or direct invocation)
        model_file="$ggufs_dir/$1.gguf"
        if [[ ! -f "$model_file" ]]; then
            echo "Model file does not exist: $1"
            return 1
        fi
    fi

    # Extract the model name for display purposes
    local model_name=$(basename "$model_file" .gguf)

    echo "Setting up server for model: $model_name"
    bash "$ggufs_dir/llamafile-0.6.2" -m "$model_file" --server --host "0.0.0.0" -ngl 7
    echo "Server setup completed for model: $model_name"
}


