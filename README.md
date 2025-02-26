# Ubuntu Server 22.04 Autoinstall USB Creator

This toolkit automates the creation of a bootable USB drive that performs an unattended installation of Ubuntu Server 22.04 LTS.

## Features

- Automatic checking and installation of required dependencies
- Checks for existing Ubuntu 22.04 Server ISO before downloading
- Unpacks and modifies the ISO to support autoinstallation
- Creates a custom bootable ISO with autoinstall configuration
- Prepares a USB drive for unattended installation

## Scripts Overview

- `create_autoinstall_usb.sh`: Main script that orchestrates the entire process
- `check_prerequisites.sh`: Checks and installs required packages
- `check_download_iso.sh`: Verifies if ISO exists or downloads if needed
- `prepare_iso.sh`: Unpacks and modifies the ISO for autoinstallation
- `build_custom_iso.sh`: Builds the custom autoinstall ISO
- `prepare_usb.sh`: Formats and prepares the USB drive
- `user-data`: Configuration file for the autoinstall process

## Usage

1. Make the main script executable:
   ```
   chmod +x create_autoinstall_usb.sh
   ```

2. Run the main script:
   ```
   ./create_autoinstall_usb.sh
   ```

3. Follow the prompts to complete the process.

## Customization

You can modify the `user-data` file to customize the installation:

- Change the username and password
- Modify installed packages
- Change locale and keyboard settings
- Adjust partitioning strategy
- Add additional late-commands

## Notes

- The default user credentials are:
  - Username: ubuntu
  - Password: ubuntu (hashed in user-data)
- The autoinstall ISO is saved at `ubuntu-22.04-autoinstall.iso`
- The process requires sudo privileges for certain operations
- Be extremely careful when selecting the USB device to avoid data loss

## Warning

**THIS TOOL WILL COMPLETELY ERASE THE SELECTED USB DRIVE. ALL DATA WILL BE LOST.**

Always double-check the device name before confirming the USB preparation.