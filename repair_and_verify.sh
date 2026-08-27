#!/usr/bin/env bash
set -e

echo "==> [1/4] Checking current service error logs..."
journalctl -u a1-agent.service -n 15 --no-pager || true

echo "==> [2/4] Verifying Python code syntax in backend..."
python3 -m py_compile /opt/a1/backend/tsetmc_pipeline.py
python3 -m py_compile /opt/a1/backend/ai_engine.py

# Ensure unified_app.py imports Flask dependencies cleanly
python3 - << 'PY_FIX'
with open('/opt/a1/backend/unified_app.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Clean duplicate imports
cleaned_lines = []
seen_imports = set()
for line in lines:
    if line.startswith("from ai_engine import") or line.startswith("from tsetmc_pipeline import"):
        if line in seen_imports:
            continue
        seen_imports.add(line)
    cleaned_lines.append(line)

with open('/opt/a1/backend/unified_app.py', 'w', encoding='utf-8') as f:
    f.writelines(cleaned_lines)
PY_FIX

python3 -m py_compile /opt/a1/backend/unified_app.py
echo "[OK] Python syntax validated."

echo "==> [3/4] Restarting systemd service..."
systemctl restart a1-agent.service
sleep 2

echo "==> [4/4] Verifying dynamic AI responses..."
echo "--- Test 1: فولاد ---"
curl -s -X POST http://127.0.0.1:8000/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "وضعیت فولاد"}'

echo ""
echo "--- Test 2: شبندر ---"
curl -s -X POST http://127.0.0.1:8000/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "بررسی شبندر"}'

echo ""
echo "--- Service Status ---"
systemctl status a1-agent.service --no-pager | head -n 12
