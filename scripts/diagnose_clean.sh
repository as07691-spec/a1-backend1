#!/usr/bin/env bash
# ==============================================================================
# Script Name : diagnose_clean.sh
# Purpose     : Diagnose service status, port availability, and API endpoints.
# Logic       : Read verify_ui_full.sh, inspect systemd status, test HTTP routes.
# Reason      : Determine why validation stopped and verify API routes directly.
# ==============================================================================

set -u

echo "============================================================"
echo "A1 VALIDATION AND ENDPOINT INSPECTION"
echo "============================================================"

echo "==> 1. Content of verify_ui_full.sh:"
if [ -f /opt/a1/backend/scripts/verify_ui_full.sh ]; then
    cat /opt/a1/backend/scripts/verify_ui_full.sh
else
    echo "FILE NOT FOUND"
fi
echo

echo "==> 2. Service status:"
systemctl status a1-agent.service --no-pager
echo

echo "==> 3. Listening port 8000:"
ss -ltnp | grep :8000 || echo "Port 8000 not listening"
echo

echo "==> 4. Test UI Index (GET /):"
curl -s -o /dev/null -w "HTTP_CODE: %{http_code}\n" http://127.0.0.1:8000/ || true
echo

echo "==> 5. Test AI Infer (POST /api/ai/infer):"
curl -s -w "\nHTTP_CODE: %{http_code}\n" \
  -H "Content-Type: application/json" \
  -d '{"symbol":"FOOLAD"}' \
  http://127.0.0.1:8000/api/ai/infer || true
echo

echo "==> 6. Test Strategy Evaluate (POST /api/strategy/evaluate):"
curl -s -w "\nHTTP_CODE: %{http_code}\n" \
  -H "Content-Type: application/json" \
  -d '{"strategy":"MOMENTUM_LOCAL_V1"}' \
  http://127.0.0.1:8000/api/strategy/evaluate || true
echo

echo "==> 7. Test Trade Order (POST /api/trade/order):"
curl -s -w "\nHTTP_CODE: %{http_code}\n" \
  -H "Content-Type: application/json" \
  -d '{"symbol":"FOOLAD","qty":10,"side":"BUY"}' \
  http://127.0.0.1:8000/api/trade/order || true
echo

echo "==> 8. Test Killswitch (POST /api/trade/killswitch):"
curl -s -w "\nHTTP_CODE: %{http_code}\n" \
  -X POST \
  http://127.0.0.1:8000/api/trade/killswitch || true
echo
