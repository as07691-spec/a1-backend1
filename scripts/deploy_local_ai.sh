#!/usr/bin/env bash
set -Eeuo pipefail

BACKEND_DIR="/opt/a1/backend"
AI_DIR="$BACKEND_DIR/ai_engine"
DATA_FILE="$BACKEND_DIR/data/market_snapshot.json"

echo "=== 1. DEPLOYING LOCAL AI CORE ENGINE ==="

cat << 'AI_CORE_EOF' > "$AI_DIR/engine.py"
import os
import json
import logging
from typing import Dict, Any

class LocalAIEngine:
    def __init__(self, data_path: str):
        self.data_path = data_path
        self.model_version = "v1.0-local-hybrid"

    def calculate_technical_indicators(self, data: Dict[str, Any]) -> Dict[str, Any]:
        net_val = data.get("net_value", 0)
        buying_power = data.get("buying_power", 0)
        
        # Risk assessment formula
        power_ratio = (buying_power / net_val) if net_val > 0 else 0
        risk_score = round(max(0.05, min(0.95, 1.0 - power_ratio)), 2)
        
        # Signal Generation Logic
        if risk_score > 0.70:
            signal = "SELL_RISK_OFF"
            decision = "ریسک بالا: کاهش حجم موقعیت‌ها و حفظ نقدینگی توصیه می‌شود."
        elif risk_score < 0.30:
            signal = "BUY_OPPORTUNITY"
            decision = "فرصت خرید: قدرت نقدینگی بالا و شرایط تعادلی مناسب ارزیابی شد."
        else:
            signal = "HOLD"
            decision = "وضعیت متعادل: نگهداری دارایی‌ها و پایش جریان معاملات بازار."

        return {
            "signal": signal,
            "risk_score": risk_score,
            "decision": decision,
            "power_ratio": round(power_ratio, 3)
        }

    def run_inference(self) -> Dict[str, Any]:
        if not os.path.exists(self.data_path):
            return {
                "ok": False,
                "status": "data_unavailable",
                "message": "Market snapshot file not found."
            }
        try:
            with open(self.data_path, "r", encoding="utf-8") as f:
                market_data = json.load(f)
            
            analysis = self.calculate_technical_indicators(market_data)
            
            return {
                "ok": True,
                "status": "processed",
                "model": self.model_version,
                "signal": analysis["signal"],
                "risk_score": analysis["risk_score"],
                "analysis": analysis["decision"],
                "metrics": {
                    "power_ratio": analysis["power_ratio"],
                    "timestamp": market_data.get("timestamp")
                }
            }
        except Exception as e:
            return {"ok": False, "status": "inference_error", "message": str(e)}

ai_engine = LocalAIEngine("/opt/a1/backend/data/market_snapshot.json")
AI_CORE_EOF

echo "=== 2. INTEGRATING WITH BACKEND APP ==="

cat << 'APP_EOF' > "$BACKEND_DIR/unified_app.py"
import os
import json
from fastapi import FastAPI
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from ai_engine.engine import ai_engine

DATA_FILE = "/opt/a1/backend/data/market_snapshot.json"
WWW_DIR = "/opt/a1/backend/www"

app = FastAPI(title="A1 Autonomous Trading Agent", version="0.18.0")

@app.get("/api/health")
def health_check():
    return {"status": "ok", "service": "A1-Agent", "ok": True}

@app.get("/api/market/snapshot")
def get_market_snapshot():
    if not os.path.exists(DATA_FILE):
        return JSONResponse(status_code=404, content={"ok": False, "message": "Market snapshot not found"})
    try:
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        return JSONResponse(status_code=200, content={"ok": True, "data": data})
    except Exception as e:
        return JSONResponse(status_code=500, content={"ok": False, "message": str(e)})

@app.get("/api/ai/status")
def get_ai_status():
    return JSONResponse(content={"ok": True, "model": ai_engine.model_version, "mode": "local_standalone"})

@app.post("/api/ai/analyze-market")
def trigger_market_analysis():
    res = ai_engine.run_inference()
    return JSONResponse(status_code=200 if res.get("ok") else 503, content=res)

if os.path.exists(WWW_DIR):
    app.mount("/static", StaticFiles(directory=WWW_DIR), name="static")

    @app.get("/")
    def serve_root():
        return FileResponse(os.path.join(WWW_DIR, "index.html"))
APP_EOF

cp "$BACKEND_DIR/unified_app.py" "$BACKEND_DIR/main.py"
cp "$BACKEND_DIR/unified_app.py" "$BACKEND_DIR/app/main.py" 2>/dev/null || true

systemctl restart a1-agent.service
echo "=== LOCAL AI PIPELINE SUCCESSFULLY DEPLOYED ==="
