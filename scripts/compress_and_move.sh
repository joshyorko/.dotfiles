
#!/bin/bash

# The name of the directory to be compressed
DIRECTORY="projects"

# The desired name of the tarball
TARBALL_NAME="projects_backup.tar.gz"

# The path to the My Passport SSD mount location (assuming the default mount point)
# Josh will need to replace '/media/yourusername' with his actual path, which typically includes the username
SSD_MOUNT_PATH="/media/kdlocpanda/My Passport"


# Compress the directory into a tarball
tar -czvf "$TARBALL_NAME" "$DIRECTORY"

# Check if the compression was successful
if [ $? -eq 0 ]; then
    echo "Directory compressed successfully."
    
    # Move the tarball to the My Passport SSD
    mv "$TARBALL_NAME" "$SSD_MOUNT_PATH"
    
    # Check if the move was successful
    if [ $? -eq 0 ]; then
        echo "Tarball moved to the SSD successfully."
    else
        echo "Failed to move the tarball to the SSD. Check the SSD mount path."
    fi
else
    echo "Failed to compress the directory. Check the directory name and try again."
fi
