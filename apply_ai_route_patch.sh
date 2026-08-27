#!/usr/bin/env bash
set -Eeuo pipefail

BACKEND_DIR="/opt/a1/backend"
MAIN_FILE="${BACKEND_DIR}/main.py"
CANDIDATE_FILE="${BACKEND_DIR}/main.py.ai_route_candidate"

if [ ! -f "${CANDIDATE_FILE}" ]; then
    echo "ERROR: Candidate file ${CANDIDATE_FILE} does not exist. Run prepare_ai_route_patch.sh first."
    exit 1
fi

echo "==> [1/3] Replacing main.py with validated candidate..."
mv -f "${CANDIDATE_FILE}" "${MAIN_FILE}"

echo "==> [2/3] Restarting a1-agent.service..."
systemctl restart a1-agent.service
sleep 2

echo "==> [3/3] Executing Verification Tests on /api/ai/chat..."
echo "--- Test 1: فولاد ---"
curl -s -X POST http://127.0.0.1:8000/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "تحلیل نماد فولاد"}'
echo -e "\n"

echo "--- Test 2: اهرم ---"
curl -s -X POST http://127.0.0.1:8000/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "بررسی وضعیت نماد اهرم"}'
echo -e "\n"

echo "--- Test 3: Generic / Help ---"
curl -s -X POST http://127.0.0.1:8000/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "راهنما"}'
echo -e "\n"
