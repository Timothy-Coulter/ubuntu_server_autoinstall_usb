#!/bin/bash
#
# Format USB drive for Ubuntu Server autoinstall

# Get the USB device path from the first argument
USB_DEVICE="$1"

# Check if USB device is provided
if [[ -z "$USB_DEVICE" ]]; then
    error_exit "No USB device specified."
fi

# Check if it's a block device
check_block_device "$USB_DEVICE"

# Get device name without path
USB_DEVICE_NAME=$(get_device_name "$USB_DEVICE")

# Check if the device is mounted and unmount it
mounted_partitions=$(mount | grep "$USB_DEVICE" | awk '{print $1}')
if [[ -n "$mounted_partitions" ]]; then
    info "Unmounting partitions on $USB_DEVICE..."
    for part in $mounted_partitions; do
        info "Unmounting $part..."
        umount "$part" || warning "Failed to unmount $part"
    done
fi

# Confirm one last time
info "About to format $USB_DEVICE. ALL DATA WILL BE LOST!"
read -p "Are you absolutely sure you want to continue? [y/N]: " final_confirm
if [[ "$final_confirm" != "y" && "$final_confirm" != "Y" ]]; then
    error_exit "Operation cancelled by user."
fi

# Create a new partition table (GPT)
info "Creating new GPT partition table on $USB_DEVICE..."
parted --script "$USB_DEVICE" mklabel gpt

# Create partitions:
# 1. EFI System Partition (ESP) - 512MB
# 2. Ubuntu installation partition - rest of the drive

info "Creating partitions on $USB_DEVICE..."
parted --script "$USB_DEVICE" \
    mkpart ESP fat32 1MiB 513MiB \
    set 1 boot on \
    set 1 esp on \
    mkpart primary ext4 513MiB 100%

# Wait for the OS to recognize the new partitions
info "Waiting for partitions to be recognized..."
sleep 2

# Get partition device paths
ESP_PARTITION=$(get_partition_device "$USB_DEVICE" 1)
UBUNTU_PARTITION=$(get_partition_device "$USB_DEVICE" 2)

# Wait for partition devices to be available
wait_for_device "$ESP_PARTITION" 10
wait_for_device "$UBUNTU_PARTITION" 10

# Format the partitions
info "Formatting ESP partition ($ESP_PARTITION) as FAT32..."
mkfs.vfat -F 32 -n "UBUNTU_ESP" "$ESP_PARTITION"

info "Formatting Ubuntu partition ($UBUNTU_PARTITION) as ext4..."
mkfs.ext4 -L "UBUNTU_INST" "$UBUNTU_PARTITION"

info "USB device $USB_DEVICE has been formatted successfully."
info "Created partitions:"
info "  - ESP (boot): $ESP_PARTITION (FAT32)"
info "  - Ubuntu: $UBUNTU_PARTITION (ext4)"

# Export partition paths for other scripts
export ESP_PARTITION
export UBUNTU_PARTITION