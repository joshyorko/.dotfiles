#!/bin/bash

# Prompt for directory to compress
read -p "Enter the directory to compress: " directory
if [ ! -d "$directory" ]; then
    echo "Directory does not exist."
    exit 1
fi

# Prompt for tarball name
read -p "Enter the name for the tarball (e.g., backup.tar.gz): " tarball_name

# Attempt to find the My Passport SSD mount path automatically, ensuring we handle spaces correctly
ssd_mount_path=$(df --output=target | grep 'My Passport' | head -n 1 | tr -d '[:space:]')
if [ -z "$ssd_mount_path" ]; then
    echo "$ssd_mount_path"
    echo "My Passport SSD not found. Please mount it and retry."
    exit 1
fi

# Check if pigz is installed, if not, fall back to gzip
if command -v pigz >/dev/null 2>&1; then
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

    # Move the tarball to the My Passport SSD
    mv "${tarball_name}" "${ssd_mount_path}/"

    # Check if the move was successful
    if [ $? -eq 0 ]; then
        echo "Tarball moved to the SSD successfully."
    else
        echo "Failed to move the tarball to the SSD. Check the SSD mount path."
    fi
else
    echo "Failed to compress the directory. Check the directory name and try again."
    echo "Refer to /tmp/tar_errors.log for errors."
fi

