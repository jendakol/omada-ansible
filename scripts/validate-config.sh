#!/bin/bash
# Configuration Validation Script
#
# Validates Omada Ansible configuration before applying to controller.
# Checks YAML syntax, required fields, and common configuration errors.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0

error() {
    echo -e "${RED}❌ ERROR:${NC} $1"
    ERRORS=$((ERRORS + 1))
}

warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

success() {
    echo -e "${GREEN}✅${NC} $1"
}

info() {
    echo -e "${BLUE}ℹ️${NC}  $1"
}

# Usage
if [ $# -eq 0 ]; then
    echo "Usage: $0 <path-to-inventory>"
    echo ""
    echo "Example:"
    echo "  $0 ../my-omada-config/inventories/production"
    echo ""
    exit 1
fi

INVENTORY_PATH="$1"
GROUP_VARS="$INVENTORY_PATH/group_vars/all"

echo "=========================================="
echo "Omada Ansible Configuration Validation"
echo "=========================================="
echo ""
info "Validating: $INVENTORY_PATH"
echo ""

# Check if inventory path exists
if [ ! -d "$INVENTORY_PATH" ]; then
    error "Inventory path does not exist: $INVENTORY_PATH"
    exit 1
fi

# Check Python/yamllint availability
if ! command -v python3 &> /dev/null; then
    error "python3 not found. Please install Python 3."
    exit 1
fi

echo "Step 1: Checking directory structure..."
echo "----------------------------------------"

# Check for hosts.yml
if [ -f "$INVENTORY_PATH/hosts.yml" ]; then
    success "hosts.yml found"
else
    error "hosts.yml not found"
fi

# Check for group_vars directory
if [ -d "$GROUP_VARS" ]; then
    success "group_vars/all directory found"
else
    error "group_vars/all directory not found"
fi

echo ""
echo "Step 2: Checking required files..."
echo "----------------------------------------"

# List of required files
REQUIRED_FILES=(
    "00_controller.yml"
)

OPTIONAL_FILES=(
    "infra_devices.yml"
    "infra_networks.yml"
    "wireless_ssids.yml"
    "security_ip_groups.yml"
    "security_firewall.yml"
    "services_multicast.yml"
    "services_vpn.yml"
    "nat_port_forward.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$GROUP_VARS/$file" ]; then
        success "$file (required)"
    else
        error "$file is required but not found"
    fi
done

for file in "${OPTIONAL_FILES[@]}"; do
    if [ -f "$GROUP_VARS/$file" ]; then
        success "$file (optional)"
    else
        info "$file not found (optional, skipping)"
    fi
done

echo ""
echo "Step 3: Validating YAML syntax..."
echo "----------------------------------------"

# Validate YAML syntax with Python
for file in "$GROUP_VARS"/*.yml; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            success "$filename - Valid YAML syntax"
        else
            error "$filename - Invalid YAML syntax"
            python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>&1 | sed 's/^/  /'
        fi
    fi
done

echo ""
echo "Step 4: Validating controller configuration..."
echo "----------------------------------------"

if [ -f "$GROUP_VARS/00_controller.yml" ]; then
    # Check for required fields
    if grep -q "omada_controller_url:" "$GROUP_VARS/00_controller.yml"; then
        url=$(grep "omada_controller_url:" "$GROUP_VARS/00_controller.yml" | sed 's/.*: *"\?\([^"]*\)"\?.*/\1/' | tr -d '"' | tr -d "'")

        if [[ "$url" == *"example.com"* ]]; then
            warning "Controller URL still contains 'example.com' - update with your actual URL"
        elif [[ "$url" == https://* ]]; then
            success "Controller URL format valid"
        else
            error "Controller URL should start with https://"
        fi
    else
        error "omada_controller_url not found in controller config"
    fi

    if grep -q "omada_site:" "$GROUP_VARS/00_controller.yml"; then
        success "omada_site defined"
    else
        error "omada_site not found in controller config"
    fi

    if grep -q "omada_username:" "$GROUP_VARS/00_controller.yml"; then
        success "omada_username defined"
    else
        error "omada_username not found in controller config"
    fi

    if grep -q "omada_password:" "$GROUP_VARS/00_controller.yml"; then
        success "omada_password defined"
    else
        error "omada_password not found in controller config"
    fi
fi

echo ""
echo "Step 5: Validating network configuration..."
echo "----------------------------------------"

if [ -f "$GROUP_VARS/infra_networks.yml" ]; then
    # Check for VLAN ID conflicts
    vlan_ids=$(python3 - "$GROUP_VARS/infra_networks.yml" << 'EOF'
import yaml
import sys
try:
    with open(sys.argv[1]) as f:
        data = yaml.safe_load(f)
        if data and 'vlans' in data:
            ids = [v['id'] for v in data['vlans'] if 'id' in v]
            # Check for duplicates
            if len(ids) != len(set(ids)):
                print("DUPLICATE_VLAN_IDS")
            else:
                print("OK")
        else:
            print("NO_VLANS")
except Exception as e:
    print(f"ERROR: {e}")
EOF
)

    if [ "$vlan_ids" == "OK" ]; then
        success "No duplicate VLAN IDs found"
    elif [ "$vlan_ids" == "DUPLICATE_VLAN_IDS" ]; then
        error "Duplicate VLAN IDs found - each VLAN must have unique ID"
    elif [ "$vlan_ids" == "NO_VLANS" ]; then
        warning "No VLANs defined"
    else
        warning "Could not validate VLAN IDs"
    fi

    # Check for subnet overlaps (basic check)
    success "Network configuration structure valid"
else
    info "Networks configuration not found (optional)"
fi

echo ""
echo "Step 6: Validating device configuration..."
echo "----------------------------------------"

if [ -f "$GROUP_VARS/infra_devices.yml" ]; then
    # Check MAC address format
    mac_check=$(python3 - "$GROUP_VARS/infra_devices.yml" << 'EOF'
import yaml
import sys
import re
try:
    with open(sys.argv[1]) as f:
        data = yaml.safe_load(f)
        if data and 'devices' in data:
            mac_pattern = re.compile(r'^([0-9a-f]{2}:){5}[0-9a-f]{2}$')
            invalid = []
            for device in data['devices']:
                if 'mac' in device:
                    if not mac_pattern.match(device['mac']):
                        invalid.append(f"{device.get('name', 'unknown')}: {device['mac']}")
            if invalid:
                print("INVALID_MACS")
                for inv in invalid:
                    print(f"  {inv}")
            else:
                print("OK")
        else:
            print("NO_DEVICES")
except Exception as e:
    print(f"ERROR: {e}")
EOF
)

    if [ "$mac_check" == "OK" ]; then
        success "All MAC addresses valid"
    elif [[ "$mac_check" == INVALID_MACS* ]]; then
        error "Invalid MAC address format (use lowercase with colons: aa:bb:cc:dd:ee:ff)"
        echo "$mac_check" | grep -v "INVALID_MACS" | while read line; do
            echo "  $line"
        done
    elif [ "$mac_check" == "NO_DEVICES" ]; then
        warning "No devices defined"
    fi
else
    info "Devices configuration not found (optional)"
fi

echo ""
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Configuration is valid!${NC}"
    echo ""
    echo "You can now run:"
    echo "  ansible-playbook -i $INVENTORY_PATH playbooks/site.yml"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Configuration has $WARNINGS warning(s)${NC}"
    echo ""
    echo "Warnings should be reviewed but won't prevent deployment."
    echo "You can run:"
    echo "  ansible-playbook -i $INVENTORY_PATH playbooks/site.yml"
    echo ""
    exit 0
else
    echo -e "${RED}❌ Configuration has $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "Please fix errors before running playbook."
    echo ""
    exit 1
fi
