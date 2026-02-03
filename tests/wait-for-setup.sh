#!/bin/bash
# Wait for manual controller setup to complete

set -e

echo "========================================="
echo "Waiting for Controller Setup"
echo "========================================="
echo ""
echo "Please complete the manual setup at: https://localhost:8043"
echo ""
echo "Waiting for setup to complete..."
echo "(Press Ctrl+C to cancel)"
echo ""

MAX_WAIT=600  # 10 minutes
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]; do
    CONFIGURED=$(curl -k -s https://localhost:8043/api/info 2>/dev/null | jq -r '.result.configured' 2>/dev/null || echo "false")

    if [ "$CONFIGURED" == "true" ]; then
        echo ""
        echo "✓ Controller setup complete!"
        echo ""
        echo "Ready to run tests:"
        echo "  ./tests/run-all-tests.sh"
        exit 0
    fi

    echo -n "."
    sleep 5
    WAITED=$((WAITED + 5))
done

echo ""
echo "⚠️  Timeout waiting for setup"
echo "Please complete setup and run this script again"
exit 1
