#!/usr/bin/env bash
set -Eeuo pipefail

BACKEND_DIR="/opt/a1/backend"
TRADE_DIR="$BACKEND_DIR/trade"
DATA_DIR="$BACKEND_DIR/data"

# 1. Autonomous Order Executor Module
cat << 'EXEC_EOF' > "$TRADE_DIR/executor.py"
import os
import json
import time
from typing import Dict, Any

ORDERS_FILE = "/opt/a1/backend/data/orders_history.jsonl"

class TradeExecutor:
    def __init__(self):
        self.orders_file = ORDERS_FILE
        self.execution_mode = "PAPER_TRADING_SIMULATOR"

    def execute_order(self, symbol: str, side: str, volume: int, price: float) -> Dict[str, Any]:
        # Enforce execution safety
        if volume <= 0 or price <= 0:
            return {"ok": False, "reason": "INVALID_VOLUME_OR_PRICE"}

        order_record = {
            "order_id": f"ORD-{int(time.time()*1000)}",
            "timestamp": time.time(),
            "time_iso": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
            "symbol": symbol,
            "side": side.upper(),
            "volume": volume,
            "price": price,
            "total_value": volume * price,
            "status": "FILLED",
            "mode": self.execution_mode
        }

        try:
            with open(self.orders_file, "a", encoding="utf-8") as f:
                f.write(json.dumps(order_record, ensure_ascii=False) + "\n")
            return {"ok": True, "order": order_record}
        except Exception as e:
            return {"ok": False, "reason": str(e)}

    def get_order_history(self, limit: int = 10):
        if not os.path.exists(self.orders_file):
            return []
        try:
            with open(self.orders_file, "r", encoding="utf-8") as f:
                lines = f.readlines()
            return [json.loads(l.strip()) for l in lines if l.strip()][-limit:]
        except Exception:
            return []

trade_executor = TradeExecutor()
EXEC_EOF

# 2. Update Unified Application with Execution Endpoints
cat << 'APP_EOF' > "$BACKEND_DIR/unified_app.py"
import os
import json
from fastapi import FastAPI, Body
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from ai_engine.engine import ai_engine
from strategy.manager import strategy_mgr
from trade.executor import trade_executor

DATA_FILE = "/opt/a1/backend/data/market_snapshot.json"
WWW_DIR = "/opt/a1/backend/www"

app = FastAPI(title="A1 Autonomous Trading Agent", version="0.22.0")

# --- Routes: Health ---
@app.api_route("/api/health", methods=["GET", "HEAD"])
def health_check():
    return {"status": "ok", "service": "A1-Agent", "ok": True, "version": "0.22.0"}

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

# --- Routes: Trade Execution ---
@app.post("/api/trade/execute")
def execute_trade_order(payload: dict = Body(...)):
    symbol = payload.get("symbol", "FOLAD")
    side = payload.get("side", "BUY")
    volume = int(payload.get("volume", 1000))
    price = float(payload.get("price", 5000))
    
    result = trade_executor.execute_order(symbol, side, volume, price)
    return JSONResponse(status_code=200 if result.get("ok") else 400, content=result)

@app.api_route("/api/trade/orders", methods=["GET", "HEAD"])
def get_orders_list():
    orders = trade_executor.get_order_history(limit=10)
    return JSONResponse(content={"ok": True, "orders": orders})

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
echo "Phase 22 Trade Execution Engine Deployed."
