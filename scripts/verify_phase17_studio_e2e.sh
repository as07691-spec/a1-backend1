#!/usr/bin/env bash
# ==============================================================================
# Script Name : verify_phase17_studio_e2e.sh
# Purpose     : Perform full end-to-end audit for A1 Studio UI and Phase 17 engine.
# Logic       : 1. Validate service uptime and process operational state.
#               2. Validate UI static entry point delivery (/opt/a1/frontend/index.html).
#               3. Query /api/market/overview and confirm ticker data structure.
#               4. Test AI and Strategy execution endpoints.
#               5. Generate structured audit status report.
# ==============================================================================
set -euo pipefail

readonly BASE_URL="http://127.0.0.1:8000"
readonly SERVICE_NAME="a1-agent.service"

echo "============================================================"
echo "       A1 STUDIO PRO - END-TO-END VERIFICATION AUDIT        "
echo "============================================================"

# Step 1: Check systemd backend service
echo -n "[TEST 1/5] Checking service status (${SERVICE_NAME})... "
if systemctl is-active --quiet "${SERVICE_NAME}"; then
    echo "PASS (ACTIVE)"
else
    echo "FAIL (INACTIVE)"
    exit 1
fi

# Step 2: Validate UI Delivery
echo -n "[TEST 2/5] Checking UI static file route (/)... "
UI_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/")
if [ "${UI_CODE}" -eq 200 ]; then
    echo "PASS (HTTP 200)"
else
    echo "FAIL (HTTP ${UI_CODE})"
    exit 1
fi

# Step 3: Validate Phase 17 Market Feed
echo -n "[TEST 3/5] Checking TSETMC Market Feed (/api/market/overview)... "
MARKET_RESPONSE=$(curl -s "${BASE_URL}/api/market/overview")
if echo "${MARKET_RESPONSE}" | grep -q "FOOLAD"; then
    echo "PASS (Market Stream Active)"
else
    echo "FAIL (Data Stream Incomplete)"
    exit 1
fi

# Step 4: AI Inference Endpoint Validation
echo -n "[TEST 4/5] Testing AI Inference Endpoint (/api/ai/infer)... "
AI_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/ai/infer" \
    -H "Content-Type: application/json" -d '{"symbol": "FOOLAD"}')
if [ "${AI_CODE}" -eq 200 ]; then
    echo "PASS (HTTP 200)"
else
    echo "FAIL (HTTP ${AI_CODE})"
    exit 1
fi

# Step 5: Strategy Evaluation Endpoint Validation
echo -n "[TEST 5/5] Testing Strategy Engine Endpoint (/api/strategy/evaluate)... "
STRAT_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/strategy/evaluate" \
    -H "Content-Type: application/json" -d '{"strategy": "MOMENTUM_LOCAL_V1"}')
if [ "${STRAT_CODE}" -eq 200 ]; then
    echo "PASS (HTTP 200)"
else
    echo "FAIL (HTTP ${STRAT_CODE})"
    exit 1
fi

echo "============================================================"
echo "          AUDIT RESULT: 5/5 TESTS PASSED (SUCCESS)          "
echo "============================================================"
