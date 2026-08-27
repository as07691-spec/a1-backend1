#!/usr/bin/env bash
set -Eeuo pipefail

BACKEND_DIR="/opt/a1/backend"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
REPORT_DIR="/opt/a1/diagnostics"
REPORT_FILE="${REPORT_DIR}/active_route_${STAMP}.txt"

mkdir -p "${REPORT_DIR}"

exec > >(tee "${REPORT_FILE}") 2>&1

echo "A1 Active Route Inspection"
echo "UTC: ${STAMP}"
echo

echo "== Service command =="
systemctl show a1-agent.service \
  -p WorkingDirectory \
  -p ExecStart \
  -p Environment \
  --no-pager
echo

echo "== Main file: numbered source =="
nl -ba "${BACKEND_DIR}/main.py"
echo

echo "== AI package files =="
find "${BACKEND_DIR}/ai_engine" -maxdepth 2 -type f -print -exec sh -c '
  echo "--- $1"
  nl -ba "$1"
' sh {} \;
echo

echo "== API route references =="
grep -RInE \
  "api/ai/chat|ai_chat|chat|response|engine\.analyze|ai_engine" \
  "${BACKEND_DIR}/main.py" \
  "${BACKEND_DIR}/api_router.py" \
  "${BACKEND_DIR}/agent_router.py" \
  "${BACKEND_DIR}/ai_engine" \
  --include='*.py' || true
echo

echo "== Import test =="
cd "${BACKEND_DIR}"
python3 - <<'PY'
import importlib
import inspect

print("Importing main...")
main = importlib.import_module("main")
print("main.app:", type(getattr(main, "app", None)))

print()
print("Main symbols:")
for name in sorted(dir(main)):
    if "chat" in name.lower() or "ai" in name.lower() or name == "app":
        value = getattr(main, name)
        print(name, type(value).__name__)

print()
print("FastAPI routes:")
app = getattr(main, "app", None)
if app is not None and hasattr(app, "routes"):
    for route in app.routes:
        methods = getattr(route, "methods", None)
        path = getattr(route, "path", None)
        endpoint = getattr(route, "endpoint", None)
        if path:
            print(
                path,
                sorted(methods) if methods else "",
                getattr(endpoint, "__name__", repr(endpoint))
            )
PY

echo
echo "Report file: ${REPORT_FILE}"
echo "No application file was modified."
echo "No service restart was performed."
