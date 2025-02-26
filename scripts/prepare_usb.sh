#!/bin/bash
#
# Prepare USB drive with Ubuntu Server image and autoinstall files

# Get arguments
USB_DEVICE="$1"
IMAGE_PATH="$2"
IMAGE_TYPE="$3"

# Check if all required arguments are provided
if [[ -z "$USB_DEVICE" || -z "$IMAGE_PATH" || -z "$IMAGE_TYPE" ]]; then
    error_exit "Missing required arguments. Usage: prepare_usb.sh <usb_device> <image_path> <image_type>"
fi

# Check if image file exists
check_file_readable "$IMAGE_PATH"

# Get partition device paths (should be exported from format_usb.sh)
if [[ -z "$ESP_PARTITION" || -z "$UBUNTU_PARTITION" ]]; then
    ESP_PARTITION=$(get_partition_device "$USB_DEVICE" 1)
    UBUNTU_PARTITION=$(get_partition_device "$USB_DEVICE" 2)
fi

# Create mount points
ESP_MOUNT=$(mktemp -d)
UBUNTU_MOUNT=$(mktemp -d)
ISO_MOUNT=$(mktemp -d)

# Ensure mount points are cleaned up on exit
trap 'umount "$ISO_MOUNT" 2>/dev/null; rmdir "$ISO_MOUNT" 2>/dev/null; umount "$ESP_MOUNT" 2>/dev/null; rmdir "$ESP_MOUNT" 2>/dev/null; umount "$UBUNTU_MOUNT" 2>/dev/null; rmdir "$UBUNTU_MOUNT" 2>/dev/null' EXIT

# Mount the partitions
info "Mounting USB partitions..."
mount "$ESP_PARTITION" "$ESP_MOUNT"
mount "$UBUNTU_PARTITION" "$UBUNTU_MOUNT"

# Function to prepare USB from ISO image
prepare_from_iso() {
    info "Preparing USB from ISO image: $IMAGE_PATH"
    
    # Mount the ISO
    info "Mounting ISO image..."
    mount -o loop "$IMAGE_PATH" "$ISO_MOUNT"
    
    # Copy ISO contents to the Ubuntu partition
    info "Copying ISO contents to USB..."
    rsync -ah --progress "$ISO_MOUNT/" "$UBUNTU_MOUNT/"
    
    # Modify the bootloader for autoinstall
    info "Configuring bootloader for autoinstall..."
    
    # For UEFI boot
    if [[ -d "$UBUNTU_MOUNT/boot/grub" ]]; then
        # Backup original grub.cfg
        cp "$UBUNTU_MOUNT/boot/grub/grub.cfg" "$UBUNTU_MOUNT/boot/grub/grub.cfg.backup"
        
        # Modify grub.cfg to add autoinstall parameter
        sed -i 's/linux\t\(\/casper\/vmlinuz\)/linux\t\1 autoinstall ds=nocloud;s=\/cdrom\/autoinstall\/ quiet ---/' "$UBUNTU_MOUNT/boot/grub/grub.cfg"
    fi
    
    # For Legacy BIOS boot
    if [[ -d "$UBUNTU_MOUNT/isolinux" ]]; then
        # Backup original isolinux.cfg
        cp "$UBUNTU_MOUNT/isolinux/isolinux.cfg" "$UBUNTU_MOUNT/isolinux/isolinux.cfg.backup"
        
        # Modify isolinux.cfg to add autoinstall parameter
        sed -i 's/append\s\(.*\)/append \1 autoinstall ds=nocloud;s=\/cdrom\/autoinstall\/ quiet ---/' "$UBUNTU_MOUNT/isolinux/isolinux.cfg"
    fi
    
    # Create autoinstall directory
    mkdir -p "$UBUNTU_MOUNT/autoinstall"
    
    # Copy template files to autoinstall directory
    info "Copying autoinstall configuration files..."
    cp "$TEMPLATES_DIR/user-data.yml" "$UBUNTU_MOUNT/autoinstall/user-data"
    cp "$TEMPLATES_DIR/meta-data.yml" "$UBUNTU_MOUNT/autoinstall/meta-data"
    
    # Copy network config if it exists
    if [[ -f "$TEMPLATES_DIR/network-config.yml" ]]; then
        cp "$TEMPLATES_DIR/network-config.yml" "$UBUNTU_MOUNT/autoinstall/network-config"
    fi
    
    # Unmount ISO
    info "Unmounting ISO image..."
    umount "$ISO_MOUNT"
}

# Function to prepare USB from IMG image
prepare_from_img() {
    info "Preparing USB from IMG image: $IMAGE_PATH"
    
    # For IMG files, we'll use dd to write directly to the device
    info "Writing IMG to USB device (this may take a while)..."
    dd if="$IMAGE_PATH" of="$USB_DEVICE" bs=4M status=progress conv=fsync
    
    # Re-read the partition table
    info "Re-reading partition table..."
    partprobe "$USB_DEVICE"
    
    # Wait for partitions to be recognized
    sleep 2
    
    # Remount partitions as they might have changed
    info "Remounting partitions..."
    umount "$ESP_MOUNT" 2>/dev/null
    umount "$UBUNTU_MOUNT" 2>/dev/null
    
    # Find the correct partitions on the device
    # This is more complex with IMG files as the partition layout might vary
    # We'll look for the largest partition which is likely the main Ubuntu partition
    
    # Get list of partitions
    partitions=$(lsblk -ln -o NAME,SIZE "$USB_DEVICE" | grep -v "$(basename "$USB_DEVICE")" | sort -k2 -hr | awk '{print $1}')
    
    # The first (largest) partition is likely the main Ubuntu partition
    main_partition=$(echo "$partitions" | head -n1)
    main_partition_path="/dev/$main_partition"
    
    # Mount the main partition
    mount "$main_partition_path" "$UBUNTU_MOUNT"
    
    # Create autoinstall directory
    mkdir -p "$UBUNTU_MOUNT/autoinstall"
    
    # Copy template files to autoinstall directory
    info "Copying autoinstall configuration files..."
    cp "$TEMPLATES_DIR/user-data.yml" "$UBUNTU_MOUNT/autoinstall/user-data"
    cp "$TEMPLATES_DIR/meta-data.yml" "$UBUNTU_MOUNT/autoinstall/meta-data"
    
    # Copy network config if it exists
    if [[ -f "$TEMPLATES_DIR/network-config.yml" ]]; then
        cp "$TEMPLATES_DIR/network-config.yml" "$UBUNTU_MOUNT/autoinstall/network-config"
    fi
    
    # Modify bootloader configuration for autoinstall
    # This is more complex with IMG files as the bootloader location might vary
    # We'll try to find and modify common bootloader configurations
    
    # For GRUB
    if [[ -d "$UBUNTU_MOUNT/boot/grub" ]]; then
        info "Configuring GRUB for autoinstall..."
        for cfg in "$UBUNTU_MOUNT/boot/grub/grub.cfg" "$UBUNTU_MOUNT/boot/grub/grub.conf"; do
            if [[ -f "$cfg" ]]; then
                # Backup original file
                cp "$cfg" "${cfg}.backup"
                
                # Modify to add autoinstall parameter
                sed -i 's/linux\s\+\([^ ]*\)/linux \1 autoinstall ds=nocloud;s=\/autoinstall\/ quiet ---/' "$cfg"
            fi
        done
    fi
}

# Process based on image type
if [[ "$IMAGE_TYPE" == "iso" ]]; then
    prepare_from_iso
elif [[ "$IMAGE_TYPE" == "img" ]]; then
    prepare_from_img
else
    error_exit "Unsupported image type: $IMAGE_TYPE. Must be 'iso' or 'img'."
fi

# Sync and unmount
info "Syncing file systems..."
sync

info "Unmounting USB partitions..."
umount "$ESP_MOUNT"
umount "$UBUNTU_MOUNT"

info "USB preparation complete."
info "The USB drive is now ready for Ubuntu Server autoinstall."