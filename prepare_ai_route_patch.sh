#!/usr/bin/env bash
set -Eeuo pipefail

BACKEND_DIR="/opt/a1/backend"
MAIN_FILE="${BACKEND_DIR}/main.py"
CANDIDATE_FILE="${BACKEND_DIR}/main.py.ai_route_candidate"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="${BACKEND_DIR}/backups/pre_ai_route_${STAMP}"

mkdir -p "${BACKUP_DIR}"

echo "==> [1/4] Creating backup..."
cp -a "${MAIN_FILE}" "${BACKUP_DIR}/main.py"

echo "==> [2/4] Generating candidate patch..."
python3 - "${MAIN_FILE}" "${CANDIDATE_FILE}" << 'PY'
import sys
from pathlib import Path

source_path = Path(sys.argv[1])
candidate_path = Path(sys.argv[2])

text = source_path.read_text(encoding="utf-8")

old_block = '''    analysis = (
        f"تحلیل هوش مصنوعی A1 برای «{prompt}»: "
        "برای تصمیم معاملاتی، داده لحظه‌ای بازار، حجم معاملات، "
        "حد ضرر و نسبت ریسک به بازده را بررسی کنید."
    )

    return {
        "ok": True,
        "response": analysis,
        "model": "v1.0-local-hybrid",
    }'''

new_block = '''    result = ai_engine.analyze(prompt)

    if not isinstance(result, dict):
        result = {
            "ok": True,
            "response": str(result),
            "model": "v1.0-local-hybrid",
        }

    result.setdefault("ok", True)
    result.setdefault("model", "v1.0-local-hybrid")
    result.setdefault("symbol", ai_engine.extract_symbol(prompt))
    return result'''

if old_block not in text:
    print("ERROR: Target block not found in main.py", file=sys.stderr)
    sys.exit(1)

patched_text = text.replace(old_block, new_block, 1)
candidate_path.write_text(patched_text, encoding="utf-8")
print(f"[OK] Candidate created: {candidate_path}")
PY

echo "==> [3/4] Validating candidate syntax..."
python3 -m py_compile "${CANDIDATE_FILE}"
echo "[OK] Python syntax validation passed."

echo "==> [4/4] Generating diff..."
echo "--------------------------------------------------------"
diff -u "${MAIN_FILE}" "${CANDIDATE_FILE}" || true
echo "--------------------------------------------------------"
echo "Candidate file ready at: ${CANDIDATE_FILE}"
echo "No changes applied to active service."
