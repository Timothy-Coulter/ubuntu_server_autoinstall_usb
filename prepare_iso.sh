#!/bin/bash

# Setup variables
WORK_DIR="/home/cirrus0/cloud_deployment/ubuntu_server_autoinstall_usb"
ISO_DIR="/home/cirrus0/Downloads/os_images"
ISO_NAME="ubuntu-24.04.2-live-server-amd64.iso"
ISO_PATH="$ISO_DIR/$ISO_NAME"
SOURCE_DIR="$WORK_DIR/source-files"
BOOT_DIR="$WORK_DIR/BOOT"

# Create necessary directories
mkdir -p "$SOURCE_DIR"
mkdir -p "$BOOT_DIR"

echo "Unpacking ISO..."
7z -y x "$ISO_PATH" -o"$SOURCE_DIR"

if [ $? -ne 0 ]; then
    echo "Failed to unpack ISO."
    exit 1
fi

echo "Moving boot images..."
# Handle boot images if they exist
if [ -d "$SOURCE_DIR/[BOOT]" ]; then
    echo "Found [BOOT] directory, copying contents..."
    # Create BOOT directory if it doesn't exist
    mkdir -p "$BOOT_DIR"
    # Copy files instead of moving the directory
    cp -r "$SOURCE_DIR/[BOOT]"/* "$BOOT_DIR/" 2>/dev/null || true
fi

# Create server directory for autoinstall files
echo "Creating server directory for autoinstall files..."
mkdir -p "$SOURCE_DIR/server"

# Note: meta-data file will be copied from the work directory by build_custom_iso.sh

# Modify grub configuration
echo "Modifying grub configuration..."
GRUB_CFG="$SOURCE_DIR/boot/grub/grub.cfg"

if [ -f "$GRUB_CFG" ]; then
    # Backup the original file
    cp "$GRUB_CFG" "${GRUB_CFG}.bak"
    
    # Add autoinstall menu entry
    sed -i '0,/menuentry/s/menuentry/menuentry "Autoinstall Ubuntu Server" {\n    set gfxpayload=keep\n    linux   \/casper\/vmlinuz quiet autoinstall ds=nocloud\\;s=\/cdrom\/server\/  ---\n    initrd  \/casper\/initrd\n}\n\nmenuentry/' "$GRUB_CFG"
    
    echo "Grub configuration modified successfully."
else
    echo "Error: grub.cfg not found at $GRUB_CFG"
    exit 1
fi

echo "ISO preparation completed successfully."