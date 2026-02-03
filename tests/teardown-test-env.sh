#!/bin/bash
# Teardown test environment - stop and clean up

set -e

echo "========================================="
echo "Tearing down test environment"
echo "========================================="
echo ""

cd tests

# Stop and remove containers
echo "Stopping Omada Controller..."
docker-compose down

# Optionally remove volumes (data cleanup)
if [ "$1" == "--clean" ]; then
    echo ""
    echo "Cleaning up data volumes..."
    docker-compose down -v
    echo "✓ All data removed"
fi

echo ""
echo "========================================="
echo "Test environment stopped"
echo "========================================="
echo ""
echo "To restart: ./tests/setup-test-env.sh"
echo "To clean all data: ./tests/teardown-test-env.sh --clean"
