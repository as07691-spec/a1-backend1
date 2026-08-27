from pathlib import Path

app_file = Path("/opt/a1/backend/unified_app.py")
content = app_file.read_text(encoding="utf-8")

route_marker = '@app.api_route("/api/ai/chat"'

if route_marker in content:
    print("Route already exists. No change made.")
    raise SystemExit(0)

route_code = r'''

@app.api_route("/api/ai/chat", methods=["GET", "POST", "HEAD"])
async def ai_chat_handler(request: Request):
    if request.method in ("GET", "HEAD"):
        return {
            "ok": True,
            "status": "AI Chat Assistant Ready",
            "model": "v1.0-local-hybrid",
        }

    try:
        body = await request.json()
    except Exception:
        body = {}

    prompt = str(body.get("message", "")).strip()

    if not prompt:
        return {
            "ok": False,
            "error": "message is required",
            "model": "v1.0-local-hybrid",
        }

    analysis = (
        f"تحلیل هوش مصنوعی A1: برای پرسش «{prompt}»، "
        "مدیریت ریسک، تعیین حد ضرر و بررسی داده‌های لحظه‌ای بازار ضروری است."
    )

    return {
        "ok": True,
        "response": analysis,
        "model": "v1.0-local-hybrid",
    }
'''

content += route_code
app_file.write_text(content, encoding="utf-8")

print("Route added safely:", app_file)
