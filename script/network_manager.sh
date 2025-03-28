#!/bin/bash

# Network Monitoring Script
# Monitors connections, logs anomalies, tests connectivity, and reports bandwidth

# Configuration
LOG_FILE="/var/log/network_monitor.log"
ALERT_THRESHOLD=50  # Number of connections to trigger alert
CHECK_INTERVAL=60   # Seconds between checks
KNOWN_SERVERS=("google.com" "8.8.8.8" "your-server.example.com")  # Add your servers
BANDWIDTH_INTERFACE="eth0"  # Change to your network interface
TOP_PROCESSES=5     # Number of top processes to show in bandwidth report

# Create log file if it doesn't exist
touch $LOG_FILE

# Log function with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Monitor active network connections
monitor_connections() {
    log "===== Active Network Connections ====="
    local suspicious_conn=$(netstat -tunap 2>/dev/null | grep -v "ESTABLISHED" | awk '$6 != "LISTEN" {print}')
    local total_conn=$(netstat -tunap 2>/dev/null | wc -l)
    
    # Log all connections if verbose (uncomment next line for debugging)
    # netstat -tunap | tee -a $LOG_FILE
    
    if [ -n "$suspicious_conn" ]; then
        log "Suspicious connections found:"
        echo "$suspicious_conn" | tee -a $LOG_FILE
    fi
    
    if [ $total_conn -gt $ALERT_THRESHOLD ]; then
        log "ALERT: High number of connections ($total_conn)" | tee -a $LOG_FILE
        log "Top connections:"
        netstat -tunap | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -n $TOP_PROCESSES | tee -a $LOG_FILE
    fi
}

# Test connectivity to important servers
test_connectivity() {
    log "===== Connectivity Tests ====="
    for server in "${KNOWN_SERVERS[@]}"; do
        if ping -c 2 -W 1 "$server" &>/dev/null; then
            log "Connection to $server: SUCCESS"
        else
            log "Connection to $server: FAILED" | tee -a $LOG_FILE
        fi
    done
}

# Monitor bandwidth usage
monitor_bandwidth() {
    log "===== Bandwidth Usage ====="
    
    # Get current RX/TX values
    local rx_bytes=$(cat /sys/class/net/$BANDWIDTH_INTERFACE/statistics/rx_bytes)
    local tx_bytes=$(cat /sys/class/net/$BANDWIDTH_INTERFACE/statistics/tx_bytes)
    
    # Calculate rates if we have previous values
    if [ -n "$last_rx_bytes" ]; then
        local rx_rate=$(( (rx_bytes - last_rx_bytes) / CHECK_INTERVAL ))
        local tx_rate=$(( (tx_bytes - last_tx_bytes) / CHECK_INTERVAL ))
        log "Download rate: $(($rx_rate / 1024)) KB/s, Upload rate: $(($tx_rate / 1024)) KB/s"
        
        # Check for high bandwidth usage
        if [ $rx_rate -gt $((1024 * 1024)) ] || [ $tx_rate -gt $((1024 * 1024)) ]; then
            log "ALERT: High bandwidth usage detected!" | tee -a $LOG_FILE
            log "Top bandwidth-consuming processes:"
            
            # Show top processes (requires nethogs or similar)
            if command -v nethogs &>/dev/null; then
                nethogs -c 2 -d 1 -v 2 | head -n $((TOP_PROCESSES + 2)) | tee -a $LOG_FILE
            else
                ss -t -p -H | awk '{print $1,$5,$7}' | sort | uniq -c | sort -nr | head -n $TOP_PROCESSES | tee -a $LOG_FILE
            fi
        fi
    fi
    
    # Store current values for next run
    last_rx_bytes=$rx_bytes
    last_tx_bytes=$tx_bytes
}

# Check for suspicious listening ports
check_listening_ports() {
    log "===== Listening Ports Check ====="
    local unusual_ports=$(netstat -tulnp | awk '$4 ~ /0.0.0.0/ && $1 != "tcp6" {print}')
    
    if [ -n "$unusual_ports" ]; then
        log "Unusual listening ports detected:"
        echo "$unusual_ports" | tee -a $LOG_FILE
    fi
}

# Main monitoring loop
log "Starting network monitoring..."
while true; do
    echo "" | tee -a $LOG_FILE
    log "===== New Monitoring Cycle ====="
    
    monitor_connections
    test_connectivity
    monitor_bandwidth
    check_listening_ports
    
    sleep $CHECK_INTERVAL
done
