#!/bin/bash
#
# Main entrypoint script for creating an Ubuntu Server 24.04 autoinstall USB
# This script orchestrates the entire process by calling specialized scripts

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"
TESTS_DIR="${SCRIPT_DIR}/tests"

# Source utility functions
source "${SCRIPTS_DIR}/utils.sh"

# Print banner
print_banner "Ubuntu Server 24.04 Autoinstall USB Creator"

# Check dependencies
echo "Checking dependencies..."
source "${SCRIPTS_DIR}/check_dependencies.sh"

# Ask for image type and path
echo
echo "Ubuntu Server 24.04 Image Selection"
echo "=================================="
echo "1. Download Ubuntu Server 24.04 ISO"
echo "2. Use existing ISO file"
echo "3. Use existing IMG file"
echo
read -p "Select an option [1-3]: " image_option

case $image_option in
    1)
        source "${SCRIPTS_DIR}/download_image.sh"
        image_path="${DOWNLOAD_PATH}"
        image_type="iso"
        ;;
    2)
        read -p "Enter path to existing ISO file: " image_path
        if [[ ! -f "$image_path" ]]; then
            echo "Error: File not found: $image_path"
            exit 1
        fi
        image_type="iso"
        ;;
    3)
        read -p "Enter path to existing IMG file: " image_path
        if [[ ! -f "$image_path" ]]; then
            echo "Error: File not found: $image_path"
            exit 1
        fi
        image_type="img"
        ;;
    *)
        echo "Invalid option. Exiting."
        exit 1
        ;;
esac

# Get USB device path
echo
echo "USB Device Selection"
echo "==================="
echo "Available devices:"
lsblk -d -o NAME,SIZE,MODEL,VENDOR | grep -v loop

echo
echo "WARNING: ALL DATA ON THE SELECTED DEVICE WILL BE ERASED!"
echo "Make sure you select the correct device."
echo
read -p "Enter USB device path (e.g., /dev/sda): " usb_device

# Confirm selection
echo
echo "You selected: $usb_device"
read -p "Are you sure you want to continue? This will erase all data on $usb_device [y/N]: " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Format USB
echo "Formatting USB device..."
source "${SCRIPTS_DIR}/format_usb.sh" "$usb_device"

# Create template files if they don't exist
echo "Creating template files..."
source "${SCRIPTS_DIR}/create_templates.sh"

# Prepare USB with Ubuntu image and autoinstall files
echo "Preparing USB with Ubuntu image and autoinstall files..."
source "${SCRIPTS_DIR}/prepare_usb.sh" "$usb_device" "$image_path" "$image_type"

echo
echo "USB preparation complete!"
echo "Your USB drive is now ready to perform an automated Ubuntu Server 24.04 installation."
echo

# Ask if user wants to test with KVM
echo "Would you like to test the installation with KVM?"
echo "1. Yes, test with KVM"
echo "2. No, exit"
echo
read -p "Select an option [1-2]: " test_option

if [[ "$test_option" == "1" ]]; then
    echo "Starting KVM test..."
    source "${TESTS_DIR}/test_kvm.sh" "$usb_device"
fi

echo "Done!"
exit 0