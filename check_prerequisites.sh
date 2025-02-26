#!/bin/bash

# Check if required packages are installed
check_package() {
    if ! command -v "$1" &> /dev/null; then
        echo "Package $1 is not installed. Installing..."
        sudo apt update
        sudo apt install -y "$1"
    else
        echo "Package $1 is already installed."
    fi
}

echo "Checking prerequisites..."
check_package "p7zip"
check_package "wget"
check_package "xorriso"

echo "All prerequisites are installed."