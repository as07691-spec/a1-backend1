#!/usr/bin/env bash
# ==============================================================================
# Script Name : save_stage17_checkpoint.sh
# Purpose     : Create a full verified stage checkpoint for Phase 17 deployment.
# Logic       : 1. Ensure backup directory exists.
#               2. Archive /opt/a1/backend and /opt/a1/frontend states.
#               3. Calculate and display SHA256 checksum for audit and integrity.
# ==============================================================================
set -euo pipefail

readonly BACKUP_DIR="/opt/a1/backups"
readonly TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
readonly ARCHIVE_NAME="a1_phase17_verified_checkpoint_${TIMESTAMP}.tar.gz"

echo "Creating stage checkpoint archive in ${BACKUP_DIR}..."
mkdir -p "${BACKUP_DIR}"

tar -czf "${BACKUP_DIR}/${ARCHIVE_NAME}" \
    -C /opt/a1 backend frontend

echo "Generating SHA256 verification hash..."
sha256sum "${BACKUP_DIR}/${ARCHIVE_NAME}" > "${BACKUP_DIR}/${ARCHIVE_NAME}.sha256"

echo "============================================================"
echo "Checkpoint Created : ${BACKUP_DIR}/${ARCHIVE_NAME}"
echo "Checksum           : $(cat "${BACKUP_DIR}/${ARCHIVE_NAME}.sha256")"
echo "Status             : Phase 17 Baseline Successfully Frozen"
echo "============================================================"
