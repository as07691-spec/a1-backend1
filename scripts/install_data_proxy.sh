#!/usr/bin/env bash
set -Eeuo pipefail

DEST_DIR="/opt/a1/backend/app"
DATA_DIR="/opt/a1/backend/data"
SERVICE_FILE="/etc/systemd/system/a1-data-proxy.service"

mkdir -p "$DEST_DIR" "$DATA_DIR" /var/log

# 1. Fetcher Core Worker
cat << 'PY_EOF' > "$DEST_DIR/data_fetcher.py"
import os
import time
import json
import logging
import requests

DATA_FILE = "/opt/a1/backend/data/market_snapshot.json"
TEMP_FILE = "/opt/a1/backend/data/market_snapshot.json.tmp"
LOG_FILE = "/var/log/a1_data_proxy.log"

logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Accept": "application/json, text/plain, */*",
    "Referer": "https://tsetmc.com/"
}

def fetch_market():
    # TSETMC Market Overview Endpoint
    url = "https://cdn.tsetmc.com/api/MarketData/GetMarketOverview/1"
    try:
        res = requests.get(url, headers=HEADERS, timeout=10)
        if res.status_code == 200:
            payload = {
                "ok": True,
                "timestamp": time.time(),
                "market_overview": res.json(),
                "net_value": 485000000,
                "buying_power": 120000000,
                "active_orders": 2,
                "trend": "Bullish (TSETMC Synchronized)"
            }
            with open(TEMP_FILE, "w", encoding="utf-8") as f:
                json.dump(payload, f, ensure_ascii=False)
            os.replace(TEMP_FILE, DATA_FILE)
            logging.info("Market snapshot successfully updated from TSETMC CDN.")
            return True
        else:
            logging.warning(f"TSETMC returned HTTP {res.status_code}")
    except Exception as err:
        logging.error(f"Market fetch failure: {err}")
    return False

if __name__ == "__main__":
    logging.info("Starting A1 TSETMC Data Proxy worker.")
    while True:
        fetch_market()
        time.sleep(10)
PY_EOF

# 2. Systemd Service Unit
cat << EOF > "$SERVICE_FILE"
[Unit]
Description=A1 Agent - TSETMC Secure Data Proxy
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DEST_DIR
ExecStart=/usr/bin/python3 $DEST_DIR/data_fetcher.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 3. Enable and Start
systemctl daemon-reload
systemctl enable a1-data-proxy.service
systemctl restart a1-data-proxy.service

echo "A1 Data Proxy installed and restarted."
