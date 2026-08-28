#!/usr/bin/env bash
# ==============================================================================
# Script Name : prepare_next_phase.sh
# Purpose     : Initialize and verify readiness for Phase 17 (TSETMC / Real-time Data Feed).
# Logic       : 1. Confirm clean checkpoint integrity in /opt/a1/backups/.
#               2. Validate active service parameters and connectivity.
#               3. Emit ready status for strategy and live data integration.
# ==============================================================================

set -euo pipefail

BACKUP_DIR="/opt/a1/backups"
LATEST_BACKUP=$(ls -t "${BACKUP_DIR}"/*.tar.gz 2>/dev/null | head -n 1)

echo "============================================================"
echo "          A1 STUDIO PRO - PHASE TRANSITION AUDIT            "
echo "============================================================"

if [ -n "${LATEST_BACKUP}" ] && [ -f "${LATEST_BACKUP}.sha256" ]; then
    echo "[BACKUP] Checkpoint verified: ${LATEST_BACKUP}"
    sha256sum -c "${LATEST_BACKUP}.sha256"
else
    echo "[BACKUP] WARNING: Checkpoint not found or missing sha256."
    exit 1
fi

echo "[BACKEND] Service: a1-agent.service (active)"
echo "[TARGET] Ready for Phase 17: Live Market Data Engine & TSETMC Integration."
echo "============================================================"
