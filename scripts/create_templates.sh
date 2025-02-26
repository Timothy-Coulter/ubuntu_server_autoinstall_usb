#!/bin/bash
#
# Create template files for Ubuntu Server autoinstall

# Check if templates directory exists
if [[ ! -d "$TEMPLATES_DIR" ]]; then
    info "Creating templates directory: $TEMPLATES_DIR"
    mkdir -p "$TEMPLATES_DIR"
fi

# Create user-data template if it doesn't exist
if [[ ! -f "$TEMPLATES_DIR/user-data.yml" ]]; then
    info "Creating user-data template..."
    cat > "$TEMPLATES_DIR/user-data.yml" << 'EOF'
#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: us
  identity:
    hostname: ubuntu-server
    username: ubuntu
    # Password is 'ubuntu'
    password: '$6$exDY1mhS4KUYCE/2$zmn9ToZwTKLhCw.b4/b.ZRTIZM30JZ4QrOQ2aOXJ8yk96xpcCof0kxKwuX1kqLG/ygbJ1f8wxED22bTL4F46P0'
  ssh:
    install-server: true
    allow-pw: true
  storage:
    layout:
      name: direct
  packages:
    - openssh-server
    - cloud-init
  user-data:
    disable_root: false
  late-commands:
    - echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/ubuntu
    - chmod 440 /target/etc/sudoers.d/ubuntu
EOF
    info "User-data template created."
fi

# Create meta-data template if it doesn't exist
if [[ ! -f "$TEMPLATES_DIR/meta-data.yml" ]]; then
    info "Creating meta-data template..."
    cat > "$TEMPLATES_DIR/meta-data.yml" << 'EOF'
instance-id: ubuntu-server-autoinstall
local-hostname: ubuntu-server
EOF
    info "Meta-data template created."
fi

# Create network-config template if it doesn't exist
if [[ ! -f "$TEMPLATES_DIR/network-config.yml" ]]; then
    info "Creating network-config template..."
    cat > "$TEMPLATES_DIR/network-config.yml" << 'EOF'
version: 2
ethernets:
  eth0:
    dhcp4: true
    optional: true
EOF
    info "Network-config template created."
fi

# Inform user about customizing templates
info "Template files created in $TEMPLATES_DIR"
info "You can customize these files before proceeding with the USB preparation."
info "  - user-data.yml: Contains system configuration, user accounts, etc."
info "  - meta-data.yml: Contains instance metadata"
info "  - network-config.yml: Contains network configuration"

# Ask if user wants to customize templates
read -p "Do you want to customize the template files now? [y/N]: " customize_templates
if [[ "$customize_templates" == "y" || "$customize_templates" == "Y" ]]; then
    # Determine which editor to use
    if command_exists nano; then
        EDITOR=nano
    elif command_exists vim; then
        EDITOR=vim
    elif command_exists vi; then
        EDITOR=vi
    else
        warning "No suitable text editor found. Skipping customization."
        return 0
    fi
    
    # Edit user-data
    info "Opening user-data.yml for editing..."
    $EDITOR "$TEMPLATES_DIR/user-data.yml"
    
    # Edit network-config
    info "Opening network-config.yml for editing..."
    $EDITOR "$TEMPLATES_DIR/network-config.yml"
    
    info "Template customization complete."
fi