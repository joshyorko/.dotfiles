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
plugins=(ansible git python zsh-autosuggestions zsh-syntax-highlighting kubectl)

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

#alias ls="colorls"
#alias ll="colorls -al"
#alias lt="colorls --tree=3"


conda_snapshot() {
  local snapshot_dir="${1:-$HOME/conda_snapshots}"
  mkdir -p "$snapshot_dir"
  conda env list | grep -v "^#" | awk '{print $1}' | while read -r env; do
    if [ ! -z "$env" ]; then
      echo "📸 Taking snapshot of '$env' environment..."
      conda list -n "$env" --explicit > "$snapshot_dir/$env.txt"
      echo "🗃️ Snapshot saved to '$snapshot_dir/$env.txt'"
    fi
  done
  echo "🌠 All Conda environment snapshots are saved in '$snapshot_dir'!"
}



conda_build_interactive() {
  # Check if conda is installed
  if ! command -v conda &> /dev/null; then
    echo "🔍 Conda not found. Installing Miniconda..."
    
    # Detect OS
    case "$(uname -s)" in
      Linux*)
        installer_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
        ;;
      Darwin*)
        if [[ $(uname -m) == "arm64" ]]; then
          installer_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
        else
          installer_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
        fi
        ;;
      *)
        echo "❌ Unsupported operating system"
        return 1
        ;;
    esac

    # Download and install Miniconda
    wget "$installer_url" -O miniconda.sh || curl -o miniconda.sh "$installer_url"
    bash miniconda.sh -b -p "$HOME/miniconda"
    rm miniconda.sh

    # Initialize conda for the current shell
    eval "$("$HOME/miniconda/bin/conda" "shell.$(basename "$SHELL")" hook)"

    # Add conda to PATH permanently
    echo 'export PATH="$HOME/miniconda/bin:$PATH"' >> "$HOME/.$(basename "$SHELL")rc"
    
    echo "✅ Conda installed successfully!"
  fi

  # Existing conda_build_interactive function continues here
  echo "🔧 Let's build a new Conda environment."
  echo "Enter the name for your new environment: "
  read env_name

  # Get available Python versions dynamically
  echo "Fetching available Python versions..."
  python_versions=$(conda search "^python$" | grep "python" | awk '{print $2}' | sort -V | uniq)

  # Display Python versions in a compact table format
  echo "Available Python Versions:"
  version_array=(${(f)python_versions}) # Split into an array by newlines
  for i in {1..$#version_array}; do
    echo "$i) ${version_array[i]}"
  done

  echo "Select Python version by index number (e.g., 82 for Python 3.11.0): "
  read py_index
  py_version="python=${version_array[$py_index]}"

  echo "Would you like to install packages using Conda or pip? (Enter 'conda' or 'pip')"
  read package_manager

  # Prompt for package selection
  echo "Enter package names separated by spaces to search (e.g., numpy scipy): "
  read -A package_list

  echo "Creating environment '$env_name' with Python version '$py_version'..."
  conda create --name "$env_name" "$py_version" -y

  echo "Activating environment '$env_name'..."
  eval "$(conda shell.zsh hook)"
  conda activate "$env_name"

  if [[ "$package_manager" == "conda" ]]; then
    for package in $package_list; do
      echo "Attempting to install $package using Conda..."
      if ! conda install "$package" -y; then
        echo "$package not found in Conda repositories. Attempting to install with pip."
        pip cache purge
        pip install --no-cache-dir "$package"
      fi
    done
  elif [[ "$package_manager" == "pip" ]]; then
    echo "Installing packages using pip: ${package_list[*]}"
    echo "Clearing pip cache..."
    pip cache purge
    pip install  --no-cache-dir ${package_list[@]}
  fi

  echo "🚀 Environment '$env_name' created and packages installed successfully."
  echo "✨ Conda environment setup is complete! Use 'conda activate $env_name' to start using it."
}







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




# APPLICATIONS
#
#
compress() {
    # Prompt for directory to compress
    echo -n "Enter the directory to compress: "
    read directory
    if [ ! -d "$directory" ]; then
        echo "❌ Directory does not exist: $directory"
        return 1
    fi

    # Prompt for backup name (optional)
    echo -n "Enter a name for the backup (press Enter to use directory name): "
    read backup_name
    
    # Use directory name if no backup name provided
    if [[ -z "$backup_name" ]]; then
        backup_name=$(basename "$directory")
    fi
    
    # Create timestamp and final filename
    timestamp=$(date '+%Y%m%d_%H%M%S')
    tarball_name="${timestamp}_${backup_name}.tar.gz"
    
    # Determine compression program
    if command -v pigz >/dev/null 2>&1; then
        echo "✅ pigz found, using pigz for compression."
        compressor="pigz"
        compress_cmd=(--use-compress-program=pigz)
    else
        echo "⚠️  pigz not found, falling back to gzip."
        compressor="gzip"
        compress_cmd=(-z)
    fi

    echo "📦 Compressing $directory into $tarball_name..."

    # Compress using tar with the appropriate compression method
    tar -cf "$tarball_name" "${compress_cmd[@]}" "$directory" 2> /tmp/tar_errors.log

    # Check result
    if [ $? -eq 0 ]; then
        echo "✅ Directory compressed successfully into $tarball_name"
        echo "📍 Full path: $(pwd)/$tarball_name"
    else
        echo "❌ Compression failed. Check /tmp/tar_errors.log for details."
    fi
}


edir() {
    local editor_option=$1

    # Check if tools are in PATH first
    local needs_fzf=0
    local needs_fd=0

    # Check for fzf in PATH
    if ! command -v fzf >/dev/null 2>&1; then
        needs_fzf=1
    fi

    # Check for fd/fdfind in PATH
    if ! (command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1); then
        needs_fd=1
    fi

    # Install only if needed
    if [ $needs_fzf -eq 1 ]; then
        echo "❌ 'fzf' is not installed. Installing..."
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y fzf
        elif command -v brew >/dev/null 2>&1; then
            brew install fzf
        elif command -v cargo >/dev/null 2>&1; then
            cargo install fzf
        else
            echo "⚠️ Unable to install 'fzf'. Please install it manually."
            return 1
        fi
    fi

    if [ $needs_fd -eq 1 ]; then
        echo "❌ 'fd' is not installed. Installing..."
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y fd-find
            # Link fdfind to fd only if fd doesn't exist
            if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
                mkdir -p ~/.local/bin
                ln -s $(which fdfind) ~/.local/bin/fd
                export PATH="$HOME/.local/bin:$PATH"
                echo "Linked 'fdfind' to 'fd'."
            fi
        elif command -v brew >/dev/null 2>&1; then
            brew install fd
        elif command -v cargo >/dev/null 2>&1; then
            cargo install fd-find
        else
            echo "⚠️ Unable to install 'fd'. Please install it manually."
            return 1
        fi
    fi

    # Use fd or fdfind (whichever is available)
    local fd_cmd
    if command -v fd >/dev/null 2>&1; then
        fd_cmd="fd"
    else
        fd_cmd="fdfind"
    fi

    # Use fd to search directories
    local selected_dir
    selected_dir=$(
        { $fd_cmd . --type d "$PWD" 2>/dev/null; $fd_cmd . --type d /home 2>/dev/null; $fd_cmd . --type d /workspaces 2>/dev/null; } |
        fzf --prompt="Select a directory: "
    )

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
            -n) nvim "$selected_dir" ;;  # Open in nvim if -n option is provided
            *) cd "$selected_dir" ;;     # Default behavior: change to the selected directory
        esac
    else
        echo "🚫 No directory selected."
    fi
}


cn() {
  # Ensure fzf is installed
  if ! command -v fzf &> /dev/null; then
    echo "fzf is not installed. Please install it and try again."
    return 1
  fi

  # Try to get namespaces using kubectl first, then fallback to rancher kubectl
  ns_list=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || rancher kubectl get ns -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

  if [ -z "$ns_list" ]; then
    echo "No namespaces found using kubectl or rancher kubectl"
    return 1
  fi

  # Use fzf to display namespaces with fuzzy finding
  selected_ns=$(echo "$ns_list" | tr ' ' '\n' | fzf --prompt="Select namespace: " --select-1 --exit-0)

  # If a selection is made, update the default namespace
  if [ -n "$selected_ns" ]; then
    # Try kubectl first, then fallback to rancher kubectl
    kubectl config set-context --current --namespace="$selected_ns" > /dev/null 2>&1 || \
    rancher kubectl config set-context --current --namespace="$selected_ns" > /dev/null 2>&1
    echo "Selected namespace: $selected_ns"
  else
    echo "No namespace selected."
  fi
}





crawl() {
  if [ -f "$HOME/yorko_io/all_the_docks/ai_flow/scrapeCrawl.py" ]; then
    uv run "$HOME/yorko_io/all_the_docks/ai_flow/scrapeCrawl.py" "$@"
  elif [ -f "$HOME/scrapeCrawl.py" ]; then
    uv run "$HOME/scrapeCrawl.py" "$@"
  elif [ -f "$HOME/.dotfiles/scripts/scrapeCrawl.py" ]; then
    uv run "$HOME/.dotfiles/scripts/scrapeCrawl.py" "$@"
  else
    echo "Error: scrapeCrawl.py not found in $HOME/yorko_io/all_the_docks/ai_flow/, $HOME/, or $HOME/.dotfiles/scripts/"
    return 1
  fi
}


mischief_managed() {
  local TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
  local WORKSPACE_DIR=$(pwd)
  local SNAPSHOT_DIR="${HOME}/.mischief_snapshots"
  local MISCHIEF_ARCHIVE="mischief_${TIMESTAMP}.zip"
  local VAULT_ARCHIVE="${MISCHIEF_ARCHIVE}.vault"
  local MARAUDERS_LOG="${SNAPSHOT_DIR}/marauders_log.txt"

  # Ensure snapshot directory exists
  mkdir -p "$SNAPSHOT_DIR"

  echo -e "\033[1;35m🧙‍♂️ Mischief Managed! Archiving and encrypting your workspace...\033[0m"

  # Zip current workspace, excluding .git & unnecessary clutter
  zip -qr "${SNAPSHOT_DIR}/${MISCHIEF_ARCHIVE}" "$WORKSPACE_DIR" -x "*.git*" "*.venv*" "*node_modules*"

  # Encrypt using Ansible Vault
  ansible-vault encrypt "${SNAPSHOT_DIR}/${MISCHIEF_ARCHIVE}" --output="${SNAPSHOT_DIR}/${VAULT_ARCHIVE}"

  # Cleanup unencrypted zip
  rm "${SNAPSHOT_DIR}/${MISCHIEF_ARCHIVE}"

  # Git stash or auto-commit
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    git add -A && git commit -m "✨ Mischief managed snapshot at ${TIMESTAMP}" || git stash push -u -m "✨ Mischief managed stash at ${TIMESTAMP}"
  fi

  # Run Ansible cleanup/reset playbook
  if [ -f "${WORKSPACE_DIR}/cleanup.yml" ]; then
    echo -e "\033[1;34m🪄 Ansible restoring your workspace to pristine condition...\033[0m"
    ansible-playbook "${WORKSPACE_DIR}/cleanup.yml"
  fi

  # Restart Devcontainer services gracefully (assuming Docker Compose or devcontainer CLI)
  if [ -f ".devcontainer/docker-compose.yml" ]; then
    docker-compose -f .devcontainer/docker-compose.yml restart
  elif command -v devcontainer &>/dev/null; then
    devcontainer restart
  fi

  # Log your Marauder’s entry
  echo "🪄 Mischief managed at ${TIMESTAMP} from ${WORKSPACE_DIR}" >> "${MARAUDERS_LOG}"

  # Whimsical Terminal Output 🎩
  echo -e "\033[1;32m✨✨✨ Mischief Managed! Your workspace is pristine and your secrets safe. ✨✨✨\033[0m"
  echo -e "🔮 Use \033[1;33mreveal_mischief\033[0m to view previous adventures!"
}

# Reveal past adventures from Marauder’s Log
reveal_mischief() {
  local MARAUDERS_LOG="${HOME}/.mischief_snapshots/marauders_log.txt"
  if [ -f "$MARAUDERS_LOG" ]; then
    echo -e "\033[1;36m📜 Marauder’s Log - Your Past Mischief:\033[0m"
    cat "$MARAUDERS_LOG"
  else
    echo -e "\033[1;31m⚠️ No mischief logged yet!\033[0m"
  fi
}




# SMART NOTE CREATION FUNCTION for .zshrc
# This script creates either a Zettelkasten note or a Journal entry with structured templates.
cz() {
    echo "📝 Welcome to Smart Note Creation!"

    # Usage function for error messaging
    usage() {
        cat <<EOF
📚 Usage: cz [-e|--editor EDITOR] [-l|--local] [-j|--journal]
Interactive note creation wizard for Zettelkasten notes and Journal entries.

Options:
  -e, --editor     Optional: Specify editor (code|code-insiders|nvim)
  -l, --local      Create note in current directory instead of PARA structure
  -j, --journal    Create a Journal entry (instead of a standard Zettel)
  -h, --help       Show this help message

Examples:
  cz                     # Create a standard Zettel note
  cz -j                 # Create a Journal entry
  cz -e code           # Create note and open in VS Code
  cz -l                # Create note in current directory
  cz -j -e nvim       # Create Journal entry and open in Neovim
EOF
        return 1
    }

    # Function to detect if a directory has PARA structure
    detect_para_structure() {
        local dir="$1"
        # Check if the directory contains the main PARA folders
        local para_folders=("Projects" "Areas" "Resources" "Archives")
        local valid_structure=true
        
        for folder in "${para_folders[@]}"; do
            if [ ! -d "$dir/$folder" ]; then
                valid_structure=false
                break
            fi
        done
        
        echo "$valid_structure"
    }

    # Function to get immediate subdirectories only (one level)
    get_immediate_subdirs() {
        local dir="$1"
        find "$dir" -mindepth 1 -maxdepth 1 -type d -not -path '*/\.*' -exec basename {} \; | sort
    }

    # Function to navigate directories one level at a time
    navigate_directories() {
        local base_dir="$1"
        local current_path=""
        local full_path="$base_dir"
        local tags=()
        
        while true; do
            echo "📂 Current path: ${current_path:-<root>}" >&2
            echo >&2
            echo "Available directories:" >&2
            echo >&2
            
            # Get immediate subdirectories at current level
            local subdirs=("${(@f)$(get_immediate_subdirs "$full_path")}")
            
            if [ ${#subdirs[@]} -eq 0 ]; then
                echo "No subdirectories found at this level." >&2
                echo >&2
                echo "Options:" >&2
                echo "1. Create new directory" >&2
                echo "2. Use current path" >&2
                echo "3. Go back" >&2
                echo >&2
                printf "Enter choice (1-3): " >&2
                read choice
                
                case "$choice" in
                    1)
                        printf "Enter new directory name: " >&2
                        read dirname
                        echo >&2
                        if [ -n "$dirname" ]; then
                            if [ -z "$current_path" ]; then
                                current_path="$dirname"
                            else
                                current_path="${current_path}/${dirname}"
                            fi
                            tags+=("$dirname")
                            # Ensure full_path is updated correctly before mkdir
                            full_path="${base_dir}/${current_path}"
                            mkdir -p "$full_path"
                            break
                        fi
                        ;;
                    2)
                        if [ -z "$current_path" ]; then
                            echo "❌ Cannot use empty path. Please create a directory or go back." >&2
                            continue
                        fi
                        break
                        ;;
                    3)
                        if [ -z "$current_path" ]; then
                            echo "❌ Already at root. Please select or create a directory." >&2
                            continue
                        fi
                        # Go back one level
                        current_path=$(dirname "$current_path")
                        # Handle going back to root where dirname is '.'
                        if [[ "$current_path" == "." ]]; then
                            current_path=""
                        fi
                        full_path="$base_dir/$current_path"
                        tags=(${tags[@]::${#tags[@]}-1})
                        ;;
                    *)
                        echo "Invalid choice" >&2
                        ;;
                esac
                continue
            fi
            
            # Add navigation options
            local options=("${subdirs[@]}" "[[Create New Directory]]" "[[Use Current Path]]" "[[Go Back]]")
            
            local selection=$(printf "%s\n" "${options[@]}" | fzf \
                --prompt="Select directory or action: " \
                --header="📂 Current path: ${current_path:-<root>}" \
                --height=40% \
                --border=rounded \
                --info=inline)
            
            case "$selection" in
                "[[Create New Directory]]")
                    printf "\nEnter new directory name: " >&2
                    read dirname
                    echo >&2
                    if [ -n "$dirname" ]; then
                        if [ -z "$current_path" ]; then
                            current_path="$dirname"
                        else
                            current_path="${current_path}/${dirname}"
                        fi
                        tags+=("$dirname")
                        # Ensure full_path is updated correctly before mkdir
                        full_path="${base_dir}/${current_path}"
                        mkdir -p "$full_path"
                        break
                    fi
                    ;;
                "[[Use Current Path]]")
                    if [ -z "$current_path" ]; then
                        echo "❌ Cannot use empty path. Please select or create a directory." >&2
                        continue
                    fi
                    break
                    ;;
                "[[Go Back]]")
                    if [ -z "$current_path" ]; then
                        echo "❌ Already at root. Please select or create a directory." >&2
                        continue
                    fi
                    # Go back one level
                    current_path=$(dirname "$current_path")
                    # Handle going back to root where dirname is '.'
                    if [[ "$current_path" == "." ]]; then
                        current_path=""
                    fi
                    full_path="$base_dir/$current_path"
                    tags=(${tags[@]::${#tags[@]}-1})
                    ;;
                "") # ESC pressed
                    if [ -z "$current_path" ]; then
                        echo "❌ No directory selected. Exiting." >&2
                        current_path=""
                        break
                    fi
                    break
                    ;;
                *)
                    if [ -z "$current_path" ]; then
                        current_path="$selection"
                    else
                        current_path="${current_path}/${selection}"
                    fi
                    full_path="${base_dir}/${current_path}"
                    tags+=("$selection")
                    ;;
            esac
        done

        # Prepare the final output string securely
        local final_path="$current_path"
        local final_tags_string=$(IFS=','; echo "${tags[*]}")
        local output_string="${final_path}|${final_tags_string}"

        # Only echo the final prepared string to standard output
        echo "$output_string"
    }

    # Check for fzf dependency
    if ! command -v fzf &> /dev/null; then
        echo "❌ fzf is not installed. Installing..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y fzf
        elif command -v brew &> /dev/null; then
            brew install fzf
        elif command -v yum &> /dev/null; then
            sudo yum install -y fzf
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y fzf
        else
            echo "⚠️ Please install fzf manually to continue"
            echo "Visit: https://github.com/junegunn/fzf#installation"
            return 1
        fi
    fi

    # Initialize variables
    local EDITOR=""
    local IS_LOCAL=false
    local NOTE_TYPE="zettel"  # default note type

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--editor)
                if [ -z "$2" ]; then
                    echo "❌ Error: --editor option requires an editor value"
                    return 1
                fi
                if [[ $2 =~ ^(code|code-insiders|nvim)$ ]]; then
                    EDITOR="$2"
                    if ! command -v "$EDITOR" &> /dev/null; then
                        echo "❌ Error: $EDITOR is not installed"
                        return 1
                    fi
                    shift 2
                else
                    echo "❌ Error: Invalid editor. Must be 'code', 'code-insiders', or 'nvim'"
                    return 1
                fi
                ;;
            -l|--local)
                IS_LOCAL=true
                shift
                ;;
            -j|--journal)
                NOTE_TYPE="journal"
                shift
                ;;
            -h|--help)
                usage
                return 0
                ;;
            *)
                echo "❌ Error: Unknown option $1"
                usage
                return 1
                ;;
        esac
    done

    # Define the root directory for notes
    # First check if current directory has PARA structure
    local ROOT_DIR
    if [ "$(detect_para_structure "$PWD")" = "true" ]; then
        ROOT_DIR="$PWD"
        echo "📂 Found PARA structure in current directory"
    elif [ -n "${ZET_ROOT_DIR}" ] && [ "$(detect_para_structure "${ZET_ROOT_DIR}")" = "true" ]; then
        ROOT_DIR="${ZET_ROOT_DIR}"
        echo "📂 Using configured ZET_ROOT_DIR: ${ZET_ROOT_DIR}"
    elif [ "$(detect_para_structure "$HOME/second_brain")" = "true" ]; then
        ROOT_DIR="$HOME/second_brain"
        echo "📂 Using default second_brain location"
    else
        echo "⚠️  No PARA structure found, initializing in $HOME/second_brain"
        ROOT_DIR="$HOME/second_brain"
        # Create PARA structure
        for folder in "Projects" "Areas" "Resources" "Archive"; do
            mkdir -p "$ROOT_DIR/$folder"
        done
    fi

    local TARGET_DIR
    local TOPIC_FOLDER

    if [ "$IS_LOCAL" = true ]; then
        TARGET_DIR="$PWD"
        TOPIC_FOLDER=$(basename "$PWD")
        echo "📍 Creating note in current directory: $TARGET_DIR"
    else
        # For Journal entries, automatically set PARA category to Areas/journal
        if [ "$NOTE_TYPE" = "journal" ]; then
            PARA_CATEGORY="Areas"
            TOPIC_FOLDER="journal"
            TARGET_DIR="${ROOT_DIR}/${PARA_CATEGORY}/${TOPIC_FOLDER}"
        else
            echo "Step 2: Select PARA Category"
            local PARA_CATEGORIES=("Projects" "Areas" "Resources" "Archive")
            local PARA_CATEGORY=$(printf "%s\n" "${PARA_CATEGORIES[@]}" | fzf \
                --prompt="Select PARA category: " \
                --header="🗂️  PARA Categories (use arrow keys or type to filter)" \
                --height=40% \
                --border=rounded \
                --info=inline)
            
            if [ -z "$PARA_CATEGORY" ]; then
                echo "❌ No category selected. Exiting."
                return 1
            fi
            echo "✅ Selected category: $PARA_CATEGORY"

            # Step 3: Navigate through directories one level at a time
            echo -e "\nStep 3: Navigate Topic Folders"
            local BASE_DIR="$ROOT_DIR/$PARA_CATEGORY"
            local RESULT=$(navigate_directories "$BASE_DIR")
            
            # Split result into path and tags
            TOPIC_FOLDER=$(echo "$RESULT" | cut -d'|' -f1)
            local TAGS=$(echo "$RESULT" | cut -d'|' -f2)
            
            if [ -z "$TOPIC_FOLDER" ]; then
                echo "❌ No topic folder specified. Exiting."
                return 1
            fi
            
            echo "✅ Selected/Created topic path: $TOPIC_FOLDER"
            TARGET_DIR="${ROOT_DIR}/${PARA_CATEGORY}/${TOPIC_FOLDER}"
            mkdir -p "$TARGET_DIR"
        fi
    fi

    # For Journal entries, use a default title based on the date
    local TITLE=""
    local SANITIZED_TITLE=""
    if [ "$NOTE_TYPE" = "journal" ]; then
        TITLE="$(date +'%Y-%m-%d') Daily Journal"
        SANITIZED_TITLE="$(date +'%Y-%m-%d')-daily-journal"
        echo "✅ Default journal title set to: \"$TITLE\""
    else
        echo -e "\nStep 4: Enter Note Title"
        echo "📝 Enter your note title (be descriptive):"
        read TITLE

        local TITLE_LENGTH=${#TITLE}
        if [ -z "$TITLE" ]; then
            echo "❌ No title specified. Exiting."
            return 1
        elif [ $TITLE_LENGTH -lt 3 ]; then
            echo "❌ Title too short (minimum 3 characters). Exiting."
            return 1
        fi
        echo "✅ Title accepted ($TITLE_LENGTH characters)"
        SANITIZED_TITLE=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//')
    fi

    # Generate a timestamp with seconds for uniqueness
    local TIMESTAMP=$(date +%Y%m%d%H%M%S)

    # Create filename
    local FILENAME="${TIMESTAMP}-${SANITIZED_TITLE}.md"

    # Create the target directory if it doesn't exist
    mkdir -p "${TARGET_DIR}"

    # Create the note file with the appropriate template
    if [ "$NOTE_TYPE" = "journal" ]; then
        cat > "${TARGET_DIR}/${FILENAME}" << EOL
---
id: ${TIMESTAMP}
type: journal
title: "${TITLE}"
date: "$(date +'%Y-%m-%d')"
created: "$(date +'%Y-%m-%d %H:%M:%S')"
modified: 
tags: [journal, ${TAGS}]
---

## Context & State
- Current focus:
- Energy level:
- Key challenges:

## Daily Insights
[Capture atomic ideas that could become Zettel notes]
- 

## Connections
- Related notes: [[note-id]] - [connection explanation]
- Emerging patterns:
- Questions arising:

## Actions & Progress
- [ ] Priority tasks:
- Progress made:
- Blocks encountered:

## Follow-up Thoughts
- Ideas to explore:
- Future Zettels to create:

EOL
    else
        cat > "${TARGET_DIR}/${FILENAME}" << EOL
---
id: ${TIMESTAMP}
title: "${TITLE}"
tags: [${TAGS}]
created: "$(date +'%Y-%m-%d %H:%M:%S')"
modified: 
---

# ${TITLE}

## Context
[Brief context or trigger for this note]

## Main Idea
[Single, atomic idea - one thought per note]

## Development
[Expand on the main idea, but stay focused and atomic]

## References & Links
- Related notes:
  - [[note-id]] - Connection explanation
  - [[another-note]] - Why it connects
- Sources:
  - [if applicable]

## Future Lines of Thought
[Questions or ideas this note generates]

EOL
    fi

    # Create a symbolic link to the new note in the relevant category index if not local
    if [ "$IS_LOCAL" = false ]; then
        local INDEX_FILE="${ROOT_DIR}/${PARA_CATEGORY}/00_${TOPIC_FOLDER}_index.md"
        if [ ! -f "$INDEX_FILE" ]; then
            cat > "$INDEX_FILE" << EOL
# ${TOPIC_FOLDER} Index

## Recent Notes
EOL
        fi
        echo "- [[${FILENAME%.*}]] - ${TITLE}" >> "$INDEX_FILE"
        echo "📔 Added note reference to index: ${INDEX_FILE}"
    fi

    echo "✨ Created new ${NOTE_TYPE}: ${FILENAME}"
    if [ "$IS_LOCAL" = true ]; then
        echo "📂 Location: Current directory"
    else
        echo "📂 Location: ${PARA_CATEGORY}/${TOPIC_FOLDER}"
    fi

    # Open the file in the specified editor if one was provided
    if [ -n "$EDITOR" ]; then
        echo "🚀 Opening note in $EDITOR..."
        if ! $EDITOR "${TARGET_DIR}/${FILENAME}" 2>/dev/null; then
            echo "❌ Error: Failed to open $EDITOR. The note was created but couldn't be opened."
            echo "📂 You can find it at: ${TARGET_DIR}/${FILENAME}"
            return 1
        fi
    else
        echo "📝 Note ready for editing! Use 'cz -e <editor>' next time to open automatically."
    fi

    # Final feedback with linking suggestions
    echo "✅ Note creation complete! Happy writing! 🎉"
    if [ "$NOTE_TYPE" = "zettel" ]; then
        echo "💡 Tips:"
        echo "  - Link this note to related concepts using [[note-title]]"
        echo "  - Add relevant tags in the frontmatter"
        echo "  - Keep atomic: one main idea per note"
    else
        echo "💡 Tips:"
        echo "  - Link to relevant Zettel notes from your journal"
        echo "  - Track your energy levels and patterns"
        echo "  - Review previous daily entries for continuity"
    fi
}

export COMPOSE_BAKE=true
