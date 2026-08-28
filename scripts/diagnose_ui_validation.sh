#!/usr/bin/env bash
# ==============================================================================
# Script Name : diagnose_ui_validation.sh
# Purpose     : Diagnose why verify_ui_full.sh stops during TEST 1/4.
# Logic       : Collect script content, service state, recent logs, listening
#               ports, and direct HTTP responses without : The system.
# Reason      : The previous validation stopped before printing the result.
#               Diagnosis must be completed before applying another fix.
# ==============================================================================

set -u

readonly VERIFY_SCRIPT="/opt/a1/backend/scripts/verify_ui_full.sh"
readonly SERVICE_NAME="a1-agent.service"
readonly BASE_URL="http://127.0.0.1:8000"
readonly REPORT_DIR="/opt/a1/backend/diagnostics"
readonly REPORT_FILE="${REPORT_DIR}/validation_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "${REPORT_DIR}"

exec > >(tee -a "${REPORT_FILE}") 2>&1

echo "============================================================"
echo "A1 UI VALIDATION DIAGNOSTIC REPORT"
echo "============================================================"
echo "Timestamp: $(date --iso-8601=seconds)"
-8601=seconds)"
 1. Verification script metadata"
if [ -f "${VERIFY_SCRIPT}" ]; then
    ls -l "${VERIFY_SCRIPT}"
    file "${VERIFY_SCRIPT}"
else
    echo "ERROR: Verification script does not exist: ${VERIFY_SCRIPT}"
fi
echo

echo "==> 2. Verification script content"
if [ -f "${VERIFY_SCRIPT}" ]; then
    nl -ba "${VERIFY_SCRIPT}"
else
    echo "SKIPPED"
fi
echo

echo "==> 3. Service status"
systemctl --no-pager --full status "${SERVICE_NAME}" || true
echo

echo "==> 4. Service enablement and process information"
systemctl is-active "${SERVICE_NAME}" || true
systemctl is-enabled "${SERVICE_NAME}" || true
systemctl show "${SERVICE_NAME}" \
    --property=ActiveState \
    --property=SubState \
    --property=MainPID \
    --property=ExecMainStatus \
    --property=FragmentPath || true
echo

echo "==> 5. Recent service logs"
journalctl -u "${SERVICE_NAME}" -n 100 --no-pager || true
echo

echo "==> 6. Listening sockets on port 8000"
ss -ltnp | grep -E '(:8000[[:space:]]|:8000$)' || true
echo

echo "==> 7. UI file status"
ls -la /opt/a1/backend/www/ 2>&1 || true
if [ -f /opt/a1/backend/www/index.html ]; then
    wc -c /opt/a1/backend/www/index.html
    sha256sum /opt/a1/backend/www/index.html
fi
echo

echo "==> 8. Direct UI request"
curl --silent --show-error \
    --connect-timeout 5 \
    --max-time 15 \
    --output /tmp/a1_ui_response.html \
    --write-out 'HTTP_STATUS=%{http_code}\nCONTENT_TYPE=%{content_type}\nSIZE=%{size_download}\n' \
    "${BASE_URL}/" || true

if [ -f /tmp/a1_ui_response.html ]; then
    echo "Response preview:"
    head -c 500 /tmp/a1_ui_response.html
    echo
fi
echo

echo "==> 9. FastAPI OpenAPI availability"
curl --silent --show-error \
    --connect-timeout 5 \
    --max-time 15 \
    --output /tmp/a1_openapi.json \
    --write-out 'HTTP_STATUS=%{http_code}\nSIZE=%{size_download}\n' \
    "${10. Required route checks"
for endpoint in \
   

echo "==> 10. Required route checks"
for endpoint in \
    "/api/ai/infer" \
    "/api/strategy/evaluate" \
    "/api/trade/order" \
    "/api/trade/killswitch"
do
    echo "--- ${endpoint}"
    curl --silent --show-error \
        --connect-timeout 5 \
        --max-time 15 \
        -X POST \
        -H 'Content-Type: application/json' \
        --data '{"symbol":"FOOLAD","strategy":"MOMENTUM_LOCAL_V1","qty":1,"side":"BUY"}' \
        --write-out '\nHTTP_STATUS=%{http_code}\n' \
        "${BASE_URL}${endpoint}" || true
done
echo

 syntax check"
python311. Python syntax check"
python3 -m py_compile /opt/a1/backend/app/main.py
PYTHON_STATUS=$?
echo "PYTHON_COMPILE_STATUS=${PYTHON_STATUS}"
echo

echo "============================================================"
echo "Diagnostic report saved at:"
echo "${REPORT_FILE}"
echo "============================================================"
