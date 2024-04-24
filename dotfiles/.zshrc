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
    ssh-add ~/.ssh/id_ed25519
    git config --global user.email "joshua.yorko@gmail.com"
    echo "Switched to Personal SSH and Git Config."
  }
alias nvim="lvim"

conda_destroy() {
  envs_to_delete=$(conda env list | grep -v "^#" | grep -v "base" | awk '{print $1}')
  if [ -z "$envs_to_delete" ]; then
    echo "🔍 Only the 'base' Conda environment found. No environments to destroy! 🏡"
  else
    echo "$envs_to_delete" | while read -r env; do
      if [ ! -z "$env" ]; then
        conda env remove -n "$env" -y
        echo "🚀 Environment '$env' destroyed! 💥"
      fi
    done
    echo "🌌 All non-base Conda environments have been annihilated! 🌠"
  fi
}

generate_class_prompt() {
  echo "Enter the objective of the class:"
  read objective

  echo "How many functions does your class need (excluding __init__)?"
  read num_funcs

  prompt="Create a Python class that enables ${objective}. I need the following FUNCTION support:\n\nFUNCTION\n\n__init__()"

  for ((i = 1; i <= num_funcs; i++))
  do
    echo "Enter name for function $i:"
    read func_name

    echo "Does function $i have parameters? [y/n]"
    read has_params

    func_def="$func_name"

    if [[ $has_params == "y" ]]; then
      echo "Enter parameter(s) for $func_name, comma-separated if multiple:"
      read params
      func_def="${func_def}(${params})"
    else
      func_def="${func_def}()"
    fi

    echo "Do you want to add a description for $func_name? [y/n]"
    read has_desc

    if [[ $has_desc == "y" ]]; then
      echo "Enter description for $func_name:"
      read desc
      func_def="${func_def} - $desc"
    fi

    prompt="${prompt}\n${func_def}"
  done

  echo -e "\n${prompt}"
}


  work() {
    ssh-add -D
    ssh-add ~/.ssh/id_ed25519_work
  
    git config --global user.name "Josh Yorko"
    git config --global user.email "joshua.yorko@gainwelltechnologies.com"
    echo "Switched to Work SSH and Git Config."
  }
# APPLICATIONS
#
#
compress() {
    # Prompt for directory to compress
    echo -n "Enter the directory to compress: "
    read directory
    if [ ! -d "$directory" ]; then
        echo "Directory does not exist."
        return 1
    fi

    # Prompt for tarball name
    echo -n "Enter the name for the tarball (e.g., backup.tar.gz): "
    read tarball_name
    # Check if pigz is installed, if not, fall back to gzip
    if command -v pigz >/dev/null 2>&1; then
        echo "pigz found, using pigz for compression."
        compressor="pigz"
    else
        compressor="gzip"
        echo "pigz not found, using gzip instead."
    fi

    # Compress the directory using tar with the chosen compressor
    tar -I $compressor -cvf "${tarball_name}" "$directory" 2> /tmp/tar_errors.log | pv -lep -s $(find "$directory" -type f | wc -l) > /dev/null

    # Check if the compression was successful
    if [ $? -eq 0 ]; then
        echo "Directory compressed successfully."
    else
        echo "Failed to compress the directory. Check the directory name and try again."
        echo "Refer to /tmp/tar_errors.log for errors."
    fi
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




export PATH="$PATH:/home/kdlocpanda/chrome-linux64"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/kdlocpanda/google-cloud-sdk/path.zsh.inc' ]; then . '/home/kdlocpanda/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/kdlocpanda/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/kdlocpanda/google-cloud-sdk/completion.zsh.inc'; fi

export PATH=/usr/local/cuda-12.3/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-12.3/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
export PATH=/home/kdlocpanda/.local/bin:$PATH
export PATH=/home/kdlocpanda/.cargo/bin:$PATH


# Load custom aliases
if [ -f "/home/kdlocpanda/.config/fabric/fabric-bootstrap.inc" ]; then . "/home/kdlocpanda/.config/fabric/fabric-bootstrap.inc"; fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/kdlocpanda/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/kdlocpanda/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/kdlocpanda/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/kdlocpanda/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


