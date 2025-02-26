#!/bin/bash
#
# Test Ubuntu Server autoinstall using KVM

# Get the USB device path from the first argument
USB_DEVICE="$1"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPTS_DIR="${PARENT_DIR}/scripts"

# Source utility functions
source "${SCRIPTS_DIR}/utils.sh"

# Check if USB device is provided
if [[ -z "$USB_DEVICE" ]]; then
    error_exit "No USB device specified."
fi

# Check if it's a block device
check_block_device "$USB_DEVICE"

# Check if KVM is available
if ! command_exists qemu-system-x86_64; then
    error_exit "qemu-system-x86_64 is not installed. Please install it to use KVM testing."
fi

# Create a temporary directory for VM files
VM_DIR=$(mktemp -d)
trap "rm -rf $VM_DIR" EXIT

# Create a virtual disk for the VM
VIRTUAL_DISK="${VM_DIR}/vm-disk.qcow2"
info "Creating virtual disk for testing..."
qemu-img create -f qcow2 "$VIRTUAL_DISK" 20G

# Test options
print_banner "KVM Test Options"
echo "1. Test boot only (no installation)"
echo "2. Test full autoinstall (will install Ubuntu on a virtual disk)"
echo "3. Test with custom options"
echo
read -p "Select an option [1-3]: " test_option

case $test_option in
    1)
        # Boot only test
        info "Starting KVM with boot-only test..."
        qemu-system-x86_64 \
            -m 2048 \
            -enable-kvm \
            -drive "file=$USB_DEVICE,format=raw,if=virtio,cache=none" \
            -boot menu=on
        ;;
    2)
        # Full autoinstall test
        info "Starting KVM with full autoinstall test..."
        info "This will install Ubuntu Server on a virtual disk."
        info "The installation will proceed automatically based on your autoinstall configuration."
        info "Press Ctrl+C to abort the test at any time."
        
        qemu-system-x86_64 \
            -m 2048 \
            -enable-kvm \
            -drive "file=$VIRTUAL_DISK,format=qcow2,if=virtio,cache=none" \
            -drive "file=$USB_DEVICE,format=raw,if=virtio,cache=none" \
            -boot menu=on
        ;;
    3)
        # Custom options
        info "Custom KVM test options:"
        
        # Ask for memory size
        read -p "Memory size in MB [2048]: " memory_size
        memory_size=${memory_size:-2048}
        
        # Ask for number of CPUs
        read -p "Number of CPUs [2]: " num_cpus
        num_cpus=${num_cpus:-2}
        
        # Ask for network type
        echo "Network type:"
        echo "1. User mode (default)"
        echo "2. Bridge mode (requires setup)"
        read -p "Select network type [1-2]: " network_type
        
        case $network_type in
            2)
                read -p "Bridge interface name [br0]: " bridge_name
                bridge_name=${bridge_name:-br0}
                network_opts="-netdev bridge,br=$bridge_name,id=net0 -device virtio-net-pci,netdev=net0"
                ;;
            *)
                network_opts="-netdev user,id=net0 -device virtio-net-pci,netdev=net0"
                ;;
        esac
        
        # Ask for display type
        echo "Display type:"
        echo "1. SDL (default)"
        echo "2. VNC"
        echo "3. No graphics (serial console only)"
        read -p "Select display type [1-3]: " display_type
        
        case $display_type in
            2)
                read -p "VNC display number [0]: " vnc_display
                vnc_display=${vnc_display:-0}
                display_opts="-vnc :$vnc_display"
                ;;
            3)
                display_opts="-nographic"
                ;;
            *)
                display_opts=""
                ;;
        esac
        
        info "Starting KVM with custom options..."
        qemu-system-x86_64 \
            -m "$memory_size" \
            -smp "$num_cpus" \
            -enable-kvm \
            -drive "file=$VIRTUAL_DISK,format=qcow2,if=virtio,cache=none" \
            -drive "file=$USB_DEVICE,format=raw,if=virtio,cache=none" \
            $network_opts \
            $display_opts \
            -boot menu=on
        ;;
    *)
        error_exit "Invalid option. Exiting."
        ;;
esac

info "KVM test completed."