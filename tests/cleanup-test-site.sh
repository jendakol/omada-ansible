#!/bin/bash
# Delete Test-Automation site from production controller

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "Cleaning up Test Site"
echo "========================================="
echo ""
echo "⚠️  This will DELETE the Test-Automation site and all its data:"
echo "  - VLANs/Networks"
echo "  - DHCP Reservations"
echo "  - WiFi SSIDs"
echo "  - Firewall Rules"
echo "  - All test configuration"
echo ""
read -p "Are you sure? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Deleting Test-Automation site..."

# Check for vault files
VAULT_PASS_FILE="$HOME/.ansible/vault_pass"
VAULT_FILE="$ANSIBLE_DIR/tests/inventories/test/group_vars/all/vault.yml"
VAULT_VOLUME=""
VAULT_ARGS=""

if [ -f "$VAULT_PASS_FILE" ] && [ -f "$VAULT_FILE" ]; then
  VAULT_VOLUME="-v $VAULT_PASS_FILE:/root/vault_pass:ro"
  VAULT_ARGS="--vault-password-file /root/vault_pass -e @/ansible/tests/inventories/test/group_vars/all/vault.yml"
fi

# Run cleanup playbook
docker run --rm \
  --network host \
  -e ANSIBLE_REMOTE_TMP=/tmp \
  -e ANSIBLE_LOCAL_TMP=/tmp \
  -e ANSIBLE_HOST_KEY_CHECKING=False \
  -e ANSIBLE_CONFIG=/ansible/tests/ansible.cfg \
  -v "$ANSIBLE_DIR:/ansible" \
  $VAULT_VOLUME \
  -w /ansible/tests \
  quay.io/ansible/ansible-runner \
  ansible-playbook playbooks/00_cleanup_test_site.yml \
  -i inventories/test/hosts.yml \
  $VAULT_ARGS

echo ""
echo "========================================="
echo "✓ Test site deleted"
echo "========================================="
