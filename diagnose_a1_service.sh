#!/usr/bin/env bash
set -Eeuo pipefail

BACKEND_DIR="/opt/a1/backend"
REPORT_DIR="/opt/a1/diagnBACK"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="/opt/a1/backups/pre_repair_${STAMP}"
REPORT_FILE="${REPORT_DIR}/report_${STAMP}.txt"

mkdir -p "${REPORT_DIR}" "${BACKUP_DIR}"

exec > >(tee -a "${REPORT_FILE}") 2>&1

echo "A1 Agent Diagnostic Report"
echo "UTC: ${STAMP}"
echo

echo "== Service unit =="
systemctl cat a1-agent.service || true
echo

echo "== Service status =="
systemctl status a1-agent.service --no-pager -l || true
echo

echo "== Recent service logs =="
journalctl -u a1-agent.service -n 80 --no-pager || true
echo

echo "== Backend file list =="
find "${BACKEND_DIR}" -maxdepth 2 -type f -printf '%p\n' | sort
echo

echo "== Python syntax checks =="
for file in \
  "${BACKEND_DIR}/main.py" \
  "${BACKEND_DIR}/unified_app.py" \
  "${BACKEND_DIR}/ai_engine.py" \
  "${BACKEND_DIR}/tsetf "${file}"do
  if [ -f "${file}" ]; then
    echo "--- ${file}"
    python3 -m py_compile "${file}" || true
  fi
done
echo

echo "== Import references =="
grep -RInE \
  "ai_engine(\.engine)?|unified_app|main:|create_app|Flask|Quart|FastAPI" \
  "${BACKEND_DIR}" \
  --include='*.py' \
  --include='*.service' || true
echo

echo "== Route references =="
grep -RInE \
  "/api/ai/chat|def ai_chat|def api_ai_chat|@app\.(route|get|post)" \
  "${BACKEND_DIR}" \
  --include='*.py' || true
echo

echo "== Backup =="
for file in \
  "${BACKEND_DIR}/main.py" \
  "${BACKEND_DIR}/unified_app.py" \
  "${BACKEND_DIR}/ai_engine.py" \
  "${BACKEND_DIR}/tsetmc_pipeline.py"
do
  if [ -  fi
done

if [ -f -a "${file}" "${BACKUP_DIR}/"
  fi
done

if [ -f /etc/systemd/system/a1-agent.service ]; then
  cp -a /etc/systemd/system/a1-agent.service "${BACKUP_DIR}/"
fi

echo "Backup directory: ${BACKUP_DIR}"
echo "Diagnostic report: ${REPORT_FILE}"
echo
echo "No application file was modified."
echo "No service restart was performed."
