#!/bin/bash
# Validate test playbooks for syntax errors

set -e

echo "========================================="
echo "Validating Test Playbooks"
echo "========================================="
echo ""

ERRORS=0

for playbook in tests/playbooks/*.yml; do
    echo "Validating: $(basename $playbook)"

    # Run ansible-playbook syntax check
    docker run --rm \
      -e ANSIBLE_CONFIG=/ansible/tests/ansible.cfg \
      -v $(pwd):/ansible \
      -w /ansible/tests \
      quay.io/ansible/ansible-runner \
      ansible-playbook "playbooks/$(basename $playbook)" \
      -i inventories/test/hosts.yml \
      --syntax-check 2>&1

    if [ $? -eq 0 ]; then
        echo "  ✓ Syntax OK"
    else
        echo "  ✗ Syntax Error"
        ((ERRORS++))
    fi
    echo ""
done

echo "========================================="
if [ $ERRORS -eq 0 ]; then
    echo "✓ All playbooks valid!"
    exit 0
else
    echo "✗ Found $ERRORS error(s)"
    exit 1
fi
