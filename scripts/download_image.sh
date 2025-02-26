#!/bin/bash
#
# Download Ubuntu Server 24.04 image if not already downloaded

# Download directory
DOWNLOAD_DIR="/home/cirrus0/Downloads/os_images"
UBUNTU_VERSION="24.04"
ISO_FILENAME="ubuntu-server-${UBUNTU_VERSION}.iso"
DOWNLOAD_PATH="${DOWNLOAD_DIR}/${ISO_FILENAME}"

# Ubuntu Server 24.04 download URL
# Note: This URL might need to be updated when Ubuntu 24.04 is officially released
UBUNTU_URL="https://releases.ubuntu.com/${UBUNTU_VERSION}/ubuntu-${UBUNTU_VERSION}-live-server-amd64.iso"

# Create download directory if it doesn't exist
if [[ ! -d "$DOWNLOAD_DIR" ]]; then
    info "Creating download directory: $DOWNLOAD_DIR"
    mkdir -p "$DOWNLOAD_DIR"
fi

# Check if the image already exists
if [[ -f "$DOWNLOAD_PATH" ]]; then
    info "Ubuntu Server ${UBUNTU_VERSION} image already exists at: $DOWNLOAD_PATH"
    info "File size: $(get_file_size "$DOWNLOAD_PATH")"
    
    read -p "Do you want to use this existing image? [Y/n]: " use_existing
    if [[ "$use_existing" == "n" || "$use_existing" == "N" ]]; then
        info "Will download a fresh copy."
        rm -f "$DOWNLOAD_PATH"
    else
        info "Using existing image."
        return 0
    fi
fi

# Download the image
info "Downloading Ubuntu Server ${UBUNTU_VERSION} image..."
info "This may take a while depending on your internet connection."
info "Download URL: $UBUNTU_URL"
info "Download destination: $DOWNLOAD_PATH"

# Check if the URL is valid
if ! is_valid_url "$UBUNTU_URL"; then
    # If the URL is not valid, try to construct a new one
    warning "The download URL appears to be invalid: $UBUNTU_URL"
    warning "This might be because Ubuntu 24.04 is not yet released or the URL structure has changed."
    warning "Trying alternative URL..."
    
    # Try daily builds if the release is not available
    UBUNTU_URL="https://cdimage.ubuntu.com/ubuntu-server/daily-live/current/noble-live-server-amd64.iso"
    
    if ! is_valid_url "$UBUNTU_URL"; then
        error_exit "Could not find a valid download URL for Ubuntu Server ${UBUNTU_VERSION}."
    fi
    
    info "Found alternative URL: $UBUNTU_URL"
fi

# Download the image
if ! download_file "$UBUNTU_URL" "$DOWNLOAD_PATH"; then
    error_exit "Failed to download Ubuntu Server ${UBUNTU_VERSION} image."
fi

# Verify the download
info "Download complete."
info "Verifying the downloaded image..."

# Check if it's a valid ISO
if ! is_iso_image "$DOWNLOAD_PATH"; then
    error_exit "The downloaded file is not a valid ISO image."
fi

info "Ubuntu Server ${UBUNTU_VERSION} image downloaded and verified successfully."
info "Location: $DOWNLOAD_PATH"
info "File size: $(get_file_size "$DOWNLOAD_PATH")"

# Export the download path for the main script
export DOWNLOAD_PATH