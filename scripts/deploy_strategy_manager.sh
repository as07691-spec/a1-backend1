#!/usr/bin/env bash
set -Eeuo pipefail

BACKEND_DIR="/opt/a1/backend"
STRATEGY_DIR="$BACKEND_DIR/strategy"
DATA_DIR="$BACKEND_DIR/data"
WWW_DIR="$BACKEND_DIR/www"

# 1. Strategy & Signal History Module
cat << 'STRAT_EOF' > "$STRATEGY_DIR/manager.py"
import os
import json
import time
from typing import Dict, Any, List

HISTORY_FILE = "/opt/a1/backend/data/trade_signals.jsonl"

class StrategyManager:
    def __init__(self):
        self.active_strategy = "Adaptive-Mean-Reversion-v1"
        self.history_file = HISTORY_FILE

    def record_signal(self, signal_data: Dict[str, Any]) -> None:
        try:
            entry = {
                "timestamp": time.time(),
                "time_iso": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
                "signal": signal_data.get("signal", "HOLD"),
                "risk_score": signal_data.get("risk_score", 0.0),
                "model": signal_data.get("model", "local"),
                "power_ratio": signal_data.get("metrics", {}).get("power_ratio", 0.0)
            }
            with open(self.history_file, "a", encoding="utf-8") as f:
                f.write(json.dumps(entry, ensure_ascii=False) + "\n")
        except Exception:
            pass

    def get_recent_signals(self, limit: int = 10) -> List[Dict[str, Any]]:
        if not os.path.exists(self.history_file):
            return []
        try:
            with open(self.history_file, "r", encoding="utf-8") as f:
                lines = f.readlines()
            records = [json.loads(line.strip()) for line in lines if line.strip()]
            return records[-limit:]
        except Exception:
            return []

strategy_mgr = StrategyManager()
STRAT_EOF

# 2. Update Unified Application with Strategy History Endpoints
cat << 'APP_EOF' > "$BACKEND_DIR/unified_app.py"
import os
import json
from fastapi import FastAPI
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from ai_engine.engine import ai_engine
from strategy.manager import strategy_mgr

DATA_FILE = "/opt/a1/backend/data/market_snapshot.json"
WWW_DIR = "/opt/a1/backend/www"

app = FastAPI(title="A1 Autonomous Trading Agent", version="0.20.0")

# --- Routes: Health ---
@app.api_route("/api/health", methods=["GET", "HEAD"])
def health_check():
    return {"status": "ok", "service": "A1-Agent", "ok": True, "version": "0.20.0"}

# --- Routes: Market ---
@app.api_route("/api/market/snapshot", methods=["GET", "HEAD"])
def get_market_snapshot():
    if not os.path.exists(DATA_FILE):
        return JSONResponse(status_code=404, content={"ok": False, "message": "Market snapshot not found"})
    try:
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        return JSONResponse(status_code=200, content={"ok": True, "data": data})
    except Exception as e:
        return JSONResponse(status_code=500, content={"ok": False, "message": str(e)})

# --- Routes: AI ---
@app.api_route("/api/ai/status", methods=["GET", "HEAD"])
def get_ai_status():
    return JSONResponse(content={"ok": True, "model": ai_engine.model_version, "mode": "local_standalone"})

@app.post("/api/ai/analyze-market")
def trigger_market_analysis():
    res = ai_engine.run_inference()
    if res.get("ok"):
        strategy_mgr.record_signal(res)
    return JSONResponse(status_code=200 if res.get("ok") else 503, content=res)

# --- Routes: Strategy ---
@app.api_route("/api/strategy/history", methods=["GET", "HEAD"])
def get_strategy_history():
    history = strategy_mgr.get_recent_signals(limit=5)
    return JSONResponse(content={"ok": True, "strategy": strategy_mgr.active_strategy, "history": history})

# --- Frontend Mount & Root Handling ---
if os.path.exists(WWW_DIR):
    app.mount("/static", StaticFiles(directory=WWW_DIR), name="static")

    @app.api_route("/", methods=["GET", "HEAD"])
    def serve_root():
        index_path = os.path.join(WWW_DIR, "index.html")
        if os.path.exists(index_path):
            return FileResponse(index_path)
        return JSONResponse(status_code=404, content={"message": "Frontend index.html not found"})
APP_EOF

# Sync to all entrypoints
cp "$BACKEND_DIR/unified_app.py" "$BACKEND_DIR/main.py"
cp "$BACKEND_DIR/unified_app.py" "$BACKEND_DIR/app/main.py" 2>/dev/null || true

systemctl restart a1-agent.service
echo "Phase 20 Strategy Manager and Signal History deployed."
