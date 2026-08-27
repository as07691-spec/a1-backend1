#!/usr/bin/env bash
set -e

python3 - << 'PY_FIX'
import re

app_path = '/opt/a1/backend/unified_app.py'

with open(app_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Make sure imports are present
if "from ai_engine import ai_engine" not in code:
    code = "from ai_engine import ai_engine\n" + code

# Cleanly define /api/ai/chat route
chat_route_code = '''
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
'''

# Remove any previous definitions of api_ai_chat or /api/ai/chat
code = re.sub(r"@app\.route\(['\"]/api/ai/chat['\"][^)]*\)\s*def\s+[a-zA-Z0-9_]+\(\):[\s\S]*?(?=\n@app|\nif __name__|$)", "", code)

# Append clean route before main block
if "if __name__" in code:
    code = code.replace("if __name__", chat_route_code + "\nif __name__")
else:
    code += "\n" + chat_route_code

with open(app_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("[OK] /api/ai/chat route successfully mounted in unified_app.py")
PY_FIX

echo "==> Restarting service..."
systemctl restart a1-agent.service
sleep 1.5

echo "==> Testing AI Chat Endpoint with 'فولاد':"
curl -s -X POST http://127.0.0.1:8000/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "بررسی نماد فولاد"}' | jq . || curl -s -X POST http://127.0.0.1:8000/api/ai/chat -H "Content-Type: application/json" -d '{"message": "بررسی نماد فولاد"}'

echo ""
echo "==> Testing AI Chat Endpoint with 'شبندر':"
curl -s -X POST http://127.0.0.1:8000/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "تحلیل تکنیکال شبندر"}' | jq . || curl -s -X POST http://127.0.0.1:8000/api/ai/chat -H "Content-Type: application/json" -d '{"message": "تحلیل تکنیکال شبندر"}'

echo ""
echo "==> Status Check:"
systemctl is-active a1-agent.service
