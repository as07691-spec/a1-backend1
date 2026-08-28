#!/usr/bin/env bash
set -euo pipefail

echo "[AUDIT] Checking UI and API Health..."
UI_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:8000/")
MARKET_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:8000/api/market/overview")

if [ "$UI_STATUS" -eq 200 ] && [ "$MARKET_STATUS" -eq 200 ]; then
    echo "SUCCESS: Site and API responding (200 OK)."
else
    echo "ERROR: Site or API unreachable."
    exit 1
fi
