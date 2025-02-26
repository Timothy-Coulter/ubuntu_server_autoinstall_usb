#!/bin/bash

ISO_DIR="/home/cirrus0/Downloads/os_images"
# Create the ISO directory if it doesn't exist
mkdir -p "$ISO_DIR"
ISO_NAME="ubuntu-22.04.5-live-server-amd64.iso"
ISO_PATH="$ISO_DIR/$ISO_NAME"
ISO_URL="https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso"

# Check if ISO exists
if [ -f "$ISO_PATH" ]; then
    echo "Ubuntu 22.04 Server ISO already exists at $ISO_PATH"
else
    echo "Ubuntu 22.04 Server ISO not found. Downloading..."
    wget -P "$ISO_DIR" "$ISO_URL"
    
    if [ $? -eq 0 ]; then
        echo "Download completed successfully."
    else
        echo "Download failed. Please check your internet connection and try again."
        exit 1
    fi
fi

echo "ISO location: $ISO_PATH"