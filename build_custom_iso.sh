#!/bin/bash

# Setup variables
WORK_DIR="/home/cirrus0/cloud_deployment/ubuntu_server_autoinstall_usb"
SOURCE_DIR="$WORK_DIR/source-files"
OUTPUT_ISO="$WORK_DIR/ubuntu-22.04-autoinstall.iso"
BOOT_DIR="$WORK_DIR/BOOT"

# Copy the user-data file to the source directory
echo "Copying user-data to source directory..."
cp "$WORK_DIR/user-data" "$SOURCE_DIR/server/"

# Check if source files directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source files directory not found at $SOURCE_DIR"
    exit 1
fi

# Check if boot images exist
if [ ! -f "$BOOT_DIR/1-Boot-NoEmul.img" ] || [ ! -f "$BOOT_DIR/2-Boot-NoEmul.img" ]; then
    echo "Warning: Boot images not found in $BOOT_DIR"
    echo "The ISO may not be bootable in UEFI mode."
    echo "Make sure prepare_iso.sh was run successfully."
fi

echo "Building custom ISO..."
cd "$SOURCE_DIR"

# Use the comprehensive xorriso command from the instructions to ensure UEFI boot support
xorriso -as mkisofs -r \
  -V 'Ubuntu 22.04 LTS AUTO (EFIBIOS)' \
  -o "$OUTPUT_ISO" \
  --grub2-mbr "$BOOT_DIR/1-Boot-NoEmul.img" \
  -partition_offset 16 \
  --mbr-force-bootable \
  -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b "$BOOT_DIR/2-Boot-NoEmul.img" \
  -appended_part_as_gpt \
  -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
  -c '/boot.catalog' \
  -b '/boot/grub/i386-pc/eltorito.img' \
    -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
  -eltorito-alt-boot \
  -e '--interval:appended_partition_2:::' \
  -no-emul-boot \
  .

if [ $? -eq 0 ]; then
    echo "Custom ISO created successfully at: $OUTPUT_ISO"
else
    echo "Failed to create custom ISO."
    exit 1
fi