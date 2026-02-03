#!/bin/bash
# Automated Omada Controller Provisioning
# This script provisions a fresh Omada Controller via API

set -e

CONTROLLER_URL="https://localhost:8043"
ADMIN_USER="admin"
ADMIN_PASS="admin"
SITE_NAME="Default"

echo "========================================="
echo "Automated Controller Provisioning"
echo "========================================="
echo ""

# Function to wait for controller API
wait_for_api() {
    echo "Waiting for controller API to be ready..."
    MAX_WAIT=180
    WAITED=0

    while [ $WAITED -lt $MAX_WAIT ]; do
        if curl -k -s ${CONTROLLER_URL}/api/info >/dev/null 2>&1; then
            echo "✓ Controller API is responding"
            return 0
        fi
        echo -n "."
        sleep 3
        WAITED=$((WAITED + 3))
    done

    echo ""
    echo "ERROR: Controller API not responding after ${MAX_WAIT}s"
    return 1
}

# Function to check if controller is configured
is_configured() {
    local CONFIGURED=$(curl -k -s ${CONTROLLER_URL}/api/info | jq -r '.result.configured' 2>/dev/null || echo "false")
    [ "$CONFIGURED" == "true" ]
}

# Function to get controller ID
get_controller_id() {
    curl -k -s ${CONTROLLER_URL}/api/info | jq -r '.result.omadacId'
}

# Wait for API
wait_for_api || exit 1

# Check if already configured
if is_configured; then
    echo ""
    echo "✓ Controller is already configured"
    echo ""
    echo "Credentials:"
    echo "  URL: ${CONTROLLER_URL}"
    echo "  Username: ${ADMIN_USER}"
    echo "  Password: ${ADMIN_PASS}"
    exit 0
fi

OMADAC_ID=$(get_controller_id)
echo "Controller ID: ${OMADAC_ID}"
echo ""

# Try automated provisioning via API
echo "Attempting automated provisioning..."

# Step 1: Try to initialize via API (may not work on all versions)
echo "Step 1: Initializing controller..."

INIT_RESULT=$(curl -k -s -w "\n%{http_code}" -X POST ${CONTROLLER_URL}/${OMADAC_ID}/api/v2/login/init \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"${ADMIN_USER}\",
    \"password\": \"${ADMIN_PASS}\",
    \"email\": \"admin@test.local\"
  }")

HTTP_CODE=$(echo "$INIT_RESULT" | tail -1)
RESPONSE=$(echo "$INIT_RESULT" | sed '$d')

if [ "$HTTP_CODE" == "200" ]; then
    ERROR_CODE=$(echo "$RESPONSE" | jq -r '.errorCode')
    if [ "$ERROR_CODE" == "0" ]; then
        echo "✓ Controller initialized successfully via API"

        # Give it a moment to complete initialization
        sleep 5

        if is_configured; then
            echo ""
            echo "========================================="
            echo "✓ Automated provisioning successful!"
            echo "========================================="
            echo ""
            echo "Credentials:"
            echo "  URL: ${CONTROLLER_URL}"
            echo "  Username: ${ADMIN_USER}"
            echo "  Password: ${ADMIN_PASS}"
            echo ""
            exit 0
        fi
    fi
fi

# Automated provisioning failed - provide manual instructions
echo ""
echo "⚠️  Automated provisioning not available"
echo ""
echo "========================================="
echo "Manual Setup Required (one-time)"
echo "========================================="
echo ""
echo "Please complete setup manually:"
echo ""
echo "1. Open: ${CONTROLLER_URL}"
echo "   (Accept self-signed certificate)"
echo ""
echo "2. Setup wizard:"
echo "   Username: ${ADMIN_USER}"
echo "   Password: ${ADMIN_PASS}"
echo "   Email: admin@test.local"
echo "   Country: Any"
echo "   Timezone: Any"
echo ""
echo "3. Skip device discovery (no hardware needed)"
echo "4. Skip/disable cloud connection"
echo ""
echo "5. Once complete, run tests:"
echo "   ./tests/run-all-tests.sh"
echo ""
echo "Note: Configuration persists in Docker volume"
echo "      This is only needed once!"
echo ""

exit 1
