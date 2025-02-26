#!/bin/bash

# Setup variables
WORK_DIR="/home/cirrus0/cloud_deployment/ubuntu_server_autoinstall_usb"
ISO_PATH="$WORK_DIR/ubuntu-24.04-autoinstall.iso"

# Check if the ISO exists
if [ ! -f "$ISO_PATH" ]; then
    echo "Error: Custom ISO not found at $ISO_PATH"
    echo "Please run the build_custom_iso.sh script first."
    exit 1
fi

# List available drives for user selection
echo "Available disk devices:"
lsblk -d -o NAME,SIZE,MODEL,VENDOR,TYPE | grep -v loop

# Ask user for USB device
echo ""
echo "WARNING: The selected device will be completely erased. All data will be lost."
echo "CAUTION: Make sure you select the correct device to avoid data loss on your system."
echo ""
read -p "Enter the device name for your USB drive (e.g., sdb, sdc): " USB_DEVICE

# Confirm with user
if [[ "$USB_DEVICE" == "sda" ]]; then
    echo "ERROR: You've selected your primary system drive. Operation aborted for safety."
    exit 1
fi

USB_PATH="/dev/$USB_DEVICE"

if [ ! -b "$USB_PATH" ]; then
    echo "Error: Device $USB_PATH does not exist or is not a block device."
    exit 1
fi

echo ""
echo "You have selected device: $USB_PATH"
lsblk "$USB_PATH"
echo ""
echo "WARNING: This will completely erase all data on $USB_PATH"
read -p "Are you absolutely sure you want to continue? (yes/NO): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Unmount any mounted partitions on the USB device
echo "Unmounting any existing partitions on $USB_PATH..."
sudo umount "$USB_PATH"?* 2>/dev/null

# Write the ISO directly to the USB drive
echo "Writing ISO to USB drive. This may take a while..."
sudo dd if="$ISO_PATH" of="$USB_PATH" bs=4M status=progress conv=fdatasync

# Sync to ensure all data is written
sudo sync

echo ""
echo "USB drive preparation completed."
echo "You can now boot from this USB drive to perform an autoinstall of Ubuntu Server 24.04."
echo ""