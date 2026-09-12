#!/bin/bash

# Function to display an error message and exit
error_exit() {
    echo
    echo "*********************************************"
    echo "Error: $1"
    echo "*********************************************"
    echo
    exit 1
}

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    error_exit "This script must be run as root. Please use sudo."
fi

# Prompt user for their Debian-based distribution
echo
echo "*********************************************"
echo "Welcome to the XRDP setup script for Debian-based systems."
echo "*********************************************"
echo
echo "Please enter the number corresponding to your Debian-based distribution:"
echo "1. Ubuntu Desktop"
echo "2. Kali Linux"
echo "3. Debian"
echo "4. Linux Mint"
echo "5. Elementary OS"
echo "6. Zorin OS"
echo "7. MX Linux"
echo "8. Parrot OS"
echo
read -p "Enter your choice (1/2/3/4/5/6/7/8): " distro_choice

case $distro_choice in
    1) distro_name="Ubuntu Desktop"; desktop_env="xfce4";;
    2) distro_name="Kali Linux"; desktop_env="kali-desktop-xfce";;
    3) distro_name="Debian"; desktop_env="xfce4";;
    4) distro_name="Linux Mint"; desktop_env="xfce4";;
    5) distro_name="Elementary OS"; desktop_env="xfce4";;
    6) distro_name="Zorin OS"; desktop_env="xfce4";;
    7) distro_name="MX Linux"; desktop_env="xfce4";;
    8) distro_name="Parrot OS"; desktop_env="parrot-xfce";;
    *) error_exit "Invalid choice. Please run the script again and enter a valid option.";;
esac

echo
echo "You have chosen: $distro_name"
echo

# Update the system
echo
echo "*********************************************"
echo "Step 1: Updating system..."
echo "*********************************************"
echo
apt update && apt upgrade -y || error_exit "Failed to update the system."

# Install XRDP
echo
echo "*********************************************"
echo "Step 2: Installing XRDP..."
echo "*********************************************"
echo
apt install xrdp -y || error_exit "Failed to install XRDP."

# Install and configure OpenSSH Server (SSH on TCP port 22)
echo
echo "*********************************************"
echo "Step 2b: Installing and configuring SSH..."
echo "*********************************************"
echo
apt install openssh-server -y || error_exit "Failed to install OpenSSH server."

# Ensure SSH listens on the standard port 22.
if [ -f /etc/ssh/sshd_config ]; then
    if grep -Eq '^[[:space:]]*#?[[:space:]]*Port[[:space:]]+' /etc/ssh/sshd_config; then
        sed -i -E 's/^[[:space:]]*#?[[:space:]]*Port[[:space:]]+.*/Port 22/' /etc/ssh/sshd_config
    else
        printf '\nPort 22\n' >> /etc/ssh/sshd_config
    fi
fi

# Validate configuration before restarting SSH.
sshd -t || error_exit "Invalid SSH configuration."
systemctl enable ssh || error_exit "Failed to enable SSH service."
systemctl restart ssh || error_exit "Failed to start/restart SSH service."

# Install the appropriate Desktop Environment
echo
echo "*********************************************"
echo "Step 3: Installing Desktop Environment..."
echo "*********************************************"
echo
if ! dpkg -l | grep -q xfce4; then
    apt install $desktop_env -y || error_exit "Failed to install $desktop_env."
else
    echo "XFCE Desktop Environment is already installed."
fi

# Configure XRDP to use XFCE
echo
echo "*********************************************"
echo "Step 4: Configuring XRDP to use XFCE..."
echo "*********************************************"
echo
echo "startxfce4" > /etc/skel/.xsession || error_exit "Failed to configure XRDP session."

# Enable and start XRDP service
echo
echo "*********************************************"
echo "Step 5: Enabling and starting XRDP service..."
echo "*********************************************"
echo
systemctl enable xrdp || error_exit "Failed to enable XRDP service."
systemctl start xrdp || error_exit "Failed to start XRDP service."

# Configure the firewall (if UFW or Firewalld is installed)
echo
echo "*********************************************"
echo "Step 6: Configuring firewall to allow XRDP..."
echo "*********************************************"
echo

if command -v ufw &> /dev/null; then
    ufw allow 3389/tcp || error_exit "Failed to configure UFW firewall for XRDP."
    ufw allow 22/tcp || error_exit "Failed to configure UFW firewall for SSH."
    echo "UFW configured: TCP 3389 (RDP) and TCP 22 (SSH)."
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --add-port=3389/tcp --permanent || error_exit "Failed to configure firewalld for XRDP."
    firewall-cmd --add-port=22/tcp --permanent || error_exit "Failed to configure firewalld for SSH."
    firewall-cmd --reload || error_exit "Failed to reload firewalld."
    echo "firewalld configured: TCP 3389 (RDP) and TCP 22 (SSH)."
else
    echo "No supported firewall (UFW or firewalld) is installed. Skipping firewall configuration."
fi

# Display completion message
echo
echo "*********************************************"
echo "XRDP setup completed successfully."
echo "*********************************************"
echo
echo "You can now connect to this machine using a Remote Desktop client."

# Display SSH connection information
echo
echo "SSH is enabled on TCP port 22."
echo "From Linux/macOS:"
echo "  ssh <username>@<server-ip>"
echo "From Windows PowerShell:"
echo "  ssh <username>@<server-ip>"
echo
echo "Check SSH status with:"
echo "  systemctl status ssh"
echo

# Display additional info
echo
echo "To connect from Windows:"
echo "  Use 'Remote Desktop Connection' and enter the IP address of this Debian-based machine."
echo
echo "To connect from Linux:"
echo "  Use a Remote Desktop client like 'Remmina' and select RDP protocol."
echo

# Check XRDP and SSH status
systemctl status xrdp
echo
echo "*********************************************"
echo "SSH service status:"
echo "*********************************************"
systemctl status ssh --no-pager

# Provide log file locations for troubleshooting
echo
echo "*********************************************"
echo "For troubleshooting, check the following log files:"
echo "  /var/log/xrdp.log"
echo "  /var/log/xrdp-sesman.log"
echo "*********************************************"
echo

exit 0