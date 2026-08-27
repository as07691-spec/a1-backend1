from pathlib import Path
import re
import sys

app_file = Path("/opt/a1/backend/main.py")
content = app_file.read_text(encoding="utf-8")

if '@app.api_route("/api/ai/chat"' in content or '@app.post("/api/ai/chat"' in content:
    print("Route /api/ai/chat already exists. No change made.")
    sys.exit(0)

if "from fastapi import" not in content:
    print("ERROR: FastAPI import was not found in main.py")
    sys.exit(1)

if re.search(r"from fastapi import [^\n]*\bRequest\b", content) is None:
    content = re.sub(
        r"^(from fastapi import [^\n]+)$",
        lambda m: m.group(1) + ", Request",
        content,
        count=1,
        flags=re.MULTILINE,
    )

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
        f"تحلیل هوش مصنوعی A1 برای «{prompt}»: "
        "برای تصمیم معاملاتی، داده لحظه‌ای بازار، حجم معاملات، "
        "حد ضرر و نسبت ریسک به بازده را بررسی کنید."
    )

    return {
        "ok": True,
        "response": analysis,
        "model": "v1.0-local-hybrid",
    }
'''

app_file.write_text(content.rstrip() + route_code + "\n", encoding="utf-8")
print(f"Route added successfully to: {app_file}")
