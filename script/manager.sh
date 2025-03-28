#!/bin/bash

# User Management Script
# Handles user creation, modification, deletion, SSH keys, password policies, and groups

# Configuration
PASSWORD_EXPIRE_DAYS=90
MIN_PASSWORD_DAYS=7
PASSWORD_WARN_DAYS=7
MIN_PASSWORD_LENGTH=12
LOG_FILE="/var/log/user_manager.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Check root privileges
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log "This script must be run as root"
        exit 1
    fi
}

# Password policy function
set_password_policy() {
    log "Setting password policies..."
    sed -i "s/^PASS_MAX_DAYS.*/PASS_MAX_DAYS    $PASSWORD_EXPIRE_DAYS/" /etc/login.defs
    sed -i "s/^PASS_MIN_DAYS.*/PASS_MIN_DAYS    $MIN_PASSWORD_DAYS/" /etc/login.defs
    sed -i "s/^PASS_WARN_AGE.*/PASS_WARN_AGE    $PASSWORD_WARN_DAYS/" /etc/login.defs
    sed -i "s/^minlen.*/minlen = $MIN_PASSWORD_LENGTH/" /etc/security/pwquality.conf
    log "Password policies updated"
}

# Create user function
create_user() {
    read -p "Enter username: " username
    if id "$username" &>/dev/null; then
        log "User $username already exists"
        return 1
    fi
    
    read -p "Enter full name: " fullname
    read -s -p "Enter password: " password
    echo
    
    useradd -m -c "$fullname" "$username" && \
    echo "$username:$password" | chpasswd
    
    if [ $? -eq 0 ]; then
        log "User $username created successfully"
        passwd -e "$username" >/dev/null  # Force password change on first login
        return 0
    else
        log "Failed to create user $username"
        return 1
    fi
}

# Modify user function
modify_user() {
    read -p "Enter username to modify: " username
    if ! id "$username" &>/dev/null; then
        log "User $username does not exist"
        return 1
    fi
    
    echo "1. Change password"
    echo "2. Change shell"
    echo "3. Change home directory"
    echo "4. Lock account"
    echo "5. Unlock account"
    read -p "Select option: " option
    
    case $option in
        1) 
            passwd "$username"
            log "Password changed for $username"
            ;;
        2)
            read -p "Enter new shell (e.g., /bin/bash): " newshell
            usermod -s "$newshell" "$username"
            log "Shell changed to $newshell for $username"
            ;;
        3)
            read -p "Enter new home directory: " newhome
            usermod -m -d "$newhome" "$username"
            log "Home directory changed to $newhome for $username"
            ;;
        4)
            usermod -L "$username"
            log "Account $username locked"
            ;;
        5)
            usermod -U "$username"
            log "Account $username unlocked"
            ;;
        *)
            log "Invalid option"
            return 1
            ;;
    esac
}

# Delete user function
delete_user() {
    read -p "Enter username to delete: " username
    if ! id "$username" &>/dev/null; then
        log "User $username does not exist"
        return 1
    fi
    
    read -p "Delete home directory and mail spool? [y/N]: " del_files
    read -p "Are you sure you want to delete $username? [y/N]: " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        if [ "$del_files" = "y" ] || [ "$del_files" = "Y" ]; then
            userdel -r "$username"
            log "User $username deleted with home directory"
        else
            userdel "$username"
            log "User $username deleted (files preserved)"
        fi
    else
        log "User deletion cancelled"
    fi
}

# Manage SSH keys
manage_ssh_keys() {
    read -p "Enter username: " username
    if ! id "$username" &>/dev/null; then
        log "User $username does not exist"
        return 1
    fi
    
    echo "1. Add SSH key"
    echo "2. Remove SSH key"
    read -p "Select option: " option
    
    case $option in
        1)
            read -p "Paste SSH public key: " sshkey
            mkdir -p "/home/$username/.ssh"
            echo "$sshkey" >> "/home/$username/.ssh/authorized_keys"
            chown -R "$username:$username" "/home/$username/.ssh"
            chmod 700 "/home/$username/.ssh"
            chmod 600 "/home/$username/.ssh/authorized_keys"
            log "SSH key added for $username"
            ;;
        2)
            if [ -f "/home/$username/.ssh/authorized_keys" ]; then
                echo "Current keys:"
                cat -n "/home/$username/.ssh/authorized_keys"
                read -p "Enter key number to remove: " keynum
                sed -i "${keynum}d" "/home/$username/.ssh/authorized_keys"
                log "SSH key removed for $username"
            else
                log "No SSH keys found for $username"
            fi
            ;;
        *)
            log "Invalid option"
            return 1
            ;;
    esac
}

# Group management
manage_groups() {
    echo "1. Create group"
    echo "2. Delete group"
    echo "3. Add user to group"
    echo "4. Remove user from group"
    read -p "Select option: " option
    
    case $option in
        1)
            read -p "Enter group name: " groupname
            groupadd "$groupname"
            log "Group $groupname created"
            ;;
        2)
            read -p "Enter group name to delete: " groupname
            groupdel "$groupname"
            log "Group $groupname deleted"
            ;;
        3)
            read -p "Enter username: " username
            read -p "Enter group name: " groupname
            usermod -aG "$groupname" "$username"
            log "User $username added to group $groupname"
            ;;
        4)
            read -p "Enter username: " username
            read -p "Enter group name: " groupname
            gpasswd -d "$username" "$groupname"
            log "User $username removed from group $groupname"
            ;;
        *)
            log "Invalid option"
            return 1
            ;;
    esac
}

# Main menu
main_menu() {
    echo ""
    echo "USER MANAGEMENT SYSTEM"
    echo "1. Create user"
    echo "2. Modify user"
    echo "3. Delete user"
    echo "4. Manage SSH keys"
    echo "5. Set password policies"
    echo "6. Manage groups"
    echo "7. Exit"
    echo ""
}

# Main execution
check_root
set_password_policy

while true; do
    main_menu
    read -p "Select option: " choice
    
    case $choice in
        1) create_user ;;
        2) modify_user ;;
        3) delete_user ;;
        4) manage_ssh_keys ;;
        5) set_password_policy ;;
        6) manage_groups ;;
        7) 
            log "Exiting user manager"
            exit 0
            ;;
        *)
            log "Invalid option"
            ;;
    esac
    
    read -p "Press Enter to continue..."
done
