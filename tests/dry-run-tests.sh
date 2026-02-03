#!/bin/bash
# Dry-run all tests to show what would be executed

set -e

echo "========================================="
echo "Dry-Run: Test Execution Plan"
echo "========================================="
echo ""

TESTS=(01 02 03 04 05 06 07 08 99)

for TEST in "${TESTS[@]}"; do
    PLAYBOOK=$(ls tests/playbooks/${TEST}_test_*.yml | head -1)
    TEST_NAME=$(basename $PLAYBOOK .yml | sed 's/^[0-9]*_test_//')

    echo "========================================="
    echo "Test $TEST: $TEST_NAME"
    echo "========================================="

    # Run check mode
    docker run --rm \
      -e ANSIBLE_CONFIG=/ansible/tests/ansible.cfg \
      -v $(pwd):/ansible \
      -w /ansible/tests \
      quay.io/ansible/ansible-runner \
      ansible-playbook "playbooks/$(basename $PLAYBOOK)" \
      -i inventories/test/hosts.yml \
      --check \
      --list-tasks 2>&1 | grep -E "(TASK|PLAY)" || echo "  (Would execute test tasks)"

    echo ""
done

echo "========================================="
echo "Dry-run complete"
echo "========================================="
