#!/usr/bin/env bash
set -Eeuo pipefail

BACKEND_DIR="/opt/a1/backend"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKEND_DIR}/backups/fix_${TIMESTAMP}"

mkdir -p "${BACKUP_DIR}"

echo "==> [1/4] Backing up relevant files to ${BACKUP_DIR}..."
cp -a "${BACKEND_DIR}/main.py" "${BACKUP_DIR}/" || true
if [ -f "${BACKEND_DIR}/ai_engine.py" ]; then
    mv "${BACKEND_DIR}/ai_engine.py" "${BACKUP_DIR}/ai_engine.py.shadow_backup"
    echo "[OK] Moved conflicting top-level ai_engine.py to backup."
fi

echo "==> [2/4] Verifying package structure in /opt/a1/backend/ai_engine/..."
if [ ! -f "${BACKEND_DIR}/ai_engine/__init__.py" ]; then
    touch "${BACKEND_DIR}/ai_engine/__init__.py"
    echo "[OK] Created __init__.py in ai_engine package directory."
fi

echo "==> [3/4] Validating syntax of main.py and ai_engine/engine.py..."
python3 -m py_compile "${BACKEND_DIR}/ai_engine/engine.py"
python3 -m py_compile "${BACKEND_DIR}/main.py"
echo "[OK] Syntax checks passed for FastAPI entry points."

echo "==> [4/4] Restarting systemd service..."
systemctl restart a1-agent.service
sleep 2

echo "==> Checking Service Status:"
systemctl status a1-agent.service --no-pager -l | head -n 15

echo ""
echo "==> Testing AI Chat Endpoint:"
curl -s -X POST http://127.0.0.1:8000/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "تحلیل نماد فولاد"}' || curl -s http://127.0.0.1:8000/docs
