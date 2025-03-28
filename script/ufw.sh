# Allow SSH
sudo ufw allow ssh
# Or specify port explicitly
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow specific port ranges
sudo ufw allow 6000:6007/tcp

# Allow from specific IP
sudo ufw allow from 192.168.1.100

# Allow specific service from specific IP
sudo ufw allow from 192.168.1.100 to any port 22

# Delete a rule
sudo ufw delete allow 80/tcp

# Check current rules
sudo ufw status verbose
