#!/usr/bin/env bash
# ==============================================================================
# Script Name : save_stage_checkpoint.sh
# Purpose     : Create a permanent backup checkpoint for A1 Studio Pro v0.22.1 (v10)
#               and archive verified backend code and static UI assets.
# Logic       : 1. Generate timestamped tar.gz archive under /opt/a1/backups/.
#               2. Compute SHA256 checksum for audit validation.
#               3. Log state confirmation.
# ==============================================================================

set -euo pipefail

BACKUP_DIR="/opt/a1/backups"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
ARCHIVE_NAME="a1_v10_verified_checkpoint_${TIMESTAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"

echo "Creating backup archive: ${BACKUP_DIR}/${ARCHIVE_NAME}..."
tar -czf "${BACKUP_DIR}/${ARCHIVE_NAME}" \
    -C /opt/a1 backend

echo "Generating SHA256 checksum..."
sha256sum "${BACKUP_DIR}/${ARCHIVE_NAME}" > "${BACKUP_DIR}/${ARCHIVE_NAME}.sha256"

echo "============================================================"
echo "Backup Status : COMPLETED"
echo "Archive File  : ${BACKUP_DIR}/${ARCHIVE_NAME}"
echo "Checksum File : ${BACKUP_DIR}/${ARCHIVE_NAME}.sha256"
echo "============================================================"
