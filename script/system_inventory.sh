#!/bin/bash

# System Inventory Script
# Collects hardware info, installed packages, running services
# Outputs formatted report

# Output file
REPORT_FILE="system_inventory_$(date +%Y%m%d_%H%M%S).txt"

# Header
echo "SYSTEM INVENTORY REPORT" > $REPORT_FILE
echo "Generated: $(date)" >> $REPORT_FILE
echo "======================================" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# 1. System Information
echo "SYSTEM INFORMATION" >> $REPORT_FILE
echo "------------------" >> $REPORT_FILE
echo "Hostname: $(hostname)" >> $REPORT_FILE
echo "OS: $(grep PRETTY_NAME /etc/os-release | cut -d '"' -f 2)" >> $REPORT_FILE
echo "Kernel: $(uname -r)" >> $REPORT_FILE
echo "Uptime: $(uptime -p)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# 2. CPU Information
echo "CPU INFORMATION" >> $REPORT_FILE
echo "---------------" >> $REPORT_FILE
echo "Model: $(grep "model name" /proc/cpuinfo | head -n 1 | cut -d ':' -f 2 | sed 's/^[ \t]*//')" >> $REPORT_FILE
echo "Cores: $(nproc)" >> $REPORT_FILE
echo "Threads per core: $(lscpu | grep "Thread(s) per core" | cut -d ':' -f 2 | tr -d ' ')" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# 3. Memory Information
echo "MEMORY INFORMATION" >> $REPORT_FILE
echo "------------------" >> $REPORT_FILE
free -h >> $REPORT_FILE
echo "" >> $REPORT_FILE

# 4. Disk Information
echo "DISK INFORMATION" >> $REPORT_FILE
echo "----------------" >> $REPORT_FILE
echo "Mount points:" >> $REPORT_FILE
df -h >> $REPORT_FILE
echo "" >> $REPORT_FILE
echo "Disk devices:" >> $REPORT_FILE
lsblk >> $REPORT_FILE
echo "" >> $REPORT_FILE

# 5. Installed Packages
echo "INSTALLED PACKAGES" >> $REPORT_FILE
echo "------------------" >> $REPORT_FILE
if [ -f /etc/debian_version ]; then
    echo "Debian/Ubuntu sys" >> $REPORT_FILE
    dpkg --get-selections | grep -v deinstall >> $REPORT_FILE
elif [ -f /etc/redhat-release ]; then
    echo "RHEL/CentOS system detected" >> $REPORT_FILE
    rpm -qa >> $REPORT_FILE
else
    echo "Unknown package manager" >> $REPORT_FILE
fi
echo "" >> $REPORT_FILE

# 6. Running Services
echo "RUNNING SERVICES" >> $REPORT_FILE
echo "----------------" >> $REPORT_FILE
if command -v systemctl &> /dev/null; then
    systemctl list-units --type=service --state=running >> $REPORT_FILE
elif command -v service &> /dev/null; then
    service --status-all | grep "+" >> $REPORT_FILE
else
    echo "Could not determine service manager" >> $REPORT_FILE
fi
echo "" >> $REPORT_FILE

# 7. Network Information
echo "NETWORK INFORMATION" >> $REPORT_FILE
echo "-------------------" >> $REPORT_FILE
ifconfig show >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Footer
echo "======================================" >> $REPORT_FILE
echo "End of report" >> $REPORT_FILE

echo "Inventory report generated: $REPORT_FILE"
