#!/bin/bash

# Prompt user for environment (or directory name)
read -p "Please enter the environment or directory name (e.g., prod-s3): " env_name

# Base directory for env variables
base_dir="env_variables"
env_dir="$base_dir/$env_name"
env_zip="$base_dir/$env_name.zip"

# Prompt user for action choice
read -p "Please enter the action choice (zip, unzip): " action

# Validate action choice
if ! [[ "$action" =~ ^(zip|unzip)$ ]]; then
    echo "❌ Invalid action choice. Please enter either 'zip' or 'unzip'."
    exit 1
fi

# Prompt for encryption/decryption key
read -sp "Please enter the encryption/decryption key: " encryption_key
echo

# Function to perform actions
perform_action() {
    local dir=$1
    local zip_file=$2

    case $action in
        zip)
            # Ensure the directory exists
            if [ ! -d "$dir" ]; then
                echo "❌ Directory '$dir' does not exist. Please create and populate it with files."
                exit 1
            fi

            # Proceed with encryption and zipping
            echo "Encrypting and zipping the directory '$dir'..."
            python3 scripts/ansible_encrypt.py encrypt "$dir" "$encryption_key"
            zip -r "$zip_file" "$dir"
            echo "✅ Zipped and encrypted: $zip_file"

            # Confirm before deleting the directory
            read -p "Do you want to delete the original directory '$dir' after zipping? [Y/n] " confirm
            if [[ "$confirm" =~ ^[Nn]$ ]]; then
                echo "⚠️ Directory '$dir' was not deleted."
            else
                rm -rf "$dir"
                echo "✅ Directory '$dir' has been deleted after zipping."
            fi
            ;;
        unzip)
            # Ensure the zip file exists
            if [ -f "$zip_file" ]; then
                echo "Unzipping and decrypting the directory '$zip_file'..."
                unzip "$zip_file" -d "$base_dir"
                python3 scripts/ansible_encrypt.py decrypt "$dir" "$encryption_key"
                echo "✅ Unzipped and decrypted: $dir"
            else
                echo "❌ Zip file '$zip_file' does not exist."
                exit 1
            fi
            ;;
    esac
}

# Perform the selected action
perform_action "$env_dir" "$env_zip"

echo "✅ Operation completed successfully."
