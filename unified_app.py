from ai_engine import ai_engine
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

    try:
        body = await request.json()
        prompt = body.get("message", "")
    except Exception:
        prompt = ""
    
    analysis = f"تحلیل دستیار هوش مصنوعی A1: بر اساس شرایط تابلو و استراتژی نوسان‌گیری، نمادهای پیشرو بازار دارای تحرکات مثبت هستند. در خصوص سوال '{prompt}' توصیه می‌شود حد ضرر را روی محدوده ۲.۵٪ تثبیت نمایید."
    return {"ok": True, "response": analysis, "model": "v1.0-local-hybrid"}


    try:
        body = await request.json()
        prompt = body.get("message", "")
    except Exception:
        prompt = ""

    analysis = f"تحلیل هوش مصنوعی A1: برای پرسش '{prompt}'، نمادهای شاخص در کانال صعودی تثبیت شده‌اند و استراتژی نوسان‌گیری با مدیریت ریسک ۲۵٪ فعال است."
    return {"ok": True, "response": analysis, "model": "v1.0-local-hybrid"}


    try:
        body = await request.json()
        prompt = body.get("message", "")
    except Exception:
        prompt = ""

    analysis = f"تحلیل هوش مصنوعی A1: برای پرسش '{prompt}'، نمادهای شاخص در کانال صعودی تثبیت شده‌اند و استراتژی نوسان‌گیری با مدیریت ریسک ۲۵٪ فعال است."
    return {"ok": True, "response": analysis, "model": "v1.0-local-hybrid"}


@app.api_route("/api/ai/chat", methods=["GET", "POST", "HEAD"])
async def ai_chat_handler(request: Request):
    if request.method in ["GET", "HEAD"]:
        return {"ok": True, "status": "AI Chat Engine Active", "model": "v1.0-local-hybrid"}
    try:
        body = await request.json()
        prompt = body.get("message", "")
    except Exception:
        prompt = ""
    
    analysis = f"تحلیل هوش مصنوعی A1: در پاسخ به '{prompt}'، وضعیت شاخص در مدار تعادلی قرار دارد و سطوح حمایتی برای نمادهای فعال حفظ شده است."
    return {"ok": True, "response": analysis, "model": "v1.0-local-hybrid"}


@app.route('/api/ai/chat', methods=['GET', 'POST'])
def api_ai_chat():
    if request.method == 'POST':
        data = request.get_json(silent=True) or {}
        query = data.get("message", "").strip()
    else:
        query = request.args.get("message", "").strip()
    
    if not query:
        query = "وضعیت"
    
    reply = ai_engine.analyze(query)
    extracted = ai_engine.extract_symbol(query)
    return jsonify({"ok": True, "reply": reply, "symbol": extracted})
