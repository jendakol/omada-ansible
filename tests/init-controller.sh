#!/bin/bash
# Automated Omada Controller Initial Setup

set -e

CONTROLLER_URL="https://localhost:8043"
ADMIN_USER="admin"
ADMIN_PASS="admin"
SITE_NAME="Default"

echo "========================================="
echo "Initializing Omada Controller"
echo "========================================="
echo ""

# Wait for controller to be ready
echo "Checking controller status..."
MAX_WAIT=60
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]; do
    if curl -k -s ${CONTROLLER_URL}/api/info > /dev/null 2>&1; then
        break
    fi
    echo -n "."
    sleep 2
    WAITED=$((WAITED + 2))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo ""
    echo "ERROR: Controller not responding"
    exit 1
fi

echo ""
echo "Controller is responding"

# Get controller info
CONTROLLER_INFO=$(curl -k -s ${CONTROLLER_URL}/api/info)
CONFIGURED=$(echo $CONTROLLER_INFO | jq -r '.result.configured')
OMADAC_ID=$(echo $CONTROLLER_INFO | jq -r '.result.omadacId')

echo "Controller ID: $OMADAC_ID"
echo "Configured: $CONFIGURED"

if [ "$CONFIGURED" == "true" ]; then
    echo ""
    echo "✓ Controller already configured"
    exit 0
fi

echo ""
echo "Running initial setup..."

# Step 1: Initialize controller
echo "Step 1: Initializing controller..."
INIT_RESPONSE=$(curl -k -s -X POST ${CONTROLLER_URL}/${OMADAC_ID}/api/v2/login/init \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"${ADMIN_USER}\",
    \"password\": \"${ADMIN_PASS}\",
    \"email\": \"admin@example.com\"
  }")

INIT_ERROR=$(echo $INIT_RESPONSE | jq -r '.errorCode')

if [ "$INIT_ERROR" != "0" ]; then
    echo "ERROR: Failed to initialize controller"
    echo $INIT_RESPONSE | jq .
    exit 1
fi

echo "✓ Controller initialized"

# Step 2: Login
echo "Step 2: Logging in..."
LOGIN_RESPONSE=$(curl -k -s -X POST ${CONTROLLER_URL}/${OMADAC_ID}/api/v2/login \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"${ADMIN_USER}\",
    \"password\": \"${ADMIN_PASS}\"
  }" \
  -c /tmp/omada-cookies.txt)

LOGIN_ERROR=$(echo $LOGIN_RESPONSE | jq -r '.errorCode')

if [ "$LOGIN_ERROR" != "0" ]; then
    echo "ERROR: Failed to login"
    echo $LOGIN_RESPONSE | jq .
    exit 1
fi

# Extract CSRF token
CSRF_TOKEN=$(grep csrfToken /tmp/omada-cookies.txt | awk '{print $7}')

if [ -z "$CSRF_TOKEN" ]; then
    echo "ERROR: No CSRF token found"
    exit 1
fi

echo "✓ Logged in successfully"

# Step 3: Get sites
echo "Step 3: Checking for sites..."
SITES_RESPONSE=$(curl -k -s -X GET ${CONTROLLER_URL}/${OMADAC_ID}/api/v2/sites \
  -H "Csrf-Token: ${CSRF_TOKEN}" \
  -b /tmp/omada-cookies.txt)

SITE_EXISTS=$(echo $SITES_RESPONSE | jq -r ".result.data[] | select(.name==\"${SITE_NAME}\") | .id")

if [ -n "$SITE_EXISTS" ]; then
    echo "✓ Site '${SITE_NAME}' already exists (ID: $SITE_EXISTS)"
else
    echo "Site '${SITE_NAME}' not found - this is expected for fresh install"
    echo "Note: Default site is created automatically"
fi

echo ""
echo "========================================="
echo "✓ Controller initialization complete!"
echo "========================================="
echo ""
echo "Credentials:"
echo "  Username: ${ADMIN_USER}"
echo "  Password: ${ADMIN_PASS}"
echo ""
echo "Ready for testing!"

# Cleanup
rm -f /tmp/omada-cookies.txt
