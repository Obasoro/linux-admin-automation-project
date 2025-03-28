#!/bin/bash
# Unified logging framework for all maintenance scripts

LOG_DIR="/var/log/maintenance"
mkdir -p "$LOG_DIR"

# Log levels
declare -A LOG_LEVELS=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3 [CRITICAL]=4)
DEFAULT_LOGLEVEL="INFO"

# Initialize logging
setup_logging() {
    local script_name=$(basename "$0")
    LOG_FILE="$LOG_DIR/${script_name}.log"
    touch "$LOG_FILE"
}

# Core logging function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    
    # Check if level exists and is at least default level
    if [[ -z "${LOG_LEVELS[$level]}" ]] || \
       [[ "${LOG_LEVELS[$level]}" -lt "${LOG_LEVELS[$DEFAULT_LOGLEVEL]}" ]]; then
        return
    fi

    # Log to file
    echo "[$timestamp] [$level] [$(basename "$0")] $message" >> "$LOG_FILE"
    
    # Critical events trigger email
    if [[ "$level" == "CRITICAL" ]] && [[ -n "$ALERT_EMAIL" ]]; then
        echo "[$timestamp] CRITICAL: $message" | mailx -s "ALERT: $script_name failure" "$ALERT_EMAIL"
    fi
}
