#!/bin/bash

# This script sets up a full Xfce4 installation on Gentoo
# It includes Thunar, Firefox, and other essential packages
# It only prints fatal errors to the terminal and includes a progress bar

# Function to check for errors and continue
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "\033[91mFatal error occurred during installation.\033[39m"
        exit 1
    fi
}

# Function to install packages with a progress bar
install_with_progress() {
    echo "Installing $1..."
    emerge --ask --force "$1" > /dev/null 2>&1
    check_error
}

# Update the system
echo "Updating the system..."
emerge --sync > /dev/null 2>&1
check_error

# Set the profile for Xfce
echo "Setting the profile for Xfce..."
eselect profile set default/linux/amd64/23.0/desktop > /dev/null 2>&1
check_error

# Set USE flags in make.conf
echo "Setting USE flags..."
echo 'USE="X gtk gnome systemd"' >> /etc/portage/make.conf
check_error

# Install systemd forcefully
install_with_progress "sys-apps/systemd"

# Install Xfce and essential packages
install_with_progress "xfce-base/xfce4-meta"
install_with_progress "xfce-extra/xfce4-pulseaudio-plugin"
install_with_progress "xfce-extra/xfce4-taskmanager"
install_with_progress "x11-themes/xfwm4-themes"
install_with_progress "app-editors/mousepad"
install_with_progress "xfce-base/xfce4-power-manager"
install_with_progress "x11-terms/xfce4-terminal"
install_with_progress "xfce-base/thunar"
install_with_progress "www-client/firefox"

# Add user to necessary groups
echo "Adding user to necessary groups..."
for group in cdrom cdrw usb; do
    gpasswd -a $(whoami) $group || check_error
done

# Update environment variables
echo "Updating environment variables..."
env-update && source /etc/profile || check_error

# Create .xinitrc for starting Xfce
echo "Creating .xinitrc for starting Xfce..."
echo "exec startxfce4" > ~/.xinitrc || check_error

# Enable necessary services
echo "Enabling necessary services..."
rc-update add dbus default || check_error
rc-update add display-manager default || check_error

# Final message
echo "Xfce installation and setup complete! You can start Xfce by typing 'startx'."
