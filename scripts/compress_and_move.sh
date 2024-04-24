#!/bin/bash

# The name of the directory to be compressed
DIRECTORY="/home/kdlocpanda/personal"

# The desired name of the tarball
TARBALL_NAME="personal_1_14_24.tar.gz"

# Compress the directory into a tarball
tar -czvf "$TARBALL_NAME" "$DIRECTORY"

# Check if the compression was successful
if [ $? -eq 0 ]; then
    echo "Directory compressed successfully."
else
    echo "Failed to compress the directory. Check the directory name and try again."
fi
