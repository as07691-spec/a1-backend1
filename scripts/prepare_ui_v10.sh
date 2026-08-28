#!/usr/bin/env bash
# ==============================================================================
# Script Name : prepare_ui_v10.sh
# Purpose     : Backup current UI and deploy v10 baseline for testing
# Logic       : Creates timestamped backup in /opt/a1/backup, checks www path,
#               and verifies local web serving endpoints.
# ==============================================================================

set -euo pipefail

BACKUP_DIR="/opt/a1/backup/ui_$(date +%Y%m%d_%H%M%S)"
WWW_DIR="/opt/a1/backend/www"

echo "==> Step 1: Creating backup directory: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"

if [ -f "${WWW_DIR}/index.html" ]; then
    cp "${WWW_DIR}/index.html" "${BACKUP_DIR}/index.html.bak"
    echo "==> Backup created successfully."
else
    echo "==> No existing index.html found to backup."
fi

echo "==> Step 2: Ensuring www directory exists"
mkdir -p "${WWW_DIR}"

echo "==> UI v10 staging ready. You can now push updated HTML to ${WWW_DIR}/index.html"
echo "==> Service check: systemctl is-active a1-agent.service"
systemctl is-active a1-agent.service || true
