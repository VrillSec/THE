#!/bin/bash

# Enable strict error handling
set -euo pipefail  # Exit on error, unset variables, and fail on any command in a pipeline failing
shopt -s inherit_errexit nullglob  # Inherit errexit in subshells and handle empty globs

# This script sets up a full Xfce4 installation on Gentoo
# It includes Thunar, Firefox, and other essential packages
# It only prints fatal errors to the terminal and includes a progress bar

# Function to check for errors and continue
check_error() {
    local exit_code=$?  # Capture the exit code of the last command
    if [ $exit_code -ne 0 ]; then
        echo -e "\033[91mFatal error occurred during installation: Exit code $exit_code\033[39m"
        echo "Last command: $BASH_COMMAND"  # Show the last executed command
        exit $exit_code
    fi
}

# Function to check if a package is installed
is_installed() {
    if emerge -q "$1" > /dev/null 2>&1; then
        return 0  # Package is installed
    else
        return 1  # Package is not installed
    fi
}

# Function to install packages with a progress bar
install_with_progress() {
    if is_installed "$1"; then
        echo "$1 is already installed."
    else
        echo "Installing $1..."
        emerge --ask --force "$1" > /dev/null 2>&1 || { echo "Failed to install $1"; check_error; }
    fi
}

# Function to check if systemd is being used
is_systemd() {
    if [ -d /run/systemd/system ]; then
        return 0  # Systemd is present
    else
        return 1  # Systemd is not present
    fi
}

# Update the system
echo "Updating the system..."
emerge --sync > /dev/null 2>&1 || { echo "Failed to update the system"; check_error; }

# Set the profile for Xfce
echo "Setting the profile for Xfce..."
eselect profile set default/linux/amd64/23.0/desktop > /dev/null 2>&1 || { echo "Failed to set profile"; check_error; }

# Set USE flags in make.conf
echo "Setting USE flags..."
echo 'USE="X gtk gnome systemd"' >> /etc/portage/make.conf || { echo "Failed to set USE flags"; check_error; }

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
for group in audio cdrom cdrw usb; do
    gpasswd -a "$(whoami)" "$group" || { echo "Failed to add user to group $group"; check_error; }
done

# Update environment variables
echo "Updating environment variables..."
env-update && source /etc/profile || { echo "Failed to update environment variables"; check_error; }

# Create .xinitrc for starting Xfce
echo "Creating .xinitrc for starting Xfce..."
echo "exec startxfce4" > ~/.xinitrc || { echo "Failed to create .xinitrc"; check_error; }

# Enable necessary services based on the init system
echo "Enabling necessary services..."
if is_systemd; then
    # If systemd is detected, use systemctl to enable services
    systemctl enable dbus.service || { echo "Failed to enable dbus.service"; check_error; }
    systemctl enable display-manager.service || { echo "Failed to enable display-manager.service"; check_error; }
else
    # If systemd is not detected, use rc-update for OpenRC
    rc-update add dbus default || { echo "Failed to add dbus to default"; check_error; }
    rc-update add display-manager default || { echo "Failed to add display-manager to default"; check_error; }
fi

# Final message
echo "Xfce installation and setup complete! You can start Xfce by typing 'startx'."
