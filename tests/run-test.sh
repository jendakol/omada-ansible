#!/bin/bash
# Run a specific test playbook

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <test_name> [ansible-args...]"
    echo ""
    echo "Available tests:"
    echo "  controller_auth      - Controller Authentication"
    echo "  infra_networks       - Network Configuration (VLANs + DHCP auto-generation)"
    echo "  wireless_ssids       - WiFi Configuration"
    echo "  wireless_ppsk        - PPSK (Private Pre-Shared Key) Configuration"
    echo "  security_ip_groups   - IP Groups"
    echo "  security_firewall    - Firewall Rules"
    echo "  services_multicast   - mDNS Forwarding"
    echo "  nat_port_forward     - Port Forwarding"
    echo "  full_integration     - Full Integration Test"
    echo ""
    echo "Example: $0 controller_auth"
    echo "Example: $0 nat_port_forward -vvv"
    exit 1
fi

TEST_NAME=$1
shift

# Test playbook file
TEST_PLAYBOOK="tests/playbooks/test_${TEST_NAME}.yml"

# Special case for full integration
if [ "$TEST_NAME" = "full_integration" ]; then
    TEST_PLAYBOOK="tests/playbooks/99_test_full_integration.yml"
fi

# Check if test exists
if [ ! -f "$TEST_PLAYBOOK" ]; then
    echo "ERROR: Test '${TEST_NAME}' not found at: $TEST_PLAYBOOK"
    exit 1
fi

PLAYBOOK="$TEST_PLAYBOOK"

echo "========================================="
echo "Running test: $(basename $PLAYBOOK .yml)"
echo "========================================="
echo ""

# Check for vault files
VAULT_PASS_FILE="$HOME/.ansible/vault_pass"
VAULT_FILE="$(pwd)/tests/inventories/test/group_vars/all/vault.yml"
VAULT_VOLUME=""
VAULT_ARGS=""

if [ -f "$VAULT_PASS_FILE" ] && [ -f "$VAULT_FILE" ]; then
  VAULT_VOLUME="-v $VAULT_PASS_FILE:/root/vault_pass:ro"
  VAULT_ARGS="--vault-password-file /root/vault_pass -e @/ansible/tests/inventories/test/group_vars/all/vault.yml"
fi

# Run the test with Docker
# Uses host network to access production controller
docker run --rm \
  --network host \
  -e ANSIBLE_REMOTE_TMP=/tmp \
  -e ANSIBLE_LOCAL_TMP=/tmp \
  -e ANSIBLE_HOST_KEY_CHECKING=False \
  -e ANSIBLE_CONFIG=/ansible/tests/ansible.cfg \
  -v $(pwd):/ansible \
  $VAULT_VOLUME \
  -w /ansible/tests \
  quay.io/ansible/ansible-runner \
  ansible-playbook "playbooks/$(basename $PLAYBOOK)" \
  -i inventories/test/hosts.yml \
  $VAULT_ARGS \
  "$@"

echo ""
echo "========================================="
echo "Test completed"
echo "========================================="
