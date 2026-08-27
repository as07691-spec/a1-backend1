#!/usr/bin/env bash
set -Eeuo pipefail

BACKEND_DIR="/opt/a1/backend"
DATA_FILE="$BACKEND_DIR/data/market_snapshot.json"
WWW_DIR="$BACKEND_DIR/www"

cat << 'APP_EOF' > "$BACKEND_DIR/unified_app.py"
import os
import json
from fastapi import FastAPI
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from ai_engine.engine import ai_engine

DATA_FILE = "/opt/a1/backend/data/market_snapshot.json"
WWW_DIR = "/opt/a1/backend/www"

app = FastAPI(title="A1 Autonomous Trading Agent", version="0.19.1")

# --- Routes: Health ---
@app.api_route("/api/health", methods=["GET", "HEAD"])
def health_check():
    return {"status": "ok", "service": "A1-Agent", "ok": True}

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
    return JSONResponse(status_code=200 if res.get("ok") else 503, content=res)

# --- Frontend Mount & Root Handling (GET + HEAD support) ---
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
echo "Unified App updated with GET/HEAD compliance and restarted."
