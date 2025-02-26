#!/bin/bash
#
# Check if all required dependencies are installed

# Required commands
REQUIRED_COMMANDS=(
    "wget"
    "lsblk"
    "parted"
    "mkfs.vfat"
    "mkfs.ext4"
    "mount"
    "umount"
    "rsync"
    "dd"
    "sha256sum"
    "file"
    "qemu-system-x86_64"  # For KVM testing
    "xorriso"             # For ISO manipulation
)

# Check if running as root
check_root

# Check for each required command
missing_commands=()
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command_exists "$cmd"; then
        missing_commands+=("$cmd")
    fi
done

# If there are missing commands, suggest how to install them
if [[ ${#missing_commands[@]} -gt 0 ]]; then
    echo "The following required commands are missing:"
    for cmd in "${missing_commands[@]}"; do
        echo "  - $cmd"
    done
    
    echo
    echo "You can install them with:"
    echo "sudo apt update"
    echo "sudo apt install -y wget parted dosfstools e2fsprogs rsync coreutils file qemu-system-x86 xorriso"
    
    read -p "Would you like to install them now? [y/N]: " install_deps
    if [[ "$install_deps" == "y" || "$install_deps" == "Y" ]]; then
        echo "Installing dependencies..."
        apt update
        apt install -y wget parted dosfstools e2fsprogs rsync coreutils file qemu-system-x86 xorriso
        
        # Check again after installation
        still_missing=()
        for cmd in "${missing_commands[@]}"; do
            if ! command_exists "$cmd"; then
                still_missing+=("$cmd")
            fi
        done
        
        if [[ ${#still_missing[@]} -gt 0 ]]; then
            echo "The following commands are still missing:"
            for cmd in "${still_missing[@]}"; do
                echo "  - $cmd"
            done
            error_exit "Please install the missing dependencies manually and try again."
        fi
    else
        error_exit "Please install the missing dependencies and try again."
    fi
fi

echo "All dependencies are installed."