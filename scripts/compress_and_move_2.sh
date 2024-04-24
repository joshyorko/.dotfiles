#!/bin/bash

# Prompt for directory to compress
read -p "Enter the directory to compress: " directory
if [ ! -d "$directory" ]; then
    echo "Directory does not exist."
    exit 1
fi

# Prompt for tarball name
read -p "Enter the name for the tarball (e.g., backup.tar.gz): " tarball_name

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
