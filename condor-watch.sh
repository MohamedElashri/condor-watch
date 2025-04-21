#!/usr/bin/env bash

set -euo pipefail

# Load config
CONFIG_FILE="$(dirname "$0")/condor-watch.conf"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[ERROR] Config file not found at $CONFIG_FILE"
    exit 1
fi
source "$CONFIG_FILE"

# Check required tools
if ! command -v condor_q >/dev/null 2>&1; then
    echo "[ERROR] condor_q not found in PATH"
    exit 1
fi

if ! command -v msmtp >/dev/null 2>&1; then
    echo "[ERROR] msmtp not found in PATH. Please install it and configure ~/.msmtprc"
    exit 1
fi

# Prepare dirs
mkdir -p "$STATE_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "$(date '+%F %T') - $1" >> "$LOG_FILE"
}

# Map numeric job status to human-readable names
status_name() {
    case "$1" in
        0) echo "Unexpanded" ;;
        1) echo "Idle" ;;
        2) echo "Running" ;;
        3) echo "Removed" ;;
        4) echo "Completed" ;;
        5) echo "Held" ;;
        6) echo "TransferringOutput" ;;
        7) echo "Suspended" ;;
        *) echo "Unknown" ;;
    esac
}

# Email notification function
send_email() {
    local subject="$1"
    local body="$2"
    echo "$body" | msmtp --subject="$subject" "$EMAIL_TO"
}

# Monitoring loop
for JOB_ID in $JOBS_TO_MONITOR; do
    STATE_FILE="${STATE_DIR}/${JOB_ID}.status"
    
    CURRENT_STATUS_CODE=$(condor_q "$JOB_ID" -format "%d\n" JobStatus 2>/dev/null || echo -1)
    CURRENT_STATUS=$(status_name "$CURRENT_STATUS_CODE")

    PREV_STATUS="Unknown"
    [[ -f "$STATE_FILE" ]] && PREV_STATUS=$(<"$STATE_FILE")

    if [[ "$CURRENT_STATUS" != "$PREV_STATUS" ]]; then
        echo "$CURRENT_STATUS" > "$STATE_FILE"
        MSG="HTCondor job $JOB_ID status changed: $PREV_STATUS → $CURRENT_STATUS"
        log "$MSG"

        if [[ "$EMAIL_ENABLED" == "true" && "$NOTIFY_LEVEL" == "status_change" ]]; then
            send_email "$EMAIL_SUBJECT_PREFIX Job $JOB_ID Status Update" "$MSG"
        fi
    else
        log "Job $JOB_ID status unchanged: $CURRENT_STATUS"
    fi
done
