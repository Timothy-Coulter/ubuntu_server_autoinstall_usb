# Ubuntu Server 24.04 Autoinstall USB Creator

This project provides a set of scripts to create a USB drive for non-interactive installation of Ubuntu Server 24.04. The scripts handle both ISO and IMG image files and create a fully automated installation process.

## Features

- Downloads Ubuntu Server 24.04 image if not already available
- Formats and prepares USB drives for installation
- Supports both ISO and IMG image files
- Creates customizable templates for autoinstall, cloud-init, and network configuration
- Provides testing capabilities using KVM
- Separates functionality into modular scripts for maintainability

## Prerequisites

The scripts require the following tools to be installed:

- bash
- wget
- lsblk
- parted
- mkfs.vfat
- mkfs.ext4
- mount/umount
- rsync
- dd
- sha256sum
- file
- qemu-system-x86_64 (for KVM testing)
- xorriso (for ISO manipulation)

You can install these dependencies on Ubuntu with:

```bash
sudo apt update
sudo apt install -y wget parted dosfstools e2fsprogs rsync coreutils file qemu-system-x86 xorriso
```

## Directory Structure

```
ubuntu_server_autoinstall_usb/
├── create_ubuntu_usb.sh       # Main entrypoint script
├── README.md                  # This file
├── scripts/                   # Utility scripts
│   ├── check_dependencies.sh  # Check for required tools
│   ├── create_templates.sh    # Create template files
│   ├── download_image.sh      # Download Ubuntu Server image
│   ├── format_usb.sh          # Format USB drive
│   ├── prepare_usb.sh         # Prepare USB with image and files
│   └── utils.sh               # Common utility functions
├── templates/                 # Template files
│   ├── meta-data.yml          # Instance metadata
│   ├── network-config.yml     # Network configuration
│   └── user-data.yml          # System configuration
└── tests/                     # Test scripts
    ├── test_autoinstall.sh    # Test autoinstall configuration
    ├── test_cloud_init.sh     # Test cloud-init configuration
    └── test_kvm.sh            # Test with KVM
```

## Usage

1. Run the main script:

```bash
sudo ./create_ubuntu_usb.sh
```

2. Follow the prompts to:
   - Select or download an Ubuntu Server 24.04 image
   - Choose a USB device
   - Customize autoinstall templates (optional)
   - Format and prepare the USB drive
   - Test the installation with KVM (optional)

## Customization

The script creates template files in the `templates/` directory that you can customize:

- `user-data.yml`: Contains system configuration, user accounts, etc.
- `meta-data.yml`: Contains instance metadata
- `network-config.yml`: Contains network configuration

You can edit these files before running the USB preparation to customize the installation.

## Testing

The scripts provide several testing options:

- `test_autoinstall.sh`: Validates the autoinstall configuration
- `test_cloud_init.sh`: Validates the cloud-init configuration
- `test_kvm.sh`: Tests the installation using KVM

To run the tests individually:

```bash
sudo ./tests/test_autoinstall.sh
sudo ./tests/test_cloud_init.sh
sudo ./tests/test_kvm.sh /dev/sdX  # Replace with your USB device
```

## Notes

- The scripts require root privileges to format and prepare the USB drive.
- All data on the selected USB drive will be erased during the process.
- The default autoinstall configuration creates a user named `ubuntu` with password `ubuntu`.
- The installation is completely non-interactive and will erase the target disk.

## Troubleshooting

If you encounter issues:

1. Check that all dependencies are installed
2. Verify that the USB drive is properly detected
3. Ensure the Ubuntu image is valid
4. Check the autoinstall configuration for errors
5. Try testing with KVM before using on physical hardware

## License

This project is open source and available under the MIT License.