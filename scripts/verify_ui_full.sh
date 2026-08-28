#!/usr/bin/env bash
# ==============================================================================
# Script Name : verify_ui_full.sh
# Purpose     : Verify HTTP status, UI structure, and endpoints integrity
# Logic       : Checks HTTP 200 on index, tests AI inference, Strategy, and Trade
# ==============================================================================

set -euo pipefail

echo "============================================================"
echo "          A1 STUDIO PRO v0.22.1 - VALIDATION SUITE          "
echo "============================================================"

# 1. UI Root Status
echo -n "[TEST 1/4] Checking UI Index Serving... "
UI_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/)
if [ "$UI_CODE" -eq 200 ]; then
    echo "OK (HTTP $UI_CODE)"
else
    echo "FAILED (HTTP $UI_CODE)"
fi

# 2. AI Inference Endpoint
echo -n "[TEST 2/4] Checking Local AI Endpoint (/api/ai/infer)... "
AI_RESP=$(curl -s -X POST http://127.0.0.1:8000/api/ai/infer \
    -H "Content-Type: application/json" \
    -d '{"symbol": "FOOLAD"}')
echo "$AI_RESP"

# 3. Strategy Engine Endpoint
echo -n "[TEST 3/4] Checking Strategy Engine (/api/strategy/evaluate)... "
STRAT_RESP=$(curl -s -X POST http://127.0.0.1:8000/api/strategy/evaluate \
    -H "Content-Type: application/json" \
    -d '{"strategy": "MOMENTUM_LOCAL_V1"}')
echo "$STRAT_RESP"

# 4. Trade Engine Endpoint
echo -n "[TEST 4/4] Checking Simulator Order (/api/trade/order)... "
TRADE_RESP=$(curl -s -X POST http://127.0.0.1:8000/api/trade/order \
    -H "Content-Type: application/json" \
    -d '{"symbol": "IKCO", "qty": 100, "side": "BUY"}')
echo "$TRADE_RESP"

echo "============================================================"
echo "                 ALL VALIDATION CHECKS COMPLETED            "
echo "============================================================"
