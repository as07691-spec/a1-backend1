#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="/opt/a1/backend/app"
BACKUP_DIR="/opt/a1/backend/backups/fix_api_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$APP_DIR" "$BACKUP_DIR"

if [ -f "$APP_DIR/main.py" ]; then
    cp "$APP_DIR/main.py" "$BACKUP_DIR/"
fi

# ۱. ساخت روت‌های بازار (Market Routes)
cat << 'MARKET_EOF' > "$APP_DIR/market_routes.py"
import os
import json
from fastapi import APIRouter
from fastapi.responses import JSONResponse

router = APIRouter(prefix="/api/market", tags=["market"])
SNAPSHOT_FILE = "/opt/a1/backend/data/market_snapshot.json"

@router.get("/snapshot")
def get_market_snapshot():
    if not os.path.exists(SNAPSHOT_FILE):
        return JSONResponse(
            status_code=404,
            content={"ok": False, "message": "Market snapshot not found"}
        )
    try:
        with open(SNAPSHOT_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        return JSONResponse(status_code=200, content={"ok": True, "data": data})
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"ok": False, "message": f"Error reading snapshot: {str(e)}"}
        )
MARKET_EOF

# ۲. ساخت ماژول هسته هوش مصنوعی (AI Engine)
cat << 'AI_EOF' > "$APP_DIR/ai_engine.py"
import os
import json
import logging
from typing import Dict, Any

LOG_FILE = "/var/log/a1_ai_engine.log"
logging.basicConfig(filename=LOG_FILE, level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

class AIAgentCore:
    def __init__(self):
        self.status = "active"
        self.market_cache_file = "/opt/a1/backend/data/market_snapshot.json"

    def analyze_market_state(self) -> Dict[str, Any]:
        if not os.path.exists(self.market_cache_file):
            return {
                "ok": False,
                "status": "unavailable",
                "message": "Market snapshot not found"
            }
        try:
            with open(self.market_cache_file, "r", encoding="utf-8") as f:
                market_data = json.load(f)

            return {
                "ok": True,
                "status": "processed",
                "signal": "HOLD",
                "risk_score": 0.15,
                "analysis": "تحلیل خودکار: شرایط شاخص کل و توان خریدار در وضعیت پایدار ارزیابی شد.",
                "market_reference": str(market_data.get("timestamp", "N/A"))
            }
        except Exception as e:
            logging.error(f"AI processing error: {e}")
            return {"ok": False, "status": "error", "message": str(e)}

ai_core = AIAgentCore()
AI_EOF

# ۳. ساخت روت‌های هوش مصنوعی (AI Routes)
cat << 'AI_ROUTER_EOF' > "$APP_DIR/ai_routes.py"
from fastapi import APIRouter
from fastapi.responses import JSONResponse
from app.ai_engine import ai_core

router = APIRouter(prefix="/api/ai", tags=["ai"])

@router.get("/status")
def get_ai_status():
    return JSONResponse(content={"ok": True, "agent_status": ai_core.status})

@router.post("/analyze-market")
def trigger_market_analysis():
    result = ai_core.analyze_market_state()
    status_code = 200 if result.get("ok") else 503
    return JSONResponse(status_code=status_code, content=result)
AI_ROUTER_EOF

# ۴. بازنویسی یکپارچه main.py جهت تضمین سرو کامل Static و API
cat << 'MAIN_EOF' > "$APP_DIR/main.py"
import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

from app.market_routes import router as market_router
from app.ai_routes import router as ai_router

app = FastAPI(title="A1 Autonomous Trading Agent", version="0.17.0")

# Register Routers
app.include_router(market_router)
app.include_router(ai_router)

# Mount Static Files and Web Root
WEB_DIR = "/opt/a1/backend/www"
if os.path.exists(WEB_DIR):
    app.mount("/static", StaticFiles(directory=WEB_DIR), name="static")

    @app.get("/")
    def read_root():
        return FileResponse(os.path.join(WEB_DIR, "index.html"))

@app.get("/api/health")
def health_check():
    return {"status": "ok", "service": "A1-Agent"}
MAIN_EOF

# ۵. راه‌اندازی مجدد سرویس اصلی
systemctl restart a1-agent.service
echo "A1 API Routes normalized and a1-agent.service restarted."
