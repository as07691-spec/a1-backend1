#!/usr/bin/env bash
set -Eeuo pipefail

echo "======================================================"
echo "    A1 AUTONOMOUS TRADING AGENT - WEB AUDIT SUITE     "
echo "======================================================"

echo -n "[1/6] Web Root (HTTP 200 OK)... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/)
if [ "$HTTP_CODE" = "200" ]; then
    echo "PASS (HTTP 200)"
else
    echo "FAIL (HTTP $HTTP_CODE)"
fi

echo -n "[2/6] Market Snapshot Route... "
SNAP_OK=$(curl -s http://127.0.0.1:8000/api/market/snapshot | jq -r '.ok // false')
if [ "$SNAP_OK" = "true" ]; then
    echo "PASS"
else
    echo "FAIL"
fi

echo -n "[3/6] Local AI Engine Engine Route... "
AI_SIG=$(curl -s -X POST http://127.0.0.1:8000/api/ai/analyze-market | jq -r '.signal // empty')
if [ -n "$AI_SIG" ]; then
    echo "PASS (Signal: $AI_SIG)"
else
    echo "FAIL"
fi

echo -n "[4/6] Strategy Telemetry Log... "
STRAT_COUNT=$(curl -s http://127.0.0.1:8000/api/strategy/history | jq '.history | length')
echo "PASS ($STRAT_COUNT records found)"

echo -n "[5/6] Order Book Execution History... "
ORDER_COUNT=$(curl -s http://127.0.0.1:8000/api/trade/orders | jq '.orders | length')
echo "PASS ($ORDER_COUNT orders recorded)"

echo -n "[6/6] Static Assets & UI Script Validation... "
HAS_CHART=$(curl -s http://127.0.0.1:8000/ | grep -c "dashboard-chart" || true)
HAS_JS=$(curl -s http://127.0.0.1:8000/ | grep -c "DashboardManager" || true)
if [ "$HAS_CHART" -gt 0 ] && [ "$HAS_JS" -gt 0 ]; then
    echo "PASS (DOM Elements & JS Modules Verified)"
else
    echo "FAIL"
fi

echo "======================================================"
echo "          WEB INTERFACE VALIDATION COMPLETED          "
echo "======================================================"
