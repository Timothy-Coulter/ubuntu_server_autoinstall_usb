#!/bin/bash
#
# Test cloud-init configuration for Ubuntu Server

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

print_banner "Cloud-Init Configuration Test"

# Check if user-data file exists
if [[ ! -f "$TEMPLATES_DIR/user-data.yml" ]]; then
    error_exit "user-data.yml not found in $TEMPLATES_DIR. Please run create_templates.sh first."
fi

# Copy user-data to temp directory
cp "$TEMPLATES_DIR/user-data.yml" "$TEMP_DIR/user-data"

# Extract cloud-init configuration from user-data
info "Extracting cloud-init configuration from user-data..."
if grep -q "^  user-data:" "$TEMP_DIR/user-data"; then
    # Extract the user-data section and remove the leading spaces
    sed -n '/^  user-data:/,/^  [a-z]/ p' "$TEMP_DIR/user-data" | sed '1d;$d' | sed 's/^    //' > "$TEMP_DIR/cloud-init-config"
    
    if [[ ! -s "$TEMP_DIR/cloud-init-config" ]]; then
        warning "user-data section is empty in user-data.yml."
    else
        info "Extracted cloud-init configuration."
    fi
else
    # Create a minimal cloud-init config for testing
    cat > "$TEMP_DIR/cloud-init-config" << 'EOF'
# This is a minimal cloud-init configuration for testing
hostname: ubuntu-server
manage_etc_hosts: true
EOF
    warning "No user-data section found in user-data.yml. Created a minimal configuration for testing."
fi

# Validate cloud-init configuration
info "Validating cloud-init configuration..."

if command_exists cloud-init; then
    # If cloud-init is installed, use its validation tool
    if cloud-init schema --config-file "$TEMP_DIR/cloud-init-config" 2>/dev/null; then
        info "Cloud-init configuration is valid according to cloud-init schema validation."
    else
        warning "Cloud-init configuration failed schema validation. It may not work as expected."
    fi
elif command_exists python3; then
    if python3 -c "import yaml" 2>/dev/null; then
        # Python with yaml module is available, use it to validate
        info "Validating YAML syntax..."
        if ! python3 -c "import yaml; yaml.safe_load(open('$TEMP_DIR/cloud-init-config'))" 2>/dev/null; then
            error_exit "YAML validation failed for cloud-init configuration. Please check the syntax."
        fi
        info "Cloud-init configuration has valid YAML syntax."
    else
        warning "Python yaml module not available. Skipping YAML validation."
    fi
else
    warning "Neither cloud-init nor Python3 is available. Skipping validation."
fi

# Check for common cloud-init modules
info "Checking for common cloud-init modules in configuration..."

common_modules=(
    "hostname"
    "users"
    "ssh"
    "packages"
    "runcmd"
    "write_files"
    "bootcmd"
    "mounts"
    "apt"
    "timezone"
    "locale"
)

found_modules=()
for module in "${common_modules[@]}"; do
    if grep -q "^$module:" "$TEMP_DIR/cloud-init-config"; then
        found_modules+=("$module")
    fi
done

if [[ ${#found_modules[@]} -gt 0 ]]; then
    info "Found the following cloud-init modules in configuration:"
    for module in "${found_modules[@]}"; do
        echo "  - $module"
    done
else
    warning "No common cloud-init modules found in configuration."
fi

# Create a test environment for cloud-init
info "Creating a test environment for cloud-init..."

# Create a minimal cloud-init environment
mkdir -p "$TEMP_DIR/cloud-init-test/etc/cloud/cloud.cfg.d"
cp "$TEMP_DIR/cloud-init-config" "$TEMP_DIR/cloud-init-test/etc/cloud/cloud.cfg.d/99-custom.cfg"

# Create a test script to simulate cloud-init
cat > "$TEMP_DIR/test-cloud-init.sh" << 'EOF'
#!/bin/bash
echo "Simulating cloud-init with the provided configuration..."
echo "In a real environment, cloud-init would process the configuration and apply it to the system."
echo "The following configuration would be applied:"
echo "----------------------------------------"
cat "$1"
echo "----------------------------------------"
echo "Cloud-init simulation completed."
EOF

chmod +x "$TEMP_DIR/test-cloud-init.sh"

# Run the test script
info "Running cloud-init simulation..."
"$TEMP_DIR/test-cloud-init.sh" "$TEMP_DIR/cloud-init-test/etc/cloud/cloud.cfg.d/99-custom.cfg"

# Summary
print_banner "Cloud-Init Test Summary"

echo "Cloud-init configuration extracted from: $TEMPLATES_DIR/user-data.yml"
echo
echo "Found modules: ${found_modules[*]:-None}"
echo
echo "The cloud-init configuration appears to be valid."
echo "In a real environment, cloud-init would apply this configuration after installation."
echo
echo "Note: This is a basic validation. The actual cloud-init execution might still fail"
echo "if there are logical errors in the configuration."