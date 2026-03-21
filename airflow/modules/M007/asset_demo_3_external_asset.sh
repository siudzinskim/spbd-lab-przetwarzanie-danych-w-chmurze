#!/bin/bash
# To run this script, execute:
# ```
#     bash modules/M007/asset_demo_3_external_asset.sh
# ```
# then paste the airflow-ui URL

# --- CONFIGURATION ---
read -p "Enter Airflow Base URL (e.g., http://localhost:8080): " AIRFLOW_BASE_URL
ASSET_URI="event://milestones/external_trigger"
USERNAME="admin"
PASSWORD="admin"

echo "------------------------------------------------"
echo "Step 1: Authenticating and obtaining JWT Token..."
# ------------------------------------------------
TOKEN=$(curl -s -X POST "$AIRFLOW_BASE_URL/auth/token" \
  -H "Content-Type: application/json" \
  -d "{ \"username\": \"$USERNAME\", \"password\": \"$PASSWORD\" }" | jq -r '.access_token')

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
    echo "Error: Authentication failed. Please check your credentials."
    exit 1
fi
echo "Success: JWT Token acquired."

echo "------------------------------------------------"
echo "Step 2: Resolving internal Asset ID from URI..."
# ------------------------------------------------
# Airflow 3.0 API requires the numeric internal ID (Asset ID)
ASSET_ID=$(curl -s -X GET "$AIRFLOW_BASE_URL/api/v2/assets" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" | \
  jq -r ".assets[] | select(.uri == \"$ASSET_URI\") | .id")

if [ "$ASSET_ID" == "null" ] || [ -z "$ASSET_ID" ]; then
    echo "Error: Could not find an Asset with URI: $ASSET_URI"
    echo "Make sure your Consumer DAG is deployed and 'On'."
    exit 1
fi
echo "Success: Found Asset ID: $ASSET_ID"

echo "------------------------------------------------"
echo "Step 3: Creating Asset Event (Triggering Consumer)..."
# ------------------------------------------------
curl -X POST "$AIRFLOW_BASE_URL/api/v2/assets/events" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"asset_id\": $ASSET_ID,
    \"extra\": {
      \"source\": \"External System (Bash Script)\",
      \"status\": \"success\",
      \"message\": \"Triggered directly via API v2\"
    }
  }"

echo -e "\n------------------------------------------------"
echo "Process Complete! The Consumer DAG should start now."