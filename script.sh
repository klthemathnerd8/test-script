#!/bin/bash
#STARTUP
sudo apt update -y && sudo apt upgrade -y
sudo apt install ufw -y && sudo ufw enable


#USER MANAGEMENT (changes all passwords to Cyberpatriot1!)


# Prompt for administrators
read -p "Administrators (comma-separated): " admin_input
IFS=',' read -r -a admins <<< "$admin_input"

# Prompt for authorized users
read -p "Authorized Users (comma-separated): " user_input
IFS=',' read -r -a users <<< "$user_input"

# Combine admin and user lists into one for reference
all_users=("${admins[@]}" "${users[@]}")

# Get the list of all regular users (UID >= 1000)
system_users=($(getent passwd | awk -F: '$3 >= 1000 {print $1}'))

# Remove users not in the allowed lists
for user in "${system_users[@]}"; do
    if [[ ! " ${all_users[@]} " =~ " ${user} " ]]; then
        echo "Removing user: $user"
        sudo userdel -r "$user"
    fi
done

# Set password for administrators and change privileges
for admin in "${admins[@]}"; do
    echo "Changing password for admin: $admin"
    echo "$admin:Cyberpatriot1!" | sudo chpasswd
    # Elevate privileges (make sure the admin group exists)
    sudo usermod -aG sudo "$admin"
done

# Remove admin privileges from authorized users
for user in "${users[@]}"; do
    echo "Removing admin privileges from user: $user"
    sudo deluser "$user" sudo 2>/dev/null
done

echo "Script execution completed."

#PASSWORD STUFF

MAX_DAYS=90
MIN_DAYS=7
WARN_DAYS=14

# Get a list of all regular users (UID >= 1000)
regular_users=($(getent passwd | awk -F: '$3 >= 1000 {print $1}'))

# Loop through each user and apply the settings
for user in "${regular_users[@]}"; do
    echo "Setting password expiration for user: $user"
    sudo chage -M "$MAX_DAYS" -m "$MIN_DAYS" -W "$WARN_DAYS" "$user"
done

echo "Password expiration settings updated for all regular users."


#DISABLE IPV4 FORWARDING
echo net.ipv4.ip_forward=0 >> /etc/sysctl.conf

#STOP SERVICES
sudo systemctl stop apache
sudo systemctl disable apache
sudo systemctl stop nginx
sudo systemctl disable nginx
sudo systemctl stop openvpn
sudo systemctl disable openvpn
sudo systemctl stop vsftpd
sudo systemctl disable vsftpd

#REMOVE STUFF
sudo apt remove john -y
sudo apt remove ophcrack -y
sudo apt remove deluge -y
sudo apt remove wireshark -y
sudo apt remove freeciv -y
sudo apt remove netcat -y
sudo apt remove hydra -y
sudo apt remove inkscape -y
sudo apt remove  -y

#FILE PERMS

chmod -R 640 /etc/passwd
chmod -R 640 /etc/group
chmod -R 640 /etc/shadow
chmod -R 640 /etc/sudoers
chmod -R 640 /var/www



