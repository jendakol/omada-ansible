#!/bin/bash
# Create Test-Automation site on production controller

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "Setting up Test Site"
echo "========================================="
echo ""

# Check for vault files
VAULT_PASS_FILE="$HOME/.ansible/vault_pass"
VAULT_FILE="$ANSIBLE_DIR/tests/inventories/test/group_vars/all/vault.yml"
VAULT_VOLUME=""
VAULT_ARGS=""

if [ -f "$VAULT_PASS_FILE" ] && [ -f "$VAULT_FILE" ]; then
  VAULT_VOLUME="-v $VAULT_PASS_FILE:/root/vault_pass:ro"
  VAULT_ARGS="--vault-password-file /root/vault_pass -e @/ansible/tests/inventories/test/group_vars/all/vault.yml"
fi

# Run a simple playbook to create the test site
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
  ansible-playbook playbooks/00_setup_test_site.yml \
  -i inventories/test/hosts.yml \
  $VAULT_ARGS

echo ""
echo "========================================="
echo "✓ Test site ready!"
echo "========================================="
echo ""
echo "Test Site: Test-Automation"
echo "Controller: https://omada.home.jenda.eu"
echo ""
echo "Run tests with:"
echo "  ./tests/run-all-tests.sh"
echo ""
echo "Cleanup test site:"
echo "  ./tests/cleanup-test-site.sh"
