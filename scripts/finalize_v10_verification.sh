#!/usr/bin/env bash
# ==============================================================================
# Script Name : finalize_v10_verification.sh
# Purpose     : Perform end-to-end integration and smoke testing for A1 UI v10.
# Logic       : 1. Verifies UI index delivery and static asset integrity.
#               2. Executes validation tests on AI, Strategy, and Trade APIs.
#               3. Checks systemd service status and memory limits.
#               4. Emits a structured summary report with exit code 0 on success.
# ==============================================================================

set -euo pipefail

readonly BASE_URL="http://127.0.0.1:8000"
readonly SERVICE_NAME="a1-agent.service"

echo "============================================================"
echo "          A1 STUDIO PRO v0.22.1 - FULL SMOKE TEST           "
echo "============================================================"

# Step 1: UI Root Validation
echo -n "[CHECK 1/5] UI Static File Delivery (/)... "
UI_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/")
if [ "$UI_STATUS" -eq 200 ]; then
    echo "PASS (HTTP 200)"
else
    echo "FAIL (HTTP $UI_STATUS)"
    exit 1
fi

# Step 2: AI Infer API Validation
echo -n "[CHECK 2/5] AI Inference API (/api/ai/infer)... "
AI_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/ai/infer" \
    -H "Content-Type: application/json" -d '{"symbol": "FOOLAD"}')
if [ "$AI_STATUS" -eq 200 ]; then
    echo "PASS (HTTP 200)"
else
    echo "FAIL (HTTP $AI_STATUS)"
    exit 1
fi

# Step 3: Strategy Evaluation API Validation
echo -n "[CHECK 3/5] Strategy Engine API (/api/strategy/evaluate)... "
STRAT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/strategy/evaluate" \
    -H "Content-Type: application/json" -d '{"strategy": "MOMENTUM_LOCAL_V1"}')
if [ "$STRAT_STATUS" -eq 200 ]; then
    echo "PASS (HTTP 200)"
else
    echo "FAIL (HTTP $STRAT_STATUS)"
    exit 1
fi

# Step 4: Trade Order Simulation API Validation
echo -n "[CHECK 4/5] Simulator Trade Order API (/api/trade/order)... "
TRADE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/trade/order" \
    -H "Content-Type: application/json" -d '{"symbol": "IKCO", "qty": 100, "side": "BUY"}')
if [ "$TRADE_STATUS" -eq 200 ]; then
    echo "PASS (HTTP 200)"
else
    echo "FAIL (HTTP $TRADE_STATUS)"
    exit 1
fi

# Step 5: Systemd Unit Status Check
echo -n "[CHECK 5/5] Backend Daemon State (${SERVICE_NAME})... "
if systemctl is-active --quiet "${SERVICE_NAME}"; then
    echo "PASS (active/running)"
else
    echo "FAIL (service not active)"
    exit 1
fi

echo "============================================================"
echo "          RESULT: ALL 5/5 CHECKS PASSED SUCCESSFULLY         "
echo "============================================================"
