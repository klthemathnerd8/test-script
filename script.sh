#!/bin/bash
#STARTUP
sudo apt update -y && sudo apt upgrade -y
sudo apt install ufw -y && sudo ufw enable


#USER MANAGEMENT (changes all passwords to Cyberpatriot1!)

# Prompt for administrators
read -p "Administrators (space-separated): " admin_input
IFS=' ' read -r -a admins <<< "$admin_input"

# Prompt for authorized users
read -p "Authorized Users (space-separated): " user_input
IFS=' ' read -r -a users <<< "$user_input"

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

#CRONTABS
echo "ALL" >> /etc/cron.deny

#.RC LOCAL
echo "exit 0" > /etc/rc.local

#HARDEN KERNEL
git clone https://github.com/klthemathnerd8/test-script
touch /etc/sysctl.conf.backup
cp /etc/sysctl.conf /etc/sysctl.conf.backup
cp ~/test-script/sysctl.conf /etc/sysctl.conf

#STOP SERVICES
badservices=(
  apache apache2 nginx openvpn ftp vsftpd
)
echo "Enter the required services (space-separated):"
read -r -a required_services

declare -A required_map
for services in "${required_services[@]}"; do
  required_map[$services]=1
done

for package in "${badservices[@]}"; do
  if [[ -z ${required_map[$package]} ]]; then
    echo "Removing $package..."
    sudo systemctl stop --purge -y "$package"
  else
    echo "Skipping $package (required)."
  fi
done



#REMOVE STUFF
naughty_list=(
  john nmap vuze frostwire kismet freeciv minetest minetest-server medusa hydra
  truecrack ophcrack nikto cryptcat nc netcat tightvncserver x11vnc nfs xinetd samba
  postgresql sftpd vsftpd apache apache2 ftp mysql php snmp pop3 icmp sendmail
  dovecot bind9 nginx telnet rlogind rshd rcmd rexecd rbootd rquotad rstatd rusersd
  rwalld rexd fingerd tftpd telnet snmp netcat nc
)
echo "Enter the required software (space-separated):"
read -r -a required_software

declare -A required_map
for software in "${required_software[@]}"; do
  required_map[$software]=1
done

for package in "${naughty_list[@]}"; do
  if [[ -z ${required_map[$package]} ]]; then
    echo "Removing $package..."
    sudo apt-get remove --purge -y "$package"
  else
    echo "Skipping $package (required)."
  fi
done

sudo apt-get autoremove -y
sudo apt-get autoclean

#FILE PERMS

chmod -R 640 /etc/passwd
chmod -R 640 /etc/group
chmod -R 640 /etc/shadow
chmod -R 640 /etc/sudoers
chmod -R 640 /var/www


#APACHE
echo "ServerSignature Off" | sudo tee -a /etc/apache2/apache2.conf
echo "ServerTokens Prod" | sudo tee -a /etc/apache2/apache2.conf

#SSH
echo "Protocol 2" | sudo tee -a /etc/ssh/sshd_config
echo "LogLevel VERBOSE" | sudo tee -a /etc/ssh/sshd_config
echo "X11Forwarding no" | sudo tee -a /etc/ssh/sshd_config
echo "MaxAuthTries 4" | sudo tee -a /etc/ssh/sshd_config
echo "IgnoreRhosts yes" | sudo tee -a /etc/ssh/sshd_config
echo "HostbasedAuthentication no" | sudo tee -a /etc/ssh/sshd_config
echo "PermitRootLogin no" | sudo tee -a /etc/ssh/sshd_config
echo "PermitEmptyPasswords no" | sudo tee -a /etc/ssh/sshd_config

#UNATTENDED UPGRADES
sudo apt install unattended-upgrades
sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
sudo tee -a /etc/apt/apt.conf.d/50auto-upgrades <<EOF
Unattended-Upgrade::Allowed-Origins {
	"\${distro_id} stable";
	"\${distro_id} \${distro_codename}-security";
	"\${distro_id} \${distro_codename}-updates";
};

Unattended-Upgrade::Package-Blacklist {
	"libproxy1v5";		# since the school filter blocks the word proxy
};
EOF

