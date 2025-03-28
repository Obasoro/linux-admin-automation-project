#!/bin/bash

# System Hardening Script
# Configures SSH securely, disables unnecessary services, updates packages, and implements security policies

# Configuration
SSH_PORT=22  # Change this to your preferred SSH port
LOG_FILE="/var/log/system_hardening.log"
UNWANTED_SERVICES=("ftp" "telnet" "rsh" "rlogin" "rexec" "nfs" "vnc" "snmp" "squid" "smb" "nmb" "ypserv" "ypbind" "tftp" "chargen" "daytime" "discard" "echo" "time" "talk" "ntalk" "sendmail" "identd" "rpcbind" "xinetd")

# Check root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Backup original files
backup_file() {
    if [ -f "$1" ]; then
        cp "$1" "$1.bak-$(date +%Y%m%d)"
        log "Backup created for $1"
    fi
}

# Update system packages
update_system() {
    log "Starting system update..."
    if [ -x "$(command -v apt-get)" ]; then
        apt-get update && apt-get upgrade -y
        apt-get autoremove -y
        apt-get autoclean
    elif [ -x "$(command -v yum)" ]; then
        yum update -y
        yum autoremove -y
    elif [ -x "$(command -v dnf)" ]; then
        dnf upgrade -y
        dnf autoremove -y
    else
        log "Package manager not found. Skipping updates."
        return 1
    fi
    log "System updated successfully"
}

# Configure SSH securely
secure_ssh() {
    log "Securing SSH configuration..."
    SSH_CONFIG="/etc/ssh/sshd_config"
    backup_file "$SSH_CONFIG"
    
    # Set secure SSH options
    sed -i "s/^#Port 22/Port $SSH_PORT/" "$SSH_CONFIG"
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
    sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
    sed -i 's/^#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$SSH_CONFIG"
    sed -i 's/^#UsePAM.*/UsePAM yes/' "$SSH_CONFIG"
    sed -i 's/^#ClientAliveInterval.*/ClientAliveInterval 300/' "$SSH_CONFIG"
    sed -i 's/^#ClientAliveCountMax.*/ClientAliveCountMax 2/' "$SSH_CONFIG"
    sed -i 's/^#MaxAuthTries.*/MaxAuthTries 3/' "$SSH_CONFIG"
    sed -i 's/^#LoginGraceTime.*/LoginGraceTime 60/' "$SSH_CONFIG"
    sed -i 's/^#AllowAgentForwarding.*/AllowAgentForwarding no/' "$SSH_CONFIG"
    sed -i 's/^#AllowTcpForwarding.*/AllowTcpForwarding no/' "$SSH_CONFIG"
    sed -i 's/^#X11Forwarding.*/X11Forwarding no/' "$SSH_CONFIG"
    sed -i 's/^#LogLevel.*/LogLevel VERBOSE/' "$SSH_CONFIG"
    
    # Restrict protocol to SSHv2
    echo "Protocol 2" >> "$SSH_CONFIG"
    
    # Configure allowed users (uncomment and add your users)
    # echo "AllowUsers your_username" >> "$SSH_CONFIG"
    
    systemctl restart sshd
    log "SSH secured. New port: $SSH_PORT. Root login and password authentication disabled."
}

# Disable unnecessary services
disable_services() {
    log "Disabling unnecessary services..."
    for service in "${UNWANTED_SERVICES[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            systemctl stop "$service"
            systemctl disable "$service"
            log "Disabled service: $service"
        fi
    done
    
    # Additional service cleanup
    if [ -x "$(command -v yum)" ] || [ -x "$(command -v dnf)" ]; then
        yum remove -y xinetd telnet-server rsh-server &>/dev/null
    fi
}

# Configure firewall
setup_firewall() {
    log "Configuring firewall..."
    if [ -x "$(command -v ufw)" ]; then
        ufw --force reset
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow "$SSH_PORT/tcp"
        ufw enable
    elif [ -x "$(command -v firewall-cmd)" ]; then
        firewall-cmd --permanent --remove-service=ssh
        firewall-cmd --permanent --add-port="$SSH_PORT/tcp"
        firewall-cmd --permanent --set-default-zone=drop
        firewall-cmd --reload
    elif [ -x "$(command -v iptables)" ]; then
        iptables -F
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT
        iptables -A INPUT -p tcp --dport "$SSH_PORT" -j ACCEPT
        iptables -A INPUT -i lo -j ACCEPT
        iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        iptables-save > /etc/iptables.rules
    fi
    log "Firewall configured"
}

# Set system-wide security policies
set_security_policies() {
    log "Setting security policies..."
    
    # Secure shared memory
    echo "tmpfs     /run/shm     tmpfs     defaults,noexec,nosuid     0     0" >> /etc/fstab
    
    # Set restrictive umask
    echo "umask 027" >> /etc/profile
    echo "umask 027" >> /etc/bashrc
    
    # Disable core dumps
    echo "* hard core 0" >> /etc/security/limits.conf
    echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf
    
    # Kernel hardening
    cat <<EOF >> /etc/sysctl.conf
# Prevent SYN flood attacks
net.ipv4.tcp_syncookies = 1
# Disable IP source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
# Enable IP spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
# Disable ICMP redirect acceptance
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
# Enable bad error message protection
net.ipv4.icmp_ignore_bogus_error_responses = 1
# Enable log martians
net.ipv4.conf.all.log_martians = 1
# Disable IPv6 if not needed
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
    
    sysctl -p
    
    # Secure cron
    chmod 600 /etc/crontab
    chmod 600 /etc/cron.hourly
    chmod 600 /etc/cron.daily
    chmod 600 /etc/cron.weekly
    chmod 600 /etc/cron.monthly
    chmod 600 /etc/cron.d
    
    log "Security policies applied"
}

# Main execution
log "Starting system hardening process..."

update_system
secure_ssh
disable_services
setup_firewall
set_security_policies

log "System hardening complete. Details logged to $LOG_FILE"
echo "System hardening complete. Please note:"
echo "1. SSH is now on port $SSH_PORT"
echo "2. Root login via SSH is disabled"
echo "3. Password authentication is disabled (use SSH keys)"
echo "4. Many unnecessary services have been disabled"
echo "5. Firewall rules have been applied"
echo "6. System-wide security policies are in place"
echo ""
echo "IMPORTANT: Before disconnecting, ensure you have:"
echo "1. SSH access configured with keys on port $SSH_PORT"
echo "2. Tested your connection in another session"
