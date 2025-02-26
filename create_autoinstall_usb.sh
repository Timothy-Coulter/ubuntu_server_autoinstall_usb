#!/bin/bash

# Main script to create Ubuntu Server 24.04 autoinstall USB
# This script orchestrates the entire process

WORK_DIR="/home/cirrus0/cloud_deployment/ubuntu_server_autoinstall_usb"
cd "$WORK_DIR"

echo "===================================================="
echo "Ubuntu Server 24.04 Autoinstall USB Creation Utility"
echo "===================================================="
echo ""

# Make all scripts executable
chmod +x "$WORK_DIR"/*.sh

# Step 1: Check prerequisites
echo "[Step 1/5] Checking prerequisites..."
./check_prerequisites.sh
if [ $? -ne 0 ]; then
    echo "Failed to install prerequisites. Exiting."
    exit 1
fi
echo "Prerequisites check completed."
echo ""

# Step 2: Check and download ISO if needed
echo "[Step 2/5] Checking for Ubuntu 24.04 Server ISO..."
./check_download_iso.sh
if [ $? -ne 0 ]; then
    echo "Failed to check/download ISO. Exiting."
    exit 1
fi
echo "ISO check completed."
echo ""

# Step 3: Prepare ISO (unpack and modify)
echo "[Step 3/5] Preparing ISO files..."
./prepare_iso.sh
if [ $? -ne 0 ]; then
    echo "Failed to prepare ISO. Exiting."
    exit 1
fi
echo "ISO preparation completed."
echo ""

# Step 4: Build custom ISO
echo "[Step 4/5] Building custom autoinstall ISO..."
./build_custom_iso.sh
if [ $? -ne 0 ]; then
    echo "Failed to build custom ISO. Exiting."
    exit 1
fi
echo "Custom ISO build completed."
echo ""

# Step 5: Prepare USB drive
echo "[Step 5/5] Preparing USB drive..."
echo "This step will format and partition your USB drive."
read -p "Do you want to continue to USB preparation? (yes/NO): " CONTINUE

if [[ "$CONTINUE" != "yes" ]]; then
    echo "USB preparation skipped."
    echo "You can run ./prepare_usb.sh later to prepare your USB drive."
    echo ""
    echo "Custom autoinstall ISO is available at: $WORK_DIR/ubuntu-24.04-autoinstall.iso"
    exit 0
fi

./prepare_usb.sh
if [ $? -ne 0 ]; then
    echo "Failed to prepare USB drive. Exiting."
    exit 1
fi

echo ""
echo "===================================================="
echo "Ubuntu Server 24.04 Autoinstall USB creation process completed."
echo "You can now boot from this USB drive to perform an autoinstall"
echo "of Ubuntu Server 24.04 with the configured settings."
echo "===================================================="