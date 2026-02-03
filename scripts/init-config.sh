#!/bin/bash
# Configuration Initialization Script
#
# Creates a new configuration repository from examples.
# Helps users get started with their own Omada configuration.

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success() {
    echo -e "${GREEN}✅${NC} $1"
}

info() {
    echo -e "${BLUE}ℹ️${NC}  $1"
}

warning() {
    echo -e "${YELLOW}⚠️${NC}  $1"
}

# Usage
if [ $# -eq 0 ]; then
    echo "Usage: $0 <target-directory>"
    echo ""
    echo "Creates a new Omada configuration from examples."
    echo ""
    echo "Example:"
    echo "  $0 ../my-omada-config"
    echo ""
    echo "This will create:"
    echo "  ../my-omada-config/inventories/production/"
    echo ""
    exit 1
fi

TARGET_DIR="$1"
INVENTORY_DIR="$TARGET_DIR/inventories/production"
GROUP_VARS="$INVENTORY_DIR/group_vars/all"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLES_DIR="$(dirname "$SCRIPT_DIR")/examples/inventories/example"

echo "=========================================="
echo "Omada Ansible Configuration Initialization"
echo "=========================================="
echo ""
info "Target directory: $TARGET_DIR"
info "Examples source: $EXAMPLES_DIR"
echo ""

# Check if examples exist
if [ ! -d "$EXAMPLES_DIR" ]; then
    echo "Error: Examples directory not found at $EXAMPLES_DIR"
    exit 1
fi

# Check if target already exists
if [ -d "$TARGET_DIR" ]; then
    warning "Target directory already exists"
    read -p "Do you want to continue? This may overwrite files. (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Aborted."
        exit 1
    fi
fi

# Create directory structure
echo "Step 1: Creating directory structure..."
echo "----------------------------------------"
mkdir -p "$GROUP_VARS"
success "Created $INVENTORY_DIR"

# Copy example files
echo ""
echo "Step 2: Copying example configuration files..."
echo "----------------------------------------"

# Copy hosts.yml
if [ -f "$EXAMPLES_DIR/hosts.yml.example" ]; then
    cp "$EXAMPLES_DIR/hosts.yml.example" "$INVENTORY_DIR/hosts.yml"
    success "Created hosts.yml"
fi

# Copy all config files without .example extension
for example_file in "$EXAMPLES_DIR/group_vars/all"/*.example; do
    if [ -f "$example_file" ]; then
        filename=$(basename "$example_file" .example)
        cp "$example_file" "$GROUP_VARS/$filename"
        success "Created $filename"
    fi
done

# Create .gitignore
echo ""
echo "Step 3: Creating .gitignore..."
echo "----------------------------------------"

cat > "$TARGET_DIR/.gitignore" << 'EOF'
# Ansible Vault password files
*.vault_pass
.vault_pass
vault_pass

# Ansible retry files
*.retry

# Python
__pycache__/
*.py[cod]
*$py.class

# OS files
.DS_Store
Thumbs.db

# Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# Logs
*.log

# Local testing
.ansible/
EOF

success "Created .gitignore"

# Create README
echo ""
echo "Step 4: Creating README..."
echo "----------------------------------------"

cat > "$TARGET_DIR/README.md" << 'EOF'
# My Omada SDN Configuration

Private configuration repository for Omada SDN Controller management.

## Setup

1. **Install Ansible Vault password file**:
   ```bash
   mkdir -p ~/.ansible
   echo "your-vault-password" > ~/.ansible/vault_pass
   chmod 600 ~/.ansible/vault_pass
   ```

2. **Encrypt sensitive variables**:
   ```bash
   ansible-vault encrypt_string 'your-username' --name 'vault_omada_username'
   ansible-vault encrypt_string 'your-password' --name 'vault_omada_password'
   ansible-vault encrypt_string 'wifi-password' --name 'vault_wifi_password_main'
   ```

3. **Edit configuration files**:
   - Update `inventories/production/group_vars/all/00_controller.yml` with your controller URL
   - Configure networks, devices, firewall rules, etc.

4. **Validate configuration**:
   ```bash
   cd /path/to/omada-ansible
   ./scripts/validate-config.sh ../my-omada-config/inventories/production
   ```

5. **Apply configuration**:
   ```bash
   cd /path/to/omada-ansible
   ansible-playbook -i ../my-omada-config/inventories/production playbooks/site.yml
   ```

## Configuration Files

- `00_controller.yml` - Controller connection settings (required)
- `infra_devices.yml` - Device registry (DHCP reservations auto-generated)
- `infra_networks.yml` - VLAN/network configuration
- `wireless_ssids.yml` - WiFi SSID configuration
- `security_ip_groups.yml` - IP address groups for firewall rules
- `security_firewall.yml` - Firewall ACL rules
- `services_multicast.yml` - mDNS/multicast forwarding
- `services_vpn.yml` - WireGuard VPN configuration
- `nat_port_forward.yml` - Port forwarding/NAT rules

## Notes

- This repository contains your private network configuration
- Keep it private! Do not share publicly
- Use Ansible Vault for all passwords and secrets
- Test changes in a non-production environment first
- Always validate before applying: `./scripts/validate-config.sh`

## Backup

Commit your configuration to version control:

```bash
git init
git add .
git commit -m "Initial Omada configuration"
git remote add origin <your-private-repo-url>
git push -u origin main
```
EOF

success "Created README.md"

# Create vault file template
echo ""
echo "Step 5: Creating vault template..."
echo "----------------------------------------"

cat > "$TARGET_DIR/vault-template.yml" << 'EOF'
# Ansible Vault Variables Template
#
# Copy these into your configuration files and encrypt them with:
# ansible-vault encrypt_string '<value>' --name '<variable-name>'

# Controller credentials
vault_omada_username: "admin"
vault_omada_password: "your-password-here"

# WiFi passwords
vault_wifi_password_main: "your-wifi-password"
vault_wifi_password_iot: "your-iot-wifi-password"
vault_wifi_password_guest: "your-guest-wifi-password"

# WireGuard VPN peer public keys (if using VPN)
vault_wireguard_peer_laptop_pubkey: "your-laptop-public-key"
vault_wireguard_peer_phone_pubkey: "your-phone-public-key"

# How to encrypt:
# ansible-vault encrypt_string 'actual-password' --name 'vault_omada_password'
#
# This will output encrypted text like:
# vault_omada_password: !vault |
#   $ANSIBLE_VAULT;1.1;AES256
#   ...encrypted data...
#
# Copy the entire output into your configuration file.
EOF

success "Created vault-template.yml"

# Summary
echo ""
echo "=========================================="
echo "✅ Configuration Initialized Successfully!"
echo "=========================================="
echo ""
info "Your configuration has been created at:"
echo "  $TARGET_DIR"
echo ""
info "Next steps:"
echo ""
echo "1. Edit configuration files:"
echo "   cd $TARGET_DIR"
echo "   vim inventories/production/group_vars/all/00_controller.yml"
echo ""
echo "2. Set up Ansible Vault:"
echo "   mkdir -p ~/.ansible"
echo "   echo 'your-vault-password' > ~/.ansible/vault_pass"
echo "   chmod 600 ~/.ansible/vault_pass"
echo ""
echo "3. Encrypt sensitive values (see vault-template.yml for examples)"
echo ""
echo "4. Validate configuration:"
echo "   ./scripts/validate-config.sh $INVENTORY_DIR"
echo ""
echo "5. Apply to controller:"
echo "   ansible-playbook -i $INVENTORY_DIR playbooks/site.yml"
echo ""
warning "Remember to version control your configuration (keep it private!)"
echo ""
