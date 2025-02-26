#!/bin/bash
#
# Utility functions for Ubuntu Server autoinstall USB scripts

# Print a banner with the given text
print_banner() {
    local text="$1"
    local length=${#text}
    local line=$(printf '%*s' "$length" | tr ' ' '=')
    
    echo
    echo "$line"
    echo "$text"
    echo "$line"
    echo
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 
        echo "Please run with sudo or as root user"
        exit 1
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Print error message and exit
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Print warning message
warning() {
    echo "WARNING: $1" >&2
}

# Print info message
info() {
    echo "INFO: $1"
}

# Create a temporary directory and ensure it's cleaned up on exit
create_temp_dir() {
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    echo "$temp_dir"
}

# Mount a device and ensure it's unmounted on exit
mount_device() {
    local device="$1"
    local mount_point="$2"
    
    mkdir -p "$mount_point"
    mount "$device" "$mount_point"
    
    # Return the mount point
    echo "$mount_point"
}

# Unmount a device safely
unmount_device() {
    local mount_point="$1"
    
    if mountpoint -q "$mount_point"; then
        umount "$mount_point"
    fi
}

# Get the size of a file in human-readable format
get_file_size() {
    local file="$1"
    du -h "$file" | cut -f1
}

# Check if a file exists and is readable
check_file_readable() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        error_exit "File not found: $file"
    fi
    if [[ ! -r "$file" ]]; then
        error_exit "File not readable: $file"
    fi
}

# Check if a directory exists and is writable
check_dir_writable() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        error_exit "Directory not found: $dir"
    fi
    if [[ ! -w "$dir" ]]; then
        error_exit "Directory not writable: $dir"
    fi
}

# Check if a block device exists
check_block_device() {
    local device="$1"
    if [[ ! -b "$device" ]]; then
        error_exit "Not a block device: $device"
    fi
}

# Get the device name without the path (e.g., /dev/sda -> sda)
get_device_name() {
    local device="$1"
    basename "$device"
}

# Get the partition device path (e.g., /dev/sda -> /dev/sda1)
get_partition_device() {
    local device="$1"
    local partition_number="$2"
    
    # Check if device ends with a number
    if [[ "$device" =~ [0-9]$ ]]; then
        echo "${device}p${partition_number}"
    else
        echo "${device}${partition_number}"
    fi
}

# Wait for a device to be available
wait_for_device() {
    local device="$1"
    local timeout="$2"
    local count=0
    
    while [[ ! -b "$device" && $count -lt $timeout ]]; do
        sleep 1
        ((count++))
    done
    
    if [[ ! -b "$device" ]]; then
        error_exit "Timeout waiting for device: $device"
    fi
}

# Check if a string is a valid URL
is_valid_url() {
    local url="$1"
    wget --spider "$url" >/dev/null 2>&1
    return $?
}

# Download a file with progress
download_file() {
    local url="$1"
    local output_file="$2"
    
    wget --progress=bar:force -O "$output_file" "$url"
    return $?
}

# Check if a file is an ISO image
is_iso_image() {
    local file="$1"
    file "$file" | grep -q "ISO 9660"
    return $?
}

# Check if a file is an IMG image
is_img_image() {
    local file="$1"
    # This is a simple check, might need to be improved
    file "$file" | grep -q "boot sector"
    return $?
}

# Calculate SHA256 checksum of a file
calculate_checksum() {
    local file="$1"
    sha256sum "$file" | cut -d' ' -f1
}

# Verify checksum of a file
verify_checksum() {
    local file="$1"
    local expected_checksum="$2"
    
    local actual_checksum=$(calculate_checksum "$file")
    
    if [[ "$actual_checksum" != "$expected_checksum" ]]; then
        error_exit "Checksum verification failed for $file"
    fi
}