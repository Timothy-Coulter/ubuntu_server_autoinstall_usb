#!/bin/bash
#
# Test Ubuntu Server autoinstall configuration

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPTS_DIR="${PARENT_DIR}/scripts"
TEMPLATES_DIR="${PARENT_DIR}/templates"

# Source utility functions
source "${SCRIPTS_DIR}/utils.sh"

# Check if running as root
check_root

# Create a temporary directory
TEMP_DIR=$(create_temp_dir)

print_banner "Ubuntu Server Autoinstall Configuration Test"

# Check if user-data file exists
if [[ ! -f "$TEMPLATES_DIR/user-data.yml" ]]; then
    error_exit "user-data.yml not found in $TEMPLATES_DIR. Please run create_templates.sh first."
fi

# Check if meta-data file exists
if [[ ! -f "$TEMPLATES_DIR/meta-data.yml" ]]; then
    error_exit "meta-data.yml not found in $TEMPLATES_DIR. Please run create_templates.sh first."
fi

# Copy template files to temp directory
cp "$TEMPLATES_DIR/user-data.yml" "$TEMP_DIR/user-data"
cp "$TEMPLATES_DIR/meta-data.yml" "$TEMP_DIR/meta-data"

# Copy network-config if it exists
if [[ -f "$TEMPLATES_DIR/network-config.yml" ]]; then
    cp "$TEMPLATES_DIR/network-config.yml" "$TEMP_DIR/network-config"
fi

# Validate YAML syntax
info "Validating YAML syntax of configuration files..."

if command_exists python3; then
    if python3 -c "import yaml" 2>/dev/null; then
        # Python with yaml module is available, use it to validate
        for file in "$TEMP_DIR"/*; do
            filename=$(basename "$file")
            info "Validating $filename..."
            if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
                error_exit "YAML validation failed for $filename. Please check the syntax."
            fi
        done
        info "All configuration files have valid YAML syntax."
    else
        warning "Python yaml module not available. Skipping YAML validation."
    fi
else
    warning "Python3 not available. Skipping YAML validation."
fi

# Check for required autoinstall keys in user-data
info "Checking for required autoinstall keys in user-data..."

# Basic check for required sections
if ! grep -q "^autoinstall:" "$TEMP_DIR/user-data"; then
    error_exit "Missing 'autoinstall' section in user-data."
fi

if ! grep -q "^  version:" "$TEMP_DIR/user-data"; then
    error_exit "Missing 'version' key in autoinstall section of user-data."
fi

# Check for identity section (required for non-interactive install)
if ! grep -q "^  identity:" "$TEMP_DIR/user-data"; then
    warning "Missing 'identity' section in user-data. This is required for non-interactive installation."
fi

# Check for storage section
if ! grep -q "^  storage:" "$TEMP_DIR/user-data"; then
    warning "Missing 'storage' section in user-data. Default storage configuration will be used."
fi

# Check for late-commands section
if grep -q "^  late-commands:" "$TEMP_DIR/user-data"; then
    info "Found 'late-commands' section in user-data."
    
    # Count number of late commands
    late_commands=$(grep -A 100 "^  late-commands:" "$TEMP_DIR/user-data" | grep -c "^    -")
    info "Found $late_commands late commands."
else
    info "No 'late-commands' section found in user-data."
fi

# Check for early-commands section
if grep -q "^  early-commands:" "$TEMP_DIR/user-data"; then
    info "Found 'early-commands' section in user-data."
    
    # Count number of early commands
    early_commands=$(grep -A 100 "^  early-commands:" "$TEMP_DIR/user-data" | grep -c "^    -")
    info "Found $early_commands early commands."
else
    info "No 'early-commands' section found in user-data."
fi

# Check for user-data section
if grep -q "^  user-data:" "$TEMP_DIR/user-data"; then
    info "Found 'user-data' section in user-data (cloud-init configuration)."
else
    info "No 'user-data' section found in user-data."
fi

# Check meta-data
info "Checking meta-data..."
if ! grep -q "^instance-id:" "$TEMP_DIR/meta-data"; then
    warning "Missing 'instance-id' in meta-data."
fi

# Check network-config if it exists
if [[ -f "$TEMP_DIR/network-config" ]]; then
    info "Checking network-config..."
    if ! grep -q "^version:" "$TEMP_DIR/network-config"; then
        warning "Missing 'version' in network-config."
    fi
else
    info "No network-config file found. Default network configuration will be used."
fi

# Summary
print_banner "Autoinstall Configuration Test Summary"

echo "Configuration files location: $TEMPLATES_DIR"
echo
echo "user-data: $(if [[ -f "$TEMPLATES_DIR/user-data.yml" ]]; then echo "Present"; else echo "Missing"; fi)"
echo "meta-data: $(if [[ -f "$TEMPLATES_DIR/meta-data.yml" ]]; then echo "Present"; else echo "Missing"; fi)"
echo "network-config: $(if [[ -f "$TEMPLATES_DIR/network-config.yml" ]]; then echo "Present"; else echo "Missing"; fi)"
echo
echo "The autoinstall configuration appears to be valid."
echo "You can now proceed with creating the USB drive."
echo
echo "Note: This is a basic validation. The actual installation might still fail"
echo "if there are logical errors in the configuration."